using DataFrames,CSV

#
# this is the 2024 projection from cppvopendata2020.xls, 1 year intervals
# age,m,f
#
const ages = [
           0	23464	22357
           1	23468	22353
           2	23726	22572
           3	24342	23136
           4	25571	24209
           5	26904	25246
           6	27743	26207
           7	28663	26743
           8	29833	27797
           9	29999	28467
          10	30245	28559
          11	30771	29257
          12	31698	29815
          13	32478	30902
          14	30766	29689
          15	31683	30446
          16	31532	30325
          17	30470	29030
          18	30010	28730
          19	30887	29383
          20	31489	30438
          21	31205	30826
          22	31627	31345
          23	33749	33726
          24	34827	33610
          25	35647	34118
          26	36123	34611
          27	37199	35643
          28	36911	35168
          29	36606	35308
          30	37395	36647
          31	37771	38210
          32	39923	40331
          33	40318	40053
          34	38742	38729
          35	38289	38636
          36	38090	38716
          37	36551	37711
          38	36532	37026
          39	35710	37131
          40	34591	35969
          41	34676	36439
          42	34957	37029
          43	34952	36388
          44	34254	35570
          45	33183	33915
          46	30195	32036
          47	30076	30875
          48	31229	32845
          49	30952	33306
          50	31817	33494
          51	33560	35567
          52	35102	38025
          53	36096	39700
          54	35642	39018
          55	37079	40427
          56	37682	41094
          57	38259	40813
          58	37619	40741
          59	38893	41788
          60	38011	41509
          61	37963	41042
          62	37123	39622
          63	35849	38566
          64	34527	37012
          65	33707	36750
          66	32534	35474
          67	31553	34088
          68	30232	32843
          69	28374	31268
          70	27790	30384
          71	26726	29502
          72	25347	28182
          73	24984	28085
          74	24723	27734
          75	24605	27948
          76	24703	28272
          77	25669	30119
          78	18657	22022
          79	16666	20597
          80	16367	20241
          81	14559	19027
          82	12383	16996
          83	10660	15146
          84	10242	14640
          85	9257	13493
          86	8252	12303
          87	6868	10941
          88	5847	9701
          89	4971	8341
          90	3917	7044
          91	3177	5730
          92	2555	4928
          93	1951	3900
          94	1434	3011
          95	1019	2256
          96	680	1650
          97	454	1208
          98	306	837
          99	192	540
         100	110	351
         101	59	215
         102	33	130
         103	18	76
         104	9	43
        110	4	27
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

CSV.write( "popn_by_range_2024.csv", out )

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
