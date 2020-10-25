using Test
using ScottishTaxBenefitModel
using .STBParameters: MinimumWage, get_minimum_wage 


## FIXME don't need both
lmt = LegacyMeansTestedBenefitSystem{Float64}()
sys = get_system( scotland=true )

mwsys = MinimumWage()

@testset "Basic MW Retrieve 2020/21 values" begin
    @test get_minimum_wage(mwsys,18) == 6.45
    @test get_minimum_wage(mwsys,16) == 4.55
    @test get_minimum_wage(mwsys,1) == 0
    @test get_minimum_wage(mwsys,49) == 8.72
    @test get_minimum_wage(mwsys,99) == 8.72
end


