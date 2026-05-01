using Test
using CSV
using ArgCheck
using DataFrames
using Dates
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
    dump_frames, summarise_frames!, make_gain_lose,
    dump_summaries

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 120
BenchmarkTools.DEFAULT_PARAMETERS.samples = 2

tot = 0

function getSet()
    settings = Settings()
    settings.run_name = basiccensor( "Simple Runner Tests Output : $(Dates.now())" )
    settings.do_marginal_rates = true
    settings.dump_frames = true
    settings.means_tested_routing = uc_full
    return settings
end


function make_systems()
    sys1 = get_default_system_for_fin_year(2026; scotland=true)
    sys2 = get_default_system_for_fin_year( 2026; scotland=true )
    # some arbitrary changes
    sys2.it.non_savings_thresholds .+= 0.02
    sys2.it.personal_allowance *= 0.8
    sys2.uc.taper -= 0.02
    [sys1,sys2]
end

const SYSTEMS = make_systems()

@time settings.num_households, settings.num_people, nhh2 = FRSHouseholdGetter.initialise( settings; reset=true )

# observer = Observer(Progress("",0,0,0))
tot = 0
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
    println(tot)
end

@testset "basic run timing" begin
    settings =  getSet()
    for mt in instances( MT_Routing )
        println( "starting run using $mt routing")
        settings.run_name = basiccensor( "Simple Runner Tests Output : $(Dates.now()) MT Transition Type $mt" )
        settings.means_tested_routing = mt
        @time summary, results, settings = do_basic_run( settings, SYSTEMS )
    end
end

@testset "thread test" begin
    settings = getSet()
    settings.requested_threads = 4
    @time summary, results, settings = do_basic_run( settings, SYSTEMS )
end
