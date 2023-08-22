#=
    
This module holds both the data and calculations for indirect tax calculations. Quickie pro tem thing
for Northumberland, but you know how that goes..

TODO move the declarations to a Seperate module/ModelHousehold module.
TODO add mapping for example households.
TODO all uprating is nom gdp for now.

=#


module IndirectTaxes

using CSV,DataFrames,StatsBase

using ScottishTaxBenefitModel
using .Definitions
using .GeneralTaxComponents
using .ModelHousehold
using .Results
using .RunSettings
using .STBParameters
using .Uprating

function calc_indirect_tax!(  hres :: HouseholdResult, hh :: Household, sys :: IndirectTaxSystem )
    
                # FIXME 
                if sym in DEFAULT_STANDARD_RATE
                    r[sym] /= 1.2
                elseif sym in DEFAULT_REDUCED_RATE
                    r[sym] /= 1.05
                elseif sym in DEFAULT_EXEMPT
                    r[sym] /= 1.08
                end
    
    
end

end # IndirectTaxes module 