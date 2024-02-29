module LegalAidCalculations

using ScottishTaxBenefitModel

using .ModelHousehold: 
    get_benefit_units,
    is_head,
    is_spouse,
    is_child,
    BenefitUnit,
    Household, 
    Person
using .Definitions

using .GeneralTaxComponents: 
    TaxResult, 
    calctaxdue

using .Results:
    get_indiv_result,
    BenefitUnitResult,
    HouseholdResult,
    LegalAidResult,
    OneLegalAidResult

using .STBIncomes

using .STBParameters:
    cont_proportion,
    cont_fixed,
    do_expense,
    sys_aa,
    sys_civil, 
    ContributionType, 
    OneLegalAidSys,
    ScottishLegalAidSys
    
using .Intermediate: 
    HHIntermed,
    MTIntermediate
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


function bandcalc( x :: Real, r :: Vector, t :: Vector,  cont_type :: ContributionType ) :: Real
    if cont_type == cont_proportion
        return calctaxdue(
            taxable=x,
            rates=r,
            thresholds=t ).due
    else
        n = length( r )
        for i in 1:n
            if x < t[i]
                return r[i]
            end
        end
    end
    return -1
end

"""
Benefit unit level legal aid.

FIXME capital and housing assigned to 1st bu only.
FIXME ttw costs not even imputed.
"""
function calc_legal_aid!(   
    benefit_unit_result :: BenefitUnitResult,
    household           :: Household, # for housing costs
    benefit_unit        :: BenefitUnit,
    buno                :: Integer,  
    intermed            :: MTIntermediate,
    lasys               :: OneLegalAidSys,
    extra_nondeps       :: Integer )
    
    bu = benefit_unit # alias
    bres = benefit_unit_result # alias
    onela = bres.legalaid.civil # alias
    if lasys.systype == sys_aa  
        onela = bres.legalaid.aa # alias
    end
    totinc = 0.0
    repayments = 0.0
    workexp = 0.0
    maintenance = 0.0
    hb = 0.0
    ct = 0.0
    ctb = 0.0
    child_costs = 0.0
    npeople = 1+extra_nondeps
    age_oldest = -1
    for (pid,pers) in bu.people
        income = bres.pers[pid].income
        # these are all actually the same number except living_allowance
        if any_positive( income, lasys.passported_benefits )
            onela.passported = true
            onela.entitlement = la_passported
            return
        end
        # CHECK next 3 - 2nd bus can't claim housing costs?? , but these should be zero anyway
        hb += income[HOUSING_BENEFIT]
        ctb += income[COUNCIL_TAX_BENEFIT]
        ct += income[LOCAL_TAXES]
        maintenance += income[ALIMONY_AND_CHILD_SUPPORT_PAID]
        child_costs += pers.cost_of_childcare
        workexp += make_ttw( pers )
        repayments += make_repayments( pers )
        age_oldest = max( pers.age, age_oldest )
        if pers.relationship_to_hoh == This_Person
            onela.income_allowances += lasys.income_living_allowance
        elseif pers.relationship_to_hoh == Spouse
            onela.income_allowances += lasys.income_partners_allowance
            npeople += 1
        elseif is_child( pers )
            onela.income_allowances += lasys.income_child_allowance
            npeople += 1
        end
        totinc += isum( income, lasys.incomes.included; deducted=lasys.incomes.deducted )
    end

    # aa capital allowances
    if length(lasys.capital_allowances) > 0
        for i in 1:npeople-1
            onela.capital_allowances += lasys.capital_allowances[i]
        end
    end 

    onela.income_allowances +=  (extra_nondeps * lasys.income_other_dependants_allowance)

    if buno == 1
        housing = max( 0.0, household.gross_rent - hb) +
                max( 0.0, ct - ctb ) +
                household.mortgage_interest +
                household.other_housing_charges
                #!!! FIXME insurance
        onela.housing = do_expense( housing, lasys.expenses.housing )
    end
    onela.childcare = do_expense( child_costs, lasys.expenses.childcare )
    onela.other_outgoings += do_expense( maintenance, lasys.expenses.maintenance )
    onela.other_outgoings += do_expense( repayments, lasys.expenses.debt_repayments )
    onela.work_expenses = do_expense( workexp, lasys.expenses.work_expenses )
    onela.net_income = totinc
    onela.outgoings = 
        onela.housing + 
        onela.childcare + 
        onela.other_outgoings + 
        onela.work_expenses
    onela.disposable_income = max( 0.0, 
        onela.net_income - 
        onela.outgoings - 
        onela.income_allowances )

    onela.eligible_on_income = onela.disposable_income < lasys.income_contribution_limits[end]

    # FIXME individual level 
    if buno == 1
        if net_physical_wealth in lasys.included_capital 
            onela.capital += household.net_physical_wealth
        end 
        if net_financial_wealth in lasys.included_capital 
            onela.capital += household.net_financial_wealth
        end 
        if net_housing_wealth in lasys.included_capital 
            onela.capital += household.net_housing_wealth
        end 
        if net_pension_wealth in lasys.included_capital 
            onela.capital += household.net_pension_wealth
        end 
    end
    # println( "onela.disposable_income = $(onela.disposable_income)")
    if age_oldest >= lasys.pensioner_age_limit
        onela.capital_allowances += bandcalc( 
            onela.disposable_income,
            lasys.capital_disregard_amounts,
            lasys.capital_disregard_limits,
            cont_fixed )
    end

    onela.disposable_capital = max( 0.0, onela.capital - onela.capital_allowances )
    onela.eligible_on_capital = onela.disposable_capital < lasys.capital_contribution_limits[end]
    onela.eligible = onela.eligible_on_capital && onela.eligible_on_income
    if onela.eligible
        onela.income_contribution = bandcalc( 
            onela.disposable_income,
            lasys.income_contribution_rates,
            lasys.income_contribution_limits,
            lasys.income_cont_type )
        onela.capital_contribution = bandcalc( 
            onela.disposable_capital,
            lasys.capital_contribution_rates,   
            lasys.capital_contribution_limits,
            lasys.capital_cont_type )
    end

    onela.entitlement = if (! onela.eligible)
        la_none
    elseif onela.passported # can't actually get here but leave in for completeness
        la_passported
    elseif (onela.income_contribution + onela.capital_contribution) > 0.0
        la_with_contribution
    else 
        la_full
    end

end # calc_legal_aid!



function get_problem_prob( pers :: Person ) :: NamedTuple


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
    bus = get_benefit_units(household)
    zero_income_bus = Set{Int}()
    for buno in eachindex(bus)
        if (buno > 1) && (household_result.bus[buno].net_income == 0.0)
            push!(zero_income_bus, buno)
        end
    end
    for buno in eachindex(bus)
        nzbus =  buno == 1 ? length( zero_income_bus ) : 0
        calc_legal_aid!(   
            household_result.bus[buno], #ben_unit_result  :: BenefitUnitResult,
            household,
            bus[buno], 
            buno,
            intermed.buint[buno],
            lasys,
            nzbus )
    end
end # calc_legal_aid!

end # module