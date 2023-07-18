using ArgCheck
using CSV
using DataFrames
using Observables
using StatsBase 
using Test

using ScottishTaxBenefitModel
using .Definitions
using .ExampleHelpers
using .HealthRegressions: get_health, create_health_indicator, summarise_sf12
using .ModelHousehold
using .HouseholdFromFrame: create_regression_dataframe
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
    # settings.poverty_line = make_poverty_line( results.hh[1], settings )
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
end # testset

@testset "big merged data" begin

    #=
    settings = Settings()
    
    sc_hh_dataset = CSV.File("$(settings.data_dir)/$(settings.household_name).tab" ) |> DataFrame
    sc_people_dataset = CSV.File("$(settings.data_dir)/$(settings.people_name).tab") |> DataFrame
    sc_data = create_regression_dataframe( sc_hh_dataset, sc_people_dataset )

    sc_data_ads = sc_data[sc_data.age .>=16,:]
    =#

    settings = get_all_uk_settings_2023()
    uk_hh_dataset = CSV.File("$(settings.data_dir)/$(settings.household_name).tab" ) |> DataFrame
    uk_people_dataset = CSV.File("$(settings.data_dir)/$(settings.people_name).tab") |> DataFrame
    uk_data = create_regression_dataframe( uk_hh_dataset, uk_people_dataset )
    uk_data_ads = uk_data[(uk_data.age .>=16).&(uk_data.gor_ni .== 0),:]
    nr,nc = size(uk_data)
    
    sys = [get_system(year=2022, scotland=true), get_system( year=2022, scotland=true )]    
    results = do_one_run( settings, sys, obs )
    ## actually 
    outf = summarise_frames!( results, settings )    

    #=
    nr2 = nr*2

    results[sys] = DataFrame( 
        hid=zeros(BigInt,nr2), 
        pid=zeros(Int,nr2), 
        sysno=zeros(Int,nr2), 
        
        data_year=zeros(Int,nr2), 
        quintile=zeros(Int,nr2),
        eqinc = zeros(Float64, nr2 ))

    hresults = DataFrame( 
        hid=zeros(BigInt,nr2), 
        pid=zeros(Int,nr2), 
        sysno=zeros(Int,nr2),         
        data_year=zeros(Int,nr2), 
        sf12 = zeros(Float64, nr2 ),
        sf6 = zeros(Float64, nr2 ),
        imputed_wealth = zeros(Float64, nr2 ))

    p = 0
    @time for h in eachrow(sc_data_ads)
            for sysno in 1:2
                p += 1
                results[p,:hid] = h.hid    
                results[p,:pid] = h.pid    
                results[p,:sysno] = sysno
                results[p,:data_year] = h.data_year
                results[p,:quintile] = rand(1:5)
                results[p,:eqinc] = log.(1000.0*rand())
                hresults[p,:hid] = h.hid    
                hresults[p,:pid] = h.pid    
                hresults[p,:sysno] = sysno
                hresults[p,:data_year] = h.data_year
            end
        end
    =#

    nc12 = Symbol.(intersect( names(uk_data), names(HealthRegressions.SFD12_REGRESSION_TR)))
    coefs12 = Vector{Float64}( HealthRegressions.SFD12_REGRESSION_TR[nc12] )
    nc6 = Symbol.(intersect( names(uk_data), names(HealthRegressions.SFD6_REGRESSION_TR)))
    coefs6 = Vector{Float64}( HealthRegressions.SFD6_REGRESSION_TR[nc6] )
    @time for sysno in 1:2        
        data_ads = innerjoin( 
            uk_data_ads, 
            results.indiv[sysno], on=[:data_year, :hid ],makeunique=true )
        data_ads.mlogbhc = log.(max.(1,data_ads.eq_bhc_net_income ))
        data_ads.quintile = ((results.indiv[sysno][!,:decile] .+1) .÷ 2)
        data_ads.q1mlog = (data_ads.quintile .== 1) .* data_ads.mlogbhc
        data_ads.q2mlog = (data_ads.quintile .== 2) .* data_ads.mlogbhc
        data_ads.q3mlog = (data_ads.quintile .== 3) .* data_ads.mlogbhc
        data_ads.q4mlog = (data_ads.quintile .== 4) .* data_ads.mlogbhc
        data_ads.q5mlog = (data_ads.quintile .== 5) .* data_ads.mlogbhc
        for h in eachrow(sc_data_ads)
            pslot = get_slot_for_person( h.pid, h.data_year )
            results.indiv[sysno][:sf12] = 
                HealthRegressions.rm2( nc12, h, coefs12 )
            results.indiv[sysno][:sf6] = 
                HealthRegressions.rm2( nc6, h, coefs6 )
            results.indiv[sysno][:has_mental_health_problem] = -1
            results.indiv[sysno][:qualys] = -1
            results.indiv[sysno][:life_expectancy] = -1
        end
        println(summarystats(results.indiv[sysno][!,:sf12]))
        println(summarystats(results.indiv[sysno][!,:sf6]))
    end    
end