using Test
using STBParameters
using JSON
using Utils
import GeneralTaxComponents: WEEKS_PER_YEAR

@testset "IT Parameter Tests" begin
    itsysdir :: IncomeTaxSys = get_default_it_system( year=2019, scotland=true)
    itsyseng :: IncomeTaxSys = get_default_it_system( year=2019, scotland=false)
    @test itsyseng.non_savings_rates[1]≈0.20
    @test itsyseng.non_savings_thresholds[2]≈150_000/WEEKS_PER_YEAR
    it = IncomeTaxSys()
    itweekly = deepcopy(it)
    @test itweekly.savings_rates == it.savings_rates
    weeklyise!( itweekly )
    annualise!( itweekly )
    @test isapprox( itweekly.non_savings_thresholds, it.non_savings_thresholds, rtol=0.00001 )
    @test itweekly.mca_minimum ≈ it.mca_minimum
    it_s = JSON.json( it )
    itj_dic = JSON.parse( it_s )
    itj = fromJSON( itj_dic )
    @test itj.non_savings_thresholds ≈ it.non_savings_thresholds
    @test itj.mca_minimum ≈ it.mca_minimum
    @test itj.company_car_charge_by_CO2_emissions ≈ it.company_car_charge_by_CO2_emissions
end # example 1
