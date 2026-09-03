module STBIncomes2


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
   bereavement_allowance_or_widowed_parents_allowance_or_bereavement = 2006
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

   other_tax = 2889


   discretionary_housing_payment = 2999
   other_benefits = 3000

end


end
