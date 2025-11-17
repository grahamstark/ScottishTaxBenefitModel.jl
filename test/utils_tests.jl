using Test

using CategoricalArrays
using StatsBase 

using ScottishTaxBenefitModel
using .Utils

@enum SomeEnum thing1 thing2 thing3


@testset "CrossTabs" begin

    order = ["C","A","B"]
    n = 10_000
    w = Weights( fill( 1.0, n ))
    a = categorical(rand(["A","B","C"], n ))
    b = categorical(rand(["A","B","C"], n ))
     
    crosstab2, alabels2, blabels2, examples = make_crosstab( a, b; weights=w, rowlevels=order, collevels=order, max_examples=3, add_totals=false )
    @show crosstab2
    @test sum(crosstab2[1:end,1:end]) == n
    @test alabels2 == blabels2 == order
    @show examples

    v1 = rand( instances(SomeEnum), n )
    v2 = rand( instances(SomeEnum), n )
    crosstab3,  v1labels, v2labels, examples = make_crosstab( v1, v2 )
    @show crosstab3
    @test sum(crosstab3[1:end-1,1:end-1]) == n
    @test v1labels == v2labels == ["Thing1","Thing2","Thing3", "Total"]
    @show examples

    @show levels(a)
    @show levels(b)
    
    crosstab, alabels, blabels = make_crosstab( a, b )
    @show crosstab
    @show order
    @test sum(crosstab[1:end-1,1:end-1]) == n # skip totals
    @test alabels == blabels == ["A","B","C", "Total"]

end



