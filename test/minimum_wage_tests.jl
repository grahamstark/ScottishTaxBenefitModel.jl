using Test
using ScottishTaxBenefitModel
using .STBParameters: MinimumWage, get_minimum_wage 
using .ExampleHelpers


## FIXME don't need both
lmt = LegacyMeansTestedBenefitSystem{Float64}()
sys = get_system( year=2019, scotland=true )

mwsys = MinimumWage()

@testset "Basic MW Retrieve 2019/20 values" begin
    @test get_minimum_wage(mwsys,18) == 6.15
    @test get_minimum_wage(mwsys,16) == 4.35
    @test get_minimum_wage(mwsys,1) == 0
    @test get_minimum_wage(mwsys,49) == 8.21
    @test get_minimum_wage(mwsys,99) == 8.21
    #= 20/1
    @test get_minimum_wage(mwsys,18) == 6.45
    @test get_minimum_wage(mwsys,16) == 4.55
    @test get_minimum_wage(mwsys,1) == 0
    @test get_minimum_wage(mwsys,49) == 8.72
    @test get_minimum_wage(mwsys,99) == 8.72
    =#
end


