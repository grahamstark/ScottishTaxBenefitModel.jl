#=

 This is the one.
 https://www.slab.org.uk/solicitors/other-resources/key-cards/civil-keycard/


=#


@enum SystemType sys_civil sys_aa
@enum ClaimType normalClaim  personalInjuryClaim
@enum PensionerState pensioner  nonPensioner
@enum Income_Or_Capital income  capital
@enum Net_Or_Gross net  gross
@enum Assessment_Period weekly  monthly  annualHistoric  annualForward
@enum ContributionType proportion  fixed

@with_kw mutable struct Expenses{T}
    housing               = Expense( false, one(T), typemax(T))
    #=
    council_tax           = Expense( false, one(T), typemax(T))
    water_rates           = Expense( false, one(T), typemax(T))
    ground_rent           = Expense( false, one(T), typemax(T))
    service_charges       = Expense( false, one(T), typemax(T))
    repairs_and_insurance = Expense( false, one(T), typemax(T))
    rent                  = Expense( false, one(T), typemax(T))
    =#
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

    living_allowance           = zero(RT)
    partners_allowance         = RT(2529)
    other_dependants_allowance = RT(4056)
    child_allowance            = RT(4056)
    
    cont_type               = proportion
    contribution_rates :: RateBands{RT} =  [0.0,33.0,50.0,100.0]
    contribution_limits :: RateBands{RT} =  [3_521.0, 11_540.0, 15_743, 26_239.0]
        
        
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
    expenses = Expenses{RT}()

end

@with_kw mutable struct ScottishLegalAidSys{RT}
    civil = OneLegalAidSys{RT}()
    aa    = OneLegalAidSys{RT}()
end

"""
express aa weekly and civil annually
"""
function weeklyise!( la :: OneLegalAidSys )
    if la.systype == sys_aa
        la.contribution_rates ./= 100
        return 
    else
        la.living_allowance /= WEEKS_PER_YEAR
        la.partners_allowance         /= WEEKS_PER_YEAR
        la.other_dependants_allowance /= WEEKS_PER_YEAR
        la.child_allowance            /= WEEKS_PER_YEAR
        la.contribution_rates ./= 100
        la.contribution_limits ./= WEEKS_PER_YEAR
    end
end

function weeklyise!( sla :: ScottishLegalAidSys )
    weeklyise!( sla.civil )
    weeklyise!( sla.aa )
end

