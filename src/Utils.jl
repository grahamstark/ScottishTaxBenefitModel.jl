module Utils

using Base: Integer, String
using DataFrames
using Dates
using Base.Unicode
using CSV
using BudgetConstraints

export @exported_enum, qstrtodict, pretty, basiccensor, get_if_set
export addsysnotoname, diff_between, mult_dict!, get_project_path
export loadtoframe, age_in_years, isapprox, ≈, operate_on_struct!, uprate_struct
export eq_nearest_p,  mult, has_non_z, haskeys, todays_date, age_then
export coarse_match
export nearest, nearesti, nearz, not_zero_or_missing, is_zero_or_missing
export BR_DIGITS, mybigrand, randchunk, strtobi, mybigrandstr

#=
Some functions to make a huge, 60 digit random number, and extract 
groups of digits from it.

One such number is attached to each person and household
when the dataset is created. This seems a simple way to create
repeatable but kinda-sort random numbers.
=#
const BR_DIGITS = 60

"""
The random number is mangled by spreadsheets even when
it's enclosed in quotes, so one crude fix is to prefix it
with a letter and extract from beyond that.
"""
function strtobi( s :: String ) :: BigInt
   return parse( BigInt,s[2:end])
end

"""
A random number which always has BR_DIGITS decimal digits.
"""
function mybigrand()::BigInt
   return rand( BigInt(10)^BR_DIGITS:(BigInt(10)^(BR_DIGITS+1)-1))
end

"""
one of our a `BR_DIGITS` random numbers, prefixed with a character so spreadsheets
don't mangle it.
"""
function mybigrandstr()::String
   return "X"*string(mybigrand())
end

"""
Extract a chunk `len` long from one of our big numbers, starting at 
`start` (from right, so 1=the last digit, not the first).
"""
function randchunk( b :: Integer, start::Int, len :: Int ) :: Int
   return Int((b ÷ BigInt(10)^(start-len)) % (BigInt(10)^len))
end

"""
The index of the DataFrame row with a date field nearest to Date `d`, assuming dates are
sorted low->high. Should really be a binary search but isn't quite.
"""
function nearest( d::Date, df :: DataFrame, col::Symbol=:Date ) :: Integer
   pos = 0
   n = size(df)[1]; 
   p = -1;
   mid = n÷2
   mind = d - df[mid,col]
   if mind == Day(0)
       return mid
   elseif mind < Day(0)
       direction = -1
       las = 1
       mid -= 1
       if mid < 1 # idiot check for v short lists
           return 1
       end
   else
       direction = 1
       las = n
       mid += 1
       if mid > n # idiot check for v short lists
           return n
       end
   end    
   mind = abs(mind)
   pmind = mind
   # println( "p=$p mid=$mid direction=$direction las=$las mind=$mind")
   for i in mid:direction:las
       dd = df[i,col]
       diff = dd - d
       diff = abs( diff ); # print( diff )
       if diff < mind
         mind = diff
         p = i
       end 
       if pmind < mind # we've gone past 
         # println( "returning pmind=$pmind mind=$mind")
         return p
       end
       pmind = mind       
  end
  return p
end



function not_zero_or_missing( thing :: Union{Missing, Number }) :: Bool
   if ismissing( thing )
      return false
   end
   return thing != 0
end

function is_zero_or_missing( thing :: Union{Missing, Number }) :: Bool
   if ismissing( thing )
      return true
   end
   return thing == 0
end

"""
return the index of element of comps that's closest to x 
"""
function nearesti( x :: Real , comps... )
   n = length( comps )
   dist = zeros( n )
   for i in 1:n
       dist[i] = abs( x - comps[i])
   end
   i = findmin( dist )
   return i[1]
end

"""
return the element of comps that's closest to x 
"""
function nearest( x :: Real , comps... )
   return comps[ nearesti( x, comps )]
end

"""
The thing (comps...) that x is closest to, but returning zero even
if 0 isn't in comps..
"""
function nearz( x :: Real, comps ... ) :: Real
    if x ≈ 0
        return 0.0
    end
    return nearest( x, comps ... )
end




#
# this has a higher top income than the BC default
#
const BC_SETTINGS = BCSettings(0.0,20_000.0,DEFAULT_SETTINGS.increment,DEFAULT_SETTINGS.tolerance,true,DEFAULT_SETTINGS.maxdepth)

