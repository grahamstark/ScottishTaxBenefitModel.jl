using Test
using ScottishTaxBenefitModel
using .Definitions
using .Inferences: add_wealth_to_dataframes!
using .HouseholdFromFrame: create_regression_dataframe
using .ModelHousehold
using .OtherTaxes: calculate_other_taxes!
using .Results
using .RunSettings
using .STBIncomes

using CSV
using DataFrames
using GLM
using StatsBase


@testset "Wealth Tax" begin
    sys = get_system( year=2023, scotland=true )
    sys.othertaxes.wealth_tax = 0.01
    hh = make_hh()
    println( INCOME_TAXES )
    t = [0,0,0.0,0.0,90_000.00]
    for w in [0,1_000,100_000.0,1_000_000.0,10_000_000.0]
        hh.net_physical_wealth = w
        hres = init_household_result( hh )
        calculate_other_taxes!( hres, hh, sys.othertaxes )
        aggregate!( hh, hres )
        @test hres.income[OTHER_TAX] ≈ w*sys.othertaxes.wealth_tax
        println( "hres.bhc_net_income=$(hres.bhc_net_income)" )
    end
end

@testset "Corporation Tax" begin
    sys = get_system( year=2023, scotland=true )
    sys.othertaxes.corporation_tax_changed = true
    sys.othertaxes.implicit_wage_tax = 0.01
    hh = make_hh( adults = 2 )
    for w in [0,1_000,100_000.0,1_000_000.0]
        for (pid,ad) in hh.people
            hh.people[pid].public_or_private = Private
            hh.people[pid].income[wages] = w
        end
        hres = init_household_result( hh )
        calculate_other_taxes!( hres, hh, sys.othertaxes )
        aggregate!( hh, hres )
        println( "hres.bhc_net_income=$(hres.bhc_net_income)" )
    end
end