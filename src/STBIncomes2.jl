module STBIncomes2

"""
Stolen from:
https://discourse.julialang.org/t/export-enum/5396/5
"""

#=
macro exported_enum(name, args...)
    if length(args) == 1 && args[1] isa Expr && args[1].head == :block
        # Handle the begin ... end block syntax
        block = args[1] 
        # Filter out comments from the block
        enum_members = filter(x -> x isa Symbol, block.args)
        return esc(quote
            @enum $name begin
                $(enum_members...)
            end
            export $name
            $([:(export $arg) for arg in enum_members]...)
        end)
    else
        # Handle the standard @enum syntax
        return esc(quote
            @enum($name, $(args...))
            export $name
            $([:(export $arg) for arg in args]...)
        end)
    end
end
=#

#=
*** missing_in_stb_incomes


BEREAVEMENT_ALLOWANCE bereavement_allowance 
child_tax_credit_lump_sum
child_winter_heating_assistance_payment
DLA_MOBILITY dla_mobility
DLA_SELF_CARE dla_self_care
dwp_third_party_payments_is_or_pc
dwp_third_party_payments_jsa_or_esa

CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE contrib_employment_and_support_allowance
NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE non_contrib_employment_and_support_allowance
SAVINGS_CREDIT savings_credit
CONTRIB_JOBSEEKERS_ALLOWANCE contrib_job_seekers_allowance
NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE non_contrib_job_seekers_allowance 
COUNCIL_TAX_BENEFIT  council_tax_benefit
OTHER_TAX other_tax



extended_hb other_benefits
funeral_grant_from_social_fund other_benefits
industrial_injury_disablement_benefit

job_start_payment
MATERNITY_GRANT maternity_grant_from_social_fund 
pupil_development_grant
self_employment_expenses
self_employment_losses
social_fund_loan_repayment_from_is_or_pc
social_fund_loan_repayment_from_jsa_or_esa
troubles_permanent_disablement
war_widows_or_widowers_pension
working_tax_credit_lump_sum

OTHER_SCOTTISH_BENEFITS other_scottish_benefits


*** missing_in_def_incomes


BASIC_INCOME



FUNERAL_GRANT
INDUSTRIAL_INJURY_BENEFIT


WAR_WIDOWS_PENSION

=#

macro exported_enum(name, args...)
    # Helper function to extract the symbol name from an enum member definition.
    # This correctly handles both `ValueA` and `ValueA = 1`.
    function get_enum_symbol(arg)
        if arg isa Symbol
            return arg
        elseif arg isa Expr && arg.head == :(=) && arg.args[1] isa Symbol
            return arg.args[1]
        else
            return nothing # Ignore things like LineNumberNodes or comments
        end
    end

    local enum_definition_args # The raw arguments for the @enum macro
    local member_names         # The clean symbols for the export list

    if length(args) == 1 && args[1] isa Expr && args[1].head == :block
        # Handle the `begin ... end` block syntax
        block = args[1]
        enum_definition_args = block
        member_names = filter(!isnothing, [get_enum_symbol(arg) for arg in block.args])
    else
        # Handle the standard `@enum(name, ValueA, ValueB=2)` syntax
        enum_definition_args = args
        member_names = filter(!isnothing, [get_enum_symbol(arg) for arg in enum_definition_args])
    end

    # The @enum macro can take the block or the splatted args directly.
    # We construct the appropriate call based on the syntax used.
    enum_definition = if enum_definition_args isa Expr && enum_definition_args.head == :block
        :(@enum $name $enum_definition_args)
    else
        :(@enum $name $(enum_definition_args...))
    end

    # We escape the final generated code block to ensure it is executed
    # in the scope where the macro was called.
    return esc(quote
        $enum_definition
        export $name
        $([:(export $name) for name in member_names]...)
    end)
end

@exported_enum Incomes_Type_2 begin
    wages  = 100
    self_employment_income = 101
    odd_jobs = 102
    work_expenses = 103
    avcs = 104
    other_deductions = 105
    pension_contributions_employee = 106
    pension_contributions_employer = 107

    private_pensions = 150

    national_savings = 200
    bank_interest  = 201
    stocks_shares  = 202
    individual_savings_account = 203
    property = 204
    royalties = 205
    bonds_and_gilts = 206 
    other_investment_income = 207 
    
    other_income = 300

    alimony_and_child_support_received = 400
    private_sickness_scheme_benefits = 401
    accident_insurance_scheme_benefits = 402
    hospital_savings_scheme_benefits = 403
    unemployment_or_redundancy_insurance = 404
    permanent_health_insurance = 405
    any_other_sickness_insurance = 406
    critical_illness_cover = 407
    trade_union_sick_or_strike_pay = 408
    health_insurance = 409
    alimony_and_child_support_paid = 410
    trade_unions_etc = 411
    friendly_societies = 412
    loan_repayments = 413
    
    income_tax = 1000
    national_insurance = 1001
    local_taxes = 1002
    social_fund_loan_repayment = 1003
    student_loan_repayments = 1004
    care_insurance = 1005

    child_benefit = 2000
    state_pension = 2001
    bereavement_allowance = 2002
    armed_forces_compensation_scheme = 2003
    war_widows_pension = 2004
    severe_disability_allowance = 2005
    attendance_allowance = 2006
    carers_allowance = 2007
    industrial_injury_benefit = 2008
    incapacity_benefit = 2009
    personal_independence_payment_daily_living = 2010
    personal_independence_payment_mobility = 2011
    dla_self_care = 2012
    dla_mobility = 2013
    education_allowances = 2014
    foster_care_payments = 2015
    maternity_allowance = 2016
    maternity_grant = 2017
    funeral_grant = 2018
    any_other_ni_or_state_benefit = 2019
    friendly_society_benefits = 2020
    government_training_allowances = 2021
    
    
    guardians_allowance = 2022
    widows_payment = 2023

    winter_fuel_payments = 2024        
    housing_benefit = 2025
    
    non_contrib_employment_and_support_allowance = 2050
    contrib_jobseekers_allowance = 2051
    non_contrib_jobseekers_allowance = 2052
    contrib_employment_and_support_allowance = 2053

    
    free_school_meals = 2026
    universal_credit  = 2027
    student_grants = 2028
    student_loans = 2029

    council_tax_benefit = 2060
    
    working_tax_credit = 3000
    child_tax_credit = 3001
    income_support = 3002
    pension_credit = 3003
    savings_credit = 3004

    scottish_child_payment = 4000
    carers_allowance_supplement = 4001
     
    discretionary_housing_payment = 4002  # not just scottish, but, hey..
    carers_support_payment = 4003
    child_disability_payment_care = 4004
    child_disability_payment_mobility = 4005
    pension_age_disability = 4006
    adp_daily_living = 4007
    adp_mobility = 4008

    other_benefits = 6000
    basic_income = 6001
    other_scottish_benefits = 6002

    other_tax = 7000
