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

SCJS_SLAB_MAP = Dict([
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

function civ_sample( casetype :: Symbol )::DataFrameRow
    subset = CIVIL_COSTS[ (CIVIL_COSTS.categorydescription  .∈ ( SCJS_SLAB_MAP[casetype], )), :] #.& ( CIVIL_COSTS.la_status .== la_status ), :]
    # @show subset
    n = size(subset)[1]
    p = sample(1:n)    
    # @show n p
    return subset[p,:]
    # sample(CIVIL_COSTS[CIVIL_COSTS.hsm_censored .== casetype,:]
end

function add_civil_category!(pr :: DataFrameRow )
    for problem in SCJS_PROBLEM_TYPES[2:end]
        casetype = Symbol( "civ_$(problem)")
        CIVIL_COSTS.categorydescription  .∈ SCJS_SLAB_MAP[casetype]
    end
end

"""
Note: this is done *just over those with a modelled entitlement* (of any kind).
`needs` are the sum of the mean probabilities for each person for each SCJS problem type
`cases_per_need` is the number of SLAB cost cases of that type, divided by needs for that type.
"""
function get_needs_and_cases( entitled_people ::DataFrame )::Tuple
    needs = Dict()
    cases_per_need = Dict()
    for problem in keys( SCJS_SLAB_MAP )
        subset = CIVIL_COSTS[ (CIVIL_COSTS.categorydescription  .∈ ( SCJS_SLAB_MAP[problem], )), :] # .& ( CIVIL_COSTS.la_status .== la_status ), :]
        n = size(subset)[1]        
        needs[problem] = sum(  entitled_people[!, Symbol( "modelled_$(problem)")], Weights( entitled_people.weight )) # status == la_status
        cases_per_need[problem] = n/(needs[problem])
    end
    needs, cases_per_need
end

function compare_breakdowns( )
   
end

function make_costs_dataframe( n :: Integer )::DataFrame
    return DataFrame(
        hid       = zeros( BigInt, n ),
        pid       = zeros( BigInt, n ),
        data_year  = zeros( Int, n ),        
        pno   = zeros( Int, n ),
        max_contribution = zeros(n),   
        actual_contribution = zeros(n), 
        net_contribution  = zeros(n), 
        gross_cost = zeros(n),
        net_cost = zeros(n),
        entitlement = fill( la_none, n ))
end

# const OFFER_PROPENSITY = Dict( [la_passported => 0.9, la_full => 0.8, la_with_contribution=> 0.7])
# const OFFER_PROPENSITY = Dict( [la_passported => 1, la_full => 1, la_with_contribution=> 1])

"""

"""
function do_one_costing( eligible_people :: DataFrame, cases_per_need::Dict )::DataFrame
    n = size( CIVIL_COSTS )[1]*2
    cases = make_costs_dataframe( n )
    needs = 0
    pno = 0
    nc = 0
    is_aa = false
    weeks = is_aa ? 1.0 : WEEKS_PER_YEAR
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
                        case = civ_sample( problem )
                        nc += 1
                        cs = @view cases[nc,:]
                        cs.hid = pers.hid
                        cs.pid = pers.pid
                        cs.data_year = pers.data_year
                        cs.pno = pers.pno
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

settings = Settings()
settings.included_data_years = [2019,2021,2022]
settings.num_households, settings.num_people, nhh2 = 
    FRSHouseholdGetter.initialise( settings; reset=true )
settings.do_legal_aid = true
LegalAidData.init( settings )

# observer = Observer(Progress("",0,0,0))
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
    println(tot)
end

hh, people = get_raw_data( settings )
probdata = rename( s->"prob_"*s, LA_PROB_DATA)
people = leftjoin( people, probdata, on=[
    :data_year=>:prob_data_year,
    :hid=>:prob_hid,
    :pno=>:prob_pno] )
rename!( hh, [
    :data_year=>:hh_data_year, 
    :hid=>:hh_hid,
    :uhid=>:hh_uhid,
    :onerand=>:hh_onerand])
people = rightjoin( people, hh, on=[
    :data_year=>:hh_data_year,
    :hid=>:hh_hid] ) # just to get weights
sys = STBParameters.get_default_system_for_fin_year( 2024 )
results = Runner.do_one_run( settings, [sys], obs )
outf = summarise_frames!( results, settings )
modelled_results = rename( s->"modelled_"*s, results.legalaid.civil.data[1])
people = leftjoin( people, modelled_results, on=[:pid=>:modelled_pid], makeunique=true ) # add baseline results
people.modelled_la_status_agg = agg_la_status.( people.modelled_la_status )
eligible_people = people[ people.modelled_la_status .!== la_none, :]
needs, cases_per_need = get_needs_and_cases( eligible_people )
costings = do_one_costing( eligible_people, cases_per_need )