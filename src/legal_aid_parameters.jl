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
@enum Net_Or_Gross net gross
@enum Assessment_Period weekly monthly annualHistoric annualForward
export ContributionType, cont_proportion, cont_fixed
@enum ContributionType cont_proportion cont_fixed

@with_kw mutable struct Expenses{T}
    housing               = Expense( false, one(T), typemax(T))
    debt_repayments       = Expense( false, one(T), typemax(T))
    childcare             = Expense( false, one(T), typemax(T))
    work_expenses         = Expense( false, one(T), typemax(T))
    maintenance           = Expense( false, one(T), typemax(T))
    repayments            = Expense( false, one(T), typemax(T))
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
        
        CHILD_BENEFIT,
        STATE_PENSION,
        BEREAVEMENT_ALLOWANCE, 
        ARMED_FORCES_COMPENSATION_SCHEME,
        WAR_WIDOWS_PENSION,
        SEVERE_DISABILITY_ALLOWANCE,
        ATTENDANCE_ALLOWANCE,
        CARERS_ALLOWANCE,
        INDUSTRIAL_INJURY_BENEFIT,
        INCAPACITY_BENEFIT,
        PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
        PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY,
        DLA_SELF_CARE,
        DLA_MOBILITY,
        EDUCATION_ALLOWANCES,
        FOSTER_CARE_PAYMENTS,
        MATERNITY_ALLOWANCE,
        MATERNITY_GRANT,
        FUNERAL_GRANT,
        ANY_OTHER_NI_OR_STATE_BENEFIT,
        FRIENDLY_SOCIETY_BENEFITS,
        GOVERNMENT_TRAINING_ALLOWANCES,
        CONTRIB_JOBSEEKERS_ALLOWANCE,
        GUARDIANS_ALLOWANCE,
        WIDOWS_PAYMENT,
        WINTER_FUEL_PAYMENTS,
        # legacy mt benefits
        WORKING_TAX_CREDIT,
        CHILD_TAX_CREDIT,
        NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE, # ppt
        INCOME_SUPPORT, # ppt
        # PENSION_CREDIT,
        # SAVINGS_CREDIT 
        NON_CONTRIB_JOBSEEKERS_ALLOWANCE, # ppt
        # HOUSING_BENEFIT, netted off housing 
        
        FREE_SCHOOL_MEALS,
        UNIVERSAL_CREDIT, # ppt, but in case not
        OTHER_BENEFITS,
        STUDENT_GRANTS,
        STUDENT_LOANS,
        # COUNCIL_TAX_BENEFIT netted off ct
        CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
    
        SCOTTISH_CHILD_PAYMENT, # should always be ppt
        SCOTTISH_CARERS_SUPPLEMENT, # 
    
        DISCRESIONARY_HOUSING_PAYMENT,  # not just Scottish, but, hey..
     
        SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_DAILY_LIVING,
        SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_MOBILITY,
        SCOTTISH_DISABILITY_ASSISTANCE_OLDER_PEOPLE,
        SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_DAILY_LIVING,
        SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_MOBILITY,
        UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE 
    ],
    [        
        INCOME_TAX,
        NATIONAL_INSURANCE,
        LOCAL_TAXES         
    ] )

@with_kw mutable struct OneLegalAidSys{RT}
    abolished = false
    title = ""
    systype = sys_civil
    gross_income_limit        = typemax(RT)
    incomes    :: IncludedItems = DEFAULT_LA_INCOME
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
        aa.capital_disregard_amounts :: RateBands{RT} =  [25_000,20_000,15_0000,10_000,5_000]
        # allowances are all zero
        aa.expenses.housing = Expense( false, zero(RT), typemax(RT))
        aa.expenses.debt_repayments = Expense( false, zero(RT), typemax(RT))
        aa.expenses.childcare = Expense( false, zero(RT), typemax(RT))
        aa.expenses.work_expenses = Expense( false, zero(RT), typemax(RT))
        aa.expenses.maintenance = Expense( false, zero(RT), typemax(RT))
        aa.expenses.repayments = Expense( false, zero(RT), typemax(RT))
    end
    aa
end

@with_kw mutable struct ScottishLegalAidSys{RT}
    civil = OneLegalAidSys{RT}()
    aa    = default_aa_sys( 2023, RT )
end

"""
express aa weekly and civil annually
"""
function weeklyise!( la :: OneLegalAidSys )
    if la.systype == sys_aa
        # la.income_contribution_rates ./= 100
        # la.capital_contribution_rates ./= 100
        return 
    else
        la.income_living_allowance /= WEEKS_PER_YEAR
        la.income_partners_allowance         /= WEEKS_PER_YEAR
        la.income_other_dependants_allowance /= WEEKS_PER_YEAR
        la.income_child_allowance            /= WEEKS_PER_YEAR
        la.income_contribution_rates ./= 100
        la.income_contribution_limits ./= WEEKS_PER_YEAR
        la.capital_contribution_rates ./= 100.0
        # la.capital_contribution_limits ./= WEEKS_PER_YEAR
        
    end
end

function weeklyise!( sla :: ScottishLegalAidSys )
    weeklyise!( sla.civil )
    weeklyise!( sla.aa )
end

