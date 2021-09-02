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

const DEFAULT_CHUNK_SIZE = 5
const DLA_TO_PIP = 3
const UC_TRANSITION = 12;

"""
Extract a chunk `len` long from one of our big numbers, starting at 
`start` (from right, so 1=the last digit, not the first).
"""
function randchunk( b :: Integer, start::Int, len :: Int = DEFAULT_CHUNK_SIZE ) :: Int
   return Int((b ÷ BigInt(10)^(start-len)) % (BigInt(10)^len))
end

function testp( b :: Integer, p :: Real, start :: Int ) :: Bool
    test = randchunk( b, start )
    ia = Int(trunc(p*10^DEFAULT_CHUNK_SIZE))
    return test > ia
end


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



end