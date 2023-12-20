module HouseholdAdjuster

    using ScottishTaxBenefitModel
    using .STBParameters
    using .ModelHousehold
    using .Definitions

    export adjusthh

    function mult_income!( incomes :: Incomes_Dict, mults :: Incomes_Dict)
        k1 = keys(incomes)
        k2 = keys(mults)
        kt = intersect(k1,k2)
        for k in kt
            incomes[k] *= mults[k]
        end
    end

    function adjusthh( hh :: Household, dataj :: DataAdjustments ) :: Household
        if ! STBParameters.any_changes_needed( dataj )
            return hh
        end
        chh = deepcopy(hh)
        chh.water_and_sewerage  *= dataj.pct_housing[1]
        chh.mortgage_payment *= dataj.pct_housing[2]
        chh.mortgage_interest *= dataj.pct_housing[3]
        chh.mortgage_outstanding *= dataj.pct_housing[4]
        chh.gross_rent *= dataj.pct_housing[5]
        chh.other_housing_charges *= dataj.pct_housing[6]
        chh.gross_housing_costs *= dataj.pct_housing[7]
        chh.house_value *= dataj.pct_housing[8]
        
        chh.total_wealth *= dataj.pct_wealth[1]
        chh.net_physical_wealth *= dataj.pct_wealth[2]
        chh.net_financial_wealth *= dataj.pct_wealth[3]
        chh.net_housing_wealth *= dataj.pct_wealth[4]
        chh.net_pension_wealth *= dataj.pct_wealth[5]

        for (pid,pers) in chh.people
            mult_income!( pers.income, dataj.pct_income_changes )
        end

        return chh
    end

end