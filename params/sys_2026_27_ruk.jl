"""
This is the benefit/tax credit/IT/MinWage/NI rates for rUK, excluding NI, 
as of January 2026 - FY 2026/7

  GOV.UK. ‘Benefit and Pension Rates 2026 to 2027’. Accessed 9 January 2026. https://www.gov.uk/government/publications/benefit-and-pension-rates-2026-to-2027.
  GOV.UK. 'Annex A: Rates and allowances'. Accessed 9 January 2026. https://www.gov.uk/government/publications/budget-2025-overview-of-tax-legislation-and-rates-ootlar/annex-a-rates-and-allowances. 
  GOV.UK, 'Minimum wage rates for 2026'. Accessed 12 January 2026. https://www.gov.uk/government/publications/minimum-wage-rates-for-2026.

  [Others to be added as used.]

"""
function load_sys_2026_27_ruk!( sys :: TaxBenefitSystem{T} ) where T
    sys.name = "rUK System 2026/7"

    # COMMENT: Income tax rates/thresholds not in PDF - carried forward, need confirmation
    sys.it.non_savings_rates = [20.0,40.0,45.0]
    sys.it.non_savings_thresholds = [37_700, 125_140.0]
    sys.it.non_savings_basic_rate = 2 # above this counts as higher rate rate FIXME 3???
  
    sys.it.savings_rates = [0, 20.0, 40.0, 45.0] # this doesn't change in 26/27 but will change 27/28
    sys.it.savings_thresholds = [5_000.0, 37_700.0, 125_140.0]
    sys.it.savings_basic_rate = 2 # above this counts as higher rate
  
    sys.it.dividend_rates = [0.0, 10.75, 35.75, 39.35] # includes 2025 budget changes
    sys.it.dividend_thresholds = [500.0, 37_700.0, 125_140.0] # FIXME this gets the right answers & follows Melville, but the 500 is called 'dividend allowance in HMRC docs'
    sys.it.dividend_basic_rate = 2 # above this counts as higher 
  
    sys.it.personal_allowance   = 12_570.00
    sys.it.personal_allowance_income_limit = 100_000.00
    sys.it.personal_allowance_withdrawal_rate = 50.0
    sys.it.blind_persons_allowance  = 3_250.0  
  
    sys.it.married_couples_allowance = 11_700.0  
    sys.it.mca_minimum     = 4_530.00  
    sys.it.mca_income_maximum   = 39_200.00
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

  
  sys.it.fuel_imputation = 27_800.00 # TODO: CHECK 2026/27 rate

  #
  # TODO CHECK THIS WORKED EXAMPLE 2024/5 system change check
  # 
  sys.it.pension_contrib_basic_amount = 10_000.00
  sys.it.pension_contrib_annual_allowance = 60_000.00
  sys.it.pension_contrib_annual_minimum = 10_000.00
  sys.it.pension_contrib_threshold_income = 260_000.00
  sys.it.pension_contrib_withdrawal_rate = 50.0
  # TODO: 2026/27 hasn't been published yet I think - https://www.gov.uk/government/publications/rates-and-allowances-pension-schemes/pension-schemes-rates

  # NI
  # FREEPORTS ??? WTF ???
  sys.ni.abolished = false
  sys.ni.primary_class_1_rates = [0.0, 0.0, 8.0, 2.0 ]  # TODO: Is the first one in cases of no income? GKS - above 1st 0 rate you're credited with making NI contributions - makes no difference to a 1 period model.
  sys.ni.primary_class_1_bands = [129.0, 242.0, 967.0, 9999999999999.9]  
  sys.ni.secondary_class_1_rates = [0.0, 15.0, 15.0 ]  
  sys.ni.secondary_class_1_bands = [96.0, 967.0, 99999999999999.9 ] 
  sys.ni.state_pension_age = 66; # TODO I think transition has started to 67 but this is a good approx?
  sys.ni.class_2_threshold = 7_105  
  sys.ni.class_2_rate = 3.65  # TODO is this the class 2 cont rates Below Small Profits Threshold (SPT)?
  sys.ni.class_4_rates = [0.0, 6.0, 2.0 ] 
  sys.ni.class_4_bands = [12_570.0, 50_270.0, 99999999999999.9 ] 
  
  #
  # TODO CHECK APPRENTICE, U21 
  #
  sys.lmt.isa_jsa_esa_abolished = false
  sys.lmt.pen_credit_abolished = false
  ## FIXME we can't turn off pension credit individually here..

  # Premia 
  sys.lmt.premia.family = 20.22 # FIXME this was previously set at 0.0 but with comment (see cpag 21/2 p 330 18.53)
  sys.lmt.premia.family_lone_parent = 22.20 # like above 
  sys.lmt.premia.carer_single = 48.15  
  sys.lmt.premia.carer_couple = 2*48.15
  sys.lmt.premia.disabled_child = 84.46  
  sys.lmt.premia.disability_single = 44.85 
  sys.lmt.premia.disability_couple = 64.00 
  sys.lmt.premia.enhanced_disability_child = 33.99 
  sys.lmt.premia.enhanced_disability_single = 22.00  
  sys.lmt.premia.enhanced_disability_couple = 31.40 
  sys.lmt.premia.severe_disability_single = 86.05  
  sys.lmt.premia.severe_disability_couple = 172.10  
  sys.lmt.premia.pensioner_is = 213.10 

  # Allowances 
  sys.lmt.allowances.age_18_24 = 75.65  
  sys.lmt.allowances.age_25_and_over = 95.55  
  sys.lmt.allowances.age_18_and_in_work_activity = 95.55
  sys.lmt.allowances.over_pension_age = 217.00 # FIXME is this still a thing? TODO: CHECK
  sys.lmt.allowances.lone_parent = 95.55  
  sys.lmt.allowances.lone_parent_over_pension_age = 217.00 # FIXME sat TODO: CHECK
  sys.lmt.allowances.couple_both_under_18 = 75.65  
  sys.lmt.allowances.couple_both_over_18 = 150.15  
  sys.lmt.allowances.couple_over_pension_age = 324.70 # FIXME TODO: CHECK
  sys.lmt.allowances.couple_one_over_18_high = 150.15
  sys.lmt.allowances.couple_one_over_18_med = 95.55
  sys.lmt.allowances.pa_couple_one_over_18_low = 75.65
  sys.lmt.allowances.child = 87.88  
  sys.lmt.allowances.pc_mig_single = 238.00  
  sys.lmt.allowances.pc_mig_couple = 363.25  
  sys.lmt.allowances.pc_child = 69.98  

  # Income rules 
  sys.lmt.income_rules.permitted_work = 203.50  
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
  sys.lmt.income_rules.pensioner_tariff = 500 
  
  # FIXME why do we need a seperate copy of HoursLimits here?
  sys.lmt.hours_limits.lower = 16
  sys.lmt.hours_limits.med = 24
  sys.lmt.hours_limits.higher = 30
  # TODO - can't find these for 26/27 but seems only relevant to legacy benefits so doubt it changed?


  # Savings credit 
  sys.lmt.savings_credit.abolished = false
  sys.lmt.savings_credit.withdrawal_rate = 60.0
  sys.lmt.savings_credit.threshold_single = 208.07  
  sys.lmt.savings_credit.max_single = 17.96  
  sys.lmt.savings_credit.max_couple = 20.10  
  sys.lmt.savings_credit.available_till = Date( 2016, 04, 06 )

  # Child Tax Credit
  sys.lmt.child_tax_credit.abolished = true
  sys.lmt.child_tax_credit.family = 545.0
  sys.lmt.child_tax_credit.child = 3_455.0
  sys.lmt.child_tax_credit.disability = 4_170.0
  sys.lmt.child_tax_credit.severe_disability = 5_850.0  
  sys.lmt.child_tax_credit.threshold = 19_995.0

  # Working Tax Credit
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

  # Housing Benefit 
  sys.lmt.hb.taper = 65.0
  sys.lmt.hb.ndd_deductions = [20.40, 46.85, 64.35, 105.20, 119.85, 131.45] 
  sys.lmt.hb.ndd_incomes = [192.0, 279.0, 365.0, 485.0, 605.0, 99999999999999.9]  # Updated bands from PDF
  # FIXME they appear like this in the pdf but seem frozen since 25/26 while the deductions have increased. Weird. TODO: CHECK
  
  sys.lmt.ctr.taper = 20.0 # CHECK SCOTLAND!! 20% is correct
  sys.lmt.ctr.ndd_deductions = [5.35, 10.35, 13.15, 15.95] # FIXME 25/26 rates. First applies to those without remuneration and with less than 273.
  sys.lmt.ctr.ndd_incomes = [273.0, 474.0, 586.0] # FIXME 25/26 rates. TODO: Check post-budget
  # TODO - I've added these in for 25/26. Don't think they are being used in the code.

  # Universal Credit
  sys.uc.abolished = false
  sys.uc.threshold = 2_500.0 ## NOT USED
  sys.uc.age_18_24 = 338.58  
  sys.uc.age_25_and_over = 424.90  

  sys.uc.couple_both_under_25 = 528.34  
  sys.uc.couple_oldest_25_plus = 666.97  

  sys.uc.first_child = 351.88  
  sys.uc.subsequent_child = 303.94  
  sys.uc.disabled_child_lower = 164.79  
  sys.uc.disabled_child_higher = 514.71  
  # COMMENT: LCWRA has different rates for different claimant types in 2026/27.
  # PDF shows: LCWRA = 217.26 (general) BUT 429.80 for pre-2026 claimants/severe conditions/terminally ill
  # The 25/26 rate was 423.27 for everyone TODO: CHECK
  sys.uc.limited_capcacity_for_work_activity = 217.26  
  sys.uc.carer = 209.34  

  sys.uc.ndd = 96.55 

  sys.uc.childcare_max_2_plus_children = 1836.16  
  sys.uc.childcare_max_1_child = 1071.09  

  sys.uc.minimum_income_floor_hours = 35*WEEKS_PER_MONTH # CHECK

  sys.uc.work_allowance_w_housing = 427.00 
  sys.uc.work_allowance_no_housing = 710.00  
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

  sys.child_limits.max_children = 9999999 # TODO: CHECK. 2CL abolished.

  # Minimum wage
  sys.minwage.ages = [16,18,21,23]
  sys.minwage.wage_per_hour = [8.0, 10.85, 12.71, 12.71] 

  sys.minwage.apprentice_rate = 8.0  

  # CHECK THESE 3 - fine https://www.gov.uk/housing-benefit/what-youll-get
  sys.hr.maximum_rooms = 4 # FIXME - Don't know what this is.
  sys.hr.rooms_rent_reduction = [14.0,25.0]
  sys.hr.single_room_age = 35 # FIXME - changed from 35. If this is who's expected to have a single room it's anyone above 16.
  # GKS - this is the 'one bedroom shared accomodation' age (which column in tne BRMA table you look up). 35 is correct for this but I'll revisit. 

  # Attendance Allowance 
  sys.nmt_bens.attendance_allowance.abolished = false
  sys.nmt_bens.attendance_allowance.higher = 114.60  
  sys.nmt_bens.attendance_allowance.lower = 76.70  


  # Child Benefit 
  sys.nmt_bens.child_benefit.abolished = false
  sys.nmt_bens.child_benefit.first_child = 27.05  
  sys.nmt_bens.child_benefit.other_children = 17.90 
  sys.nmt_bens.child_benefit.high_income_thresh = 60_000.0
  sys.nmt_bens.child_benefit.withdrawal = 1/200
  sys.nmt_bens.child_benefit.guardians_allowance = 22.95  

  # DLA 
  sys.nmt_bens.dla.abolished = false
  sys.nmt_bens.dla.care_high = 114.60  
  sys.nmt_bens.dla.care_middle = 76.70  
  sys.nmt_bens.dla.care_low = 30.30  
  sys.nmt_bens.dla.mob_high = 80.00  
  sys.nmt_bens.dla.mob_low = 30.30  

  # Carer's Allowance 
  sys.nmt_bens.carers.abolished = false
  sys.nmt_bens.carers.allowance = 86.45  

  # TODO
  sys.nmt_bens.carers.scottish_supplement = 288.60 # TODO: CHECK 2026/27 - NOT USED!!! see scottish bens
  sys.nmt_bens.carers.hours :: Int = 35
  # FIXME check the earnings rules here
  sys.nmt_bens.carers.gainful_employment_min = 204.00  


  # PIP 
  sys.nmt_bens.pip.abolished = false
  sys.nmt_bens.pip.dl_standard = 76.70  
  sys.nmt_bens.pip.dl_enhanced = 114.60  
  sys.nmt_bens.pip.mobility_standard = 30.30  
  sys.nmt_bens.pip.mobility_enhanced = 80.00  
  
  # ESA 
  sys.nmt_bens.esa.abolished = false
  sys.nmt_bens.esa.assessment_u25 = 75.65 
  sys.nmt_bens.esa.assessment_25p = 95.55  
  sys.nmt_bens.esa.main   = 95.55
  sys.nmt_bens.esa.work   = 37.95  
  sys.nmt_bens.esa.support  = 50.35  


  # JSA 
  sys.nmt_bens.jsa.abolished = false
  sys.nmt_bens.jsa.u25 = 75.65  
  sys.nmt_bens.jsa.o24 = 95.55  

  # State Pension 
  sys.nmt_bens.pensions.abolished = false
  sys.nmt_bens.pensions.new_state_pension = 241.30  
  # pension_start_date = Date( 2016, 04, 06 )
  sys.nmt_bens.pensions.cat_a  = 184.90  
  sys.nmt_bens.pensions.cat_b  = 184.90
  sys.nmt_bens.pensions.cat_b_survivor = 110.75  
  sys.nmt_bens.pensions.cat_d  = 110.75  

  # Bereavement 
  sys.nmt_bens.bereavement.abolished = false
  # higher effectively just means 'with children'; 
  sys.nmt_bens.bereavement.lump_sum_higher = 3_500  
  sys.nmt_bens.bereavement.lump_sum_lower = 2_500  
  sys.nmt_bens.bereavement.higher = 350  
  sys.nmt_bens.bereavement.lower = 100  

  # Widow's Pension 
  sys.nmt_bens.widows_pension.abolished = false
  sys.nmt_bens.widows_pension.industrial_higher = 184.90  
  sys.nmt_bens.widows_pension.industrial_lower = 55.47   
  sys.nmt_bens.widows_pension.standard_rate = 156.65  
  sys.nmt_bens.widows_pension.parent = 156.65 
  sys.nmt_bens.widows_pension.ages = collect(54:-1:45)
  sys.nmt_bens.widows_pension.age_amounts = [145.68, 134.72, 123.75, 112.79, 101.82,
    90.86, 79.89, 68.93, 57.96, 47.00]

  # Maternity 
  sys.nmt_bens.maternity.abolished = false
  sys.nmt_bens.maternity.rate = 194.32
  sys.nmt_bens.smp = 194.32  

  # Benefit Cap 
  sys.bencap.abolished = false
  sys.bencap.outside_london_single = 283.71 
  sys.bencap.outside_london_couple = 423.46  
  sys.bencap.inside_london_single = 326.29  
  sys.bencap.inside_london_couple = 486.98  
  sys.bencap.uc_incomes_limit = 16 *  sys.minwage.wage_per_hour[end] * WEEKS_PER_MONTH

  # UBI
  sys.ubi.abolished = true
  sys.ubi.adult_amount = 4_800.0
  sys.ubi.child_amount= 3_000.0
  sys.ubi.universal_pension = 8_780.0
  sys.ubi.adult_age = 17
  sys.ubi.retirement_age = 66

  # Council Tax
  # TODO - Update with 26/27 figures. Post SG budget?
  sys.loctax.ct.band_d = Dict(
    [
      :ENGLAND  => 2_280.0, # TODO: UPDATE 2026/27
      :WALES    => 2_170.0, # TODO: UPDATE 2026/27
      :SCOTLAND => 1_421.0, # TODO: UPDATE 2026/27
      :LONDON => 2_280.0,   # TODO: UPDATE 2026/27
      :NIRELAND => -99999.99
    ] )

  # FIXME? Update BRMA path for 2026/27
  brmapath = joinpath( qualified_artifact( "augdata" ), "brma-2023-2024-country-averages.csv")  # TODO: UPDATE
  sys.hr.brmas = loadBRMAs( 4, Float64, brmapath )

  # here so it's always on 
  # COMMENT: Scottish Child Payment not in PDF - need separate Scottish source
  sys.scottish_child_payment.abolished = false
  sys.scottish_child_payment.amounts = [26.70,0.0]  # TODO: CHECK 2026/27
  sys.scottish_child_payment.maximum_ages = [15,99]
  

end
