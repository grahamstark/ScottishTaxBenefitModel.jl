"""
This is the benefit/tax credit/IT/MinWage/NI rates for rUK, excluding NI, 
as of August 2025 - FY 2025/6

  GOV.UK. ‘Alcohol Duty Rates’. 1 February 2025. https://www.gov.uk/guidance/alcohol-duty-rates.
  GOV.UK. ‘Benefit and Pension Rates 2025 to 2026’. Accessed 16 August 2025. https://www.gov.uk/government/publications/benefit-and-pension-rates-2025-to-2026/benefit-and-pension-rates-2025-to-2026.
  GOV.UK. ‘Child Benefit, Guardian’s Allowance and Tax Credits — Rates and Allowances’. Accessed 16 August 2025. https://www.gov.uk/government/publications/rates-and-allowances-tax-credits-child-benefit-and-guardians-allowance/tax-credits-child-benefit-and-guardians-allowance.
  GOV.UK. ‘Minimum Wage Rates for 2025’. Accessed 16 August 2025. https://www.gov.uk/government/publications/minimum-wage-rates-for-2025.
  GOV.UK. ‘Tobacco Products Duty Rates’. Accessed 18 August 2025. https://www.gov.uk/government/publications/rates-and-allowances-excise-duty-tobacco-duty/excise-duty-tobacco-duty-rates.
  GOV.UK. ‘Vehicle Excise Duty Rates for Cars, Vans and Motorcycles — from 1 April 2025’. Accessed 16 August 2025. https://www.gov.uk/government/publications/vehicle-excise-duty-rates-for-cars-vans-and-motorcycles-from-1-april-2025/vehicle-excise-duty-rates-for-cars-vans-and-motorcycles-from-1-april-2025.
  UK Parliament Seely, Antony, Francesco Masala, James Mirza-Davies, and Matthew Keep. Direct Taxes: Rates and Allowances for 2025/26. 16 August 2025. https://commonslibrary.parliament.uk/research-briefings/cbp-10237/.

See also:

  Scottish Government. ‘Minimum Unit Pricing for Alcohol’. Accessed 18 August 2025. https://www.gov.scot/policies/alcohol-and-drugs/minimum-unit-pricing/.
  Scottish Government. ‘Up-Rating Policy for 2025-26’. Accessed 16 August 2025. https://www.gov.scot/publications/social-security-assistance-scotland-up-rating-inflation-2025-26/pages/8/.
  Scottish Government.‘2025 to 2026’. Accessed 18 August 2025. https://www.gov.scot/publications/local-housing-allowance-rates/pages/2025-to-2026/.
  Scottish Government.‘Council Tax Datasets’. 26 March 2024. https://www.gov.scot/publications/council-tax-datasets/.
  Scottish Fiscal Commission. Scotland’s Economic and Fiscal Forecasts Update – June 2025 | Scottish Fiscal Commission. 25 June 2025. https://fiscalcommission.scot/publications/scotlands-economic-and-fiscal-forecasts-update-june-2025/.
  National Records Scotland. ‘Mid-2024 Population Estimates - National Records of Scotland (NRS)’. Accessed 16 August 2025. https://www.nrscotland.gov.uk/publications/mid-2024-population-estimates/.
"""
function load_sys_2025_26_ruk!( sys :: TaxBenefitSystem{T} ) where T
    sys.name = "rUK System 2025/6"

    sys.it.non_savings_rates = [20.0,40.0,45.0]
    sys.it.non_savings_thresholds = [37_700, 125_140.0]
    sys.it.non_savings_basic_rate = 2 # above this counts as higher rate rate FIXME 3???
  
    sys.it.savings_rates = [0, 20.0, 40.0, 45.0]
    sys.it.savings_thresholds = [5_000.0, 37_700.0, 125_000.0]
    sys.it.savings_basic_rate = 2 # above this counts as higher rate
  
    sys.it.dividend_rates = [0.0, 8.75,33.75,39.35]
    sys.it.dividend_thresholds = [500.0, 37_700.0, 150_000.0] # FIXME this gets the right answers & follows Melville, but the 500 is called 'dividend allowance in HMRC docs'
    sys.it.dividend_basic_rate = 2 # above this counts as higher 
  
    sys.it.personal_allowance   = 12_570.00
    sys.it.personal_allowance_income_limit = 100_000.00
    sys.it.personal_allowance_withdrawal_rate = 50.0
    sys.it.blind_persons_allowance  = 3_130.0
  
    sys.it.married_couples_allowance = 11_270.0
    sys.it.mca_minimum     = 4_360.00
    sys.it.mca_income_maximum   = 37_700.00
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

  
  sys.it.fuel_imputation = 27_800.00 # 22/23 # CHECK THIS

  #
  # TODO CHECK THIS WORKED EXAMPLE 2024/5 system change check
  # 
  sys.it.pension_contrib_basic_amount = 10_000.00
  sys.it.pension_contrib_annual_allowance = 60_000.00
  sys.it.pension_contrib_annual_minimum = 10_000.00
  sys.it.pension_contrib_threshold_income = 260_000.00
  sys.it.pension_contrib_withdrawal_rate = 50.0

  # NI
  # FREEPORTS ??? WTF ???
  sys.ni.abolished = false
  sys.ni.primary_class_1_rates = [0.0, 0.0, 8.0, 2.0 ]
  sys.ni.primary_class_1_bands = [123.0, 242.0, 967.0, 9999999999999.9] # the '-1' here is because json can't write inf
  sys.ni.secondary_class_1_rates = [0.0, 15.0, 15.0 ] # keep 2 so
  sys.ni.secondary_class_1_bands = [175.0, 967.0, 99999999999999.9 ]
  sys.ni.state_pension_age = 66; # fixme move
  # https://www.gov.uk/self-employed-national-insurance-rates
  sys.ni.class_2_threshold = 6_845
  sys.ni.class_2_rate = 3.50
  sys.ni.class_4_rates = [0.0, 6.0, 2.0 ]
  # TODO CHECK 50_270
  sys.ni.class_4_bands = [12_570.0, 50_270.0, 99999999999999.9 ]
  
  #
  # TODO CHECK APPRENTICE, U21 
  #
  sys.lmt.isa_jsa_esa_abolished = false
  sys.lmt.pen_credit_abolished = false
  ## FIXME we can't turn off pension credit individually here..

  sys.lmt.premia.family = 0.0 # see cpag 21/2 p 330 18.53
  sys.lmt.premia.family_lone_parent = 0.0 # 22.20 
  sys.lmt.premia.carer_single = 46.40
  sys.lmt.premia.carer_couple = 2*46.40
  sys.lmt.premia.disabled_child = 81.37
  sys.lmt.premia.disability_single = 43.20
  sys.lmt.premia.disability_couple = 61.65
  sys.lmt.premia.enhanced_disability_child = 32.75 
  sys.lmt.premia.enhanced_disability_single = 21.20
  sys.lmt.premia.enhanced_disability_couple = 30.25
  sys.lmt.premia.severe_disability_single = 81.50
  sys.lmt.premia.severe_disability_couple = 163.00
  sys.lmt.premia.pensioner_is = 201.95

  sys.lmt.allowances.age_18_24 = 72.90
  sys.lmt.allowances.age_25_and_over = 92.05
  sys.lmt.allowances.age_18_and_in_work_activity = 92.05
  sys.lmt.allowances.over_pension_age = 217.00 # FIXME is this still a thing?
  sys.lmt.allowances.lone_parent = 92.05
  sys.lmt.allowances.lone_parent_over_pension_age = 217.00 # FIXME sat
  sys.lmt.allowances.couple_both_under_18 = 72.90
  sys.lmt.allowances.couple_both_over_18 = 142.25
  sys.lmt.allowances.couple_over_pension_age = 324.70 # FIXME
  sys.lmt.allowances.couple_one_over_18_high = 142.25
  sys.lmt.allowances.couple_one_over_18_med = 92.05
  sys.lmt.allowances.pa_couple_one_over_18_low = 72.90
  sys.lmt.allowances.child = 84.66
  sys.lmt.allowances.pc_mig_single = 227.10
  sys.lmt.allowances.pc_mig_couple = 346.60
  sys.lmt.allowances.pc_child = 67.42

  # sys.lmt.income_rules.
  sys.lmt.income_rules.permitted_work = 195.50
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
  # FIXME child capital disregard 5000 what's that?

  sys.lmt.income_rules.capital_tariff = 250
  sys.lmt.income_rules.pensioner_tariff = 500 # FIXME is this a thing?
  # FIXME why do we need a seperate copy of HoursLimits here?

  sys.lmt.hours_limits.lower = 16
  sys.lmt.hours_limits.med = 24
  sys.lmt.hours_limits.higher = 30

  sys.lmt.savings_credit.abolished = false
  sys.lmt.savings_credit.withdrawal_rate = 60.0
  sys.lmt.savings_credit.threshold_single = 198.27
  sys.lmt.savings_credit.threshold_couple = 314.34
  sys.lmt.savings_credit.max_single = 17.30
  sys.lmt.savings_credit.max_couple = 19.36
  sys.lmt.savings_credit.available_till = Date( 2016, 04, 06 )

  sys.lmt.child_tax_credit.abolished = true
  sys.lmt.child_tax_credit.family = 545.0
  sys.lmt.child_tax_credit.child = 3_455.0
  sys.lmt.child_tax_credit.disability = 4_170.0
  sys.lmt.child_tax_credit.severe_disability = 5_850.0 # 
  sys.lmt.child_tax_credit.threshold = 19_995.0

  sys.lmt.working_tax_credit.abolished = true
  sys.lmt.working_tax_credit.basic = 2_435.0
  sys.lmt.working_tax_credit.lone_parent = 2_500.0
  sys.lmt.working_tax_credit.couple = 2_500.0
  sys.lmt.working_tax_credit.hours_ge_30 = 1_015.00
  sys.lmt.working_tax_credit.disability = 3_935.00
  sys.lmt.working_tax_credit.severe_disability = 1_705.00
  sys.lmt.working_tax_credit.age_50_plus = 1_365.00 # ?? delete
  sys.lmt.working_tax_credit.age_50_plus_30_hrs = 2_030.00 # ??
  sys.lmt.working_tax_credit.childcare_max_2_plus_children = 300.0 # pw
  sys.lmt.working_tax_credit.childcare_max_1_child = 175.0
  sys.lmt.working_tax_credit.childcare_proportion = 70.0
  sys.lmt.working_tax_credit.taper = 41.0
  sys.lmt.working_tax_credit.threshold = 7_955.0
  sys.lmt.working_tax_credit.non_earnings_minima = 300.0 # FIXME check

  sys.lmt.hb.taper = 65.0
  sys.lmt.hb.ndd_deductions = [19.65,45.15,62.00,101.35,115.45,126.65]
  sys.lmt.hb.ndd_incomes = [183.0,266.0,348.0,463.0,577.0,99999999999999.9]

  sys.lmt.ctr.taper = 20.0 # CHECK SCOTLAND!!
  sys.lmt.ctr.ndd_deductions = [] # FIXME
  sys.lmt.ctr.ndd_incomes = []


  sys.uc.abolished = false
  sys.uc.threshold = 2_500.0 ## NOT USED
  sys.uc.age_18_24 = 316.98
  sys.uc.age_25_and_over = 400.14

  sys.uc.couple_both_under_25 = 497.55
  sys.uc.couple_oldest_25_plus = 628.10

  sys.uc.first_child = 339.00
  sys.uc.subsequent_child = 292.81
  sys.uc.disabled_child_lower = 158.76
  sys.uc.disabled_child_higher = 495.87
  sys.uc.limited_capcacity_for_work_activity = 423.27
  sys.uc.carer = 201.68

  sys.uc.ndd = 91.47

  sys.uc.childcare_max_2_plus_children = 1768.94 # pm
  sys.uc.childcare_max_1_child = 1_031.88
  sys.uc.childcare_proportion = 85.0 # pct

  sys.uc.minimum_income_floor_hours = 35*WEEKS_PER_MONTH # CHECK

  sys.uc.work_allowance_w_housing = 411.00
  sys.uc.work_allowance_no_housing = 684.00
  sys.uc.other_income = UC_OTHER_INCOME
  # sys.uc.earned_income :: IncludedItems = UC_EARNED_INCOME
  sys.uc.capital_min = 6_000.0
  sys.uc.capital_max = 16_000.0
  # £1 *per week* ≆ 4.35 pm FIXME make 4.35 WEEKS_PER_MONTH? 
  sys.uc.capital_tariff = 250.0/4.35
  sys.uc.taper = 55.0
  sys.uc.ctr_taper = 20.0 # CHECK

  sys.age_limits.state_pension_ages = pension_ages()
  sys.age_limits.savings_credit_to_new_state_pension = Date( 2016, 04, 06 )

  sys.hours_limits.lower = 16
  sys.hours_limits.med = 24
  sys.hours_limits.higher = 30

  sys.child_limits.max_children = 2

  # https://www.gov.uk/government/publications/minimum-wage-rates-for-2022
  # col 1
  sys.minwage.ages = [16,18,21,23]
  sys.minwage.wage_per_hour = [7.55, 10.0, 12.21, 12.21]

  sys.minwage.apprentice_rate = 7.55

  # CHECK THESE 3 - fine https://www.gov.uk/housing-benefit/what-youll-get
  sys.hr.maximum_rooms = 4
  sys.hr.rooms_rent_reduction = [14.0,25.0]
  sys.hr.single_room_age = 35


  sys.nmt_bens.attendance_allowance.abolished = false
  sys.nmt_bens.attendance_allowance.higher = 110.40
  sys.nmt_bens.attendance_allowance.lower = 73.90


  sys.nmt_bens.child_benefit.abolished = false
  sys.nmt_bens.child_benefit.first_child = 26.05
  sys.nmt_bens.child_benefit.other_children = 17.25
  sys.nmt_bens.child_benefit.high_income_thresh = 60_000.0
  sys.nmt_bens.child_benefit.withdrawal = 1/200
  sys.nmt_bens.child_benefit.guardians_allowance = 22.10

  sys.nmt_bens.dla.abolished = false
  sys.nmt_bens.dla.care_high = 110.40
  sys.nmt_bens.dla.care_middle = 73.90
  sys.nmt_bens.dla.care_low = 29.20
  sys.nmt_bens.dla.mob_high = 77.05
  sys.nmt_bens.dla.mob_low = 29.20

  sys.nmt_bens.carers.abolished = false
  sys.nmt_bens.carers.allowance = 83.30

  # TODO
  sys.nmt_bens.carers.scottish_supplement = 288.60 # CHECK 2023/4 NOT USED!!! see scottish bens
  sys.nmt_bens.carers.hours :: Int = 35
  # FIXME check the earnings rules here
  sys.nmt_bens.carers.gainful_employment_min = 196.00


  sys.nmt_bens.pip.abolished = false
  sys.nmt_bens.pip.dl_standard = 73.90
  sys.nmt_bens.pip.dl_enhanced = 110.40
  sys.nmt_bens.pip.mobility_standard = 29.20
  sys.nmt_bens.pip.mobility_enhanced = 77.05
  
  sys.nmt_bens.esa.abolished = false
  sys.nmt_bens.esa.assessment_u25 = 72.90
  sys.nmt_bens.esa.assessment_25p = 92.05
  sys.nmt_bens.esa.main   = 92.05
  sys.nmt_bens.esa.work   = 36.55
  sys.nmt_bens.esa.support  = 48.50 # chevk 2024 typo!


  sys.nmt_bens.jsa.abolished = false
  sys.nmt_bens.jsa.u25 = 72.90
  sys.nmt_bens.jsa.o24 = 92.05

  sys.nmt_bens.pensions.abolished = false
  sys.nmt_bens.pensions.new_state_pension = 230.25
  # pension_start_date = Date( 2016, 04, 06 )
  sys.nmt_bens.pensions.cat_a  = 176.45
  sys.nmt_bens.pensions.cat_b  = 176.45
  sys.nmt_bens.pensions.cat_b_survivor = 105.70
  sys.nmt_bens.pensions.cat_d  = 105.70

  sys.nmt_bens.bereavement.abolished = false
  # higher effectively just means 'with children'; 
  sys.nmt_bens.bereavement.lump_sum_higher = 3_500
  sys.nmt_bens.bereavement.lump_sum_lower = 2_500
  sys.nmt_bens.bereavement.higher = 350
  sys.nmt_bens.bereavement.lower = 100

  sys.nmt_bens.widows_pension.abolished = false
  sys.nmt_bens.widows_pension.industrial_higher = 156.20 # FIXME check these 2 again
  sys.nmt_bens.widows_pension.industrial_lower = 46.86
  sys.nmt_bens.widows_pension.standard_rate =  150.90
  sys.nmt_bens.widows_pension.parent = 148.40 # FIXME abolished???
  sys.nmt_bens.widows_pension.ages = collect(54:-1:45)
  sys.nmt_bens.widows_pension.age_amounts = [140.34, 129.77, 119.21, 108.65, 98.09,
    87.52, 76.69, 66.40, 55.83, 45.27] # CHECK 2024!

  # 
  sys.nmt_bens.maternity.abolished = false
  sys.nmt_bens.maternity.rate = 187.18

  sys.nmt_bens.smp = 184.03 ## 90% of earn cpag 21/2 812

  sys.bencap.abolished = false
  sys.bencap.outside_london_single = 283.71
  sys.bencap.outside_london_couple = 423.46
  sys.bencap.inside_london_single = 326.29
  sys.bencap.inside_london_couple = 486.98
  sys.bencap.uc_incomes_limit = 16 *  sys.minwage.wage_per_hour[end] * WEEKS_PER_MONTH

  sys.ubi.abolished = true
  sys.ubi.adult_amount = 4_800.0
  sys.ubi.child_amount= 3_000.0
  sys.ubi.universal_pension = 8_780.0
  sys.ubi.adult_age = 17
  sys.ubi.retirement_age = 66

  sys.loctax.ct.band_d = Dict(
    [
      :ENGLAND  => 2_280.0, # !!! Inc London
      :WALES    => 2_170.0,
      :SCOTLAND => 1_421.0, # !!! 2024/5
      :LONDON => 2_280.0, # !!! NO
      :NIRELAND => -99999.99
    ] )

  # FIXME? No updated publication as of 5/7/2024 ??https://www.gov.uk/government/publications/local-housing-allowance-lha-rates-applicable-from-april-2023-to-march-2024#full-publication-update-history
  # brmapath = joinpath(MODEL_DATA_DIR, "local", "brma-2023-2024-country-averages.csv")
  brmapath = joinpath( qualified_artifact( "augdata" ), "brma-2023-2024-country-averages.csv")
  sys.hr.brmas = loadBRMAs( 4, Float64, brmapath )

  # here so it's always on 
  sys.scottish_child_payment.abolished = false
  sys.scottish_child_payment.amount = 26.70
  sys.scottish_child_payment.maximum_age = 15
  

end