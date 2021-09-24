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

sys21_22 = load_file( "../params/sys_2021_22.jl" )
load_file!( sys21_22, "../params/sys_2021-uplift-removed.jl")
wpm=PWPM
wpy=52
weeklyise!( sys21_22; wpy=wpy, wpm=wpm  )
f = open( "tmp/vs_pinp.txt", "w")
println( f, "weeklyise start wpm=$wpm wpy=$wpy")

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
    println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres_scot.bhc_net_income, 324.84+67.3749 )
    @test PWPM*hres_scot.bus[1].pers[head.pid].income[UNIVERSAL_CREDIT] ≈ 324.84+67.3749
    
    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres_scot.ahc_net_income,323.70+67.3749)
    @test hres_scot.bus[1].pers[head.pid].income[NON_CONTRIB_JOBSEEKERS_ALLOWANCE]*PWPM ≈ 323.70
    # println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    
    employ!(head)
    head.usual_hours_worked = 30
    head.income[wages] = 1_000/PWPM
    hres_scot = do_one_calc( hh, sys21_22, settings )
    println( f, inctostr( hres_scot.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres_scot.bhc_net_income,1026.23)

    #println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    # println( f, to_md_table( sys21_22.lmt.working_tax_credit ))

    settings.means_tested_routing = uc_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres_scot.bhc_net_income,975.68)
    # println( f, to_md_table(hres_scot.bus[1].legacy_mtbens ))

    head.income[wages] = 500/PWPM
 
    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres_scot.bhc_net_income,736.25+67.40)


    settings.means_tested_routing = uc_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres_scot.bhc_net_income,509.84)
    # println( f, to_md_table(hres_scot.bus[1].uc ))
    # println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    
    head.usual_hours_worked = 10

    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres_scot.bhc_net_income,500.0+67.40)

    settings.means_tested_routing = uc_full
    hres_scot = do_one_calc( hh, sys21_22, settings )
    println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres_scot.bhc_net_income,509.84+67.40)
    
    head.usual_hours_worked = 0
    head.income[wages] = 0
    blind!( head )
    unemploy!( head )
    head.jsa_type = income_related_jsa

    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres_scot.bhc_net_income, 475.80+67.40 )

    settings.means_tested_routing = uc_full
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres_scot.bhc_net_income, 324.84+67.40 )


    head.jsa_type = no_jsa 
    head.esa_type = income_related_jsa

    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres_scot.bhc_net_income, 323.70 )


    settings.means_tested_routing = uc_full
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres_scot.bhc_net_income, 324.84 )

    head.age = 17

    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres_scot.bhc_net_income, 323.70 )


    settings.means_tested_routing = uc_full
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres_scot.bhc_net_income, 257.33 )

end


@testset "Lone Parent" begin

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

    pid1 = add_child!( hh, 3, Female )
    pid2 = add_child!( hh, 1, Male )
    # println( f, keys( hh.people ))
    # println( f, "pid1=$pid1 pid2=$pid2 head.default_benefit_unit=$(head.default_benefit_unit)")
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
    @test compare_w_2_m(hres_scot.bhc_net_income, 1036.85 )
    
    settings.means_tested_routing = uc_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres_scot.bhc_net_income, 1037.98 )
    
    head.usual_hours_worked = 30
    head.income[wages] = 1_000/PWPM

    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres_scot.bhc_net_income, 2517.72 )
    println( f, to_md_table(hres_scot.bus[1].legacy_mtbens ))
    println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    # println( f, to_string( head ))
    # println( f, hres_scot.bus[1].legacy_mtbens.premia )

    settings.means_tested_routing = uc_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres_scot.bhc_net_income,  2460.10 )
    println( f, to_md_table(hres_scot.bus[1].uc ))
    println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))

end


@testset "Single Person with housing costs" begin
    
    hh = make_hh(
        adults = 1,
        children = 0,
        earnings = 0,
        rent = 0,
        rooms = 0,
        age = 50,
        tenure = Private_Rented_Furnished )
    hh.gross_rent = 400/PWPM
    #
    # Glasgow:  They have 493.62 LHA per month 1 bedroom 113.92pw (4.333 = 52/12)
    #
    hh.bedrooms = 1
    head = get_head( hh )
    empty!( head.income )
    unemploy!( head )
    enable!( head )

    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres_scot.bhc_net_income, 323.70 )
    # since 100% rent rebated this should be the same
    @test compare_w_2_m(hres_scot.ahc_net_income, 323.70 )
    println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    println( f, "CT Band=$(hh.ct_band)" )
    settings.means_tested_routing = uc_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres_scot.bhc_net_income, 324.84 )
    @test compare_w_2_m(hres_scot.ahc_net_income, 324.84 )
    println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))

    head.income[wages] = 300/PWPM

    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres_scot.bhc_net_income, 812.77 )
    # since 100% rent rebated this should be the same
    @test compare_w_2_m(hres_scot.ahc_net_income, 345.37 )
    println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    println( f, "CT Band=$(hh.ct_band)" )
    settings.means_tested_routing = uc_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres_scot.bhc_net_income, 881.04 )
    @test compare_w_2_m(hres_scot.ahc_net_income, 413.64 )
    println( f, inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    println( f, to_md_table(hres_scot.bus[1].uc ))
end

close( f )