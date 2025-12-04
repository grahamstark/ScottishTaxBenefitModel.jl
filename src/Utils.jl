module Utils

#
# This contains general purpose, messy stuff not easily fitting elsewhere. 
# A fair chunk is no longer used :(
#

using BudgetConstraints
using ScottishTaxBenefitModel

using ArgCheck
using ArtifactUtils
using Base: Integer, String, Bool
using Base.Unicode
using CategoricalArrays
using CSV
using DataFrames
using Dates
using LazyArtifacts
using Pkg
using LazyArtifacts
using Preferences
using Printf
using PrettyTables
using StatsBase

export 
   @exported_enum, 
   BR_DIGITS, 
   ≈, 
   addsysnotoname, 
   age_in_years, 
   age_then,
   alternates,
   basiccensor, 
   coarse_match,
   date_string,
   diff_between, 
   df_diff,
   eq_nearest_p,  
   extract_digits,
   get_artifact_name,
   get_if_set,
   get_project_path,
   get_quantiles,
   glimpse,
   has_non_z, 
   haskeys,
   index_of_field, 
   insert_quantile!,
   is_zero_or_missing,
   isapprox, 
   isordered,
   loadtoframe, 
   make_start_stops,
   make_crosstab,
   mult_dict!, 
   mult, 
   md_format,
   nearest, 
   nearesti, 
   nearz, 
   not_zero_or_missing, 
   operate_on_struct!, 
   one_of_matches,
   pretty, 
   qstrtodict, 
   renameif!,
   riskyhash,
   to_md_table,
   to_categorical,
   todays_date, 
   qualified_artifact,
   uprate_struct!,
   get_data_version

const ARTIFACT_DIR = "/mnt/data/ScotBen/artifacts/"

function get_data_version()::VersionNumber
   return if haskey(ENV,"SCOTBEN_DATA_VERSION")
      VersionNumber( ENV["SCOTBEN_DATA_VERSION"])
   else
      pkgversion(ScottishTaxBenefitModel) 
   end
end

"""
Very simple sampler for the main hh/pers data.
TODO: add all the joined data.
"""
function make_household_sample( 
   ;
   hhs :: DataFrame,
   pers :: DataFrame,
   sample_size :: Int  ) :: Tuple
   hids = sample( hhs.uhid, sample_size )
   shhs = hhs[ hhs.uhid .∈ ( targets, ), : ]
   spers = pers[ pers.uhid .∈ ( targets, ), : ]
   sort!( shhs, :uhid )
   sort!( spers, :uhid )
   shhs, spers 
end

function get_artifact_name( artname :: String, is_windows :: Bool )::Tuple   
   osname = if is_windows
      "windows"
   else
      "unix"
   end
   version = get_data_version() # pkgversion(ScottishTaxBenefitModel) # get_version()
   # println( "got version as |$version|")
   return "$(artname)-$(osname)-v$(version)", "$(artname)-v$(version)"
end

function get_artifact_name( artname :: String )::AbstractString
    return get_artifact_name( artname, Sys.iswindows())[1]
end

"""
return something like "augdata-v0.13", or, if "SCOTBEN_DATA_DEVELOPING" is set as
an env variable, the directory we build the artifacts in. 
"""
function qualified_artifact( artname :: String )
   return if haskey(ENV,"SCOTBEN_DATA_DEVELOPING") # we're writing direct into the development directory
      joinpath(ARTIFACT_DIR,artname)
   else
      @artifact_str(get_artifact_name( artname ))
   end
end

