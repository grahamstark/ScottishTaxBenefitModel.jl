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
    do_expense,
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
    civla = bres.legalaid.civil # alias
        
    totinc = 0.0
    repayments = 0.0
    workexp = 0.0
    maintenance = 0.0
    hb = 0.0
    ct = 0.0
    ctb = 0.0
    child_costs = 0.0
    for (pid,pers) in bu.people
        income = bres.pers[pid].income
        # these are all actually the same number except living_allowance
        if any_positive( income, lasys.passported_benefits )
            civla.passported = true
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
        if pers.relationship_to_hoh == This_Person
            civla.allowances += lasys.living_allowance
        elseif pers.relationship_to_hoh == Spouse
            civla.allowances += lasys.partners_allowance
        elseif is_child( pers )
            civla.allowances += lasys.child_allowance
        end
        totinc += isum( income, lasys.incomes.included; deducted=lasys.incomes.deducted )
    end
    civla.allowances +=  (extra_nondeps * lasys.other_dependants_allowance)
    if buno == 1
        housing = max( 0.0, household.gross_rent - hb) +
                max( 0.0, ct - ctb ) +
                household.mortgage_interest +
                household.other_housing_charges
                #!!! FIXME insurance
        civla.housing = do_expense( housing, lasys.expenses.housing )
    end
    civla.childcare = do_expense( child_costs, lasys.expenses.childcare )
    civla.other_outgoings += do_expense( maintenance, lasys.expenses.maintenance )
    civla.other_outgoings += do_expense( repayments, lasys.expenses.debt_repayments )
    civla.work_expenses = do_expense( workexp, lasys.expenses.work_expenses )
    civla.net_income = totinc
    civla.outgoings = 
        civla.housing + 
        civla.childcare + 
        civla.other_outgoings + 
        civla.work_expenses
    civla.disposable_income = max( 0.0, 
        civla.net_income - 
        civla.outgoings - 
        civla.allowances )

    civla.eligible_on_income = civla.disposable_income < lasys.contribution_limits[end]

    wealth = 0.0
    # FIXME individual level 
    if buno == 1
        if net_physical_wealth in lasys.included_wealth 
            wealth += household.net_physical_wealth
        end 
        if net_financial_wealth in lasys.included_wealth 
            wealth += household.net_financial_wealth
        end 
        if net_housing_wealth in lasys.included_wealth 
            wealth += household.net_housing_wealth
        end 
        if net_pension_wealth in lasys.included_wealth 
            wealth += household.net_pension_wealth
        end 
    end
    civla.eligible_on_wealth = wealth < lasys.capital_upper_limit 
    civla.eligible = civla.eligible_on_wealth && civla.eligible_on_income
    if civla.eligible
        civla.capital_contribution = max( 0.0, wealth - lasys.capital_lower_limit )
        civla.income_contribution = calctaxdue(
            taxable=civla.disposable_income,
            rates=lasys.contribution_rates,
            thresholds=lasys.contribution_limits ).due
    end
end # calc_legal_aid!

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