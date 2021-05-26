module Incomes
    
    using ScottishTaxBenefitModel
    using .Definitions
    using StaticArrays
    using .ModelHousehold: Person

    # declarations  ----------------
    const WAGES = 1
    const SELF_EMPLOYMENT_INCOME = 2
    const ODD_JOBS = 3
    const PRIVATE_PENSIONS = 4
    const NATIONAL_SAVINGS = 5
    const BANK_INTEREST = 6
    const STOCKS_SHARES = 7
    const INDIVIDUAL_SAVINGS_ACCOUNT = 8
    const PROPERTY = 9
    const ROYALTIES = 10
    const BONDS_AND_GILTS = 11
    const OTHER_INVESTMENT_INCOME = 12
    const OTHER_INCOME = 13
    const ALIMONY_AND_CHILD_SUPPORT_RECEIVED = 14
    const PRIVATE_SICKNESS_SCHEME_BENEFITS = 15
    const ACCIDENT_INSURANCE_SCHEME_BENEFITS = 16
    const HOSPITAL_SAVINGS_SCHEME_BENEFITS = 17
    const UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE = 18
    const PERMANENT_HEALTH_INSURANCE = 19
    const ANY_OTHER_SICKNESS_INSURANCE = 20
    const CRITICAL_ILLNESS_COVER = 21
    const TRADE_UNION_SICK_OR_STRIKE_PAY = 22
    const SPARE_INC_1 = 23
    const SPARE_INC_2 = 24
    const SPARE_INC_3 = 25
    const SPARE_INC_4 = 26
    const SPARE_INC_5 = 27


    const HEALTH_INSURANCE = 28
    const ALIMONY_AND_CHILD_SUPPORT_PAID = 29
    const TRADE_UNIONS_ETC = 30
    const FRIENDLY_SOCIETIES = 31
    const WORK_EXPENSES = 32
    const AVCS = 33
    const OTHER_DEDUCTIONS = 34
    const LOAN_REPAYMENTS = 35
    const PENSION_CONTRIBUTIONS_EMPLOYEE = 36
    const PENSION_CONTRIBUTIONS_EMPLOYER = 37
    const SPARE_DEDUCT_1 = 38
    const SPARE_DEDUCT_2 = 39
    const SPARE_DEDUCT_3 = 40
    const SPARE_DEDUCT_4 = 41
    const SPARE_DEDUCT_5 = 42

    const INCOME_TAX = 43
    const NATIONAL_INSURANCE = 44
    const LOCAL_TAXES = 45
    const SOCIAL_FUND_LOAN_REPAYMENT = 46
    const STUDENT_LOAN_REPAYMENTS = 47
    const CARE_INSURANCE = 48
    const SPARE_TAX_1 = 49
    const SPARE_TAX_2 = 50
    const SPARE_TAX_3 = 51
    const SPARE_TAX_4 = 52
    const SPARE_TAX_5 = 53

    const CHILD_BENEFIT = 54
    const STATE_PENSION = 55
    const BEREAVEMENT_ALLOWANCE = 56
    const ARMED_FORCES_COMPENSATION_SCHEME = 57
    const WAR_WIDOWS_PENSION = 58
    const SEVERE_DISABILITY_ALLOWANCE = 59
    const ATTENDENCE_ALLOWANCE = 60
    const CARERS_ALLOWANCE = 61
    const INDUSTRIAL_INJURY_BENEFIT = 62
    const INCAPACITY_BENEFIT = 63
    const PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING = 64
    const PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY = 65
    const DLA_SELF_CARE = 66
    const DLA_MOBILITY = 67
    const EDUCATION_ALLOWANCES = 68
    const FOSTER_CARE_PAYMENTS = 69
    const MATERNITY_ALLOWANCE = 70
    const MATERNITY_GRANT = 71
    const FUNERAL_GRANT = 72
    const ANY_OTHER_NI_OR_STATE_BENEFIT = 73
    const FRIENDLY_SOCIETY_BENEFITS = 74
    const GOVERNMENT_TRAINING_ALLOWANCES = 75
    const CONTRIB_JOBSEEKERS_ALLOWANCE = 76
    const GUARDIANS_ALLOWANCE = 77
    const WIDOWS_PAYMENT = 78
    const WINTER_FUEL_PAYMENTS = 79
    const WORKING_TAX_CREDIT = 80
    const CHILD_TAX_CREDIT = 81
    const EMPLOYMENT_AND_SUPPORT_ALLOWANCE = 82
    const INCOME_SUPPORT = 83
    const PENSION_CREDIT = 84
    const SAVINGS_CREDIT = 85
    const NON_CONTRIB_JOBSEEKERS_ALLOWANCE = 86
    const HOUSING_BENEFIT = 87
    const FREE_SCHOOL_MEALS = 88
    const UNIVERSAL_CREDIT = 89
    const OTHER_BENEFITS = 90
    const STUDENT_GRANTS = 91
    const STUDENT_LOANS = 92
    const COUNCIL_TAX_BENEFIT = 93
    const SPARE_BEN_1 = 94
    const SPARE_BEN_2 = 95
    const SPARE_BEN_3 = 96
    const SPARE_BEN_4 = 97
    const SPARE_BEN_5 = 98
    const SPARE_BEN_6 = 99
    const SPARE_BEN_7 = 100
    const SPARE_BEN_8 = 101
    const SPARE_BEN_9 = 102
    const SPARE_BEN_10 = 103

    const NON_CALCULATED = WAGES:SPARE_INC_5
    const BENEFITS = CHILD_BENEFIT:SPARE_BEN_10
    const LEGACY_MTS = WORKING_TAX_CREDIT:HOUSING_BENEFIT
    const CALCULATED = INCOME_TAX:SPARE_BEN_10
    const SICKNESS_ILLNESS = SEVERE_DISABILITY_ALLOWANCE:DLA_MOBILITY
    const DEDUCTIONS = HEALTH_INSURANCE:SPARE_DEDUCT_5
    const INC_ARRAY_SIZE = SPARE_BEN_10

    # exports ----------------
    export WAGES
    export SELF_EMPLOYMENT_INCOME
    export ODD_JOBS
    export PRIVATE_PENSIONS
    export NATIONAL_SAVINGS
    export BANK_INTEREST
    export STOCKS_SHARES
    export INDIVIDUAL_SAVINGS_ACCOUNT
    export PROPERTY
    export ROYALTIES
    export BONDS_AND_GILTS
    export OTHER_INVESTMENT_INCOME
    export OTHER_INCOME
    export ALIMONY_AND_CHILD_SUPPORT_RECEIVED
    export PRIVATE_SICKNESS_SCHEME_BENEFITS
    export ACCIDENT_INSURANCE_SCHEME_BENEFITS
    export HOSPITAL_SAVINGS_SCHEME_BENEFITS
    export UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE
    export PERMANENT_HEALTH_INSURANCE
    export ANY_OTHER_SICKNESS_INSURANCE
    export CRITICAL_ILLNESS_COVER
    export TRADE_UNION_SICK_OR_STRIKE_PAY
    export SPARE_INC_1
    export SPARE_INC_2
    export SPARE_INC_3
    export SPARE_INC_4
    export SPARE_INC_5
    export HEALTH_INSURANCE
    export ALIMONY_AND_CHILD_SUPPORT_PAID
    export TRADE_UNIONS_ETC
    export FRIENDLY_SOCIETIES
    export WORK_EXPENSES
    export AVCS
    export OTHER_DEDUCTIONS
    export LOAN_REPAYMENTS
    export PENSION_CONTRIBUTIONS_EMPLOYEE
    export PENSION_CONTRIBUTIONS_EMPLOYER
    export SPARE_DEDUCT_1
    export SPARE_DEDUCT_2
    export SPARE_DEDUCT_3
    export SPARE_DEDUCT_4
    export SPARE_DEDUCT_5
    export INCOME_TAX
    export NATIONAL_INSURANCE
    export LOCAL_TAXES
    export SOCIAL_FUND_LOAN_REPAYMENT
    export STUDENT_LOAN_REPAYMENTS
    export CARE_INSURANCE
    export SPARE_TAX_1
    export SPARE_TAX_2
    export SPARE_TAX_3
    export SPARE_TAX_4
    export SPARE_TAX_5
    export CHILD_BENEFIT
    export STATE_PENSION
    export BEREAVEMENT_ALLOWANCE
    export ARMED_FORCES_COMPENSATION_SCHEME
    export WAR_WIDOWS_PENSION
    export SEVERE_DISABILITY_ALLOWANCE
    export ATTENDENCE_ALLOWANCE
    export CARERS_ALLOWANCE
    export INDUSTRIAL_INJURY_BENEFIT
    export INCAPACITY_BENEFIT
    export PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING
    export PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY
    export DLA_SELF_CARE
    export DLA_MOBILITY
    export EDUCATION_ALLOWANCES
    export FOSTER_CARE_PAYMENTS
    export MATERNITY_ALLOWANCE
    export MATERNITY_GRANT
    export FUNERAL_GRANT
    export ANY_OTHER_NI_OR_STATE_BENEFIT
    export FRIENDLY_SOCIETY_BENEFITS
    export GOVERNMENT_TRAINING_ALLOWANCES
    export CONTRIB_JOBSEEKERS_ALLOWANCE
    export GUARDIANS_ALLOWANCE
    export WIDOWS_PAYMENT
    export WINTER_FUEL_PAYMENTS
    export WORKING_TAX_CREDIT
    export CHILD_TAX_CREDIT
    export EMPLOYMENT_AND_SUPPORT_ALLOWANCE
    export INCOME_SUPPORT
    export PENSION_CREDIT
    export SAVINGS_CREDIT
    export NON_CONTRIB_JOBSEEKERS_ALLOWANCE
    export HOUSING_BENEFIT
    export FREE_SCHOOL_MEALS
    export UNIVERSAL_CREDIT
    export OTHER_BENEFITS
    export STUDENT_GRANTS
    export STUDENT_LOANS
    export COUNCIL_TAX_BENEFIT
    export SPARE_BEN_1
    export SPARE_BEN_2
    export SPARE_BEN_3
    export SPARE_BEN_4
    export SPARE_BEN_5
    export SPARE_BEN_6
    export SPARE_BEN_7
    export SPARE_BEN_8
    export SPARE_BEN_9
    export SPARE_BEN_10

    export NON_CALCULATED
    export BENEFITS
    export LEGACY_MTS
    export CALCULATED
    export DEDUCTIONS 
    export SICKNESS_ILLNESS
    export INC_ARRAY_SIZE

    export iname
    export make_static_incs
    export make_mutable_incs
    export make_a
    export map_incomes

    const ISet = Set{Int}
    const ZSet = Set{Int}()

    function make_static_incs( 
        T         :: Type; 
        ones      = ZSet, 
        minusones = ZSet ) :: SVector # {INC_ARRAY_SIZE,T} where T
        v = zeros(T, INC_ARRAY_SIZE) 
        for i in ones
            v[i] = one(T)
        end
        for i in minusones
            v[i] = -one(T)
        end
        return SVector{INC_ARRAY_SIZE,T}(v)
    end

    function make_mutable_incs( 
        T         :: Type; 
        ones      = ZSet, 
        minusones = ZSet ) :: MVector # {INC_ARRAY_SIZE,T} where T
        v = zeros(T, INC_ARRAY_SIZE) 
        for i in ones
            v[i] = one(T)
        end
        for i in minusones
            v[i] = -one(T)
        end
        return MVector{INC_ARRAY_SIZE,T}(v)
    end

    function make_a( T :: Type ) :: SizedVector
        return SizedVector(Zeros(T, INC_ARRAY_SIZE))
    end


    function iname(i::Integer)::String
        @assert i in 1:INC_ARRAY_SIZE 
        if i == WAGES
            return "Wages"
        elseif i == SELF_EMPLOYMENT_INCOME
            return "Self Employment Income"
        elseif i == ODD_JOBS
            return "Odd Jobs"
        elseif i == PRIVATE_PENSIONS
            return "Private Pensions"
        elseif i == NATIONAL_SAVINGS
            return "National Savings"
        elseif i == BANK_INTEREST
            return "Bank Interest"
        elseif i == STOCKS_SHARES
            return "Stocks Shares"
        elseif i == INDIVIDUAL_SAVINGS_ACCOUNT
            return "Individual Savings Account"
        elseif i == PROPERTY
            return "Property"
        elseif i == ROYALTIES
            return "Royalties"
        elseif i == BONDS_AND_GILTS
            return "Bonds And Gilts"
        elseif i == OTHER_INVESTMENT_INCOME
            return "Other Investment Income"
        elseif i == OTHER_INCOME
            return "Other Income"
        elseif i == ALIMONY_AND_CHILD_SUPPORT_RECEIVED
            return "Alimony And Child Support Received"
        elseif i == PRIVATE_SICKNESS_SCHEME_BENEFITS
            return "Private Sickness Scheme Benefits"
        elseif i == ACCIDENT_INSURANCE_SCHEME_BENEFITS
            return "Accident Insurance Scheme Benefits"
        elseif i == HOSPITAL_SAVINGS_SCHEME_BENEFITS
            return "Hospital Savings Scheme Benefits"
        elseif i == UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE
            return "Unemployment Or Redundancy Insurance"
        elseif i == PERMANENT_HEALTH_INSURANCE
            return "Permanent Health Insurance"
        elseif i == ANY_OTHER_SICKNESS_INSURANCE
            return "Any Other Sickness Insurance"
        elseif i == CRITICAL_ILLNESS_COVER
            return "Critical Illness Cover"
        elseif i == TRADE_UNION_SICK_OR_STRIKE_PAY
            return "Trade Union Sick Or Strike Pay"
        elseif i == SPARE_INC_1
            return "Spare Inc 1"
        elseif i == SPARE_INC_2
            return "Spare Inc 2"
        elseif i == SPARE_INC_3
            return "Spare Inc 3"
        elseif i == SPARE_INC_4
            return "Spare Inc 4"
        elseif i == SPARE_INC_5
            return "Spare Inc 5"
        elseif i == HEALTH_INSURANCE
            return "Health Insurance"
        elseif i == ALIMONY_AND_CHILD_SUPPORT_PAID
            return "Alimony And Child Support Paid"
        elseif i == TRADE_UNIONS_ETC
            return "Trade Unions Etc"
        elseif i == FRIENDLY_SOCIETIES
            return "Friendly Societies"
        elseif i == WORK_EXPENSES
            return "Work Expenses"
        elseif i == AVCS
            return "Avcs"
        elseif i == OTHER_DEDUCTIONS
            return "Other Deductions"
        elseif i == LOAN_REPAYMENTS
            return "Loan Repayments"
        elseif i == PENSION_CONTRIBUTIONS_EMPLOYEE
            return "Pension Contributions Employee"
        elseif i == PENSION_CONTRIBUTIONS_EMPLOYER
            return "Pension Contributions Employer"
        elseif i == SPARE_DEDUCT_1
            return "Spare Deduct 1"
        elseif i == SPARE_DEDUCT_2
            return "Spare Deduct 2"
        elseif i == SPARE_DEDUCT_3
            return "Spare Deduct 3"
        elseif i == SPARE_DEDUCT_4
            return "Spare Deduct 4"
        elseif i == SPARE_DEDUCT_5
            return "Spare Deduct 5"
        elseif i == INCOME_TAX
            return "Income Tax"
        elseif i == NATIONAL_INSURANCE
            return "National Insurance"
        elseif i == LOCAL_TAXES
            return "Local Taxes"
        elseif i == SOCIAL_FUND_LOAN_REPAYMENT
            return "Social Fund Loan Repayment"
        elseif i == STUDENT_LOAN_REPAYMENTS
            return "Student Loan Repayments"
        elseif i == CARE_INSURANCE
            return "Care Insurance"
        elseif i == SPARE_TAX_1
            return "Spare Tax 1"
        elseif i == SPARE_TAX_2
            return "Spare Tax 2"
        elseif i == SPARE_TAX_3
            return "Spare Tax 3"
        elseif i == SPARE_TAX_4
            return "Spare Tax 4"
        elseif i == SPARE_TAX_5
            return "Spare Tax 5"
        elseif i == CHILD_BENEFIT
            return "Child Benefit"
        elseif i == STATE_PENSION
            return "State Pension"
        elseif i == BEREAVEMENT_ALLOWANCE
            return "Bereavement Allowance"
        elseif i == ARMED_FORCES_COMPENSATION_SCHEME
            return "Armed Forces Compensation Scheme"
        elseif i == WAR_WIDOWS_PENSION
            return "War Widows Pension"
        elseif i == SEVERE_DISABILITY_ALLOWANCE
            return "Severe Disability Allowance"
        elseif i == ATTENDENCE_ALLOWANCE
            return "Attendence Allowance"
        elseif i == CARERS_ALLOWANCE
            return "Carers Allowance"
        elseif i == INDUSTRIAL_INJURY_BENEFIT
            return "Industrial Injury Benefit"
        elseif i == INCAPACITY_BENEFIT
            return "Incapacity Benefit"
        elseif i == PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING
            return "Personal Independence Payment Daily Living"
        elseif i == PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY
            return "Personal Independence Payment Mobility"
        elseif i == DLA_SELF_CARE
            return "Dla Self Care"
        elseif i == DLA_MOBILITY
            return "Dla Mobility"
        elseif i == EDUCATION_ALLOWANCES
            return "Education Allowances"
        elseif i == FOSTER_CARE_PAYMENTS
            return "Foster Care Payments"
        elseif i == MATERNITY_ALLOWANCE
            return "Maternity Allowance"
        elseif i == MATERNITY_GRANT
            return "Maternity Grant"
        elseif i == FUNERAL_GRANT
            return "Funeral Grant"
        elseif i == ANY_OTHER_NI_OR_STATE_BENEFIT
            return "Any Other Ni Or State Benefit"
        elseif i == FRIENDLY_SOCIETY_BENEFITS
            return "Friendly Society Benefits"
        elseif i == GOVERNMENT_TRAINING_ALLOWANCES
            return "Government Training Allowances"
        elseif i == CONTRIB_JOBSEEKERS_ALLOWANCE
            return "Contrib Jobseekers Allowance"
        elseif i == GUARDIANS_ALLOWANCE
            return "Guardians Allowance"
        elseif i == WIDOWS_PAYMENT
            return "Widows Payment"
        elseif i == WINTER_FUEL_PAYMENTS
            return "Winter Fuel Payments"
        elseif i == WORKING_TAX_CREDIT
            return "Working Tax Credit"
        elseif i == CHILD_TAX_CREDIT
            return "Child Tax Credit"
        elseif i == EMPLOYMENT_AND_SUPPORT_ALLOWANCE
            return "Employment And Support Allowance"
        elseif i == INCOME_SUPPORT
            return "Income Support"
        elseif i == PENSION_CREDIT
            return "Pension Credit"
        elseif i == SAVINGS_CREDIT
            return "Savings Credit"
        elseif i == NON_CONTRIB_JOBSEEKERS_ALLOWANCE
            return "Non Contrib Jobseekers Allowance"
        elseif i == HOUSING_BENEFIT
            return "Housing Benefit"
        elseif i == UNIVERSAL_CREDIT
            return "Universal Credit"
        elseif i == OTHER_BENEFITS
            return "Other Benefits"
        elseif i == STUDENT_GRANTS
            return "Student Grants"
        elseif i == STUDENT_LOANS
            return "Student Loans"
        elseif i == FREE_SCHOOL_MEALS
            return "Free School Meals"
        elseif i == COUNCIL_TAX_BENEFIT
            return "Council Tax Rebate"
        elseif i == SPARE_BEN_1
            return "Spare Ben 1"
        elseif i == SPARE_BEN_2
            return "Spare Ben 2"
        elseif i == SPARE_BEN_3
            return "Spare Ben 3"
        elseif i == SPARE_BEN_4
            return "Spare Ben 4"
        elseif i == SPARE_BEN_5
            return "Spare Ben 5"
        elseif i == SPARE_BEN_6
            return "Spare Ben 6"
        elseif i == SPARE_BEN_7
            return "Spare Ben 7"
        elseif i == SPARE_BEN_8
            return "Spare Ben 8"
        elseif i == SPARE_BEN_9
            return "Spare Ben 9"
        elseif i == SPARE_BEN_10
            return "Spare Ben 10"
        end
        @assert false "$i not mapped in iname"
    end # iname

    function map_incomes( pers :: Person{T}; include_calculated :: Bool=false ) :: MVector{INC_ARRAY_SIZE,T} where T
        out = MVector{INC_ARRAY_SIZE,T}( zeros(T,INC_ARRAY_SIZE ))
        incd = pers.income
        if haskey(incd, Definitions.wages )
            out[WAGES] = incd[Definitions.wages]
        end
        if haskey(incd, Definitions.self_employment_income )
            out[SELF_EMPLOYMENT_INCOME] = incd[Definitions.self_employment_income]
        end
        if haskey(incd, Definitions.odd_jobs )
            out[ODD_JOBS] = incd[Definitions.odd_jobs]
        end
        if haskey(incd, Definitions.private_pensions )
            out[PRIVATE_PENSIONS] = incd[Definitions.private_pensions]
        end
        if haskey(incd, Definitions.national_savings )
            out[NATIONAL_SAVINGS] = incd[Definitions.national_savings]
        end
        if haskey(incd, Definitions.bank_interest )
            out[BANK_INTEREST] = incd[Definitions.bank_interest]
        end
        if haskey(incd, Definitions.stocks_shares )
            out[STOCKS_SHARES] = incd[Definitions.stocks_shares]
        end
        if haskey(incd, Definitions.individual_savings_account )
            out[INDIVIDUAL_SAVINGS_ACCOUNT] = incd[Definitions.individual_savings_account]
        end
        if haskey(incd, Definitions.property )
            out[PROPERTY] = incd[Definitions.property]
        end
        if haskey(incd, Definitions.royalties )
            out[ROYALTIES] = incd[Definitions.royalties]
        end
        if haskey(incd, Definitions.bonds_and_gilts )
            out[BONDS_AND_GILTS] = incd[Definitions.bonds_and_gilts]
        end
        if haskey(incd, Definitions.other_investment_income )
            out[OTHER_INVESTMENT_INCOME] = incd[Definitions.other_investment_income]
        end
        if haskey(incd, Definitions.other_income )
            out[OTHER_INCOME] = incd[Definitions.other_income]
        end
        if haskey(incd, Definitions.alimony_and_child_support_received )
            out[ALIMONY_AND_CHILD_SUPPORT_RECEIVED] = incd[Definitions.alimony_and_child_support_received]
        end
        if haskey(incd, Definitions.private_sickness_scheme_benefits )
            out[PRIVATE_SICKNESS_SCHEME_BENEFITS] = incd[Definitions.private_sickness_scheme_benefits]
        end
        if haskey(incd, Definitions.accident_insurance_scheme_benefits )
            out[ACCIDENT_INSURANCE_SCHEME_BENEFITS] = incd[Definitions.accident_insurance_scheme_benefits]
        end
        if haskey(incd, Definitions.hospital_savings_scheme_benefits )
            out[HOSPITAL_SAVINGS_SCHEME_BENEFITS] = incd[Definitions.hospital_savings_scheme_benefits]
        end
        if haskey(incd, Definitions.unemployment_or_redundancy_insurance )
            out[UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE] = incd[Definitions.unemployment_or_redundancy_insurance]
        end
        if haskey(incd, Definitions.permanent_health_insurance )
            out[PERMANENT_HEALTH_INSURANCE] = incd[Definitions.permanent_health_insurance]
        end
        if haskey(incd, Definitions.any_other_sickness_insurance )
            out[ANY_OTHER_SICKNESS_INSURANCE] = incd[Definitions.any_other_sickness_insurance]
        end
        if haskey(incd, Definitions.critical_illness_cover )
            out[CRITICAL_ILLNESS_COVER] = incd[Definitions.critical_illness_cover]
        end
        if haskey(incd, Definitions.trade_union_sick_or_strike_pay )
            out[TRADE_UNION_SICK_OR_STRIKE_PAY] = incd[Definitions.trade_union_sick_or_strike_pay]
        end
        if haskey(incd, Definitions.health_insurance )
            out[HEALTH_INSURANCE] = incd[Definitions.health_insurance]
        end
        if haskey(incd, Definitions.alimony_and_child_support_paid )
            out[ALIMONY_AND_CHILD_SUPPORT_PAID] = incd[Definitions.alimony_and_child_support_paid]
        end
        if haskey(incd, Definitions.trade_unions_etc )
            out[TRADE_UNIONS_ETC] = incd[Definitions.trade_unions_etc]
        end
        if haskey(incd, Definitions.friendly_societies )
            out[FRIENDLY_SOCIETIES] = incd[Definitions.friendly_societies]
        end
        if haskey(incd, Definitions.work_expenses )
            out[WORK_EXPENSES] = incd[Definitions.work_expenses]
        end
        if haskey(incd, Definitions.avcs )
            out[AVCS] = incd[Definitions.avcs]
        end
        if haskey(incd, Definitions.other_deductions )
            out[OTHER_DEDUCTIONS] = incd[Definitions.other_deductions]
        end
        if haskey(incd, Definitions.loan_repayments )
            out[LOAN_REPAYMENTS] = incd[Definitions.loan_repayments]
        end
        if haskey(incd, Definitions.pension_contributions_employee )
            out[PENSION_CONTRIBUTIONS_EMPLOYEE] = incd[Definitions.pension_contributions_employee]
        end
        if haskey(incd, Definitions.pension_contributions_employer )
            out[PENSION_CONTRIBUTIONS_EMPLOYER] = incd[Definitions.pension_contributions_employer]
        end
        if include_calculated 
            if haskey(incd, Definitions.income_tax )
                out[INCOME_TAX] = incd[Definitions.income_tax]
            end
            if haskey(incd, Definitions.national_insurance )
                out[NATIONAL_INSURANCE] = incd[Definitions.national_insurance]
            end
            if haskey(incd, Definitions.local_taxes )
                out[LOCAL_TAXES] = incd[Definitions.local_taxes]
            end
            if haskey(incd, Definitions.social_fund_loan_repayment_from_is_or_pc) 
                out[SOCIAL_FUND_LOAN_REPAYMENT] = incd[Definitions.social_fund_loan_repayment_from_is_or_pc]
            end
            if haskey(incd, Definitions.social_fund_loan_repayment_from_is_or_pc) 
                out[SOCIAL_FUND_LOAN_REPAYMENT] += incd[Definitions.social_fund_loan_repayment_from_jsa_or_esa]
            end

            if haskey(incd, Definitions.student_loan_repayments )
                out[STUDENT_LOAN_REPAYMENTS] = incd[Definitions.student_loan_repayments]
            end
            if haskey(incd, Definitions.care_insurance )
                out[CARE_INSURANCE] = incd[Definitions.care_insurance]
            end
            if haskey(incd, Definitions.child_benefit )
                out[CHILD_BENEFIT] = incd[Definitions.child_benefit]
            end
            if haskey(incd, Definitions.state_pension )
                out[STATE_PENSION] = incd[Definitions.state_pension]
            end
            if haskey(incd, Definitions.bereavement_allowance_or_widowed_parents_allowance_or_bereavement )
                out[BEREAVEMENT_ALLOWANCE] = incd[Definitions.bereavement_allowance_or_widowed_parents_allowance_or_bereavement]
            end
            if haskey(incd, Definitions.armed_forces_compensation_scheme )
                out[ARMED_FORCES_COMPENSATION_SCHEME] = incd[Definitions.armed_forces_compensation_scheme]
            end
            if haskey(incd, Definitions.war_widows_or_widowers_pension )
                out[WAR_WIDOWS_PENSION] = incd[Definitions.war_widows_or_widowers_pension]
            end
            if haskey(incd, Definitions.severe_disability_allowance )
                out[SEVERE_DISABILITY_ALLOWANCE] = incd[Definitions.severe_disability_allowance]
            end
            if haskey(incd, Definitions.attendence_allowance )
                out[ATTENDENCE_ALLOWANCE] = incd[Definitions.attendence_allowance]
            end
            if haskey(incd, Definitions.carers_allowance )
                out[CARERS_ALLOWANCE] = incd[Definitions.carers_allowance]
            end
            if haskey(incd, Definitions.industrial_injury_disablement_benefit )
                out[INDUSTRIAL_INJURY_BENEFIT] = incd[Definitions.industrial_injury_disablement_benefit]
            end
            if haskey(incd, Definitions.incapacity_benefit )
                out[INCAPACITY_BENEFIT] = incd[Definitions.incapacity_benefit]
            end
            if haskey(incd, Definitions.personal_independence_payment_daily_living )
                out[PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING] = incd[Definitions.personal_independence_payment_daily_living]
            end
            if haskey(incd, Definitions.personal_independence_payment_mobility )
                out[PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY] = incd[Definitions.personal_independence_payment_mobility]
            end
            if haskey(incd, Definitions.dlaself_care )
                out[DLA_SELF_CARE] = incd[Definitions.dlaself_care]
            end
            if haskey(incd, Definitions.dlamobility )
                out[DLA_MOBILITY] = incd[Definitions.dlamobility]
            end
            if haskey(incd, Definitions.education_allowances )
                out[EDUCATION_ALLOWANCES] = incd[Definitions.education_allowances]
            end
            if haskey(incd, Definitions.foster_care_payments )
                out[FOSTER_CARE_PAYMENTS] = incd[Definitions.foster_care_payments]
            end
            if haskey(incd, Definitions.maternity_allowance )
                out[MATERNITY_ALLOWANCE] = incd[Definitions.maternity_allowance]
            end
            if haskey(incd, Definitions.maternity_grant_from_social_fund )
                out[MATERNITY_GRANT] = incd[Definitions.maternity_grant_from_social_fund]
            end
            if haskey(incd, Definitions.funeral_grant_from_social_fund )
                out[FUNERAL_GRANT] = incd[Definitions.funeral_grant_from_social_fund]
            end
            if haskey(incd, Definitions.any_other_ni_or_state_benefit )
                out[ANY_OTHER_NI_OR_STATE_BENEFIT] = incd[Definitions.any_other_ni_or_state_benefit]
            end
            if haskey(incd, Definitions.friendly_society_benefits )
                out[FRIENDLY_SOCIETY_BENEFITS] = incd[Definitions.friendly_society_benefits]
            end
            if haskey(incd, Definitions.government_training_allowances )
                out[GOVERNMENT_TRAINING_ALLOWANCES] = incd[Definitions.government_training_allowances]
            end
            if haskey(incd, Definitions.jobseekers_allowance )
                if pers.jsa_type == contributory_jsa
                    out[CONTRIB_JOBSEEKERS_ALLOWANCE] = incd[Definitions.jobseekers_allowance]
                elseif pers.jsa_type == income_related_jsa
                    out[NON_CONTRIB_JOBSEEKERS_ALLOWANCE] = incd[Definitions.jobseekers_allowance]
                elseif pers.jsa_type == both_jsa
                    out[NON_CONTRIB_JOBSEEKERS_ALLOWANCE] = incd[Definitions.jobseekers_allowance]/2
                    out[CONTRIB_JOBSEEKERS_ALLOWANCE] = incd[Definitions.jobseekers_allowance]/2
                else
                    @assert false "jsa is positive but jsa_type unset"
                end
            end
            if haskey(incd, Definitions.guardians_allowance )
                out[GUARDIANS_ALLOWANCE] = incd[Definitions.guardians_allowance]
            end
            if haskey(incd, Definitions.widows_payment )
                out[WIDOWS_PAYMENT] = incd[Definitions.widows_payment]
            end
            if haskey(incd, Definitions.winter_fuel_payments )
                out[WINTER_FUEL_PAYMENTS] = incd[Definitions.winter_fuel_payments]
            end
            if haskey(incd, Definitions.working_tax_credit )
                out[WORKING_TAX_CREDIT] = incd[Definitions.working_tax_credit]
            end
            if haskey(incd, Definitions.child_tax_credit )
                out[CHILD_TAX_CREDIT] = incd[Definitions.child_tax_credit]
            end
            if haskey(incd, Definitions.employment_and_support_allowance )
                out[EMPLOYMENT_AND_SUPPORT_ALLOWANCE] = incd[Definitions.employment_and_support_allowance]
            end
            if haskey(incd, Definitions.income_support )
                out[INCOME_SUPPORT] = incd[Definitions.income_support]
            end
            if haskey(incd, Definitions.pension_credit )
                out[PENSION_CREDIT] = incd[Definitions.pension_credit]
            end
            # merged with pension credit in the frs, I think
            # if haskey(incd, Definitions.savings_credit )
            #    out[SAVINGS_CREDIT] = incd[Definitions.savings_credit]
            # end
            if haskey(incd, Definitions.housing_benefit )
                out[HOUSING_BENEFIT] = incd[Definitions.housing_benefit]
            end

            if haskey(incd, Definitions.extended_hb )
                out[HOUSING_BENEFIT] += incd[Definitions.extended_hb]
            end
   
            if haskey(incd, Definitions.working_tax_credit_lump_sum )
                out[WORKING_TAX_CREDIT] += incd[Definitions.working_tax_credit_lump_sum]
            end
            if haskey(incd, Definitions.child_tax_credit_lump_sum )
                out[CHILD_TAX_CREDIT] += incd[Definitions.child_tax_credit_lump_sum]
            end

            if haskey(incd, Definitions.universal_credit )
                out[UNIVERSAL_CREDIT] = incd[Definitions.universal_credit]
            end
            if haskey(incd, Definitions.other_benefits )
                out[OTHER_BENEFITS] = incd[Definitions.other_benefits]
            end
            if haskey(incd, Definitions.student_grants )
                out[STUDENT_GRANTS] = incd[Definitions.student_grants]
            end
            if haskey(incd, Definitions.student_loans )
                out[STUDENT_LOANS] = incd[Definitions.student_loans]
            end
            if haskey(incd, Definitions.free_school_meals )
                out[FREE_SCHOOL_MEALS] = incd[Definitions.free_school_meals]
            end
            # not in the income list
            # if haskey(incd, Definitions.council_tax_rebate )
            #     out[COUNCIL_TAX_REBATE] = incd[Definitions.council_tax_rebate]
            # end
        end
        return out
    end 

end # module