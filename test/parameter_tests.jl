using Test
# using JSON3


using ScottishTaxBenefitModel
using .STBParameters:
    IncomeTaxSys,
    weeklyise!,
    annualise!,
    TaxBenefitSystem,
    get_default_system_for_date, 
    get_default_system_for_cal_year, 
    get_default_system_for_fin_year

using .Utils
using .ExampleHelpers

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
    
    sys_scot = get_system( year=2019, scotland=true )
    @show sys_scot
    @show sys_scot.it
    @show sys_scot.ni
    
    sys2 = get_default_system_for_fin_year( 2021 ) 
    # load_file( "../params/sys_2021_22.jl" )
    # weeklyise!( sys2 )
    @test sys2.it.personal_allowance ≈ 12_570/WEEKS_PER_YEAR
    @test sys2.lmt.working_tax_credit.age_50_plus_30_hrs == 2_030.00/WEEKS_PER_YEAR
    @test sys2.child_limits.max_children == 2
    @show sys2

    

end # example 1

@testset "Load complete defaults" begin

    for y in 2020:2023
        sys = get_default_system_for_fin_year( y )
    end
    for y in 2020:2023
        sys = get_default_system_for_fin_year( y; scotland=false )
    end

end