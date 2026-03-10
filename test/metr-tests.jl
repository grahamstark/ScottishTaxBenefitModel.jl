using Test
using CSV
using ArgCheck
using DataFrames
using StatsBase
using BenchmarkTools
using PrettyTables
using Observables
using ScottishTaxBenefitModel
using ScottishTaxBenefitModel.GeneralTaxComponents
using ScottishTaxBenefitModel.STBParameters
using ScottishTaxBenefitModel.Runner: do_one_run
using ScottishTaxBenefitModel.RunSettings
using .STBOutput
using .Utils
using .Monitor: Progress
using .ExampleHelpers
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames!, make_gain_lose,
    dump_summaries


@testset "MR test" begin

    settings = Settings()
    settings.do_marginal_rates = true
    settings.dump_frames = true
    @time settings.num_households, settings.num_people, nhh2 = FRSHouseholdGetter.initialise( settings; reset=false )

    sys = [
        get_default_system_for_fin_year(2026; scotland=true),
        get_default_system_for_fin_year( 2026; scotland=true )]

    @time begin
        sys = [get_system(year=2026, scotland=true), get_system( year=2026, scotland=true )]
        summary, results, settings = do_basic_run( settings, sys, reset=false )
        println( summary.metrs[1] )
    end
end

@testset "hist tests " begin

    d = DataFrame( hid = collect(1:400), metr = vcat(fill(100.0,100),fill(20.0,50), fill(50.01,25), fill(49.999,25), zeros(200)), weight=ones(400))
    histd = STBOutput.metrs_to_hist( d; breaks=[-Inf, 0.0000, 0.0001, 10.0, 20.0, 30.0, 50.0, 80.0, 100.0, 100.001, Inf] )
    @show histd
    histd2 = STBOutput.metrs_to_hist( d; )
    @show histd2
    t = DataFrame( metr=histd2.hist.weights, label=METR_TABLE_BREAK_LABELS )
    pretty_table( t )
    @test t[t.label .== "20-29.99",:metr][1] == 50
    @test t[t.label .== "Zero",:metr][1] == 200
    @test t[t.label .== "50-59.99",:metr][1] == 25
    @test t[t.label .== "40-49.99",:metr][1] == 25
    @test t[t.label .== "100",:metr][1] == 100
    @test t[t.label .== "10-19.99",:metr][1] == 0
end
