using Test
using ScottishTaxBenefitModel
using .ModelHousehold: Household, Person, People_Dict, default_bu_allocation
using .ExampleHouseholdGetter
using .Definitions
using .LegacyMeansTestedBenefits: calc_legacy_means_tested_benefits, 
    LMTResults, working_for_esa_purposes
using .STBParameters: LegacyMeansTestedBenefits, IncomeRules, HoursLimits
using .GeneralTaxComponents: WEEKS_PER_YEAR

lmt = LegacyMeansTestedBenefitSystem{Float64}()


@testset "CPAG" begin
    # BASIC IT Calcaulation on

    @time names = ExampleHouseholdGetter.initialise()
    income = [110.0,145.0,325,755.0,1_000.0]

    ntests = size(income)[1]
    hh = ExampleHouseholdGetter.get_household( "example_hh3" )
    bus = get_benefit_units( hh )
    bu = bus[1]
    @test size(bus)[1] == 1
    head = bu.people[320190000901]
    spouse = bu.people[320190000902]
    head.usual_hours_worked = 0
    spouse.usual_hours_worked = 45
    @test ! search( bu, working_for_esa_purposes, lmt.hours_limits.lower )
    spouse.usual_hours_worked = 5
    @test search( bu, working_for_esa_purposes, lmt.hours_limits.lower )

    for i in 1:ntests
        pers.income[wages] = income[i]      
    end
end # t1
