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
using .ExampleHelpers

sys21_22 = get_default_system_for_date( Date( 2021, 12, 1 ); wpy=52, wpm=PWPM ) 
# load_file( "../params/sys_2021_22.jl" )
# load_file!( sys21_22, "../params/sys_2021-uplift-removed.jl")
# load_file!( sys21_22, "../params/budget_2021_uc_changes.jl")
# println( "weeklyise start wpm=$PWPM wpy=52")
# weeklyise!( sys21_22; wpy=52, wpm=PWPM  )

settings = Settings()

@testset "Single Pensioner from AGEUK" begin

    hh = make_hh(
        adults = 1,
        children = 0,
        earnings = 0,
        rent = 0,
        rooms = 0,
        age = 68,
        tenure = Private_Rented_Furnished,
        council = :S12000049 )
    head = get_head( hh )
    settings.means_tested_routing = lmt_full 

    head = get_head( hh )
    empty!( head.income )
    unemploy!( head )
    enable!( head )

    hres = do_one_calc( hh, sys21_22, settings )
    @test hres.ahc_net_income ≈ 179.60
    println( to_md_table(hres.bus[1].legacy_mtbens ))
    println( "Age 68; \n"*inctostr(  hres.bus[1].pers[head.pid].income ))

    head.age = 80

    hres = do_one_calc( hh, sys21_22, settings )
    @test hres.ahc_net_income ≈  (137.60*1.1) + 25.74
    println( "Age 80; old pension x 1.1 \n"*inctostr(  hres.bus[1].pers[head.pid].income ))

    head.benefit_ratios[state_pension] = 154.0/137.60 # just qualify for savings credit
    hres = do_one_calc( hh, sys21_22, settings )
    # pen / pen credit / savings credit
    @test hres.ahc_net_income ≈ 154 + 23.10 + 0.18
    println( "Age 80; old pension x 1.119 so qualify for savings credit \n"*inctostr(  hres.bus[1].pers[head.pid].income ))
      
    head.benefit_ratios[state_pension] = 1
    pid1 = add_child!( hh, 3, Female ) # 01/01/2018
    head.age=68 # 01/01/1953

    # £98.76 = 52.10PC + 10.00 SCP + 15.51 CTR + 21.15 CB + 179.60PENS
    hres = do_one_calc( hh, sys21_22, settings )
    @test hres.bhc_net_income ≈ (179.60 + 98.76) atol=0.04 # FIXME check weird rounding 

    hh.gross_rent = 100
    hres = do_one_calc( hh, sys21_22, settings )
    @test hres.bhc_net_income ≈ (179.60 + 198.76) atol=0.04 # FIXME check weird rounding 
    println( to_md_table(hres.bus[1].legacy_mtbens ))
    println( "Age 68; + 1 chld no rent \n"*inctostr(  hres.bus[1].income ))


end