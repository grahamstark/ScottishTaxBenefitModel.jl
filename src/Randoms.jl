module Randoms

#=
Some functions to make a huge, 60 digit random number, and extract 
groups of digits from it.

One such number is attached to each person and household
when the dataset is created. This seems a simple way to create
repeatable but kinda-sort random numbers.
=#

export 
    DLA_TO_PIP,
    UC_TRANSITION,
    mybigrand, 
    mybigrandstr, 
    randchunk, 
    strtobi, 
    testp
    

const BR_DIGITS = 60

const DEFAULT_CHUNK_SIZE = 8
const DLA_TO_PIP = 1
const UC_TRANSITION = 9

"""
extract the chars from start:len-1 and convert to a probability
"""
function randchunk( b :: String, start::Int, len :: Int = DEFAULT_CHUNK_SIZE ) :: Float64
    div = Float64( 10^(len) )
    s =b[start:start+len-1]
    p = parse( Float64, s )/div
   
    @assert 0 <= p <= 1 "p out of range $p"
    return p
end

#
# if thresh is 0.2 we want this to return true 20% of the time
#
function testp( b :: String, thresh :: Real, start :: Int ) :: Bool
    p = randchunk( b, start ) 
    # println( "thresh=|$thresh| p=$p")
    return thresh > p
end

"""
The random number is mangled by spreadsheets even when
it's enclosed in quotes, so one crude fix is to prefix it
with a letter and extract from beyond that.
"""
function strtobi( s :: String ) :: String
   return s[2:end]
end

"""
A random number which always has BR_DIGITS decimal digits.
"""
function mybigrand()::String
   return "X"*String(rand( '0':'9', BR_DIGITS  ))
end

"""
one of our a `BR_DIGITS` random numbers, prefixed with a character so spreadsheets
don't mangle it.
"""
function mybigrandstr()::String
   return "X"*string(mybigrand())
end

# print( "randoms is loaded")

end # module Randoms