
module SingleHouseholdCalculations

#
# This module drives all the calculations for single household and a single set of parameters.
#

using ScottishTaxBenefitModel

using .Definitions
using .HouseholdAdjuster: 
    adjusthh, 
    apply_minumum_wage!
using .ModelHousehold: 
    BenefitUnit, 
    BenefitUnits, 
    BUAllocation,
    Household, 
    People_Dict, 
    PeopleArray, 
    Person,     
    default_bu_allocation,
    get_benefit_units, 
    get_head, 
    get_spouse, 
    num_people,
    printpids
using .Results: 
    IndividualResult,
    BenefitUnitResult,
    HouseholdResult,
    init_household_result,
    aggregate!
using .RunSettings: Settings
using .STBParameters: 
    TaxBenefitSystem
using .CTR

# using .LegacyMeansTestedBenefits

using .NonMeansTestedBenefits:
    calc_pre_tax_non_means_tested!,
    calc_post_tax_non_means_tested!

using .IncomeTaxCalculations: 
    calc_income_tax!

using .IndirectTaxes: calc_indirect_tax!

using .NationalInsuranceCalculations: 
    calculate_national_insurance!

using .STBIncomes

using .Intermediate: 
    MTIntermediate,
    make_intermediate

using .Results: 
    BenefitUnitResult,
    HouseholdResult,
    IndividualResult,
    ITResult, 
    NIResult

using .LocalLevelCalculations:
    calc_council_tax,
    calc_proportional_property_tax

using .LegacyMeansTestedBenefits: 
    calc_legacy_means_tested_benefits!,
    calculateHB_CTR!

using .LegalAidCalculations: calc_legal_aid!

using .UniversalCredit:
    calc_universal_credit!

using .BenefitCap:
    apply_benefit_cap!

using .UCTransition: route_to_uc_or_legacy!

using .ScottishBenefits: 
    calc_scottish_child_payment!,
    calc_bedroom_tax_mitigation!

using .UBI: calc_UBI!, make_ubi_post_adjustments!

using .OtherTaxes: calculate_other_taxes!, calculate_wealth_tax!

using .CrudeTakeup: correct_for_caseload_non_takeup!

export do_one_calc

"One complete calculation for a single household and tb system."
function do_one_calc( 
    mhh :: Household{T}, 
    sys :: TaxBenefitSystem{T},
    settings :: Settings = Settings() ) :: HouseholdResult{T} where T
    # hh = deepcopy( mhh ) # for minwage and so on
    hh :: Household = adjusthh( mhh, sys.adjustments )
    bus = get_benefit_units( hh )
    hres :: HouseholdResult{T} = init_household_result(hh)
    intermed = make_intermediate( 
        T,
        settings,
        hh, 
        sys.hours_limits, 
        sys.age_limits, 
        sys.child_limits )
    apply_minumum_wage!( hres, hh, sys.minwage )
    
    hd :: BigInt = get_head( hh ).pid
    calc_pre_tax_non_means_tested!( 
        hres,
        hh, 
        sys.nmt_bens,
        sys.hours_limits,
        sys.age_limits )

    calc_UBI!(
        hres,
        hh,
        sys.ubi,
        sys.lmt,
        sys.uc,
        intermed,
        sys.hours_limits,
        sys.minwage )    
    buno = 1
    for bu in bus

        # income tax, with some nonsense for
        # what remains of joint taxation..
        head = get_head( bu )
        spouse = get_spouse( bu )
        calc_income_tax!( 
            hres.bus[buno],
            head,
            spouse,
            sys.it )
        for chno in bu.children
            child = bu.people[chno]
            calc_income_tax!(
                hres.bus[buno].pers[child.pid],    
                child,
                sys.it )
        end
        for (pid,pers) in bu.people
            if pers.age >= 16 # must be 16+
                calculate_national_insurance!( 
                    hres.bus[buno].pers[pers.pid], 
                    pers, 
                    sys.ni )
                end
        end
        buno += 1
    end # bus loop
    calc_post_tax_non_means_tested!( 
        hres,
        hh, 
        sys.nmt_bens, 
        sys.age_limits )
    if ! sys.loctax.ct.abolished 
        hres.bus[1].pers[hd].income[LOCAL_TAXES] = 
            calc_council_tax( hh, intermed.hhint, sys.loctax.ct )
    end
    if ! sys.loctax.ppt.abolished       
        ltax, ntax = calc_proportional_property_tax( hh, intermed.hhint, sys.loctax.ppt )
        hres.bus[1].pers[hd].income[LOCAL_TAXES] += ltax
        hres.bus[1].pers[hd].income[OTHER_TAX] += ntax            
    end

    routes = UCTransition.get_routes_for_hh( settings, hh, intermed )

    calc_legacy_means_tested_benefits!(
        hres,
        hh,
        intermed,
        sys.lmt,
        sys.age_limits,
        sys.hours_limits,
        sys.nmt_bens,
        sys.hr, 
        routes )

    calc_universal_credit!(
        hres,
        hh,
        intermed,
        sys.uc,
        sys.age_limits,
        sys.hours_limits,
        sys.child_limits,
        sys.hr,
        sys.minwage, 
        routes )

    #=
    calc_ctr!(
        hres,
        hh,
        intermed,
        sys.uc,
        sys.ctr,
        sys.age_limits,
        sys.hours_limits,
        sys.child_limits,
    route_to_uc_or_legacy!( 
        hres,
        settings,
        hh,
        intermed )
        sys.minwage )
    =#

    # jam on CTR legacy style - see CPAG note
    # note thus needs to be done *after* the UC legacy routing so incomes are cleared
    # of 
    if ! sys.lmt.ctr.abolished
        calculateHB_CTR!( 
            hres,            
            ctr,
            hh,
            intermed,
            sys.lmt,
            sys.age_limits,
            sys.nmt_bens )      
    end
     
    for buno in eachindex( bus )
        if hh.region == Scotland
            calc_scottish_child_payment!( 
                hres.bus[buno],
                bus[buno],
                intermed.buint[buno],
                sys.scottish_child_payment )
        end
        apply_benefit_cap!( 
            hres.bus[buno],
            hh.region,
            bus[buno],
            intermed.buint[buno],
            sys.bencap,
            hres.bus[buno].route )
    end
    # do this after the benefit cap
    # since the DISCRETIONARY_HOUSING_PAYMENT must be <= hb/uc housing costs
    if (hh.region == Scotland) && sys.scottish_adjustments.mitigate_bedroom_tax
        calc_bedroom_tax_mitigation!( hres, hh )
    end
    if ! sys.ubi.abolished
        make_ubi_post_adjustments!( hres, sys.ubi )
    end
    if ! sys.wealth.abolished
        calculate_wealth_tax!( hres, hh, sys.wealth )
    end
    
    calculate_other_taxes!( hres, hh, sys.othertaxes )
    if settings.do_indirect_tax_calculations
        calc_indirect_tax!( hres, hh, sys.indirect )
    end
    if settings.do_dodgy_takeup_corrections
        correct_for_caseload_non_takeup!( hres, hh, intermed )
    end
    aggregate!( hh, hres )
    if settings.do_legal_aid
        calc_legal_aid!( 
            hres, 
            hh, 
            intermed, 
            sys.legalaid.civil, 
            sys.nmt_bens, 
            sys.age_limits )
        calc_legal_aid!( 
            hres, 
            hh, 
            intermed, 
            sys.legalaid.aa, 
            sys.nmt_bens, 
            sys.age_limits )        
    end
    return hres
end

end # module