
module IncomesType
#
# can't work out the iterators here.
#
using DataStructures

import Base
export IncomesList

struct IncomesList{K,T<:Number}
    i :: SortedDict{K,T}
    function IncomesList{K,T}() where K where T 
        new{K,T}( SortedDict{K,T}())
    end
end

function Base.show(io::IO, ::MIME"text/plain", i::IncomesList)
    println(i.i)
end

# FIXME this is odd way round for SortedDic
function Base.setindex!(i::IncomesList,v::T, key::K) where K where T<:Number
    i.i[key] = v
end

# not needed if iterate works
function Base.sum(i::IncomesList)
    return sum( values(i.i))
end

function Base.getindex(i::IncomesList,key::K) where K
    return get(i.i,key,0.0)
end

function Base.iterate(i::IncomesList)
    if length(i.i) == 0
        return nothing
    end
    tok = startof(i.i)
    return tok
end #	Returns either a tuple of the first item and initial state or nothing if empty

function Base.iterate(i::IncomesList, state ) 
    println("xx")
    @show state
    nk = advance((i.i,state))
    if nk == pastendsemitoken(i.i)
        return nothing
    end
    return nk # (nk,i.i[nk])    
end

#=
function Base.firstindex(i::IncomesList)

    if length(i.i) == 0
        return nothing
    end
    first(i)[1]
end

function Base.lastindex(i::IncomesList)
    l = length(i.i)
    if l == 0
        return nothing
    end
    last(i)[1]
end

function Base.length(i::IncomesList)
    return length(i.i)
end
=#

end