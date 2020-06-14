module ExampleHouseholdGetter

using DataFrames
using CSV

using ScottishTaxBenefitModel
using ScottishTaxBenefitModel.ModelHousehold
using ScottishTaxBenefitModel.Definitions
using ScottishTaxBenefitModel.HouseholdFromFrame

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
        EXAMPLE_HOUSEHOLDS[hhf.name] = load_hhld_from_frame( hseq, hhf, people_dataset )
    end
    KEYMAP
end

function example_names()
    global KEYMAP
    KEYMAP
end

function get_household( pos :: Integer ) :: Household
    global EXAMPLE_HOUSEHOLDS
    global KEYMAP
    key = KEYMAP[pos]
    EXAMPLE_HOUSEHOLDS[key]
end

function get_household( name :: AbstractString ) :: Household
    global EXAMPLE_HOUSEHOLDS
    EXAMPLE_HOUSEHOLDS[name]
end


end
