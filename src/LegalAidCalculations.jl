module LegalAidCalculations

using ScottishTaxBenefitModel

using .ModelHousehold: 
    BenefitUnit,
    Household, 
    Person
using .Definitions

using .GeneralTaxComponents: 
    TaxResult, 
    calctaxdue

using .Results:
    HouseholdResult,
    LegalAidResult,
    OneLegalAidResult

using .STBIncomes

using .STBParameters:
    OneLegalAidSys,
    ScottishLegalAidSys

using .Intermediate: 
    HHIntermed
export calc_legal_aid!

function make_ttw( pers :: Person ) 
    # FIXME
    if pers.employment_status in [Full_time_Employee,
        Part_time_Employee,
        Full_time_Self_Employed,
        Part_time_Self_Employed]
        return 20.0
    end
    return 0.0
end

function make_repayments( pers :: Person )
    # FIXME
    return 0.0
end

"""
Calculated solely at the HH level 
"""
function calc_legal_aid!(     
    household_result :: HouseholdResult,
    household        :: Household,
    intermed         :: HHIntermed,
    lasys            :: OneLegalAidSys )
    if lasys.abolished
        return
    end
    hh = household # alias
    hr = household_result # alias
    civla = hr.legalaid.civil # alias
   
    
    totinc = 0.0
    repayments = 0.0
    other = 0.0
    workexp = 0.0
    maintenance = 0.0
    hb = 0.0
    ct = 0.0
    ctb = 0.0
    child_costs = 0.0
    for (pid,pers) in household.people
        income = get_indiv_result( hres, pid ).income
        # these are all actually the same number except living_allowance
        if any_positive( income, lasys.passported_benefits )
            civla.passported = true
            return
        end
        hb += income[HOUSING_BENEFIT]
        ctb += income[COUNCIL_TAX_BENEFIT]
        ct += income[LOCAL_TAXES]
        maintenance += income[ALIMONY_AND_CHILD_SUPPORT_PAID]
        child_costs += pers.cost_of_childcare
        workexp += make_ttw( pers )
        repayments += make_repayments( pers )
        if is_head( pers )
            civla.allowances += lasys.living_allowance
        elseif is_spouse( pers )
            civla.allowances += lasys.partners_allowance
        elseif is_child( pers )
            civla.allowances += lasys.child_allowance
        else
            civla.allowances += lasys.other_dependants_allowance
        end
        totinc += isum( income, lasys.incomes.included, lasys.incomes.deducted )
    end
    housing = max( 0.0, hh.gross_rent - hb), lasys.expenses. +
              max( 0.0, ct - ctb ) +
              hh.mortgage_interest +
              hh.other_housing_charges
              #!!! insurance
    civla.housing = do_expense( housing, lasys.expenses.housing )
    civla.childcare = do_expense( housing, lasys.expenses.childcare )
    civla.other_outgoings += do_expense( maintenance, lasys.expenses.maintenance )
    civla.other_outgoings += do_expense( other, lasys.expenses.debt )
    civla.other_outgoings += do_expense( repayments, lasys.expenses.repayments )
    civla.work_expenses = do_expense( workexp, lasys.expenses.work_expenses )
    civla.net_income = totinc
    civla.outgoings = civla.housing + civla.childcare + civla.other_outgoings + civla.work_expenses
    civla.disposable_income = max( 0.0, civla.net_income - civla.outgoings - civla.allowances )

    civla.eligible_on_income = civla.disposable_income < contribution_limits[1]
    wealth = 0.0
    if net_physical_wealth in lasys.included_wealth 
        wealth += hh.net_physical_wealth
    end 
    if net_financial_wealth in lasys.included_wealth 
        wealth += hh.net_financial_wealth
    end 
    if net_housing_wealth in lasys.included_wealth 
        wealth += hh.net_housing_wealth
    end 
    if net_pension_wealth in lasys.included_wealth 
        wealth += hh.net_pension_wealth
    end 
    civla.eligible_on_wealth = wealth < lasys.capital_upper_limit 
    if civla.eligible_on_wealth && civla.eligible_on_income
        civla.capital_contribution = max( 0.0, wealth - lasys.capital_lower_limit )
        civla.income_contribution = calctaxdue(
            taxable=civla.disposable_income,
            rates=lasys.contribution_rates,
            thresholds=lasys.contribution_limits ).due
    end
end # calc_legal_aid!

end # module

#=

@with_kw mutable struct OneLegalAidResult{RT<:Real}
        income = zero(RT)
        housing = zero(RT)
        work_expenses = zero(RT)
        other_outgoings = zero(RT)
        wealth = zero(RT)
        passported = false
        eligible   = false
        eligible_on_income = false
        eligible_on_wealth = false
        income_contribution = zero(RT)
        income_contribution_pw = zero(RT)
        capital_contribution = zero(RT)
        allowances = zero(RT)
        disposable_income = zero(RT)
end
    
gross_income_limit        = typemax(RT)
incomes    :: IncludedItems = DEFAULT_LA_INCOME

living_allowance           = zero(RT)
partners_allowance         = RT(2529)
other_dependants_allowance = RT(4074)
child_allowance            = RT(4074)

cont_type               = proportion
contribution_rates :: RateBands{RT} =  [0.0,33.0,50.0,100.0]
contribution_limits :: RateBands{RT} =  [3_521.0, 11_544.0, 15_744, 26_329.0]
    
    
passported_benefits        = IncomesSet([
    INCOME_SUPPORT, 
    NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
    NON_CONTRIB_JOBSEEKERS_ALLOWANCE, 
    UNIVERSAL_CREDIT])

pensioner_age_limit        = 60

# capital from wealth tax
included_wealth = WealthSet([net_financial_wealth])
capital_lower_limit = RT(7_853.0)
capital_upper_limit = RT(13_017.0)

=#