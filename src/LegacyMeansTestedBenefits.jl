module LegacyMeansTestedBenefits

import Parameters: @with_kw

using ScottishTaxBenefitModel
using .Definitions
import .ModelHousehold: Person
import .STBParameters: LegacyMeansTestedBenefitSystem
import .GeneralTaxComponents: TaxResult, calctaxdue, RateBands, *
import .Utils: get_if_set

export calc_legacy_means_tested_benefits, LMTResults

@with_kw mutable struct LMTResults{IT<:Integer, RT<:Real}
    esa :: RT = 0.0
    hb  :: RT = 0.0
    jsa :: RT = 0.0
    pc  :: RT = 0.0
    ndds :: RT = 0.0
    wtc :: RT = 0.0
    ctc :: RT = 0.0
    intermediate :: Dict = Dict()
end



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
    sys    :: LegacyMeansTestedBenefitSystem ) :: LMTResults

end

end # module LegacyMeansTestedBenefits
