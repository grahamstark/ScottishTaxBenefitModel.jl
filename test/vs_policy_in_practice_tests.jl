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
using .IncomeTaxCalculations
using .SingleHouseholdCalculations
using .RunSettings
using .Utils
using .ExampleHelpers

sys21_22 = load_file( "../params/sys_2021_22.jl" )
load_file!( sys21_22, "../params/sys_2021-uplift-removed.jl")
#
# Note this was pre-2021/2 budget, so no UC taper to 55
#
# load_file!( sys21_22, "../params/budget_2021_uc_changes.jl")

sys21_22.minwage.abolished = true # so we can experiment with low wages
wpm=PWPM
wpy=52
weeklyise!( sys21_22; wpy=wpy, wpm=wpm  )
println(  "weeklyise start wpm=$wpm wpy=$wpy")

settings = Settings()

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
        tenure = Private_Rented_Furnished,
        council = :S12000049 ) # glasgow
    
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
    println( to_md_table(hres.bus[1].legacy_mtbens ))
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
        tenure = Private_Rented_Furnished,
        council = :S12000049 )
    
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
    ## FIXME CHECK CT here
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
        tenure = Private_Rented_Furnished,
        council = :S12000049 )
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
    println( inctostr(  hres.bus[1].pers[head.pid].income ))
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


@testset "Couple with 2 children and housing costs" begin
    
    hh = make_hh(
        adults = 2,
        children = 2,
        earnings = 0,
        rent = 200,
        rooms = 3,
        age = 50,
        tenure = Private_Rented_Furnished,
        council = :S12000049 )
    hh.gross_rent = 200 # 800/PWPM
    hh.water_and_sewerage = 0
    hh.other_housing_charges = 0
    # === 2 ch family unemployed & hit by benefit cap & rent reduction
    head = get_head( hh )
    spouse = get_spouse( hh )
    spouse.age = 51
    println( "spouse.age=$(spouse.age)")
    unemploy!( head )
    enable!( head )
    unemploy!( spouse )
    enable!( spouse )
    empty!( head.income )
    empty!( head.assets )
    empty!( spouse.income )
    empty!( spouse.assets )
    
    bus = get_benefit_units(hh)
    bu = bus[1]
    ccph = 5.00 # 4.69
    # 40 hrs child care @4.69ph
    for pid in bu.children
        ch = bu.people[pid]
        empty!( ch.income )
        empty!( ch.assets )
        ch.age = 2
        ch.hours_of_childcare = 20
        ch.cost_of_childcare = 20*ccph
    end

    nh = num_people( hh )
    np = num_people( bu )
    nc = num_children( bu )
    na = num_adults( bu )
    println( "hh people $nh bu1 people $np children $nc adults $na")
    @test na == 2
    @test nc == 2
    @test np == 4
    @test nh == np
    println( to_md_table( hh ))
    println(  to_md_table( head ))
    println(  to_md_table( spouse ))
    
    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income, 1843.22 )
    # since 100% rent rebated this should be the same
    # the 200 is child care, to match the calculator
    @test compare_w_2_m(hres.ahc_net_income-200,  20.02)
    
    settings.means_tested_routing = uc_full 
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income, 1843.22 )
    # the 200 is child care, to match the calculator
    @test compare_w_2_m(hres.ahc_net_income-200, 20.02)

    # 500 pw split between partners
    head.income[wages] = 250
    head.usual_hours_worked = 30
    spouse.income[wages] = 250
    spouse.usual_hours_worked = 30
    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income, 3262.14, 2 )
    println(  to_md_table(hres.bus[1].legacy_mtbens ))
    println(  to_md_table(hres.bus[1].bencap ))    
    print( "## BU Income ")
    println(  inctostr(  hres.bus[1].income ))
    print( "## Head Income ")
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    print( "## Spouse Income ")
    println(  inctostr(  hres.bus[1].pers[spouse.pid].income ))

    settings.means_tested_routing = uc_full 
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income, 3563.71, 2 )
    println(  to_md_table(hres.bus[1].uc ))    
    println(  to_md_table(hres.bus[1].bencap ))    
    println(  inctostr(  hres.bus[1].income ))

    head.income[wages] = 500
    spouse.income[wages] = 250
    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income, 3441.42, 2 ) # 5p per month because of weird roun
    println(  to_md_table(hres.bus[1].legacy_mtbens ))
    println(  to_md_table(hres.bus[1].bencap ))    
    print( "## BU Income ")
    println(  inctostr(  hres.bus[1].income ))
    print( "## Head Income ")
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    print( "## Spouse Income ")
    println(  inctostr(  hres.bus[1].pers[spouse.pid].income ))

    settings.means_tested_routing = uc_full 
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income, 3836.58, 2 )
    println(  to_md_table(hres.bus[1].uc ))    
    println(  to_md_table(hres.bus[1].bencap ))    
    println(  inctostr(  hres.bus[1].income ))

    # == 4 children under 5
    hh.bedrooms = 4
    head.income[wages] = 250
    spouse.income[wages] = 250
    pid1 = add_child!( hh, 3, Female )
    pid2 = add_child!( hh, 1, Male )

    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income, 3569.85, 2 )
    println(  to_md_table(hres.bus[1].legacy_mtbens ))
    println(  to_md_table(hres.bus[1].bencap ))    
    print( "## BU Income ")
    println(  inctostr(  hres.bus[1].income ))
    print( "## Head Income ")
    println(  inctostr(  hres.bus[1].pers[head.pid].income ))
    print( "## Spouse Income ")
    println(  inctostr(  hres.bus[1].pers[spouse.pid].income ))

    settings.means_tested_routing = uc_full 
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income, 3871.42, 2 )
    
    for pid in bu.children
        println( bu.people[pid].age )
    end
   
