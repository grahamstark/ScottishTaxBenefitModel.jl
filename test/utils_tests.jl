using Test

using CategoricalArrays
using StatsBase 

using ScottishTaxBenefitModel
using .Utils

@enum SomeEnum thing1 thing2 thing3

@testset "CrossTabs" begin

    n = 10_000
    a = categorical(rand(["A","B","C"], n ))
    b = categorical(rand(["A","B","C"], n ))
    order = ["C","A","B"]
    w = Weights( fill( 1.0, n ))
    crosstab, alabels, blabels = make_crosstab( a, b )
    println( "crosstab $crosstab")
    @test sum(crosstab) == n
    @test alabels == blabels == ["A","B","C"]

    crosstab2, alabels2, blabels2 = make_crosstab( a, b; weights=w, rowlevels=order, collevels=order )
    println( "crosstab2 $crosstab2")
    @test sum(crosstab2) == n
    @test alabels2 == blabels2 == order

    v1 = rand( instances(SomeEnum), n )
    v2 = rand( instances(SomeEnum), n )
    crosstab3,  v1labels, v2labels = make_crosstab( v1, v2 )
    println( "crosstab3 $crosstab3")
    @test sum(crosstab3) == n
    @test v1labels == v2labels == ["Thing1","Thing2","Thing3"]
    
end



