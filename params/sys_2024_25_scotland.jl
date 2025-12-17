"""
 SCOTLAND 2024/5

 Sources:
 IT: https://www.gov.scot/publications/scottish-income-tax-2024-25-factsheet/
 CT: https://www.gov.scot/publications/council-tax-datasets/
 BRMA: https://www.gov.scot/publications/local-housing-allowance-rates-2024-2025/
 Benefits: https://bprcdn.parliament.scot/published/2024/3/14/6f58227d-21aa-4016-91e6-f3d0bb29962d/SB%2024-15.pdf
"""
function load_sys_2024_25_scotland!( sys :: TaxBenefitSystem{T} ) where T
    sys.name = "Scottish System 2024/25"
    sys.it.non_savings_rates = T[
        19.0, # starter
        20.0, # basic
        21.0, # intermediate
        42.0, # higher
        45,   # advanced
        48.0] # top
    sys.it.non_savings_thresholds = T[
        2_306.0,
        13_991.0,
        31_092.0,
        62_430.0,
        125_140.0]
    sys.it.non_savings_basic_rate = 2 # above this counts as higher rate rate FIXME 3???
    # sys.nmt_bens.carers.scottish_supplement = 0.0 # FROM APRIL 2021
    sys.nmt_bens.carers.scottish_supplement = 231.40 # FROM APRIL 2021
  
    ## !!! FIXME the Welsh ones in this file are not updated 
    brmapath = joinpath( qualified_artifact( "augdata" ), "lha_rates_scotland_2024_25.csv")
    sys.hr.brmas = loadBRMAs( 4, T, brmapath )
    sys.loctax.ct.band_d = Dict(
        [:S12000033 => 1_489.55, # Aberdeen City
        :S12000034 => 1_393.42, # Aberdeenshire
        :S12000041 => 1_316.68, # Angus
        :S12000035 => 1_627.12, # Argyll and Bute
        :S12000036 => 1_447.69, # City of Edinburgh
        :S12000005 => 1_410.96, # Clackmannanshire
        :S12000006 => 1_334.85, # Dumfries and Galloway
        :S12000042 => 1_486.43, # Dundee City
        :S12000008 => 1_487.44, # East Ayrshire
        :S12000045 => 1_415.66, # East Dunbartonshire
        :S12000010 => 1_435.62, # East Lothian
        :S12000011 => 1_415.22, # East Renfrewshire
        :S12000014 => 1_363.82, # Falkirk
        :S12000047 => 1_385.18, # Fife
        :S12000049 => 1_499.00, # Glasgow City
        :S12000017 => 1_427.19, # Highland
        :S12000018 => 1_547.01, # Inverclyde
        :S12000019 => 1_514.73, # Midlothian
        :S12000020 => 1_430.69, # Moray
        :S12000013 => 1_290.75, # Na h-Eileanan Siar
        :S12000021 => 1_452.12, # North Ayrshire
        :S12000050 => 1_320.78, # North Lanarkshire
        :S12000023 => 1_369.21, # Orkney Islands
        :S12000048 => 1_403.69, # Perth and Kinross
        :S12000038 => 1_436.17, # Renfrewshire
        :S12000026 => 1_356.11, # Scottish Borders
        :S12000027 => 1_260.61, # Shetland Islands
        :S12000028 => 1_453.16, # South Ayrshire
        :S12000029 => 1_300.81, # South Lanarkshire
        :S12000030 => 1_481.50, # Stirling
        :S12000039 => 1_398.98, # West Dunbartonshire
        :S12000040 => 1_390.96]) # West Lothian

    # here so it's always on 
    sys.scottish_child_payment.abolished = false
    sys.scottish_child_payment.amount = 26.70
    sys.scottish_child_payment.maximum_age = 15
    #
    # FIXME rest of Scottish Benefits somehow
    #
    # Renames to Scottish benefits.
    sys.nmt_bens.carers.slot = CARERS_SUPPORT_PAYMENT
    sys.nmt_bens.dla.care_slot = CHILD_DISABILITY_PAYMENT_CARE
    sys.nmt_bens.dla.mob_slot = CHILD_DISABILITY_PAYMENT_MOBILITY
    sys.nmt_bens.pip.care_slot = ADP_DAILY_LIVING
    sys.nmt_bens.pip.mob_slot = ADP_MOBILITY
    sys.nmt_bens.attendance_allowance.slot = PENSION_AGE_DISABILITY

end


