using ArgCheck
using CSV
using DataFrames
using Observables
using StatsBase 
using Test

using ScottishTaxBenefitModel
using .Definitions
using .ExampleHelpers
using .FRSHouseholdGetter
using .HealthRegressions: get_health, create_health_indicator, summarise_sf12, do_health_regressions!
using .GeneralTaxComponents:WEEKS_PER_MONTH
using .ModelHousehold
using .HouseholdFromFrame
using .Monitor: Progress
using .Results
using .Runner: do_one_run
using .RunSettings
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames!, make_gain_lose

settings = Settings()
obs = Observable(Progress(settings.uuid,"thing",0,0,0,0))
tot = 0
of = on(obs) do p
    global tot
    println(p)    
    tot += p.step
    println(tot)
end

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
    ## settings = Settings()
    settings = get_all_uk_settings_2023()
    @time settings.num_households, settings.num_people, nhh2 = initialise( settings; reset=true )
    # Actually, `eq_bhc_net_income` is the default anyway.
    settings.requested_threads = 4
    settings.ineq_income_measure = eq_bhc_net_income
    # FIXME 2019->2023
    sys = [get_system(year=2023, scotland=false), get_system( year=2023, scotland=false )]    
    summary = []
    results = do_one_run( settings, sys, obs )
    ## actually 
    outf = summarise_frames!( results, settings )
    quint_count = fill( 0.0, 5, 2 )
    sf12s = fill( 0.0, 100_000, 2 )
    @time for sysno in 1:2
        hhr = results.hh[sysno]
        quintiles = HealthRegressions.get_quintiles( outf.deciles[sysno][:,3])
        ncases = 0
        for hno in 1:settings.num_households
            hh = FRSHouseholdGetter.get_household( hno )
            if hh.region !== Northern_Ireland
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
        CSV.write( "/home/graham_s/tmp/sf12_output_v1.csv", outps )
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
end # testset

#=
function do_health_regressions!( results :: NamedTuple, settings :: Settings ) :: Array{NamedTuple}
    uk_data = get_regression_dataset() # alias
    uk_data_ads = uk_data[(uk_data.from_child_record .== 0).&(uk_data.gor_ni.==0),:]
    sys = [get_system(year=2023, scotland=false), get_system( year=2023, scotland=false )]    
    results = do_one_run( settings, sys, obs )
    outf = summarise_frames!( results, settings )    
    summaries = []
    nc12 = Symbol.(intersect( names(uk_data), names(HealthRegressions.SFD12_REGRESSION_TR)))
    coefs12 = Vector{Float64}( HealthRegressions.SFD12_REGRESSION_TR[nc12] )
    nc6 = Symbol.(intersect( names(uk_data), names(HealthRegressions.SFD6_REGRESSION_TR)))
    coefs6 = Vector{Float64}( HealthRegressions.SFD6_REGRESSION_TR[nc6] )
    nsys = size( results.indiv )[1]
    @time for sysno in 1:nsys
        data_ads = innerjoin( 
            uk_data_ads, 
            results.indiv[sysno], on=[:data_year, :hid ], makeunique=true )
        data_ads.mlogbhc = log.(max.(1,WEEKS_PER_MONTH.*data_ads.eq_bhc_net_income ))
        data_ads.quintile = ((data_ads.decile .+1) .÷ 2)
        data_ads.q1mlog = (data_ads.quintile .== 1) .* data_ads.mlogbhc
        data_ads.q2mlog = (data_ads.quintile .== 2) .* data_ads.mlogbhc
        data_ads.q3mlog = (data_ads.quintile .== 3) .* data_ads.mlogbhc
        data_ads.q4mlog = (data_ads.quintile .== 4) .* data_ads.mlogbhc
        data_ads.q5mlog = (data_ads.quintile .== 5) .* data_ads.mlogbhc
        k = 0
        for h in eachrow(data_ads)
            k += 1
            pslot = get_slot_for_person( BigInt(h.pid), h.data_year )
            sf12 = HealthRegressions.rm2( nc12, h, coefs12; lagvalue = 0.526275 )            
            results.indiv[sysno][pslot,:sf12] = sf12
            sf6 = HealthRegressions.rm2( nc6, h, coefs6; lagvalue = 0.5337817 )
            results.indiv[sysno][pslot,:sf6] = sf6                
            results.indiv[sysno][pslot,:has_mental_health_problem] = 
                sf12 <= settings.sf12_depression_limit 
            results.indiv[sysno][pslot,:qualys] = -1
            results.indiv[sysno][pslot,:life_expectancy] = -1
        end
        summary = summarise_sf12( results.indiv[sysno][results.indiv[sysno].sf12 .> 0,:], settings )
        push!( summaries, summary )
    end       
    return summaries
