# Custom enum-based income type for Julia microsimulation

## me

In Julia, I'm trying to create a type that I can use in microsimulation models to represent a list of incomes of a person, and possibly other things like a list of household spending. I've tried to build one myself but would appreciate your input. 

The requirements are:

A) The types of incomes (e.g. wages, pensions, taxes etc.) will be represented by a Julia enumerated type from the `@enum` macro e.g.

    @enum Income wage pension tax

This Enum could be quite long, possibly 256+ entries. The Enum may use the macro's long form: 

```julia
@ebum Income begin
   wage = 99
   tax = 900
end
```

And so on, where the numbers (99, 900, etc.) may not be consecutive and may be large. In what follows,  I'll call the type we're building `IT` and the enum `Incomes`; 

B) I'm agnostic about what underlying data structure is used. It could be a Dict, a Vector, a named tuple or something else;

C) I'd prefer something fast, but simplicity and intelligibility to an averagely skilled programmer (me) is more important;

D)  `IT` should have the following properties: 

1. Constructors like:
   ```julia
   i=IT{Incomes,Float64}()
   i=IT{Incomes,Number}(wage=10)
   i=IT{Incomes,Number}(;default=0.0)
   i=IT{Incomes,T}(;operator=f) # where T is an arbitrary type and `f` is a function. This last is intended to work with `map` and similar;
   ```
2. Broadcasting should work, 
   `i .= 0` should set all set elements to 0
   Vector product of `i  and some other instance of `IT` should work even if elements of either are not explicitly set.
3. `i.wage = 99` and `i[wage]=99` should both work
4. @show should display only the elements that have been explicitly set, and as prettily as possible;
5. `i.wage` should always return 0 if `wage` hasn't been set.

E) Instances of this type should be serialisable and de-serialisable using Julia's JSON package https://github.com/JuliaIO/JSON.jl

F) As far as possible `IT` should be compatible with Julia's Array interface (although pushing elements should be prohibited). A loop: 

```
     for (k,v) in i
     ...
     end
```

Should work as normal but iterate only over the elements of `i` that have been explicitly set.
The Array interface is described here: https://www.geeksforgeeks.org/julia/array-interfaces-in-julia/

G) in looping, printing, etc., the order of elements should always be the same as in the Enum.

## Claude says:

Nice groundwork to build on. Here's a design that meets all your points, plus the reasoning behind the trickier choices (I made a couple of judgment calls where your spec was ambiguous — flagged below so you can tell me if I read them wrong).

### Key design decisions

Storage: `dense Vector{V} + BitVector mask`. With 256+ enum members but typically only a handful set per person, a Dict would also work, but a dense vector indexed by the enum's declaration position is simpler to reason about, faster, and makes broadcasting/array-interface support almost free. The BitVector (isset) just tracks which slots were explicitly written, for display/iteration/JSON.
This relies on instances(E) preserving declaration order, not the numeric values you assigned (so @enum Income wage=99 tax=900 still gives instances(Income) == (wage, tax)). This is guaranteed by @enum — but it's the load-bearing assumption of the whole design, so I've called it out.

`IT{E,V} <: AbstractVector{V}`. Subtyping gets you almost the entire Array interface, similar, and broadcasting for free. The one deliberate deviation: I override iterate to yield key => value pairs (only for set entries), because that's what you asked for (k,v) in i to do. This doesn't break sum, collect, map, or broadcasting, because those all use index-based access (axes/getindex) for AbstractArray, not iterate — iterate is only invoked for explicit for loops. Worth knowing if you extend this later.

`i .= 0 — I` read "set all set elements to 0" as "set all elements to 0" (i.e. standard broadcast-assign semantics), which also marks every slot as explicitly set afterward. If you actually meant "only touch the currently-set elements and leave the rest untouched," that's a different (still easy) implementation — say the word.
operator=f constructor — your spec ties this to map, so I implemented it as: apply f to every enum instance and populate all slots — effectively `IT{E,T}(operator=f) == map(f, instances(E))` packed into the container. `Base.map(f, i::IT)` then works naturally via the standard AbstractArray map, returning a new fully-populated IT{E,T}.

```julia
module IndexedTypes

using JSON

export IT

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
struct IT{E<:Enum,V} <: AbstractVector{V}
    values  :: Vector{V}
    isset   :: BitVector
    default :: V
end

function IT{E,V}(; default = nothing, operator = nothing, kwargs...) where {E<:Enum,V}
    n = length(_enum_meta(E).instances)
    d = default === nothing ? convert(V, 0) : convert(V, default)
    it = IT{E,V}(fill(d, n), falses(n), d)

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
Base.getindex(i::IT{E}, x::E) where {E} = i.values[_enum_index(x)]
Base.getindex(i::IT, idx::Integer) = i.values[idx]

function Base.setindex!(i::IT{E,V}, v, x::E) where {E,V}
    k = _enum_index(x)
    i.values[k] = v
    i.isset[k] = true
    return i
