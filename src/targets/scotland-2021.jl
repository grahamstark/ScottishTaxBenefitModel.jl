#
# This is our default set of targets for 2021/2. 
# DON'T USE WITHOUT REVERTING the data creation.
#
const DEFAULT_TARGETS_2021 = [
    # Employment totals from NOMIS
    # We drop 'inactive' because of collinearity with NRS population
    1.02361127107591*1_330_149,  #	1	M- Total in employment- aged 16+ - the constant here scales the NOMIS over 16 populations to the NRS totals
    1.02361127107591*68_308,	 #	2	M- Total unemployed- aged 16+
    1.01039881362443*1_304_812,  #	3	F- Total in employment- aged 16+
    1.01039881362443*50_481,     #	4	F- Total unemployed- aged 16+
    # Tenure - the constant scales SGov occupied households counts to NRS total household counts.
    # OOs dropped for colinearity with NRS household counts.
    1.00987684414087*370_845,   #	5	private rented+rent free 
    1.00987684414087*280_715,   #	6	housing association
    1.00987684414087*314_433,   #	7	las etc rented
    # NRS popn by age 2021/2
	135_959,	#	8	M – 0 - 4
	152_847,	#	9	5 - 9
	151_875,	#	10	10 - 14
	144_207,	#	11	15 - 19
	173_302,	#	12	20 - 24
	189_139,	#	13	25 - 29
	185_637,	#	14	 30 - 34
	174_079,	#	15	 35 - 39
	159_586,	#	16	40 - 44
	169_376,	#	17	 45 - 49
	189_355,	#	18	 50 - 54
	193_348,	#	19	 55 - 59
	170_701,	#	20	 60 - 64
	144_529,	#	21	 65 - 69
	135_910,	#	22	 70 - 74
	89_206,  #	23	 75 - 79
	106_156,	#	24	80+
	127_847,	#	25	F – 0 - 4
	145_056,	#	26	5 - 9
	146_206,	#	27	10 - 14
	137_913,	#	28	15 - 19
	168_453,	#	29	20 - 24
	188_065,	#	30	25 - 29
	188_432,	#	31	 30 - 34
	181_587,	#	32	 35 - 39
	164_780,	#	33	40 - 44
	180_548,	#	34	 45 - 49
	203_758,	#	35	 50 - 54
	205_996,	#	36	 55 - 59
	181_868,	#	37	 60 - 64
	155_904,	#	38	 65 - 69
	149_920,	#	39	 70 - 74
	109_004,	#	40	 75 - 79
	165_451,	#	41	80+
    # NRS households 
	468_147,	#	42	 # 42 - 1 adult: male
	453_675,	#	43	 # 43 - 1 adult: female
	795_465,	#	44	 # 44 - 2 adults
	90_276,	#	45	 # 45 - 1 adult 1 child
	67_324,	#	46	 # 46 - 1 adult 2+ children
	440_062,	#	47	 # 47 - 2+ adults 1+ children
	208_147,	#	48	 # 48 - 3+ adults
    # Disability benefit receipts from Stat-Explore
	82_031,	#	49	CARERS
	124_192,	#	50	AA
	432_744,	#	51	PIP/DLA
    # Household (not popn) from NRS by LA. Aberdeen city dropped for collinearity.
	113_217,	#	52	 # S12000034 - 52 Aberdeenshire  
	54_378,	#	53	 # S12000041 - Angus  
	41_635,	#	54	 # S12000035 - Argyll and Bute  
	243_954,	#	55	 # S12000036 - City of Edinburgh  
	24_039,	#	56	 # S12000005 - Clackmannanshire  
	69_824,	#	57	 # S12000006 - Dumfries and Galloway  
	71_077,	#	58	 # S12000042 - Dundee City  
	55_642,	#	59	 # S12000008 - East Ayrshire  
	46_627,	#	60	 # S12000045 - East Dunbartonshire  
	47_707,	#	61	 # S12000010 - East Lothian  
	39_978,	#	62	 # S12000011 - East Renfrewshire  
	73_621,	#	63	 # S12000014 - Falkirk  
	170_311,	#	64	 # S12000047 - Fife  
	299_004,	#	65	 # S12000049 - Glasgow City  
	110_436,	#	66	 # S12000017 - Highland  
	37_462,	#	67	 # S12000018 - Inverclyde  
	40_993,	#	68	 # S12000019 - Midlothian  
	43_406,	#	69	 # S12000020 - Moray  
	12_798,	#	70	 # S12000013 - Na h-Eileanan Siar  
	64_201,	#	71	 # S12000021 - North Ayrshire  
	153_918,	#	72	 # S12000050 - North Lanarkshire  
	10_701,	#	73	 # S12000023 - Orkney Islands  
	69_706,	#	74	 # S12000048 - Perth and KinroS  
	87_944,	#	75	 # S12000038 - Renfrewshire  
	55_090,	#	76	 # S12000026 - Scottish Borders  
	10_503,	#	77	 # S12000027 - Shetland Islands  
	52_804,	#	78	 # S12000028 - South Ayrshire  
	149_064,	#	79	 # S12000029 - South Lanarkshire  
	40_383,	#	80	 # S12000030 - Stirling  
	43_215,	#	81	 # S12000039 - West Dunbartonshire  
	80_562	#	82	 # S12000040 - West Lothian  
    ]


