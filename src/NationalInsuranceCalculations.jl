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

export calculate_national_insurance

@with_kw mutable struct NIResult
    above_lower_earnings_limit :: Bool = false
    total_ni :: Real = 0.0
    class_1_primary    :: Real = 0.0
    class_1_secondary  :: Real = 0.0
    class_2   :: Real = 0.0
    class_3   :: Real = 0.0
    class_4   :: Real = 0.0
end

function make_gross_earnings_bc( )

end

function calculate_national_insurance( pers::Person, sys :: NationalInsuranceSys ) :: NIResult
    if size(sys.gross_to_net_lookup)[1] == 0 && size( sys.secondary_class_1_rates)[1] > 0 


    primary_class_1_rates :: RateBands = [0.0, 0.0, 12.0, 2.0 ]
  primary_class_1_bands :: RateBands = [118.0, 166.0, 962.0, 99999999999.99 ]
  secondary_class_1_rates :: RateBands = [0.0, 13.8, 13.8 ] # keep 2 so
  secondary_class_1_bands :: RateBands = [166.0, 962.0, 99999999999.99 ]
end

function gross_from_net( bc :: BudgetConstraint, net :: Real )::Real
    return get_x_from_y( bc, net )
end

end # module
