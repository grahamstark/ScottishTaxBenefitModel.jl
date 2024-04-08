"""
 This is the benefit/tax credit/IT/MinWage/NI rates from November 17, 2022
 sources:

* https://www.gov.uk/government/publications/benefit-and-pension-rates-2022-to-2023
* https://www.gov.uk/government/publications/rates-and-allowances-tax-credits-child-benefit-and-guardians-allowance/tax-credits-child-benefit-and-guardians-allowance
* https://www.gov.uk/income-tax-rates
* https://www.gov.uk/guidance/rates-and-thresholds-for-employers-2022-to-2023
* https://www.gov.scot/publications/scottish-income-tax-2022-2023/
* https://www.gov.uk/government/publications/benefit-and-pension-rates-2022-to-2023

"""
function load_sys_2022_23!( sys :: TaxBenefitSystem{T} ) where T
  sys.name = "Scottish System 2022/23"

  sys.it.savings_rates = [0.0, 20.0, 40.0, 45.0]
  sys.it.savings_thresholds = [5_000.0, 37_700.0, 150_000.0]
  sys.it.savings_basic_rate = 2 # above this counts as higher rate

  sys.it.non_savings_rates = [19.0,20.0,21.0,41.0,46.0]
  sys.it.non_savings_thresholds = [2_162, 13_118, 31_092, 150_000.0]
  sys.it.non_savings_basic_rate = 2 # above this counts as higher rate rate FIXME 3???

  sys.it.dividend_rates = [0.0, 8.75,33.75,39.35]
  sys.it.dividend_thresholds = [2_000.0, 37_700.0, 150_000.0] # FIXME this gets the right answers & follows Melville, but the 2k is called 'dividend allowance in HMRC docs'
  sys.it.dividend_basic_rate = 2 # above this counts as higher 

  sys.it.personal_allowance   = 12_570.00
  sys.it.personal_allowance_income_limit = 100_000.00
  sys.it.personal_allowance_withdrawal_rate = 50.0
  sys.it.blind_persons_allowance  = 2_600.00

  sys.it.married_couples_allowance = 9_415.00
  sys.it.mca_minimum     = 3_640.00
  sys.it.mca_income_maximum   = 31_400.00
  sys.it.mca_credit_rate    = 10.0
  sys.it.mca_withdrawal_rate  = 50.0

  sys.it.marriage_allowance   = 1_260.00
  sys.it.personal_savings_allowance = 1_000.00

  # 29/2022 CHECK
  # FIXME better to have it straight from
  # the book with charges per CO2 range
  # and the data being an estimate of CO2 per type
  merge( sys.it.company_car_charge_by_CO2_emissions,
  Dict([ 
    Missing_Fuel_Type=>0.1,
    No_Fuel=>0.1,
    Other=>0.1,
    Dont_know=>0.1,
    Petrol=>0.25,
    Diesel=>0.37,
    Hybrid_use_a_combination_of_petrol_and_electricity=>0.16,
    Electric=>0.02,
    LPG=>0.02,
    Biofuel_eg_E85_fuel=>0.02 ]))

  
  sys.it.fuel_imputation = 25_300.00 # 22/23

  #
  # pensions !!! CHECKUNCHANED 2022
  #
  sys.it.pension_contrib_basic_amount = 3_600.00
  sys.it.pension_contrib_annual_allowance = 40_000.00
  sys.it.pension_contrib_annual_minimum = 4_000.00
  sys.it.pension_contrib_threshold_income = 240_000.00
  sys.it.pension_contrib_withdrawal_rate = 50.0

  # sys.it.non_savings_income = NON_SAVINGS_INCOME
  # sys.it.all_taxable = ALL_TAXABLE_INCOME
  # sys.it.savings_income = SAVINGS_INCOME
  # sys.it.dividend_income = DIVIDEND_INCOME

  # sys.it.mca_date = MCA_DATE

  # NOTE THESE DO NOT INCLUDE JULY CHANGES
  # see: https://www.gov.uk/national-insurance-rates-letters
  # Nov 2022 - 5th april 2023
  sys.ni.abolished = false
  sys.ni.primary_class_1_rates = [0.0, 0.0, 12.0, 2.0 ]
  sys.ni.primary_class_1_bands = [123.0, 242.0, 967.0, 9999999999999.9] # the '-1' here is because json can't write inf
    sys.ni.secondary_class_1_rates = [0.0, 13.8, 13.8 ] # keep 2 so
  sys.ni.secondary_class_1_bands = [175.0, 967.0, 99999999999999.9 ]
  sys.ni.state_pension_age = 66; # fixme move
  # https://www.gov.uk/self-employed-national-insurance-rates
  sys.ni.class_2_threshold = 6_725.0;
  sys.ni.class_2_rate = 3.15;
  sys.ni.class_4_rates = [0.0, 9.73, 2.73 ]
  sys.ni.class_4_bands = [11_909.0, 50_270.0, 99999999999999.9 ]
  # sys.ni.class_1_income = IncludedItems([WAGES],[PENSION_CONTRIBUTIONS_EMPLOYER])
  # sys.ni.class_4_income = [SELF_EMPLOYMENT_INCOME]

  sys.lmt.isa_jsa_esa_abolished = false
  sys.lmt.pen_credit_abolished = false
  ## FIXME we can't turn off pension credit individually here..

  sys.lmt.premia.family = 17.85
  sys.lmt.premia.family_lone_parent = 22.20 
  sys.lmt.premia.carer_single = 38.85
  sys.lmt.premia.carer_couple = 2*38.85
  sys.lmt.premia.disabled_child = 68.04
  sys.lmt.premia.disability_single = 36.20
  sys.lmt.premia.disability_couple = 51.60
  sys.lmt.premia.enhanced_disability_child = 26.67
  sys.lmt.premia.enhanced_disability_single = 17.75
  sys.lmt.premia.enhanced_disability_couple = 25.35
  sys.lmt.premia.severe_disability_single = 69.40
  sys.lmt.premia.severe_disability_couple = 138.80
  sys.lmt.premia.pensioner_is = 157.65

  sys.lmt.allowances.age_18_24 = 61.05
  sys.lmt.allowances.age_25_and_over = 77.00
  sys.lmt.allowances.age_18_and_in_work_activity = 77.00
  sys.lmt.allowances.over_pension_age = 197.10 #
  sys.lmt.allowances.lone_parent = 77.00
  sys.lmt.allowances.lone_parent_over_pension_age = 197.10
  sys.lmt.allowances.couple_both_under_18 = 61.05
  sys.lmt.allowances.couple_both_over_18 = 121.05
  sys.lmt.allowances.couple_over_pension_age = 294.90
  sys.lmt.allowances.couple_one_over_18_high = 121.05
  sys.lmt.allowances.couple_one_over_18_med = 77.00
  sys.lmt.allowances.pa_couple_one_over_18_low = 61.05
  sys.lmt.allowances.child = 70.80
  sys.lmt.allowances.pc_mig_single = 182.60
  sys.lmt.allowances.pc_mig_couple = 278.70
  sys.lmt.allowances.pc_child = 56.35

  # sys.lmt.income_rules.
  sys.lmt.income_rules.permitted_work =152.00
  sys.lmt.income_rules.lone_parent_hb = 25.0
  sys.lmt.income_rules.high = 20.0
  sys.lmt.income_rules.low_couple = 10.0
  sys.lmt.income_rules.low_single = 5.0
  sys.lmt.income_rules.hb_additional = 17.10
  sys.lmt.income_rules.childcare_max_1 = 175.0
  sys.lmt.income_rules.childcare_max_2 = 300.0
  sys.lmt.income_rules.incomes  = LEGACY_MT_INCOME
  sys.lmt.income_rules.hb_incomes = LEGACY_HB_INCOME
  sys.lmt.income_rules.pc_incomes = LEGACY_PC_INCOME
  sys.lmt.income_rules.sc_incomes = LEGACY_SAVINGS_CREDIT_INCOME
  sys.lmt.income_rules.capital_min = 6_000.0
  sys.lmt.income_rules.capital_max = 16_000.0
  sys.lmt.income_rules.pc_capital_min = 10_000.0
  sys.lmt.income_rules.pc_capital_max = 99999999999999.9
  sys.lmt.income_rules.pensioner_capital_min = 10_000.0
  sys.lmt.income_rules.pensioner_capital_max = 16_000.0

  sys.lmt.income_rules.capital_tariff = 250
  sys.lmt.income_rules.pensioner_tariff = 500
  # FIXME why do we need a seperate copy of HoursLimits here?

  sys.lmt.hours_limits.lower = 16
  sys.lmt.hours_limits.med = 24
  sys.lmt.hours_limits.higher = 30

  sys.lmt.savings_credit.abolished = false
  sys.lmt.savings_credit.withdrawal_rate = 60.0
  sys.lmt.savings_credit.threshold_single = 158.47
  sys.lmt.savings_credit.threshold_couple = 251.70
  sys.lmt.savings_credit.max_single = 14.48
  sys.lmt.savings_credit.max_couple = 16.20
  sys.lmt.savings_credit.available_till = Date( 2016, 04, 06 )

  sys.lmt.child_tax_credit.abolished = false
  sys.lmt.child_tax_credit.family = 545.0
  sys.lmt.child_tax_credit.child = 2_935.0
  sys.lmt.child_tax_credit.disability = 3_545.0
  sys.lmt.child_tax_credit.severe_disability = 4825
  sys.lmt.child_tax_credit.threshold = 16_480.0

  sys.lmt.working_tax_credit.basic = 2_070.00
  sys.lmt.working_tax_credit.lone_parent = 2_125.00
  sys.lmt.working_tax_credit.couple = 2_125.00
  sys.lmt.working_tax_credit.hours_ge_30 = 860.00
  sys.lmt.working_tax_credit.disability = 3_345.00
  sys.lmt.working_tax_credit.severe_disability = 1_445.00
  sys.lmt.working_tax_credit.age_50_plus = 1_365.00 # ??
  sys.lmt.working_tax_credit.age_50_plus_30_hrs = 2_030.00
  sys.lmt.working_tax_credit.childcare_max_2_plus_children = 300.0 # pw
  sys.lmt.working_tax_credit.childcare_max_1_child = 175.0
  sys.lmt.working_tax_credit.childcare_proportion = 70.0
  sys.lmt.working_tax_credit.taper = 41.0
  sys.lmt.working_tax_credit.threshold = 6_770.0
  sys.lmt.working_tax_credit.non_earnings_minima = 300.0 # FIXME check

  sys.lmt.hb.taper = 65.0
  sys.lmt.hb.ndd_deductions = [16.45,37.80,51.85,84.85,96.60,106.05]
  sys.lmt.hb.ndd_incomes = [154.0,224.0,292.0,389.0,484.0,99999999999999.9]

  sys.lmt.ctr.taper = 20.0
  sys.lmt.ctr.ndd_deductions = []
  sys.lmt.ctr.ndd_incomes = []


  sys.uc.abolished = false
  sys.uc.threshold = 2_500.0 ## NOT USED
  sys.uc.age_18_24 = 265.31
  sys.uc.age_25_and_over = 334.91

  sys.uc.couple_both_under_25 = 416.45
  sys.uc.couple_oldest_25_plus = 525.72

  sys.uc.first_child = 290.00
  sys.uc.subsequent_child = 244.58
  sys.uc.disabled_child_lower = 132.89
  sys.uc.disabled_child_higher = 414.88
  sys.uc.limited_capcacity_for_work_activity = 354.28
  sys.uc.carer = 168.81

  sys.uc.ndd = 77.87

  sys.uc.childcare_max_2_plus_children = 1_108.04 # pm
  sys.uc.childcare_max_1_child = 646.35
  sys.uc.childcare_proportion = 85.0 # pct

  sys.uc.minimum_income_floor_hours = 35*WEEKS_PER_MONTH

  sys.uc.work_allowance_w_housing = 344.00 
  sys.uc.work_allowance_no_housing = 573.00
  sys.uc.other_income = UC_OTHER_INCOME
  # sys.uc.earned_income :: IncludedItems = UC_EARNED_INCOME
  sys.uc.capital_min = 6_000.0
  sys.uc.capital_max = 16_000.0
  # £1 *per week* ≆ 4.35 pm FIXME make 4.35 WEEKS_PER_MONTH? 
  sys.uc.capital_tariff = 250.0/4.35
  sys.uc.taper = 55.0
  sys.uc.ctr_taper = 20.0

  sys.age_limits.state_pension_ages = pension_ages()
  sys.age_limits.savings_credit_to_new_state_pension = Date( 2016, 04, 06 )

  sys.hours_limits.lower = 16
  sys.hours_limits.med = 24
  sys.hours_limits.higher = 30

  sys.child_limits.max_children = 2

  # https://www.gov.uk/government/publications/minimum-wage-rates-for-2022
  # col 1
  sys.minwage.ages = [16,18,21,23]
  sys.minwage.wage_per_hour = [4.81, 6.83, 9.18, 9.50]

  sys.minwage.apprentice_rate = 4.81

  sys.hr.maximum_rooms = 4
  sys.hr.rooms_rent_reduction = [14.0,25.0]
  sys.hr.single_room_age = 35
  #
  # These are unchanged in 3 years; see:
  # https://www.gov.scot/publications/local-housing-allowance-rates-2021-2022/
  #
  sys.hr.brmas = loadBRMAs( 4, Float64, DEFAULT_BRMA_2021 ) 



  sys.nmt_bens.attendance_allowance.abolished = false
  sys.nmt_bens.attendance_allowance.higher = 92.40
  sys.nmt_bens.attendance_allowance.lower = 61.85


  sys.nmt_bens.child_benefit.abolished = false
  sys.nmt_bens.child_benefit.first_child = 21.80
  sys.nmt_bens.child_benefit.other_children = 14.45
  sys.nmt_bens.child_benefit.high_income_thresh = 50_000.0
  sys.nmt_bens.child_benefit.withdrawal = 1/100
  sys.nmt_bens.child_benefit.guardians_allowance = 18.55

  sys.nmt_bens.dla.abolished = false
  sys.nmt_bens.dla.care_high = 92.40
  sys.nmt_bens.dla.care_middle = 61.85
  sys.nmt_bens.dla.care_low = 24.45
  sys.nmt_bens.dla.mob_high = 64.50
  sys.nmt_bens.dla.mob_low = 24.45


  sys.nmt_bens.carers.abolished = false
  sys.nmt_bens.carers.allowance = 69.70

  sys.nmt_bens.carers.scottish_supplement = 231.40 # FROM APRIL 2021
  sys.nmt_bens.carers.hours :: Int = 35
  sys.nmt_bens.carers.gainful_employment_min = 132.00


  sys.nmt_bens.pip.abolished = false
  sys.nmt_bens.pip.dl_standard = 61.85
  sys.nmt_bens.pip.dl_enhanced = 92.40
  sys.nmt_bens.pip.mobility_standard = 24.45
  sys.nmt_bens.pip.mobility_enhanced = 64.50
  
  sys.nmt_bens.esa.abolished = false
  sys.nmt_bens.esa.assessment_u25 = 61.05
  sys.nmt_bens.esa.assessment_25p = 77.00
  sys.nmt_bens.esa.main   = 77.00
  sys.nmt_bens.esa.work   = 30.60
  sys.nmt_bens.esa.support  = 40.60


  sys.nmt_bens.jsa.abolished = false
  sys.nmt_bens.jsa.u25 = 61.05
  sys.nmt_bens.jsa.o24 = 77.00

  sys.nmt_bens.pensions.abolished = false
  sys.nmt_bens.pensions.new_state_pension = 185.15
  # pension_start_date = Date( 2016, 04, 06 )
  sys.nmt_bens.pensions.cat_a  = 141.85
  sys.nmt_bens.pensions.cat_b  = 141.85
  sys.nmt_bens.pensions.cat_b_survivor = 85.00
  sys.nmt_bens.pensions.cat_d  = 85.00

  sys.nmt_bens.bereavement.abolished = false
  # higher effectively just means 'with children'; 
  sys.nmt_bens.bereavement.lump_sum_higher = 3_500
  sys.nmt_bens.bereavement.lump_sum_lower = 2_500
  sys.nmt_bens.bereavement.higher = 350
  sys.nmt_bens.bereavement.lower = 100

  sys.nmt_bens.widows_pension.abolished = false
  sys.nmt_bens.widows_pension.industrial_higher = 141.85
  sys.nmt_bens.widows_pension.industrial_lower = 42.56
  sys.nmt_bens.widows_pension.standard_rate = 126.35
  sys.nmt_bens.widows_pension.parent = 126.35
  sys.nmt_bens.widows_pension.ages = collect(54:-1:45)
  sys.nmt_bens.widows_pension.age_amounts = [117.51,108.66,99.82,90.97,82.13,73.28,64.44,55.59,46.75,37.91]

  # 
  # young carer grant
  sys.nmt_bens.maternity.abolished = false
  sys.nmt_bens.maternity.rate = 156.66


  sys.nmt_bens.smp = 156.66 ## 90% of earn cpag 21/2 812
  # = XX

  sys.bencap.abolished = false
  sys.bencap.outside_london_single = 257.69
  sys.bencap.outside_london_couple = 384.62
  # not really needed, but anyway ..
  sys.bencap.inside_london_single = 296.35
  sys.bencap.inside_london_couple = 442.31
  sys.bencap.uc_incomes_limit = 617

  sys.scottish_child_payment.amount = 25.0
  sys.scottish_child_payment.maximum_age = 15

  sys.ubi.abolished = true
  sys.ubi.adult_amount = 4_800.0
  sys.ubi.child_amount= 3_000.0
  sys.ubi.universal_pension = 8_780.0
  sys.ubi.adult_age = 17
  sys.ubi.retirement_age = 66

  sys.loctax.ct.band_d = Dict(
    [
      :S12000033 => 1418.62,
      :S12000034 => 1339.83,
      :S12000041 => 1242.14,
      :S12000035 => 1408.76,
      :S12000036 => 1378.75,
      :S12000005 => 1343.77,
      :S12000006 => 1259.30,
      :S12000042 => 1419.03,
      :S12000008 =>	1416.61,
      :S12000045 =>	1348.25,
      :S12000010 =>	1341.69,
      :S12000011 =>	1335.11,
      :S12000014 =>	1274.60,
      :S12000047 =>	1319.22,
      :S12000049 =>	1428.00,
      :S12000017 =>	1372.29,
      :S12000018 =>	1357.81,
      :S12000019 =>	1442.60,
      :S12000020 => 1362.56,
      :S12000013 =>	1229.29,
      :S12000021 =>	1382.97,
      :S12000050 =>	1257.89,
      :S12000023 =>	1244.73,
      :S12000048 =>	1351.00,
      :S12000038 =>	1354.88,
      :S12000026 =>	1291.53,
      :S12000027 =>	1206.33,
      :S12000028 =>	1383.96,
      :S12000029 =>	1233.00,
      :S12000030 =>	1384.58,
      :S12000039 =>	1332.36,
      :S12000040 =>	1314.71] )

end
