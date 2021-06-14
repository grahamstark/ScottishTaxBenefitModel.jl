using Test
using Dates
using ScottishTaxBenefitModel
using .ModelHousehold: Household, Person, People_Dict, is_single,
    default_bu_allocation, get_benefit_units, get_head, get_spouse, search,
    pers_is_disabled, pers_is_carer
using .ExampleHouseholdGetter
using .Definitions
using .LegacyMeansTestedBenefits:  
    calc_legacy_means_tested_benefits!, tariff_income,
    LMTResults, is_working_hours, make_lmt_benefit_applicability,
    working_disabled, calc_allowances,
    apply_2_child_policy, calc_incomes
using .TimeSeriesUtils
using .Intermediate: MTIntermediate, make_intermediate

using .STBParameters: LegacyMeansTestedBenefitSystem, IncomeRules, HoursLimits, 
    reached_state_pension_age, state_pension_age, AgeLimits
using .Results: LMTResults, LMTCanApplyFor

## FIXME don't need both
lmt = LegacyMeansTestedBenefitSystem{Float64}()
sys = get_system( scotland=true )

@testset "Test Pension Ages" begin
    #
    # FIXME we need to jam a 'current' date on here or some of these will fail 
    # next financial year
    #
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
    # old style pension switch
    @test reached_state_pension_age(
        sys.age_limits, 
        70, 
        Male,
        sys.age_limits.savings_credit_to_new_state_pension )
    # The tests below have 'now' being 2021; tge `age_now` thing effectively jams in a Fixed
    # current date, by adding 1 to some of these ages next year and so on. Make Wholesale_trade_except_of_motor_vehicles_and_motorcycles
    # in June 2021, a 69 yo will have reached state pension age
    # but would have been 64 and so under state pension age (65) when the new state pension
    # was introduced in April 2016. Note all we have is years
    # for ages. So: 
    # hadn't reached in April 2016
    @test ! reached_state_pension_age(
        sys.age_limits, 
        age_now(69), 
        Male,
        sys.age_limits.savings_credit_to_new_state_pension )
    # reached pension age *now* 
    @test reached_state_pension_age(
        sys.age_limits, 
        age_now(69), 
        Male )
    # 68 yo woman would have been 63 in 2016, so at state pension age (63 for women)
    @test reached_state_pension_age(
        sys.age_limits, 
        age_now(68), 
        Female,
        sys.age_limits.savings_credit_to_new_state_pension )
    # ..but a 67 yo would have been 62 so too young in '16 ...
    @test ! reached_state_pension_age(
        sys.age_limits, 
        age_now(67), 
        Female,
        sys.age_limits.savings_credit_to_new_state_pension )
           

end


