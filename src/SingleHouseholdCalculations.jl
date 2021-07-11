"""
As this progresses, this will be the main entry point for calculations on a household
"""

module SingleHouseholdCalculations

import ScottishTaxBenefitModel:
    Definitions,
    IncomeTaxCalculations,
    LegacyMeansTestedBenefits,
    ModelHousehold,
    NationalInsuranceCalculations,
    NonMeansTestedBenefits,
    Results,
    STBParameters

using .Definitions

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

using .Results: 
    BenefitUnitResult,
    HouseholdResult,
    IndividualResult,
    ITResult, 
    NIResult

export do_one_calc

"""
One complete calculation for a single household and tb system.
"""
function do_one_calc( hh :: Household, sys :: TaxBenefitSystem ) :: HouseholdResult
    bus = get_benefit_units( hh )
    hres :: HouseholdResult = init_household_result(hh)
    hd :: BigInt = get_head( hh )
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
            calculate_national_insurance!( 
                hres.bus[buno].pers[pers.pid], 
                pers, 
                sys.ni )
        end
        buno += 1
    end # bus loop
    calc_post_tax_non_means_tested!( 
        hres,
        hh, 
        sys.nmt_bens, 
        sys.age_limits )
        
    intermed = make_intermediate( hh, sys.hours_limits, sys.age_limits )
    
    hres.bus[1].pers[hd].income[LOCAL_TAXES] = 
        calc_council_tax( hh, intermed.hhint, sys.loctax.ct )
    
    calc_legacy_means_tested_benefits!(
        hres,
        hh,
        intermed,
        sys.age_limits,
        sys.lmt_ben_sys,
        sys.hours_limits,
        sys.hr )

    aggregate!( hh, hres )
    return hres
end

end # module