end
=# 
@testset "big merged data" begin
    settings = get_all_uk_settings_2023()
    @time settings.num_households, settings.num_people, nhh2 = initialise( settings; reset=true )
    uk_data = get_regression_dataset() # alias
    uk_data_ads = uk_data[(uk_data.from_child_record .== 0).&(uk_data.gor_ni.==0),:]
    sys = [get_system(year=2023, scotland=false), get_system( year=2023, scotland=false )]    
    results = do_one_run( settings, sys, obs )
    outf = summarise_frames!( results, settings )    

    @time summaries = do_health_regressions!( results, settings )
    #=
    nc12 = Symbol.(intersect( names(uk_data), names(HealthRegressions.SFD12_REGRESSION_TR)))
    coefs12 = Vector{Float64}( HealthRegressions.SFD12_REGRESSION_TR[nc12] )
    nc6 = Symbol.(intersect( names(uk_data), names(HealthRegressions.SFD6_REGRESSION_TR)))
    coefs6 = Vector{Float64}( HealthRegressions.SFD6_REGRESSION_TR[nc6] )
    @time for sysno in 1:2        
        data_ads = innerjoin( 
            uk_data_ads, 
            results.indiv[sysno], on=[:data_year, :hid ], makeunique=true )
        data_ads.mlogbhc = log.(max.(1,WEEKS_PER_MONTH.*data_ads.eq_bhc_net_income ))
        data_ads.quintile = ((data_ads.decile .+1) .÷ 2)
        data_ads.q1mlog = (data_ads.quintile .== 1) .* data_ads.mlogbhc
        data_ads.q2mlog = (data_ads.quintile .== 2) .* data_ads.mlogbhc
        data_ads.q3mlog = (data_ads.quintile .== 3) .* data_ads.mlogbhc
        data_ads.q4mlog = (data_ads.quintile .== 4) .* data_ads.mlogbhc
        data_ads.q5mlog = (data_ads.quintile .== 5) .* data_ads.mlogbhc
        k = 0
        for h in eachrow(data_ads)
            k += 1
            pslot = get_slot_for_person( BigInt(h.pid), h.data_year )
            sf12 = HealthRegressions.rm2( nc12, h, coefs12; lagvalue = 0.526275 )            
            results.indiv[sysno][pslot,:sf12] = sf12
            sf6 = HealthRegressions.rm2( nc6, h, coefs6; lagvalue = 0.5337817 )
            results.indiv[sysno][pslot,:sf6] = sf6                
            results.indiv[sysno][pslot,:has_mental_health_problem] = 
                sf12 <= settings.sf12_depression_limit 
            results.indiv[sysno][pslot,:qualys] = -1
            results.indiv[sysno][pslot,:life_expectancy] = -1
        end

        println(summarystats(results.indiv[sysno][results.indiv[sysno].sf12 .> 0,:sf12]))
        println(summarystats(results.indiv[sysno][results.indiv[sysno].sf6 .> 0,:sf6]))        

        summary = summarise_sf12( results.indiv[sysno][results.indiv[sysno].sf12 .> 0,:], settings )
        CSV.write( "/home/graham_s/tmp/sf12_output_v2.csv", results.indiv[sysno][results.indiv[sysno].sf6 .> 0, :])
        println( summary )
    end    
    =#
    println( summaries[1])
    println( summaries[2])
end