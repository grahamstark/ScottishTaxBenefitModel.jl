using ScottishTaxBenefitModel
using .DataSummariser
using .Definitions
using .FRSHouseholdGetter
using .LegalAidData
using .Monitor: Progress
using .Runner
using .RunSettings
using .STBParameters
using .Utils

using StatsBase
using Observables
using CSV
using DataFrames

include( "comparisons_skeleton.jl")


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
        ["Adults with incapacity",
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


function make_costs_by_case( system_type :: SystemType )::Dict{Symbol,DataFrame}
    costs, map, ctype, nms = if system_type == sys_civil
        CIVIL_COSTS, 
        SCJS_SLAB_MAP_CIVIL, 
        :categorydescription, 
        collect( keys( SCJS_SLAB_MAP_CIVIL ))    
    else
        AA_COSTS, 
        SCJS_SLAB_MAP_AA, 
        :hsm_full,
        collect( keys( SCJS_SLAB_MAP_AA ))
    end
    m = Dict{Symbol,DataFrame}
    for nm in nms 
        subset = costs[ (costs[!,ctype] .∈ ( map[casetype], )), :]    
        m[nm] = subset
    end
    return m
end

const CIVIL_COSTS_BY_SCJS_CASE = make_costs_by_case( sys_civil )
const AA_COSTS_BY_SCJS_CASE = make_costs_by_case( sys_aa )

"""
casetype -> unfairness_prediction etc. from the maps above.
system_type: sys_civil, sys_aa
Selects one row at random from those mapped to the given casetype in the civil or AA costs data.
"""
function costs_sample( casetype :: Symbol, system_type :: SystemType )::DataFrameRow
    subset = if system_type == sys_civil
        CIVIL_COSTS_BY_SCJS_CASE[casetype]
    else
        AA_COSTS_BY_SCJS_CASE[casetype]
    end
    # subset = costs[ (costs[!,ctype] .∈ ( map[casetype], )), :]    
    n = size(subset)[1]
    p = sample(1:n)    
    return subset[p,:]
end

#=
"""
casetype -> unfairness_prediction etc. from the maps above.
Selects one row at random from those mapped to the given casetype in the AA costs data.
"""
function aa_sample( casetype :: Symbol )::DataFrameRow
    subset = AA_COSTS[ (AA_COSTS.hsm_full .∈ ( SCJS_SLAB_MAP_AA[casetype], )), :] 
    n = size(subset)[1]
    p = sample(1:n)    
    return subset[p,:]
end
=#
function compare_breakdowns( modelled :: DataFrame, actual :: DataFrame )::Tuple # , system_type :: SystemType
    counts_cases_m = countmap( modelled[!, :slab_casetype ])
    counts_cases_a = countmap( actual[!, :hsm_full])
    counts_status_m = countmap( modelled[!, :entitlement  ])
    counts_status_a = countmap( actual[!, :la_status])
    counts_cases = Dict()
    for k in keys( counts_cases_m )
        counts_cases[k] = ( counts_cases_a[k], counts_cases_m[k])
    end
    counts_status = Dict()
    for k in keys( counts_status_m )
        counts_status[k] = ( counts_status_a[k], counts_status_m[k])
    end
    stats_m = summarystats( modelled.gross_cost )
    stats_a = summarystats( actual.totalpaid )
    counts_cases, counts_status, stats_m, stats_a
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

# const OFFER_PROPENSITY = Dict( [la_passported => 0.9, la_full => 0.8, la_with_contribution=> 0.7])
# const OFFER_PROPENSITY = Dict( [la_passported => 1, la_full => 1, la_with_contribution=> 1])

"""

"""
function do_one_costing( 
    eligible_people :: DataFrame, 
    cases_per_need :: Dict,
    system_type :: SystemType )::DataFrame
    costs = if system_type == sys_civil # FIXME - do this once & pass in to `sample`
        CIVIL_COSTS
    else
        AA_COSTS
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
                probkey = Symbol("modelled_$(problem)")
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
    cases[1:nc,:]
end # proc `do_one_costing`

function initialise( 
    settings :: Settings, 
    sys :: TaxBenefitSystem,
    obs :: Observable; 
    reset_data = false, 
    system_type = sys_civil )::Tuple
    LegalAidData.init( settings )
    hh, people = get_raw_data!( settings; reset=reset_data )
    probdata = rename( s->"prob_"*s, LA_PROB_DATA)
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
    results = Runner.do_one_run( settings, [sys], obs )
    outf = summarise_frames!( results, settings )
    modelled_results = if system_type == sys_civil
        rename( s->"modelled_"*s, results.legalaid.civil.data[1])
    else 
        rename( s->"modelled_"*s, results.legalaid.aa.data[1])
    end
    mrpeople = leftjoin( mpeople, modelled_results, on=[:pid=>:modelled_pid], makeunique=true ) # add baseline results
    mrpeople.modelled_la_status_agg = agg_la_status.( mrpeople.modelled_la_status )
    eligible_people = mrpeople[ mrpeople.modelled_la_status .!== la_none, :]
    needs, cases_per_need = get_needs_and_cases( eligible_people, system_type )
    costings = do_one_costing( eligible_people, cases_per_need, system_type )
    costings, needs, cases_per_need, mpeople, results
end

settings = Settings()
settings.included_data_years = [2019,2021,2022]
# emulate, as far as we can, the system in place in 2024, 
# when the SLAB data was created.
settings.to_y = 2024
settings.to_q = 1
settings.means_tested_routing = modelled_phase_in
# settings.num_households, settings.num_people, nhh2 = 
#    FRSHouseholdGetter.initialise( settings; reset=true )
settings.do_legal_aid = true
sys = STBParameters.get_default_system_for_fin_year( 2024 )
# observer = Observer(Progress("",0,0,0))
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
    println(tot)
end

    
# const in final version
const civ_base_costings, civ_needs, civ_cases_per_need, civ_people, base_results = 
    initialise( settings, sys, obs; reset_data=true, system_type = sys_civil )
const aa_base_costings, aa_needs, aa_cases_per_need, aa_people, ignoreme = 
    initialise( settings, sys, obs; reset_data=false, system_type = sys_aa )

"""

"""
function do_one_costing( results::NamedTuple, system_type :: SystemType, sysno = 2 )
    modelled_results, mpeople, cases_per_need = if system_type == sys_civil
        rename( s->"modelled_"*s, results.legalaid.civil.data[sysno]), civ_people, civ_cases_per_need
    else 
        rename( s->"modelled_"*s, results.legalaid.aa.data[sysno]), aa_people, aa_cases_per_need
    end
    mrpeople = leftjoin( mpeople, modelled_results, on=[:pid=>:modelled_pid], makeunique=true ) # add baseline results
    mrpeople.modelled_la_status_agg = agg_la_status.( mrpeople.modelled_la_status )
    eligible_people = mrpeople[ mrpeople.modelled_la_status .!== la_none, :]
    costings = do_one_costing( eligible_people, cases_per_need, system_type )
    return costings
end

civ_counts_cases, civ_counts_status, civ_stats_m, civ_stats_a = compare_breakdowns( civ_base_costings, CIVIL_COSTS )
for (k,v) in civ_counts_cases
    println( "$k = $v")
end

aa_counts_cases, aa_counts_status, aa_stats_m, aa_stats_a = compare_breakdowns( aa_base_costings, AA_COSTS )
for (k,v) in aa_counts_cases
    println( "$k = $v")
end


#=

sketch 2
=#

sys2 = deepcopy(sys)
sys2.legalaid.civil.capital_contribution_limits[2]=190_000
sys2.legalaid.civil.income_contribution_limits[4]=190_000
results = Runner.do_one_run( settings, [sys,sys2], obs )
open("stdout.txt", "w") do io
    redirect_stdout(io) do
        outf = summarise_frames!( results, settings )
    end
end