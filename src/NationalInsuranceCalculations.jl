module NationalInsuranceCalculations

import Dates
import Dates: Date, now, TimeType, Year
import Parameters: @with_kw

using ScottishTaxBenefitModel
using .Definitions
import .ModelHousehold: Person
import .STBParameters: NationalInsuranceSys
import .GeneralTaxComponents: TaxResult, calctaxdue, RateBands, *
import .Utils: get_if_set

export calc_ni, calc_class_1,
    calc_class_1a, calc_class_2, calc_class_3, calc_class_4

@with_kw mutable struct NIResult
    above_threshold :: Bool = false
    total_ni :: Real = 0.0
    class_1   :: Real = 0.0
    class_1a  :: Real = 0.0
    class_2   :: Real = 0.0
    class_3   :: Real = 0.0
    class_4   :: Real = 0.0
end

end # module
