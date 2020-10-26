using Test
using ScottishTaxBenefitModel
using .ModelHousehold: Household, Person, People_Dict, is_single,
    default_bu_allocation, get_benefit_units, get_head, get_spouse, search,
    pers_is_disabled, pers_is_carer
using .ExampleHouseholdGetter
using .Definitions
using .LegacyMeansTestedBenefits:  
    calc_legacy_means_tested_benefits!, tariff_income,
    LMTResults, is_working_hours, make_lmt_benefit_applicability,
    working_disabled, MTIntermediate, make_intermediate, calc_allowances,
    apply_2_child_policy, calc_incomes
using .TimeSeriesUtils

using .STBParameters: LegacyMeansTestedBenefitSystem, IncomeRules, HoursLimits, 
    reached_state_pension_age, state_pension_age, AgeLimits
using .Results: init_benefit_unit_result, LMTResults, LMTCanApplyFor
using Dates

## FIXME don't need both
lmt = LegacyMeansTestedBenefitSystem{Float64}()
sys = get_system( scotland=true )

@testset "Test Pension Ages" begin
    
    @test state_pension_age(sys.age_limits,Male) == 65
    
    @test state_pension_age(sys.age_limits,Female,2015) == 62
    @test state_pension_age(sys.age_limits,Female,2045) == 67
    @test state_pension_age(sys.age_limits,Female,2046) == 68
    @test state_pension_age(sys.age_limits,Male,2046) == 68
    
    @test reached_state_pension_age(sys.age_limits,65,Male)
    @test reached_state_pension_age(sys.age_limits,65,Female)
    @test ! reached_state_pension_age(sys.age_limits,62,Female, Date( 2022, 01, 01))
    # A person who's 67 now will have reached pension age 
    # by then.
    @test reached_state_pension_age(sys.age_limits,67, Male, Date( 2046, 01, 01))
    # since this is financial year
    @test reached_state_pension_age(sys.age_limits,68, Male, 2046 )
    

end


