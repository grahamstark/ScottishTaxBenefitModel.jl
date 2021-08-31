module ExampleHouseholdGetter
#
# This module contains code to fetch some test households from CSV files.
# It differs from the main FRSHouseholdGetter in that it doesn't bother with weighting, and households
# to be accessed by names rather than indexes.
#
using DataFrames
using CSV

import ScottishTaxBenefitModel: ModelHousehold, Definitions, HouseholdFromFrame
using .Definitions
import .ModelHousehold: Household
import .HouseholdFromFrame: load_hhld_from_frame

export  initialise, get_household

EXAMPLE_HOUSEHOLDS = Dict{String,Household}()

KEYMAP = Vector{AbstractString}()


"""
return number of households available
"""
function initialise(
    ;
    household_name :: AbstractString = "example_households",
    people_name :: AbstractString = "example_people" ) :: Vector{AbstractString}

    global KEYMAP
    global EXAMPLE_HOUSEHOLDS

    hh_dataset = CSV.File("$(MODEL_DATA_DIR)/$(household_name).tab", delim='\t' ) |> DataFrame
    people_dataset = CSV.File("$(MODEL_DATA_DIR)/$(people_name).tab", delim='\t' ) |> DataFrame
    npeople = size( people_dataset)[1]
    nhhlds = size( hh_dataset )[1]
    for hseq in 1:nhhlds
        hhf = hh_dataset[hseq,:]
        push!( KEYMAP, hhf.name )
        println( "loading $(hhf.name)")
        EXAMPLE_HOUSEHOLDS[hhf.name] = load_hhld_from_frame( hseq, hhf, people_dataset, ExampleSource )
    end
    return KEYMAP
end

function example_names()
    global KEYMAP
    return KEYMAP
end

function get_household( pos :: Integer ) :: Household
    global EXAMPLE_HOUSEHOLDS
    global KEYMAP
    key = KEYMAP[pos]
    return EXAMPLE_HOUSEHOLDS[key]
end

function get_household( name :: AbstractString ) :: Household
    global EXAMPLE_HOUSEHOLDS
    return EXAMPLE_HOUSEHOLDS[name]
end


end
