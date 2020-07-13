using DataFrames
using CSV
using StatsModels
using StatsBase
using ScottishTaxBenefitModel.Definitions

frshh = CSV.File( "$MODEL_DATA_DIR/model_households.tab" ) |> DataFrame
frspeople = CSV.File( "$MODEL_DATA_DIR/model_people.tab" ) |> DataFrame
