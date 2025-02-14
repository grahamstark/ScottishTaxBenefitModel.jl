module Common

using ScottishTaxBenefitModel
using .RunSettings

using CSV,
    DataFrames,
    Measures,
    StatsBase,
    ArgCheck

export MatchingLocation, score, load, composition_map, composition_map, searchbaddies, person_map 
export TOPCODE, within, composition_map, makeoutdf, age_hrp, pct, compareone
export checkall , checkdiffs

struct MatchingLocation
    case :: Int
    datayear :: Int
    score :: Float64
    income :: Float64
    incdiff :: Float64
end

function map_socio( socio :: Int, default=9998 ) :: Vector{Int}
    @argcheck socio in 1:12
    out = fill( default, 3 )
    out[1] = socio
    out[2] = if socio in 1:3 # higher & managers
        1
    elseif socio <= 8 # other jobs
        2
    else # none, students, unemployed
        3
    end
    out[3] = socio <= 8 ? 1 : 2 # workers/non-workers
    out
end

function map_marital( ms :: Int, default=9998 ) :: Vector{Int}
    out = fill( default, 3 )
    out[1] = ms
    out[2] = ms in [1,2] ? 1 : 2 # married, civil or cohabiting
    return out
end

function map_empstat( ie :: Int, default=9998 ):: Vector{Int}
    @argcheck ie in 1:12
    out = fill( default, 3 )
    out[1] = ie
    out[2] = ie in 1:2 ? 1 : 2 # employee
    return out
end

"""
Score for one of our 3-level matches 1 for exact 0.5 for partial 1, 0.1 for partial 2
"""
function score( a3 :: Vector{Int}, b3 :: Vector{Int})::Float64
    @argcheck length(a3) == length(b3)
    l = length(a3)
    return if a3[1] == b3[1]
        1.0
    elseif a3[2] == b3[2]
        0.5
    elseif (l == 3) && (a3[3] == b3[3])
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
    d = CSV.File( path; missingstring=["", " "] ) |> DataFrame
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

function map_tenure( tenure :: Union{Int,Missing}, default=9999 ) :: Vector{Int}
@argcheck tenure in 1:8
    out = fill( default, 3 )
    if ismissing( tenure )

    elseif tenure == 1
        out[1] = 1
        out[2] = 1
    elseif tenure == 2
        out[1] = 2
        out[2] = 1
    elseif tenure == 3
        out[1] = 3
        out[2] = 1
    elseif tenure == 4
        out[1] = 4
        out[2] = 1
    elseif tenure == 5 
        out[1] = 5
        out[2] = 2
    elseif tenure == 6
        out[1] = 6
        out[2] = 2   
    elseif tenure in [7,8]
        out[1] = 7
        out[2] = 3   
    else
        @assert false "unmatched tenure $tenure";
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
        # acc = tryparse( Int, acc )
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


function age_grp( age :: Int ) :: Vector{Int}
    out = if age < 16 # can't happen?
        1
    elseif age < 25
        2
    elseif age < 35
        3
    elseif age < 45
        4
    elseif age < 55
        5
    elseif age < 65
        6
    elseif age < 75
        7
    elseif age >= 75
        8
    end
    return frs_age_map( out, 9998 )
end


function age_map( age:: Int, default=9998 ) :: Vector{Int}
    out = fill( default, 3 )
    out[1] = hhagegr4
    if agein 1:3 # u35
        out[2] = 1
    elseif agein 4:5 # 35-64
        out[2] = 2
    else
        out[2] = 3
    end
    out
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


"""
Map accomodation. General case.
"""
function map_accom( acc :: Any, default=9998)  :: Vector{Int}
    @argcheck acc in 1:6
    out = fill( default, 3 )
    # missing in 2020 f*** 
    if typeof(acc) <: AbstractString
        return out
        # acc = tryparse( Int, acc )
    end
    out[1] = acc
    if acc in 1:3
        out[2] = 1
    elseif acc in 4:5
        out[2] = 2
    elseif acc == 6
        out[2] = 3
    else
        @assert false "unmatched acc $acc"
    end
    out
end

"""
frs age group for hrp - 1st is exact, 2nd u40,40+
"""
function map_age_hrp( age:: Int ) :: Vector{Int}
    @argcheck age in 1:13
    out = fill( 9998, 3 )
    out[1] = age
    if age<= 5
        out[2] = 1
    elseif age<= 13
        out[2] = 2
    else
        @assert false "mapping $age not in 1:13"
    end
    out
