using ArgCheck
using Observables
using StatsBase 
using Test

using ScottishTaxBenefitModel
using .Definitions
using .ExampleHelpers
using .HealthRegressions: get_sf_6d
using .ModelHousehold
using .Monitor: Progress
using .Results
using .Runner: do_one_run
using .RunSettings
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames!, make_gain_lose

# observer = Observer(Progress("",0,0,0))


function get_quintiles( decs :: Vector )::Vector
    @argcheck size(decs)[1] == 10
    quintiles = fill(0.0,5)
    q = 0
    for i in 2:2:10
        q += 1
        quintiles[q] = decs[i]
    end
    @assert size( quintiles )[1] == 5
    quintiles
end

function q_from_inc( thresh :: Vector, inc :: Real )::Int
    n = size(thresh)[1]
    for i in 1:n
        if i <= thresh[i]
            return i;
        end
    end
    @assert false "got to end shouldn't happen"
end



@testset "get_death_prob" begin
   

end

@testset "get_sfd6 Examples" begin
    # just make something up pro. tem.
    quintiles = [100.0,200,300,400,50000000]
    sf6s = fill(0.0, 0 )
    for (hht,hh) in get_all_examples()
        for inc in quintiles
            inc -= 1
            quintile = q_from_inc( quintiles, inc )
            sf6 = get_sf_6d( hh = hh, eq_bhc_net_income=inc, quintile=quintile )
            for (pid,sf) in sf6
                @test 0 < sf < 1
                pers = hh.people[pid]
                push!( sf6s, sf )
                println( "income $inc hh $hht age $(pers.age) sex $(pers.sex) sf $sf")
            end # people in hh
        end # quintiles
    end # example loop
    println(StatsBase.summarystats( sf6s ))
end

    
@testset "get_sfd6 Live Data" begin
    settings = Settings()
    # Actually, `eq_bhc_net_income` is the default anyway.
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
    @time settings.num_households, settings.num_people, nhh2 = initialise( settings; reset=true )
    quintiles = []
    sf6s = fill( 0.0 ,100_000, 2 )
    for sysno in 1:2
        hhr = results.hh[sysno]
        quintiles = get_quintiles( outf.deciles[sysno][:,3])
        ncases = 0
        for hno in 1:settings.num_households
            hh = FRSHouseholdGetter.get_household( hno )
            inc = hhr[ (hhr.hid.== hh.hid) .& (hhr.data_year .== hh.data_year), :eq_bhc_net_income][1]
            quintile = q_from_inc( quintiles, inc )
            if sysno == 2
                inc *= 2.0
            end
            sf6 = get_sf_6d( hh = hh, eq_bhc_net_income=inc, quintile=quintile )
            for (pid,sf) in sf6
                ncases += 1
                sf6s[ncases,sysno] = sf
            end
        end
        push!(summary, StatsBase.summarystats( sf6s[1:ncases,sysno] ))
    end
    println( summary )
end