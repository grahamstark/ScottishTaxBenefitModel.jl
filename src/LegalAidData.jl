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
AA_COSTS = DataFrame()
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
    # FIXME DUPS
    if size( CIVIL_COSTS ) == (0,0) || size(AA_COSTS) == (0,0) || size(CIVIL_AWARDS) == (0.0)
        l_artifact = RunSettings.get_artifact(; 
            name="legalaid", 
            source=settings.data_source == SyntheticSource ? "synthetic" : "slab", 
            scottish=settings.target_nation == N_Scotland )

        CIVIL_COSTS = load_costs( joinpath( l_artifact, "civil-legal-aid-case-costs.tab" ))
        AA_COSTS = load_aa_costs( joinpath( l_artifact, "aa-case-costs.tab" ))
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

end # module