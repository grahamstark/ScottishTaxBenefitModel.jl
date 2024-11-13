"""

 This is the benefit/tax credit/IT/MinWage/NI rates for rUK, excluding NI,
  from As of July, 2023
 sources:
 IT: 

* - allowances: https://www.gov.uk/government/publications/rates-and-allowances-income-tax/income-tax-rates-and-allowances-current-and-past
*   - https://www.gov.uk/marriage-allowance
*   - pension:https://www.gov.uk/government/publications/abolition-of-lifetime-allowance-and-increases-to-pension-tax-limits/pension-tax-limits
* NI: https://www.gov.uk/government/publications/rates-and-allowances-national-insurance-contributions/rates-and-allowances-national-insurance-contributions
* Benefits: https://www.gov.uk/government/publications/benefit-and-pension-rates-2023-to-2024/benefit-and-pension-rates-2023-to-2024
* Tax Credits, CB etc.:https://www.gov.uk/government/publications/rates-and-allowances-tax-credits-child-benefit-and-guardians-allowance/tax-credits-child-benefit-and-guardians-allowance

##  Local Taxes: 

* ENGLAND https://www.gov.uk/government/statistics/council-tax-levels-set-by-local-authorities-in-england-2023-to-2024/council-tax-levels-set-by-local-authorities-in-england-2023-to-2024
* WALES https://www.gov.wales/council-tax-levels-april-2023-march-2024
* SCOTLAND http://www.gov.scot/publications/council-tax-datasets/

## LHA 

* ENGLAND https://www.gov.uk/government/publications/local-housing-allowance-lha-rates-applicable-from-april-2023-to-march-2024
* WALES https://www.gov.wales/local-housing-allowance
* SCOTLAND: 

"""
function load_sys_2023_24_ruk!( sys :: TaxBenefitSystem{T} ) where T
  sys.name = "rUK System 2023/24"
  sys.it.savings_rates = [10.0, 20.0, 40.0, 45.0]
  sys.it.savings_thresholds = [5_000.0, 37_700.0, 125_140.0]
  sys.it.savings_basic_rate = 2 # above this counts as higher rate

  sys.it.non_savings_rates = [20.0,40.0,45.0] # check bottom
  sys.it.non_savings_thresholds = [37_700, 125_140.0]
  sys.it.non_savings_basic_rate = 2 # above this counts as higher rate rate FIXME 3???

  sys.it.dividend_rates = [0.0, 8.75,33.75,39.35]
  sys.it.dividend_thresholds = [1_000.0, 37_700.0, 125_140.0] # FIXME this gets the right answers & follows Melville, but the 2k is called 'dividend allowance in HMRC docs'
  sys.it.dividend_basic_rate = 2 # above this counts as higher 

  sys.it.personal_allowance   = 12_570.00
  sys.it.personal_allowance_income_limit = 100_000.00
  sys.it.personal_allowance_withdrawal_rate = 50.0
  sys.it.blind_persons_allowance  = 2_870.00

  sys.it.married_couples_allowance = 10_375.0
  sys.it.mca_minimum     = 4_010.00
  sys.it.mca_income_maximum   = 34_600.00
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

  
  sys.it.fuel_imputation = 27_800.00 # 22/23

  #
  # TODO CHECK THIS WORKED EXAMPLE
  # 
  sys.it.pension_contrib_basic_amount = 10_000.00
  sys.it.pension_contrib_annual_allowance = 60_000.00
  sys.it.pension_contrib_annual_minimum = 10_000.00
  sys.it.pension_contrib_threshold_income = 260_000.00
  sys.it.pension_contrib_withdrawal_rate = 50.0

  # NI
  # FREEPORTS ??? WTF ???
  sys.ni.abolished = false
  sys.ni.primary_class_1_rates = [0.0, 0.0, 12.0, 2.0 ]
  sys.ni.primary_class_1_bands = [123.0, 242.0, 967.0, 9999999999999.9] # the '-1' here is because json can't write inf
  sys.ni.secondary_class_1_rates = [0.0, 13.8, 13.8 ] # keep 2 so
  sys.ni.secondary_class_1_bands = [175.0, 967.0, 99999999999999.9 ]
  sys.ni.state_pension_age = 66; # fixme move
  # https://www.gov.uk/self-employed-national-insurance-rates
  sys.ni.class_2_threshold = 6_725.0;
  sys.ni.class_2_rate = 3.45;
  sys.ni.class_4_rates = [0.0, 9.0, 2.0 ]
  sys.ni.class_4_bands = [12_570.0, 50_270.0, 99999999999999.9 ]
  # sys.ni.class_1_income = IncludedItems([WAGES],[PENSION_CONTRIBUTIONS_EMPLOYER])
  # sys.ni.class_4_income = [SELF_EMPLOYMENT_INCOME]

  sys.lmt.isa_jsa_esa_abolished = false
  sys.lmt.pen_credit_abolished = false
  ## FIXME we can't turn off pension credit individually here..

  sys.lmt.premia.family = 0.0 # see cpag 21/2 p 330 18.53
  sys.lmt.premia.family_lone_parent = 0.0 # 22.20 
  sys.lmt.premia.carer_single = 42.75
  sys.lmt.premia.carer_couple = 2*42.75
  sys.lmt.premia.disabled_child = 74.69
  sys.lmt.premia.disability_single = 39.85
  sys.lmt.premia.disability_couple = 56.80
  sys.lmt.premia.enhanced_disability_child = 26.67
  sys.lmt.premia.enhanced_disability_single = 19.55
  sys.lmt.premia.enhanced_disability_couple = 27.90
  sys.lmt.premia.severe_disability_single = 76.40
  sys.lmt.premia.severe_disability_couple = 152.80
  sys.lmt.premia.pensioner_is = 173.55

  sys.lmt.allowances.age_18_24 = 67.20
  sys.lmt.allowances.age_25_and_over = 84.80
  sys.lmt.allowances.age_18_and_in_work_activity = 84.80
  sys.lmt.allowances.over_pension_age = 217.00 #
  sys.lmt.allowances.lone_parent = 84.80
  sys.lmt.allowances.lone_parent_over_pension_age = 217.00
  sys.lmt.allowances.couple_both_under_18 = 67.20
  sys.lmt.allowances.couple_both_over_18 = 133.30
  sys.lmt.allowances.couple_over_pension_age = 324.70
  sys.lmt.allowances.couple_one_over_18_high = 133.30
  sys.lmt.allowances.couple_one_over_18_med = 84.80
  sys.lmt.allowances.pa_couple_one_over_18_low = 67.20
  sys.lmt.allowances.child = 77.78
  sys.lmt.allowances.pc_mig_single = 201.05
  sys.lmt.allowances.pc_mig_couple = 306.85
  sys.lmt.allowances.pc_child = 61.88

  # sys.lmt.income_rules.
  sys.lmt.income_rules.permitted_work = 167.00
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
  sys.lmt.savings_credit.threshold_single = 174.49
  sys.lmt.savings_credit.threshold_couple = 277.12
  sys.lmt.savings_credit.max_single = 15.94
  sys.lmt.savings_credit.max_couple = 17.84
  sys.lmt.savings_credit.available_till = Date( 2016, 04, 06 )

  sys.lmt.child_tax_credit.abolished = false
  sys.lmt.child_tax_credit.family = 545.0
  sys.lmt.child_tax_credit.child = 3_235.0
  sys.lmt.child_tax_credit.disability = 3_905.0
  sys.lmt.child_tax_credit.severe_disability = 3_905.0 + 1_575
  sys.lmt.child_tax_credit.threshold = 18_725.0

  sys.lmt.working_tax_credit.basic = 2_280.0
  sys.lmt.working_tax_credit.lone_parent = 2_340.0
  sys.lmt.working_tax_credit.couple = 2_340.0
  sys.lmt.working_tax_credit.hours_ge_30 = 950.00
  sys.lmt.working_tax_credit.disability = 3_685.00
  sys.lmt.working_tax_credit.severe_disability = 1_595.00
  sys.lmt.working_tax_credit.age_50_plus = 1_365.00 # ?? delete
  sys.lmt.working_tax_credit.age_50_plus_30_hrs = 2_030.00 # ??
  sys.lmt.working_tax_credit.childcare_max_2_plus_children = 300.0 # pw
  sys.lmt.working_tax_credit.childcare_max_1_child = 175.0
  sys.lmt.working_tax_credit.childcare_proportion = 70.0
  sys.lmt.working_tax_credit.taper = 41.0
  sys.lmt.working_tax_credit.threshold = 7_455.0
  sys.lmt.working_tax_credit.non_earnings_minima = 300.0 # FIXME check

  sys.lmt.hb.taper = 65.0
  sys.lmt.hb.ndd_deductions = [18.10,41.60,57.10,93.40,106.35,116.75]
  sys.lmt.hb.ndd_incomes = [162.0,236.0,308.0,410.0,511.0,99999999999999.9]

  sys.lmt.ctr.taper = 20.0
  sys.lmt.ctr.ndd_deductions = []
  sys.lmt.ctr.ndd_incomes = []


  sys.uc.abolished = false
  sys.uc.threshold = 2_500.0 ## NOT USED
  sys.uc.age_18_24 = 292.11
  sys.uc.age_25_and_over = 368.74

  sys.uc.couple_both_under_25 = 458.51
  sys.uc.couple_oldest_25_plus = 578.82

  sys.uc.first_child = 315.00
  sys.uc.subsequent_child = 269.58
  sys.uc.disabled_child_lower = 146.31
  sys.uc.disabled_child_higher = 456.89
  sys.uc.limited_capcacity_for_work_activity = 390.06
  sys.uc.carer = 185.86

  sys.uc.ndd = 85.73

  sys.uc.childcare_max_2_plus_children = 1_630.15 # pm
  sys.uc.childcare_max_1_child = 950.92
  sys.uc.childcare_proportion = 85.0 # pct

  sys.uc.minimum_income_floor_hours = 35*WEEKS_PER_MONTH

  sys.uc.work_allowance_w_housing = 379.00
  sys.uc.work_allowance_no_housing = 631.00
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
  sys.minwage.wage_per_hour = [5.28, 7.49, 10.18, 10.42]

  sys.minwage.apprentice_rate = 5.28

  # CHECK THESE 3
  sys.hr.maximum_rooms = 4
  sys.hr.rooms_rent_reduction = [14.0,25.0]
  sys.hr.single_room_age = 35


  sys.nmt_bens.attendance_allowance.abolished = false
  sys.nmt_bens.attendance_allowance.higher = 101.75
  sys.nmt_bens.attendance_allowance.lower = 68.10


  sys.nmt_bens.child_benefit.abolished = false
  sys.nmt_bens.child_benefit.first_child = 24.00
  sys.nmt_bens.child_benefit.other_children = 15.90
  sys.nmt_bens.child_benefit.high_income_thresh = 50_000.0
  sys.nmt_bens.child_benefit.withdrawal = 1/100
  sys.nmt_bens.child_benefit.guardians_allowance = 20.40

  sys.nmt_bens.dla.abolished = false
  sys.nmt_bens.dla.care_high = 101.75
  sys.nmt_bens.dla.care_middle = 68.10
  sys.nmt_bens.dla.care_low = 26.90
  sys.nmt_bens.dla.mob_high = 71.00
  sys.nmt_bens.dla.mob_low = 26.90


  sys.nmt_bens.carers.abolished = false
  sys.nmt_bens.carers.allowance = 76.75

  # TODO
  sys.nmt_bens.carers.scottish_supplement = 231.40 # FROM APRIL 2021
  sys.nmt_bens.carers.hours :: Int = 35
  sys.nmt_bens.carers.gainful_employment_min = 132.00


  sys.nmt_bens.pip.abolished = false
  sys.nmt_bens.pip.dl_standard = 68.10
  sys.nmt_bens.pip.dl_enhanced = 101.75
  sys.nmt_bens.pip.mobility_standard = 26.90
  sys.nmt_bens.pip.mobility_enhanced = 71.00
  
  sys.nmt_bens.esa.abolished = false
  sys.nmt_bens.esa.assessment_u25 = 67.20
  sys.nmt_bens.esa.assessment_25p = 84.80
  sys.nmt_bens.esa.main   = 84.80
  sys.nmt_bens.esa.work   = 33.70
  sys.nmt_bens.esa.support  = 44.70


  sys.nmt_bens.jsa.abolished = false
  sys.nmt_bens.jsa.u25 = 67.20
  sys.nmt_bens.jsa.o24 = 84.80

  sys.nmt_bens.pensions.abolished = false
  sys.nmt_bens.pensions.new_state_pension = 203.85
  # pension_start_date = Date( 2016, 04, 06 )
  sys.nmt_bens.pensions.cat_a  = 156.20
  sys.nmt_bens.pensions.cat_b  = 156.20
  sys.nmt_bens.pensions.cat_b_survivor = 93.60
  sys.nmt_bens.pensions.cat_d  = 93.60

  sys.nmt_bens.bereavement.abolished = false
  # higher effectively just means 'with children'; 
  sys.nmt_bens.bereavement.lump_sum_higher = 3_500
  sys.nmt_bens.bereavement.lump_sum_lower = 2_500
  sys.nmt_bens.bereavement.higher = 350
  sys.nmt_bens.bereavement.lower = 100

  sys.nmt_bens.widows_pension.abolished = false
  sys.nmt_bens.widows_pension.industrial_higher = 156.20
  sys.nmt_bens.widows_pension.industrial_lower = 46.86
  sys.nmt_bens.widows_pension.standard_rate = 139.10
  sys.nmt_bens.widows_pension.parent = 139.10
  sys.nmt_bens.widows_pension.ages = collect(54:-1:45)
  sys.nmt_bens.widows_pension.age_amounts = [129.36,119.63,109.89,100.15,90.42,80.68,70.94,61.20,51.47,41.73]

  # 
  # young carer grant
  sys.nmt_bens.maternity.abolished = false
  sys.nmt_bens.maternity.rate = 172.48


  sys.nmt_bens.smp = 172.48 ## 90% of earn cpag 21/2 812
  # = XX

  sys.bencap.abolished = false
  sys.bencap.outside_london_single = 283.71
  sys.bencap.outside_london_couple = 423.46
  # not really needed, but anyway ..
  sys.bencap.inside_london_single = 326.29
  sys.bencap.inside_london_couple = 486.98
  sys.bencap.uc_incomes_limit = 722.0

  sys.ubi.abolished = true
  sys.ubi.adult_amount = 4_800.0
  sys.ubi.child_amount= 3_000.0
  sys.ubi.universal_pension = 8_780.0
  sys.ubi.adult_age = 17
  sys.ubi.retirement_age = 66

  sys.loctax.ct.band_d = Dict(
    [
      :ENGLAND  => 2_065.0,
      :WALES    => 1_879.0,
      :SCOTLAND => 1_417.0,
      :LONDON => 2_065.0,
      :NIRELAND => -99999.99
    ] )

  brmapath = joinpath( artifact"augdata", "brma-2023-2024-country-averages.csv" )

  sys.hr.brmas = loadBRMAs( 4, Float64, brmapath )

  # here so it's always on 
  sys.scottish_child_payment.abolished = false
  sys.scottish_child_payment.amount = 25.0
  sys.scottish_child_payment.maximum_age = 15

end