#
# As of September 19 2021
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

const POLICY_IN_PRACTICE_WEEKS_PER_MONTH = 52/12 
const PWPM = POLICY_IN_PRACTICE_WEEKS_PER_MONTH

function pip_weekly( monthly :: Real ) :: Real
    ceil( monthly / PWPM,  digits=2 )
end


function to_pip_monthly( weekly :: Real ) :: Real
    ceil( weekly*PWPM,  digits=2 )
end

function compare( uspw::Real, thempm::Real )
    uspm = uspw*WEEKS_PER_MONTH
    @assert uspm ≈ thempm "us $(uspw)pw ($(uspm)pm) != $(thempm)pm"
    return true
end

sys21_22 = load_file( "../params/sys_2021_22.jl" )
load_file!( sys21_22, "../params/sys_2021-uplift-removed.jl")
weeklyise!( sys21_22, wpm=PWPM, wpy=52 )

settings = DEFAULT_SETTINGS
@testset "Single Person, No Housing Costs 19/Sep/2021 values (without £20)" begin
    
    dob = Date( 1970, 1, 1 )
    # basic - no tax credits, no ESA/JSA, single person
    # check we've loaded correctly
    @test sys21_22.uc.age_25_and_over ≈ 324.84/WEEKS_PER_MONTH 
    hh = make_hh(
        adults = 1,
        children = 0,
        earnings = 0,
        rent = 0,
        rooms = 0,
        age = 50,
        tenure = Private_Rented_Furnished )
    
    head = get_head( hh )
    println( to_string( head ))
    empty!( head.income )
    println( "Head income $(head.income)")
    unemploy!( head )
    enable!( head )
    println( to_string( head ))
    settings.means_tested_routing = uc_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test eq_nearest_p(hres_scot.bhc_net_income*52/12, 324.84)
    @test compare(
        hres_scot.bus[1].pers[head.pid].income[UNIVERSAL_CREDIT], 324.84 )
    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test hres_scot.ahc_net_income*PWPM  ≈ 323.70 
    @test hres_scot.bus[1].pers[head.pid].income[NON_CONTRIB_JOBSEEKERS_ALLOWANCE]*PWPM ≈ 323.70
    println( inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    employ!(head)
    head.usual_hours_worked = 30
    head.income[wages] = 1_000/PWPM
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test hres_scot.bhc_net_income*PWPM  ≈ 1026.23
    println( inctostr(  hres_scot.bus[1].pers[head.pid].income.*PWPM ))
    uprate_struct!(hres_scot.bus[1].legacy_mtbens, PWPM ) # PWPM)
    println( to_md_table(hres_scot.bus[1].legacy_mtbens ))
end