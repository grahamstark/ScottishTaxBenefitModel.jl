module NationalInsuranceCalculations

import BudgetConstraints: BudgetConstraint, get_x_from_y
import Dates
import Dates: Date, now, TimeType, Year
import Parameters: @with_kw

using ScottishTaxBenefitModel
using .Definitions
import .ModelHousehold: Person
import .STBParameters: NationalInsuranceSys
import .GeneralTaxComponents: TaxResult, calctaxdue, RateBands, *
import .Utils: get_if_set

export calc_ni, calc_class_1_primary,
    calc_class_1_secondary, calc_class_2, calc_class_3, calc_class_4

@with_kw mutable struct NIResult
    above_threshold :: Bool = false
    total_ni :: Real = 0.0
    class_1_primary   :: Real = 0.0
    class_1_secondary  :: Real = 0.0
    class_2   :: Real = 0.0
    class_3   :: Real = 0.0
    class_4   :: Real = 0.0
end

function gross_from_net( bc :: BudgetConstraint, net :: Real )::Real
    return get_x_from_y( bc, net )
end

end # module
