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
    working_disabled, MTIntermediate, make_intermediate, calc_allowances,
    apply_2_child_policy, calc_incomes, calc_NDDs, calculateHB_CTR!

using .STBParameters: LegacyMeansTestedBenefitSystem, IncomeRules, HoursLimits
using .Results: init_benefit_unit_result, LMTResults, LMTCanApplyFor, init_household_result
using Dates

## FIXME don't need both
lmt = LegacyMeansTestedBenefitSystem{Float64}()
sys = get_system( scotland=true )

@testset "2 child policy" begin
    examples = get_ss_examples()
    sparent = get_benefit_units(examples[single_parent_hh])[1]
    println( sparent.children )
    @test num_children( sparent ) == 2
    @test apply_2_child_policy( sparent ) == 2
    np = add_child!( sparent, 10, Female );
    @test num_children( sparent ) == 3
    @test apply_2_child_policy( sparent ) == 3
    np = add_child!( sparent, 1, Female );
    @test num_children( sparent ) == 4  
    @test apply_2_child_policy( sparent ) == 3
    @test apply_2_child_policy( sparent, child_limit=5 ) == 4
    @test apply_2_child_policy( sparent, start_date=Date(2000,4,6) ) == 2
end
    
@testset "CPAG income and capital chapters 20, 21, 22, 23" begin
    
    examples = get_ss_examples()
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

    
    for (hht,hh) in examples 
        println( "on hhld '$hht'")
        bus = get_benefit_units( hh )
        bu = bus[1]
        intermed = make_intermediate( 
            1,
            bu,  
            lmt.hours_limits,
            sys.age_limits )

        @test size(bus)[1] == 1
        spouse = nothing
        head = get_head(bu)
        hdwork = is_working_hours( head, lmt.hours_limits.lower )
        head.usual_hours_worked = 5
        head.employment_status = Unemployed
        if hht in [cpl_w_2_children_hh childless_couple_hh]
            spouse = get_spouse(bu)
            spouse.employment_status = Full_time_Employee
            spouse.usual_hours_worked = 45
            working = search( bu, is_working_hours, lmt.hours_limits.lower )
            println( "working $working ") 
            @test working
            spouse.usual_hours_worked = 5
            spouse.employment_status = Unemployed
            spwork = is_working_hours( spouse, lmt.hours_limits.lower )
            working = search( bu, is_working_hours, lmt.hours_limits.lower )
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
                    intermed,
                    lmt.income_rules,
                    lmt.hours_limits ) 
                @test inc.tariff_income ≈ 0.0
                # cpl_w_2_children_hh single_parent_hh single_hh childless_couple_hh

                if hht == single_parent_hh
                    if ben == hb
                        @test inc.disregard == 25.0
                    else
                        @test inc.disregard == 20.0
                    end
                elseif hht == cpl_w_2_children_hh 
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
    e_and_m = get_benefit_units( examples[cpl_w_2_children_hh] )[1]
    emr = init_benefit_unit_result( Float64, e_and_m )
    evan = get_head( e_and_m )
    mia = get_spouse( e_and_m )
    intermed = make_intermediate( 
        1,
        e_and_m,  
        lmt.hours_limits,
        sys.age_limits )
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
        intermed,
        lmt.income_rules,
        lmt.hours_limits ) 
    @test inc.net_earnings ≈ 98.90
    @test inc.total_income ≈ 99.90
    @test inc.disregard ≈ 37.10
    

end # test set

