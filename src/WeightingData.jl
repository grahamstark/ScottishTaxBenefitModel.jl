module WeightingData
#=

This module holds pre-calculated household weights.
TODO add UK,rUK,GB,NIreland,Wales country level weights

=#
using CSV
using DataFrames
using LazyArtifacts

using ScottishTaxBenefitModel
using .RunSettings
using .ModelHousehold 
using .Definitions
using .Utils
using .Weighting

export init, get_weight,LA_CODES,LA_NAMES

mutable struct WS 
    weights::DataFrame
    incomes::DataFrame
end 

# la codes in order
const LA_CODES = [
    :S12000033,
    :S12000034,
    :S12000041,
    :S12000035,
    :S12000036,
    :S12000005,
    :S12000006,
    :S12000042,
    :S12000008,
    :S12000045,
    :S12000010,
    :S12000011,
    :S12000014,
    :S12000047,
    :S12000049,
    :S12000017,
    :S12000018,
    :S12000019,
    :S12000020,
    :S12000013,
    :S12000021,
    :S12000050,
    :S12000023,
    :S12000048,
    :S12000038,
    :S12000026,
    :S12000027,
    :S12000028,
    :S12000029,
    :S12000030,
    :S12000039,
    :S12000040]

const LA_NAMES = Dict(
    :S12000033 => "Aberdeen City",
    :S12000034 => "Aberdeenshire",
    :S12000041 => "Angus",
    :S12000035 => "Argyll and Bute",
    :S12000036 => "City of Edinburgh",
    :S12000005 => "Clackmannanshire",
    :S12000006 => "Dumfries and Galloway",
    :S12000042 => "Dundee City",
    :S12000008 => "East Ayrshire",
    :S12000045 => "East Dunbartonshire",
    :S12000010 => "East Lothian",
    :S12000011 => "East Renfrewshire",
    :S12000014 => "Falkirk",
    :S12000047 => "Fife",
    :S12000049 => "Glasgow City",
    :S12000017 => "Highland",
    :S12000018 => "Inverclyde",
    :S12000019 => "Midlothian",
    :S12000020 => "Moray",
    :S12000013 => "Na h-Eileanan Siar",
    :S12000021 => "North Ayrshire",
    :S12000050 => "North Lanarkshire",
    :S12000023 => "Orkney Islands",
    :S12000048 => "Perth and Kinross",
    :S12000038 => "Renfrewshire",
    :S12000026 => "Scottish Borders",
    :S12000027 => "Shetland Islands",
    :S12000028 => "South Ayrshire",
    :S12000029 => "South Lanarkshire",
    :S12000030 => "Stirling",
    :S12000039 => "West Dunbartonshire",
    :S12000040 => "West Lothian")
    # reverse lookup
const LA_NAMES_TO_CCODES = Dict( values(LA_NAMES) .=> keys(LA_NAMES))

const WEIGHTS = WS(DataFrame(),DataFrame())
const WEIGHTS_LA = WS(DataFrame(),DataFrame())
const NULL_CC = :""
NOMIS_WAGE_DATA = Dict{String,DataFrame}()

"""
TODO add the local authority version of this.
"""
function run_weighting( settings :: Settings )
    # default weighting using current Scotland settings; otherwise do manually
    if(settings.weighting_strategy == use_precomputed_weights) && 
    (settings.target_nation == N_Scotland) 
        @time weights = generate_weights( settings )
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
    fname = joinpath( qualified_artifact( "augdata" ),"nomis-annual-hours-and-earnings-by-la.tab" )
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

"""
set the weight for a hh depending on whether do_local is set 
"""
function set_weight!( hh :: Household, settings::Settings )
    if settings.do_local_run && (settings.ccode != NULL_CC)
        if size( WEIGHTS_LA.weights )==(0,0)
            init_local_weights( settings, reset=true )
        end
        hno = findfirst( (WEIGHTS_LA.weights.hid .== hh.hid).&(WEIGHTS_LA.weights.data_year.==hh.data_year))
        hh.weight = WEIGHTS_LA.weights[hno,hh.council]
    elseif settings.target_nation == N_Scotland #FIXME parameterise this
        if size( WEIGHTS.weights )==(0,0)
            init_national_weights( settings, reset=true )
        end
        hno = findfirst( (WEIGHTS.weights.hid .== hh.hid).&(WEIGHTS.weights.data_year.== hh.data_year))
        hh.weight = WEIGHTS.weights[hno,:weight]
    end
end

function init_local_incomes( settings::Settings; reset :: Bool )
    dataset_artifact = get_data_artifact( settings )
    if reset || (size( WEIGHTS_LA.incomes ) == (0,0))
        ifile = joinpath(dataset_artifact,"local-nomis-frs-wage-relativities.tab")
        if isfile( ifile )
            WEIGHTS_LA.incomes = CSV.File( ifile ) |> DataFrame
        else # reset to zero
            WEIGHTS_LA.incomes = DataFrame()
        end
    end 
    return size(WEIGHTS_LA.weights)
end

function update_local_incomes!( hh :: Household, settings::Settings )
    if settings.do_local_run && (settings.ccode != NULL_CC)
        if size( WEIGHTS_LA.incomes )==(0,0)
            init_local_incomes( settings, reset=true )
        end
    end
    for (pid,pers) in hh.people
        if is_working(pers.employment_status)
            wage = get( pers.income, wages, 0.0 )
            se = get( pers.income, self_employment_income, 0.0 )
            ft = pers.employment_status in [Full_time_Employee,
                Full_time_Self_Employed]
            k = make_wage_key(; sex = pers.sex, is_ft=ft )
            inf = WEIGHTS_LA.incomes[WEIGHTS_LA.incomes.keys.==k,settings.ccode ][1,1]
            pers.income[self_employment_income] = se*inf
            pers.income[wages] = wage*inf
        end
    end
end

end # WeightingData module