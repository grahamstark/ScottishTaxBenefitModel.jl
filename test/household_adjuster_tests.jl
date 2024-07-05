using DataFrames
using Test

using ScottishTaxBenefitModel
using .Definitions
using .ExampleHelpers
using .ExampleHouseholdGetter
using .FRSHouseholdGetter
using .HouseholdAdjuster
using .ModelHousehold
using .Results
using .RunSettings: Settings, get_all_uk_settings_2023
using .STBIncomes
using .STBParameters
using .Uprating

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

@testset "Minimum Wages " begin
    sys = get_system( year=2023 )
    hh = ExampleHouseholdGetter.get_household( "example_hh1" )  
    head = get_head( hh )
    println(head)
    hres = init_household_result( hh )
    apply_minumum_wage!( hres, hh, sys.minwage )
    mw = get_minimum_wage( sys.minwage, head.age )
    @assert hres.bus[1].pers[head.pid].income[WAGES] ≈ head.income[Definitions.wages]
    head.income[Definitions.wages] = 100.0
    apply_minumum_wage!( hres, hh, sys.minwage )
    @assert hres.bus[1].pers[head.pid].income[WAGES] ≈ mw*head.usual_hours_worked
    println( "set wage to $(hres.bus[1].pers[head.pid].income[WAGES]) hours $(head.usual_hours_worked) mw=$mw")
    head.income[Definitions.self_employment_income] = 50
    apply_minumum_wage!( hres, hh, sys.minwage )
    @assert hres.bus[1].pers[head.pid].income[WAGES] ≈ (mw*head.usual_hours_worked*(2/3)) "wage is $(hres.bus[1].pers[head.pid].income[WAGES]) "
    println( "set wage to $(hres.bus[1].pers[head.pid].income[WAGES]) hours $(head.usual_hours_worked) mw=$mw")
end