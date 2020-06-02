using CSV
using DataFrames
using Definitions

household_name = "model_households"
people_name = "model_people"

hh_dataset = CSV.File("$(MODEL_DATA_DIR)/$(household_name).tab", delim='\t' ) |> DataFrame
people_dataset = CSV.File("$(MODEL_DATA_DIR)/$(people_name).tab", delim='\t') |> DataFrame

scottish_hhlds = hh_dataset[(hh_dataset.region .== 299999999),:]
scottish_people = join(people_dataset, scottish_hhlds,on=[:hid,:data_year],kind = :semi)

CSV.write("$(MODEL_DATA_DIR)model_households_scotland.tab", scottish_hhlds, delim = "\t")
CSV.write("$(MODEL_DATA_DIR)model_people_scotland.tab", scottish_people, delim = "\t")
