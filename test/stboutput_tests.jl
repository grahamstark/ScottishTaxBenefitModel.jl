using ScottishTaxBenefitModel
using .STBOutput
using DataFrames
using Test

@testset "basic gain lose tests" begin
    
    d = DataFrame( weight=[200,300,200,100,100],i=[1,1,2,2,2],change=[10,2,4,5,3])
    d.weighted_change = d.weight.*d.change
    ogl = STBOutput.one_gain_lose( d, :i )

    @test ogl."Average Change(£s)" ≈ [5.2,4.0]
    @test sum( ogl."No Change") == 0
    @test sum( ogl."Gain £1.01-£10" ) == sum(d.weight)
end