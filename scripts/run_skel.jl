#
# Just something I can do quick runs with independently
# of the test code.
#

using CSV
using DataFrames
using StatsBase
using BenchmarkTools
using PrettyTables
using Observables
using ScottishTaxBenefitModel
using ScottishTaxBenefitModel.Definitions
using ScottishTaxBenefitModel.GeneralTaxComponents
using ScottishTaxBenefitModel.STBParameters
using ScottishTaxBenefitModel.Runner: do_one_run
using ScottishTaxBenefitModel.RunSettings
using .Utils
using .Monitor: Progress
using .ExampleHelpers
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames!, make_gain_lose

include( "$(TEST_DIR)/testutils.jl")

settings = Settings()
tot = 0
# observer = Observer(Progress("",0,0,0))
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
    println(tot)
end

settings.means_tested_routing = modelled_phase_in
settings.run_name="run-$(settings.means_tested_routing)-$(date_string())"

sys1 = get_system( year=2022, scotland=true)
sys2 = get_system( year=2022, scotland=true )
sys2.ni.primary_class_1_rates = [0,0,0.16,0.0325]

tot = 0
results = do_one_run( settings, [sys1,sys2], obs )
h1 = results.hh[1]
settings.poverty_line = make_poverty_line( results.hh[1], settings )
dump_frames( settings, results )
println( "poverty line = $(settings.poverty_line)")
outf = summarise_frames!( results, settings )
println( outf )
gl = make_gain_lose( results.hh[1], results.hh[2], settings )
    
