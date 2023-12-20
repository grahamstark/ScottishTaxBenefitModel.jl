using Test
using ScottishTaxBenefitModel.Uprating
using DataFrames
using ScottishTaxBenefitModel
using .RunSettings: Settings, get_all_uk_settings_2023
using .ModelHousehold
using .STBParameters
using .ExampleHouseholdGetter
using .HouseholdAdjuster
using .FRSHouseholdGetter
using .Definitions
using .ExampleHelpers

prfr = Uprating.load_prices( Settings() )

print( prfr )

@time thesenames = ExampleHouseholdGetter.initialise( Settings() )

## NOTE this test has the 2019 OBR data and 2019Q4 as a target jammed on - will need
## changing with update versions

@testset "Adjusting tests #1" begin
    hh = ExampleHouseholdGetter.get_household( "mel_c2_scot" )
    dataj = DataAdjustments{Float64}()
    chh = adjusthh( hh, dataj )
    println( hh )
    # @test chh == hh 
    dataj.pct_housing[5] = 20
    weeklyise!( dataj )
    chh = adjusthh( hh, dataj )
    @test chh.gross_rent ≈ hh.gross_rent*1.2
    @test chh.other_housing_charges ≈ hh.other_housing_charges
    dataj.pct_income_changes[Definitions.wages] = 15.0
    dataj.pct_housing[5] = 0
    weeklyise!( dataj )
    chh = adjusthh( hh, dataj )
    for (pid,pers) in hh.people
        incs = keys(pers.income) 
        if Definitions.wages ∈ incs
            @test pers.income[Definitions.wages] ≈ hh.people[pid].income[Definitions.wages]*1.15
        end
    end
end