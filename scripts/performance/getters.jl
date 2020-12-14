# tests of getter, which is the pattern for get_household 
#
# Lessons: 
# 1. no lessons - hopefully the read hhld bit is a sufficiently small part of a run.

module Getters

    using BenchmarkTools
    using InteractiveUtils

    const N = 10
    
    struct A
        v :: Vector{Float64}
    end

    VA = rand( N )
    const CA = rand( N )
    const SA = A(rand(N))
    
    function get_c( i :: Integer ) :: Float64
        c :: Float64 = CA[i]
        c
    end
    
    function get_v( i :: Integer ) :: Float64
        v :: Float64 = VA[i]
        v
    end
    
    function get_s( i :: Integer ) :: Float64
        v :: Float64 = SA.v[i]
        v
    end
        
    function fv()::Float64
        s = 0.0
        for i in 1:N
            v :: Float64 = get_v( i )
            s += v
        end
        s
    end
    
    function fc()::Float64
        s = 0.0
        for i in 1:N
            v :: Float64 = get_c( i )
            s += v
        end
        s
    end
    
    function fs()::Float64
        s = 0.0
        for i in 1:N
            v :: Float64 = get_s( i )
            s += v
        end
        s
    end

    function do_all()
        get_suite = BenchmarkGroup()
        
        println( "Constant" )
        get_suite[:Variable] = @benchmark fv()
        
        println( "Struct" )
        get_suite[:Struct] = @benchmark fs()
        
        println( "Variable" )
        get_suite[:Constant] = @benchmark fc()
        get_suite
    end
    
end

println( "fv" )
@code_warntype( Getters.fv() )

println( "fc" )
@code_warntype( Getters.fc() )

println( "get_v" )
@code_warntype( Getters.get_v(1))

println( "get_c" )
@code_warntype( Getters.get_c(1) )

println( "get_s" )
@code_warntype( Getters.get_s(1) )

Getters.do_all()