end

"""
North_East = 1
North_West = 2
Yorks_and_the_Humber = 3
East_Midlands = 4
West_Midlands = 5
East_of_England = 6
London = 7
South_East = 8
South_West = 9
Scotland = 11 
Wales = 10
Northern_Ireland = 12
"""
function map_region( gvtregn :: Union{Int,Missing}, default=9999 ) :: Vector{Int}
    out = fill( default, 3 )
    if ismissing( gvtregn )
        return out
    end
        # gvtregn = parse(Int, gvtregn )
    out[1] = gvtregn

    if ismissing( gvtregn )
        ;
    elseif gvtregn == 7 # london
        out[2] = 1
    elseif gvtregn in 1:9 # rEngland
        out[2] = 2
    elseif gvtregn == 11 # scotland
        out[2] = 3
    elseif gvtregn == 10 # 
        out[2] = 4
    elseif gvtregn == 12 # nire
        out[2] = 5
    else
        @assert false "unmatched gvtregn $gvtregn";
    end 
    return out
end


const CHECKING_VAR_LENS = Dict(
    ["age"=>3,
    "region"=>3,
    "accom"=>3,
    "tenure"=>3,
    "socio"=>3,
    "empstat"=>3,
    "marital"=>3,
    "year"=>1,
    "wages"=>1,
    "selfemp"=>1,
    "pensions"=>1,
    "degree"=>1,
    "children"=>3,
    "adults"=>3,
    "sex"=>1,
    "year"=>1])