"""
Given a directory in the artifacts directory (jammed on to /mnt/data/ScotBen/artifacts/) 
with some data in it, make a gzipped tar file, upload this to a server 
defined in Project.toml and add an entry to `Artifacts.toml`. Artifact
is set to lazy load. Uses `ArtifactUtils`.

main data files should contain: `people.tab` `households.tab` `README.md`, all top-level
other files can contain anything.

"""
function make_artifact(;
   artifact_name :: AbstractString,
   is_local :: Bool,
   is_windows :: Bool,
   toml_file = "Artifacts.toml" )::Int 
   full_artifact_name, filename = get_artifact_name( artifact_name, is_windows )
   # version = Pkg.project().version
   gzip_file_name = "$(filename).tar.gz"
   dir = ARTIFACT_DIR 
   if is_windows # windows defender 
         artifact_server_upload = @load_preference( "local-artifact_server_upload_windows" )
         artifact_server_url = @load_preference( "local-artifact_server_url_windows" )
   else 
      if is_local 
         artifact_server_upload = @load_preference( "local-artifact_server_upload_unix" )
         artifact_server_url = @load_preference( "local-artifact_server_url_unix" )
      else
         artifact_server_upload = @load_preference( "public-artifact_server_upload" )
         artifact_server_url = @load_preference( "public-artifact_server_url" )
      end
   end
   tarcmd = `tar zcvf $(dir)/tmp/$(gzip_file_name) -C $(dir)/$(artifact_name)/ .`
   run( tarcmd )
   dest = "$(artifact_server_upload)/$(gzip_file_name)"
   println( "copying |$(dir)/tmp/$gzip_file_name| to |$dest| ")
   url = "$(artifact_server_url)/$gzip_file_name"
   try
      if ! is_windows # we'll handle windows ad. hoc
         upload = `scp $(dir)/tmp/$(gzip_file_name) $(dest)`
         println( "upload cmd |$upload|")
         run( upload )
      end
      @show toml_file full_artifact_name url
      add_artifact!( toml_file, full_artifact_name, url; force=true, lazy=true )
   catch e 
      println( "ERROR UPLOADING $e")
      return -1
   end
   return 0
end

"""
Crude version of Tidyverse `glimpse` command - print 1st `n` rows of each
col in a DataFrame, sideways.
"""
function glimpse( d::AbstractDataFrame; n = 10 )
   n = min(n, size(d)[1])
   w=permutedims(d)[:,1:n]
   pretty_table(insertcols( w, 1 ,:name=>names(d)))
end

"""
crosstab rows vs cols of a categorical arrays using the given weights.
FIXME has a horrible hack for missing values.
   return the crosstab, prettyfied row labels, prettyified col labels, matrix of positions of examples
"""
function make_crosstab( 
   rows :: AbstractCategoricalArray, 
   cols :: AbstractCategoricalArray;
   rowlevels :: AbstractVector{String} = fill("",0),
   collevels :: AbstractVector{String} = fill("",0),
   weights :: AbstractWeights = Weights(ones(length(rows))),
   add_totals = true,
   max_examples = 0 ) :: Tuple
   row_levs = copy(rowlevels)
   col_levs = copy(collevels)
   @argcheck length(rows) == length(cols) == length( weights )

   # find first with hack for missing values. Must be better way...
   function fwm( needle, haystack ) :: Int
      needle = ismissing(needle) ? "Missing" : needle
      ri = findfirst( x->x==needle, haystack )
      @assert ! ismissing(ri) "couldn't match $needle in $haystack"
      ri
   end

   # levels with a 'missing' pushed on the end if needs be
   function makelevels( v :: CategoricalArray )
      l = levels( v,skipmissing=false )
      if any( ismissing.(l))
         l[ismissing.(l)] .= "Missing"
      end
      # send back a copy since otherwise r,c share the same copy & you may get dup 'Total' labels
      copy(l), length(l)
   end
   
   nr = length(row_levs)
   if nr == 0
      row_levs,nr = makelevels( rows )
   end
   @show col_levs
   nc = length(col_levs)
   if nc == 0
      col_levs,nc = makelevels( cols )
   end
   @show col_levs
   if add_totals
      nr += 1
      nc += 1
      push!( row_levs,"Total")
      push!( col_levs,"Total")
   end
   @show col_levs
   m = zeros( nr, nc )
   examples = nothing
   if max_examples > 0
      examples = Array{Vector{Int}}(undef,nr,nc)
      for r in 1:nr
         for c in 1:nc
            examples[r,c] = Int[]
         end
      end
   end
   for r in eachindex( rows )
      rv = rows[r]
      cv = cols[r]
      ri = fwm( rv, row_levs )
      ci = fwm( cv, col_levs )
      # println( "rv=$rv cv==$cv ri=$ri ci=$ci")
      m[ri,ci] += weights[r]
      if 0 < max_examples > length(examples[ri,ci]) 
         push!( examples[ri,ci], r )
      end
   end
   if add_totals
      for c in 1:nc-1
         m[nr,c] = sum( m[1:nr-1,c])
      end
      for r in 1:nr-1
         m[r,nc] = sum( m[r,1:nc-1])
      end
      m[nr,nc] = sum(m[1:nr-1,1:nc-1])
   end
   m, pretty.(row_levs), pretty.(col_levs), examples
