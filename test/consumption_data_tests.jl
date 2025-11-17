
#=
Tests of the ExpenditureData.jl module, which matches in lcf expenditure data.
=#
using CSV,DataFrames,StatsBase,Test
using Observables
using ScottishTaxBenefitModel
using .BenefitGenerosity
using .ConsumptionData
using .FRSHouseholdGetter
using .GeneralTaxComponents
using .ModelHousehold
using .RunSettings
using .STBParameters
using .Uprating
using .Utils
using .Monitor: Progress
using .ExampleHouseholdGetter

settings = Settings()

# observer = Observer(Progress("",0,0,0))
tot = 0
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)

    tot += p.step
    println(tot)
end


@testset "test load indirect" begin
    settings = Settings() # FIXME meed matches for UK  get_all_uk_settings_2023()
    settings.do_indirect_tax_calculations = true
    # Uprating.load_prices( settings )
    # ConsumptionData.init( settings, reset=true )
    println( settings.indirect_method )
    obs[]= Progress( settings.uuid, "weights", 0, 0, 0, 0  )
    # force initialisation so we're not mixing uk and scot datasets
    settings.num_households, settings.num_people, nhh2 = 
        FRSHouseholdGetter.initialise( settings; reset=true ) # force UK dataset 
    for hno in 1:settings.num_households
        hh = FRSHouseholdGetter.get_household( hno )
        # @test isnothing( hh.expenditure )
        # ConsumptionData.find_consumption_for_hh!( hh, settings, 1)
        @test ! isnothing( hh.expenditure )
        println( "on hno $hno")
        if (hno % 100) == 0
            println( hh.expenditure )
            println( hh.factor_costs )
        end
    end
end

@testset "test examples consumption" begin
    settings = Settings() # FIXME UK get_all_uk_settings_2023() # so, with expenditure == matching jammed on
    settings.do_indirect_tax_calculations = true
    @test settings.indirect_method == matching
    ExampleHouseholdGetter.initialise( settings )
    for (key,hh) in ExampleHouseholdGetter.EXAMPLE_HOUSEHOLDS
        @test ! isnothing(hh.expenditure)
    end
end

@testset "Indirect Parameters" begin
    println( "default_exempt = $(DEFAULT_EXEMPT)")
    println( "default_reduced_rate = $(DEFAULT_REDUCED_RATE)")
    println( "default_zero_rated = $(DEFAULT_ZERO_RATE)")
    println( "default_standard_rate = $(DEFAULT_STANDARD_RATE)")
end