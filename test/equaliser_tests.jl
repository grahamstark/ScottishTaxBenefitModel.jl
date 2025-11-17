using Test

using ScottishTaxBenefitModel

using .Definitions
using .ExampleHelpers
using .Intermediate: MTIntermediate, make_intermediate    
using .ModelHousehold: count,Household, le_age, ge_age
using .Monitor: Progress
using .Results: aggregate!, init_household_result
using .Runner: do_one_run
using .RunSettings
using .STBIncomes
using .STBOutput
using .STBParameters
using .TheEqualiser
using .UBI: calc_UBI!,make_ubi_post_adjustments! 

using Observables
using PrettyTables
using CSV


settings = Settings()# get_all_uk_settings_2023()
settings.do_indirect_tax_calculations = true
settings.do_marginal_rates = false
settings.poverty_line=100.0 # arbit

# observer = Observer(Progress("",0,0,0))
tot = 0
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)

    tot += p.step
    # println(tot)
end

@testset "Eq UBI with income tax Tests" begin
    base = get_system(year=2023, scotland=true ) # FIXME WE NEED ENGLAND 
    sys = get_system(year=2023, scotland=true )
    sys.ubi.abolished = false
    sys.it.personal_allowance = 0.0
    settings.num_households, settings.num_people, nhh2 = 
        FRSHouseholdGetter.initialise( settings; reset=true )
    make_ubi_pre_adjustments!( sys )
    base_res = do_one_run(
        settings,
        [base],
        obs )
    summary = summarise_frames!(base_res,settings)
    base_cost = summary.income_summary[1][1,:net_inc_indirect]
    println( "base cost is $base_cost")
    eq = equalise( 
        eq_it, 
        sys, 
        settings, 
        base_cost, 
        obs )
    sys.it.non_savings_rates .+= eq
    println( "got it rate change of $eq")
    ubi_res = do_one_run(
        settings,
        [sys],
        obs )
    ubi_summary = summarise_frames!(ubi_res,settings)
    ubi_cost = ubi_summary.income_summary[1][1,:net_inc_indirect]
    println( "needs tax rise of $eq")
    net_cost = ubi_cost - base_cost
    println( "net_cost=$net_cost" )
    println( "taxrates $(sys.it.non_savings_rates)")
    println("ubi summary")
    CSV.write( "ubi_summary.income_summary.csv", ubi_summary.income_summary[1] )
    # pretty_table( ubi_summary.income_summary[1][1,:] )

end

@testset "Eq UBI With Wealth Tests" begin
    base = get_system(year=2023, scotland=true )
    sys = get_system(year=2023, scotland=true )
    sys.ubi.abolished = false
    sys.it.personal_allowance = 0.0
    make_ubi_pre_adjustments!( sys )
    base_res = do_one_run(
        settings,
        [base],
        obs )
    summary = summarise_frames!(base_res,settings)
    base_cost = summary.income_summary[1][1,:net_inc_indirect]
    
    eq = equalise( 
        eq_wealth_tax, 
        sys, 
        settings, 
        base_cost, 
        obs )
    sys.wealth.rates .+= eq
    println( "VAT change is $eq")
    ubi_res = do_one_run(
        settings,
        [sys],
        obs )

    
    ubi_summary = summarise_frames!(ubi_res,settings)
    ubi_cost = ubi_summary.income_summary[1][1,:net_inc_indirect]
   
    println( "needs tax rise of $eq")
    net_cost = ubi_cost - base_cost
    println( "net_cost=$net_cost" )
    println( "taxrates $(sys.wealth.rates.*100)%")
    println("ubi summary")
    CSV.write( "ubi_summary.income_summary_wealth.csv", ubi_summary.income_summary[1] )
    # pretty_table( ubi_summary.income_summary[1][1,:] )

end

@testset "Eq UBI With VAT" begin
    base = get_system(year=2023, scotland=true )
    sys = get_system(year=2023, scotland=true )
    sys.ubi.abolished = false
    # sys.it.personal_allowance = 0.0
    make_ubi_pre_adjustments!( sys )
    base_res = do_one_run(
        settings,
        [base],
        obs )
    summary = summarise_frames!(base_res,settings)
    base_cost = summary.income_summary[1][1,:net_inc_indirect]
    
    eq = equalise( 
        eq_all_vat, 
        sys, 
        settings, 
        base_cost, 
        obs )
    sys.indirect.vat.standard_rate += eq
    sys.indirect.vat.reduced_rate += eq
    sys.indirect.vat.assumed_exempt_rate += eq*0.5
    ubi_res = do_one_run(
        settings,
        [sys],
        obs )
    ubi_summary = summarise_frames!(ubi_res,settings)
    ubi_cost = ubi_summary.income_summary[1][1,:net_inc_indirect]
   
    net_cost = ubi_cost - base_cost
    println( "net_cost=$net_cost" )
    println( "taxrates $(sys.indirect.vat.standard_rate*100.0)%")
    println("ubi summary")
    CSV.write( "base_eq_summary.csv", summary.income_summary[1] )    
    CSV.write( "ubi_summary.income_summary_vat.csv", ubi_summary.income_summary[1] )
    # pretty_table( ubi_summary.income_summary[1][1,:] )
end
