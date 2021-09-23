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

function compare( uspw::Real, thempm::Real )
    uspm = uspw*PWPM
    @assert to_nearest_p(uspm,thempm) "us $(uspw)pw ($(uspm)pm) != $(thempm)pm"
    return true
end


sys21_22 = load_file( "../params/sys_2021_22.jl" )
load_file!( sys21_22, "../params/sys_2021-uplift-removed.jl")
wpm=PWPM
wpy=52
println( "weeklyise start wpm=$wpm wpy=$wpy")
weeklyise!( sys21_22; wpy=wpy, wpm=wpm  )

settings = DEFAULT_SETTINGS
@testset "Single Person, No Housing Costs 19/Sep/2021 values (without £20)" begin

    # These from https://policyinpractice.co.uk/benefit-budgeting-calculator/
    dob = Date( 1970, 1, 1 )
    # basic - no tax credits, no ESA/JSA, single person
    # check we've loaded correctly
    @test sys21_22.uc.age_25_and_over ≈ 324.84/PWPM
    hh = make_hh(
        adults = 1,
        children = 0,
        earnings = 0,
        rent = 0,
        rooms = 0,
        age = 50,
        tenure = Private_Rented_Furnished )
    
    head = get_head( hh )
    empty!( head.income )
    unemploy!( head )
    enable!( head )
    settings.means_tested_routing = uc_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )

    @test hres_scot.bhc_net_income*PWPM ≈ 324.84
    @test PWPM*hres_scot.bus[1].pers[head.pid].income[UNIVERSAL_CREDIT] ≈ 324.84
    
    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test hres_scot.ahc_net_income*PWPM ≈ 323.70 
    @test hres_scot.bus[1].pers[head.pid].income[NON_CONTRIB_JOBSEEKERS_ALLOWANCE]*PWPM ≈ 323.70
    # println( inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    
    employ!(head)
    head.usual_hours_worked = 30
    head.income[wages] = 1_000/PWPM
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income,1026.23)

    #println( inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    # println( to_md_table( sys21_22.lmt.working_tax_credit ))

    settings.means_tested_routing = uc_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income,975.68)
    # println( to_md_table(hres_scot.bus[1].legacy_mtbens ))

    head.income[wages] = 500/PWPM
 
    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income,736.25)


    settings.means_tested_routing = uc_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income,509.84)
    # println( to_md_table(hres_scot.bus[1].uc ))
    # println( inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    
    head.usual_hours_worked = 10

    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income,500.0)

    settings.means_tested_routing = uc_full
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income,509.84)
    
    head.usual_hours_worked = 0
    head.income[wages] = 0
    blind!( head )
    unemploy!( head )
    head.jsa_type = income_related_jsa

    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income, 475.80 )

    settings.means_tested_routing = uc_full
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income, 324.84 )


    head.jsa_type = no_jsa 
    head.esa_type = income_related_jsa

    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income, 323.70 )


    settings.means_tested_routing = uc_full
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income, 324.84 )

    head.age = 17

    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income, 323.70 )


    settings.means_tested_routing = uc_full
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income, 257.33 )



    ## THESE from https://benefitscheck.ageuk.org.uk/
    #  ref: AC73A0470
    head.age = 68
    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test hres_scot.bhc_net_income ≈ 179.60

 
    head.age = 80

    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test hres_scot.bhc_net_income ≈  (137.60*1.1) + 25.74
    
    head.benefit_ratios[state_pension] = 154.0/137.60 # just qualify for savings credit
    hres_scot = do_one_calc( hh, sys21_22, settings )
    # pen / pen credit / savings credit
    @test hres_scot.bhc_net_income ≈ 154 + 23.10 + 0.18
    
    # println( to_md_table(hres_scot.bus[1].uc ))

    ## back to main calc .. children

    head.age = 51

    pid1 = add_child!( hh, 3, Female )
    pid2 = add_child!( hh, 1, Male )
    # println( keys( hh.people ))
    # println( "pid1=$pid1 pid2=$pid2 head.default_benefit_unit=$(head.default_benefit_unit)")
    unemploy!( head )
    enable!( head )
    unblind!( head )
    head.jsa_type = no_jsa
    head.esa_type = no_jsa
    bus = get_benefit_units(hh)
    ccph = 5.00 # 4.69
    # 40 hrs child care @4.69ph
    ch1 = hh.people[pid1]
    ch2 = hh.people[pid2]
    ch1.hours_of_childcare = 20
    ch2.hours_of_childcare = 20
    ch1.cost_of_childcare = 20*ccph
    ch2.cost_of_childcare = 20*ccph

    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income, 1036.85 )
    
    settings.means_tested_routing = uc_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income, 1037.98 )
    
    head.usual_hours_worked = 30
    head.income[wages] = 1_000/PWPM

    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income, 2517.72 )
    println( to_md_table(hres_scot.bus[1].legacy_mtbens ))
    println( inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    # println( to_string( head ))
    # println( hres_scot.bus[1].legacy_mtbens.premia )

    settings.means_tested_routing = uc_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare(hres_scot.bhc_net_income,  2460.10 )
    println( to_md_table(hres_scot.bus[1].uc ))
    println( inctostr(  hres_scot.bus[1].pers[head.pid].income ))

end