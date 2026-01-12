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
        if i < 20
            @show hh.hid hh.data_year hh.weight
        end
        people += w*num_people(hh)
        hhlds += w
    end
    hhlds, people
end



@testset "weighting strategies" begin
    settings = Settings()

    adir = get_data_artifact(settings)
    settings.include_institutional_population = false
    settings.weighting_target_year = 2026
    settings.weighting_strategy = dont_use_weights
    settings.num_households, settings.num_people = 
        initialise(  settings; reset=true )
    data_years = get_data_years()
    raw_hhlds = CSV.File(joinpath(adir,"households.tab"))|>DataFrame
    raw_weights = CSV.File( joinpath( adir, "weights.tab")) |> DataFrame
    @show data_years
    hhlds, people = wsum(settings)
    @test hhlds ≈ settings.num_households
    @test people ≈ settings.num_people 
    household_total,
    popns, 
    initialise_target_dataframe,
    make_target_row! = Weighting.get_targets( settings )

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
    #= REDO precompured weights 
    settings.weighting_strategy = use_precomputed_weights
    settings.num_households, settings.num_people = 
        initialise( settings; reset=true )
    hhlds, people = wsum(settings)
    @test hhlds ≈ target_scot_hhlds
    @test people ≈ target_scots_people
    println( "precomputed weights OK")
    # FIXME this breaks without updates!
    =#
    # same totals, smaller subset
    settings.included_data_years = collect(2021:2023) # [2018,2019,2020,2021]
    settings.weighting_strategy = use_runtime_computed_weights
    settings.lower_multiple = 0.15
    settings.upper_multiple = 9.0
    settings.num_households, settings.num_people = 
        initialise( settings; reset=true )
    hhlds, people = wsum(settings)
    @test hhlds ≈ target_scot_hhlds
    @test people ≈ target_scots_people
    println( "settings.num_people=$(settings.num_people), settings.num_households=$(settings.num_households)")
    @test get_data_years() ==  settings.included_data_years

    settings.included_data_years = [2019,2021,2022,2023] 
    settings.weighting_strategy = use_supplied_weights
    # settings.include_institutional_population = false
    
    dataweights = sum( raw_weights.weight )
    #raw_hhlds[ raw_hhlds.data_year .∈ (settings.included_data_years, ), :weight] )
    settings.num_households, settings.num_people = 
        initialise( settings; reset=true )
    hhlds, people = wsum(settings)
    # not a valid test @test dataweights ≈ hhlds 
end
