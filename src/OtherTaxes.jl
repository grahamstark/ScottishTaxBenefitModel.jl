module OtherTaxes

using ScottishTaxBenefitModel
using .Definitions
using .GeneralTaxComponents: calctaxdue
using .ModelHousehold
using .Results
using .STBParameters
using .STBIncomes 
export calculate_other_taxes!, calculate_wealth_tax!

"""
Flat rate wealth tax, assigned soley to HH head.
"""
function calculate_wealth_tax!(     
    household_result :: HouseholdResult,
    hh               :: Household,
    sys              :: WealthTaxSys )
    hd = get_head( hh )
    pres = household_result.bus[1].pers[ hd.pid ]
    wealth = 0.0
    # to individual level 
    if sys.abolished > 0
        return
    end
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
    # println( "hh $(hh.hid); got wealth as $wealth")
    wealth = max( 0.0, wealth - sys.allowance )
    wtax = calctaxdue( taxable=wealth, rates=sys.rates, thresholds=sys.thresholds )
    pres.wealth.total_payable = wtax.due 
    pres.wealth.weekly_equiv = pres.wealth.total_payable * sys.weekly_rate
    household_result.bus[1].pers[ hd.pid ].income[OTHER_TAX] += pres.wealth.weekly_equiv
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
    if sys.corporation_tax_changed
        calculate_corporation_tax!( household_result, hh, sys )
    end
end # othertaxes

end # module OtherTaxes