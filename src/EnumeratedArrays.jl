module EnumeratedArrays

#=

An array-like thing indexed by an enumerated type, like in Pascal/Ada
Move to it's own package??

=#

using JSON

export EnumeratedArray

# ---------------------------------------------------------------------
# Per-Enum metadata cache: dense index + name lookup, computed once
# per Enum type and cached (keyed by type identity).
# ---------------------------------------------------------------------
const _ENUM_META_CACHE = IdDict{DataType,Any}()

function _enum_meta(::Type{E}) where {E<:Enum}
    get!(_ENUM_META_CACHE, E) do
        insts = instances(E)                       # declaration order, guaranteed by @enum
        index = Dict{E,Int}(x => i for (i, x) in enumerate(insts))
        symbol = Dict{Symbol,E}(Symbol(x) => x for x in insts)
        (instances = insts, index = index, symbol = symbol)
    end
end

@inline _enum_index(x::E) where {E<:Enum} = _enum_meta(E).index[x]
@inline _enum_from_symbol(::Type{E}, s::Symbol) where {E<:Enum} = _enum_meta(E).symbol[s]

# ---------------------------------------------------------------------
# The type
# ---------------------------------------------------------------------
struct EnumeratedArray{E<:Enum,V} <: AbstractVector{V}
    values  :: Vector{V}
    isset   :: BitVector
    default :: V
end

function EnumeratedArray{E,V}(; default = nothing, operator = nothing, kwargs...) where {E<:Enum,V}
    n = length(_enum_meta(E).instances)
    d = default === nothing ? convert(V, 0) : convert(V, default)
    it = EnumeratedArray{E,V}(fill(d, n), falses(n), d)

    if operator !== nothing
        for x in _enum_meta(E).instances
            it[x] = operator(x)
        end
    end
    for (k, v) in kwargs
        it[_enum_from_symbol(E, k)] = v
    end
    return it
end

# ---------------------------------------------------------------------
# Indexing: by enum value or by dense Int position
# ---------------------------------------------------------------------
Base.getindex(i::EnumeratedArray{E}, x::E) where {E} = i.values[_enum_index(x)]
Base.getindex(i::EnumeratedArray, idx::Integer) = i.values[idx]

function Base.setindex!(i::EnumeratedArray{E,V}, v, x::E) where {E,V}
    k = _enum_index(x)
    i.values[k] = v
    i.isset[k] = true
    return i
end
function Base.setindex!(i::EnumeratedArray, v, idx::Integer)
    i.values[idx] = v
    i.isset[idx] = true
    return i
end

# ---------------------------------------------------------------------
# Property syntax: i.wage
# ---------------------------------------------------------------------
function Base.getproperty(i::EnumeratedArray{E,V}, s::Symbol) where {E,V}
    s === :values  && return getfield(i, :values)
    s === :isset   && return getfield(i, :isset)
    s === :default && return getfield(i, :default)
    return i[_enum_from_symbol(E, s)]
end

function Base.setproperty!(i::EnumeratedArray{E,V}, s::Symbol, v) where {E,V}
    s === :values  && return setfield!(i, :values, v)
    s === :isset   && return setfield!(i, :isset, v)
    s === :default && return setfield!(i, :default, v)
    i[_enum_from_symbol(E, s)] = v
end

Base.propertynames(::EnumeratedArray{E}) where {E} = Symbol.(_enum_meta(E).instances)

# ---------------------------------------------------------------------
# Array interface
# ---------------------------------------------------------------------
Base.size(i::EnumeratedArray) = (length(i.values),)
Base.length(i::EnumeratedArray) = length(i.values)          # total capacity (= number of Enum members)
Base.axes(i::EnumeratedArray) = axes(i.values)
Base.IndexStyle(::Type{<:EnumeratedArray}) = IndexLinear()

Base.similar(i::EnumeratedArray{E,V}) where {E,V} = EnumeratedArray{E,V}(; default = i.default)
function Base.similar(::EnumeratedArray{E,V}, ::Type{T}, dims::Dims) where {E,V,T}
    n = length(_enum_meta(E).instances)
    dims == (n,) || throw(DimensionMismatch("EnumeratedArray's size is fixed by the Enum $E"))
    EnumeratedArray{E,T}()
end

# Fixed size: no growing/shrinking
for f in (:push!, :append!, :pop!, :popfirst!, :pushfirst!, :resize!, :deleteat!, :insert!)
    @eval Base.$f(::EnumeratedArray, args...; kwargs...) =
        error("$($f) is not supported: EnumeratedArray's size is fixed by its Enum type")
end

# ---------------------------------------------------------------------
# Iteration: only explicitly-set entries, as key=>value pairs, in Enum order
# (Note: this only affects explicit `for`/`iterate` use — sum/collect/map
# use index-based AbstractArray methods and are unaffected.)
# ---------------------------------------------------------------------
Base.eltype(::Type{EnumeratedArray{E,V}}) where {E,V} = Pair{E,V}

function Base.iterate(i::EnumeratedArray{E}, state::Int = 1) where {E}
    insts = _enum_meta(E).instances
    n = length(insts)
    idx = state
    while idx <= n && !i.isset[idx]
        idx += 1
    end
    idx > n && return nothing
    return (insts[idx] => i.values[idx], idx + 1)
end

Base.keys(i::EnumeratedArray{E})   where {E} = (x for (idx, x) in enumerate(_enum_meta(E).instances) if i.isset[idx])
Base.values(i::EnumeratedArray)                = (i.values[idx] for idx in eachindex(i.values) if i.isset[idx])
Base.pairs(i::EnumeratedArray{E})  where {E} = (x => i.values[idx] for (idx, x) in enumerate(_enum_meta(E).instances) if i.isset[idx])

# ---------------------------------------------------------------------
# Pretty printing: only set elements, enum order
# ---------------------------------------------------------------------
function Base.show(io::IO, i::EnumeratedArray{E,V}) where {E,V}
    print(io, "EnumeratedArray{", E, ",", V, "}(")
    join(io, ("$k=$v" for (k, v) in i), ", ")
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", i::EnumeratedArray{E,V}) where {E,V}
    n = count(i.isset)
    println(io, "EnumeratedArray{", E, ",", V, "} (", n, " of ", length(i), " set):")
    for (k, v) in i
        println(io, "  ", k, " => ", v)
    end
end

# ---------------------------------------------------------------------
# JSON.jl support (only set entries, keyed by member name)
# ---------------------------------------------------------------------
JSON.lower(i::EnumeratedArray) = Dict(String(Symbol(k)) => v for (k, v) in i)

function EnumeratedArray{E,V}(d::AbstractDict) where {E<:Enum,V}
    it = EnumeratedArray{E,V}()
    for (k, v) in d
        it[_enum_from_symbol(E, Symbol(k))] = v
    end
    return it
end

end # module
