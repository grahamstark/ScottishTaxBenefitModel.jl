module LegalAidCalculations

using ScottishTaxBenefitModel
using Logging 

using .ModelHousehold: 
    get_benefit_units,
    get_head,
    get_spouse,
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

using .LegacyMeansTestedBenefits: calc_premia

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
    NonMeansTestedSys,
    AgeLimits,
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
    nmt_bens             :: NonMeansTestedSys,
    age_limits          :: AgeLimits,
    extra_nondeps       :: Integer )
    
    bu = benefit_unit # alias
    bres = benefit_unit_result # alias
    onela = OneLegalAidResult{Float64}() # FIXME float 64

    totinc = 0.0
    repayments = 0.0
    workexp = 0.0
    maintenance = 0.0
    ttw = 0.0
    hb = 0.0
    ct = 0.0
    ctb = 0.0
    # FIXME NOT USED FOR UC TEST
    onela.uc_income = bres.uc.total_income
    child_costs = 0.0
    npeople = 1+extra_nondeps
    age_oldest = -1

   prems, premset = calc_premia(
        Definitions.hb,
        bu,
        bres,
        intermed,
        lasys.premia,
        nmt_bens,
        age_limits )
    onela.extra_allowances = prems
    @debug prems 
    @debug premset
    for (pid,pers) in bu.people
        income = bres.pers[pid].income
        # CHECK next 3 - 2nd bus can't claim housing costs?? , but these should be zero anyway
        hb += income[HOUSING_BENEFIT]
        ctb += income[COUNCIL_TAX_BENEFIT]
        ct += income[LOCAL_TAXES]
        onela.uc_entitlement += income[UNIVERSAL_CREDIT]
        maintenance += income[ALIMONY_AND_CHILD_SUPPORT_PAID]
        child_costs += pers.cost_of_childcare
        workexp += pers.work_expenses + pers.travel_to_work
        repayments += pers.debt_repayments #  make_repayments( pers )
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
    end # people in bu

    # aa capital allowances
    if length(lasys.capital_allowances) > 0
        for i in 1:npeople-1
            onela.capital_allowances += lasys.capital_allowances[i]
        end
    end 

    onela.income_allowances +=  (extra_nondeps * lasys.income_other_dependants_allowance)

    if buno == 1
        # gross housing costs and treating CTB HB as income
        mp = lasys.include_mortgage_repayments ? 
            household.mortgage_payment : 0.0
        housing = household.gross_rent +
                ct + 
                # max( 0.0, household.gross_rent - hb) +
                # max( 0.0, ct - ctb ) +
                mp + # NOTE NOT ACTUALLY PAYMENT - CAPITAL FIX NAME
                household.mortgage_interest +
                household.other_housing_charges
                #!!! FIXME insurance
        onela.housing = do_expense( housing, lasys.expenses.housing )
    end
    onela.childcare = do_expense( child_costs, lasys.expenses.childcare )
    onela.maintenance += do_expense( maintenance, lasys.expenses.maintenance )
    onela.repayments += do_expense( repayments, lasys.expenses.repayments )
    onela.work_expenses = do_expense( workexp, lasys.expenses.work_expenses )
    onela.net_income = totinc
    onela.outgoings = 
        onela.housing + 
        onela.childcare + 
        onela.maintenance +
        onela.repayments +
        onela.work_expenses
    onela.disposable_income = max( 0.0, 
        onela.net_income - 
        onela.outgoings - 
        onela.income_allowances - 
        onela.extra_allowances )

    onela.eligible_on_income = onela.disposable_income < lasys.income_contribution_limits[end]

    if net_physical_wealth in lasys.included_capital 
        onela.capital += intermed.net_physical_wealth
    end 
    if net_financial_wealth in lasys.included_capital 
        onela.capital += intermed.net_financial_wealth
    end 
    if net_housing_wealth in lasys.included_capital 
        onela.capital += intermed.net_housing_wealth
    end 
    if net_pension_wealth in lasys.included_capital 
        onela.capital += intermed.net_pension_wealth
    end 
    
    #=
    # FIXME individual level 
    if lasys.use_inferred_capital 
        # if buno == 1
        end
    else
        if  net_physical_wealth in lasys.included_capital
            head = get_head( bu )
            onela.capital += head.wealth_and_assets
            spouse = get_spouse( bu )
            if ! isnothing( spouse )
                onela.capital += spouse.wealth_and_assets
            end
        end
    end
    =#

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
    passported_on_uc = false
    for (pid,pers) in bu.people
        if any_positive( bres.pers[pid].income, lasys.passported_benefits )
            onela.passported = true
        end
        if ( UNIVERSAL_CREDIT in lasys.passported_benefits ) && 
            any_positive( bres.pers[pid].income, [UNIVERSAL_CREDIT] )
            passported_on_uc = true
        end
    end
    if lasys.systype == sys_aa # turn off passported for AA if ineligible on capital - K's note.
        if ! onela.eligible_on_capital
            onela.passported = false # onela.passported
        end
    end
    if passported_on_uc # proposed uc non-passport
        if lasys.uc_limit_type == uc_max_income
            # remove passport based on either uc
            # earnings or assessed net income
            ucinc = lasys.uc_use_earnings ? bres.uc.earned_income : onela.net_income
            if ucinc > lasys.uc_limit
                onela.passported = false
            end
        elseif lasys.uc_limit_type == uc_min_payment
            if onela.uc_entitlement < lasys.uc_limit
                onela.passported = false
            end
        end
    end # UC Passo[port ]
    onela.entitlement = if onela.passported 
        la_passported
    elseif (! onela.eligible)
        la_none
    elseif (onela.income_contribution + onela.capital_contribution) > 0.0
        la_with_contribution
    else 
        la_full
    end
    if lasys.systype == sys_aa  
        bres.legalaid.aa = onela # alias
    else 
        bres.legalaid.civil = onela # alias
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
    lasys            :: OneLegalAidSys,
    nmt_bens         :: NonMeansTestedSys,
    age_limits       :: AgeLimits )
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
            nmt_bens,
            age_limits,
            nzbus )
    end
end # calc_legal_aid!

end # module