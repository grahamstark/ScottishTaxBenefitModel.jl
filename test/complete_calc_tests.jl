using Test
using ScottishTaxBenefitModel
import ScottishTaxBenefitModel.ModelHousehold: Household, Person, People_Dict, default_bu_allocation
# import FRSHouseholdGetter
import ScottishTaxBenefitModel.ExampleHouseholdGetter
using ScottishTaxBenefitModel.Definitions
import Dates: Date
import ScottishTaxBenefitModel.STBParameters: TaxBenefitSystem, IncomeTaxSys, get_default_it_system
import SingleHouseholdCalculations:do_one_calc
using .Results: IndividualResult,
    BenefitUnitResult,
    HouseholdResult

@testset "Reproduce HMRC 2019/20" begin


end
