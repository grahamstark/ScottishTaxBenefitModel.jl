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
    num_people,
    num_children,
    pers_is_carer,
    pers_is_disabled, 
    search

using .IncomeTaxCalculations: 
    calc_income_tax!

using .NationalInsuranceCalculations:
    calculate_national_insurance!

using .Intermediate: 
    MTIntermediate, 
    apply_2_child_policy,
    make_intermediate 

using .NonMeansTestedBenefits:
    calc_pre_tax_non_means_tested!,
    calc_post_tax_non_means_tested!
    
using .STBParameters: 
    HoursLimits,
    HousingRestrictions,
    MinimumWage,
    UniversalCreditSys
   
using .UniversalCredit
    basic_conditions_satisfied,
    calc_elements!,
    calc_standard_allowance,
    calc_tariff_income!,
    calc_uc_child_costs!,
    calc_uc_income!,
    calc_universal_credit!, 
    disqualified_on_capital,
    qualifiying_16_17_yo    

using .Results: 
    BenefitUnitResult,
    LMTResults, 
    LMTCanApplyFor, 
    init_household_result, 
    init_benefit_unit_result, 
    to_string

using .Utils: 
    eq_nearest_p,
    to_md_table

using .GeneralTaxComponents:
    WEEKS_PER_MONTH,
    WEEKS_PER_YEAR

using .Definitions

using .STBIncomes

## FIXME don't need both
sys = get_system( scotland=true )

@testset "UC Example Shakedown Tests" begin
    #
    # Just drive the example hhls through the UC routine
    # & see if anything crashes. Fuller tests to follow.
    #
    # Normally we'll do these tests monthly so they correspond better
    # to the CPAG examples
    # uc = get_default_uc( weekly = true )

    examples = get_ss_examples()
    
    incomes = [110.0,145.0,325,755.0,1_000.0]

    for (hht,hh) in examples 
        for income in incomes
            println( "on hhld '$hht' income=$income")

            bus = get_benefit_units( hh )
            intermed = make_intermediate( 
                hh,  
                sys.hours_limits,
                sys.age_limits,
                sys.child_limits )
            res = init_household_result( hh )
            hhead = get_head( hh )
            hhead.income[wages] = income 
            calc_universal_credit!(
                res,
                hh, 
                intermed,
                sys.uc,
                sys.age_limits,
                sys.hours_limits,
                sys.child_limits,
                sys.hr,
                sys.minwage
            )
            for buno in eachindex(res.bus) 
                head = get_head( bus[buno] )
                println( res.bus[buno].uc )
                println( "UC Entitlement for $hht bu $buno earn $income = $(res.bus[buno].pers[head.pid].income[UNIVERSAL_CREDIT])" )
            end
        end
    end
end



