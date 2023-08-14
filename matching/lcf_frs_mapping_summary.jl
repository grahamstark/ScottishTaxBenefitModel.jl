# 
using StatsBase

include( "lcf_frs_matching.jl")

#=
Length:         16364
Missing Count:  0
Mean:           940.095382
Minimum:        0.000000
1st Quartile:   438.874295
Median:         743.636606
3rd Quartile:   1256.389693
Maximum:        3074.510511


julia> summarystats(lcfhh.income)
Summary Stats:
Length:         16311
Missing Count:  0
Mean:           936.906094
Minimum:        0.000000
1st Quartile:   442.083857
Median:         777.742216
3rd Quartile:   1262.485743
Maximum:        3074.510511

=#

size(unique( alldf, [:lcf_case_1,:lcf_datayear_1]))

#=
(8401, 83) - so 1/2 units unused?? 
=#

sort(combine(adfg, :lcf_case_1=>length ),:lcf_case_1_length)

#=
1 record used 39 times! (1776,2018)

 Row │ lcf_case_1  lcf_datayear_1  lcf_case_1_length 
─────┼───────────────────────────────────────────────
8389 │        588            2020                 15
8390 │       1597            2020                 15
8391 │       1908            2020                 15
8392 │       2146            2020                 15
8393 │       2892            2019                 15
8394 │       2423            2020                 16
8395 │       2660            2020                 16
8396 │        577            2020                 19
8397 │       1085            2020                 22
8398 │       2088            2020                 22
8399 │       2915            2020                 22
8400 │       3294            2018                 25
8401 │       1776            2018                 39

=#

alldf[alldf.lcf_case_1.==1776,:]

#=

alldf[alldf.lcf_case_1.==1776,:]
39×83 DataFrame
 Row │ frs_sernum  frs_datayear  frs_income  lcf_case_1  lcf_datayear_1  lcf_score_1  lcf_income_1  lcf_case_2  lcf_datayear_2   ⋯
     │ Int64       Int64         Float64     Int64       Int64           Float64      Float64       Int64       Int64            ⋯
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │         25          2021     2560.47        1776            2018      20.4969       2559.72        1136            2018   ⋯
   2 │        285          2021     2560.47        1776            2018      19.9969       2559.72        2834            2019
   3 │        754          2021     2560.47        1776            2018      21.4969       2559.72        3488            2019
   4 │       1059          2021     2560.47        1776            2018      19.9969       2559.72        2045            2019
   5 │       2390          2021     2560.47        1776            2018      20.9969       2559.72        3488            2019   ⋯
   6 │       3255          2021     2560.47        1776            2018      20.4969       2559.72        4721            2020
  ⋮  │     ⋮            ⋮            ⋮           ⋮             ⋮              ⋮            ⋮            ⋮             ⋮          ⋱
  35 │      13250          2021     2526.85        1776            2018      19.3642       2559.72        4032            2018
  36 │      13363          2021     2560.47        1776            2018      20.5969       2559.72        3488            2019
  37 │      14674          2021     2560.47        1776            2018      21.4969       2559.72        3488            2019   ⋯
  38 │      15302          2021     2543.84        1776            2018      21.9344       2559.72        3488            2019
  39 │      16018          2021     2560.47        1776            2018      21.4969       2559.72        4721            2020

  1 │      true               false        false           false          false                 1             2           4        5  112000004         6       13
frs tenure[5, 2, 9999]
frs region[4, 2, 9999]
frs age hrp[4, 1, 9998]
frs composition[8, 2, 9999]
1×12 DataFrame
 Row │ any_wages  any_pension_income  any_selfemp  hrp_unemployed  hrp_non_white  has_female_adult  num_children  num_people  a121   gorx   a065p  a062  
     │ Bool       Bool                Bool         Bool            Int64          Int64             Int64         Int64       Int64  Int64  Int64  Int64 
─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │      true               false        false           false              0                 1             2           4      5      4      9     11
lcf tenure[5, 2, 9998]
lcf region[4, 2, 9998]
lcf age_hrp[7, 2, 9998]
lcf composition[8, 2, 9998]

Basically, pretty much any FRS household with 2 children and a high income gets mapped to lcf 1776 2018. I think this is because of top coding LCF income.

What to do??

=#

### unweighted summary stats 

summarystats( lcfhh.p550p ) # total expenditure

#=
Summary Stats:
Length:         16311
Missing Count:  0
Mean:           526.255429
Minimum:        -157.820000
1st Quartile:   272.424818
Median:         433.435458
3rd Quartile:   665.670927
Maximum:        8109.473568
=#

summarystats(sellcfhh.p550p) 

#=

## summary over just selected hhlds

summarystats(sellcfhh.p550p) 
Summary Stats:
Length:         8401
Missing Count:  0
Mean:           507.238792
Minimum:        -157.820000
1st Quartile:   268.473278
Median:         425.234438
3rd Quartile:   644.682900
Maximum:        8109.473568

summarystats(lcfhh.p602) # total alc & tobacco

Summary Stats:
Length:         16311
Missing Count:  0
Mean:           13.783688
Minimum:        0.000000
1st Quartile:   0.000000
Median:         4.750000
3rd Quartile:   18.197500
Maximum:        414.540000


summarystats(sellcfhh.p602)
Summary Stats:
Length:         8401
Missing Count:  0
Mean:           13.724181
Minimum:        0.000000
1st Quartile:   0.000000
Median:         4.880000
3rd Quartile:   18.485000
Maximum:        350.070000

summarystats(lcfhh.p537t) # ONS fuel, light and power
Summary Stats:
Length:         16311
Missing Count:  0
Mean:           24.453977
Minimum:        -50.900000
1st Quartile:   15.090000
Median:         21.080000
3rd Quartile:   30.000000
Maximum:        557.680000


julia> summarystats(sellcfhh.p537t) # ONS fuel, light and power
Summary Stats:
Length:         8401
Missing Count:  0
Mean:           23.828880
Minimum:        -36.360000
1st Quartile:   15.000000
Median:         20.770000
3rd Quartile:   28.850000
Maximum:        395.920000

... all seems OK, that way. 

=#

