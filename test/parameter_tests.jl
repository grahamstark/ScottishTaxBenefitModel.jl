using Test
using JSON3


using ScottishTaxBenefitModel
using ScottishTaxBenefitModel.STBParameters:
    IncomeTaxSys,weeklyise!,annualise!
using ScottishTaxBenefitModel.Utils
using ScottishTaxBenefitModel.ParamsIO
import ScottishTaxBenefitModel.GeneralTaxComponents: WEEKS_PER_YEAR

@testset "IT Parameter Tests" begin
    itsysdir :: IncomeTaxSys = get_default_it_system( year=2019, scotland=true)
    itsyseng :: IncomeTaxSys = get_default_it_system( year=2019, scotland=false)
    @test itsyseng.non_savings_rates[1]≈0.20
    @test itsyseng.non_savings_thresholds[2]≈150_000/WEEKS_PER_YEAR
    it = IncomeTaxSys{Float64}()
    itweekly = deepcopy(it)
    @test itweekly.savings_rates == it.savings_rates
    weeklyise!( itweekly )
    annualise!( itweekly )
    @test isapprox( itweekly.non_savings_thresholds, it.non_savings_thresholds, rtol=0.00001 )
    @test itweekly.mca_minimum ≈ it.mca_minimum
    
    sys_scot = get_system( scotland=true )
    @show sys_scot
    @show sys_scot.it
    @show sys_scot.ni
    
    it_s = toJSON( sys_scot )
    scotj = fromJSON( it_s )
    @show scotj
    @show scotj.it
    @show scotj.ni
    
    @test sys_scot.it.non_savings_thresholds ≈ scotj.it.non_savings_thresholds
    @test sys_scot.it.mca_minimum ≈ scotj.it.mca_minimum
    @test isapprox(sys_scot.it.company_car_charge_by_CO2_emissions, scotj.it.company_car_charge_by_CO2_emissions )
end # example 1