end
function Base.setindex!(i::IT, v, idx::Integer)
    i.values[idx] = v
    i.isset[idx] = true
    return i
end

# ---------------------------------------------------------------------
# Property syntax: i.wage
# ---------------------------------------------------------------------
function Base.getproperty(i::IT{E,V}, s::Symbol) where {E,V}
    s === :values  && return getfield(i, :values)
    s === :isset   && return getfield(i, :isset)
    s === :default && return getfield(i, :default)
    return i[_enum_from_symbol(E, s)]
end

function Base.setproperty!(i::IT{E,V}, s::Symbol, v) where {E,V}
    s === :values  && return setfield!(i, :values, v)
    s === :isset   && return setfield!(i, :isset, v)
    s === :default && return setfield!(i, :default, v)
    i[_enum_from_symbol(E, s)] = v
end

Base.propertynames(::IT{E}) where {E} = Symbol.(_enum_meta(E).instances)

# ---------------------------------------------------------------------
# Array interface
# ---------------------------------------------------------------------
Base.size(i::IT) = (length(i.values),)
Base.length(i::IT) = length(i.values)          # total capacity (= number of Enum members)
Base.axes(i::IT) = axes(i.values)
Base.IndexStyle(::Type{<:IT}) = IndexLinear()

Base.similar(i::IT{E,V}) where {E,V} = IT{E,V}(; default = i.default)
function Base.similar(::IT{E,V}, ::Type{T}, dims::Dims) where {E,V,T}
    n = length(_enum_meta(E).instances)
    dims == (n,) || throw(DimensionMismatch("IT's size is fixed by the Enum $E"))
    IT{E,T}()
end

# Fixed size: no growing/shrinking
for f in (:push!, :append!, :pop!, :popfirst!, :pushfirst!, :resize!, :deleteat!, :insert!)
    @eval Base.$f(::IT, args...; kwargs...) =
        error("$($f) is not supported: IT's size is fixed by its Enum type")
end

# ---------------------------------------------------------------------
# Iteration: only explicitly-set entries, as key=>value pairs, in Enum order
# (Note: this only affects explicit `for`/`iterate` use — sum/collect/map
# use index-based AbstractArray methods and are unaffected.)
# ---------------------------------------------------------------------
Base.eltype(::Type{IT{E,V}}) where {E,V} = Pair{E,V}

function Base.iterate(i::IT{E}, state::Int = 1) where {E}
    insts = _enum_meta(E).instances
    n = length(insts)
    idx = state
    while idx <= n && !i.isset[idx]
        idx += 1
    end
    idx > n && return nothing
    return (insts[idx] => i.values[idx], idx + 1)
end

Base.keys(i::IT{E})   where {E} = (x for (idx, x) in enumerate(_enum_meta(E).instances) if i.isset[idx])
Base.values(i::IT)                = (i.values[idx] for idx in eachindex(i.values) if i.isset[idx])
Base.pairs(i::IT{E})  where {E} = (x => i.values[idx] for (idx, x) in enumerate(_enum_meta(E).instances) if i.isset[idx])

# ---------------------------------------------------------------------
# Pretty printing: only set elements, enum order
# ---------------------------------------------------------------------
function Base.show(io::IO, i::IT{E,V}) where {E,V}
    print(io, "IT{", E, ",", V, "}(")
    join(io, ("$k=$v" for (k, v) in i), ", ")
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", i::IT{E,V}) where {E,V}
    n = count(i.isset)
    println(io, "IT{", E, ",", V, "} (", n, " of ", length(i), " set):")
    for (k, v) in i
        println(io, "  ", k, " => ", v)
    end
end

# ---------------------------------------------------------------------
# JSON.jl support (only set entries, keyed by member name)
# ---------------------------------------------------------------------
JSON.lower(i::IT) = Dict(String(Symbol(k)) => v for (k, v) in i)

function IT{E,V}(d::AbstractDict) where {E<:Enum,V}
    it = IT{E,V}()
    for (k, v) in d
        it[_enum_from_symbol(E, Symbol(k))] = v
    end
    return it
end

end # module

```

### Tests

```julia

using .IndexedTypes, JSON

@enum Income begin
    wage = 99
    pension = 5
    tax = 900
end

i = IT{Income,Float64}()                    # D1.i
j = IT{Income,Number}(wage = 10)            # D1.ii
k = IT{Income,Number}(; default = 0.0)      # D1.iii
m = IT{Income,Float64}(; operator = x -> Int(x) / 10)  # D1.iv

i .= 0                                      # D2 — works, all slots become 0 & "set"
prod = j .* k                               # D2 — works even though most slots unset (→ plain Vector)

i.wage = 99                                 # D3
i[wage] = 99                                # D3
@show i                                     # D4 — only set entries, in Enum order
i.pension                                   # D5 — 0.0, unset

for (k, v) in i                             # F
    println(k, " ", v)
end

j_json = JSON.json(j)                       # E
j2 = IT{Income,Number}(JSON.parse(j_json))  # E — round trip

```
