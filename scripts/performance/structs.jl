# tests of various struct types
#
# Lessons: 
#  1. we need explicit vectors, not abstract containers
#  2. specialised function makes no difference


module Structs

    abstract type TestType end
    
    struct Untyped <: TestType
        a
    end
    
    struct FixedType  <: TestType
        a :: Vector{Float64}
    end
    
    struct SemiFixedType1  <: TestType
        a :: Vector{<:Number}
    end
    
    struct SemiFixedType2  <: TestType
        a :: AbstractArray
    end
    
    struct SemiParameterisedType{T<:Number}  <: TestType
        a :: AbstractArray{T}
    end
    
    struct ParameterisedType{ArrayT<:AbstractArray{<:Number}} <: TestType
        a :: ArrayT
    end
    
        
    function f(x::TestType)::Real
        s = 0.0
        for i in x.a
          s += i
        end
        s
    end
    
    function f2( x::ParameterisedType )::Real
        s = 0.0
        for i in x.a
          s += i
        end
        s
    end
    
    NA = 10_000
    nums = rand(NA)
    type_suite = BenchmarkGroup()
    
    println( "Untyped" )
    type_suite[:Untyped] = @benchmark f( Untyped( nums ))
    
    println( "FixedType" )
    type_suite[:FixedType] = @benchmark f( FixedType( nums ))
    
    println( "SemiFixedType1" )
    type_suite[:SemiFixedType1] =  @benchmark f( SemiFixedType1( nums ))
    
    println( "SemiFixedType2" )
    type_suite[:SemiFixedType2] = @benchmark f( SemiFixedType2( nums ))
    
    println( "SemiParameterisedType" )
    a = SemiParameterisedType{Float64}( nums )
    type_suite[:SemiParameterisedType] = @benchmark f( a )
    
    println( "ParameterisedType" )
    b = ParameterisedType{Vector{Float64}}( nums )
    type_suite[:ParameterisedType] = @benchmark f( b )
    
    println( "ParameterisedType(2)" )
    type_suite[:ParameterisedTypeWithSpecialisedFunction] = @benchmark f2( b )
    
    
end

Structs.type_suite
