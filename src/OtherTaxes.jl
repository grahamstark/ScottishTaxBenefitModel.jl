module OtherTaxes

using ScottishTaxBenefitModel
using .ModelHousehold
using .Results
using .STBParameters
using .STBIncomes 
export calculate_other_taxes!

"""
Flat rate wealth tax, assigned soley to HH head.
"""
function calculate_wealth_tax!(     
    household_result :: HouseholdResult,
    hh               :: Household,
    sys              :: OtherTaxesSys )
    hd = get_head( hh )
    wt = sys.wealth_tax * hh.total_wealth
    household_result.bus[1].pers[ hd.pid ].income[OTHER_TAX] = wt
end

function calculate_other_taxes!(     
    household_result :: HouseholdResult,
    hh               :: Household,
    sys              :: OtherTaxesSys )
    if sys.wealth_tax > 0
        calculate_wealth_tax!(     
            household_result, hh, sys )
    end
end

end # module OtherTaxes