end 

@testset "Couple pension contributions and savings" begin
    # https://betteroffcalculator.co.uk/calculator/McOuzi
    hh = make_hh(
        adults = 2,
        children = 2,
        earnings = 0,
        rent = 200,
        rooms = 3,
        age = 50,
        tenure = Private_Rented_Furnished,
        council = :S12000049 )
    hh.gross_rent = 200 # 800/PWPM
    hh.water_and_sewerage = 0
    hh.other_housing_charges = 0    # === 2 ch family unemployed & hit by benefit cap & rent reduction
    hh.bedrooms = 2
    head = get_head( hh )
    spouse = get_spouse( hh )
    spouse.age = 51
    bus = get_benefit_units(hh)
    bu = bus[1]
    for pid in bu.children
        ch = bu.people[pid]
        empty!( ch.income )
        empty!( ch.assets )
        ch.age = 2
        ch.hours_of_childcare = 0
        ch.cost_of_childcare = 0 #*ccph
    end

    println( "spouse.age=$(spouse.age)")
    employ!( head )
    enable!( head )
    unemploy!( spouse )
    enable!( spouse )
    empty!( head.income )
    empty!( head.assets )
    empty!( spouse.income )
    empty!( spouse.assets )
    
    head.income[wages] = 500.0
    head.usual_hours_worked = 30

    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income, 2379.81, 2 )

    settings.means_tested_routing = uc_full 
    hres = do_one_calc( hh, sys21_22, settings )
    @test compare_w_2_m(hres.bhc_net_income, 2714.29, 2 )

    head.income[pension_contributions_employee] = 200
    
    settings.means_tested_routing = lmt_full 
    hres = do_one_calc( hh, sys21_22, settings )
    # these don't quite work because of differences 
    # in how PiP treats pension contributions for income tax
    # we add a tax credit to pension contributions, they
    # deduct pension contribs from income. I think I'm right.
    # @test compare_w_2_m(hres.bhc_net_income, 2460.97, 2 )
    # @test compare_w_2_m(hres.bhc_net_income, 2002.99, 2 )
    # there's about £10pm in it.
    println( to_md_table(hres.bus[1].pers[head.pid].it ))
    println(  to_md_table(hres.bus[1].legacy_mtbens ))    
    println(  to_md_table(hres.bus[1].bencap ))    
    println(  inctostr(  hres.bus[1].income ))

    settings.means_tested_routing = uc_full 
    hres = do_one_calc( hh, sys21_22, settings )
    # these don't quite work because of differences 
    # in how PiP treats pension contributions for income tax
    # we add a tax credit to pension contributions, they
    # deduct pension contribs from income. I think I'm right.
    # @test compare_w_2_m(hres.bhc_net_income, 2460.97, 2 )
    println(  to_md_table(hres.bus[1].uc ))    
    println(  to_md_table(hres.bus[1].bencap ))    
    println(  inctostr(  hres.bus[1].income ))

    ## MEMO INCOME TAX to check against PiP
    bures = init_benefit_unit_result( bu )
    bures.pers[head.pid].income[WAGES] = 500
    bures.pers[head.pid].income[PENSION_CONTRIBUTIONS_EMPLOYEE] = 200
    calc_income_tax!(
        bures,
        head,
        spouse,
        sys21_22.it
        )
    println( "HEAD")
    println( to_md_table( bures.pers[head.pid].it ))
    println( bures.pers[head.pid].income[INCOME_TAX] )
    println( "SPOUSE")
    println( to_md_table( bures.pers[spouse.pid].it ))
    println( bures.pers[spouse.pid].income[INCOME_TAX] )

    bures = init_benefit_unit_result( bu )
    bures.pers[head.pid].income[WAGES] = 300
    bures.pers[head.pid].income[PENSION_CONTRIBUTIONS_EMPLOYEE] = 0
    calc_income_tax!(
        bures,
        head,
        spouse,
        sys21_22.it
        )
    println( bures.pers[head.pid].income[INCOME_TAX] )
    println( to_md_table( bures.pers[head.pid].it ))
end