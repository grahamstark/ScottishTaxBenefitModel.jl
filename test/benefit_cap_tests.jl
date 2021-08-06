using Test
using Dates

using ScottishTaxBenefitModel

using .ModelHousehold: 
    Household, 
    Person, 
    People_Dict,     
    default_bu_allocation, 
    get_benefit_units, 
    get_head, 
    get_spouse, 
    is_single,
    pers_is_carer,
    pers_is_disabled, 
    search

using .IncomeTaxCalculations: 
    calc_income_tax!

using .Definitions

using .LegacyMeansTestedBenefits:  
    LMTResults, 
    calc_allowances,
    calc_incomes, 
    calc_legacy_means_tested_benefits!, 
    calc_NDDs, 
    calc_premia,
    calculateHB_CTR!,
    calcWTC_CTC!,
    is_working_hours, 
    make_lmt_benefit_applicability, 
    tariff_income,
    working_disabled

using .LocalLevelCalculations: 
    apply_rent_restrictions, 
    calc_council_tax

using .Incomes

using .Intermediate: 
    MTIntermediate, 
    make_intermediate
   
using .STBParameters: 
    UniversalCreditSys,
    BenefitCapSys,
    LegacyMeansTestedBenefitSystem
    
using .Results: 
    BenefitUnitResult,
    HouseholdResult,
    init_household_result, 
    init_benefit_unit_result, 
    to_string

using .Utils: 
    eq_nearest_p,
    to_md_table


## FIXME don't need both
lmt = LegacyMeansTestedBenefitSystem{Float64}()
sys = get_system( scotland=true )

@testset "Benefit Cap" begin
    
    apply_benefit_cap!(
        hh.region,
        bur,
        bu,
        intermed,
        sys.bencap,
        legacy_bens
    )
  
end