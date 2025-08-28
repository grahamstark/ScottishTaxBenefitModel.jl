module HouseholdAdjuster

using ScottishTaxBenefitModel
using .Definitions
using .ModelHousehold
using .Results
using .STBIncomes
using .STBParameters

export adjusthh, apply_minimum_wage, apply_minumum_wage!

function mult_income!( incomes :: Incomes_Dict, mults :: Incomes_Dict)
    k1 = keys(incomes)
    k2 = keys(mults)
    kt = intersect(k1,k2)
    for k in kt
        incomes[k] *= mults[k]
    end
end

"""
Hacky thing to multiply housing costs, wealth and income components.
Returns a deep copy of hh if any change is to be made, othewise hh itself.
"""
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

"""
Massively crude min wage calculationm using wage/hours
where hours is usual hours where available. Ignores apprentices, all the
subtleties of the scheme, uses a crude wage/hours for hourly wage ...
This is dependent on the FRS data, where anyone earning is counted as employee/self-employed.
This is intended to be used on the results income array rather than 
"""
function apply_minimum_wage( 
    pers :: Person, 
    mwsys :: MinimumWage )::Real
    # FIXME!! Only apply to people whose main employment is not SE
    # see the note - there are 120-odd cases of both wage and se in Scottish subset
    # we ignore 
    # wage = 0.0
    wage = get( pers.income, Definitions.wages, 0.0 )
    minwage = get_minimum_wage( mwsys, pers.age )
        
    hours = if pers.usual_hours_worked > 0
        pers.usual_hours_worked
    elseif pers.actual_hours_worked > 0
        pers.actual_hours_worked
    elseif pers.employment_status in [
        Full_time_Employee,
        Full_time_Self_Employed]
        40.0
    elseif pers.employment_status in [
        Part_time_Employee,
        Part_time_Self_Employed]
        20.0
    elseif minwage > 0 # 0 wage - assume 
        wage/minwage
    else
        wage/10.0 # hack 10 per hour
    end
    if(wage > 0) && (hours > 0)
        se = get( pers.income, Definitions.self_employment_income, 0.0 )
        # println( "pid $(pers.pid) in minwage wage on entry = $wage hours $hours")     
        if se > wage # main source is SE - don't apply
            return wage
        elseif wage > 0 && se > 0 # proportionate where both wages and se reported FIXME hours data 
            hours = hours * (wage/(wage+se))
        end
        hourly_wage = wage / hours
        if hourly_wage < minwage
            wage = hours*minwage
        end   
        # println( "in minwage wage now = $wage")     
    end
    return wage
end

"""
Apply our crude MW across all adults in a household, changing
the Wages
"""
function apply_minumum_wage!( 
    hhres :: HouseholdResult, 
    hh :: Household, 
    mwsys :: MinimumWage )
    if mwsys.abolished
        return
    end
    bus = get_benefit_units(hh)
    nbus = size( bus )[1]
    for buno in 1:nbus
        for pid in bus[buno].adults
            hhres.bus[buno].pers[pid].income[WAGES] = 
                apply_minimum_wage( hh.people[pid], mwsys )
        end
    end
end

end