end

"""
Enumerated Type version
return the crosstab, prettyfied row labels, prettyified col labels
"""
function make_crosstab( 
   rows::AbstractVector{<:Enum}, 
   cols::AbstractVector{<:Enum}; 
   weights :: AbstractWeights = Weights(ones(length(rows))),
   add_totals = true,
   max_examples = 0 )
   # just hack into Categorical version and use that
   rv = CategoricalArray( string.(rows))
   cv = CategoricalArray( string.(cols))
   rl = collect(string.(instances(eltype(rows))))
   cl = collect(string.(instances(eltype(cols))))
   make_crosstab( 
      rv, 
      cv; 
      rowlevels=rl, 
      collevels=cl, 
      weights=weights,
      add_totals = add_totals,
      max_examples = max_examples )
end

"""
Does exactly that, with 1st col being rowlabels and names being col labels
"""
function matrix_to_frame( 
   m :: AbstractMatrix, 
   rowlabels :: AbstractVector{<:AbstractString}, 
   collabels :: AbstractVector{<:AbstractString} ) :: DataFrame
   d = DataFrame( m, collabels )
   insertcols!( d, 1, :rowlabels=>rowlabels )
   d
end

"""
map a, which is some kind of 1d collection (typically a col from a dataframe), 
to a categorical array using the contents of Dictionary `d`
for the mapping. Missings, Nothings, and integer values < 0 are all mapped to `missing`.
"""
function to_categorical( a :: Any, d :: Dict )::CategoricalArray

   function is1( a :: Nothing, d :: Dict )::Missing
      return missing
   end
   
   function is1( a :: Missing, d :: Dict )::Missing
      return missing
   end
   
   function is1( a :: AbstractString, d :: Dict )
      return is1( tryparse( Int, a ), d )
   end
   
   function is1( a :: Integer, d :: Dict )
      if a < 0
         return missing
      end
      return get(d, a, "$a" )
   end

   categorical(map( x -> is1(x,d), a ))
end
   

"""
Given a vector of (e.g.) incomes size n and a series of m quintile breaks, create m ints with qualile numbers 1:n+1
"""
function get_quantiles( inc::Vector, breaks::Vector )::Vector{Int}
   nbs = size(breaks)[1]
   nhhs = size(inc)[1]
   quints = zeros(Int,nhhs)
   for hno in 1:nhhs
         q = nbs+1
         for d in 1:nbs
            if inc[hno] <= breaks[d]
               q = d
               break
            end
         end    
         quints[hno] = q
   end
   return quints
end



"""
DataFrames `rename` throws an exception if the thing being renamed doesn't exist, but it's 
useful to be able to do that e.g. when joining datasets from multiple years. So...

renameif!( df, "FRED", "JOE" )

Rename column "from" in d to "to", if "from" exists, otherwise do nothing.
"""
function renameif!( d::DataFrame, from::AbstractString, to::AbstractString )
   if from in names(d)
      rename!(d,[from=>to])
   end
end
    
   
"""
renameif!( df, "FRED"=>"JOE" )
rename column "tf[1]" in d to tf[2], if tf[1] exists.
"""
function renameif!(d::DataFrame, pair :: Pair )
   renameif!(d, pair[1], pair[2])
end

"""
renameif!( df, ["FRED"=>"JOE","A"=>"SS"] )
Rename columns of `d` using the collection of pairs tf.
"""
function renameif!(d::DataFrame, pairs :: AbstractArray )
   for t in pairs
      renameif!( d, t ) 
   end
