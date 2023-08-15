
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
    settings = get_all_uk_settings_2023()
    Uprating.load_prices( settings )
    ConsumptionData.init( settings, reset=true )
    println( settings.indirect_method )
    obs[]= Progress( settings.uuid, "weights", 0, 0, 0, 0  )
    # force initialisation so we're not mixing uk and scot datasets
    FRSHouseholdGetter.initialise( settings; reset=true ) # force UK dataset 
    for hno in 1:settings.num_households
        hh = FRSHouseholdGetter.get_household( hno )
        @test isnothing( hh.consumption )
        ConsumptionData.find_consumption_for_hh!( hh, settings, 1)
        @test ! isnothing( hh.consumption )
        if (hno % 100) == 0
            println( hh.consumption )
        end
    end
end