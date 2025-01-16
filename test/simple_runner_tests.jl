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

# FIXME DELETE THIS AND USE THE ONE IN testutils
function basic_run( ; print_test :: Bool, mtrouting :: MT_Routing )
    settings = Settings()
    settings.means_tested_routing = mtrouting
    settings.run_name="run-$(mtrouting)-$(date_string())"
    sys = [
        get_default_system_for_fin_year(2023; scotland=true), 
        get_default_system_for_fin_year( 2023; scotland=true )]
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


@testset "Extreme Income Changes from Flat tax" begin    
    settings = Settings()
    sys = [
        get_default_system_for_fin_year(2023; scotland=true), 
        get_default_system_for_fin_year( 2023; scotland=true )]
    
    settings.do_marginal_rates = false
    # flat tax - 
    @time settings.num_households, settings.num_people, nhh2 = initialise( settings; reset=true )
    sys[2].it.non_savings_basic_rate = 1
    sys[2].it.non_savings_rates = [0.19]
    sys[2].it.non_savings_thresholds = [9999999999999999999999.999]
    results = do_one_run( settings, sys, obs )
    nhhs = size(results.hh[1],1)
    check = String(rand('a':'z',30))
    fname = "$(settings.output_dir)/$(check)_hh.txt"
    for hno in 1:nhhs
        r1 = results.hh[1][hno,:]
        r2 = results.hh[1][hno,:]
        Δ = abs(r1.eq_bhc_net_income-r2.eq_bhc_net_income)
        if Δ > 1000.0
            println( "flat tax change of Δ for hh $(r1.hid) year $(r1.year)" )
            
        end
    end
end

@testset "MR test" begin
    @time begin
        settings = Settings()
        settings.means_tested_routing = modelled_phase_in
        settings.do_marginal_rates = true
        settings.dump_frames = true
        sys = [get_system(year=2024, scotland=true), get_system( year=2024, scotland=true )]
        results = do_one_run( settings, sys, obs )
        settings.poverty_line = make_poverty_line( results.hh[1], settings )
        outf = summarise_frames!( results, settings )
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
    settings = Settings()
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