end


"""
Make a new dataframe with the difference between the fields between
start_col and end_col and other fields just copied 
diff is difference df2 - df1, Frames should have identical other cols.
"""
function df_diff( df1 :: DataFrame, df2 :: DataFrame, start_col :: Int, end_col :: Int ) :: DataFrame
   @argcheck size( df1 ) == size( df2 )
   ## maybe check that the non diffed fields are all the same too.. 
   d = copy(df1)
   d[:,start_col:end_col] = df2[:,start_col:end_col] .- df1[:,start_col:end_col]
   return d
end

"""
col number of given field name in a dataframe
"""
function index_of_field( d :: DataFrame, name :: String ) :: Int
   n = names(d)
   return findfirst( n .== name)
end

"""
For threading households
Dup of function in SurveyDataWeighting
"""
function make_start_stops( nrows::Int, num_threads::Int )::Tuple
   start = zeros(Int, num_threads)
   stop = zeros(Int, num_threads)
   chunk_size = Int(trunc(nrows/num_threads))-1;
   p = 1;
   for i in 1:num_threads
         start[i] = p
         p = p + chunk_size;
         if i < num_threads;
            stop[i] = p;
         else;
            stop[i] = nrows; # possibly different number on last thread
         end;
         p = p + 1;
   end;
   return (start, stop)
end

function extract_digits( b :: Integer, r :: UnitRange ) :: Integer
   parse(Int,string(b)[r])
end

"""
get some digits from a Digits, from the left, viewed as decimal.
e.g extract_digits( 7890, 2,3 ) = 89
extract_digits( 78901, 1,2 ) = 78
"""
function extract_digits( b :: Integer, fd::Int, ld::Int ) :: Integer
   # crude but effective
   extract_digits(b, [fd:ld])
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
const DSETT = BudgetConstraints.DEFAULT_SETTINGS
const BC_SETTINGS = BCSettings(0.0,20_000.0,DSETT.increment,DSETT.tolerance,true,DSETT.maxdepth)

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

date_string() = lowercase(Dates.format( todays_date(), "d-u-Y"))

function todays_date() :: Date
    Date( now())
end

"""
Age in years now of someone born on some date.
Annoyingly difficult to get exactly right...
"""
function age_now( born :: Date ) :: Integer
   ago = todays_date()-born
   return Int(trunc(Dates.value( todays_date()-born )/365.25))
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
   if round( a, digits=2) != round( b, digits=2 )
      println( "NOT Equal a = $a b= $b ")
      return false
   end
   return true
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
         if v in ["false","False","FALSE"]
            v = false
         elseif v in ["true","True","TRUE"]
            v = true
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

function isordered( v :: AbstractArray )
   n = size(v)[1]
   for i in 2:n
      if v[i] < v[i]-1
         return false
      end
   end
   return true
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


#=
 macro to define an enum and automatically
 add export statements for its elements
 see: https://discourse.julialang.org/t/export-enum/5396
=#
macro exported_enum(name, args...)
   esc(quote
      @enum($name, $(args...))
      export $name
      for a in $args
         local av = string(a)
         :(export $av)
      end
   end)
end

"""
load a file into a dataframe and force all the identifiers into
lower case
"""
function loadtoframe(filename::AbstractString; missings=["", " "])::DataFrame
   println( "loading $filename")
    df = CSV.File(filename, delim = '\t';missingstring=missings) |> DataFrame #
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
   @argcheck dob <= to_date
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


"""
1234.456 => 1,234.45 
"""
function format_delimited( n :: Number; groupsize :: Int = 3, delim :: Char = ',', decimal_delim :: Char = '.', prec :: Int = 2 ) :: String

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

function md_format( a :: Union{AbstractArray,Tuple} )::String
   s = ""
   for i in eachindex(a)
      vs = md_format(a[i])
      s *= "[$i = $(vs)]"
      if i != lastindex(a)
         s *= ", "
      end
   end
   return s
end

