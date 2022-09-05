using Test
using CSV
using DataFrames
using StatsBase
using BenchmarkTools
using PrettyTables
using Observables
using ScottishTaxBenefitModel
using .GeneralTaxComponents
using .STBParameters
using .Runner: do_one_run
using .RunSettings
using .SingleHouseholdCalculations
using .Utils
using .Intermediate
using .Monitor: Progress
using .ExampleHelpers
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames, make_gain_lose
using .Expenditure
using StatsBase

settings = Settings()

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 120
BenchmarkTools.DEFAULT_PARAMETERS.samples = 2

tot = 0

# observer = Observer(Progress("",0,0,0))
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)

    tot += p.step
    println(tot)
end



@testset "Expenditure Tests, Live Data" begin
    @time begin
        settings.means_tested_routing = modelled_phase_in
        settings.do_marginal_rates = false
        settings.dump_frames = false
        sys = [get_system(year=2022, scotland=true), get_system( year=2022,scotland=true )]
        nhhs,npeople = init_data()
        share = zeros( nhhs,2 )
        for hno in 1:nhhs
            hh = get_household(hno)
            # dup but can't be helped
            intermed =  make_intermediate( 
                hh, 
                sys[1].hours_limits, 
                sys[1].age_limits, 
                sys[1].child_limits )
            res = do_one_calc( hh, sys[1], settings )
            fres = impute_fuel( res, hh, intermed, 1.04, 1.0, 1.0, 2023 )
            share[hno,1] = fres.pred_share
            # 20% increase
            fres = impute_fuel( res, hh, intermed, 2.08, 1.1, 1.1, 2023 )
            share[hno,2] = fres.pred_share
            
            println( fres )
            @test fres.pred_share >= 0
            @test fres.pred_share < 1
        end
        # println( share )
        println( summarystats( share[share[:,1] .> 0,1] ))
        println( summarystats( share[share[:,2] .> 0,2] ))
    end
end

