module Common

export LCFLocation, score, load, composition_map, composition_map, searchbaddies, person_map 
export TOPCODE, within, composition_map, makeoutdf, age_hrp, pct, compareone

struct LCFLocation
    case :: Int
    datayear :: Int
    score :: Float64
    income :: Float64
    incdiff :: Float64
end

"""
Triple for the age group for the lcf hrp - 1st is groups above to 75, 2nd is 16-39, 40+ 3rd no match.
See coding frame above.
"""
function age_hrp( a065p :: Int ) :: Vector{Int}
    out = fill( 9998, 3 )
    a065p -= 2
    a065p = min( 13, a065p ) # 75+
    out[1] = a065p
    if a065p <= 5
        out[2] = 1
    elseif a065p <= 13
        out[2] = 2
    else
        @assert false "mapping a065p $a065p"
    end
    out
end

"""
Score for one of our 3-level matches 1 for exact 0.5 for partial 1, 0.1 for partial 2
"""
function score( a3 :: Vector{Int}, b3 :: Vector{Int})::Float64
    return if a3[1] == b3[1]
        1.0
    elseif a3[2] == b3[2]
        0.5
    elseif a3[3] == b3[3]
        0.1
    else
        0.0
    end
end

"""
Score for comparison between 2 ints: 1 for exact, 0.5 for within 2 steps, 0.1 for within 5. FIXME look at this again.
"""
function score( a :: Int, b :: Int ) :: Float64
    return if a == b
        1.0
    elseif abs( a - b ) < 2
        0.5
    elseif abs( a - b ) < 5
        0.1
    else
        0.0
    end
end

function load( path::String, datayear :: Int )::Tuple
    d = CSV.File( path ) |> DataFrame
    ns = lowercase.(names( d ))
    rename!( d, ns )
    d.datayear .= datayear
    rows,cols = size(d)
    return rows,cols,d
end

function checkdiffs( title::String, col1::Vector, col2::Vector )
    n = size(col1)[1]
    @assert n  ==  size(col2)[1]
    out = []
    for i in 1:n
        d = col1[i] - col2[i]
        if  abs(d) > 0.00001  
            push!( out, (i, d) )
        end
    end
    if size(out)[1] !== 0 
        println("differences at positions $out")
    end
end

function searchbaddies(lcf::DataFrame, rows, amount::Real, op=≈)
    nms = names(lcf)
    nc = size(lcf)[2]
    for i in 1:nc
        for r in rows
            if(typeof(lcf[r,i]) == Float64) && op(lcf[r,i], amount )
                println("row $r varname = $(n[i])")
            end
        end
    end
end

function person_map( n::Int, default::Int )::Vector{Int}
    @argcheck n >= 0
    out = fill( default, 3 )
    out[1] = n
    out[2] = if n in 0:2
        n
    else 
        3
    end 
    out
end

const TOPCODE = 2420.03

function within(x;min=min,max=max) 
    return if x < min min elseif x > max max else x end
end

"""
Convoluted household type map. See the note `lcf_frs_composition_mapping.md`.
"""
function composition_map( comp :: Int, mappings; default::Int ) :: Vector{Int}
    out = fill( default, 3 )
    n = length(mappings)
    for i in 1:n
        if comp in mappings[i]
            out[1] = i
            break
        end
    end
    @assert out[1] in 1:10 "unmatched comp $comp"
    out[2] = 
        if out[1] in [1,2] # single m/f people
            1
        elseif out[1] in [3,4,7,8,9,10] # any with children
            2
        else # no children
            3
        end
    return out
end


"""
Infuriatingly, this can't be used as rooms is deleted in 19/20 lcf
"""
function rooms( rooms :: Union{Missing,Int,AbstractString}, def::Int ) :: Vector{Int}
    # !!! Another missing in lcf 2020 for NO FUCKING REASON
    out = fill(def,3)    
    if (typeof(rooms) <: AbstractString) || rooms < 0
        return out
        # a116 = tryparse( Int, a116 )
    end

    rooms = min( 6, rooms )
    if (ismissing(rooms) || (rooms == 0 )) 
        return [0,0, 1]
    end
    out = fill(0,3)   
    out[1] = rooms
    out[2] = min( rooms, 3)
    out[3] = rooms == 1 ? 1 : 2
    return out
end


"""
Absolute difference in income, scaled by max difference (TOPCODE,since the possible range is zero to the top-coding)
"""
function compare_income( hhinc :: Real, p344p :: Real, topcode=TOPCODE ) :: Real
    # top & bottom code hhinc to match the lcf p344
    # hhinc = max( 0, hhinc )
    # hhinc = min( TOPCODE, hhinc ) 
    1-abs( hhinc - p344p )/topcode # topcode is also the range 
end


"""
Create a dataframe for storing all the matches. 
This has the FRS record and then 20 lcf records, with case,year,income and matching score for each.
"""
function makeoutdf( n :: Int, prefix :: AbstractString ) :: DataFrame
    d = DataFrame(
    frs_sernum = zeros(Int, n),
    frs_datayear = zeros(Int, n),
    frs_income = zeros(n))
    for i in 1:NUM_SAMPLES
        case_sym = Symbol( "$(prefix)_case_$i")
        datayear_sym = Symbol( "$(prefix)_datayear_$i")
        score_sym = Symbol( "$(prefix)_score_$i")
        income_sym = Symbol( "$(prefix)_income_$i")
        d[!,case_sym] .= 0
        d[!,datayear_sym] .= 0
        d[!,score_sym] .= 0.0
        d[!,income_sym] .= 0.0
    end
    return d
end

function pct(v)
    round.( 100.0 .* v ./ sum(v), sigdigits=2 )
end

function compareone( frs :: DataFrame, was :: DataFrame, name :: String, n :: Int ) :: Array
    out=[]
    for i in 1:n
        df = DataFrame( key=zeros(Int,200), frs=zeros(200), was=zeros(200), diff=zeros(200))
        key = Symbol( "$(name)_$(i)")
        wd = sort( countmap( was[!,key]))
        wf = sort( countmap( frs[!,key]))
        if keys(wd) != keys(wf) 
            println( "key mismatch! $key wd = $(wd) wf = $(wf)")
        end
        wk = Int.(keys( wd ))
        wv = pct(values( wd ))
        fk = Int.(keys( wf ))
        fv = pct(values( wf ))
        mx = max( maximum(wk), maximum(fk))
        mn = min( minimum(wk), minimum(fk))
        incr = 1 - mn
        len = mx - mn + 1
        j = 0
        for i in wk
            j += 1
            df[i+incr,:key] = i
            df[i+incr,:was] = wv[j]
        end
        j = 0
        for i in fk
            j += 1
            df[i+incr,:key] = i
            df[i+incr,:frs] = fv[j]
        end
        df[:,:diff] = df[:,:was] - df[:,:frs]
        println( "$key")
        push!( out, pretty_table( String, df[1:len,:];backend = Val(:markdown)))
    end
    out
end


end