
module IncomesType

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
    ks = collect(keys(i.i))
    vs = collect(values(i.i))
    k1 = (ks[1], vs[1])
    return (k1, k1[1])
end #	Returns either a tuple of the first item and initial state or nothing if empty

function Base.iterate(i::IncomesList, state::K) where K
    if length(i.i) < state
        return nothing
    end
    k1 = (ks[k], vs[k])
    return (k1, k1[1])
end

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

end