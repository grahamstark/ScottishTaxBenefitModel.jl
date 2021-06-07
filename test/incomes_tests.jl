using Test

include( "../src/Incomes.jl")

# using Incomes

@testset "Incomes" begin

    print( Incomes.isettostr(Incomes.EXEMPT_INCOME ))

end