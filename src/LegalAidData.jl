#
# This model contains 
# FIXME maybe amalgamate into an "ExtraData" module??
# 
module LegalAidData

using CSV
using DataFrames
using CategoricalArrays
using StatsBase
using Artifacts
using Random
using LazyArtifacts

using ScottishTaxBenefitModel
using .RunSettings
using .Definitions
using .ModelHousehold
using .Utils:basiccensor

export 
    agestr2, 
    gcounts,
    make_key,
    CIVIL_AWARDS_GRP_NS,
    CIVIL_AWARDS_GRP1,
    CIVIL_AWARDS_GRP2,
    CIVIL_AWARDS_GRP3,
    CIVIL_AWARDS_GRP4,
    CIVIL_AWARDS, 
    CIVIL_COSTS_GRP_NS,
    CIVIL_COSTS_GRP1,
    CIVIL_COSTS_GRP2,
    CIVIL_COSTS_GRP3,
    CIVIL_COSTS_GRP4,
    CIVIL_COSTS, 
    AA_COSTS,
    CIVIL_SUBJECTS,
    LA_PROB_DATA, 
    SCJS_PROBLEM_TYPES

LA_PROB_DATA = DataFrame()

const SCJS_PROBLEM_TYPES = 
    ["no_problem",
    "family",
    "children",
    "divorce",
    "housing_neighbours",
    "health",
    "money",
    "unfairness",
    "any"]

#=
const SLAB_PROBLEM_TYPES = [
    "adults_with_incapacity_or_mental_health",
    "contact_or_parentage",
    "divorce_or_separation",
    "family_or_matrimonial_other",
    "other",
    "residence"]
        

function scjs_to_slab( scjs :: String )::String
    return if scjs == "divorce"
        "divorce_or_separation"
    elseif scjs == "home"
        "residence"
    elseif scjs == "contact_or_family"

end
=#

const ESTIMATE_TYPES = ["lower","prediction","upper"]

function age2( age )::String
    ages = ismissing(age) ? "" : replace( age, " "=>"" )
    return if ages == ""
        "35-64"
    elseif ages in ["0 - 4"
        "5-9"
        "10-14"]
        "0-14"
    elseif ages in [
        "15-19"
        "20-24"
        "25-29"
        "30-34"]
        "15-34"
    elseif ages in [
        "35-39"
        "40-44"
        "45-49"
        "50-54"
        "55-59"
        "60-64"]
        "35-64"
    else
        "65+"
    end
end

function group_cases( fcase :: AbstractString )
    return if fcase in [
    "Residence"
    "Divorce/separation"
    "Family/matrimonial - other"
    "Contact/parentage"]
    fcase
    elseif fcase in ["Adults with incapacity", "Mental health" ]
        "Adults with incapacity/Mental Health"
    else
        "Other"
    end
end

#=
"Medical negligence"
"Immigration and asylum"

"Other"
"Reparation"
"Protective order"
"Housing/recovery of heritable property"
"Property/monetary"
"Appeals - other"
"Debt"
"Appeals - family"
"Judicial review"
"Discrimination"
"Breach of contract"
"Fatal accident inquiries"
=#


function load_awards( filename::String )::DataFrame
    awards = CSV.File( filename; missingstring=["#NULL!","","-"] )|>DataFrame
    nrows,ncols = size( awards )
    rename!( awards, lowercase.( names(awards)))
    println( names( awards ))
    for t in [
        :primary_category,
        :hsm,
        :case_status,
        :with_certificate,
        :age_banded,
        :consolidatedsex,
        :whichform]
        awards[:,t] = CategoricalArray( awards[:,t] )
    end
    rename!( awards, [:consolidatedsex=>:sex,
        :hsm => :hsm_full,
        :age_banded=>:age, 
        :passportedbenefitsmeans1=>:passported,
        :totalmaxconform2=>:maxcon])
    awards.passported = .! ismissing.( awards.passported )
    awards.la_status = fill( la_none, nrows )
    awards.age2 = age2.( awards.age )
    awards.hsm = CategoricalArray( group_cases.(awards.hsm_full))
    # NOTE this skips over Adults with incapacity
    for r in 1:nrows
        a = awards[r,:]
        # @show a
        if a.passported # form 1
            awards[r,:la_status] = la_passported
        elseif a.whichform == "2" # form 2 == means-test
            if (a.hsm == "Adults with incapacity") || # kill all abandoned cases
               (ismissing( a.meansstatusc_i )) ||
               (a.meansstatusc_i in ["ABANDONED","CONTINUED"]) || 
               (a.statustextform2 == "ABANDONED")
                ;
            else
                if a.maxcon > 0
                    awards[r,:la_status] = la_with_contribution 
                else
                    awards[r,:la_status] = la_full 
                end
            end
        end
        # 38% of recorded sex is male, so: fill in missing sex 38% male
        # FIXME maybe by type?
        if ismissing(a.sex)
            a.sex = rand() <= 0.382 ? "Male" : "Female"
        end
    end

    awards
