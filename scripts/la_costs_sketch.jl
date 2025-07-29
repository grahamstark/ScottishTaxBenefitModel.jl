using ScottishTaxBenefitModel

using .LegalAidData
using .RunSettings
using .FRSHouseholdGetter

using StatsBase
using CSV
using DataFrames

include( "comparisons_skeleton.jl")

SCJS_SLAB_MAP = Dict([
    :civ_family => 
        ["Abusive Behaviour and Sexual Harm (Scotland) Act",
        "Non  Harassment Order",
        "Protection From Abuse (Scotland) Act 2001",
        "Non Harassment Order Family",
        "Interdict Non-Molestation"],

    :civ_education => 
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

    :civ_divorce => 
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

    :civ_housing => 
        ["Judicial Review - Housing/Homelessness",
        "Reparation - housing disrepair",
        "Transfer of Tenancy"],

    :civ_mental  => 
        ["Adults With Incapacity (Scotland) Act 2000",
        "Adults with Incapacity (Scotland) Act 2000 - Welfare, or Welfare and Financial Component",
        "Home owners and debtor protection - defence"],

    :civ_immigration => 
        ["Judicial Review Immigration Proceedings",
        "Residence"],

    :civ_neighbours => 
        ["Interdict - Neighbour Disputes"],

    :civ_medical  => #  medical negligence in last 3 years => 
        ["Reparation - Medical Negligence",
        "Reparation - Other/Damages"],

    :civ_injury  => # problems concerning your health and well-being: injury because of an accident in last 3 years => 
        ["Reparation - Personal Injury"],

    :civ_money_debt => # cvjmon #  problems concerning your money, finances or anything you’ve paid for: with money and debt in last 3 years => 
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
        "Reparation - Professional Negligence (Non Medical)"],

    :civ_benefit => [],

    :civ_faulty_goods => 
        ["Delivery Of Goods"],

    :civ_discrimination  => 
        ["Other Discrimination Based Cases (Other than DDA)"],

    :civ_police => 
        ["Power of Arrest"],

    :civ_employment => 
        ["Employment Appeal Tribunal"],

    :civ_others => 
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
        "Exclusion Order",
        "Fatal Accident Inquiry",
        "Hague Convention Application",
        "Judicial Review",
        "Judicial Review - against Scottish Ministers",
        "Judicial Review against the Scottish Legal Aid Board",
        "Other Convention Application",
        "Petitions (Other Than For Judicial Review)",
        "Variation"] ])

settings = Settings()
LegalAidData.init( settings )

settings.num_households, settings.num_people, nhh2 = 
    FRSHouseholdGetter.initialise( settings; reset=false )

const N = size( CIVIL_COSTS)[1]
const GROUPS_BY_CASE = groupby( CIVIL_COSTS, :hsm_censored )

function civ_sample( casetype :: Symbol )::DataFrameRow
    subset = CIVIL_COSTS[ CIVIL_COSTS.categorydescription  .∈ ( SCJS_SLAB_MAP[casetype], ), :]
    # @show subset
    n = size(subset)[1]
    p = sample(1:n)    
    # @show n p
    return subset[p,:]
    # sample(CIVIL_COSTS[CIVIL_COSTS.hsm_censored .== casetype,:]
end

needs = Dict()
cases_per_need = Dict()
for problem in PROBLEM_TYPES[2:end]
    sym = Symbol( "$(problem)_prediction")
    needs[sym] = sum( LA_PROB_DATA[:,sym], Weights( LA_PROB_DATA.weight ))
    cases_per_need[sym] = N/(needs[sym]*7)
end

@show needs
@show cases_per_need

cases = deepcopy( CIVIL_COSTS )[1:0,:]
for hno in 1:settings.num_households
    global cases
    hh = get_household( hno )
    LegalAidData.add_la_probs!( hh )
    reps = Int( round( hh.weight ))
    for i in 1:reps
        for (pid, pers) in hh.people
            for problem in PROBLEM_TYPES[2:end]
                sym = Symbol( "$(problem)_prediction")
                slabsym = Symbol( "civ_$(problem)")
                prob = pers.legal_aid_problem_probs[sym]
                rn1 = rand()
                rn2 = rand()
                # @show rn1 rn2 prob problem 
                if rn1 < prob           
                    if rn2 < cases_per_need[sym]
                        case = civ_sample( slabsym )
                        # @show case
                        push!( cases, case )
                    end
                end
            end # problem 
        end # people
    end
end