using ArgCheck
using Observables
using StatsBase 
using Test

using ScottishTaxBenefitModel
using .Definitions
using .ExampleHelpers
using .HealthRegressions: get_health, create_health_indicator, summarise_sf12
using .ModelHousehold
using .Monitor: Progress
using .Results
using .Runner: do_one_run
using .RunSettings
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames!, make_gain_lose

# observer = Observer(Progress("",0,0,0))


@testset "get_death_prob" begin
   

end

@testset "get_sfd6 Examples" begin
    # just make something up pro. tem.
    quintiles = [100.0,200,300,400,50000000]
    sf12s = fill( 0.0, 0 )
    for (hht,hh) in get_all_examples()
        for inc in quintiles
            inc -= 1
            quintile = HealthRegressions.q_from_inc( quintiles, inc )
            sf12 = get_health( hh = hh, eq_bhc_net_income=inc, quintile=quintile )
            for (pid,sf) in sf12
                @test 0 < sf < 100
                pers = hh.people[pid]
                push!( sf12s, sf )
                println( "income $inc hh $hht age $(pers.age) sex $(pers.sex) sf $sf")
            end # people in hh
        end # quintiles
    end # example loop
    println(StatsBase.summarystats( sf12s ))
end

    
@testset "get_sfd6 Live Data" begin
    settings = Settings()
    # Actually, `eq_bhc_net_income` is the default anyway.
    settings.requested_threads = 4
    settings.ineq_income_measure = eq_bhc_net_income
    obs = Observable( Progress(settings.uuid,"",0,0,0,0))
    tot = 0
    of = on(obs) do p
        println(p)    
        tot += p.step
        println(tot)
    end
    
    # FIXME 2019->2023
    sys = [get_system(year=2022, scotland=true), get_system( year=2022, scotland=true )]    
    summary = []
    results = do_one_run( settings, sys, obs )
    ## actually 
    settings.poverty_line = make_poverty_line( results.hh[1], settings )
    outf = summarise_frames!( results, settings )
    @time settings.num_households, settings.num_people, nhh2 = initialise( settings; reset=false )
    quint_count = fill( 0.0, 5, 2 )
    sf12s = fill( 0.0, 100_000, 2 )
    @time for sysno in 1:2
        hhr = results.hh[sysno]
        quintiles = HealthRegressions.get_quintiles( outf.deciles[sysno][:,3])
        ncases = 0
        for hno in 1:settings.num_households
            hh = FRSHouseholdGetter.get_household( hno )
            inc = hhr[ (hhr.hid.== hh.hid) .& (hhr.data_year .== hh.data_year), :eq_bhc_net_income][1]
            quintile = HealthRegressions.q_from_inc( quintiles, inc )
            quint_count[quintile,sysno] += hh.weight*num_people(hh)
            if sysno == 2
                inc *= 2.0
            end
            sf12 = get_health( hh = hh, eq_bhc_net_income=inc, quintile=quintile )
            for (pid,sf) in sf12
                ncases += 1
                sf12s[ncases,sysno] = sf
            end
        end
        push!( summary, StatsBase.summarystats( sf12s[1:ncases, sysno] ))
    end
    println( summary )
    println( quint_count )
    
    for sysno in 1:2
        @time outps = create_health_indicator( 
            results.hh[sysno], 
            outf.deciles[sysno], 
            obs,
            settings )
        sum2 = StatsBase.summarystats( outps[!,:sf12] )
        println(sum2)
        pop = sum( outps[ !, :weight ])
        depressed = sum( outps[outps.sf12 .<= settings.sf12_depression_limit, :weight ])
        dp = 100*depressed/pop
        println( "num depressed $depressed out of $pop ($(dp)%)")   
        w = weights(outps[!,:weight])
        sf = outps[!,:sf12]
        range = 0.025:0.025:1
        dist = quantile( sf , w, range ) 
        println( "20th groups $(dist)")
        hist = fit(Histogram, sf, w, 0:2:100 )
        println( "histogram $hist")

        println( summarise_sf12( outps, settings ))
    end
end