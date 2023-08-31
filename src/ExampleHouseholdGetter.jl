module ExampleHouseholdGetter
#
# This module contains code to fetch some test households from CSV files.
# It differs from the main FRSHouseholdGetter in that it doesn't bother with weighting, and households
# to be accessed by names rather than indexes.
#
using DataFrames
using CSV

using ScottishTaxBenefitModel
using .Definitions
using .ModelHousehold: Household
using .ConsumptionData: find_consumption_for_hh!
using .HouseholdFromFrame: load_hhld_from_frame
using .RunSettings

export  initialise, get_household

EXAMPLE_HOUSEHOLDS = Dict{String,Household}()

KEYMAP = Vector{AbstractString}()

"""
FIXME FIXME FIXME
"""
function find_consumption_for_example!( hh, settings )
    sv_hid = hh.hid
    sv_data_year = hh.data_year
    hh.hid = 1
    hh.data_year = 2021
    println( "finding consumption for $sv_hid $sv_data_year")
    find_consumption_for_hh!( hh, settings, 1 )
    @assert ! isnothing( hh.factor_costs )
    @assert ! isnothing( hh.expenditure )
    hh.hid = sv_hid
    hh.data_year = sv_data_year
end

"""
return number of households available
"""
function initialise(
    settings       :: Settings
    ;
    # fixme move these to settings
    household_name :: AbstractString = "example_households",
    people_name    :: AbstractString = "example_people",
     ) :: Vector{AbstractString}

    global KEYMAP 
    global EXAMPLE_HOUSEHOLDS
    KEYMAP = Vector{AbstractString}()
    hh_dataset = CSV.File("$(MODEL_DATA_DIR)/$(household_name).tab", delim='\t' ) |> DataFrame
    people_dataset = CSV.File("$(MODEL_DATA_DIR)/$(people_name).tab", delim='\t' ) |> DataFrame
    npeople = size( people_dataset)[1]
    nhhlds = size( hh_dataset )[1]
    for hseq in 1:nhhlds
        hhf = hh_dataset[hseq,:]
        push!( KEYMAP, hhf.name )
        println( "loading $(hhf.name) $(hhf.council)")
        hh = load_hhld_from_frame( 
            hseq, hhf, people_dataset, ExampleSource, settings )
        if settings.indirect_method == matching
            find_consumption_for_example!( hh, settings )
        end
        EXAMPLE_HOUSEHOLDS[hhf.name] = hh
        println( EXAMPLE_HOUSEHOLDS[hhf.name].council )
    end
    return KEYMAP
end

function example_names()
    return KEYMAP
end

function get_household( pos :: Integer ) :: Household
    key = KEYMAP[pos]
    return EXAMPLE_HOUSEHOLDS[key]
end

function get_household( name :: AbstractString ) :: Household
    # global EXAMPLE_HOUSEHOLDS
    return EXAMPLE_HOUSEHOLDS[name]
end


end
