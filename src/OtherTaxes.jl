module OtherTaxes

using ScottishTaxBenefitModel
using .Definitions
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
    wealth = 0.0
    if net_physical_wealth in sys.included_wealth 
        wealth += hh.net_physical_wealth
    end 
    if net_financial_wealth in sys.included_wealth 
        wealth += hh.net_financial_wealth
    end 
    if net_housing_wealth in sys.included_wealth 
        wealth += hh.net_housing_wealth
    end 
    if net_pension_wealth in sys.included_wealth 
        wealth += hh.net_pension_wealth
    end 

    wealth = max( 0.0, wealth - sys.wealth_allowance )
    wt = wealth * sys.wealth_tax 
    household_result.bus[1].pers[ hd.pid ].income[OTHER_TAX] += wt
end

"""
hacky - modelled as a % wage tax on self-employed and non-state employed
"""
function calculate_corporation_tax!( 
    household_result :: HouseholdResult,
    hh               :: Household,
    sys              :: OtherTaxesSys )
    bus = get_benefit_units( hh )
    ot = 0.0
    buno = 0
    for bu in bus
        buno += 1
        for adno in bu.adults
            pers = bu.people[adno]
            wage = get(pers.income, wages, 0.0 )
            if( wage > 0.0) && (pers.public_or_private == Private)
                household_result.bus[buno].pers[adno].income[OTHER_TAX] += wage * sys.implicit_wage_tax
            end
            se = get(pers.income, self_employment_income, 0.0 )
            if se > 0.0
                household_result.bus[buno].pers[adno].income[OTHER_TAX] += se * sys.implicit_wage_tax
            end
        end # adults
    end # bus
end # corptax

function calculate_other_taxes!(     
    household_result :: HouseholdResult,
    hh               :: Household,
    sys              :: OtherTaxesSys )
    if sys.wealth_tax > 0
        calculate_wealth_tax!(     
            household_result, hh, sys )
    end
    if sys.corporation_tax_changed
        calculate_corporation_tax!( household_result, hh, sys )
    end
end # othertaxes

end # module OtherTaxes