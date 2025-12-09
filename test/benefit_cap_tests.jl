using Test
using Dates

using ScottishTaxBenefitModel

using .ModelHousehold: 
    Household, 
    Person, 
    People_Dict,     
    default_bu_allocation, 
    get_benefit_units, 
    get_head, 
    get_spouse, 
    is_single,
    pers_is_carer,
    pers_is_disabled, 
    search

using .Definitions

using .BenefitCap:
    apply_benefit_cap!

using .Intermediate: 
    MTIntermediate, 
    make_intermediate
   
using .STBParameters
using .STBOutput
using .STBIncomes
   
using .Results: 
    BenefitUnitResult,
    HouseholdResult,
    init_household_result, 
    total,
    to_string

using .Utils: 
    eq_nearest_p,
    to_md_table,
    approx_geq

using .RunSettings

using .ExampleHelpers

sys = get_system( year=2019, scotland=true )
settings = Settings()
    
@testset "Benefit Cap Example HH Shakedown" begin
    examples = get_all_examples()
    hbs = collect(100:100:1000)
    for (hht,hh) in examples 
        bus = get_benefit_units( hh )
        intermed = make_intermediate( 
            DEFAULT_NUM_TYPE,
            settings,
            hh,
            sys.hours_limits,
            sys.age_limits,
            sys.child_limits )
        head = get_head( hh )
        spouse = get_spouse( hh )
        spid :: BigInt = spouse === nothing ? head.pid : spouse.pid
        for hb in 200.0:200:1_000
            for cb in [20,50,100]
                res = init_household_result( hh )
                res.bus[1].pers[head.pid].income[HOUSING_BENEFIT] = hb
                res.bus[1].pers[spid].income[CHILD_BENEFIT] = cb
                for buno in eachindex(bus) 
                    buint = intermed.buint[buno]
                    apply_benefit_cap!(
                        res.bus[buno],
                        hh.region,
                        bus[buno],
                        buint,
                        sys.bencap,
                        legacy_bens )
                    println( "on family $hht bu $buno hb=$hb cb = $cb")
                    println( res.bus[buno].bencap )
                    if buint.someone_pension_age || buint.someone_is_carer ||(buint.num_severely_disabled_adults > 0)
                        @test res.bus[buno].bencap.not_applied
                    else
                        @test ! res.bus[buno].bencap.not_applied
                        @show res.bus[buno].bencap.cap total( res.bus[buno], LEGACY_CAP_BENEFITS)
                        @test approx_geq(res.bus[buno].bencap.cap,total( res.bus[buno], LEGACY_CAP_BENEFITS)) 
                    end
                    if buno == 1
                        println( "res.bus[$buno].pers[\$(head.pid)].income[HOUSING_BENEFIT] = $(res.bus[buno].pers[head.pid].income[HOUSING_BENEFIT])\n\n" ) 
                    end
                end # bus
            end # cbs
        end # hbs
    end # hhs
end # testset

@testset "Benefit Cap HH Run" begin
    settings = Settings()
    # settings.means_tested_routing = lmt_full
    sys1 = get_default_system_for_fin_year( 2025; scotland=true )
    sys2 = get_default_system_for_fin_year( 2025; scotland=true )
    sys2.bencap.abolished = true
    summary, results, settings = do_basic_run( settings, [sys1,sys2], reset=false )
    dump_frames( settings, results )
    dump_summaries( settings, summary )
end