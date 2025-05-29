"""
 SCOTLAND 2025/6

 Sources:
 IT: https://www.gov.scot/publications/scottish-income-tax-2024-25-factsheet/
 CT: https://www.gov.scot/publications/council-tax-datasets/
 BRMA: https://www.gov.scot/publications/local-housing-allowance-rates-2024-2025/
 Benefits: https://bprcdn.parliament.scot/published/2024/3/14/6f58227d-21aa-4016-91e6-f3d0bb29962d/SB%2024-15.pdf
"""
function load_sys_2025_26_scotland!( sys :: TaxBenefitSystem{T} ) where T
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
        112_570.0]
    sys.it.non_savings_basic_rate = 2 # above this counts as higher rate rate FIXME 3???
    # sys.nmt_bens.carers.scottish_supplement = 0.0 # FROM APRIL 2021
    sys.nmt_bens.carers.scottish_supplement = 231.40 # FROM APRIL 2021
  
    ## !!! FIXME the Welsh ones in this file are not updated 
    brmapath = joinpath( get_artifact_str( "augdata" ), "lha_rates_scotland_2024_25.csv")
    sys.hr.brmas = loadBRMAs( 4, T, brmapath )
    sys.loctax.ct.band_d = Dict([
        :S12000033 => 	1636.27		, # Aberdeen City
        :S12000034 => 	1532.76		, # Aberdeenshire
        :S12000041 => 	1461.52		, # Angus
        :S12000035 => 	1625.64		, # Argyll and Bute
        :S12000036 => 	1563.51		, # City of Edinburgh
        :S12000005 => 	1594.38		, # Clackmannanshire
        :S12000006 => 	1454.98		, # Dumfries and Galloway
        :S12000042 => 	1605.34		, # Dundee City
        :S12000008 => 	1606.44		, # East Ayrshire
        :S12000045 => 	1599.70		, # East Dunbartonshire
        :S12000010 => 	1579.18		, # East Lothian
        :S12000011 => 	1528.44		, # East Renfrewshire
        :S12000014 => 	1576.77		, # Falkirk
        :S12000047 => 	1498.76		, # Fife
        :S12000049 => 	1611.00		, # Glasgow City
        :S12000017 => 	1527.09		, # Highland
        :S12000018 => 	1551.30		, # Inverclyde
        :S12000019 => 	1666.20		, # Midlothian
        :S12000020 => 	1573.76		, # Moray
        :S12000013 => 	1387.56		, # Na h-Eileanan Siar
        :S12000021 => 	1553.77		, # North Ayrshire
        :S12000050 => 	1452.86		, # North Lanarkshire
        :S12000023 => 	1574.60		, # Orkney Islands
        :S12000048 => 	1537.04		, # Perth and Kinross
        :S12000038 => 	1572.61		, # Renfrewshire
        :S12000026 => 	1491.72		, # Scottish Borders
        :S12000027 => 	1386.67		, # Shetland Islands
        :S12000028 => 	1569.41		, # South Ayrshire
        :S12000029 => 	1378.85		, # South Lanarkshire
        :S12000030 => 	1611.78		, # Stirling
        :S12000039 => 	1559.86		, # West Dunbartonshire
        :S12000040 	=> 1515.45	])	# West Lothian )

    # here so it's always on 
    sys.scottish_child_payment.abolished = false
    sys.scottish_child_payment.amount = 26.70
    sys.scottish_child_payment.maximum_age = 15
    #
    # FIXME rest of Scottish Benefits somehow
    #

end


