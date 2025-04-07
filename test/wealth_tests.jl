using Test
using ScottishTaxBenefitModel

using .GeneralTaxComponents: RateBands, WEEKS_PER_YEAR, WEEKS_PER_MONTH
using .Definitions
using .ExampleHelpers
using .HouseholdFromFrame: create_regression_dataframe
using .ModelHousehold
using .Monitor: Progress
using .Runner
using .OtherTaxes: calculate_other_taxes!,calculate_wealth_tax!
using .Results
using .RunSettings
using .SingleHouseholdCalculations
using .STBIncomes
using .STBOutput
using .Utils

using CSV
using DataFrames
using GLM
using Observables
using StatsBase


@testset "Wealth Tax Examples" begin
    sys = get_system( year=2023, scotland=false )
    settings = get_all_uk_settings_2023()
    settings.do_indirect_tax_calculations = false
    sys.wealth.rates = [0.05]
    sys.wealth.thresholds = []
    sys.wealth.abolished = false
    sys.wealth.allowance = 500_000.0
    sys.wealth.one_off = true
    sys.wealth.aggregation = household
    sys.wealth.payment_years = 5
    weeklyise!( sys.wealth )
    hh = make_hh()
    hh.net_financial_wealth = 0
    hh.net_housing_wealth = 0
    hh.net_pension_wealth = 0
    hd = get_head( hh )
    println( INCOME_TAXES )
    println( sys.wealth )
    t = [0,0,0.0,0.0,90_000.00]
    for w in [0,1_000,100_000.0,1_000_000.0,10_000_000.0]
        hh.net_physical_wealth = w
    
        hres = init_household_result( hh )
        calculate_wealth_tax!( hres, hh, sys.wealth )
        aggregate!( hh, hres )
        println( hres.bus[1].pers[hd.pid].wealth )
        @test hres.income[OTHER_TAX] ≈ max(0,w-sys.wealth.allowance) * sys.wealth.rates[1] * sys.wealth.weekly_rate
        println( "hres.bhc_net_income=$(hres.bhc_net_income)" )
    end
    t = [0,0,0.0,0.0,90_000.00]
    for w in [0,1_000,100_000.0,1_000_000.0,10_000_000.0]
        hh.net_physical_wealth = w
        hres = init_household_result( hh )
        hres = do_one_calc( hh, sys, settings )
        aggregate!( hh, hres )
        println( hres.bus[1].pers[hd.pid].wealth )
        @test hres.income[OTHER_TAX] ≈ max(0,w-sys.wealth.allowance) * sys.wealth.rates[1] * sys.wealth.weekly_rate
        println( "hres.bhc_net_income=$(hres.bhc_net_income)" )
    end
end

@testset "Wealth Tax Live Data" begin
      
    tot = 0
    settings = Settings() # FIXME GET UK DATASET workimng get_all_uk_settings_2023()
    # observer = Observer(Progress("",0,0,0))
    obs = Observable( Progress(settings.uuid,"",0,0,0,0))
    of = on(obs) do p
        println(p)
        tot += p.step
        println(tot)
    end  

    @time settings.num_households, settings.num_people, nhh2 = initialise( settings; reset=true )
    settings.requested_threads = 4
    settings.ineq_income_measure = eq_bhc_net_income
    sys1 = get_system(year=2023, scotland=true) # FIXME ENGLAND NEEDS ME
    sys2 = deepcopy(sys1)
    sys2.wealth.rates = [0.05]
    sys2.wealth.thresholds = []
    sys2.wealth.abolished = false
    sys2.wealth.allowance = 500_000.0
    sys2.wealth.one_off = true
    sys2.wealth.aggregation = household
    sys2.wealth.payment_years = 5
    weeklyise!( sys2.wealth )
    sys = [sys1, sys2]    
    results = do_one_run( settings, sys, obs )
    outf = summarise_frames!( results, settings )
    dump_frames( settings, results )
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
