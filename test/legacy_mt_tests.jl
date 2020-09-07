using Test
using ScottishTaxBenefitModel
using .ModelHousehold: Household, Person, People_Dict, is_single,
    default_bu_allocation, get_benefit_units, get_head, get_spouse, search,
    pers_is_disabled, pers_is_carer, make_lmt_benefit_applicability
using .ExampleHouseholdGetter
using .Definitions
using .LegacyMeansTestedBenefits: calc_legacy_means_tested_benefits, 
    is_working, calc_incomes, tariff_income
using .STBParameters: LegacyMeansTestedBenefitSystem, IncomeRules, HoursLimits
using .Results: init_benefit_unit_result, LMTResults
    
lmt = LegacyMeansTestedBenefitSystem{Float64}()


@testset "CPAG income and capital chapters 20, 21, 22, 23" begin
    
    income = [110.0,145.0,325,755.0,1_000.0]

    #  basic check of tariff incomes; cpag ch 21 ?? page
    caps = Dict(2000=>0,6000=>0,6000.01=>1, 6253=>2,8008=>9)
    for (c,t) in caps
        ci = tariff_income(c, 
            lmt.income_rules.capital_min,
            lmt.income_rules.capital_tariff)
        println("ci=$ci t=$t c=$c")
        @test (ci == t) 
    end

    ntests = size(income)[1]

    examples = get_ss_examples()

    for (hht,hh) in examples 
        println( "on hhld '$hht'")
        bus = get_benefit_units( hh )
        bu = bus[1]
        @test size(bus)[1] == 1
        spouse = nothing
        head = get_head(bu)
        hdwork = is_working( head, lmt.hours_limits.lower )
        head.usual_hours_worked = 5
        head.employment_status = Unemployed
        if hht in [cpl_w_2_kids_hh childless_couple_hh]
            spouse = get_spouse(bu)
            spouse.employment_status = Full_time_Employee
            spouse.usual_hours_worked = 45
            working = search( bu, is_working, lmt.hours_limits.lower )
            println( "working $working ") 
            @test working
            spouse.usual_hours_worked = 5
            spouse.employment_status = Unemployed
            spwork = is_working( spouse, lmt.hours_limits.lower )
            working = search( bu, is_working, lmt.hours_limits.lower )
            println( "working $working spwork $spwork hdwork $hdwork") 
            @test ! working
            @test ! is_single( bu )
        end
        head.usual_hours_worked = 0
        head.employment_status = Unemployed
        for i in 1:ntests
            if spouse !== nothing
                spouse.income[wages] = income[i]   
            else
                head.income[wages] = income[i]
            end
            for ben in [esa hb is jsa pc]
                bur = init_benefit_unit_result( Float64, bu )
                println("on $ben")
                inc = calc_incomes(
                    ben,
                    bu,
                    bur,
                    lmt.income_rules,
                    lmt.hours_limits ) 
                @test inc.tariff_income ≈ 0.0
                # cpl_w_2_kids_hh single_parent_hh single_hh childless_couple_hh

                if hht == single_parent_hh
                    if ben == hb
                        @test inc.disregard == 25.0
                    else
                        @test inc.disregard == 20.0
                    end
                elseif hht == cpl_w_2_kids_hh 
                    if ben == hb
                        @test inc.disregard == 10.0
                    elseif ben == esa
                        @test inc.disregard == 20.0
                    else
                        @test inc.disregard == 10.0
                    end

                end
                ## TODO: finish income tests ..
                # println( "inc res for wage $(income[i])ben $ben = \n $inc") 
            end # bens loop
        end # incomes loop
    end # households loop

    # Evan and Mia example p 433
    e_and_m = get_benefit_units( examples[cpl_w_2_kids_hh] )[1]
    emr = init_benefit_unit_result( Float64, e_and_m )
    evan = get_head( e_and_m )
    mia = get_spouse( e_and_m )
    empty!(mia.income)
    mia.income[wages] = 136.0
    mia.usual_hours_worked = 17
    empty!(evan.income)
    evan.income[employment_and_support_allowance] = 1.0
    @test Results.has_income( e_and_m, emr, employment_and_support_allowance )
    inc = calc_incomes(
        hb,
        e_and_m,
        emr,
        lmt.income_rules,
        lmt.hours_limits ) 
    @test inc.net_earnings ≈ 98.90
    @test inc.total_income ≈ 99.90
    @test inc.disregard ≈ 37.10
    

end # test set

@testset "Applicability Tests" begin


end