end

function load_aa_costs( filename::String )::DataFrame
    cost = CSV.File( filename; missingstring=["#NULL!","","-"] )|>DataFrame
    nrows,ncols = size( cost )
    rename!( cost, lowercase.( names(cost)))
    for t in [
        :highersubject,
        :aidtype,
        :appcode,
        :highersubject,
        :sex ]
        cost[:,t] = CategoricalArray( cost[:,t] )
    end
    rename!( cost, [
        :highersubject=>:hsm_full,
        :age_banded=>:age, 
        :ap_contribution=>:maxcon, 
        :passport_ben=>:passported])    
    gcases = group_cases.(cost.hsm_full)    
    cost.hsm = CategoricalArray( gcases )
    cost.hsm_censored = CategoricalArray( basiccensor.(gcases))
    cost.passported = cost.passported .== "Y"
    cost.maxcon = coalesce.(cost.maxcon, 0.0 )    
    cost.age2 = age2.( cost.age )    
    cost.la_status = fill( la_none, nrows )
    for r in 1:nrows
        a = cost[r,:]
        a.la_status = if a.passported 
            la_passported 
        elseif a.maxcon > 0
            la_with_contribution
        else
            la_full
        end
        if ismissing(a.sex) || ( match( r".*Prefer.*", titlecase(a.sex) ) !== nothing )
            a.sex = rand() <= 0.47335001563966217 ? "Male" : "Female"
        end
    end
    cost.sex = titlecase.(cost.sex)
    cost
end

function load_costs( filename::String )::DataFrame
    cost = CSV.File( filename; missingstring=["#NULL!","","-"] )|>DataFrame
    nrows,ncols = size( cost )
    rename!( cost, lowercase.( names(cost)))
    for t in [
        :highersubject,
        :aidtype,
        :appcode,
        :categorydescription,
        :highersubject,
        :sex,
        :catecode,  
        :whichform ]
        cost[:,t] = CategoricalArray( cost[:,t] )
    end
    rename!( cost, [
        :highersubject=>:hsm_full,
        :age_banded=>:age,
        :totalpaidincvat=>:totalpaid])
    gcases = group_cases.(cost.hsm_full)
    cost.hsm = CategoricalArray( gcases )
    cost.hsm_censored = CategoricalArray( basiccensor.(gcases))
    cost.passported = .! ismissing.( cost.passported )
    cost.maxcon = coalesce.(cost.maxcon, 0.0 )
    cost.la_status = fill( la_none, nrows )
    cost.age2 = age2.( cost.age )
    for r in 1:nrows
        a = cost[r,:]
        # @show a
        if a.passported # form 1
            cost[r,:la_status] = la_passported
        else # elseif a.whichform == "2" # form 2 == means-test
            if (a.hsm == "Adults with incapacity")
                ;
            else
                if a.maxcon > 0
                    cost[r,:la_status] = la_with_contribution 
                else
                    cost[r,:la_status] = la_full 
                end
            end
        end
        # 38% of recorded sex is male, so: 
        # FIXME maybe by type?
        if ismissing(a.sex)
            a.sex = rand() <= 0.382 ? "Male" : "Female"
        end
        # @assert cost[r,:la_status] !== la_none
    end # each rpw
    cost
