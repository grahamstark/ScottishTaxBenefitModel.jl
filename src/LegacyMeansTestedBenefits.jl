module LegacyMeansTestedBenefits

using BudgetConstraints #: BudgetConstraint, get_x_from_y
import Dates
import Dates: Date, now, TimeType, Year
import Parameters: @with_kw

using ScottishTaxBenefitModel
using .Definitions
import .ModelHousehold: Person
import .STBParameters: NationalInsuranceSys
import .GeneralTaxComponents: TaxResult, calctaxdue, RateBands, *
import .Utils: get_if_set

@with_kw mutable struct LMTResults
    esa :: Real = 0.0
    hb  :: Real = 0.0
    jsa :: Real = 0.0
    pc  :: Real = 0.0
    ndds :: Real = 0.0
    wtc :: Real = 0.0
    ctc :: Real = 0.0
    intermediate :: Dict = Dict()
end


export calc_legacy_means_tested_benefits, LMTResults


function calc_ESA()

end

function calc_HB()

end

function calc_JSA()

end

function calc_PC()

end

function calc_CTC()

end

function calc_NDDS()

end

function calc_LHA()

end

function calc_WTC()

end

function calc_legacy_means_tested_benefits(
    pers   :: Person,
    sys    :: IncomeTaxSys ) :: LMTResults

end

end # module LegacyMeansTestedBenefits
