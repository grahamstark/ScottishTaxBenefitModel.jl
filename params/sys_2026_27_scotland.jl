"""
 SCOTLAND 2025/6

 Sources:
 IT: https://www.gov.scot/publications/scottish-income-tax-2025-26-factsheet/
 CT: https://www.gov.scot/publications/council-tax-datasets/
 BRMA: https://www.gov.scot/publications/local-housing-allowance-rates-2024-2025/
 Benefits: https://bprcdn.parliament.scot/published/2024/3/14/6f58227d-21aa-4016-91e6-f3d0bb29962d/SB%2024-15.pdf
"""
function load_sys_2026_27_scotland!( sys :: TaxBenefitSystem{T} ) where T
    sys.name = "Scottish System 2026/27"
    sys.it.non_savings_rates = T[
        19.0, # starter
        20.0, # basic
        21.0, # intermediate
        42.0, # higher
        45,   # advanced
        48.0] # top
    sys.it.non_savings_thresholds = T[
        3_967.0,
        16_956.0,
        31_092.0,
        62_430.0,
        125_140 ]

    sys.it.non_savings_basic_rate = 2 # above this counts as higher rate rate FIXME 3???
    # sys.nmt_bens.carers.scottish_supplement = 0.0 # FROM APRIL 2021
    sys.nmt_bens.carers.scottish_supplement = 293.50 # FROM APRIL 2021 !!! Check 2024
  
    brmapath = joinpath( qualified_artifact( "augdata" ), "lha_rates_scotland_2025_26.csv")
    sys.hr.brmas = loadBRMAs( 4, T, brmapath )
    sys.loctax.ct.band_d = Dict([
        :S12000033 =>   1747.34     , # Aberdeen City        (+6.8%)
        :S12000034 =>   1686.04     , # Aberdeenshire        (+10.0%)
        :S12000041 =>   1598.63     , # Angus                (+9.38%)
        :S12000035 =>   1783.33     , # Argyll and Bute      (+9.7%)
        :S12000036 =>   1626.05     , # City of Edinburgh    (+4.0%)
        :S12000005 =>   1683.69     , # Clackmannanshire     (+5.6%)
        :S12000006 =>   1578.65     , # Dumfries and Galloway (+8.5%)
        :S12000042 =>   1729.76     , # Dundee City          (+7.75%)
        :S12000008 =>   1717.28     , # East Ayrshire        (+6.9%)
        :S12000045 =>   1751.67     , # East Dunbartonshire  (+9.5%)
        :S12000010 =>   1697.62     , # East Lothian         (+7.5%)
        :S12000011 =>   1620.15     , # East Renfrewshire    (+6.0%)
        :S12000014 =>   1715.46     , # Falkirk              (+8.77%)
        :S12000047 =>   1573.70     , # Fife                 (+5.0%)
        :S12000049 =>   1706.05     , # Glasgow City         (+5.9%)
        :S12000017 =>   1633.99     , # Highland             (+7.0%)
        :S12000018 =>   1673.85     , # Inverclyde           (+7.9%)
        :S12000019 =>   1816.16     , # Midlothian           (+9.0%)
        :S12000020 =>   1731.14     , # Moray                (+10.0%)
        :S12000013 =>   1505.50     , # Na h-Eileanan Siar   (+8.5%)
        :S12000021 =>   1685.34     , # North Ayrshire       (+8.5%)
        :S12000050 =>   1554.56     , # North Lanarkshire    (+7.0%)
        :S12000023 =>   1669.08     , # Orkney Islands       (+6.0%)
        :S12000048 =>   1673.78     , # Perth and Kinross    (+8.9%)
        :S12000038 =>   1690.56     , # Renfrewshire         (+7.5%)
        :S12000026 =>   1618.52     , # Scottish Borders     (+8.5%)
        :S12000027 =>   1488.02     , # Shetland Islands     (+7.3%)
        :S12000028 =>   1694.96     , # South Ayrshire       (+8.0%)
        :S12000029 =>   1468.48     , # South Lanarkshire    (+6.5%)
        :S12000030 =>   1752.59     , # Stirling             (+8.75%)
        :S12000039 =>   1681.53     , # West Dunbartonshire  (+7.8%)
        :S12000040 =>   1627.59     ])  # West Lothian       (+7.4%)

    # here so it's always on 
    sys.scottish_child_payment.abolished = false
    sys.scottish_child_payment.amounts = [28.20,0.0]
    sys.scottish_child_payment.maximum_ages = [15,99]
    #
    # Renames to Scottish benefits.
    sys.nmt_bens.carers.slot = CARERS_SUPPORT_PAYMENT
    sys.nmt_bens.dla.care_slot = CHILD_DISABILITY_PAYMENT_CARE
    sys.nmt_bens.dla.mob_slot = CHILD_DISABILITY_PAYMENT_MOBILITY
    sys.nmt_bens.pip.care_slot = ADP_DAILY_LIVING
    sys.nmt_bens.pip.mob_slot = ADP_MOBILITY
    sys.nmt_bens.attendance_allowance.slot = PENSION_AGE_DISABILITY
    
    # 
    # FIXME rest of Scottish Benefits somehow
    #
    sys.nmt_bens.winter_fuel.income_limit = 35_000.0 # 
    sys.nmt_bens.winter_fuel.amounts = [0.0, 203.40, 305.10]
    sys.nmt_bens.winter_fuel.upper_age = 80
  
    # qualifying_benefits


end


