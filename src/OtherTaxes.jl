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

"""
hacky - modelled as a % wage tax on self-employed and non-state employed
"""
function calculate_corporation_tax!( 
    household_result :: HouseholdResult,
    hh               :: Household,
    sys              :: OtherTaxesSys )
    bus = get_benefit_units( hh )
    ot = 0.0
    for bu in bus
        for adno in bu.adults
            pers = bu.people[adno]
            if(pers.income[WAGES] > 0.0) && (pers.public_or_private == Private)
                bures.pers[adno].income[OTHER_TAX] = pers.income[WAGES] * sys.implicit_wage_tax
            end
            if(pers.income[SELF_EMPLOYMENT_INCOME] > 0.0)
                bures.pers[adno].income[OTHER_TAX] = pers.income[SELF_EMPLOYMENT_INCOME] * sys.implicit_wage_tax
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