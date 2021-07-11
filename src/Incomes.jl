module Incomes
#
# This module implements a list of incomes, roughly based on FRS incomes,
# implemented with constants and
# fixed length arrays. It's used by the calculation and results modules for
# fast computation. In the household module, incomes are modelled as a Dictionary.
# [Results.jl] has a routine to map between the two.
#
# TODO Investigate Named Arrays
#

using Base: String
using StaticArrays
     
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
    const ATTENDANCE_ALLOWANCE = 60
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
    const CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE = 82
    const INCOME_SUPPORT = 83
    const PENSION_CREDIT = 84
    const SAVINGS_CREDIT = 85
    const NON_CONTRIB_JOBSEEKERS_ALLOWANCE = 86 # FIXME JOBSEEKERS->JOB_SEEKERS everwhere
    const HOUSING_BENEFIT = 87
    const FREE_SCHOOL_MEALS = 88
    const UNIVERSAL_CREDIT = 89
    const OTHER_BENEFITS = 90
    const STUDENT_GRANTS = 91
    const STUDENT_LOANS = 92
    const COUNCIL_TAX_BENEFIT = 93
    const NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE = 94
    const SCOTTISH_CARERS_SUPPLEMENT = 95
    const SPARE_BEN_1 = 96
    const SPARE_BEN_2 = 97
    const SPARE_BEN_3 = 98
    const SPARE_BEN_4 = 99
    const SPARE_BEN_5 = 100
    const SPARE_BEN_6 = 101
    const SPARE_BEN_7 = 102
    const SPARE_BEN_8 = 103
    const SPARE_BEN_9 = 104
    
    const NON_CALCULATED = WAGES:SPARE_INC_5
    const BENEFITS = CHILD_BENEFIT:SCOTTISH_CARERS_SUPPLEMENT
    const LEGACY_MTBS = WORKING_TAX_CREDIT:HOUSING_BENEFIT
    
    const MEANS_TESTED_BENS = WORKING_TAX_CREDIT:UNIVERSAL_CREDIT
    const INCOME_TAXES = INCOME_TAX:NATIONAL_INSURANCE

    const CALCULATED = INCOME_TAX:SCOTTISH_CARERS_SUPPLEMENT
    const SICKNESS_ILLNESS = SEVERE_DISABILITY_ALLOWANCE:DLA_MOBILITY
    const DEDUCTIONS = HEALTH_INSURANCE:SPARE_DEDUCT_5
    const INC_ARRAY_SIZE = SCOTTISH_CARERS_SUPPLEMENT
    const PASSED_THROUGH_BENEFITS = [
            ARMED_FORCES_COMPENSATION_SCHEME,
            WAR_WIDOWS_PENSION,
            SEVERE_DISABILITY_ALLOWANCE,
            INDUSTRIAL_INJURY_BENEFIT,
            INCAPACITY_BENEFIT,
            EDUCATION_ALLOWANCES,
            FOSTER_CARE_PAYMENTS,
            MATERNITY_GRANT,
            FUNERAL_GRANT,
            ANY_OTHER_NI_OR_STATE_BENEFIT,
            GUARDIANS_ALLOWANCE,
            FREE_SCHOOL_MEALS,
            OTHER_BENEFITS,
            STUDENT_GRANTS,
            STUDENT_LOANS ]
    const ALL_INCOMES = union( NON_CALCULATED, BENEFITS )

    const DIRECT_TAXES_AND_DEDUCTIONS = union(INCOME_TAXES,DEDUCTIONS)
 
    # exports ----------------
    export ALL_INCOME
    export NET_INCOME
    export DIRECT_TAXES_AND_DEDUCTIONS
    export DIRECT_TAXES

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
    # taxation
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
    # benefits
    export CHILD_BENEFIT
    export STATE_PENSION
    export BEREAVEMENT_ALLOWANCE
    export ARMED_FORCES_COMPENSATION_SCHEME
    export WAR_WIDOWS_PENSION
    export SEVERE_DISABILITY_ALLOWANCE # obselete not modelled 
    export ATTENDANCE_ALLOWANCE
    export CARERS_ALLOWANCE
    export INDUSTRIAL_INJURY_BENEFIT
    export INCAPACITY_BENEFIT # obselete not modelled 
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
    export CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE
    export NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE
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
    export SPARE_BEN_1 # scottish carers supplement
    export SPARE_BEN_2
    export SPARE_BEN_3
    export SPARE_BEN_4
    export SPARE_BEN_5
    export SPARE_BEN_6
    export SPARE_BEN_7
    export SPARE_BEN_8
    export SPARE_BEN_9
    export SCOTTISH_CARERS_SUPPLEMENT

    export GROSS_INCOME
    export BENEFITS
    export LEGACY_MTBS
    export MEANS_TESTED_BENS
    export INCOME_TAXES
    export CALCULATED
    export DEDUCTIONS 
    export SICKNESS_ILLNESS
    export INC_ARRAY_SIZE
    export ALL_INCOMES
    export PASSED_THROUGH_BENEFITS

    export iname
    export make_static_incs
    export make_mutable_incs
    export make_a
    export IncludedItems
    export isum
    export any_positive

    const ISet = Set{Int}
    const ZSet = Set{Int}()

    struct IncludedItems
        included :: AbstractArray{<:Integer}
        deducted :: Union{Nothing,AbstractArray{<:Integer}}
    end

    function isum( a :: AbstractArray{T}, 
        included; 
        deducted = nothing ) :: T where T
        s = zero(T)
        for i in included
            s += a[i]
        end
        if ! isnothing(deducted)
            for i in deducted
                s -= a[i]
            end
        end
        return s
    end

    function isum( a :: AbstractArray, 
        which :: IncludedItems )
        return isum( a, which.included, deducted=which.deducted)
    end

    function any_positive( a :: AbstractArray, 
        which ) :: Bool
        for i in which
            if a[i] > 0
                return true
            end
        end
        return false
    end

    function make_static_incs( 
        T         :: Type; 
        ones      = ZSet, 
        minusones = ZSet
         ) :: SVector # {INC_ARRAY_SIZE,T} where T
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
        return SizedVector{INC_ARRAY_SIZE,T}(zeros(T, INC_ARRAY_SIZE))
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
        elseif i == ATTENDANCE_ALLOWANCE
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
        elseif i == CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE
            return "Employment And Support Allowance"
        elseif i == NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE
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
        elseif i == SCOTTISH_CARERS_SUPPLEMENT
            return "Spare Ben 10"
        end
        @assert false "$i not mapped in iname"
    end # iname

    # FIXME what if we din't export these ones, deleted '_INCOME' and instead forced Incomes.SAVINGS ...
    export LEGACY_HB_INCOME
    export LEGACY_MT_INCOME
    export GROSS_INCOME
    export LEGACY_HB_INCOME
    export LEGACY_PC_INCOME
    export LEGACY_SAVINGS_CREDIT_INCOME
    export DIVIDEND_INCOME
    export EXEMPT_INCOME
    export ALL_TAXABLE_INCOME
    export NON_SAVINGS_INCOME
    export SAVINGS_INCOME
    export DEFAULT_PASSPORTED_BENS

    const SAVINGS_INCOME = [BANK_INTEREST, BONDS_AND_GILTS,OTHER_INVESTMENT_INCOME]

    """ 
    TODO check this carefully against WTC,PC and IS chapters
    note this doesn't include wages and TaxBenefitSystem
    which are handled in the `calc_incomes` function.   
    poss. have 2nd complete version for WTC/CTC
    """
    ## FIXME CHECK THIS list
    ## NOTE wages, se are treated seperately
    const LEGACY_MT_INCOME = IncludedItems(
        [
            OTHER_INCOME,
            CARERS_ALLOWANCE,
            ALIMONY_AND_CHILD_SUPPORT_RECEIVED, # FIXME THERE IS A 15 DISREGARD SEE PP 438
            EDUCATION_ALLOWANCES,
            FOSTER_CARE_PAYMENTS,
            STATE_PENSION,
            PRIVATE_PENSIONS,
            BEREAVEMENT_ALLOWANCE,
            WAR_WIDOWS_PENSION,
            CONTRIB_JOBSEEKERS_ALLOWANCE, ## CONTRIBUTION BASED Only
            INDUSTRIAL_INJURY_BENEFIT,
            INCAPACITY_BENEFIT,
            MATERNITY_ALLOWANCE,
            MATERNITY_GRANT,
            FUNERAL_GRANT,
            ANY_OTHER_NI_OR_STATE_BENEFIT,
            TRADE_UNION_SICK_OR_STRIKE_PAY,
            FRIENDLY_SOCIETY_BENEFITS,
            WORKING_TAX_CREDIT ,
            PRIVATE_SICKNESS_SCHEME_BENEFITS,
            ACCIDENT_INSURANCE_SCHEME_BENEFITS,
            HOSPITAL_SAVINGS_SCHEME_BENEFITS,
            GOVERNMENT_TRAINING_ALLOWANCES,
            GUARDIANS_ALLOWANCE,
            WIDOWS_PAYMENT,
            UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE 
        ],
        [
            STUDENT_LOAN_REPAYMENTS,
            ALIMONY_AND_CHILD_SUPPORT_PAID
        ]
    )

    const GROSS_INCOME = IncludedItems(
        [
            WAGES,
            SELF_EMPLOYMENT_INCOME,
            ODD_JOBS,
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
            TRADE_UNION_SICK_OR_STRIKE_PAY
        ],
        [
            HEALTH_INSURANCE,
            ALIMONY_AND_CHILD_SUPPORT_PAID,
            TRADE_UNIONS_ETC,
            FRIENDLY_SOCIETIES,
            WORK_EXPENSES,
            AVCS,
            OTHER_DEDUCTIONS,
            LOAN_REPAYMENTS,
            PENSION_CONTRIBUTIONS_EMPLOYEE,
            PENSION_CONTRIBUTIONS_EMPLOYER,
            SPARE_DEDUCT_1,
            SPARE_DEDUCT_2,
            SPARE_DEDUCT_3,
            SPARE_DEDUCT_4,
            SPARE_DEDUCT_5,
        ]
    )

    const LEGACY_HB_INCOME = union( LEGACY_MT_INCOME.included, 
        # since these are passported this should only
        # ever matter if we have a 'passporting' switch
        # and it's turned off, but anyway ....       
        [
        INCOME_SUPPORT,
        CONTRIB_JOBSEEKERS_ALLOWANCE,
        NON_CONTRIB_JOBSEEKERS_ALLOWANCE,
        NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
        CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
        CHILD_TAX_CREDIT ] )

    const LEGACY_PC_INCOME = setdiff(LEGACY_MT_INCOME.included, [WORKING_TAX_CREDIT] )

    const LEGACY_SAVINGS_CREDIT_INCOME = setdiff( LEGACY_MT_INCOME.included,
        [ WORKING_TAX_CREDIT,
        INCAPACITY_BENEFIT,
        CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
        # TODO CHECK BOTH?
        CONTRIB_JOBSEEKERS_ALLOWANCE,
        MATERNITY_ALLOWANCE,
        ALIMONY_AND_CHILD_SUPPORT_RECEIVED ])

    const DIVIDEND_INCOME = [ STOCKS_SHARES ]

    const EXEMPT_INCOME = [
        CARERS_ALLOWANCE,
        FREE_SCHOOL_MEALS,
        DLA_SELF_CARE,
        DLA_MOBILITY,
        CHILD_BENEFIT,
        PENSION_CREDIT,
        BEREAVEMENT_ALLOWANCE,
        ARMED_FORCES_COMPENSATION_SCHEME,
        WAR_WIDOWS_PENSION,
        SEVERE_DISABILITY_ALLOWANCE,
        ATTENDANCE_ALLOWANCE,
        INDUSTRIAL_INJURY_BENEFIT,
        CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
        INCAPACITY_BENEFIT,
        INCOME_SUPPORT,
        MATERNITY_ALLOWANCE,
        MATERNITY_GRANT,
        FUNERAL_GRANT,
        GUARDIANS_ALLOWANCE,
        WINTER_FUEL_PAYMENTS,
        WORKING_TAX_CREDIT,
        CHILD_TAX_CREDIT,
        HOUSING_BENEFIT,
        PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
        PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY
    ]

    const ALL_TAXABLE_INCOME = setdiff( ALL_INCOMES, EXEMPT_INCOME )
    const NON_SAVINGS_INCOME = setdiff( ALL_TAXABLE_INCOME, DIVIDEND_INCOME, SAVINGS_INCOME )

    const DEFAULT_PASSPORTED_BENS = [
          INCOME_SUPPORT,
          NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
          NON_CONTRIB_JOBSEEKERS_ALLOWANCE,
          PENSION_CREDIT ]  

    export inctostr, isettostr

    function inctostr( incs :: AbstractVector ) :: String
        n = size( incs )[1] 
        @assert  n == INC_ARRAY_SIZE
        s = ""
        for i in 1:n
            if incs[i] != 0
                s *= "$(iname(i)) = $(incs[i])\n"
            end
        end
        return s
    end

    function isettostr( iset )
        s = ""
        for i in iset
            s *= "$(iname(i))\n"
        end
        return s
    end
 
end # module