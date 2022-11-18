using DataFrames,CSV

#
# this is the 2022 projection from pop-proj-2020-scot-nat-figs.xlsx, 1 year intervals
# age,m,f
#
const ages = [
0  23338  22237
1   23950  22817
2  25204  23911
3  26567  24962
4  27425  25935
5  28359  26481
6  29549  27532
7  29718  28215
8  29957  28332
9  30486  29039
10  31420  29598
11  32204  30687
12  30503  29471
13  31419  30223
14  31242  30111
15  30132  28830
16  29490  28332
17  29550  27794
18  29149  27386
19  28825  27829
20  29783  29313
21  32203  32275
22  33454  32469
23  34556  33348
24  35356  34188
25  36637  35338
26  36428  34813
27  36144  34909
28  36923  36230
29  37300  37787
30  39467  39918
31  39877  39654
32  38316  38348
33  37893  38301
34  37752  38447
35  36280  37496
36  36309  36824
37  35503  36921
38  34428  35780
39  34588  36284
40  34927  36880
41  34937  36246
42  34248  35470
43  33215  33861
44  30251  31999
45  30157  30830
46  31346  32817
47  31095  33304
48  31981  33509
49  33735  35607
50  35294  38112
51  36318  39824
52  35885  39143
53  37363  40570
54  38000  41261
55  38613  41019
56  38013  40997
57  39374  42101
58  38543  41859
59  38555  41416
60  37767  40010
61  36554  39014
62  35283  37535
63  34506  37345
64  33376  36102
65  32466  34758
66  31205  33583
67  29395  32062
68  28908  31233
69  27921  30412
70  26601  29147
71  26358  29153
72  26250  28915
73  26309  29299
74  26625  29816
75  27899  31976
76  20471  23548
77  18473  22187
78  18352  21988
79  16532  20878
80  14267  18877
81  12484  17050
82  12218  16729
83  11261  15686
84  10266  14594
85  8765  13283
86  7669  12091
87  6710  10703
88  5461  9339
89  4596  7867
90  3845  7026
91  3061  5797
92  2354  4682
93  1758  3676
94  1240  2833
95  881  2200
96  633  1630
97  428  1131
98  265  797
99  158  533
100  96  354
101  57  229
102  34  142
103  13  51
104  6  27
105  4  31
110 0  0]

#
# % in communal, Scotland, from 2018-house-proj-source-data-alltabs.xls
#  
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

ages,cols = size(aged)
aged.weighted_males = zeros(ages)
aged.weighted_females = zeros(ages)

for r in 1:ages
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

CSV.write( "popn_by_range_2022.csv", out )

const TARGETS_22 = [
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