"""
The next two are for testing purposes: check the composition of one matched
dataset against another 
"""
function create_was_frs_matching_dataset( settings :: Settings  ) :: Tuple

    function addtodf( df::DataFrame, label, n, row::Int, data::Vector)
        @assert size(data)[1] == n "data=$(size(data)[1]) n = $n"
        for i in 1:n
            k = Symbol( "$(label)_$(i)")
            df[row,k] = data[i]
        end
    end



    settings.num_households, settings.num_people, nhh2 = 
           FRSHouseholdGetter.initialise( settings; reset=false )
    was_dataset = CSV.File(joinpath(data_dir( settings ),settings.wealth_dataset))|>DataFrame
    nwas = size( was_dataset )[1]
    wasset = DataFrame()
    frsset = DataFrame()
    for v in CHECKING_VARS_LENS
        k = v[1]
        n = v[2]
        for i in 1:n
            key = Symbol( "$(k)_$(i)")
            wasset[!,key] = zeros( Int, nwas )
            frsset[!,key] = zeros( Int, settings.num_households )
        end
    end
    println( names(wasset))
    hno = 0
    for was in eachrow( was_dataset )
        hno += 1
        addtodf( 
            wasset, 
            "age",
            CHECKING_VARS_LENS["age"], 
            hno, 
            was_frs_age_map(was.age_head, 9997 ))
        addtodf( 
            wasset, 
            "region",
            CHECKING_VARS_LENS["region"], 
            hno,  
            frs_regionmap( was.region, 9997 ))
        addtodf( 
            wasset, 
            "accom",
            CHECKING_VARS_LENS["accom"], 
            hno,  
            lcf_accmap( was.accom, 9997 ))
        addtodf( 
            wasset, 
            "tenure",
            CHECKING_VARS_LENS["tenure"], 
            hno,  
            frs_tenuremap( was.tenure, 9997 ))
        addtodf( 
            wasset, 
            "socio",
            CHECKING_VARS_LENS["socio"], 
            hno, 
            map_socio( was.socio_economic_head, 9997 ))
        addtodf( 
            wasset, 
            "empstat",
            CHECKING_VARS_LENS["empstat"], 
            hno, 
            map_empstat( was.empstat_head, 9997 ))
        addtodf( 
            wasset, 
            "sex",
            CHECKING_VARS_LENS["sex"], 
            hno, 
            [was.sex_head] )
        addtodf( 
            wasset, 
            "marital",
            CHECKING_VARS_LENS["marital"], 
            hno, 
            map_marital( was.marital_status_head, 9997 ) )
        addtodf( 
            wasset, 
            "year",
            CHECKING_VARS_LENS["year"], 
            hno, 
            [was.year] )
        addtodf( 
            wasset, 
            "wages",
            CHECKING_VARS_LENS["wages"], 
            hno, 
            [was.any_wages] )
        addtodf( 
            wasset, 
            "selfemp",
            CHECKING_VARS_LENS["selfemp"], 
            hno, 
            [was.any_selfemp] )
        addtodf( 
            wasset, 
            "pensions",
            CHECKING_VARS_LENS["pensions"], 
            hno, 
            [was.any_pension_income] )
        addtodf( 
            wasset, 
            "degree",
            CHECKING_VARS_LENS["degree"], 
            hno, 
            [was.has_degree] )
        addtodf( 
            wasset, 
            "children",
            CHECKING_VARS_LENS["degree"], 
            hno, 
            [was.num_children] )
        addtodf( 
            wasset, 
            "children",
            CHECKING_VARS_LENS["children"], 
            hno, 
            person_map(was.num_children, 9997))
        addtodf( 
            wasset, 
            "adults",
            CHECKING_VARS_LENS["adults"], 
            hno, 
            person_map(was.num_adults, 9997))
    end
    for hno in 1:settings.num_households
        hh = FRSHouseholdGetter.get_household(hno)
        any_wages, any_selfemp, any_pension_income, has_female_adult, income = do_hh_sums( hh )
        hrp = get_head( hh )
        addtodf( 
            frsset, 
            "age",
            CHECKING_VARS_LENS["age"], 
            hno, 
            was_model_age_grp( hrp.age ))
        addtodf( 
            frsset,
            "region", 
            CHECKING_VARS_LENS["region"], 
            hno, 
            model_regionmap( hh.region ))
        addtodf( 
            frsset,
            "accom", 
            CHECKING_VARS_LENS["accom"], 
            hno, 
            model_accommap( hh.dwelling ))
        addtodf( 
            frsset, 
            "tenure",
            CHECKING_VARS_LENS["tenure"], 
            hno,  
            model_tenuremap( hh.tenure ))
        addtodf( 
            frsset, 
            "socio",
            CHECKING_VARS_LENS["socio"], 
            hno, 
            model_map_socio( hrp.socio_economic_grouping ))
        addtodf( 
            frsset, 
            "empstat",
            CHECKING_VARS_LENS["empstat"], 
            hno, 
            model_map_empstat( hrp.employment_status ))
        addtodf( 
            frsset, 
            "sex",
            CHECKING_VARS_LENS["sex"], 
            hno, 
            [Int(hrp.sex)] )
        addtodf( 
            frsset, 
            "marital",
            CHECKING_VARS_LENS["marital"], 
            hno, 
            model_map_marital(hrp.marital_status ) )
        addtodf( 
            frsset, 
            "year",
            CHECKING_VARS_LENS["year"], 
            hno, 
            [hh.interview_year] )
        addtodf( 
            frsset, 
            "wages",
            CHECKING_VARS_LENS["wages"], 
            hno, 
            [any_wages] )
        addtodf( 
            frsset, 
            "selfemp",
            CHECKING_VARS_LENS["selfemp"], 
            hno, 
            [any_selfemp] )
        addtodf( 
            frsset, 
            "pensions",
            CHECKING_VARS_LENS["pensions"], 
            hno, 
            [any_pension_income] )
        addtodf( 
            frsset, 
            "degree",
            CHECKING_VARS_LENS["degree"], 
            hno, 
            [highqual_degree_equiv(hrp.highest_qualification)] )
        addtodf( 
            frsset, 
            "children",
            CHECKING_VARS_LENS["children"], 
            hno, 
            person_map( num_children(hh), 9999))
        addtodf( 
            frsset, 
            "adults",
            CHECKING_VARS_LENS["adults"], 
            hno, 
            person_map( num_adults( hh ), 9999))
                                
        end
    return frsset,wasset
end # create_was_frs_matching_dataset

"""
Driver for testing 
"""
function checkall( filename = "was_matchchecks.md" )
    settings = Settings()
    frsset, wasset = create_was_frs_matching_dataset( settings )
    outf = open( joinpath( "tmp", filename), "w")
    for (k,i) in CHECKING_VARS_LENS
        tabs = compareone( frsset, wasset, k, i )
        println( outf, "## $k")
        for t in tabs
            println( outf, t )
            println( outf )
        end
    end
    close( outf )
end

end # module