@testset "Applicability Tests" begin
    # reset the examples
    examples = get_ss_examples()
    cpl = get_benefit_units(examples[cpl_w_2_children_hh])[1]
    sparent = get_benefit_units(examples[single_parent_hh])[1]
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    eligs_cpl = make_lmt_benefit_applicability( intermed, sys.lmt.hours_limits )
    head = get_head( cpl )
    println( "head=$head")
    spouse = get_spouse( cpl )
    println( "sp=$spouse" )
    println( "couple $eligs_cpl" )
    @test ! eligs_cpl.esa
    # @test ! eligs_cpl.hb 
    @test ! eligs_cpl.is
    @test ! eligs_cpl.jsa
    @test ! eligs_cpl.pc 
    @test ! eligs_cpl.ndds
    @test eligs_cpl.wtc 
    @test eligs_cpl.ctr 
    #2 not_working couple - jsa
    unemploy!( head )
    unemploy!( spouse )
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    eligs_cpl = make_lmt_benefit_applicability( intermed, sys.lmt.hours_limits )
    println( "not_working: sp=$spouse" )
    println( "not_working couple $eligs_cpl" )
    @test ! eligs_cpl.esa
    # @test ! eligs_cpl.hb 
    @test ! eligs_cpl.is
    @test eligs_cpl.jsa
    @test ! eligs_cpl.pc 
    @test ! eligs_cpl.ndds
    @test ! eligs_cpl.wtc 
    @test eligs_cpl.ctr 
    
    disable_slightly!( spouse )
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    eligs_cpl = make_lmt_benefit_applicability( intermed, sys.lmt.hours_limits )
    println( "not_working: sp=$spouse" )
    println( "not_working couple $eligs_cpl" )
    @test eligs_cpl.esa
    # @test ! eligs_cpl.hb 
    @test ! eligs_cpl.is
    @test eligs_cpl.ctr 
    enable!( spouse )
    unemploy!( spouse )
    carer!( spouse )
    carer!( head )
    println( "head.employment_status=$(head.employment_status) spouse.employment_status=$(spouse.employment_status)")
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    eligs_cpl = make_lmt_benefit_applicability( intermed, sys.lmt.hours_limits )
    println( eligs_cpl )
    @test ! eligs_cpl.esa
    @test eligs_cpl.is
    @test eligs_cpl.ctr 
    @test ! eligs_cpl.wtc
    
    intermed = make_intermediate( 
        1,
        sparent,  
        sys.lmt.hours_limits,
        sys.age_limits )
    eligs_sp = make_lmt_benefit_applicability( intermed, sys.lmt.hours_limits )
    println( "single parent $eligs_sp" )
    @test ! eligs_sp.is
    @test ! eligs_sp.jsa
    @test ! eligs_sp.pc 
    @test ! eligs_sp.ndds
    @test eligs_sp.wtc 
    @test eligs_sp.ctr 
    head = get_head( sparent )
    unemploy!( head )
    intermed = make_intermediate( 
        1,
        sparent,  
        sys.lmt.hours_limits,
        sys.age_limits )
    eligs_sp = make_lmt_benefit_applicability( intermed, sys.lmt.hours_limits )
    println( "single parent $eligs_sp" )
    @test ! eligs_sp.is
    @test eligs_sp.jsa
    @test ! eligs_sp.pc 
    @test ! eligs_sp.ndds
    @test ! eligs_sp.wtc 
    @test eligs_sp.ctr 
    carer!( head )
    intermed = make_intermediate( 
        1,
        sparent,  
        sys.lmt.hours_limits,
        sys.age_limits )
    eligs_sp = make_lmt_benefit_applicability( intermed, sys.lmt.hours_limits )
    println( "single parent $eligs_sp" )
    @test eligs_sp.is
    @test ! eligs_sp.jsa
    @test ! eligs_sp.pc 
    @test ! eligs_sp.ndds
    @test ! eligs_sp.wtc 
    @test eligs_sp.ctr 
    head.age = 70
    intermed = make_intermediate( 
        1,
        sparent,  
        sys.lmt.hours_limits,
        sys.age_limits )
    eligs_sp = make_lmt_benefit_applicability( intermed, sys.lmt.hours_limits )
    println( "single parent $eligs_sp" )
    @test ! eligs_sp.is
    @test ! eligs_sp.jsa
    @test eligs_sp.pc 
    @test ! eligs_sp.ndds
    @test ! eligs_sp.wtc  
    @test eligs_sp.ctr 
    retire!( head )
    intermed = make_intermediate( 
        1,
        sparent,  
        sys.lmt.hours_limits,
        sys.age_limits )
    eligs_sp = make_lmt_benefit_applicability( 
        intermed, 
        sys.lmt.hours_limits )
    @test ! eligs_sp.is
    @test ! eligs_sp.jsa
    @test eligs_sp.pc 
    @test ! eligs_sp.ndds
    @test ! eligs_sp.wtc  # this is right - could be on both ctr and wtc
    @test eligs_sp.ctr 
    employ!( head )
    intermed = make_intermediate( 
        1,
        sparent,  
        sys.lmt.hours_limits,
        sys.age_limits )
    eligs_sp = make_lmt_benefit_applicability( intermed, sys.lmt.hours_limits )
    @test ! eligs_sp.is
    @test ! eligs_sp.jsa
    @test eligs_sp.pc 
    @test ! eligs_sp.ndds
    @test eligs_sp.wtc  # this is right - could be on both pc and wtc
    @test eligs_sp.ctr 
    
