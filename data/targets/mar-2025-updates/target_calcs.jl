using DataFrames,CSV
#
# this is the 2025 projection
# age,m,f
#
const ages = [
        0	24_077	22_949
        1	24_187	23_077
        2	24_393	23_287
        3	25_501	23_880
        4	25_441	24_226
        5	26_093	24_821
        6	27_608	26_055
        7	27_314	25_955
        8	28_189	26_721
        9	29_720	27_859
        10	29_864	28_300
        11	30_191	28_572
        12	30_674	29_383
        13	31_708	29_851
        14	31_905	30_289
        15	31_706	30_756
        16	31_971	30_540
        17	32_252	31_088
        18	32_138	30_601
        19	32_941	32_408
        20	32_973	33_105
        21	34_855	35_079
        22	36_620	37_670
        23	35_618	37_084
        24	36_259	37_826
        25	37_996	39_337
        26	36_606	38_171
        27	35_152	36_449
        28	35_473	36_512
        29	34_431	35_849
        30	34_175	35_455
        31	35_003	36_836
        32	34_753	37_242
        33	35_843	38_352
        34	36_959	38_710
        35	35_555	37_714
        36	35_702	37_606
        37	36_492	38_396
        38	35_098	36_847
        39	35_249	36_971
        40	35_081	37_348
        41	34_249	36_167
        42	34_115	36_583
        43	34_104	36_472
        44	34_741	36_686
        45	33_906	35_483
        46	33_566	34_483
        47	30_063	32_443
        48	30_013	31_559
        49	31_572	33_439
        50	31_809	33_782
        51	32_786	34_303
        52	34_053	36_050
        53	35_391	38_450
        54	37_107	40_216
        55	37_140	39_850
        56	38_483	41_010
        57	38_850	41_711
        58	39_272	41_315
        59	38_530	41_390
        60	39_869	42_486
        61	39_208	42_359
        62	38_642	41_581
        63	37_507	39_778
        64	36_129	38_603
        65	35_339	37_550
        66	34_538	36_904
        67	33_448	36_101
        68	31_696	34_079
        69	30_467	33_018
        70	28_848	31_620
        71	27_819	30_443
        72	26_915	29_532
        73	25_269	27_994
        74	24_763	27_904
        75	24_090	27_356
        76	24_247	27_687
        77	24_076	27_858
        78	24_798	29_239
        79	18_000	21_364
        80	15_852	19_843
        81	15_388	19_367
        82	13_656	18_180
        83	11_717	16_075
        84	9_610	13_861
        85	9_136	13_474
        86	8_132	12_249
        87	7_163	10_963
        88	5_941	9_536
        89	5_002	8_429
        90	4_192	7_149
        91	3_266	5_884
        92	2_583	4_764
        93	2_091	3_678
        94	1_477	2_790
        95	1_011	2_063
        96	698	1_486
        97	420	1_020
        98	269	706
        99	167	467
        100	93	289
        101	51	179
        102	26	105
        103	16	60
        104	8	36
        110	5	33
]
# 
# % in communal, Scotland, from 2018-house-proj-source-data-alltabs.xls 
# NOTE THERE IS NO UPDATE TO THIS DATA FEB 2024
const non_hh_pct = [
15	0.004448	0.003125
19	0.113256	0.154400
24	0.081012	0.092038
29	0.030666	0.017293
34	0.019099	0.004821
39	0.015011	0.003423
44 	0.012003	0.003401
49 	0.009034	0.003194
54 	0.006794	0.003442
59 	0.006137	0.003788
64 	0.006959	0.004808
69  	0.008487	0.006123
74 	0.010430	0.009537
79 	0.020088	0.021472
84 	0.034565	0.049016
89 	0.064124	0.114468
999 	0.136843	0.256852 ]


aged = DataFrame(ages, [:age,:male,:female])

function findprop( age, sex )
    rows,cols=size(non_hh_pct)
    for r in 1:rows
        if non_hh_pct[r,1] >= age
            col = if sex == :male 
                    2 
                elseif sex == :female 
                    3
                else
                    1
                end
            return non_hh_pct[r,col]
        end
    end
end

rows,cols = size(aged)
aged.weighted_males = zeros(rows)
aged.weighted_females = zeros(rows)

for r in 1:rows
    age = aged[r,:age]
    pm = 1-findprop( age, :male )
    pf = 1-findprop( age, :female )
    aged[r,:weighted_males] = pm*aged[r,:male]
    aged[r,:weighted_females] = pf*aged[r,:female]
end

agelims = [
  4,
  9,
  15,
  19,
  24,
  29,
  34,
  39,
  44,
  49,
  54,
  59,
  64,
  69,
  74,
  79,
  84, # delete next 2 of these for 80+ only
  89,
9000]

function group( d :: DataFrame, ranges :: Vector, which :: Symbol )
    n = size(ranges)[1]
    println( ranges )
    out = zeros( n )
    for r in eachrow( d )
        for k in 1:n
            println( ranges[k])
            if ranges[k] >= r.age
                out[k] += r[which]
                break
            end
        end
    end
    out
end

out = DataFrame(
    age_range_top = agelims,
    male = group( aged, agelims, :male ),
    female = group( aged, agelims, :female ),
    hhld_males = group( aged, agelims, :weighted_males ),
    hhld_females = group( aged, agelims, :weighted_females ))

CSV.write( "popn_by_range_2025.csv", out )

