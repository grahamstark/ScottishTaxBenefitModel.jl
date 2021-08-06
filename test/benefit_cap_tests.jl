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

using .Incomes

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


sys = get_system( scotland=true )

@testset "Benefit Cap Shakedown" begin
    examples = get_ss_examples()
    for (hht,hh) in examples 
        bus = get_benefit_units( hh )
        intermed = make_intermediate( 
            hh,
            sys.hours_limits,
            sys.age_limits,
            sys.child_limits )
        res = init_household_result( hh )
        for buno in eachindex(bus) 
            apply_benefit_cap!(
                res.bus[buno],
                hh.region,
                bus[buno],
                intermed.buint[buno],
                sys.bencap,
                legacy_bens
        )
        println( res.bus[buno].bencap )
        end #buno
    end # hhs
end # testset