using Test
using CSV
using ArgCheck
using DataFrames
using StatsBase
using BenchmarkTools
using PrettyTables
using StatsBase
using Observables

using ScottishTaxBenefitModel
using .GeneralTaxComponents
using .STBParameters
using .Runner: do_one_run
using .RunSettings
using .Definitions
using .Utils

using .STBOutput
using .Utils
using .Monitor: Progress
using .ExampleHelpers
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames!, make_gain_lose,
    dump_summaries

#=
@testset "MR test" begin

    settings = Settings()
    settings.do_marginal_rates = true
    settings.dump_frames = true
    @time settings.num_households, settings.num_people, nhh2 = FRSHouseholdGetter.initialise( settings; reset=false )

    sys = [
        get_default_system_for_fin_year(2026; scotland=true),
        get_default_system_for_fin_year( 2026; scotland=true )]
    sys[2].it.non_savings_rates .+= 1
    @time begin
        summary, results, settings = do_basic_run( settings, sys, reset=false )
        println( summary.metrs[1] )
    end
end
=#

@testset "hist tests " begin
    d = DataFrame(
        hid = collect(1:400),
        metr = vcat(fill(100.0,100),fill(20.0,50), fill(50.01,25), fill(49.999,25), zeros(100), fill(missing,100)),
        weight=ones(400))
    #=
    histd = STBOutput.metrs_to_hist( d,d; breaks=METR_TABLE_BREAKS )
    @show histd
    histd2 = STBOutput.metrs_to_hist( d,d; )
    @show histd2
    =#
    d.metr_band = get_metr_band.( d.metr )
    d.short_metr_band = sh_get_metr_band.( d.metr )
    # median_income = median( d.metr, Weights( d.weight ))
    # just for devilment
    # d.poverty_state = get_poverty_state.( d.metr, median_income )

    m, row_levs, col_levs, examples = make_crosstab( d.metr_band, d.metr_band; weights=Weights(d.weight), max_examples = 3)
    @show m row_levs col_levs examples size(m)[1]
    # @test length( examples ) == 3
    @test size(m)[1] == length( row_levs )

    #=
    t = DataFrame( metr=histd2.hist.weights, label=METR_TABLE_BREAK_LABELS )
    pretty_table( t )
    @test t[t.label .== "20-29.99",:metr][1] == 50
    @test t[t.label .== "Zero",:metr][1] == 200
    @test t[t.label .== "50-59.99",:metr][1] == 25
    @test t[t.label .== "40-49.99",:metr][1] == 25
    @test t[t.label .== "100",:metr][1] == 100
    @test t[t.label .== "10-19.99",:metr][1] == 0
    =#
end

@testset "MR Classifications" begin
    @test METR_TABLE_BREAK_LABELS[Int(get_metr_band(0))] == "Zero"
    @test METR_TABLE_BREAK_LABELS[Int(get_metr_band(missing))] == "Not Computed"
    @test METR_TABLE_BREAK_LABELS[Int(get_metr_band(100))] == "100"
    @test METR_TABLE_BREAK_LABELS[Int(get_metr_band(101))] == "Above 100"
    @test METR_TABLE_BREAK_LABELS[Int(get_metr_band(-101))] == "Less than zero"
    @test SHORT_METR_TABLE_BREAK_LABELS[Int(sh_get_metr_band(0))] == "Zero/Below Zero"
    @test SHORT_METR_TABLE_BREAK_LABELS[Int(sh_get_metr_band(missing))] == "Not Computed"
    @test SHORT_METR_TABLE_BREAK_LABELS[Int(sh_get_metr_band(100))] ==  "90 and above"
    @test SHORT_METR_TABLE_BREAK_LABELS[Int(sh_get_metr_band(101))] ==  "90 and above"
    @test SHORT_METR_TABLE_BREAK_LABELS[Int(sh_get_metr_band(-101))] == "Zero/Below Zero"

end