end

CIVIL_COSTS = DataFrame()
CIVIL_COSTS_EXCL_ADULT_MENTAL_HEALTH = DataFrame()
CIVIL_COSTS_ADULT_MENTAL_HEALTH_ONLY = DataFrame()
AA_COSTS = DataFrame()
AA_COSTS_EXCL_ADULT_MENTAL_HEALTH = DataFrame()
AA_COSTS_ADULT_MENTAL_HEALTH_ONLY = DataFrame()
CIVIL_AWARDS = DataFrame()

CIVIL_AWARDS_GRP_NS = DataFrame()
CIVIL_AWARDS_GRP1 = DataFrame()
CIVIL_AWARDS_GRP2 = DataFrame()
CIVIL_AWARDS_GRP3 = DataFrame()
CIVIL_AWARDS_GRP4 = DataFrame()
CIVIL_COSTS_GRP_NS = DataFrame()

CIVIL_COSTS_GRP1 = DataFrame()
AA_COSTS_GRP1 = DataFrame()

CIVIL_COSTS_GRP2 = DataFrame()
CIVIL_COSTS_GRP3 = DataFrame()
CIVIL_COSTS_GRP4 = DataFrame()
CIVIL_SUBJECTS = DataFrame()


function init(settings::Settings; reset=false)

    global CIVIL_COSTS
    global AA_COSTS
    global CIVIL_AWARDS
    
    global CIVIL_AWARDS_GRP_NS 
    global CIVIL_AWARDS_GRP1 
    global CIVIL_AWARDS_GRP2 
    global CIVIL_AWARDS_GRP3 
    global CIVIL_AWARDS_GRP4 
    global CIVIL_COSTS_GRP_NS 
        
    global CIVIL_COSTS_GRP1 
    global AA_COSTS_GRP1 
        
    global CIVIL_COSTS_GRP2 
    global CIVIL_COSTS_GRP3 
    global CIVIL_COSTS_GRP4 
    global CIVIL_SUBJECTS 
    global LA_PROB_DATA
    global AA_COSTS_EXCL_ADULT_MENTAL_HEALTH
    global CIVIL_COSTS_EXCL_ADULT_MENTAL_HEALTH
    global AA_COSTS_ADULT_MENTAL_HEALTH_ONLY
    global CIVIL_COSTS_ADULT_MENTAL_HEALTH_ONLY

    # FIXME DUPS
    if size( CIVIL_COSTS ) == (0,0) || size(AA_COSTS) == (0,0) || size(CIVIL_AWARDS) == (0.0)
        l_artifact = RunSettings.get_artifact(; 
            name="legalaid", 
            source=settings.data_source == SyntheticSource ? "synthetic" : "slab", 
            scottish=settings.target_nation == N_Scotland )

        CIVIL_COSTS = load_costs( joinpath( l_artifact, "civil-legal-aid-case-costs.tab" ))
        CIVIL_COSTS_EXCL_ADULT_MENTAL_HEALTH = CIVIL_COSTS[CIVIL_COSTS.hsm_censored.!= "adults_with_incapacity_or_mental_health",:]
        CIVIL_COSTS_ADULT_MENTAL_HEALTH_ONLY = CIVIL_COSTS[CIVIL_COSTS.hsm_censored.== "adults_with_incapacity_or_mental_health",:]
        AA_COSTS = load_aa_costs( joinpath( l_artifact, "aa-case-costs.tab" ))
        AA_COSTS_EXCL_ADULT_MENTAL_HEALTH = AA_COSTS[AA_COSTS.hsm_censored.!= "adults_with_incapacity_or_mental_health",:]
        AA_COSTS_ADULT_MENTAL_HEALTH_ONLY = AA_COSTS[AA_COSTS.hsm_censored.== "adults_with_incapacity_or_mental_health",:]
        CIVIL_AWARDS = load_awards( joinpath( l_artifact, "civil-applications.tab" ))

        CIVIL_AWARDS_GRP_NS = groupby(CIVIL_AWARDS, [:hsm, :age2, :sex])
        CIVIL_AWARDS_GRP1 = groupby(CIVIL_AWARDS, [:hsm])
        CIVIL_AWARDS_GRP2 = groupby(CIVIL_AWARDS, [:hsm, :la_status])
        CIVIL_AWARDS_GRP3 = groupby(CIVIL_AWARDS, [:hsm, :la_status, :sex])
        CIVIL_AWARDS_GRP4 = groupby(CIVIL_AWARDS, [:hsm, :la_status,:age2, :sex])
        CIVIL_COSTS_GRP_NS = groupby(CIVIL_COSTS, [:hsm, :age2, :sex])

        CIVIL_COSTS_GRP1 = groupby(CIVIL_COSTS, [:hsm_censored])
        AA_COSTS_GRP1 = groupby(AA_COSTS, [:hsm_censored])

        CIVIL_COSTS_GRP2 = groupby(CIVIL_COSTS, [:hsm, :la_status])
        CIVIL_COSTS_GRP3 = groupby(CIVIL_COSTS, [:hsm, :la_status, :sex])
        CIVIL_COSTS_GRP4 = groupby(CIVIL_COSTS, [:hsm, :la_status, :age2, :sex])
        CIVIL_SUBJECTS = sort(levels( CIVIL_AWARDS.hsm ))
        #=  FIXME legal aid prob data is NOT NEEDED ANYMORE (but should be)- scottish crime survey probs unused at SLAB request. =#
        LA_PROB_DATA = CSV.File( joinpath( l_artifact, "$(settings.legal_aid_probs_data).tab"))|>DataFrame 
 
    end
