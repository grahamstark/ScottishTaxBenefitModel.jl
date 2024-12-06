module WeightingData

using CSV
using DataFrames
using Pkg, Pkg.Artifacts, LazyArtifacts

using ScottishTaxBenefitModel
using .RunSettings
using .ModelHousehold 
using .Definitions
using .Weighting

export init, get_weight

mutable struct WS 
    weights::DataFrame
end 

const WEIGHTS = WS(DataFrame())
const WEIGHTS_LA = WS(DataFrame())
const NULL_CC = :""
NOMIS_WAGE_DATA = Dict{String,DataFrame}()

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

function add_ccodes!( df :: DataFrame )
    n = size(df)[1]
    df.ccode = fill(Symbol(""), n )
    for r in eachrow(df)
        m = match(r".*:(.*)", r.Area )
        if ! isnothing(m)
            # println("Area $(r.Area) m[1]=$(m[1])")
            ccode = get( LA_NAMES_TO_CCODES, m[1], Symbol(""))
            if m[1] == "Scotland"
                # FIXME we need a ONS scotland symbol everywhere
                ccode = Symbol("299999999")
            end
            # println( "ccode=$ccode type=$(typeof(ccode))")
            r.ccode = ccode
        end
    end
end

function get_nomis_start_stops( fname :: AbstractString )::AbstractDict
    io = open( fname, "r" )
    starts = Dict{String,Tuple}()
    lines = readlines( io )
    ls = split.( lines, '\t' )
    n = length(lines)
    # FIXME how to broadcast this?
    for i in 1:n
        ls[i] = strip.(ls[i], ['"'])
    end
    println("n=$n")
    # Find start points for each sub-dataset; CSV barfs on this dataset. so do this myself.
    for p in 1:n
        # println( typeof(ls[p][1]))
        if ! isnothing(match( r"^Sex.*:", ls[p][1] ))
            k = ls[p][2] # e.g "Male Full Time Workers"
            w = ls[p+1][2]
            key = "k=|$k| w=|$w|"
            println( key )
            startp = p+4
            endp = 0
            for pp in (startp+2):(startp+1000)
                if ls[pp][1]==""
                    endp = pp-1
                    break
                end
            end
            starts[key] = (startp,endp)
        end
    end
    close(io)
    return starts
end

function load_wage_data()
    global NOMIS_WAGE_DATA
    fname = joinpath( artifact"augdata","nomis-annual-hours-and-earnings-by-la.tab" )
    starts = get_nomis_start_stops( fname )
    for (k,v) in starts
        println( "k=$k v=$v")
        df = CSV.File(fname; 
            delim='\t', 
            normalizenames=true,
            header=v[1],
            skipto=v[1]+2,
            ntasks=1,
            limit=v[2]-v[1]-1,
            missingstring=["#","-",""],
            debug=true
            )|>DataFrame
        add_ccodes!( df  )
        NOMIS_WAGE_DATA[k]=df
    end
end

function make_wage_key(; sex :: Union{Sex,Nothing}=nothing, 
    is_ft :: Union{Bool,Nothing}=nothing, 
    paytype = "Weekly pay - gross" )
    sexp = isnothing(sex) ? "Total" : "$sex"

    totpart = if isnothing( is_ft )
        ""
    elseif is_ft
        "Full Time Workers"
    else
        "Part Time Workers"
    end

    # e.g "k=|Female Part Time Workers| w=|Hours worked - total|"
    kkey = strip("$sexp $totpart")
    key = "k=|$kkey| w=|$paytype|"
    return key
end


function get_earnings_data(; 
    sex :: Union{Sex,Nothing}=nothing, 
    is_ft :: Union{Bool,Nothing}=nothing, 
    paytype = "Weekly pay - gross",
    # field :: Symbol = :Mean,
    council :: Symbol  )::DataFrameRow
    if length( NOMIS_WAGE_DATA ) == 0
        load_wage_data()
    end
    key = make_wage_key( sex=sex, is_ft=is_ft, paytype=paytype )
    df = NOMIS_WAGE_DATA[key]
    return df[df.ccode .== council, :][1,:]
end

"""
returns named tuple with size of weights files after the load
FIXME this forces a reload of the weights every time we change council 
"""
function init_national_weights(settings::Settings; reset=false)::Tuple
    dataset_artifact = get_data_artifact( settings )
    if reset || (size( WEIGHTS.weights ) == (0,0))
        wfile = joinpath(dataset_artifact,"weights.tab")
        println( wfile )
        if isfile( wfile )
            WEIGHTS.weights = CSV.File( wfile ) |> DataFrame
        else # reset to zero
            WEIGHTS.weights = DataFrame()
        end
    end 
    return size(WEIGHTS.weights)
end 

function init_local_weights(settings::Settings; reset=false)::Tuple
    dataset_artifact = get_data_artifact( settings )
    if reset || (size( WEIGHTS_LA.weights ) == (0,0))
        wfile = joinpath(dataset_artifact,"weights-la.tab")
        if isfile( wfile )
            WEIGHTS_LA.weights = CSV.File( wfile ) |> DataFrame
        else # reset to zero
            WEIGHTS_LA.weights = DataFrame()
        end
    end 
    return size(WEIGHTS_LA.weights)
end


function get_weight( settings::Settings, hno :: Integer )::Real
    if settings.do_local_run && (settings.ccode != NULL_CC)
        if size( WEIGHTS_LA.weights ) == (0,0)
            init_local_weights( settings, reset=true )
        end
        return WEIGHTS_LA.weights[hno,settings.ccode]
    else
        if size( WEIGHTS.weights ) == (0,0)
            init_national_weights( settings, reset=true )
        end
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
        # println( "hno=$hno hh.hid=$(hh.hid) hh.data_year=$(hh.data_year)")
        hh.weight = WEIGHTS.weights[hno,:weight]
    end
end

end # WeightingData module