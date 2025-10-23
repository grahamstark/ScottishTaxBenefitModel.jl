module ExampleHouseholdGetter
#
# This module contains code to fetch some test households from CSV files.
# It differs from the main FRSHouseholdGetter in that it doesn't bother with weighting, and households
# to be accessed by names rather than indexes.
#
using DataFrames
using CSV
using ArgCheck
using LazyArtifacts

using ScottishTaxBenefitModel
using .Definitions
using .ModelHousehold: Household, infer_house_price!
using .ConsumptionData: find_consumption_for_hh!
using .WealthData: find_wealth_for_hh!
using .HouseholdFromFrame: load_hhld_from_frame
using .MatchingLibs
using .RunSettings
using .Utils

export  initialise, get_household

const EXAMPLE_HOUSEHOLDS = Dict{String,Household}()

const KEYMAP = Vector{AbstractString}()

function find_consumption_for_example!( hh, settings )
    @argcheck settings.indirect_method == matching
    # FIXME TODO TEMP HACK since examples are not in the frs/lcf matching dataset just pick a hid/datayear that *is there*
    tmp_data_year = hh.data_year
    tmp_hid = hh.hid
    hh.data_year = 2022 # just the last 
    hh.hid = 25045 
    find_consumption_for_hh!( hh, settings, 1 )
    hh.data_year = tmp_data_year
    hh.hid = tmp_hid
    if settings.impute_fields_from_consumption
        ConsumptionData.impute_stuff_from_consumption!(hh,settings)
    end
end

function find_wealth_for_example!( hh, settings )
    @argcheck settings.wealth_method == matching
    case = 754
    find_wealth_for_hh!( hh, case )
end



"""

"""
function initialise( settings :: Settings )
    global KEYMAP 
    global EXAMPLE_HOUSEHOLDS
    # lazy load cons data if needs be
    tmp_data_source = settings.data_source 
    settings.data_source = ExampleSource
    if settings.indirect_method == matching
        ConsumptionData.init( settings ) 
    end
    if settings.wealth_method == matching
        WealthData.init( settings ) 
    end
    empty!(KEYMAP) # = [] # Vector{AbstractString}()
    hh_dataset = HouseholdFromFrame.read_hh( 
        joinpath(qualified_artifact( "example_data" ),"households.tab" ))# CSV.File( ds.hhlds ) |> DataFrame
    people_dataset = 
        HouseholdFromFrame.read_pers( 
            joinpath(qualified_artifact( "example_data" ),"people.tab" )) # CSV.File( ds.people ) |> DataFrame

    npeople = size( people_dataset)[1]
    nhhlds = size( hh_dataset )[1]
    for hseq in 1:nhhlds
        hhf = hh_dataset[hseq,:]
        push!( KEYMAP, hhf.name )
        println( "loading $(hhf.name) $(hhf.council)")
        hh = load_hhld_from_frame( 
            hseq, hhf, people_dataset, settings )
        if( settings.indirect_method == matching ) && (settings.do_indirect_tax_calculations)
            find_consumption_for_example!( hh, settings )
        end
        if settings.wealth_method == matching
            find_wealth_for_example!( hh, settings )
        end
        EXAMPLE_HOUSEHOLDS[hhf.name] = hh
        # println( EXAMPLE_HOUSEHOLDS[hhf.name].council )
        infer_house_price!( hh, settings )
    end
    settings.data_source = tmp_data_source
    # return KEYMAP
end

function example_names()
    if length(EXAMPLE_HOUSEHOLDS) == 0
        initialise( Settings())
    end
    return KEYMAP
end

function get_household( pos :: Integer ) :: Household
    if length(EXAMPLE_HOUSEHOLDS) == 0
        initialise( Settings())
    end
    key = KEYMAP[pos]
    return EXAMPLE_HOUSEHOLDS[key]
end

function get_household( name :: AbstractString ) :: Household
    if length(EXAMPLE_HOUSEHOLDS) == 0
        initialise( Settings())
    end
    return EXAMPLE_HOUSEHOLDS[name]
end

end
