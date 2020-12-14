module GlobalTest

    # 
    # see: https://docs.julialang.org/en/v1/manual/performance-tips/
    #
    
    using BenchmarkTools
    using InteractiveUtils
    
    const N = 10_000
    
    GLOB_VAR = rand(N)
    const GLOB_CONST = rand(N)
    # const GLOB_CONST_TYPED::Vector{Float64} = rand(N)
    # syntax: type declarations on global variables are not yet supported

    const T = eltype(GLOB_VAR)
    
    function fv(x::Vector)::Real
        s = 0.0
        for i in x
          s += i
        end
        s
    end

    function f_glob_const()::Real
        s = 0.0
        for i in GLOB_CONST
             s += i
        end
        s
    end
              
    function f_glob_var()::Real
        s = 0.0
        for i in GLOB_VAR
            s += i
        end
        s
    end             

    function f_glob_var_typed()::Real
        s = 0.0 
        for i in GLOB_VAR::Vector{T}
            s += i
        end
        s
    end  
    
    function f_glob_var_semi_typed()::Real
        s = 0.0
        for i in GLOB_VAR::Vector
            s += i
        end
        s
    end   
    
    function f_glob_var_demi_typed()::Real
        s = 0.0
        for i in GLOB_VAR::Vector{<:Real}
            s += i
        end
        s
    end   
    
    function do_all()
        t = Dict()            
        t[:fv_glob_const] = @benchmark fv(GLOB_CONST) 
        t[:fv_glob_var] = @benchmark fv(GLOB_VAR)
        t[:f_glob_const] = @benchmark f_glob_const()
        t[:f_glob_var] = @benchmark f_glob_var()
        t[:f_glob_var_typed] = @benchmark f_glob_var_typed()
        t[:f_glob_var_semi_typed] = @benchmark f_glob_var_semi_typed()
        t[:f_glob_var_demi_typed] = @benchmark f_glob_var_demi_typed()
        t
    end
end

t = GlobalTest.do_all()

# so, not the global variable that's the problem, 
# if you pass the global in as a parameter.
for (k,v) in t
    println( "$k = " ) 
    @show median( v )
end




