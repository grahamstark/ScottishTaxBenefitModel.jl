"""
 SCOTLAND 2023/4
 IT: https://www.gov.scot/publications/scottish-income-tax-2024-25-factsheet/
 https://www.socialsecurity.gov.scot/news-events/news/social-security-payment-rates-increased-for-2024   
"""

function load_sys_2023_24_scotland!( sys :: TaxBenefitSystem )
    sys.name = "Scottish System 2023/24"
    sys.it.non_savings_rates = [19.0,20.0,21.0,42.0,47.0]
    sys.it.non_savings_thresholds = [2_162, 13_118, 31_092, 112_570.0]
    sys.it.non_savings_basic_rate = 2 # above this counts as higher rate rate FIXME 3???
    sys.nmt_bens.carers.scottish_supplement = 0.0 # FROM APRIL 2021
    brmapath = joinpath( qualified_artifact( "augdata" ), "lha_rates_scotland_2023_24.csv")
    sys.hr.brmas = loadBRMAs( 4, Float64, brmapath )
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
        :S12000020 =>   1362.56,
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

   # here so it's always on 
   sys.scottish_child_payment.abolished = false
   sys.scottish_child_payment.amount = 25.00
   sys.scottish_child_payment.maximum_age = 15
   # Renames to Scottish benefits.
   sys.nmt_bens.carers.slot = CARERS_SUPPORT_PAYMENT
   sys.nmt_bens.dla.care_slot = CHILD_DISABILITY_PAYMENT_CARE
   sys.nmt_bens.dla.mob_slot = CHILD_DISABILITY_PAYMENT_MOBILITY
   sys.nmt_bens.pip.care_slot = ADP_DAILY_LIVING
   sys.nmt_bens.pip.mob_slot = ADP_MOBILITY
   sys.nmt_bens.attendance_allowance.slot = PENSION_AGE_DISABILITY
end