end

function gcounts( gdf :: GroupedDataFrame )
    kk = sort(keys(gdf))
    for k in kk
        if haskey( gdf, k )
            @show k
            @show size(gdf[k])[1]
            @show summarystats(gdf[k].totalpaid)
        end
    end
end

function agestr( age :: Int ) :: String
    return if age < 5
        "0 - 4"
    elseif age < 10
        "5 - 9"
    elseif age < 15
        "10 - 14"
    elseif age < 20
        "15 - 19"
    elseif age < 25
        "20 - 24"
    elseif age < 30
        "25 - 29"
    elseif age < 35
        "30 - 34"
    elseif age < 40
        "35 - 39"
    elseif age < 45
        "40 - 44"
    elseif age < 50
        "45 - 49"
    elseif age < 55
        "50 - 54"
    elseif age < 60
        "55 - 59"
    elseif age < 65
        "60 - 64"
    elseif age < 70
        "65 - 69"
    elseif age < 75
        "70 - 74"
    elseif age < 80
        "75 - 79"
    elseif age < 85
        "80 - 84"
    elseif age >= 85
        "85 and above"
    end
end

function agestr2( age :: Int ) :: String
    age2( agestr( age ))
end

function make_key(; 
    la_status :: Union{LegalAidStatus,Nothing}=nothing, 
    hsm :: Union{String,Nothing}=nothing, 
    age :: Union{String,Int,Nothing}=nothing, 
    sex :: Union{Sex,Nothing}=nothing ) :: NamedTuple
    k = []
    v = []
    if ! isnothing( hsm )
        push!(k, :hsm)
        push!(v, hsm )
    end
    if ! isnothing( la_status )
        push!(k, :la_status)
        push!(v, la_status )
    end
    if ! isnothing( age )
        push!(k, :age2)
        if typeof(age) == String
            push!(v, age )
        else
            push!(v, age2(agestr(age)) )
        end
    end
    if ! isnothing( sex )
        push!(k, :sex)
        push!(v, string.(sex) )
    end
    k = NamedTuple(zip(k,v))
    return k
end

function add_la_probs!( hh :: Household )
    global LA_PROB_DATA
    la_hhdata = LA_PROB_DATA[ (LA_PROB_DATA.data_year .== hh.data_year) .& (LA_PROB_DATA.hid.==hh.hid),: ]
    for (pid, pers ) in hh.people
        pdat = la_hhdata[la_hhdata.pid .== pers.pid,:]
        @assert size(pdat)[1] == 1
        pers.legal_aid_problem_probs = pdat[1,:]
    end