const TARGETS_24 = [
    1347880.73,	#	1	M- Total in employment- aged 16+ July 2022 – see LFS\ headline indicators.xls m/f scottish tabs
    63487.44,	#	2	M- Total unemployed- aged 16+
    1352983.44,	#	3	F- Total in employment- aged 16+
    35890.28,	#	4	F- Total unemployed- aged 16+
    396292.1,	#	5	private rented+rent free
    292100.2,	#	6	housing association
    317656.5,	#	7	las etc rented
    125921.40,	#	8	M – 0 - 4
    147410.39,	#	9	5 - 9
    186088.58,	#	10	10 – 15
    103761.46,	#	11	16 - 19
    151956.50,	#	12	20 - 24
    177806.87,	#	13	25 - 29
    189613.07,	#	14	 30 - 34
    174449.43,	#	15	 35 - 39
    165566.56,	#	16	40 - 44
    156883.79,	#	17	 45 - 49
    181617.65,	#	18	 50 - 54
    191912.96,	#	19	 55 - 59
    176250.87,	#	20	 60 - 64
    148622.84,	#	21	 65 - 69
    130764.75,	#	22	 70 - 74
    99683.51,	#	23	 75 - 79
    102280.18,	#	24	80+
    119487.43,	#	25	F – 0 - 4
    139162.75,	#	26	5 - 9
    178360.88,	#	27	10 – 15
    94149.95,	#	28	16 - 19
    146720.30,	#	29	20 - 24
    175980.22,	#	30	25 - 29
    193729.51,	#	31	 30 - 34
    182677.55,	#	32	 35 - 39
    173862.68,	#	33	40 - 44
    165536.58,	#	34	 45 - 49
    198225.35,	#	35	 50 - 54
    206606.40,	#	36	 55 - 59
    189092.45,	#	37	 60 - 64
    161055.78,	#	38	 65 - 69
    144934.45,	#	39	 70 - 74
    117987.97,	#	40	 75 - 79
    149195.50,	#	41	80+
    472953.00,	#	42	 # 42 - 1 adult: male
    455762.00,	#	43	 # 43 - 1 adult: female
    804003.00,	#	44	 # 44 - 2 adults
    157469.00,	#	45	 # 45 - 1 adult 1+ child
    439658.00,	#	47	 # 47 - 2+ adults 1+ children
    208126.00,	#	48	 # 48 - 3+ adults
    80383.00,	#	49	CARERS
    123909.00,	#	50	AA
    428125.00,	#	51	PIP/DLA
    114078.76,	#	52	 # S12000034 - 52 Aberdeenshire  
    54620.52,	#	53	 # S12000041 - Angus  
    41607.77,	#	54	 # S12000035 - Argyll and Bute  
    246540.44,	#	55	 # S12000036 - City of Edinburgh  
    24138.19,	#	56	 # S12000005 - Clackmannanshire  
    69930.18,	#	57	 # S12000006 - Dumfries and Galloway  
    71266.65,	#	58	 # S12000042 - Dundee City  
    55757.16,	#	59	 # S12000008 - East Ayrshire  
    46916.83,	#	60	 # S12000045 - East Dunbartonshire  
    48217.59,	#	61	 # S12000010 - East Lothian  
    40304.71,	#	62	 # S12000011 - East Renfrewshire  
    74175.94,	#	63	 # S12000014 - Falkirk  
    171156.22,	#	64	 # S12000047 - Fife  
    300829.79,	#	65	 # S12000049 - Glasgow City  
    111066.78,	#	66	 # S12000017 - Highland  
    37340.41,	#	67	 # S12000018 - Inverclyde  
    41684.58,	#	68	 # S12000019 - Midlothian  
    43669.41,	#	69	 # S12000020 - Moray  
    12774.80,	#	70	 # S12000013 - Na h-Eileanan Siar  
    64256.52,	#	71	 # S12000021 - North Ayrshire  
    154606.93,	#	72	 # S12000050 - North Lanarkshire  
    10773.99,	#	73	 # S12000023 - Orkney Islands  
    70140.47,	#	74	 # S12000048 - Perth and KinroS  
    88474.37,	#	75	 # S12000038 - Renfrewshire  
    55464.62,	#	76	 # S12000026 - Scottish Borders  
    10565.88,	#	77	 # S12000027 - Shetland Islands  
    52978.43,	#	78	 # S12000028 - South Ayrshire  
    149931.06,	#	79	 # S12000029 - South Lanarkshire  
    40765.49,	#	80	 # S12000030 - Stirling  
    43222.73,	#	81	 # S12000039 - West Dunbartonshire  
    81415.06,	#	82	 # S12000040 - West Lothian  
    657107.48,	#	83	% all in employment who are - 2: professional occupations (SOC2010)
    425792.91,	#	84	% all in employment who are - 3: associate prof & tech occupations (SOC2010)
    271866.28,	#	85	% all in employment who are - 4: administrative and secretarial occupations (SOC2010)
    247450.33,	#	86	% all in employment who are - 5: skilled trades occupations (SOC2010)
    256792.08,	#	87	% all in employment who are - 6: caring, leisure and other service occupations (SOC2010)
    230889.95,	#	88	% all in employment who are - 7: sales and customer service occupations (SOC2010)
    144372.57,	#	89	% all in employment who are - 8: process, plant and machine operatives (SOC2010)
    272503.22 ]	#	90	% all in employment who are - 9: elementary occupations (SOC2010)
