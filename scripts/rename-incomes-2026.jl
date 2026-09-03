using DataStructures
using ScottishTaxBenefitModel
using .Definitions
using .STBIncomes


@enum Benefit_Type_ED begin  # mapped from benefit
   missing_benefit_type = -1
   dlaself_care = 1
   dlamobility = 2
   child_benefit = 3
   pension_credit = 4
   state_pension = 5
   bereavement_allowance = 6
   armed_forces_compensation_scheme = 8
   war_widows_or_widowers_pension = 9
   severe_disability_allowance = 10
   attendance_allowance = 12
   carers_allowance = 13
   jobseekers_allowance = 14
   industrial_injury_disablement_benefit = 15
   employment_and_support_allowance = 16
   incapacity_benefit = 17
   income_support = 19
   maternity_allowance = 21
   maternity_grant_from_social_fund = 22
   funeral_grant_from_social_fund = 24
   any_other_ni_or_state_benefit = 30
   trade_union_sick_or_strike_pay = 31
   friendly_society_benefits = 32
   private_sickness_scheme_benefits = 33
   accident_insurance_scheme_benefits = 34
   hospital_savings_scheme_benefits = 35
   government_training_allowances = 36
   guardians_allowance = 37
   widows_payment = 60
   unemployment_or_redundancy_insurance = 61
   winter_fuel_payments = 62
   child_winter_heating_assistance_payment = 63
   dwp_third_party_payments_is_or_pc = 65
   dwp_third_party_payments_jsa_or_esa = 66
   social_fund_loan_repayment_from_is_or_pc = 69
   social_fund_loan_repayment_from_jsa_or_esa = 70
   extended_hb = 78
   permanent_health_insurance = 81
   any_other_sickness_insurance = 82
   critical_illness_cover = 83
   working_tax_credit = 90
   child_tax_credit = 91
   working_tax_credit_lump_sum = 92
   child_tax_credit_lump_sum = 93
   housing_benefit = 94
   universal_credit = 95
   personal_independence_payment_daily_living = 96
   personal_independence_payment_mobility = 97
   a_loan_from_the_dwp_and_dfc = 98
   a_loan_or_grant_from_local_authority = 99
   future_pension_credit = 102
   future_universal_credit = 103
   future_housing_benefit = 104
   future_working_tax_credit = 105
   future_child_tax_credit = 106
   future_income_support = 107
   future_jobseekers_allowance = 108
   future_employment_and_support_allowance = 109
   dwp_third_party_payments_uc = 110
   social_fund_loan_uc = 111
   dwp_third_party_payments_v2 = 1112 # 2019- no idea what this is
   repayment_uc_advance = 113 # 2019-
   advance_of_uc = 114 # 2019 -
   scottish_child_payment = 112
   job_start_payment = 115
   troubles_permanent_disablement = 116

   adp_daily_living = 117
   adp_mobility = 118
   one_off_irb_payment = 124

   child_disability_payment_care = 121
   child_disability_payment_mobility = 122
   pupil_development_grant = 123
   disability_topup = 125 # 2022 only so far
   pension_topup = 126  # 2022 only so far
   carers_allowance_supplement = 999
   carers_support_payment = 997 # fixme not yet in data - numbers wrong
   pension_age_disability = 998 # fixme not yet in data - numbers wrong

end


s1 = SortedSet{String}()
s2 = SortedSet{String}()

for i in instances( Definitions.Incomes_Type )
    push!( s1, uppercase(string(i)))
end

for i in instances( STBIncomes.Incomes )
    push!( s2, uppercase(string(i)))
end

renames = intersect( s1, s2 )
missing_in_old = setdiff( s2, s1 )
missing_in_new = setdiff( s1, s2 )

open( "income-renames2.sed", "w") do io
    for i in renames
        println( io, "1,\$s/$i/$(lowercase(i))/g")
    end

    println( io, "missing in old")
    for i in missing_in_old
        println( io, "$(lowercase(i))")
    end

    println( io, "missing in new")
    for i in missing_in_new
        println( io, "$i")
    end
end

#=

BEREAVEMENT_ALLOWANCE => BEREAVEMENT_ALLOWANCE_OR_WIDOWED_PARENTS_ALLOWANCE_OR_BEREAVEMENT
DLA_MOBILITY => DLAMOBILITY
DLA_SELF_CARE => DLASELF_CARE
FUNERAL_GRANT => FUNERAL_GRANT_FROM_SOCIAL_FUND
INDUSTRIAL_INJURY_BENEFIT => INDUSTRIAL_INJURY_DISABLEMENT_BENEFIT
MATERNITY_GRANT => MATERNITY_GRANT_FROM_SOCIAL_FUND


missing in old

BASIC_INCOME
CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE
CONTRIB_JOBSEEKERS_ALLOWANCE
COUNCIL_TAX_BENEFIT


NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE
NON_CONTRIB_JOBSEEKERS_ALLOWANCE
OTHER_SCOTTISH_BENEFITS
OTHER_TAX
SAVINGS_CREDIT
SOCIAL_FUND_LOAN_REPAYMENT
WAR_WIDOWS_OR_WIDOWERS_PENSION => WAR_WIDOWS_PENSION

TROUBLES_PERMANENT_DISABLEMENT

missing in new

CHILD_TAX_CREDIT_LUMP_SUM
CHILD_WINTER_HEATING_ASSISTANCE_PAYMENT
DWP_THIRD_PARTY_PAYMENTS_IS_OR_PC
DWP_THIRD_PARTY_PAYMENTS_JSA_OR_ESA
EMPLOYMENT_AND_SUPPORT_ALLOWANCE
EXTENDED_HB
JOBSEEKERS_ALLOWANCE
JOB_START_PAYMENT
PUPIL_DEVELOPMENT_GRANT
SELF_EMPLOYMENT_EXPENSES
SELF_EMPLOYMENT_LOSSES
SOCIAL_FUND_LOAN_REPAYMENT_FROM_IS_OR_PC
SOCIAL_FUND_LOAN_REPAYMENT_FROM_JSA_OR_ESA

WORKING_TAX_CREDIT_LUMP_SUM


=#
