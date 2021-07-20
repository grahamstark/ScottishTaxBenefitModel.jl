using Test
using ScottishTaxBenefitModel
using .ModelHousehold: Household, Person, People_Dict, is_single,
    default_bu_allocation, get_benefit_units, get_head, get_spouse, search,
    pers_is_disabled, pers_is_carer
using .ExampleHouseholdGetter
using .Definitions
using .LegacyMeansTestedBenefits:  
    calc_legacy_means_tested_benefits!, tariff_income,
    LMTResults, is_working_hours, make_lmt_benefit_applicability, calc_premia,
    working_disabled, calc_allowances,
    apply_2_child_policy, calc_incomes, calc_NDDs, calculateHB_CTR!

using .Intermediate: MTIntermediate, make_intermediate    
    
using .STBParameters: LegacyMeansTestedBenefitSystem, IncomeRules, HoursLimits
using .Results: LMTResults, LMTCanApplyFor, init_household_result
using Dates
using DataFrames
using CSV

## FIXME don't need both
lmt = LegacyMeansTestedBenefitSystem{Float64}()
sys = get_system( scotland=true )


"""
Extract a household from 
"""
function spreadsheet_ss_example( key :: AbstractString ) :: NamedTuple
    re = r"([A-Z0-9a-z\-]+)_([0-9]+)k"        
    m = match( re, key )
    fam = m[1]
    n = m[2]
    examples = get_ss_examples()
    name = ""
    subtype = ""
    m2 = match( r"(.*)-(.*)", fam )
    if m2 !== nothing
        fam = m2[1]
        subtype = m2[2]
    end
    hh = nothing
    rent = 600/4
    ct = 123.25/4
    earn = (1000*parse( Float64, n ))/52.0
    earn = round(earn, digits=2)
    
    if fam == "B"
        name = "Basic Case"
        hh = examples[cpl_w_2_children_hh]
        bu = get_benefit_units(hh)[1]
        spouse = get_spouse( bu )
        head = get_head( bu ) 
        head.age = 40
        head.usual_hours_worked = 40        
        head.income[wages]=earn
            
    elseif fam == "K3"
        name = "3 Kids"
        hh = examples[cpl_w_2_children_hh]
    elseif fam == "SP"
        name = "Single Parent"
        hh = examples[single_parent_hh]
    elseif fam == "SE2"
        name = "Single Earner"
        hh = examples[cpl_w_2_children_hh]
    elseif fam == "2C"
        name = "Basic; 2 child limit test"
        hh = examples[cpl_w_2_children_hh]
    elseif fam == "2E"
        name = "2 Earner"
        hh = examples[cpl_w_2_children_hh]
    elseif fam == "CC"
        name = "Child Care"
        hh = examples[cpl_w_2_children_hh]
    elseif fam == "DC"
        name = "Disabled Child"
        hh = examples[cpl_w_2_children_hh]
    elseif fam == "DA" 
        name = "Disabled Adult"
        hh = examples[cpl_w_2_children_hh]
    elseif fam == "CL"
        name = "Childless"
        hh = examples[childless_couple_hh]
    else
        error( "unknown key $fam " )
    end
    name = "$name :: $(earn)p.w."
    hh.gross_rent = rent
    hh.council_tax = ct
    return ( name=name, hh=hh )
end



@testset "Complete SS Tests - Legacy System" begin
    sys = get_system( scotland = true )
    df=CSV.File( "$(@__DIR__)/../docs/uc_test_cases_main_results_transposed.csv")|>DataFrame
    keys = split("B_7k,B_4k,B_12k,B_17k,B_22k,B_30k,B_50k,K3_7k,K3_12k,K3_12k,SP_7k,SP_12k,SP_30k,2C-a_7k,2C-b_7k,2C-c_7k,2C-c_22k,SE2_17k,2E_17k,2E_2k,SP-CC_7k,SP-CC_17k,SP-CC_22k,DC-a_7k,DC-b_7k,DC-b_22k,DA-a_7k,DA-b_7k,DA-b_22k,CL_7k,CL_12k,CL_22k", "," )
    for k in keys 
        println( "on key $k ")
        name,hh = spreadsheet_ss_example( k ) 
        println( "name=$name" )
        res = df[df.Key.==k,:][1,:]
        println( res.CTB_NEW )
        hhres = init_household_result( hh )  
        intermed = make_intermediate(
            hh,
            sys.hours_limits,
            sys.age_limits )
        calc_legacy_means_tested_benefits!(
            hhres,
            hh,   
            intermed,
            sys.lmt,
            sys.age_limits,
            sys.hours_limits,
            sys.hr )
    end
end