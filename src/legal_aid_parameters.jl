#=

 This is the one.
 https://www.slab.org.uk/solicitors/other-resources/key-cards/civil-keycard/


=#

@enum SystemType sys_civil sys_aa
export SystemType, sys_civil, sys_aa
@enum ClaimType normalClaim  personalInjuryClaim
export ClaimType, normalClaim,  personalInjuryClaim
@enum PensionerState pensioner  nonPensioner
export PensionerState, pensioner, nonPensioner
@enum Income_Or_Capital income capital
export Income_Or_Capital, income, capital
@enum Net_Or_Gross net gross
export Net_Or_Gross, net, gross
@enum Assessment_Period weekly monthly annualHistoric annualForward
export ContributionType, cont_proportion, cont_fixed
@enum ContributionType cont_proportion cont_fixed

"""
needed because json (inf) isn't supported and typemax(somefloattype) == Inf
"""
function inplaceoftypemax(T)
    return T(99999999999)
end

@with_kw mutable struct Expenses{T}
    housing               = Expense( false, T(100), inplaceoftypemax(T))
    childcare             = Expense( false, T(100), inplaceoftypemax(T))
    work_expenses         = Expense( false, T(100), inplaceoftypemax(T))
    maintenance           = Expense( false, T(100), inplaceoftypemax(T))
    repayments            = Expense( false, T(100), inplaceoftypemax(T))
end

const DEFAULT_LA_INCOME = IncludedItems(
    [
        WAGES,
        SELF_EMPLOYMENT_INCOME,
        PRIVATE_PENSIONS,
        NATIONAL_SAVINGS,
        BANK_INTEREST,
        STOCKS_SHARES,
        INDIVIDUAL_SAVINGS_ACCOUNT,
        PROPERTY, 
        ROYALTIES, 
        BONDS_AND_GILTS, 
        OTHER_INVESTMENT_INCOME,
        OTHER_INCOME,
        ALIMONY_AND_CHILD_SUPPORT_RECEIVED,
        PRIVATE_SICKNESS_SCHEME_BENEFITS,
        ACCIDENT_INSURANCE_SCHEME_BENEFITS, 
        HOSPITAL_SAVINGS_SCHEME_BENEFITS,
        UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE, 
        PERMANENT_HEALTH_INSURANCE,
        ANY_OTHER_SICKNESS_INSURANCE, 
        CRITICAL_ILLNESS_COVER,
        TRADE_UNION_SICK_OR_STRIKE_PAY,
        

    ],
    [        
        INCOME_TAX,
        NATIONAL_INSURANCE,
        LOCAL_TAXES        
    ] )

# https://www.slab.org.uk/solicitors/legal-aid-legislation/civil-legal-aid-regulations/the-civil-legal-aid-scotland-regulations-2002/#contS2
const DISREGARDED_BENEFITS_CIVIL = [
    # 5:
    INCOME_SUPPORT,
    NON_CONTRIB_JOBSEEKERS_ALLOWANCE, 
    NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE, # ppt
    
    PENSION_CREDIT,
    SAVINGS_CREDIT,
    
    UNIVERSAL_CREDIT, # ppt, but in case not
    # 7:
    ATTENDANCE_ALLOWANCE,
    CARERS_ALLOWANCE,        
    SCOTTISH_CARERS_SUPPLEMENT,
    SEVERE_DISABILITY_ALLOWANCE,
    DLA_SELF_CARE,
    DLA_MOBILITY,
    PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
    PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY,
    SCOTTISH_CHILD_PAYMENT, # should always be ppt
    SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_DAILY_LIVING,
    SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_MOBILITY,
    SCOTTISH_DISABILITY_ASSISTANCE_OLDER_PEOPLE,
    SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_DAILY_LIVING,
    SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_MOBILITY,
]