end


#=
@enum Incomes_Type begin
   wages = 1
   self_employment_income = 2
   self_employment_expenses = 3
   self_employment_losses = 4
   odd_jobs = 5
   private_pensions = 6
   national_savings = 7
   bank_interest = 8
   stocks_shares = 9
   individual_savings_account = 10
   # dividends = 11 ### FIXME NOT USED NEEDS DELETED. Use stocks_shares instead
   property = 12
   royalties = 13
   bonds_and_gilts = 14
   other_investment_income = 15
   other_income = 16
   alimony_and_child_support_received = 17
   health_insurance = 18
   alimony_and_child_support_paid = 19
   care_insurance = 20
   trade_unions_etc = 21
   friendly_societies = 22
   work_expenses = 23
   avcs = 24
   other_deductions = 25
   loan_repayments = 26
   student_loan_repayments = 27
   pension_contributions_employee = 28
   pension_contributions_employer = 29
   education_allowances = 30
   foster_care_payments = 31
   student_grants = 32
   student_loans = 33
   income_tax = 34
   national_insurance = 35
   local_taxes = 36
   free_school_meals = 37

   dla_self_care = 2001
   dla_mobility = 2002
   child_benefit = 2003
   pension_credit = 2004
   state_pension = 2005

   savings_credit = 2031
   contrib_employment_and_support_allowance = 2032
   non_contrib_employment_and_support_allowance = 2033
   contrib_job_seekers_allowance = 2034
   non_contrib_job_seekers_allowance = 2035

   council_tax_benfit = 2030

   bereavement_allowance = 2006
   armed_forces_compensation_scheme = 2008
   war_widows_or_widowers_pension = 2009
   severe_disability_allowance = 2010
   attendance_allowance = 2012
   carers_allowance = 2013
   jobseekers_allowance = 2014
   industrial_injury_disablement_benefit = 2015
   employment_and_support_allowance = 2016
   incapacity_benefit = 2017
   income_support = 2019
   maternity_allowance = 2021
   maternity_grant_from_social_fund = 2022
   funeral_grant = 2024
   any_other_ni_or_state_benefit = 2030
   trade_union_sick_or_strike_pay = 2031
   friendly_society_benefits = 2032
   private_sickness_scheme_benefits = 2033
   accident_insurance_scheme_benefits = 2034
   hospital_savings_scheme_benefits = 2035
   government_training_allowances = 2036
   guardians_allowance = 2037
   widows_payment = 2060
   unemployment_or_redundancy_insurance = 2061
   winter_fuel_payments = 2062
   child_winter_heating_assistance_payment = 2063
   dwp_third_party_payments_is_or_pc = 2065
   dwp_third_party_payments_jsa_or_esa = 2066
   social_fund_loan_repayment_from_is_or_pc = 2069
   social_fund_loan_repayment_from_jsa_or_esa = 2070
   extended_hb = 2078
   permanent_health_insurance = 2081
   any_other_sickness_insurance = 2082
   critical_illness_cover = 2083
   working_tax_credit = 2090
   child_tax_credit = 2091
   working_tax_credit_lump_sum = 2092
   child_tax_credit_lump_sum = 2093
   housing_benefit = 2094
   universal_credit = 2095
   personal_independence_payment_daily_living = 2096
   personal_independence_payment_mobility = 2097

   scottish_child_payment = 2112
   job_start_payment = 2115
   troubles_permanent_disablement = 2116
   child_disability_payment_care = 2121
   child_disability_payment_mobility = 2122
   pupil_development_grant = 2123
   adp_daily_living = 2124
   adp_mobility = 2125
   pension_age_disability = 2126
   carers_allowance_supplement = 2028
   carers_support_payment = 2029

   other_scottish_benefits = 2888
   other_tax = 2900

   discretionary_housing_payment = 2999
   other_benefits = 3000

end
=#

end