end

@testset "Intermediates" begin
    examples = get_ss_examples()
    sys = get_system( scotland=true )
    cpl = get_benefit_units(examples[cpl_w_2_children_hh])[1]
    spouse = get_spouse( cpl )
    head = get_head( cpl )
    println( "sp=$spouse" )
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    println( intermed )
    @test ! intermed.someone_pension_age
    @test ! intermed.all_pension_age
    @test intermed.working_ft
    @test intermed.num_working_pt == 0
    @test intermed.num_working_24_plus == 2
    @test intermed.total_hours_worked > 40
    @test ! intermed.is_carer
    @test ! intermed.is_sparent
    @test ! intermed.is_sing
    @test ! intermed.is_disabled
    @test intermed.num_children > 1
    @test intermed.ge_16_u_pension_age
    @test ! intermed.limited_capacity_for_work
    @test intermed.has_children
    @test intermed.economically_active
    @test intermed.num_working_full_time == 2
    @test intermed.num_not_working == 0
    @test intermed.num_working_part_time == 0
    
    unemploy!( head )
    unemploy!( spouse )
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    @test ! intermed.someone_pension_age
    @test ! intermed.all_pension_age
    @test ! intermed.working_ft
    @test intermed.num_working_pt == 0
    @test intermed.num_working_24_plus == 0
    @test intermed.total_hours_worked == 0
    @test ! intermed.is_carer
    @test ! intermed.is_sparent
    @test ! intermed.is_sing
    @test ! intermed.is_disabled
    @test intermed.num_children > 1
    @test intermed.ge_16_u_pension_age
    @test ! intermed.limited_capacity_for_work
    @test intermed.has_children
    @test intermed.economically_active # not_working is active
    @test intermed.num_working_full_time == 0
    @test intermed.num_not_working == 2
    @test intermed.num_working_part_time == 0
    
    disable_slightly!( spouse )
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    @test ! intermed.working_ft
    @test intermed.num_working_pt == 0
    @test intermed.num_working_24_plus == 0
    @test intermed.total_hours_worked == 0
    @test ! intermed.is_carer
    @test ! intermed.is_sparent
    @test ! intermed.is_sing
    @test intermed.is_disabled
    @test intermed.num_children == 2
    @test intermed.ge_16_u_pension_age
    @test intermed.limited_capacity_for_work
    @test intermed.has_children
    @test intermed.economically_active # not_working is active
    @test intermed.num_working_full_time == 0
    @test intermed.num_not_working == 2 # ! 1 not_working/1 inactive?
    @test intermed.num_working_part_time == 0
    
    carer!( head )
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    @test ! intermed.working_ft
    @test intermed.num_working_pt == 0
    @test intermed.num_working_24_plus == 0
    @test intermed.total_hours_worked == 0
    @test intermed.is_carer
    @test ! intermed.is_sparent
    @test ! intermed.is_sing
    @test intermed.is_disabled
    @test intermed.num_children == 2
    @test intermed.ge_16_u_pension_age
    @test intermed.limited_capacity_for_work
    @test intermed.has_children
    @test ! intermed.economically_active # not_working is active
    @test intermed.num_working_full_time == 0
    @test intermed.num_not_working == 2 # ! 1 not_working/1 inactive?
    @test intermed.num_working_part_time == 0

    sparent = get_benefit_units(examples[single_parent_hh])[1]
    intermed = make_intermediate( 
        1,
        sparent,  
        sys.lmt.hours_limits,
        sys.age_limits )
    @test intermed.working_ft
    @test intermed.num_working_pt == 0
    @test intermed.num_working_24_plus == 1
    @test intermed.total_hours_worked >= 40
    @test ! intermed.is_carer
    @test intermed.is_sparent
    @test ! intermed.is_sing
    @test ! intermed.is_disabled
    @test intermed.num_children > 0
    @test intermed.ge_16_u_pension_age
    @test ! intermed.limited_capacity_for_work
    @test intermed.has_children
    @test intermed.economically_active # not_working is active
    @test intermed.num_working_full_time == 1
    @test intermed.num_not_working == 0 # ! 1 not_working/1 inactive?
    @test intermed.num_working_part_time == 0
    @test ! intermed.working_disabled
        