end

#= ============================
new version
=#

export merge_in_results_and_hh, 
       create_needs_and_cases_per_need

CIVIL_NEEDS = nothing
CIVIL_CASES_PER_NEED = nothing
CIVIL_PEOPLE = nothing
AA_NEEDS = nothing
AA_CASES_PER_NEED = nothing
AA_PEOPLE = nothing


# see: https://docs.julialang.org/en/v1/stdlib/Random/
const RAND_GEN = Xoshiro(123456);

const SCJS_SLAB_MAP_CIVIL = Dict([
    :family_prediction=> 
        ["Abusive Behaviour and Sexual Harm (Scotland) Act",
        "Exclusion Order",
        "Non  Harassment Order",
        "Protection From Abuse (Scotland) Act 2001",
        "Non Harassment Order Family",
        "Interdict Non-Molestation"],

    :children_prediction=> 
        ["Appeal Inner House - family",
        "Appeal to Sheriff Appeal Court - Family",
        "Breach of Interdict - Family",
        "Interdict - Family Other",
        "Interdict - Other Non Family",
        "Orders Under Family Law (Scotland) Act",
        "Interdict against removal of Child/Other",
        "Education (Scotland) Act",
        "Parental rights and responsibilities order - s.11 Children (Scotland) Act 1995",
        "Adoption",
        "Child Support Agency Enforcement Orders",
        "Declarator Of Non Parentage",
        "Declarator Of Parentage",
        "Permanency order",
        "Contact",
        "Parental Responsibility Order",
        "Deprivation of Parental Rights and Responsibilities",
        "Orders under Matrimonial Homes (Scotland) Act",
        "Specific Issue Order"],

    :divorce_prediction=> 
        ["Divorce 1 Year",
        "Aliment",
        "Divorce On The Grounds Of Adultery",
        "Divorce on the grounds of Two Years Separation",
        "Divorce on the grounds of Unreasonable Behaviour",
        "Separation",
        "Variation",
        "Pension Splitting Order",
        "Dissolution of Civil Partnership",
        "Reciprocal Enforcement",
        "Minute for Failure to Obtemper",
        "Ailment"],

    :housing_neighbours_prediction=> 
        ["Judicial Review - Housing/Homelessness",
        "Reparation - housing disrepair",
        "Transfer of Tenancy",
        "Interdict - Neighbour Disputes"],

    :health_prediction=>
        ["Adults With Incapacity (Scotland) Act 2000",
        "Adults with Incapacity (Scotland) Act 2000 - Welfare, or Welfare and Financial Component",
        "Home owners and debtor protection - defence",
        "Reparation - Medical Negligence",
        "Reparation - Other/Damages",
        "Reparation - Personal Injury"],

    :money_prediction=> # cvjmon #  problems concerning your money, finances or anything you’ve paid for: with money and debt in last 3 years => 
        ["Division of Sale",
        "Proceeds of Crime - Civil Recovery",
        "Debt",
        "Executry",
        "Unjustified Enrichment",
        "Recovery of Heritable Property",
        "Sequestration",
        "Capital Sum",
        "Interdict against Disposal of Assets",
        "Count/Reckoning/Payment",
        "Payment",
        "Recovery of Heritable Property - Rent Arrears",
        "Breach of Contract",
        "Specific Implement",
        "Delivery Of Goods",
        "Reparation - Professional Negligence (Non Medical)"],

    :unfairness_prediction=> 
        ["Judicial Review Immigration Proceedings",
        "Residence",
        "Other Discrimination Based Cases (Other than DDA)",
        "Power of Arrest",
        "Employment Appeal Tribunal"],

    :any_prediction=>  # maps "others" to "any", which is a hack
        ["Declarator",
        "Delivery",
        "Breach of Interdict",
        "Suspension and Interdict",
        "Other Civil",
        "Reduction",
        "Administration Of Justice Act",
        "Anti-Social Behaviour Orders - Defence",
        "Appeal",
        "Appeal To The Court Of Session Inner House",
        "Appeal to Sheriff Appeal Court",
        "Application to the UK Supreme Court",
        "Civic Government (Scotland) Act",
        "Fatal Accident Inquiry",
        "Hague Convention Application",
        "Judicial Review",
        "Judicial Review - against Scottish Ministers",
        "Judicial Review against the Scottish Legal Aid Board",
        "Other Convention Application",
        "Petitions (Other Than For Judicial Review)",
        "Variation"] ])

