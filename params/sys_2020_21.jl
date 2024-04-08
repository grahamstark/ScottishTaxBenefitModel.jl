"""
# April 2020 Benefit Rates: CAREFUL 
"""
function load_sys_2020_21!( sys :: TaxBenefitSystem{T} ) where T

    sys.name = "Scotland System 2020/21"
    #
    sys.it.savings_rates   =  [0.0, 20.0, 40.0, 45.0]
    sys.it.savings_thresholds   =  [5_000.0, 37_500.0, 150_000.0]
    sys.it.savings_basic_rate = 2 # above this counts as higher rate

    sys.it.non_savings_rates  =  [19.0,20.0,21.0,41.0,46.0]
    sys.it.non_savings_thresholds  =  [2_085, 12_658, 31_931, 150_000.0]
    sys.it.non_savings_basic_rate = 2 # above this counts as higher rate

    sys.it.dividend_rates  =  [0.0, 7.5,32.5,38.1]
    sys.it.dividend_thresholds  =  [2_000.0, 37_500.0, 150_000.0]
    sys.it.dividend_basic_rate = 2 # above this counts as higher rate

    sys.it.personal_allowance          = 12_500.00
    sys.it.personal_allowance_income_limit = 100_000.00
    sys.it.personal_allowance_withdrawal_rate = 50.0
    sys.it.blind_persons_allowance     = 2_500.00

    sys.it.married_couples_allowance   = 9_075.00
    sys.it.mca_minimum                 = 3_510.00
    sys.it.mca_income_maximum          = 29_600.00
    sys.it.mca_credit_rate             = 10.0
    sys.it.mca_withdrawal_rate        = 50.0

    sys.it.marriage_allowance          = 1_260.00 # check 20/21
    sys.it.personal_savings_allowance  = 1_000.00

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

        
    sys.it.fuel_imputation  = 24_500.00 # 20/21

    #
    # pensions
    # CHECK THESE FOR UPRATING
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



    sys.ni.abolished = false
    sys.ni.primary_class_1_rates  = [0.0, 0.0, 12.0, 2.0 ]
    sys.ni.primary_class_1_bands  = [120.0, 183.0, 962.0, 9999999999999.9] # the '-1' here is because json can't write inf
    sys.ni.secondary_class_1_rates  = [0.0, 13.8, 13.8 ] # keep 2 so
    sys.ni.secondary_class_1_bands  = [170.0, 967.0, 99999999999999.9 ]
    sys.ni.state_pension_age = 66; # fixme move
    sys.ni.class_2_threshold = 6_475.0;
    sys.ni.class_2_rate = 3.05;
    sys.ni.class_4_rates  = [0.0, 9.0, 2.0 ]
    sys.ni.class_4_bands  = [9_500.0, 50_270.0, 99999999999999.9 ]
    # sys.ni.class_1_income = IncludedItems([WAGES],[PENSION_CONTRIBUTIONS_EMPLOYER])
    # sys.ni.class_4_income = [SELF_EMPLOYMENT_INCOME]

    # sys.uc.

    sys.lmt.isa_jsa_esa_abolished = false
    sys.lmt.pen_credit_abolished = false
    ## FIXME we can't turn off pension credit individually here..

    sys.lmt.premia.family = 17.60
    sys.lmt.premia.family_lone_parent = 22.20 
    sys.lmt.premia.carer_single = 37.50
    sys.lmt.premia.carer_couple = 2*37.50 
    sys.lmt.premia.disabled_child = 65.52
    sys.lmt.premia.disability_single = 34.95
    sys.lmt.premia.disability_couple = 49.80
    sys.lmt.premia.enhanced_disability_child = 26.60
    sys.lmt.premia.enhanced_disability_single = 17.10
    sys.lmt.premia.enhanced_disability_couple = 24.50
    sys.lmt.premia.severe_disability_single = 66.95
    sys.lmt.premia.severe_disability_couple = 133.90
    sys.lmt.premia.pensioner_is = 148.40

    sys.lmt.allowances.age_18_24 = 58.90
    sys.lmt.allowances.age_25_and_over = 74.35
    sys.lmt.allowances.age_18_and_in_work_activity = 74.35
    sys.lmt.allowances.over_pension_age = 187.75 #
    sys.lmt.allowances.lone_parent = 74.70
    sys.lmt.allowances.lone_parent_over_pension_age = 191.15 
    sys.lmt.allowances.couple_both_under_18 = 74.35
    sys.lmt.allowances.couple_both_over_18 = 74.35
    sys.lmt.allowances.couple_over_pension_age =  280.85
    sys.lmt.allowances.couple_one_over_18_high =  116.80
    sys.lmt.allowances.couple_one_over_18_med = 74.35
    sys.lmt.allowances.pa_couple_one_over_18_low = 58.90
    sys.lmt.allowances.child = 68.27
    sys.lmt.allowances.pc_mig_single = 173.75
    sys.lmt.allowances.pc_mig_couple = 265.20

    # sys.lmt.income_rules.
    sys.lmt.income_rules.permitted_work = 140.00
    sys.lmt.income_rules.lone_parent_hb = 25.0
    sys.lmt.income_rules.high = 20.0
    sys.lmt.income_rules.low_couple = 10.0
    sys.lmt.income_rules.low_single = 5.0
    sys.lmt.income_rules.hb_additional = 17.10
    sys.lmt.income_rules.childcare_max_1 = 175.0
    sys.lmt.income_rules.childcare_max_2 = 300.0
    sys.lmt.income_rules.incomes     = LEGACY_MT_INCOME
    sys.lmt.income_rules.hb_incomes  = LEGACY_HB_INCOME
    sys.lmt.income_rules.pc_incomes  = LEGACY_PC_INCOME
    sys.lmt.income_rules.sc_incomes  = LEGACY_SAVINGS_CREDIT_INCOME
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
    sys.lmt.savings_credit.threshold_single = 150.47
    sys.lmt.savings_credit.threshold_couple = 239.17
    sys.lmt.savings_credit.max_single = 13.97
    sys.lmt.savings_credit.max_couple = 15.62
    sys.lmt.savings_credit.available_till = Date( 2016, 04, 06 )

    sys.lmt.child_tax_credit.abolished = false
    sys.lmt.child_tax_credit.family = 545.0
    sys.lmt.child_tax_credit.child  = 2_830.0
    sys.lmt.child_tax_credit.disability = 3_415
    sys.lmt.child_tax_credit.severe_disability = 4825
    sys.lmt.child_tax_credit.threshold = 16_385.0

    sys.lmt.working_tax_credit.basic = 3_040 # with the 10pw uplift
    sys.lmt.working_tax_credit.lone_parent = 2_045
    sys.lmt.working_tax_credit.couple  = 2_045
    sys.lmt.working_tax_credit.hours_ge_30 = 825
    sys.lmt.working_tax_credit.disability = 3_220
    sys.lmt.working_tax_credit.severe_disability = 1_390
    sys.lmt.working_tax_credit.age_50_plus  = 1_365.00  # not used?
    sys.lmt.working_tax_credit.age_50_plus_30_hrs = 2_030.00 # not used?
    sys.lmt.working_tax_credit.childcare_max_2_plus_children = 300.0 # pw
    sys.lmt.working_tax_credit.childcare_max_1_child  = 175.0
    sys.lmt.working_tax_credit.childcare_proportion = 70.0
    sys.lmt.working_tax_credit.taper = 41.0
    sys.lmt.working_tax_credit.threshold = 6_530.0
    sys.lmt.working_tax_credit.non_earnings_minima = 300.0 # FIXME check

    sys.lmt.hb.taper = 65.0
    sys.lmt.hb.ndd_deductions = [15.85,36.45,50.05,81.90,93.25,102.35]
    sys.lmt.hb.ndd_incomes = [149.0,217.0,283.0,377.0,469.0,99999999999999.9]

    sys.lmt.ctr.taper = 20.0
    sys.lmt.ctr.ndd_deductions = []
    sys.lmt.ctr.ndd_incomes = []


    sys.uc.abolished = false
    sys.uc.threshold = 2_500.0 ## NOT USED
    sys.uc.age_18_24 = 342.72
    sys.uc.age_25_and_over = 409.89

    sys.uc.couple_both_under_25 = 488.59
    sys.uc.couple_oldest_25_plus = 594.04

    sys.uc.first_child  = 281.25
    sys.uc.subsequent_child = 235.83
    sys.uc.disabled_child_lower = 128.25
    sys.uc.disabled_child_higher = 400.29
    sys.uc.limited_capcacity_for_work_activity = 341.92
    sys.uc.carer = 163.73

    sys.uc.ndd = 75.15

    sys.uc.childcare_max_2_plus_children  = 1_108.04 # pm
    sys.uc.childcare_max_1_child  = 646.35
    sys.uc.childcare_proportion = 85.0 # pct

    sys.uc.minimum_income_floor_hours = 35*WEEKS_PER_MONTH

    sys.uc.work_allowance_w_housing = 292.0
    sys.uc.work_allowance_no_housing = 512.0
    sys.uc.other_income = UC_OTHER_INCOME
    # sys.uc.earned_income :: IncludedItems = UC_EARNED_INCOME
    sys.uc.capital_min = 6_000.0
    sys.uc.capital_max = 16_000.0
    # £1 *per week* ≆ 4.35 pm FIXME make 4.35 WEEKS_PER_MONTH? 
    sys.uc.capital_tariff = 250.0/4.35
    sys.uc.taper = 63.0
    sys.uc.ctr_taper = 20.0

    sys.age_limits.state_pension_ages = pension_ages()
    sys.age_limits.savings_credit_to_new_state_pension = Date( 2016, 04, 06 )

    sys.hours_limits.lower = 16
    sys.hours_limits.med = 24
    sys.hours_limits.higher = 30

    sys.child_limits.max_children = 2
    # TILL APRIL 22
    sys.minwage.ages = [16,18,21,23]
    sys.minwage.wage_per_hour = [4.62, 6.56, 8.36, 8.91]
    sys.minwage.apprentice_rate = 4.30

    sys.hr.maximum_rooms = 4
    sys.hr.rooms_rent_reduction = [14.0,25.0]
    sys.hr.single_room_age = 35
    #
    # These are unchanged in 3 years; see:
    # https://www.gov.scot/publications/local-housing-allowance-rates-2021-2022/
    #
    sys.hr.brmas = loadBRMAs( 4, T, DEFAULT_BRMA_2021 ) 



    sys.nmt_bens.attendance_allowance.abolished = false
    sys.nmt_bens.attendance_allowance.higher = 89.60
    sys.nmt_bens.attendance_allowance.lower = 60.00


    sys.nmt_bens.child_benefit.abolished = false
    sys.nmt_bens.child_benefit.first_child = 21.05
    sys.nmt_bens.child_benefit.other_children = 13.95
    sys.nmt_bens.child_benefit.high_income_thresh = 50_000.0
    sys.nmt_bens.child_benefit.withdrawal = 1/100
    sys.nmt_bens.child_benefit.guardians_allowance = 17.90

    sys.nmt_bens.dla.abolished = false
    sys.nmt_bens.dla.care_high = 89.15
    sys.nmt_bens.dla.care_middle  = 59.70
    sys.nmt_bens.dla.care_low  = 23.60
    sys.nmt_bens.dla.mob_high  = 62.25
    sys.nmt_bens.dla.mob_low  = 23.60


    sys.nmt_bens.carers.abolished = false
    sys.nmt_bens.carers.allowance =  67.25
    sys.nmt_bens.carers.scottish_supplement = 231.40
    sys.nmt_bens.carers.hours :: Int = 35
    sys.nmt_bens.carers.gainful_employment_min = 128.00


    sys.nmt_bens.pip.abolished = false
    sys.nmt_bens.pip.dl_standard = 59.70
    sys.nmt_bens.pip.dl_enhanced = 89.15
    sys.nmt_bens.pip.mobility_standard = 23.60
    sys.nmt_bens.pip.mobility_enhanced = 62.25
    
    sys.nmt_bens.esa.abolished = false
    sys.nmt_bens.esa.assessment_u25 = 58.90
    sys.nmt_bens.esa.assessment_25p = 74.35
    sys.nmt_bens.esa.main           = 74.35
    sys.nmt_bens.esa.work           = 29.55
    sys.nmt_bens.esa.support        = 39.20


    sys.nmt_bens.jsa.abolished = false
    sys.nmt_bens.jsa.u25 = 58.90
    sys.nmt_bens.jsa.o24 = 74.35

    sys.nmt_bens.pensions.abolished = false
    sys.nmt_bens.pensions.new_state_pension = 175.20
    # pension_start_date = Date( 2016, 04, 06 )
    sys.nmt_bens.pensions.cat_a     = 134.25
    sys.nmt_bens.pensions.cat_b     = 134.25
    sys.nmt_bens.pensions.cat_b_survivor = 80.45
    sys.nmt_bens.pensions.cat_d     = 80.45

    sys.nmt_bens.bereavement.abolished = false
    # higher effectively just means 'with children'; 
    sys.nmt_bens.bereavement.lump_sum_higher = 3_500
    sys.nmt_bens.bereavement.lump_sum_lower  = 2_500
    sys.nmt_bens.bereavement.higher = 350
    sys.nmt_bens.bereavement.lower  = 100

    sys.nmt_bens.widows_pension.abolished = false
    sys.nmt_bens.widows_pension.industrial_higher = 134.25
    sys.nmt_bens.widows_pension.industrial_lower = 40.28
    sys.nmt_bens.widows_pension.standard_rate =  121.95
    sys.nmt_bens.widows_pension.parent =  121.95
    sys.nmt_bens.widows_pension.ages = collect(54:-1:45)
    sys.nmt_bens.widows_pension.age_amounts = [113.41,104.88,96.34,87.80,79.27,70.73,62.19,53.66,45.12,36.59]

    # 
    # young carer grant
    sys.nmt_bens.maternity.abolished = false
    sys.nmt_bens.maternity.rate = 151.20


    sys.nmt_bens.smp = 151.97 ## 90% of earn cpag 21/2 812
    # = XX

    sys.bencap.abolished = false
    sys.bencap.outside_london_single = 257.69
    sys.bencap.outside_london_couple = 384.62
    # not really needed, but anyway ..
    sys.bencap.inside_london_single = 296.35
    sys.bencap.inside_london_couple  = 442.31
    sys.bencap.uc_incomes_limit  = 617

    sys.scottish_child_payment.amount = 10.0
    sys.scottish_child_payment.maximum_age = 5

    sys.ubi.abolished = true
    sys.ubi.adult_amount = 4_800.0
    sys.ubi.child_amount= 3_000.0
    sys.ubi.universal_pension = 8_780.0
    sys.ubi.adult_age = 17
    sys.ubi.retirement_age = 66

end