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
    apply_2_child_policy,
    make_intermediate 

using .NonMeansTestedBenefits:
    calc_pre_tax_non_means_tested!,
    calc_post_tax_non_means_tested!
    
using .LocalLevelCalculations: 
    calc_council_tax
    
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


@testset "Run on actual Data" begin
    #
    # 
    #
    nhhs,npeople = init_data()
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

    end # hhld loop
end #


