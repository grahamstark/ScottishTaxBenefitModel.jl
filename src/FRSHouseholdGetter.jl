module FRSHouseholdGetter

import CSV
import DataFrames: DataFrame
using Definitions
import ModelHousehold: Household
using HouseholdFromFrame

export  initialise, get_household

## FIXME make a constant? As per julia performance guide?
MODEL_HOUSEHOLDS = Vector{Union{Missing,Household}}(missing,0)

"""
return (number of households available, num people loaded inc. kids, num hhls in dataset (should always = item[1]))
"""
function initialise(
        ;
        household_name :: AbstractString = "model_households",
        people_name :: AbstractString = "model_people",
        start_year = -1 ) :: Tuple

    global MODEL_HOUSEHOLDS
    hh_dataset =CSV.File("$MODEL_DATA_DIR)/$(household_name).tab",delim='\t' ) |> DataFrame
    # FIXME HORRIBLE HACK - correct (???) weights for num years in dataset
    # we need to generate our own weights here
    nyears = 2018 - start_year
    hh_dataset[!,:weight] ./= nyears
    people_dataset = CSV.File("$(MODEL_DATA_DIR)/$(people_name).tab",delim='\t' ) |> DataFrame
    npeople = size( people_dataset)[1]
    nhhlds = size( hh_dataset )[1]
    MODEL_HOUSEHOLDS = Vector{Union{Missing,Household}}(missing,nhhlds)
    for hseq in 1:nhhlds
        MODEL_HOUSEHOLDS[hseq] = load_hhld_from_frame( hseq, hh_dataset[hseq,:], people_dataset )
        uprate!( MODEL_HOUSEHOLDS[hseq] )
    end
    (size(MODEL_HOUSEHOLDS)[1],npeople,nhhlds)
end

function get_household( pos :: Integer ) :: Household
    global MODEL_HOUSEHOLDS
    MODEL_HOUSEHOLDS[pos]
end

end
