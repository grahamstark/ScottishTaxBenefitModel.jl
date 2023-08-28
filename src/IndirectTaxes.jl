#=
    
This module holds calculations for indirect tax calculations. Quickie pro tem thing
for Northumberland, but you know how that goes..

TODO add mapping for example households.

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

export calc_indirect_tax!, calc_vat

function calc_vat( hh :: Household{T}, sys :: IndirectTaxSystem{T} ) :: T where T <: Real
    vat = 0.0
    for s in sys.VAT.standard_rate_goods 
        vat += hh.factor_costs[s]*sys.VAT.standard_rate
    end
    for s in sys.VAT.reduced_rate_goods 
        vat += hh.factor_costs[s]*sys.VAT.reduced_rate
    end
    for s in sys.VAT.exempt_goods 
        vat += hh.factor_costs[s]*sys.VAT.assumed_exempt_rate
    end
    return vat
end

function calc_indirect_tax!(  hres :: HouseholdResult{T}, hh :: Household{T}, sys{T} :: IndirectTaxSystem ) where T <: Real

    hres.indirect.VAT = calc_vat( hh, sys )
          
    
end

end # IndirectTaxes module 