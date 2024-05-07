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

using .STBIncomes

using .Intermediate: 
    MTIntermediate, 
    make_intermediate
   
using .STBParameters: 
    UniversalCreditSys,
    BenefitCapSys,
    LegacyMeansTestedBenefitSystem
    
using .Results: 
    BenefitUnitResult,
    HouseholdResult,
    init_household_result, 
    to_string

using .Utils: 
    eq_nearest_p,
    to_md_table

using .RunSettings

using .ExampleHelpers

sys = get_system( year=2019, scotland=true )
settings = Settings()
    
@testset "Benefit Cap Shakedown" begin
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
                res.bus[1].pers[spid].income[HOUSING_BENEFIT] = cb
                for buno in eachindex(bus) 
                    apply_benefit_cap!(
                        res.bus[buno],
                        hh.region,
                        bus[buno],
                        intermed.buint[buno],
                        sys.bencap,
                        legacy_bens
                    )
                    println( "on family $hht bu $buno hb=$hb cb = $cb")
                    println( res.bus[buno].bencap )
                    if buno == 1
                        println( "res.bus[$buno].pers[\$(head.pid)].income[HOUSING_BENEFIT] = $(res.bus[buno].pers[head.pid].income[HOUSING_BENEFIT])\n\n" ) 
                    end
                end # bus
            end # cbs
        end # hbs
    end # hhs
end # testset