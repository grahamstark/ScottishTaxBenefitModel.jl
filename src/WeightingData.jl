module WeightingData

using CSV
using DataFrames
using ScottishTaxBenefitModel
using .RunSettings
using .ModelHousehold 
using .Weighting

export init, get_weight

mutable struct WS 
    weights::DataFrame
end 

const WEIGHTS = WS(DataFrame())
const WEIGHTS_LA = WS(DataFrame())
const NULL_CC = :""

"""
TODO add the local authority version of this.
"""
function run_weighting( settings :: Settings )
    # default weighting using current Scotland settings; otherwise do manually
    if settings.auto_weight && settings.target_nation == N_Scotland
        @time weight = generate_weights( 
            settings.num_households;
            weight_type = settings.weight_type,
            lower_multiple = settings.lower_multiple,
            upper_multiple = settings.upper_multiple )
        WEIGHTS.weights = weights
    end
end


function get_weight( settings::Settings, hno :: Integer )::Real
    if settings.do_local_run && (settings.ccode != NULL_CC)
        return WEIGHTS_LA.weights[hno,settings.ccode]
    else
        return WEIGHTS.weights[hno,:weight]
    end
end

"""
set the weight for a hh depending on whether do_local is set 
"""
function set_weight!( hh :: Household, settings::Settings )
    if settings.do_local_run && size( WEIGHTS_LA.weights )!=(0,0)
        hno = findfirst( (WEIGHTS_LA.weights.hid .== hh.hid).&(WEIGHTS_LA.weights.data_year.==hh.data_year))
        hh.weight = WEIGHTS_LA.weights[hno,hh.council]
    elseif size( WEIGHTS.weights )!=(0,0)
        hno = findfirst( (WEIGHTS.weights.hid .== hh.hid).&(WEIGHTS.weights.data_year.== hh.data_year))
        hh.weight = WEIGHTS.weights[hno,:weight]
    end
end

"""
returns named tuple with size of weights files after the load
"""
function init( settings::Settings; reset :: Bool )::NamedTuple
    dataset_artifact = get_data_artifact( settings )
    if reset || (size( WEIGHTS.weights ) == (0,0))
        wfile = joinpath(dataset_artifact,"weights.tab")
        if isfile( wfile )
            WEIGHTS.weights = CSV.File( wfile ) |> DataFrame
        end
    end 
    if reset || (size( WEIGHTS_LA.weights ) == (0,0))
        wfile = joinpath(dataset_artifact,"weights-la.tab")
        if isfile( wfile )
            WEIGHTS_LA.weights = CSV.File( wfile ) |> DataFrame
        end
    end 
    return (;weights_size=size(WEIGHTS.weights), weights_la_size=size(WEIGHTS_LA.weights))
end

end # WeightingData module