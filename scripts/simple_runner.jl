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

function do_basic_run( ; print_test :: Bool, mtrouting :: MT_Routing )
    settings = Settings()
    settings.means_tested_routing = mtrouting
    settings.run_name="run-$(mtrouting)-$(date_string())"
    settings.requested_threads = 4
    settings.do_legal_aid = false
    sys = [
        get_default_system_for_fin_year(2024; scotland=true), 
        get_default_system_for_fin_year( 2024; scotland=true )]
    tot = 0
    results = do_one_run( settings, sys, obs )
    # h1 = results.hh[1]
    # pretty_table( h1[:,[:weighted_people,:bhc_net_income,:eq_bhc_net_income,:ahc_net_income,:eq_ahc_net_income]] )
    settings.poverty_line = make_poverty_line( results.hh[1], settings )
    dump_frames( settings, results )
    println( "poverty line = $(settings.poverty_line)")
    outf = summarise_frames!( results, settings )
    println( outf )
    gl = make_gain_lose( results.hh[1], results.hh[2], settings )
    return (outf,gl)
end 

#=
if print_test
    summary_output = summarise_results!( results=results, base_results=base_results )
    print( "   deciles = $( summary_output.deciles)\n\n" )
    print( "   poverty_line = $(summary_output.poverty_line)\n\n" )
    print( "   inequality = $(summary_output.inequality)\n\n" )        
    print( "   poverty = $(summary_output.poverty)\n\n" )
    print( "   gainlose_by_sex = $(summary_output.gainlose_by_sex)\n\n" )
    print( "   gainlose_by_thing = $(summary_output.gainlose_by_thing)\n\n" )
    print( "   metr_histogram= $(summary_output.metr_histogram)\n\n")
    println( "SUMMARY OUTPUT")
    println( summary_output )
    println( "as JSON")
    println( JSON.json( summary_output ))
end

=#