#

abstract type STBPerson end
struct STBAdult <: STBPerson
    age :: Int
    sex :: Int
    income :: Float64
end

struct OtherAdult
    age :: Int
    sex :: Int
    income :: Float64
end

struct STBChild <: STBPerson
    age :: Int
    sex :: Int
end

abstract type AdultTrait end
struct IsAdult <: AdultTrait end
struct IsChild <: AdultTrait end

AdultTrait(::Type) = IsChild()

AdultTrait(::Type{<:STBPerson}) = IsChild()
AdultTrait(::Type{<:STBAdult}) = IsAdult()
AdultTrait(::Type{<:OtherAdult}) = IsAdult()

employable(x::T) where {T} = employable( AdultTrait(T), x )
employable(::IsAdult, x ) = true
employable(::IsChild, x ) = false

# minimal version

abstract type DemogTrait end
struct HasDemog <: DemogTrait end
struct NoDemog <: DemogTrait end

# this means: 1st arg = a type derived from STBPerson
DemogTrait( ::Type{<: STBPerson}) = HasDemog()
DemogTrait( ::Type{<: OtherAdult}) = HasDemog()
DemogTrait( ::Type ) = NoDemog()

get_age( x::T ) where {T} = get_age( DemogTrait(T), x ) # dispatch from this ...
get_age(::HasDemog, x ) = x.age # to this ..
function get_age(::NoDemog, x ) # .. or this
    @assert false "no age" 
end