# https://www.slab.org.uk/solicitors/legal-aid-legislation/advice-and-assistance/the-advice-and-assistance-scotland-regulations-1996/#contS2
# #5
const  DISREGARDED_BENEFITS_AA = [
    PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
    PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY,
    SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_DAILY_LIVING,
    SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_MOBILITY,
    SCOTTISH_DISABILITY_ASSISTANCE_OLDER_PEOPLE,
    SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_DAILY_LIVING,
    SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_MOBILITY,
    DLA_SELF_CARE,
    DLA_MOBILITY,
    SEVERE_DISABILITY_ALLOWANCE,
    STATE_PENSION,
    HOUSING_BENEFIT,
    COUNCIL_TAX_BENEFIT
]

function zero_premia( RT :: DataType ) :: Premia
    prems = Premia{RT}()
    prems.family = zero( RT )
    prems.family_lone_parent = zero( RT ) # FIXME this is not used??
    prems.disabled_child = zero( RT )
    prems.carer_single = zero( RT )
    prems.carer_couple = zero( RT )
    prems.disability_single = zero( RT )
    prems.disability_couple = zero( RT )
    prems.enhanced_disability_child = zero( RT )
    prems.enhanced_disability_single = zero( RT )
    prems.enhanced_disability_couple = zero( RT )
    prems.severe_disability_single = zero( RT )
    prems.severe_disability_couple = zero( RT )
    prems.pensioner_is = zero( RT )
    return prems
end

"""
Since this isn't neeed in the main params - weekly anyway
"""
function weeklyise!( prems :: Premia; wpy = WEEKS_PER_YEAR )
    prems.family /= wpy
    prems.family_lone_parent /= wpy # FIXME this is not used??
    prems.disabled_child /= wpy
    prems.carer_single /= wpy
    prems.carer_couple /= wpy
    prems.disability_single /= wpy
    prems.disability_couple /= wpy
    prems.enhanced_disability_child /= wpy
    prems.enhanced_disability_single /= wpy
    prems.enhanced_disability_couple /= wpy
    prems.severe_disability_single /= wpy
    prems.severe_disability_couple /= wpy
    prems.pensioner_is /= wpy
end

function get_default_incomes( systype :: SystemType )::IncludedItems
    incs = DEFAULT_LA_INCOME
    union!(incs.included, BENEFITS)
    if systype == sys_civil 
        setdiff!( incs.included, DISREGARDED_BENEFITS_CIVIL )
    else 
        setdiff!( incs.included, DISREGARDED_BENEFITS_AA )
    end
    # @show incs.included
    incs
end


@with_kw mutable struct OneLegalAidSys{RT}
    abolished = false
    title = ""
    systype = sys_civil
    gross_income_limit        = inplaceoftypemax(RT)
    incomes    :: IncludedItems = get_default_incomes( sys_civil ) 
    income_living_allowance           = zero(RT)
    income_partners_allowance         = RT(2529)
    income_other_dependants_allowance = RT(4056)
    income_child_allowance            = RT(4056)
    capital_allowances                = RT.([])    
    income_cont_type = cont_proportion 
    capital_cont_type = cont_proportion
    income_contribution_rates :: RateBands{RT} =  [0.0,33.0,50.0,100.0]
    income_contribution_limits :: RateBands{RT} =  [3_521.0, 11_540.0, 15_743, 26_239.0]        
    
    passported_benefits        = IncomesSet([
        INCOME_SUPPORT, 
        NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
        NON_CONTRIB_JOBSEEKERS_ALLOWANCE, 
        UNIVERSAL_CREDIT])
    pensioner_age_limit        = 9999
    # capital from wealth tax
    included_capital = WealthSet([net_financial_wealth,net_physical_wealth])
    expenses = Expenses{RT}()
    capital_contribution_rates  :: RateBands{RT} =  [0,100.0]
    capital_contribution_limits :: RateBands{RT} =  [7_853.0, 13_017.0]
    capital_disregard_limits = zeros(RT,0)
    capital_disregard_amounts = zeros(RT,0)
    use_inferred_capital = true
    premia = zero_premia(RT)
    uc_limit = zero(RT)
    uc_limit_type :: UCLimitType = uc_no_limit
    uc_use_earnings = false
end

"""
# fixme we need default Civil sys as well
"""

function default_civil_sys( year::Integer, RT )::OneLegalAidSys
    if year == 2023
        return OneLegalAidSys{RT}()
    end
end