end

@testset "Allowances" begin
    examples = get_ss_examples()
    sys = get_system( scotland=true )

end

@testset "NDDS" begin
    sys = get_system( scotland=true )
    examples = get_ss_examples()
    spers = get_benefit_units(examples[single_hh])[1]
    head = get_head( spers ) # the only person, obvs..
    head.age = 30
    empty!(head.income)
    bur = init_benefit_unit_result( Float64, spers )
    wage = [600.0,400,200,0]
    ndds = [100.65, 91.70, 35.85, 15.60]
    nt = size(wage)[1]
    employ!( head )
    println( "FT Employed")
    println( head )
    for i in 1:nt
        head.income[wages] = wage[i]
        intermed = make_intermediate( 
            1,
            spers,  
            sys.lmt.hours_limits,
            sys.age_limits )
        incomes = calc_incomes(
            hb,
            spers,
            bur,
            intermed,
            sys.lmt.income_rules,
            sys.lmt.hours_limits )  
        ndd = calc_NDDs( spers, bur, intermed, incomes, sys.lmt.hb )
        @test ndd ≈ ndds[i]
    end # loop round various incomes
    println( "Unemployed")
    unemploy!( head )
    for i in 1:nt
        head.income[wages] = wage[i]
        intermed = make_intermediate( 
            1,
            spers,  
            sys.lmt.hours_limits,
            sys.age_limits )
        incomes = calc_incomes(
            hb,
            spers,
            bur,
            intermed,
            sys.lmt.income_rules,
            sys.lmt.hours_limits )  
        ndd = calc_NDDs( spers, bur, intermed, incomes, sys.lmt.hb )
        @test ndd ≈ ndds[nt]
    end # loop round various incomes, unemployed
    disable_slightly!( head )
    head.income[attendence_allowance] = 100.0
    println( "Disabled")
    for i in 1:nt
        head.income[wages] = wage[i]
        intermed = make_intermediate( 
            1,
            spers,  
            sys.lmt.hours_limits,
            sys.age_limits )
        incomes = calc_incomes(
            hb,
            spers,
            bur,
            intermed,
            sys.lmt.income_rules,
            sys.lmt.hours_limits )  
        ndd = calc_NDDs( spers, bur, intermed, incomes, sys.lmt.hb )
        @test ndd ≈ 0.0
    end # loop ro
    empty!(head.income)
    enable!( head )
    blind!( head )
    println( "Blind")
    for i in 1:nt
        head.income[wages] = wage[i]
        intermed = make_intermediate( 
            1,
            spers,  
            sys.lmt.hours_limits,
            sys.age_limits )
        incomes = calc_incomes(
            hb,
            spers,
            bur,
            intermed,
            sys.lmt.income_rules,
            sys.lmt.hours_limits )  
        ndd = calc_NDDs( spers, bur, intermed, incomes, sys.lmt.hb )
        @test ndd ≈ 0.0
    end # loop ro
    # couples 
    cpl = get_benefit_units(examples[cpl_w_2_children_hh])[1]
    spouse = get_spouse( cpl )
    head = get_head( cpl )
    employ!( spouse )
    empty!( head.income )
    unemploy!( head )
    bur = init_benefit_unit_result( Float64, cpl )
    println( "FT Employed")
    println( spouse )
    for i in 1:nt
        spouse.income[wages] = wage[i]
        intermed = make_intermediate( 
            1,
            cpl,  
            sys.lmt.hours_limits,
            sys.age_limits )
        incomes = calc_incomes(
            hb,
            cpl,
            bur,
            intermed,
            sys.lmt.income_rules,
            sys.lmt.hours_limits )  
        ndd = calc_NDDs( cpl, bur, intermed, incomes, sys.lmt.hb )
        @test ndd ≈ ndds[i]
    end # loop round various incomes
    employ!( head )
    for i in 1:nt
        spouse.income[wages] = wage[i] / 3.0
        head.income[wages] = wage[i] *2 / 3.0
        intermed = make_intermediate( 
            1,
            cpl,  
            sys.lmt.hours_limits,
            sys.age_limits )
        incomes = calc_incomes(
            hb,
            cpl,
            bur,
            intermed,
            sys.lmt.income_rules,
            sys.lmt.hours_limits )  
        ndd = calc_NDDs( cpl, bur, intermed, incomes, sys.lmt.hb )
        @test ndd ≈ ndds[i]
    end # loop round various incomes
    
    # no NDDs for CTB (I think)
    bur = init_benefit_unit_result( Float64, spers )
    head = get_head( spers )
    employ!( head )
    println( "FT Employed - CTB")
    println( head )
    for i in 1:nt
        head.income[wages] = wage[i]
        intermed = make_intermediate( 
            1,   
            spers,  
            sys.lmt.hours_limits,
            sys.age_limits )
        incomes = calc_incomes(
            hb,
            spers,
            bur,
            intermed,
            sys.lmt.income_rules,
            sys.lmt.hours_limits )  
        ndd = calc_NDDs( spers, bur, intermed, incomes, sys.lmt.ctb )
        @test ndd ≈ 0.0
    end # loop round various incomes