# Maps hsm_full field in AA_COSTS to SCJS regression categories.
SCJS_SLAB_MAP_AA = Dict([
    :family_prediction=> 
        ["Protective order",
        "Family/matrimonial - other"],
    :children_prediction=> 
        ["Contact/parentage"],
    :divorce_prediction=> 
        ["Aliment/Child Support Agency", 
        "Divorce",
        "Separation"],
    :housing_neighbours_prediction=> 
        ["Housing",
        "Antisocial Behaviour Orders (ASBO)"],
    :health_prediction=>
        [ # "Adults with incapacity",
        "Mental health",
        "Criminal Injuries Compensation Aut",
        "Medical negligence"
        ],
    :money_prediction=> # cvjmon #  problems concerning your money, finances or anything you’ve paid for: with money and debt in last 3 years => 
        ["Recovery of heritable property",
         "Wills/executry",
         "State benefit",
         "Breach of contract",
         "Hire purchase/debt",
         "Property/monetary",
         "Reparation"
         ],
    :unfairness_prediction=> 
        ["Immigration and asylum",
        "Complaints about professional bodi",
        "Employment",
        "Discrimination",
        "Residence",
        "Human rights"
        ],
    :any_prediction=>  # maps "others" to "any", which is a hack
        [
            "Appeals - other", 
            "Conveyancing", 
            "Power of attorney", 
            "Contempt - Civil matter", 
            "Fatal accident inquiries",
            "Judicial review",
            "Other"] ])

"""
casetype -> unfairness_prediction etc. from the maps above.
system_type: sys_civil, sys_aa
Selects one row at random from those mapped to the given casetype in the civil or AA costs data.
"""
function costs_sample( casetype :: Symbol, system_type :: SystemType )::DataFrameRow
    costs, map, ctype = if system_type == sys_civil
        CIVIL_COSTS_EXCL_ADULT_MENTAL_HEALTH, SCJS_SLAB_MAP_CIVIL, :categorydescription
    else
        AA_COSTS_EXCL_ADULT_MENTAL_HEALTH, SCJS_SLAB_MAP_AA, :hsm_full
    end
    subset = costs[ (costs[!,ctype] .∈ ( map[casetype], )), :]    
    n = size(subset)[1]
    p = sample(1:n)    
    return subset[p,:]
end

function make_costs_dataframe( n :: Integer )::DataFrame
    return DataFrame(
        hid = zeros( BigInt, n ),
        pid = zeros( BigInt, n ),
        data_year = zeros( Int, n ),        
        pno = zeros( Int, n ),
        slab_casetype = fill("",n),
        scjs_casetype = fill(:"",n),
        max_contribution = zeros(n),   
        net_contribution  = zeros(n), 
        gross_cost = zeros(n),
        net_cost = zeros(n),
        entitlement = fill( la_none, n ))
end