@testset "Gail and Joe; CPAG 19/20 ch 3" begin
    # p41 example
    ucs = get_default_uc( weekly=false)
    g_and_j = deepcopy( EXAMPLES[cpl_w_2_children_hh])
    @test num_children( g_and_j ) == 2
    g_and_j.gross_rent = 0.0
    g_and_j.water_and_sewerage = 0.0
    g_and_j.mortgage_payment = 0.0
    g_and_j.other_housing_charges = 0.0
    g = get_head(g_and_j)
    j = get_spouse(g_and_j)
    
    set_childrens_ages!( g_and_j, 2, 3 ) # so none qualify for 1st child extra
    employ!(g)
    unemploy!(j)
    disable_seriously!(j)
    blind!(j)
    intermed = make_intermediate( 
        g_and_j, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    @test intermed.buint[1].age_oldest_child == 3
    hres = init_household_result( g_and_j )
    calc_universal_credit!(
        hres,
        g_and_j, 
        intermed,
        ucs,
        sys.age_limits,
        sys.hours_limits,
        sys.child_limits,
        sys.hr,
        sys.minwage
    )
    @test hres.bus[1].uc.standard_allowance == ucs.couple_oldest_25_plus
    @test hres.bus[1].uc.child_element ≈ 2*ucs.subsequent_child
    ## from j being disabled
    @test hres.bus[1].uc.limited_capacity_for_work_activity_element == ucs.limited_capcacity_for_work_activity
    # they have children, j is disabled, and no hcosts so..
    @test hres.bus[1].uc.work_allowance == ucs.work_allowance_no_housing
    println( hres.bus[1].uc )
    set_childrens_ages!( g_and_j, 10, 9 ) # so none qualify for 1st child extra
    intermed = make_intermediate( 
        g_and_j, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    @test intermed.buint[1].age_oldest_child == 10
    calc_universal_credit!(
        hres,
        g_and_j, 
        intermed,
        ucs,
        sys.age_limits,
        sys.hours_limits,
        sys.child_limits,
        sys.hr,
        sys.minwage
    )
    @test hres.bus[1].uc.child_element ≈ ucs.first_child+ucs.subsequent_child
    g_and_j.gross_rent = 100.0
    g_and_j.tenure = Private_Rented_Unfurnished
    intermed = make_intermediate( 
        g_and_j, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    calc_universal_credit!(
        hres,
        g_and_j, 
        intermed,
        ucs,
        sys.age_limits,
        sys.hours_limits,
        sys.child_limits,
        sys.hr,
        sys.minwage
    )
    println( "Tenure = $(g_and_j.tenure)" )
    @test hres.bus[1].uc.work_allowance == ucs.work_allowance_w_housing
    @test hres.bus[1].uc.housing_element ≈ 100.0
    # reset
    g_and_j.gross_rent = 0.0
    set_childrens_ages!( g_and_j, 3, 2 ) # so none qualify for 1st child extra
    intermed = make_intermediate( 
        g_and_j, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    hres = init_household_result( g_and_j )
    hres.bus[1].pers[j.pid].income .= 0.0
    hres.bus[1].pers[g.pid].income .= 0.0
    empty!(g.assets)
    empty!(j.assets)
    g.assets[A_Savings_investments_etc] = 5_000.0
    hres.bus[1].pers[j.pid].income[CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE] = 483.81
    hres.bus[1].pers[g.pid].income[WAGES] = 1_200.0
    calc_universal_credit!(
        hres,
        g_and_j, 
        intermed,
        ucs,
        sys.age_limits,
        sys.hours_limits,
        sys.child_limits,
        sys.hr,
        sys.minwage
    )
    println( hres.bus[1].uc )    
    @test hres.bus[1].pers[j.pid].income[UNIVERSAL_CREDIT] ≈ 375.51
end

@testset "16-17yo adult tests; cpag ch3 sec2" begin
    ucs = get_default_uc( weekly=false)
    yph = deepcopy( EXAMPLES[mbu])
    head = get_head( yph )
    enable!( head )
    head.age = 17
    bus = get_benefit_units( yph )
    # doesn't qualify in standard case
    intermed = make_intermediate( 
        yph, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    println( ModelHousehold.to_string( head ))
    println( Intermediate.to_string( intermed.buint[1] ))
        @test ! qualifiying_16_17_yo(
        bus[1],
        head,
        intermed.buint[1],
        ucs ) 
    # qualifies as carer
    carer!( head )
    intermed = make_intermediate( 
        yph, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    @test qualifiying_16_17_yo(
        bus[1],
        head,
        intermed.buint[1],
        ucs ) 
    uncarer!( head )
    intermed = make_intermediate( 
        yph, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    @test ! qualifiying_16_17_yo(
        bus[1],
        head,
        intermed.buint[1],
        ucs ) 

    add_child!( yph, 3, Female )
    bus = get_benefit_units( yph )
    @test num_people(bus[1]) == 2
    @test num_children(bus[1]) == 1
    intermed = make_intermediate( 
        yph, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    @test qualifiying_16_17_yo(
        bus[1],
        head,
        intermed.buint[1],
        ucs ) 
   
end

@testset "capital" begin
    ucs = get_default_uc( weekly=false)
    cpl= deepcopy( EXAMPLES[cpl_w_2_children_hh])
    hres = init_household_result( cpl )
    head = get_head( cpl )
    spouse = get_spouse( cpl )
    empty!(head.assets)
    head.over_20_k_saving = false
    empty!(spouse.assets)
    spouse.over_20_k_saving = false
    bus = get_benefit_units( cpl )
    @test ! disqualified_on_capital(
        bus[1],
        ucs )
    spouse.over_20_k_saving = true
    @test disqualified_on_capital(
        bus[1],
        ucs )
    calc_tariff_income!( 
        hres.bus[1],
        bus[1],
        ucs )
    @test hres.bus[1].uc.assets == 0 
    @test hres.bus[1].uc.tariff_income == 0 
    spouse.over_20_k_saving = false
    spouse.assets[A_Premium_bonds] = 8000
    @test ! disqualified_on_capital(
        bus[1],
        ucs )
        calc_tariff_income!( 
            hres.bus[1],
            bus[1],
            ucs )
    @test hres.bus[1].uc.assets == 8_000 
    @test hres.bus[1].uc.tariff_income ≈ ceil((8000-ucs.capital_min)/ucs.capital_tariff)
    head.assets[A_Premium_bonds] = 8_001
    @test disqualified_on_capital(
        bus[1],
        ucs )
    calc_tariff_income!( 
        hres.bus[1],
        bus[1],
        ucs )
    @test hres.bus[1].uc.assets == 16_001 
    @test hres.bus[1].uc.tariff_income ≈ ceil(ucs.capital_tariff\(16001-ucs.capital_min))
    
end

@testset "income calculations" begin
    ucs = get_default_uc( weekly=false)
    cpl= deepcopy( EXAMPLES[cpl_w_2_children_hh])
    head = get_head( cpl )
    head.age = 30
    spouse = get_spouse( cpl )
    spouse.age = 30
    empty!(head.assets)
    empty!(head.income)
    head.over_20_k_saving = false
    empty!(spouse.assets)
    empty!(spouse.income)
    spouse.over_20_k_saving = false
    bus = get_benefit_units( cpl )
    hres = init_household_result( cpl )
    intermed = make_intermediate( 
        cpl, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )

    calc_uc_income!(
        hres.bus[1],
        bus[1],
        intermed.buint[1],
        ucs,
        sys.minwage
    )
    @test hres.bus[1].uc.other_income == 0
    @test hres.bus[1].uc.earned_income == 0
    # CPAG 19/20 p120 example of low se income
    # I can't test this against the book exactly
    # because of weekly/monthly units but
    # this gets close.
    head.income[self_employment_income] = 300
    head.employment_status = Full_time_Self_Employed 
    hres = init_household_result( cpl )
    @test hres.bus[1].pers[head.pid].income[SELF_EMPLOYMENT_INCOME] == 300
    hres.bus[1].pers[head.pid].income[INCOME_TAX] = 103.80
    minse = make_min_se( 
        head.income[self_employment_income],
        head.age,
        ucs,
        sys.minwage
    )
    println( "minse=$minse")
    calc_uc_income!(
        hres.bus[1],
        bus[1],
        intermed.buint[1],
        ucs,
        sys.minwage
    )
    println( hres.bus[1].uc )
    @test hres.bus[1].uc.earned_income ≈ ucs.taper*(1249.9725-103.80-503.0)
end

run_full_tests = IS_LOCAL # && false

@testset "Run on actual Data" begin
    if run_full_tests
        #
        # Just a Shakedown run ..
        #
        nhhs,npeople = init_data()
        positive_uc = 0.0
        total_uc = 0.0
        for hno in 1:nhhs
            hh = get_household(hno)
            intermed = make_intermediate( 
                hh,  
                sys.hours_limits,
                sys.age_limits,
                sys.child_limits )

            hres = init_household_result( hh )
            println( "hhno $hno")
            # tax stuff, which we kinda sorta need
            bus = get_benefit_units( hh )
            calc_pre_tax_non_means_tested!( 
                hres,
                hh, 
                sys.nmt_bens,
                sys.hours_limits,
                sys.age_limits )
        
            for buno in eachindex(bus)
                # income tax, with some nonsense for
                # what remains of joint taxation..
                head = get_head( bus[buno] )
                spouse = get_spouse( bus[buno] )            
                calc_income_tax!(
                    hres.bus[buno],
                    head,
                    spouse,
                    sys.it )
                for chno in bus[buno].children
                    child = bus[buno].people[chno]
                    calc_income_tax!(
                        hres.bus[buno].pers[child.pid],
                        child,
                        sys.it )
                end  # child loop
            end # bus loop
            calc_post_tax_non_means_tested!( 
                hres,
                hh, 
                sys.nmt_bens, 
                sys.age_limits )
        
            calc_universal_credit!(
                hres,
                hh, 
                intermed,
                sys.uc,
                sys.age_limits,
                sys.hours_limits,
                sys.child_limits,
                sys.hr,
                sys.minwage
            )
            for buno in eachindex(bus)
                # income tax, with some nonsense for
                # what remains of joint taxation..
                head = get_head( bus[buno] )
                uc = hres.bus[buno].pers[head.pid].income[UNIVERSAL_CREDIT]
                if uc > 0
                    positive_uc += hh.weight
                    total_uc += hh.weight*WEEKS_PER_YEAR*uc                            
                end
            end
        end # hhld loop
        total_uc /= 1_000_000
        println( "total UC entitlement $positive_uc total cost $total_uc (£m pa)")
        # mean of about 571pm ; actual 690.92 per StatXplore
    end # local
end # testset