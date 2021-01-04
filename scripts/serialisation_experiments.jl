#
# tests of json3 serialisation of a struct.
# see: https://github.com/quinnj/JSON3.jl
#    : https://github.com/JuliaData/StructTypes.jl
# 
using JSON3
using StructTypes
using TimeSeries

@enum Fred fred joe

DD = Dict{String,Real}

struct X
    i :: Int
end

struct T7{T}
     t :: Vector{X}
     x :: T
     f :: Fred
     d :: DD
end


StructTypes.StructType(::Type{X}) = StructTypes.Struct()
StructTypes.StructType(::Type{T7{Int64}}) = StructTypes.Struct()
StructTypes.StructType(::Type{T7{Float64}}) = StructTypes.Struct()

t = T7{Float64}( [X(9), X(8)], 77.0, joe, Dict("A"=>1,"B"=>2 ))

s = JSON3.write( t )

t2 = JSON3.read( s, T7{Float64} )

t2 == t

## todo Pretty

io = open("/tmp/t7.json", "w")
JSON3.pretty( io, s )
close( io )

io = open("/tmp/t7.json", "r")
t3 = JSON3.read( io, T7{Float64} )
close( io )

using ScottishTaxBenefitModel
using .GeneralTaxComponents: RateBands, WEEKS_PER_YEAR
using .Definitions
using Parameters

using .STBParameters

StructTypes.StructType(::Type{IncomeTaxSys{Float64}}) = StructTypes.Struct()
it = IncomeTaxSys{Float64}()

s = JSON3.write( it )

io = open("/tmp/itsys.json", "w")
JSON3.pretty( io, s )
close( io )

io = open("/tmp/itsys.json", "r")
t3 = JSON3.read( io, IncomeTaxSys{Float64} )
close( io )

module M

    using JSON3
    using StructTypes

    struct X1
        i :: Int
    end
    StructTypes.StructType(::Type{X1}) = StructTypes.Struct()
    
    DD2 = Dict{String,Real}

    @enum Fred2 fred2 joe2

    struct T8{T}
         t :: Vector{X1}
         x :: T
         f :: Fred2
         d :: DD2
    end
    
    StructTypes.StructType(::Type{T8{Float64}}) = StructTypes.Struct()
    
    function to_file( filename :: String, t :: T8 )    
        io = open( filename, "w")
        JSON3.write( io, t )
        close( io )
    end
    
    function from_file( filename :: String )::T8    
        io = open( filename, "r")
        t = JSON3.read( io, T8{Float64} )
        close( io )
        return t
    end
    
    t8 = T8{Float64}( [X1(9), X1(8)], 77.0, fred2, Dict("A"=>1,"B"=>2 ))
    
end # m
    
M.to_file( "/tmp/t8.json", M.t8 )
l_t8 = M.from_file( "/tmp/t8.json" )

module N

    struct X{T<:Number}
      a :: T
    end
   
end

#
# this one always works but has an ugly global variable
# I'm using this for now.
# 
module O

    using JSON3
    using StructTypes
 
    T = Int
    
    # StructTypes.StructType(::Type{Main.N.X{<:Number}}) = StructTypes.Struct() # doesn't work
    
    StructTypes.StructType(::Type{Main.N.X{T}}) = StructTypes.Struct()
    
    function to_file( filename :: String, t :: Main.N.X )  
        io = open( filename, "w")
        JSON3.write( io, t )
        close( io )
    end
    
    function from_file( filename :: String )::Main.N.X    
        io = open( filename, "r")
        t = JSON3.read( io, Main.N.X{T} )
        close( io )
        return t                            
    end    
    
end

#
# this one sort of works and is much neater but 
# fails with non-standard types like `Float32`
#
module P

    using JSON3
    using StructTypes

    function to_file( filename :: String, t :: Main.N.X{T} ) where T
        if T !== Float64
            @eval begin
                StructTypes.numbertype(::Type{$T}) = StructTypes.NumberType()
            end
        end
        @eval begin
            StructTypes.StructType(::Type{Main.N.X{$T}}) = StructTypes.Struct()
        end
        io = open( filename, "w")
        JSON3.write( io, t )
        close( io )
    end
    
    
    function from_file( filename :: String, T::Type )::Main.N.X
        io = open( filename, "r")
        #if T not in (Float64,Int)
              @eval begin
                   StructTypes.numbertype( ::Type{$T ) = StructTypes.NumberType()
              end
         #  end

        t = JSON3.read( io, Main.N.X{T} )
        close( io )
        return t                            
    end    
 
end


module Q

    using JSON3
    using StructTypes

    function to_file( filename :: String, t :: Main.N.X )
        T = typeof( t.a )
        @eval begin
            StructTypes.StructType(::Type{Main.N.X}) = StructTypes.Struct()        
            StructTypes.StructType(::Type{Main.N.X{$T}}) = StructTypes.Struct()
        end
        io = open( filename, "w")
        JSON3.write( io, t )
        close( io )
    end
 
end

module R
    using TimeSeries
    using JSON3
    using StructTypes
    
    data = (datetime = [DateTime(2018, 11, 21, 12, 0), DateTime(2018, 11, 21, 13, 0)],
        col1 = [10.2, 11.2],
        col2 = [20.2, 21.2],
        col3 = [30.2, 31.2])
    ta = TimeArray(data; timestamp = :datetime, meta = "Example")
    StructTypes.StructType(::Type{TimeArray{Float64,2,DateTime,Array{Float64,2}}}) = StructTypes.Struct()
    
    
    
end

typeof(R.ta)

s = JSON3.write( R.ta )
ta2 = JSON3.read( s, TimeArray{Float64,2,DateTime,Array{Float64,2}})