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
sys21_22.minwage.abolished = true # so we can experiment with low wages
wpm=PWPM
wpy=52
weeklyise!( sys21_22; wpy=wpy, wpm=wpm  )
f = open( "tmp/vs_pinp.txt", "w")
println(  "weeklyise start wpm=$wpm wpy=$wpy")

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
    
    # ================= unemploy 0 rent band b ct
    empty!( head.income )
    unemploy!( head )
    enable!( head )

    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    
    println(  "CTC", hres.bus[1].pers[head.pid].income[LOCAL_TAXES])
    println(  to_md_table(hres.bus[1].legacy_mtbens ))
    @test compare_w_2_m(hres.bhc_net_income,391.10)

 
    @test compare_w_2_m(hres.bus[1].pers[head.pid].income[NON_CONTRIB_JOBSEEKERS_ALLOWANCE], 323.70)

    settings.means_tested_routing = uc_full 
    hres = do_one_calc( hh, sys21_22, settings )
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres.bhc_net_income, 392.24 )
    @test compare_w_2_m(hres.bus[1].pers[head.pid].income[UNIVERSAL_CREDIT], 324.84)
    # println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    
    # =============== single 1,000 pm no rent
    employ!(head)
    head.usual_hours_worked = 30
    head.income[wages] = 1_000/PWPM
   
    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
    println(  inctostr( hres.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres.bhc_net_income,1026.23)

    #println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    # println(  to_md_table( sys21_22.lmt.working_tax_credit ))

    settings.means_tested_routing = uc_full 
    hres = do_one_calc( hh, sys21_22, settings )
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres.bhc_net_income,975.68)
    # println(  to_md_table(hres.bus[1].legacy_mtbens ))

    # =============== single 1,000 pm 30 hrs pw no rent Q:: why doesn't min wage kick in??
    head.income[wages] = 500/PWPM
 
    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres.bhc_net_income,740.29)
    
    settings.means_tested_routing = uc_full 
    hres = do_one_calc( hh, sys21_22, settings )
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres.bhc_net_income, 540.24)
    # println(  to_md_table(hres.bus[1].uc ))
    # println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    
    # 10 hrs worked 500pm 
    head.usual_hours_worked = 10

    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres.bhc_net_income,536.47)

    settings.means_tested_routing = uc_full
    hres = do_one_calc( hh, sys21_22, settings )
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres.bhc_net_income,540.24)

    # todo add working with pension 
   
    # ================ unemployed + blind 
    head.usual_hours_worked = 0
    head.income[wages] = 0
    blind!( head )
    unemploy!( head )
    disable_slightly!( head )
    head.pip_daily_living_type = enhanced_pip
    # we have limited capacity to work switched on in calculator
    head.jsa_type = income_related_jsa

    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
   
    @test compare_w_2_m(hres.bhc_net_income,  1145.54 ) # inc severse disabled premium!

 
    settings.means_tested_routing = uc_full
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income,  1124.14 )
 
 
    # ================= 17yo head no blind - jammed on 'parents dead' in calculator
    unblind!( head )
    head.age = 17
    # head.jsa_type = no_jsa
    # head.esa_type = no_jsa

    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
    println(  to_md_table(hres.bus[1].legacy_mtbens ))
    println( inctostr(  hres.bus[1].pers[head.pid].income ))
    
    @test compare_w_2_m(hres.bhc_net_income,  1145.54  )


    settings.means_tested_routing = uc_full
    hres = do_one_calc( hh, sys21_22, settings )
    println( to_md_table(hres.bus[1].uc ))
    println( inctostr(  hres.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres.bhc_net_income,  1056.63 )

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
    # println(  keys( hh.people ))
    # println(  "pid1=$pid1 pid2=$pid2 head.default_benefit_unit=$(head.default_benefit_unit)")
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
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.ahc_net_income, 1036.85 )
    
    settings.means_tested_routing = uc_full 
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.ahc_net_income, 1037.98 )
    
    head.usual_hours_worked = 30
    head.income[wages] = 1_000/PWPM

    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
    println(  "CT Band=$(hh.ct_band)" )
    println(  to_md_table(hres.bus[1].legacy_mtbens ))
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres.bhc_net_income,  2522.84 )
    # println(  to_string( head ))
    # println(  hres.bus[1].legacy_mtbens.premia )

    settings.means_tested_routing = uc_full 
    hres = do_one_calc( hh, sys21_22, settings )
    println(  "CT Band=$(hh.ct_band)" )
    println(  to_md_table(hres.bus[1].uc ))
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    @test compare_w_2_m(hres.bhc_net_income,  2460.10 )

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
    
    # ============== 400 pm single person - under lha 
    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
    # @test compare_w_2_m(hres.bhc_net_income, 323.70 )
    # since 100% rent rebated this should be the same
    @test compare_w_2_m(hres.ahc_net_income, 323.70 )
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    println(  "CT Band=$(hh.ct_band)" )
    settings.means_tested_routing = uc_full 
    hres = do_one_calc( hh, sys21_22, settings )
    # @test compare_w_2_m(hres.bhc_net_income, 324.84 )
    @test compare_w_2_m(hres.ahc_net_income, 324.84 )
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))


    # ============== 300 earnings 400 pm rent single person - under lha 
    employ!( head )
    head.usual_hours_worked = 30
    head.income[wages] = 300/PWPM

    settings.means_tested_routing = lmt_full     
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income, 904.38 )
    # since 100% rent rebated this should be the same
    @test compare_w_2_m(hres.ahc_net_income, 436.98 )
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    
    settings.means_tested_routing = uc_full 
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income, 881.04 )
    @test compare_w_2_m(hres.ahc_net_income,  413.64 )
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    println(  to_md_table(hres.bus[1].uc ))

    # ============== 500 earnings 400 pm rent single person - under lha 
    head.income[wages] = 500/PWPM
    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income, 934.38 )
    # since 100% rent rebated this should be the same
    @test compare_w_2_m(hres.ahc_net_income,  466.98 )
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    println(  "CT Band=$(hh.ct_band)" )

    settings.means_tested_routing = uc_full 
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income, 940.24 )
    @test compare_w_2_m(hres.ahc_net_income,  472.84  )
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    println(  to_md_table(hres.bus[1].uc ))


end

flush( f )
close( f )