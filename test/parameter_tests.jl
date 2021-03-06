using Test
using JSON3


using ScottishTaxBenefitModel
using ScottishTaxBenefitModel.STBParameters:
    IncomeTaxSys,weeklyise!,annualise!,load_file,load_file!,TaxBenefitSystem
using ScottishTaxBenefitModel.Utils
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
    
    sys2 = load_file( "../params/sys_2021.jl" )
    @test sys2.it.personal_allowance==24_991
    @show sys2
    load_file!( sys2, "../params/sys_2021a.jl" )
    @test sys2.it.personal_allowance==24

end # example 1