"""
finds the matches for a single recipient tuple `recip` in a data set `donor`.

each of the recip and donor should be structured as follows

firstvar_1, firstvar_2, firstvar_2 <- progressively coarsened first variable with the `_1` needed exactly as is;
then secondvar_1 .. thirdvar_1 .. _2 and so on. Variables can actually be in any order in the frame.

`vars` list of `firstvar`, `secondvar` and so on, in the order you want them coarsened
`max_coarsens` stop after _2, _3 etc. coarsened variables.

returns a named tuple:
     matches->indexes of rows that match
     quality->numerical indication of quality of each match: +1 for each first match, +4 for each 2nd +9 3rd, etc.
     results_matrix->nobs x nvars matrix with each cell indicating match quality (1..max_coarsens, or -9 for no match).
"""
function coarse_match( 
    recip :: DataFrameRow, 
    donor :: DataFrame, 
    vars  :: Vector{Symbol},
    max_coarsens:: Int ) :: NamedTuple
    nobs = size( donor )[1]
    nvars = size( vars )[1]
    matches = fill( true, nobs )  
    results = fill(-99, nobs,nvars)
    # println( size( results ))
    quality = fill( 0, nobs )  
    for row in 1:nobs
        for col in 1:nvars
            for cs in 1:max_coarsens
                sym = Symbol("$(String(vars[col]))_$(cs)")
                if(donor[row,sym] == recip[sym])
                    results[row,col] = cs
                    break;
                end
            end # coarsens
        end # match vars
    end # rows
    quality = fill( 0, nobs )
    for row in 1:nobs
        for col in 1:nvars
            if results[row,col] == -99 # no match
                matches[row] = false
                quality[row] = -9
                break;
            else 
                quality[row] += results[row,col]^2 # maybe
            end 
        end # no match for some matching var break
    end # check each row
    return (matches=matches,results_matrix=results,quality=quality) 
end

function todays_date() :: Date
    Date( now())
end


"""
These are trivial but annoying to get right.
"""
function age_then( age :: Int, when :: Int )::Int
    ago = Dates.year(todays_date()) - when
    age - ago
end


function age_then( age :: Int, when :: Date = todays_date() ) :: Int
    age_then( age, Dates.year( when ))
end


function eq_nearest_p( a :: Real, b :: Real )
   round( a, digits=2) == round( b, digits=2 )
end

@generated function operate_on_struct!( rec::Rec, x::NR, f::Function ) where Rec where NR<:Number
     assignments = [
         :( rec.$name = f(rec.$name, x) ) for name in fieldnames(Rec)
     ]
     quote $(assignments...) end
end

function mult( v :: AbstractFloat, x :: NR )::NR where NR <: Number
   v*x
end

function mult( v :: AbstractArray, x :: NR )::AbstractArray where NR <: Number
   mult.( v, x )
end

function mult( v::Any, x :: NR )::Any where NR <: Number
   v
end

function m( v :: Any, x :: NR ) where NR <: Number
   mult( v, x )
end

function uprate_struct!( rec::Rec, x::NR ) where Rec where NR<:Number
   operate_on_struct!( rec, x, m )
end

function addsysnotoname(names, sysno)::Array{Symbol,1}
   a = Array{Symbol,1}(undef, 0)
   for n in names
      push!(a, Symbol(String(n) * "_$sysno"))
   end
   a
    # Symbol.(String.( names ).*"_sys_$sysno")
end

"""
Does the ordering here follow stye guide
"""
function get_if_set(dict::Dict, key, default; operation=nothing)
   v = default
   if haskey(dict, key)
      v = dict[key]
      if operation !== nothing
         v = operation( v )
      end
   end
   v
end

import Base.isapprox
import Base.≈


"""
true if the keys are the same and all the elements
   compare approx equal, else false
"""
function isapprox( d1::Dict, d2::Dict ) :: Bool
   k1 = Set( collect( keys(d1)))
   k2 = Set( collect( keys(d2)))
   if k1 != k2
      # println(" resturn ne $(k1) !== $(k2)")
      return false
   end
   for k in k1
      if ! (d1[k] ≈ d2[k])
         # println( "return ne $k $(d1[k]) ≈ $(d2[k])")
         return false
      end
   end
   return true
end

#const ≈ = isapprox

"""
return a dict with all the elements in common where m2[k]-m1[k] is possible.
"""
function diff_between(m2::Dict, m1::Dict)::Dict
   out = Dict()
   keybs = intersect(keys(m1), keys(m2))
   for k in keybs
      v1 = m1[k]
      v2 = m2[k]
      try
         d = v2 - v1
         out[k] = d
      catch

      end # exception
   end # loop[]
   out
end

"""
This is for multiplying incomes where there
   are some (raw) from the data and some,
   possibly the same elements, from earlier
   calculations (net)
"""
function mult(; data::Dict{K,T}, calculated :: Dict{K,T}, included :: Dict{K,T}) :: T where T<:Number where K
   s = zero(T)
   kg = keys( data )
   kn = keys( calculated )
   ki = keys( included )
   ka = union( kg, kn )
   ka = intersect( ka, ki )
   for k in ka
      # choose the calculated value if there is one, otherwise the data one
      i = k in kn ? calculated[k] : data[k]
      s += i*included[k]
   end
   return s;