function md_format( a :: AbstractDict )::String
   s = ""
   n = length(a)
   i = 0
   for (k,v) in a
      i += 1
      vs = md_format(v)
      s *= "[$k = $vs]"
      if i != n
         s *= ", "
      end
   end
   return s
end

function md_format( a :: AbstractFloat )::String
   return @sprintf( "%0.6f", a)
end

function md_format( a )
   "$a"
end


function is_a_struct( T::Type )::Bool
   if ! isstructtype( T )
      return false
   end
   return ! (( T <: AbstractArray)||(T<:AbstractDict)||(T<:Real)||(T<:AbstractString)||(T<:Symbol))
end

#=
Crude but more-or-less effective thing that prints out a struct (which may contain other structs) as
a markdown table. 
=#
function to_md_table( f; exclude=[], depth=0 ) :: String
    F = typeof(f)
    @assert isstructtype( F )
    names = fieldnames(F)
    prinames = []
    structnames = []

    for n in names
        v = getfield(f,n)
        T = typeof(v)
        if n in exclude 
            ;
        elseif is_a_struct( T )
            push!(structnames, n )
        else
            push!(prinames, n )
        end
    end
    s = """


    |            |              |
    |:-----------|-------------:|
    """
    for n in prinames
      v = getfield(f,n)
      pn = pretty(n)
      vs = md_format(v)    
      s *= "|**$(pn)**|$vs|\n"
    end
    s *= "\n\n"
    depth += 1
    for n in structnames
        v = getfield(f,n)
        s *= "#"*repeat( "#", depth ) * " " * pretty(n) *"\n"
        s *= to_md_table( v; exclude=exclude, depth=depth )
    end
    return s;
end

"""
Hash of all (??) the elements of the things in the struct `things`
"""
function riskyhash( f, h :: UInt = UInt(0) ) :: UInt
      F = typeof(f)
      @assert isstructtype( F )
      names = fieldnames(F)
      prinames = []
      structnames = []

      for n in names
         v = getfield(f,n)
         T = typeof(v)
         if is_a_struct( T )
            push!(structnames, n )
         else
            push!(prinames, n )
         end
      end
      for n in prinames
         v = getfield(f,n)
         h = hash( v, h )
      end
      for n in structnames
         v = getfield(f,n)
         h = riskyhash( v, h )
      end
   return h
end # riskyhash

"""
Hash value of a collection of things, each of which should be
a struct of some sort. I'm sure a Proper Developer would decide that 
this is A Bad Thing, but it's useful for caching in some visualisation apps.
"""
function riskyhash( things :: AbstractVector )
   h = UInt(0)
   for f in things
      h = riskyhash( f, h )
   end
   h
end

"""
There doesn't seem to be anything like this in standard. Use like:
d.xx = one_of_matches.( d.y, "THING1", "THING2" )
"""
function one_of_matches( x::Any, things... )::Bool
   return if x ∈ things
      true
   else        
      false
   end
end

function add_cols!( df :: DataFrame, cnames :: Vector{Symbol}, types=nothing )
   nrows, ncols = size(df)
   dnames = setdiff(cnames,names(df))
   for n in dnames
      df[:,n] = zeros(nrows)
   end
end

function alternates( v1::T, v2::T, n::Integer)::Vector{T} where T
   v = fill(v1,n)
   for i in 1:n
      if i % 2 == 0
        v[i] = v2
      end
   end
   return v
end

"""
Insert a deciles/quintiles/whatever column `quant_col` in a dataframe.
Defaults to deciles, cols `weight`, `decile`
"""
function insert_quantile!( 
    df::DataFrame;
    measure_col::Symbol, 
    weight_col = :weight,
    quant_col = :decile,
    quantiles = [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9])
    nrows,ncols = size(df)
    # quantile from StatsBase
    breaks = quantile( 
      df[!,measure_col],
      Weights(df[!,weight_col]), 
      quantiles )
    decs = get_quantiles( df[!,measure_col], breaks )
    for hno in 1:nrows
        df[hno,quant_col] = decs[hno]
    end
end


end # module