"""

"""
function create_one_costs_frame( 
    eligible_people :: DataFrame, 
    cases_per_need :: Dict,
    system_type :: SystemType )::DataFrame
    costs = if system_type == sys_civil # FIXME - do this once & pass in to `sample`
        CIVIL_COSTS_EXCL_ADULT_MENTAL_HEALTH
    else
        AA_COSTS_EXCL_ADULT_MENTAL_HEALTH
    end
    n = size( costs )[1]*2
    cases = make_costs_dataframe( n )
    needs = 0
    pno = 0
    nc = 0
    weeks = system_type == sys_aa ? 1.0 : WEEKS_PER_YEAR
    for pers in eachrow( eligible_people )
        pno += 1
        reps = Int( round( pers.weight )) # this will be the weight for the actual modelled sample
        for problem in keys(cases_per_need)
            for i in 1:reps
                probkey = Symbol("prob_$(problem)")
                rnd1 = rand(RAND_GEN)
                rnd2 = rand(RAND_GEN)
                prob_of_prob = pers[probkey]
                if rnd1 < prob_of_prob
                    needs += 1
                    if rnd2 < cases_per_need[problem]
                        case = costs_sample( problem, system_type )
                        nc += 1
                        cs = @view cases[nc,:]
                        cs.hid = pers.hid
                        cs.pid = pers.pid
                        cs.data_year = pers.data_year
                        cs.pno = pers.pno
                        cs.slab_casetype = case.hsm_full
                        cs.scjs_casetype = string(problem)
                        cs.max_contribution = pers.modelled_income_contribution_amt*weeks +
                            pers.modelled_capital_contribution_amt
                        cs.gross_cost = case.totalpaid
                        if pers.modelled_entitlement in [la_full, la_with_contribution]
                            cs.net_contribution = min( cs.max_contribution, cs.gross_cost )
                        end
                        cs.net_cost = cs.gross_cost - cs.net_contribution                         
                        cs.entitlement = pers.modelled_entitlement                    
                    end # Prob of having case given a problem: go for it.
                end # Prob of having problem.
            end # Repeat for each actual person this case represents.
        end  # For each problem type.
    end # Each person in the entitled sample.
    cases[1:nc,:]
end # proc 

"""
results prefixed with `modelled_`
hh prefixed with `hh_` (indexes only)
probs prefixed by `prob_`
return eligible only
"""
function merge_in_results_and_hh( 
    hh :: DataFrame, 
    people::DataFrame,
    laresults :: DataFrame ) :: DataFrame
    probdata = rename( s->"prob_"*s, LA_PROB_DATA )
    mpeople = leftjoin( people, probdata, on=[
        :data_year=>:prob_data_year,
        :hid=>:prob_hid,
        :pno=>:prob_pno] )
    rename!( hh, [
        :data_year=>:hh_data_year, 
        :hid=>:hh_hid,
        :uhid=>:hh_uhid,
        :onerand=>:hh_onerand])
    mpeople = rightjoin( mpeople, hh, on=[
        :data_year=>:hh_data_year,
        :hid=>:hh_hid] ) # just to get weights
    
    rename!( s->"modelled_"*s, laresults )
    mrpeople = leftjoin( mpeople, modelled_results, on=[:pid=>:modelled_pid] ) # add baseline results
    @show names( mrpeople )
    # @show mrpeople.modelled_entitlement
    mrpeople.modelled_entitlement_agg = agg_la_status.( mrpeople.modelled_entitlement )
    eligible_people = mrpeople[ mrpeople.modelled_entitlement .!== la_none, :]
    return eligible_people
end

function make_adult_incapactity( system_type :: SystemType )::DataFrame
    costs = if system_type == sys_civil # FIXME - do this once & pass in to `sample`
        CIVIL_COSTS_ADULT_MENTAL_HEALTH_ONLY
    else
        AA_COSTS_ADULT_MENTAL_HEALTH_ONLY
    end    
    nrows, ncols = size( costs )
    cases = make_costs_dataframe( nrows )
    cases.hid .= -1
    cases.pid .= -1
    cases.data_year .= -1
    cases.pno .= -1
    cases.slab_casetype .= "adults_with_incapacity_or_mental_health"
    cases.scjs_casetype .= ""
    cases.max_contribution .= 0.0
    cases.gross_cost = costs.totalpaid
    cases.net_contribution .= 0.0
    cases.net_cost = cases.gross_cost
    cases.entitlement .= la_passported                
    cases
end

