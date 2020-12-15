#
# example of how you can get a const typed array into global scope,
# by wrapping it in a struct and relying on the fact that the array
# inself will always be mutable
# 
module HHLDs

    using BenchmarkTools
    using InteractiveUtils

    
    struct HH{T<:Real}
      rent :: T
      rates :: T
    end
    
    function tenkhhlds(t::Type)::Vector
        a = Vector{HH{t}}(undef,10_000)
        for i in 1:10_000
            a[i] = HH{t}(i, i*2)
        end
        a
    end
    
    struct A
       m :: Vector{HH{Float64}}
     end
     
    const AA = A(tenkhhlds(Float64))
    BB = A(tenkhhlds(Float64))
    CC = tenkhhlds(Float64)
    
    function f(x::A)::Real
        s = 0.0
        for i in x.m
          s += i.rates
        end
        s
    end  
    
    
    function f(x::Vector{HH{Float64}})::Real
        s = 0.0
        for i in x
          s += i.rates
        end
        s
    end   
    
    function getAA(i::Int)::HH{Float64}
        AA.m[i]
    end

    function getBB(i::Int)::HH{Float64}
        BB.m[i]
    end
    
    function getCC(i::Int)::HH{Float64}
        CC[i]
    end
    
    function fgAA()::Real
        s = 0.0
        for i in 1:10_000
            hh = getAA(i)
            s += hh.rates
        end
        s        
    end
    
    function fgBB()::Real
        s = 0.0
        for i in 1:10_000
            hh = getBB(i)
            s += hh.rates
        end
        s        
    end
    
    function fgCC()::Real
        s = 0.0
        for i in 1:10_000
            hh = getCC(i)
            s += hh.rates
        end
        s        
    end

    
    function do_all()
        hhbench = BenchmarkGroup()           
        hhbench[:direct_constant] = @benchmark f(AA) 
        hhbench[:direct_variable_struct] = @benchmark f(BB)
        hhbench[:direct_variable] = @benchmark f(CC)
        hhbench[:getter_struct_const] = @benchmark fgAA()
        hhbench[:getter_struct_var] = @benchmark fgBB()
        hhbench[:getter_array_variable] = @benchmark fgCC()
        
        hhbench
    end
 
end

# push!(HHLDs.AA.m,HHLDs.HH(10.0,10.0))
# or ..
# push!(HHLDs.AA.m,HHLDs.HH{Float64}(11,11))

HHLDs.do_all()

@code_warntype HHLDs.getCC(1)
# @code_warntype HHLDs.getAA(1)
