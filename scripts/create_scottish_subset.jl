using CSV
using DataFrames
using ScottishTaxBenefitModel.Definitions

household_name = "model_households"
people_name = "model_people"

hh_dataset = CSV.File("$(MODEL_DATA_DIR)/$(household_name).tab", delim='\t' ) |> DataFrame
people_dataset = CSV.File("$(MODEL_DATA_DIR)/$(people_name).tab", delim='\t') |> DataFrame

dropmissing!(people_dataset,:data_year) # kill!!! non hbai kids

scottish_hhlds = hh_dataset[(hh_dataset.region .== 299999999),:]
scottish_people = semijoin(people_dataset, scottish_hhlds,on=[:hid,:data_year])

CSV.write("$(MODEL_DATA_DIR)model_households_scotland.tab", scottish_hhlds, delim = "\t")
CSV.write("$(MODEL_DATA_DIR)model_people_scotland.tab", scottish_people, delim = "\t")


using CSV
using DataFrames
using ScottishTaxBenefitModel.Definitions

household_name = "model_households"
people_name = "model_people"

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