end

@testset "HB/CTB" begin
    # CPAG 19/20 p190
    sys = get_system( scotland=true )
    examples = get_ss_examples()
    joplings = examples[childless_couple_hh]
    jbu = get_benefit_units(joplings)[1]
    spouse = get_spouse( jbu )
    head = get_head( jbu )
    empty!( spouse.income )
    empty!( head.income )
    employ!( spouse )
    unemploy!( head )
    joplings.gross_rent = 120.00 # eligible rent
    spouse.income[wages] = 201.75
    spouse.usual_hours_worked = 21
    head.income[wages] = 73.10 # FIXME needs to be jobseekers_allowance] = 73.10
    hhres = init_household_result( joplings )
    calculateHB_CTR!( 
        hb, 
        hhres, 
        joplings.gross_rent, 
        joplings,
        sys.lmt, 
        sys.age_limits )
    println( "MTBens for Joblings:\n$(hhres.bus[1].legacy_mtbens)\n" )
    println( "Incomes $(hhres.bus[1].legacy_mtbens.hb_incomes)\n")
    @test hhres.bus[1].legacy_mtbens.hb ≈ 22.50
    
    mr_h = examples[single_hh]
    mrhbu = get_benefit_units(mr_h)[1]
    head = get_head( mrhbu )
    retire!( head )
    empty!( head.income )
    head.age = 67
    head.income[private_pensions]=60.0
    head.income[state_pension]=127.75
    mr_h.gross_rent = 88.50
    hhres = init_household_result( mr_h )
    calculateHB_CTR!( 
        hb, 
        hhres, 
        mr_h.gross_rent, 
        mr_h,
        sys.lmt, 
        sys.age_limits )
    println( "MTBens for Mr. H:\n$(hhres.bus[1].legacy_mtbens)\n" )
    println( "Incomes $(hhres.bus[1].legacy_mtbens.hb_incomes)\n")
    println( "premiums $(hhres.bus[1].legacy_mtbens.premiums)\n")
    @test length( hhres.bus[1].legacy_mtbens.premiums ) == 0
    @test hhres.bus[1].legacy_mtbens.hb_allowances == 181.00
    @test to_nearest_p( hhres.bus[1].legacy_mtbens.hb, 84.11 )
    
