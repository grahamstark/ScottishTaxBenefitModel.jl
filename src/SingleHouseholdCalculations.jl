"""
As this progresses, this will be the main entry point for calculations on a household
"""

module SingleHouseholdCalculations

import ScottishTaxBenefitModel:
    Definitions,
    Results,
    STBParameters,
    ModelHousehold,
    IncomeTaxCalculations,
    NationalInsuranceCalculations


using .Definitions
using .Results: IndividualResult,
    BenefitUnitResult,
    HouseholdResult,
    init_household_result
using .STBParameters: TaxBenefitSystem
using .ModelHousehold: Household, Person, People_Dict, BUAllocation,
      PeopleArray, printpids,
      BenefitUnit, BenefitUnits, default_bu_allocation,
      get_benefit_units, get_head, get_spouse, num_people

using .IncomeTaxCalculations: ITResult, calc_income_tax
using .NationalInsuranceCalculations: NIResult, calculate_national_insurance
using .Results: IndividualResult,
    BenefitUnitResult,
    HouseholdResult
export do_one_calc

function do_one_calc( hh :: Household, sys :: TaxBenefitSystem ) :: HouseholdResult
    bus = get_benefit_units( hh )
    hres :: HouseholdResult = init_household_result(hh)
    buno = 1
    for bu in bus
        # income tax, with some nonsense for
        # what remains of joint taxation..
        head = get_head( bu )
        spouse = get_spouse( bu )
        itres = calc_income_tax(
            head,
            spouse,
            sys.it )
        hres.bus[buno].pers[head.pid].it = itres.head
        if spouse != nothing
            hres.bus[buno].pers[spouse.pid].it = itres.head
        end
        for chno in bu.children
            child = bu.people[chno]
            itres = calc_income_tax(
                child,
                nothing,
                sys.it )
            hres.bus[buno].pers[child.pid].it = itres.head
        end
        # national insurance
        for (pid,pers) in bu.people
            hres.bus[buno].pers[pers.pid].ni =
                calculate_national_insurance( pers, sys.ni )
        end
        buno += 1
    end # bus loop
    return hres
end

end
