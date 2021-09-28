#
# As of September 19 2021
# Tests against the Age UK Pensioner calculator.
# https://benefitscheck.ageuk.org.uk/
# ref: AC73A0470
#

using Test
using Dates
using ScottishTaxBenefitModel
using .ModelHousehold
using .STBParameters
using .STBIncomes
using .Definitions
using .GeneralTaxComponents
using .SingleHouseholdCalculations
using .RunSettings
using .Utils


sys21_22 = load_file( "../params/sys_2021_22.jl" )
load_file!( sys21_22, "../params/sys_2021-uplift-removed.jl")
println( "weeklyise start wpm=$PWPM wpy=52")
weeklyise!( sys21_22; wpy=52, wpm=PWPM  )
settings = DEFAULT_SETTINGS

@testset "Single Pensioner from AGEUK" begin

    hh = make_hh(
        adults = 1,
        children = 0,
        earnings = 0,
        rent = 0,
        rooms = 0,
        age = 68,
        tenure = Private_Rented_Furnished )
    head = get_head( hh )
    settings.means_tested_routing = lmt_full 

    head = get_head( hh )
    empty!( head.income )
    unemploy!( head )
    enable!( head )

    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test hres_scot.ahc_net_income ≈ 179.60
    println( to_md_table(hres_scot.bus[1].legacy_mtbens ))
    println( "Age 68; \n"*inctostr(  hres_scot.bus[1].pers[head.pid].income ))

    head.age = 80

    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test hres_scot.ahc_net_income ≈  (137.60*1.1) + 25.74
    println( "Age 80; old pension x 1.1 \n"*inctostr(  hres_scot.bus[1].pers[head.pid].income ))

    head.benefit_ratios[state_pension] = 154.0/137.60 # just qualify for savings credit
    hres_scot = do_one_calc( hh, sys21_22, settings )
    # pen / pen credit / savings credit
    @test hres_scot.ahc_net_income ≈ 154 + 23.10 + 0.18
    println( "Age 80; old pension x 1.119 so qualify for savings credit \n"*inctostr(  hres_scot.bus[1].pers[head.pid].income ))
      
    
end