end # mult

function has_non_z( d::AbstractDict, k ) :: Bool
   if haskey( d, k )
      if typeof(d[k]) <: Number
         return d[k] != 0
      end
   end
   return false
end

function mult_dict!( m :: Dict, n :: Number )
   for (k,v) in m
      try
         m[k] = v*n
      catch
         ;
      end
   end
end

"""
parse an html query string like "sex=male&joe=22&bill=21342&z=12.20"
into a dict. If the value looks like a number, it's parsed into either an Int64 or Float64
"""
function qstrtodict(query_string::AbstractString)::Dict{AbstractString,Any}
   d = Dict{AbstractString,Any}()
   strip(query_string)
   if (query_string == "")
      return d
   end
   as = split(query_string, "&")
   for a in as
      try
         aa = split(a, "=")
         k = aa[1]
         v = aa[2]
         try
            v = parse(Int64, v)
         catch
            try
               v = parse(Float64, v)
            catch
            end
         end
         d[k] = v
      catch

      end
   end
   d
end

function haskeys( d :: AbstractDict, keys ... ) :: Bool
   for k in keys
      if haskey(d, k)
         return true
      end
   end
   return false
end

function haskeys( d :: AbstractDict, keys :: AbstractSet ) :: Bool
   for k in keys
      if haskey(d, k)
         return true
      end
   end
   return false
end

function haskeys( d :: AbstractDict, keys :: AbstractArray ) :: Bool
   for k in keys
      if haskey(d, k)
         return true
      end
   end
   return false
end




"""
returns the string converted to a form suitable to be used as (e.g.) a Symbol,
with leading/trailing blanks removed, forced to lowercase, and with various
characters replaced with '_' (at most '_' in a run).
"""
function basiccensor(s::AbstractString)::AbstractString
   s = strip(lowercase(s))
   s = replace(s, r"[ \-,\t–]" => "_")
   s = replace(s, r"[=\:\)\('’‘]" => "")
   s = replace(s, r"[\";:\.\?\*”“]" => "")
   s = replace(s, r"_$" => "")
   s = replace(s, r"^_" => "")
   s = replace(s, r"^_" => "")
   s = replace(s, r"\/" => "_or_")
   s = replace(s, r"\&" => "_and_")
   s = replace(s, r"\+" => "_plus_")
   s = replace(s, r"_\$+$" => "")
   if occursin(r"^[\d].*", s)
      s = string("v_", s) # leading digit
   end
   s = replace(s, r"__" => "_")
   s = replace(s, r"__" => "_")
   s = replace(s, r"__" => "_") # fixme neater way?
   s = replace(s, r"^_" => "")
   s = replace(s, r"_$" => "")
   return s
end


"""
a_string_or_symbol_like_this => "A String Or Symbol Like This"
"""
function pretty(a)
   s = string(a)
   s = strip(lowercase(s))
   s = replace(s, r"[_]" => " ")
   Unicode.titlecase(s)
end


"""
 macro to define an enum and automatically
 add export statements for its elements
 see: https://discourse.julialang.org/t/export-enum/5396
"""
macro exported_enum(name, args...)
   esc(quote
      @enum($name, $(args...))
      export $name
      for a in $args
         local av = string(a)
         :(export $av)
      end
              # $([:(export $arg) for arg in args]...)
   end)
end

"""
load a file into a dataframe and force all the identifiers into
lower case
"""
function loadtoframe(filename::AbstractString)::DataFrame
   println( "loading $filename")
    df = CSV.File(filename, delim = '\t') |> DataFrame #
    lcnames = Symbol.(lowercase.(string.(names(df))))
    rename!(df, lcnames)
    df
end

"""
Age now for someone with this birthday.
If today is 2020-01-27 then:

   * dob(1958-01-26) = 62
   * dob(1958-01-27) = 62
   * dob(1958-01-28) = 61

And so on.
"""
function age_in_years(
   dob :: Dates.TimeType,
   to_date :: Dates.TimeType = Dates.now() ) :: Integer
   @assert dob <= to_date
   y_to = year(to_date)
   m_to = month(to_date)
   d_to = day(to_date)
   y_dob = year(dob)
   m_dob = month(dob)
   d_dob = day(dob)
   age = y_to - y_dob
   if m_dob > m_to # check if you've not yet had your birthday ..
      age -= 1
   elseif (m_dob == m_to ) && (d_dob > d_to )
      age -= 1
   end
   age
end

# FIXME!! THIS TS TERRIBLE..
function get_project_path()
   path = splitpath(pwd())
   n = size(path)[1]
   if path[end] == "test"
      n -= 1
   end
   join( path[1:n],"/")*"/"
end

end # module
