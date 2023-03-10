#
#
# see data/targets/target_set.ods for derivation of these targets.
#
const DEFAULT_TARGETS_2020 = [
    # 1.01337880471403 is nrs 16+ popn estimate/nomis count
    # this scales to employment and popn numbers are consistent
    # we drop 'inactive' because of collinearity
    1_340_609.0*1.01337880471403, # 1 - M- Total in employment- aged 16+
    60_635*1.01337880471403, # 2 - M- Total unemployed- aged 16+
    # 745_379, # 3 - M- Total economically inactive- aged 16+
    1_301_248*1.01337880471403, # 3 - F- Total in employment- aged 16+
    59_302*1.01337880471403, # 4 - F- Total unemployed- aged 16+
    # 974_767, # 6 - F- Total economically inactive- aged 16+
    # 1_540_890, # 7 - owner occupied
    # 0.987518476103907 HERE is ratio of total hhls
    # from tenure data and nrs hhld type counts
    370_502*0.987518476103907, # 5 - private rented+rent free
    282_482*0.987518476103907, # 6 - housing association
    314_433*0.987518476103907, # 7 - las etc rented
    139_982, # 8 - M- 0 - 4
    153_297, # 9 - M- 5 - 9
    150_487, # 10 - M- 10 – 14
    144_172, # 11 - M- 15 - 19
    176_066, # 12 - M- 20 - 24
    191_145, # 13 - M- 25 - 29
    182_635, # 14 -  M- 30 - 34
    172_624, # 15 -  M- 35 - 39
    156_790, # 16 - M- 40 - 44
    174_812, # 17 -  M- 45 - 49
    193_940, # 18 -  M- 50 - 54
    190_775, # 19 -  M- 55 - 59
    166_852, # 20 -  M- 60 - 64
    144_460, # 21 -  M- 65 - 69
    132_339, # 22 -  M- 70 - 74
    87_886, # 23 -  M- 75 - 79
    104_741, # 24 - M- 80’+
    131_733, # 25 - F- 0 - 4
    146_019, # 26 - F- 5 - 9
    144_187, # 27 - F- 10 - 14
    137_786, # 28 - F- 15 - 19
    171_390, # 29 - F- 20 - 24
    191_110, # 30 - F- 25 - 29
    186_828, # 31 -  F- 30 - 34
    179_898, # 32 -  F- 35 - 39
    162_642, # 33 - F- 40 - 44
    186_646, # 34 -  F- 45 - 49
    207_150, # 35 -  F- 50 - 54
    202_348, # 36 -  F- 55 - 59
    177_841, # 37 -  F- 60 - 64
    154_984, # 38 -  F- 65 - 69
    146_517, # 39 -  F- 70 - 74
    108_065, # 40 -  F- 75 - 79
    165_153, # 41 -  F- 80+
    439_000, # 42 - 1 adult: male
    467_000, # 43 - 1 adult: female
    797_000, # 44 - 2 adults
    70_000, # 45 - 1 adult 1 child
    66_000, # 46 - 1 adult 2+ children
    448_000, # 47 - 2+ adults 1+ children
    190_000, # 48 - 3+ adults
    77_842, # 49 - CARER’S ALLOWANCE
    127_307, # 50 - AA
    431_461, # 51 pip/dla
    # council areas
    # FIXME note these sum to 0.992538132778121 of the household type totals above: Check Again
    # 108381, # S12000033 - Aberdeen City  # removed for collinearity 
    112114, # S12000034 - 52 Aberdeenshire  
    54221, # S12000041 - Angus  
    41789, # S12000035 - Argyll and Bute  
    238269, # S12000036 - City of Edinburgh  
    23890, # S12000005 - Clackmannanshire  
    69699, # S12000006 - Dumfries and Galloway  
    70685, # S12000042 - Dundee City  
    55387, # S12000008 - East Ayrshire  
    46228, # S12000045 - East Dunbartonshire  
    46771, # S12000010 - East Lothian  
    39345, # S12000011 - East Renfrewshire  
    72672, # S12000014 - Falkirk  
    169239, # S12000047 - Fife  
    294622, # S12000049 - Glasgow City  
    109514, # S12000017 - Highland  
    37614, # S12000018 - Inverclyde  
    39733, # S12000019 - Midlothian  
    42932, # S12000020 - Moray  
    12833, # S12000013 - Na h-Eileanan Siar  
    64140, # S12000021 - North Ayrshire  
    152443, # S12000050 - North Lanarkshire  
    10589, # S12000023 - Orkney Islands  
    69003, # S12000048 - Perth and KinroS  
    86683, # S12000038 - Renfrewshire  
    54715, # S12000026 - Scottish Borders  
    10439, # S12000027 - Shetland Islands  
    52588, # S12000028 - South Ayrshire  
    147434, # S12000029 - South Lanarkshire  
    39654, # S12000030 - Stirling  
    43030, # S12000039 - West Dunbartonshire  
    78966 ] # S12000040 - West Lothian 
