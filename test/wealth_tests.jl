using Test
using ScottishTaxBenefitModel

using .GeneralTaxComponents: RateBands, WEEKS_PER_YEAR, WEEKS_PER_MONTH
using .Definitions
using .ExampleHelpers
using .HouseholdFromFrame: create_regression_dataframe
using .ModelHousehold
using .Monitor: Progress
using .OtherTaxes: calculate_other_taxes!
using .Results
using .RunSettings
using .STBIncomes
using .Utils

using CSV
using DataFrames
using GLM
using Observables
using StatsBase


@testset "Wealth Tax Examples" begin
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
        @test hres.income[OTHER_TAX] ≈ max(0,w-sys.othertaxes.wealth_allowance) *sys.othertaxes.wealth_tax
        println( "hres.bhc_net_income=$(hres.bhc_net_income)" )
    end
end

@testset "Wealth Tax Live Data" begin
      
    tot = 0
    settings = get_all_uk_settings_2023()
    # observer = Observer(Progress("",0,0,0))
    obs = Observable( Progress(settings.uuid,"",0,0,0,0))
    of = on(obs) do p
        global tot
        println(p)
        tot += p.step
        println(tot)
    end  

    @time settings.num_households, settings.num_people, nhh2 = initialise( settings; reset=true )
    settings.requested_threads = 4
    settings.ineq_income_measure = eq_bhc_net_income
    # FIXME 2019->2023
    sys1 = get_system(year=2023, scotland=false)
    sys2 = deepcopy(sys1)
    sys2.othertaxes.wealth_tax = 0.01/WEEKS_PER_YEAR
    sys = [sys1, sys2]    
    results = do_one_run( settings, sys, obs )
    outf = summarise_frames!( results, settings )
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



