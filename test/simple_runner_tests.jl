using Test
using CSV
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
    dump_frames, summarise_frames, make_gain_lose

settings = Settings()

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 120
BenchmarkTools.DEFAULT_PARAMETERS.samples = 2


function basic_run( ; print_test :: Bool, mtrouting :: MT_Routing )
    settings.means_tested_routing = mtrouting
    settings.run_name="run-$(mtrouting)-$(date_string())"
    sys = [get_system(scotland=false), get_system( scotland=true )]
    observer = Observer(Monitor("",0,0,0))
    tot = 0
    of = on(observer) p do
        println(p)
        tot += p.step
        println(t)
    end
    results = do_one_run( settings, sys, observer )
    h1 = results.hh[1]
    pretty_table( h1[:,[:weighted_people,:bhc_net_income,:eq_bhc_net_income,:ahc_net_income,:eq_ahc_net_income]] )
    settings.poverty_line = make_poverty_line( results.hh[1], settings )
    dump_frames( settings, results )
    println( "poverty line = $(settings.poverty_line)")
    outf = summarise_frames( results, settings )
    println( outf )
    gl = make_gain_lose( results.hh[1], results.hh[2], settings )
    println(gl)
end 



@testset "MR test" begin
    @time begin
        observer = Observer(Monitor("",0,0,0))
        tot = 0
        of = on(observer) p do
            println(p)
            tot += p.step
            println(t)
        end
    
        settings.means_tested_routing = modelled_phase_in
        settings.do_marginal_rates = true
        settings.dump_frames = true
        sys = [get_system(scotland=false), get_system( scotland=true )]
        results = do_one_run( settings, sys, observer )
        settings.poverty_line = make_poverty_line( results.hh[1], settings )
        outf = summarise_frames( results, settings )
        println( outf.metrs[1] )
    end
end


@testset "basic run timing" begin
    for mt in instances( MT_Routing )
        println( "starting run using $mt routing")
        @time basic_run( print_test=true, mtrouting = mt )
    end
    # @benchmark frames = 
    # print(t)
end

@testset "thread test" begin
    # 42.531500 53 secs
    settings.requested_threads = 4
    @time basic_run( print_test=true, mtrouting = modelled_phase_in )

    settings.do_marginal_rates = false
    @time basic_run( print_test=true, mtrouting = modelled_phase_in )
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