end

@testset "Allowances" begin
    sys = get_system( scotland=true )
    examples = get_ss_examples()
    sing = examples[single_hh]
    singbu = get_benefit_units(sing)[1]
    head = get_head( singbu )
    head.age = 25
    empty!( head.income )
    intermed = make_intermediate( 
            1,   
            singbu,  
            sys.lmt.hours_limits,
            sys.age_limits )

    for ben in [hb,ctr,is,jsa,esa]
        allow = calc_allowances(
            ben,
            intermed,
            sys.lmt.allowances,
            sys.age_limits
        )
        @test allow ==  sys.lmt.allowances.age_25_and_over
    end
    head.age = 17
    intermed = make_intermediate( 
            1,   
            singbu,  
            sys.lmt.hours_limits,
            sys.age_limits )
    for ben in [hb,ctr,is,jsa,esa]
        allow = calc_allowances(
            ben,
            intermed,
            sys.lmt.allowances,
            sys.age_limits
        )
        @test allow ==  sys.lmt.allowances.age_18_24 # you get the 18 except in odd cases; cpag p336
    end
    #
    # 17 yo single parent - should be same as single
    #
    
    spar = examples[single_parent_hh]
    sparbu = get_benefit_units(spar)[1]
    head = get_head(sparbu) 
    
    intermed = make_intermediate( 
            1,   
            sparbu,  
            sys.lmt.hours_limits,
            sys.age_limits )
    head.age = 17
    intermed = make_intermediate( 
            1,   
            sparbu,  
            sys.lmt.hours_limits,
            sys.age_limits )
    @test intermed.num_children == 2
    @test intermed.num_allowed_children == 2
    for ben in [hb,ctr,is,jsa,esa]
        allow = calc_allowances(
            ben,
            intermed,
            sys.lmt.allowances,
            sys.age_limits
        )
        println( "on $ben allow=$allow" )
        if ben in [hb,ctr]
            @test allow == sys.lmt.allowances.age_18_24 + 2*sys.lmt.allowances.child        
        else
            @test allow ==  sys.lmt.allowances.age_18_24 # you get the 18 except in odd cases; cpag p336
        end
    end
    #
    # funny age combinations
    # a) 2 < 18
    cplhh = examples[cpl_w_2_children_hh]
    cpl = get_benefit_units(cplhh)[1]
    spouse = get_spouse( cpl )
    head = get_head( cpl )
    spouse.age = 17
    head.age = 17
    println( "sp=$spouse" )
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    println( intermed )
    for ben in [hb,ctr,is,jsa,esa]
        allow = calc_allowances( 
            ben, 
            intermed, 
            sys.lmt.allowances, 
            sys.age_limits )
        if ben in [hb,ctr]
            @test allow ≈ 87.50 + 2*sys.lmt.allowances.child   
        else
            @test allow ≈ 87.50 # p336 weird stuff about ESA stages
        end
        
    end    
    spouse.age = 17
    head.age = 18
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    println( intermed )
    for ben in [hb,ctr,is,jsa,esa]
        allow = calc_allowances( 
            ben, 
            intermed, 
            sys.lmt.allowances, 
            sys.age_limits )
        if ben in [hb,ctr]
            @test allow ≈ 114.85 + 2*sys.lmt.allowances.child   
        else
            @test allow ≈ 114.85 # p336 weird stuff about ESA stages
        end
    end    
    spouse.age = 18
    head.age = 18
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    println( intermed )
    for ben in [hb,ctr,is,jsa,esa]
        allow = calc_allowances( 
            ben, 
            intermed, 
            sys.lmt.allowances, 
            sys.age_limits )
        if ben in [hb,ctr]
            @test allow ≈ 114.85 + 2*sys.lmt.allowances.child   
        else
            @test allow ≈ 114.85 # p336 weird stuff about ESA stages
        end
    end    
    spouse.age = 60
    head.age = 60
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    for ben in [hb,ctr,is,jsa,esa]
        allow = calc_allowances( 
            ben, 
            intermed, 
            sys.lmt.allowances, 
            sys.age_limits )
        if ben in [hb,ctr]
            @test allow ≈ 114.85 + 2*sys.lmt.allowances.child   
        else
            @test allow ≈ 114.85 # p336 weird stuff about ESA stages
        end
    end    
