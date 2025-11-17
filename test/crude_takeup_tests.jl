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
using .CrudeTakeup
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames!, make_gain_lose



@testset "Takeup Runs" begin
    sys = [
        get_default_system_for_fin_year(2023; scotland=true), 
        get_default_system_for_fin_year( 2023; scotland=true )]
    settings = Settings()
    settings.run_name="run-w-takeup-correction"
    settings.do_dodgy_takeup_corrections = true
    summaries,results,settings =do_basic_run( settings, sys; reset=false )
    dump_summaries( settings, summaries )
    ct=CSV.File(
        joinpath( settings.output_dir, basiccensor( settings.run_name ), "income_summary_1.csv"))|>
        DataFrame
    settings.do_dodgy_takeup_corrections = false
    settings.run_name="run-no-takeup-correction"
    summaries,results,settings=do_basic_run( settings, sys; reset=false )
    dump_summaries( settings, summaries )
    @show settings.output_dir
    nt=CSV.File(
        joinpath( settings.output_dir,  basiccensor( settings.run_name ), "income_summary_1.csv"))|>
        DataFrame
    pretty_table(ct)
    pretty_table(nt)
    # @test ct.child_benefit[1]/ nt.child_benefit[1] ≈ 1
    # @test ct.child_tax_credit[1]/ nt.child_tax_credit[1] < 1 # roughly 0.67
    # @test ct.universal_credit[1]/ nt.universal_credit[1] < 1 # roughly 0.8
end