function default_aa_sys( year::Integer, RT )::OneLegalAidSys
    @assert year in [2023] "no sys yet for $year"
    aa = OneLegalAidSys{RT}()
    aa.incomes = get_default_incomes( sys_aa ) 
    if year == 2023
        aa.systype = sys_aa
        aa.income_living_allowance           = zero(RT)
        aa.income_partners_allowance         = RT(48.50) # note: these are civil /52 but rounded weirdly
        aa.income_other_dependants_allowance = RT(77.78)
        aa.income_child_allowance            = RT(77.78)
        aa.capital_contribution_rates=  [0.0]
        aa.capital_contribution_limits =  [1716.0]
        # there's got to be some rational explanation for this ...
        # this is just a weird way of saying 'everything above £105, with £7..
        aa.income_cont_type = cont_fixed
        aa.capital_cont_type = cont_proportion
        aa.pensioner_age_limit = 60
        aa.income_contribution_rates =  RT.(collect((0:7:135))); aa.income_contribution_rates[end]+=2
        aa.income_contribution_limits =  aa.income_contribution_rates .+ 105; aa.income_contribution_limits[end] += 5
        # this is not right; it's just 1st person 2nd ... 
        aa.capital_allowances         = RT.([335,200,fill(100,20)...])            
        aa.capital_disregard_limits :: RateBands{RT} =  [10,22,34,46,105]
        aa.capital_disregard_amounts :: RateBands{RT} =  [25_000,20_000,15_000,10_000,5_000]
        # allowances are all zero
        aa.expenses.housing = Expense( false, zero(RT), inplaceoftypemax(RT))
        aa.expenses.childcare = Expense( false, zero(RT), inplaceoftypemax(RT))
        aa.expenses.work_expenses = Expense( false, zero(RT), inplaceoftypemax(RT))
        aa.expenses.maintenance = Expense( false, zero(RT), inplaceoftypemax(RT))
        aa.expenses.repayments = Expense( false, zero(RT), inplaceoftypemax(RT))
    end
    aa
end

@with_kw mutable struct ScottishLegalAidSys{RT}
    civil = OneLegalAidSys{RT}()
    aa    = default_aa_sys( 2023, RT )
end

function weeklyise( ex :: Expense{T}; wpy = WEEKS_PER_YEAR ) :: Expense{T} where T
    max = ex.max
    v = ex.v
    if ex.is_flat
        v /= wpy
        if max < inplaceoftypemax(T)
            max /= wpy
        end
    else
        v /= 100 
    end
    return Expense( ex.is_flat, v, max )
end

function weeklyise!( ex :: Expenses; wpy = WEEKS_PER_YEAR )
    ex.housing = weeklyise( ex.housing )
    ex.childcare = weeklyise( ex.childcare )
    ex.work_expenses = weeklyise( ex.work_expenses )
    ex.maintenance = weeklyise( ex.maintenance )
    ex.repayments = weeklyise( ex.repayments )
end

"""
express aa weekly and civil annually
"""
function weeklyise!( la :: OneLegalAidSys )
    if la.systype == sys_aa
        # la.income_contribution_rates ./= 100
        # la.capital_contribution_rates ./= 100
        weeklyise!(la.expenses; wpy=1.0 )
        return 
    else
        la.uc_limit /= WEEKS_PER_YEAR
        la.income_living_allowance /= WEEKS_PER_YEAR
        la.income_partners_allowance         /= WEEKS_PER_YEAR
        la.income_other_dependants_allowance /= WEEKS_PER_YEAR
        la.income_child_allowance            /= WEEKS_PER_YEAR
        la.income_contribution_rates ./= 100
        la.income_contribution_limits ./= WEEKS_PER_YEAR
        la.capital_contribution_rates ./= 100.0
        # la.capital_contribution_limits ./= WEEKS_PER_YEAR
        weeklyise!(la.expenses; wpy=WEEKS_PER_YEAR )
        weeklyise!(la.premia; wpy=WEEKS_PER_YEAR )
    end
end

function weeklyise!( sla :: ScottishLegalAidSys )
    weeklyise!( sla.civil )
    weeklyise!( sla.aa )
end