end

@testset "Premia" begin
    sys = get_system( scotland=true )
    examples = get_ss_examples()
    cplhh = examples[cpl_w_2_children_hh]
    cpl = get_benefit_units(cplhh)[1]
    spouse = get_spouse( cpl )
    head = get_head( cpl )
    spouse.age = 60
    head.age = 60
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    for ben in [hb,ctr,is,jsa,esa]
        premia, premset = calc_premia( 
            ben, 
            cpl,            
            intermed, 
            sys.lmt.premia,
            sys.age_limits )
        @test premia ≈ 0.0
        @test length(premset)==0 
    end
    disable_slightly!( head )
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    @test pers_is_disabled( head )
    @test intermed.num_disabled_adults == 1
    @test intermed.working_disabled
    for ben in [hb,ctr,is,jsa,esa]
        premia, premset = calc_premia( 
            ben, 
            cpl,            
            intermed, 
            sys.lmt.premia,
            sys.age_limits )
        println( "ben=$ben premia=$premia" )
        if ben == esa
            @test premia ≈ 0.0
            @test length(premset)==0
        else
            @test premia == sys.lmt.premia.disability_single
            @test (disability_single ∈ premset) && length(premset)==1  
        end
    end
    disable_seriously!( head )
    intermed = make_intermediate( 
        1,
        cpl,  
        sys.lmt.hours_limits,
        sys.age_limits )
    @test pers_is_disabled( head )
    @test intermed.num_disabled_adults == 1
    @test intermed.working_disabled
    for ben in [hb,ctr,is,jsa,esa]
        premia, premset = calc_premia( 
            ben, 
            cpl,            
            intermed, 
            sys.lmt.premia,
            sys.age_limits )
        println( "ben=$ben premia=$premia" )
        if ben == esa
            @test premia ≈ sys.lmt.premia.enhanced_disability_single
            @test length(premset)==1 ## FIXME check this ESA allowed enhanced_disability_single
        else
            @test premia == sys.lmt.premia.disability_single+sys.lmt.premia.enhanced_disability_single
            @test (enhanced_disability_single ∈ premset) && length(premset)==2  
        end
    end
    
end


@testset "JSA" begin
    

end

@testset "IS" begin
    

end

@testset "PC" begin
    

end

@testset "CTC" begin
    

end

@testset "WTC" begin
    

end
