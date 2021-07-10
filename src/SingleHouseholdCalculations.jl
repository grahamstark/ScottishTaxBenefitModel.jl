"""
As this progresses, this will be the main entry point for calculations on a household
"""

module SingleHouseholdCalculations

import ScottishTaxBenefitModel:
    Definitions,
    IncomeTaxCalculations,
    LegacyMeansTestedBenefits,
    ModelHousehold,
    NationalInsuranceCalculations
    NonMeansTestedBenefits,
    Results,
    STBParameters,


using .Definitions
using .Results: 
    IndividualResult,
    BenefitUnitResult,
    HouseholdResult,
    init_household_result

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

using NonMeansTestedBenefits:
    calc_pre_tax_non_means_tested!,
    calc_post_tax_non_means_tested!

using .IncomeTaxCalculations: calc_income_tax!
using .NationalInsuranceCalculations: calculate_national_insurance!
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
    calc_pre_tax_non_means_tested!( 
        hhres, # :: HouseholdResult,
        hh,    #    :: Household,
        sys.nmt_bens, #   :: NonMeansTestedSys,
        sys.hours_limits, #  :: HoursLimits,
        sys.age_limits ) # :: AgeLimits ) 
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
        hres, # :: HouseholdResult,
        hh,    #    :: Household,
        sys.nmt_bens, #   :: NonMeansTestedSys,
        sys.age_limits ) # :: AgeLimits ) 
    return hres
end

end # module