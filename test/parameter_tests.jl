using Test
using JSON2

using ScottishTaxBenefitModel
using ScottishTaxBenefitModel.STBParameters:
    IncomeTaxSys,weeklyise!,annualise!
using ScottishTaxBenefitModel.Utils
import ScottishTaxBenefitModel.GeneralTaxComponents: WEEKS_PER_YEAR

@testset "IT Parameter Tests" begin
    itsysdir :: IncomeTaxSys = get_default_it_system( year=2019, scotland=true)
    itsyseng :: IncomeTaxSys = get_default_it_system( year=2019, scotland=false)
    @test itsyseng.non_savings_rates[1]≈0.20
    @test itsyseng.non_savings_thresholds[2]≈150_000/WEEKS_PER_YEAR
    it = IncomeTaxSys{Int64,Float64}()
    itweekly = deepcopy(it)
    @test itweekly.savings_rates == it.savings_rates
    weeklyise!( itweekly )
    annualise!( itweekly )
    @test isapprox( itweekly.non_savings_thresholds, it.non_savings_thresholds, rtol=0.00001 )
    @test itweekly.mca_minimum ≈ it.mca_minimum
    it_s = JSON2.write( it )
    itj = JSON2.read( it_s, IncomeTaxSys{Int64,Float64} )
    @test itj.non_savings_thresholds ≈ it.non_savings_thresholds
    @test itj.mca_minimum ≈ it.mca_minimum
    @test isapprox(itj.company_car_charge_by_CO2_emissions, it.company_car_charge_by_CO2_emissions )
end # example 1
