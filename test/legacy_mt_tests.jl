using Test
using ScottishTaxBenefitModel
using .ModelHousehold: Household, Person, People_Dict, is_single
    default_bu_allocation, get_benefit_units, get_head, get_spouse, search
using .ExampleHouseholdGetter
using .Definitions
using .LegacyMeansTestedBenefits: calc_legacy_means_tested_benefits, 
    working_for_esa_purposes, calc_incomes
using .STBParameters: LegacyMeansTestedBenefitSystem, IncomeRules, HoursLimits
using .Results: init_benefit_unit_result, LMTResults
    
lmt = LegacyMeansTestedBenefitSystem{Float64}()


@testset "CPAG" begin
    # BASIC IT Calcaulation on

    @time names = ExampleHouseholdGetter.initialise()
    income = [110.0,145.0,325,755.0,1_000.0]

    ntests = size(income)[1]
    hh = ExampleHouseholdGetter.get_household( "example_hh1" )
    bus = get_benefit_units( hh )
    bu = bus[1]
    @test size(bus)[1] == 1
    head = get_head(bu)
    spouse = get_spouse(bu)
    head.usual_hours_worked = 0
    spouse.usual_hours_worked = 45
    println( "spouse ")
    working = search( bu, working_for_esa_purposes, lmt.hours_limits.lower )
    println( "working $working ") 
    @test working
    spouse.usual_hours_worked = 5
    spouse.employment_status = Unemployed
    head.employment_status = Unemployed
    working = search( bu, working_for_esa_purposes, lmt.hours_limits.lower )
    println( "working $working ") 

    @test ! working
    @test ! is_single( bu )
    for i in 1:ntests
        bur = init_benefit_unit_result( Float64, bu )
        spouse.income[wages] = income[i]      
        for ben in instances( LMTBenefitType )
            inc = calc_incomes(
                ben,
                bu,
                bur,
                lmt.income_rules,
                lmt.hours_limits ) 
        end
    end
end # t1
