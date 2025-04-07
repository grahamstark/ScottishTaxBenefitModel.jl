import Test: @testset, @test

using ScottishTaxBenefitModel

using .FRSHouseholdGetter
using .ModelHousehold

using .Weighting
using .ExampleHelpers
using .RunSettings

using LazyArtifacts
using LazyArtifacts
using CSV
using DataFrames
   
#if get_num_households() == 0
function wsum(settings::Settings):Number
    hhlds = 0.0
    people = 0.0
    for i in 1:settings.num_households
        hh = get_household(i)
        w = hh.weight
        people += w*num_people(hh)
        hhlds += w
    end
    hhlds, people
end



@testset "weighting strategies" begin
    settings = Settings()

    adir = get_data_artifact(settings)
    raw_hhlds = CSV.File(joinpath(adir,"households.tab"))|>DataFrame

    settings.weighting_strategy = dont_use_weights
    settings.num_households, settings.num_people = 
        initialise(  settings; reset=true )
    data_years = get_data_years()
    @show data_years
    hhlds, people = wsum(settings)
    @test hhlds ≈ settings.num_households
    @test people ≈ settings.num_people 
    # FIXME this breaks without updates!
    popns = Weighting.DEFAULT_TARGETS_SCOTLAND_2025
    
    target_scot_hhlds = sum( popns[42:47])
    target_scots_people = sum( popns[8:41])
    settings.lower_multiple = 0.2
    settings.upper_multiple = 7.0

    settings.weighting_strategy = use_runtime_computed_weights
    settings.num_households, settings.num_people = 
        initialise(  settings; reset=true )
    hhlds, people = wsum(settings)
    @test hhlds ≈ target_scot_hhlds
    @test people ≈ target_scots_people
    println( "runtime weights OK")
    # should be same ...
    settings.weighting_strategy = use_precomputed_weights
    settings.num_households, settings.num_people = 
        initialise(  settings; reset=true )
    hhlds, people = wsum(settings)
    @test hhlds ≈ target_scot_hhlds
    @test people ≈ target_scots_people
    println( "precomputed weights OK")
    # FIXME this breaks without updates!

    # same totals, smaller subset
    settings.included_data_years = [2019,2020,2021]
    settings.weighting_strategy = use_runtime_computed_weights
    settings.lower_multiple = 0.2
    settings.upper_multiple = 8.0
    settings.num_households, settings.num_people = 
        initialise(  settings; reset=true )
    hhlds, people = wsum(settings)
    @test hhlds ≈ target_scot_hhlds
    @test people ≈ target_scots_people
    println( "settings.num_people=$(settings.num_people), settings.num_households=$(settings.num_households)")
    @test get_data_years() ==  settings.included_data_years

    settings.included_data_years = []
    settings.weighting_strategy = use_supplied_weights
    dataweights = sum( raw_hhlds.weight )
    settings.num_households, settings.num_people = 
    initialise(  settings; reset=true )
    hhlds, people = wsum(settings)
    @test dataweights ≈ hhlds    
end
