#
# this is from https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-changing-the-type-of-a-variable
#
# conclusion: 
#  1. add concrete types to local variables
#  2. or initialise to something explicit
#  3. abstract types can work as well in some cases (abstract float)
#  4. adding return type doesn't seem to matter for performance purposes
#
module Stability 

    using BenchmarkTools
    using InteractiveUtils

    const NR = 10_000
    
    function unstable()
        x = 1
        for i in 1:NR
            r = rand()
            if( r < 0.5 )
                x += r
            end
        end
        return x
    end
    
    function stable1()::Float64
        x = 1
        for i in 1:NR
            r = rand()
            if( r < 0.5 )
                x += r
            end
        end
        return x
    end
    
    function stable2()
        x = 1.0
        for i in 1:NR
            r = rand()
            if( r < 0.5 )
                x += r
            end
        end
        return x
    end
    
    function stable3()::Float64
        x = 1.0
        for i::Int in 1:10_000
            r = rand()
            if( r < 0.5 )
                x += r
            end
        end
        return x
    end
    
    function stable4()::Float64
        x :: AbstractFloat = 1
        for i in 1:NR
            r = rand()
            if( r < 0.5 )
                x += r
            end
        end
        return x
   end

    
    function do_all()::BenchmarkGroup
        stables = BenchmarkGroup()           
        stables[:stable1] = @benchmark stable1() 
        stables[:stable2] = @benchmark stable2()
        stables[:stable3] = @benchmark stable3()
        stables[:stable4] = @benchmark stable4()
        stables[:unstable] = @benchmark unstable()
        stables
   end
    
end # module

@code_warntype( Stability.unstable() )
@code_warntype( Stability.stable3() )
@code_warntype( Stability.stable4() )

Stability.do_all()