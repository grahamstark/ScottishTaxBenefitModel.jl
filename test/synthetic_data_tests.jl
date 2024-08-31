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
using .Utils
using .Monitor: Progress
using .ExampleHelpers
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames!, make_gain_lose



BenchmarkTools.DEFAULT_PARAMETERS.seconds = 120
BenchmarkTools.DEFAULT_PARAMETERS.samples = 2

tot = 0

settings = Settings()

# observer = Observer(Progress("",0,0,0))
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)

    tot += p.step
    println(tot)
end


@testset "basic run timing" begin
    settings = Settings()
    settings.data_source = SyntheticSource 
    settings.do_legal_aid = false
    settings.skiplist = "skiplist"
    lower_multiple :: Real = 0.10 # these values can be narrowed somewhat, to around 0.25-4.7
    upper_multiple :: Real = 10.0

    settings.run_name="run-$()-$(date_string())"
    sys = [
        get_default_system_for_fin_year(2024; scotland=true), 
        get_default_system_for_fin_year( 2024; scotland=true )]
    tot = 0

    summary, results, settings = do_basic_run( settings, sys; reset = true )
    h1 = results.hh[1]
end
