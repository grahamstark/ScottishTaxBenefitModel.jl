using Test
using Revise
using ScottishTaxBenefitModel
using .ModelHousehold: Household, Person, People_Dict, is_single,
    default_bu_allocation, get_benefit_units, get_head, get_spouse, search,
    pers_is_disabled, pers_is_carer
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

    for hhn in ["example_hh1", "single_parent_1"]
        println( "on hhld '$hhn'")
        hh = ExampleHouseholdGetter.get_household( hhn )
        bus = get_benefit_units( hh )
        bu = bus[1]
        @test size(bus)[1] == 1
        head = get_head(bu)
        spouse = get_spouse(bu)
        head.usual_hours_worked = 0
        if spouse !== nothing
            spouse.employment_status = Full_time_Employee
            spouse.usual_hours_worked = 45
        end
        working = search( bu, working_for_esa_purposes, lmt.hours_limits.lower )
        println( "working $working ") 
        head.employment_status = Unemployed
        if spouse !== nothing
            spouse.usual_hours_worked = 5
            spouse.employment_status = Unemployed
        end
        @test working
        working = search( bu, working_for_esa_purposes, lmt.hours_limits.lower )
        println( "working $working ") 

        @test ! working
        @test ! is_single( bu )
        for i in 1:ntests
            bur = init_benefit_unit_result( Float64, bu )
            if spouse !== nothing
                spouse.income[wages] = income[i]   
            else
                head.income[wages] = income[i]
            end
            for ben in [esa hb is jsa pc]
                println("on $ben")
                inc = calc_incomes(
                    ben,
                    bu,
                    bur,
                    lmt.income_rules,
                    lmt.hours_limits ) 
                @test inc.tariff_income ≈ 0.0
                if hhn == "single_parent_1"
                    if ben == hb
                        @test inc.disregard == 25.0
                    else
                        @test inc.disregard == 20.0
                    end
                elseif hhn == "example_hh1" # couple w. kids
                    if ben == hb
                        @test inc.disregard == 10.0
                    elseif ben == esa
                        @test inc.disregard == 20.0
                    else
                        @test inc.disregard == 10.0
                    end

                end 
            end # bens loop
        end # incomes loop
    end # households loop
end # test set
