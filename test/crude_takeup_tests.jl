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




# FIXME DELETE THIS AND USE THE ONE IN testutils
function do_basic_run( sys, settings :: Settings; print_test :: Bool )
    tot = 0
    results = do_one_run( settings, sys, obs )
    h1 = results.hh[1]
    pretty_table( h1[:,[:weighted_people,:bhc_net_income,:eq_bhc_net_income,:ahc_net_income,:eq_ahc_net_income]] )
    settings.poverty_line = make_poverty_line( results.hh[1], settings )
    dump_frames( settings, results )
    println( "poverty line = $(settings.poverty_line)")
    outf = summarise_frames!( results, settings )
    println( outf )
    gl = make_gain_lose( results.hh[1], results.hh[2], settings )
    # println(gl)
    # println( outf )
    return (outf,gl)
end 

@testset "Takeup Runs" begin
    sys = [
        get_default_system_for_fin_year(2023; scotland=true), 
        get_default_system_for_fin_year( 2023; scotland=true )]
    settings = Settings()
    settings.run_name="run-w-takeup-correction"
    settings.do_dodgy_takeup_corrections = true
    summaries2,gainlose2 =do_basic_run( sys, settings; print_test=true )
    settings.do_dodgy_takeup_corrections = false
    settings.run_name="run-no-takeup-correction"
    summaries,gainlose=do_basic_run( sys, settings; print_test=true )

    ct=CSV.File(
        joinpath( settings.output_dir, "run_w_takeup_correction_2_income-summary.csv")|>
        DataFrame
    nt=CSV.File(
        joinpath( settings.output_dir, "run_no_takeup_correction_2_income-summary.csv")|>
        DataFrame
    @test ct.child_benefit[1]/ nt.child_benefit[1] ≈ 1
    @test ct.child_tax_credit[1]/ nt.child_tax_credit[1] < 1 # roughly 0.67
    @test ct.universal_credit[1]/ nt.universal_credit[1] < 1 # roughly 0.8
end