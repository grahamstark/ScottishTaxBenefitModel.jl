# matching in SHS

## REMEMBER

run `scripts/create_scottish_subset.jl` first!. With MATCH constant off.

## NOTE Health boards in 2019

code changes from `hlthbd2014` to `hlthbd2019`. This is because Glasgow and Lanarkshire boundaries have changed, See [here](https://www.data.gov.uk/dataset/72bee810-7959-4e0e-a0b1-5e8eb96f2e3d/health-boards-april-2019-names-and-codes-in-scotland).
Codes go from 
    
    ??
    

to 
    S08000031
    S08000032

For now I've not assigned `shs_nhs_board_xx` in the merged data file - needs some thought. Proc `add_in_las_to_recip!` in `matching_funcs.jl`.

## Council Characters

`council` 4 missing 1 character
Value = K	Label = East Lothian
	Value = S	Label = Midlothian
	Value = E	Label = Scottish Borders
	Value = F	Label = Clackmannanshire
	Value = G	Label = Dumfries and Galloway
	Value = 1	Label = South Ayrshire
	Value = J	Label = East Dumbartonshire
	Value = L	Label = East Renfrewshire
	Value = Z	Label = Shetland
	Value = R	Label = Inverclyde
	Value = W	Label = Orkney
	Value = C	Label = Angus
	Value = Y	Label = Renfrewshire
	Value = V	Label = North Lanarkshire
	Value = X	Label = Perth and Kinross
	Value = B	Label = Aberdeenshire
	Value = 6	Label = Eilean Siar
	Value = Q	Label = Highland
	Value = O	Label = Fife
	Value = T	Label = Moray
	Value = 4	Label = West Dumbartonshire
	Value = 3	Label = Stirling
	Value = A	Label = Aberdeen City
	Value = U	Label = North Ayrshire
	Value = N	Label = Falkirk
	Value = H	Label = Dundee City
	Value = P	Label = Glasgow City
	Value = I	Label = East Ayrshire
	Value = 2	Label = South Lanarkshire
	Value = 5	Label = West Lothian
	Value = M	Label = Edinburgh City
	Value = D	Label = Argyll and Bute
	
`hlth14` health board
Value = S08000016	Label = Borders
	Value = S08000015	Label = Ayrshire & Arran
	Value = S08000018	Label = Fife
	Value = S08000024	Label = Lothian
	Value = S08000017	Label = Dumfries & Galloway
	Value = S08000023	Label = Lanarkshire
	Value = S08000022	Label = Highland
	Value = S08000021	Label = Greater Glasgow & Clyde
	Value = S08000026	Label = Shetland
	Value = S08000027	Label = Tayside
	Value = S08000028	Label = Western Isles
	Value = S08000019	Label = Forth Valley
	Value = S08000025	Label = Orkney

`area` broad la area

Value = 1.0	Label = Edinburgh
	Value = 2.0	Label = Glasgow
	Value = 3.0	Label = Fife
	Value = 4.0	Label = North Lanarkshire
	Value = 5.0	Label = South Lanarkshire
	Value = 6.0	Label = Highlands and Islands
	Value = 7.0	Label = Grampian
	Value = 8.0	Label = Tayside
	Value = 9.0	Label = Central
	Value = 10.0	Label = Dunbartonshire
	Value = 11.0	Label = Renfrewshire and Inverclyde
	Value = 12.0	Label = Ayrshire
	Value = 13.0	Label = Lothian
	Value = 14.0	Label = Southern Scotland
	
`rtparea` 



Corrections.

See tables 2.1 in SHS methodology papers

massive oversample of small las - min 250 (263??). 

So: probability choices amongst matches, based in LA sample frequencies.

## FINAL


# initial unmatched - 35
hh_dataset = CSV.File("$(MODEL_DATA_DIR)/$(household_name).tab", delim='\t' ) |> DataFrame
people_dataset = CSV.File("$(MODEL_DATA_DIR)/$(people_name).tab", delim='\t') |> DataFrame
 unmatched[!,critmatche1]
35×8 DataFrame
 Row │ sernum  datayear  shelter_1  singlepar_1  numadults_2  numkids_2  empstathigh_1  agehigh_1 
     │ Int64   Int64     Int64      Int64        Int64        Int64      Int64          Int64     
─────┼────────────────────────────────────────────────────────────────────────────────────────────
   1 │    718        15          1            0            1          0              5         80
   2 │    950        15          0            1            1          1              8         18
   3 │   1100        15          0            0            2          1              1         35
   4 │   4159        15          0            0            2          0              4         16
   5 │   4529        15          1            0            1          0              5         80
   6 │   4927        15          1            0            2          0              5         76
   7 │   6858        15          0            0            2          1              7         19
   8 │   6944        15          1            0            2          0              5         72
   9 │   7554        15          0            1            1          1             10         18
  10 │   7941        15          1            0            1          0              8         58
  11 │  11846        15          1            0            2          0              5         80
  12 │  15458        15          0            1            1          2              7         19
  13 │  18920        15          1            0            1          0              5         80
  14 │   1347        16          0            0            2          1              1         47
  15 │   3664        16          0            0            2          1              1         26
  16 │   5529        16          1            0            1          0              2         68
  17 │   6030        16          1            0            2          0              5         80
  18 │   6204        16          1            0            1          0              5         78
  19 │   8008        16          0            0            2          1              3         44
  20 │  10911        16          1            0            1          0              5         70
  21 │  14106        16          0            0            2          1              1         37
  22 │  16510        16          0            0            3          1              1         19
  23 │   1079        17          1            0            1          0              2         65
  24 │   1445        17          1            0            1          0              2         56
  25 │   3076        17          1            0            1          0              3         70
  26 │  11609        17          1            0            1          0              5         58
  27 │  14225        17          0            1            1          1              2         28
  28 │  17127        17          1            0            1          0              5         80
  29 │  18852        17          1            1            1          1              7         24
  30 │   2927        18          1            0            2          0              1         65
  31 │   4385        18          1            0            2          0              3         62
  32 │   4861        18          0            0            3          2              1         19
  33 │   5234        18          0            0            3          0              6         18
  34 │   5710        18          1            0            2          0              5         63
  35 │  17153        18          1            0            1          0              2         68

21 are sheltered

.. leaving ...

14×638 DataFrame
 Row │ datayear  sernum  shs_uniqidnew_1  shs_datayear_1  shs_quality_1  shs_uniqidnew_2  shs_datayear_2  shs_quality_2  shs_uniqidnew_3  shs_datayear_3  shs_quality_3  shs_uniqidnew_ ⋯
     │ Int64     Int64   String           Int64           Int64          String           Int64           Int64          String           Int64           Int64          String         ⋯
─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │       15     950                                0              0                                0              0                                0              0                 ⋯
   2 │       15    1100                                0              0                                0              0                                0              0
   3 │       15    4159                                0              0                                0              0                                0              0
   4 │       15    6858                                0              0                                0              0                                0              0
   5 │       15    7554                                0              0                                0              0                                0              0                 ⋯
   6 │       15   15458                                0              0                                0              0                                0              0
   7 │       16    1347                                0              0                                0              0                                0              0
   8 │       16    3664                                0              0                                0              0                                0              0
   9 │       16    8008                                0              0                                0              0                                0              0                 ⋯
  10 │       16   14106                                0              0                                0              0                                0              0
  11 │       16   16510                                0              0                                0              0                                0              0
  12 │       17   14225                                0              0                                0              0                                0              0
  13 │       18    4861                                0              0                                0              0                                0              0                 ⋯
  14 │       18    5234                                0              0                                0              0                                0              0

  .. leaving none ..
  
# unweighted  

| S12000033 | Aberdeen City | 104.11239193083574 | 104360.73171614773
| S12000034 | Aberdeenshire | 107.49185043144774 | 138018.19713975381
| S12000041 | Angus | 72.29466666666667 | 49243.80847212165
| S12000035 | Argyll and Bute | 55.05797101449275 | 37497.57892831282
| S12000036 | City of Edinburgh | 101.95507060333762 | 204429.57186821144
| S12000005 | Clackmannanshire | 31.22875816993464 | 23718.3481173063
| S12000006 | Dumfries and Galloway | 89.9341935483871 | 67314.93084721216
| S12000042 | Dundee City | 88.24594257178526 | 69347.93211440985
| S12000008 | East Ayrshire | 74.44489247311827 | 67089.04181752354
| S12000045 | East Dunbartonshire | 57.00123304562269 | 52406.254887762494
| S12000010 | East Lothian | 55.54750593824228 | 44951.91690803766
| S12000011 | East Renfrewshire | 50.5719794344473 | 40885.91437364229
| S12000014 | Falkirk | 93.16923076923077 | 76802.27009413468
| S12000047 | Fife | 102.32103990326482 | 183873.67016654598
| S12000049 | Glasgow City | 105.4858575008951 | 239668.26049963795
| S12000017 | Highland | 109.62362362362363 | 119043.51864590877
| S12000018 | Inverclyde | 48.47164948453608 | 39304.69116582187
| S12000019 | Midlothian | 47.30119047619048 | 39530.580195510505
| S12000020 | Moray | 57.704301075268816 | 44500.13884866039
| S12000013 | Na h-Eileanan Siar | 14.402918069584736 | 15360.454018826938
| S12000021 | North Ayrshire | 87.02849389416554 | 66185.48569876901
| S12000050 | North Lanarkshire | 102.51714862138535 | 146827.86929761042
| S12000023 | Orkney Islands | 13.896325459317586 | 11520.340514120204
| S12000048 | Perth and Kinross | 89.84765625 | 73865.71270818249
| S12000038 | Renfrewshire | 108.21847690387017 | 85837.83128167994
| S12000026 | Scottish Borders | 73.83940620782727 | 60764.14898624186
| S12000027 | Shetland Islands | 13.163934426229508 | 12423.896632874728
| S12000028 | South Ayrshire | 67.76804123711341 | 55116.92324402607
| S12000029 | South Lanarkshire | 109.4536005939124 | 163769.5465242578
| S12000030 | Stirling | 48.895191122071516 | 46759.02914554671
| S12000039 | West Dunbartonshire | 53.38709677419355 | 41337.692433019554
| S12000040 | West Lothian | 93.67259786476869 | 73865.71270818249
