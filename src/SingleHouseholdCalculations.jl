
module SingleHouseholdCalculations

#
# This module drives all the calculations for single household and a single set of parameters.
#

using ScottishTaxBenefitModel

using .Definitions

using .RunSettings:
    Settings,
    DEFAULT_SETTINGS

using .Results: 
    IndividualResult,
    BenefitUnitResult,
    HouseholdResult,
    init_household_result,
    aggregate!

using .STBParameters: 
    TaxBenefitSystem

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

# using .LegacyMeansTestedBenefits

using .NonMeansTestedBenefits:
    calc_pre_tax_non_means_tested!,
    calc_post_tax_non_means_tested!

using .IncomeTaxCalculations: 
    calc_income_tax!

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
    calc_council_tax

using .LegacyMeansTestedBenefits: 
    calc_legacy_means_tested_benefits!

using .UniversalCredit:
    calc_universal_credit!

using .BenefitCap:
    apply_benefit_cap!

using .UCTransition: route_to_uc_or_legacy!

using .ScottishBenefits: 
    calc_scottish_child_payment!,
    calc_bedroom_tax_mitigation!

using .UBI: calc_UBI!, make_ubi_post_adjustments!

export do_one_calc

"""
One complete calculation for a single household and tb system.
"""
function do_one_calc( 
    hh :: Household{T}, 
    sys :: TaxBenefitSystem{T},
    settings :: Settings = DEFAULT_SETTINGS ) :: HouseholdResult{T} where T
    # hh = deepcopy( mhh ) # for minwage and so on

    bus = get_benefit_units( hh )
    hres :: HouseholdResult{T} = init_household_result(hh)
    intermed = make_intermediate( 
        hh, 
        sys.hours_limits, 
        sys.age_limits, 
        sys.child_limits )
    
    hd :: BigInt = get_head( hh ).pid
    calc_pre_tax_non_means_tested!( 
        hres,
        hh, 
        sys.nmt_bens,
        sys.hours_limits,
        sys.age_limits )
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
        
    hres.bus[1].pers[hd].income[LOCAL_TAXES] = 
        calc_council_tax( hh, intermed.hhint, sys.loctax.ct )
        
    calc_UBI!(
        hres,
        hh,
        sys.ubi )

    calc_legacy_means_tested_benefits!(
        hres,
        hh,
        intermed,
        sys.lmt,
        sys.age_limits,
        sys.hours_limits,
        sys.nmt_bens,
        sys.hr )

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
    
    route_to_uc_or_legacy!( 
        hres,
        settings,
        hh,
        intermed )
    
    
    for buno in eachindex( bus )
        calc_scottish_child_payment!( 
            hres.bus[buno],
            bus[buno],
            intermed.buint[buno],
            sys.scottish_child_payment )

        apply_benefit_cap!( 
            hres.bus[buno],
            hh.region,
            bus[buno],
            intermed.buint[buno],
            sys.bencap,
            hres.bus[buno].route )
    end
    # do this after the benefit cap
    # since the DISCRESIONARY_HOUSING_PAYMENT must be <= hb/uc housing costs
    calc_bedroom_tax_mitigation!( hres, hh )
    if ! sys.ubi.abolished
        make_ubi_post_adjustments!( hres, sys.ubi )
    end
    aggregate!( hh, hres )
    return hres
end

end # module