"""

"""
function do_one_costing( 
    eligible_people :: DataFrame, 
    cases_per_need :: Dict,
    system_type :: SystemType )::DataFrame
    costs = if system_type == sys_civil # FIXME - do this once & pass in to `sample`
        CIVIL_COSTS_EXCL_ADULT_MENTAL_HEALTH
    else
        AA_COSTS_EXCL_ADULT_MENTAL_HEALTH
    end
    n = size( costs )[1]*2
    cases = make_costs_dataframe( n )
    needs = 0
    pno = 0
    nc = 0
    weeks = system_type == sys_aa ? 1.0 : WEEKS_PER_YEAR
    for pers in eachrow( eligible_people )
        pno += 1
        reps = Int( round( pers.weight )) # this will be the weight for the actual modelled sample
        for problem in keys(cases_per_need)
            for i in 1:reps
                probkey = Symbol("prob_$(problem)")
                rnd1 = rand()
                rnd2 = rand()
                prob_of_prob = pers[probkey]
                if rnd1 < prob_of_prob
                    needs += 1
                    if rnd2 < cases_per_need[problem]
                        case = costs_sample( problem, system_type )
                        nc += 1
                        cs = @view cases[nc,:]
                        cs.hid = pers.hid
                        cs.pid = pers.pid
                        cs.data_year = pers.data_year
                        cs.pno = pers.pno
                        cs.slab_casetype = case.hsm_full
                        cs.scjs_casetype = string(problem)
                        cs.max_contribution = pers.modelled_income_contribution_amt*weeks +
                            pers.modelled_capital_contribution_amt
                        cs.gross_cost = case.totalpaid
                        if pers.modelled_entitlement in [la_full, la_with_contribution]
                            cs.net_contribution = min( cs.max_contribution, cs.gross_cost )
                        end
                        cs.net_cost = cs.gross_cost - cs.net_contribution                         
                        cs.entitlement = pers.modelled_entitlement                    
                    end # Prob of having case given a problem: go for it.
                end # Prob of having problem.
            end # Repeat for each actual person this case represents.
        end  # For each problem type.
    end # Each person in the entitled sample.
    # just stick the adults with incapacity on at the end
    adinc = make_adult_incapactity( system_type )
    return vcat(cases[1:nc,:],adinc)
end # proc `do_one_costing`

"""

"""
function do_one_costing( results::NamedTuple, system_type :: SystemType, sysno :: Integer )
    modelled_results, mpeople, cases_per_need = if system_type == sys_civil
        rename( s->"modelled_"*s, results.legalaid.civil.data[sysno]), 
            CIVIL_PEOPLE, 
            CIVIL_CASES_PER_NEED
    else 
        rename( s->"modelled_"*s, results.legalaid.aa.data[sysno]), 
            AA_PEOPLE, 
            AA_CASES_PER_NEED
    end
    mrpeople = leftjoin( mpeople, modelled_results, 
        on=[:pid=>:modelled_pid], makeunique=true ) # add baseline results
    @show names(mrpeople)
    @show mrpeople[1,:modelled_entitlement]
    mrpeople.modelled_entitlement_agg = agg_la_status.( mrpeople.modelled_entitlement )
    eligible_people = mrpeople[ mrpeople.modelled_entitlement .!== la_none, :]
    costings = do_one_costing( eligible_people, cases_per_need, system_type )
    return costings
end # do_one_costing

"""
Note: this is done *just over those with a modelled entitlement* (of any kind).
`needs` are the sum of the mean probabilities for each person for each SCJS problem type
`cases_per_need` is the number of SLAB cost cases of that type, divided by needs for that type.
"""
function get_needs_and_cases( entitled_people ::DataFrame, system_type :: SystemType  )::Tuple
    needs = Dict()
    cases_per_need = Dict()
    costs, map, ctype = if system_type == sys_civil
        CIVIL_COSTS_EXCL_ADULT_MENTAL_HEALTH, SCJS_SLAB_MAP_CIVIL, :categorydescription
    else
        AA_COSTS_EXCL_ADULT_MENTAL_HEALTH, SCJS_SLAB_MAP_AA, :hsm_full
    end
    for problem in keys( map )
        subset = costs[ (costs[!,ctype] .∈ ( map[problem], )), :]
        n = size(subset)[1]        
        needs[problem] = sum( entitled_people[!, Symbol( "prob_$(problem)")], Weights( entitled_people.weight ))
        cases_per_need[problem] = n/(needs[problem])
    end
    needs, cases_per_need
end

end # module