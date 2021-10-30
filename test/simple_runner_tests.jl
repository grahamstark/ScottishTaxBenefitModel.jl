using Test
using CSV
using DataFrames
using StatsBase
using BenchmarkTools
using PrettyTables

using ScottishTaxBenefitModel
using ScottishTaxBenefitModel.GeneralTaxComponents
using ScottishTaxBenefitModel.STBParameters
using ScottishTaxBenefitModel.Runner: do_one_run
using ScottishTaxBenefitModel.RunSettings: Settings, MT_Routing
using .Utils
using .ExampleHelpers
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames, add_gain_lose!

settings = Settings()

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 120
BenchmarkTools.DEFAULT_PARAMETERS.samples = 2


function basic_run( ; print_test :: Bool, mtrouting :: MT_Routing  )
    settings.means_tested_routing = mtrouting
    settings.run_name="run-$(mtrouting)-$(date_string())"
    sys = [get_system(scotland=false), get_system( scotland=true )]
    results = do_one_run( settings, sys )
    h1 = results.hh[1]
    pretty_table( h1[:,[:weighted_people,:bhc_net_income,:eq_bhc_net_income,:ahc_net_income,:eq_ahc_net_income]] )
    settings.poverty_line = make_poverty_line( results.hh[1], settings )
    dump_frames( settings, results )
    println( "poverty line = $(settings.poverty_line)")
    outf = summarise_frames( results, settings )
    println( outf )
    gl = add_gain_lose!( results.hh[1], results.hh[2], settings )
    println(sum(gl.gainers))
end 

@testset "basic run timing" begin
    for mt in instances( MT_Routing )
        println( "starting run using $mt routing")
        @time basic_run( print_test=true, mtrouting = mt )
    end
    # @benchmark frames = 
    # print(t)
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