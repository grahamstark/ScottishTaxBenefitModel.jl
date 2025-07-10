using Test
using Dates

using ScottishTaxBenefitModel

using .CTR
using .Definitions
using .ExampleHelpers
using .IncomeTaxCalculations
using .Intermediate
using .LocalLevelCalculations
using .ModelHousehold
using .NationalInsuranceCalculations
using .Results
using .RunSettings
using .STBIncomes
using .STBParameters
using .Utils

## FIXME don't need both
sys = get_system( year=2024, scotland=true )
settings = Settings()


@testset "Council Tax Reductions" begin
    # FIXME update skeleton.
    cpl= get_example( cpl_w_2_children_hh )
    head = get_head( cpl )
    head.age = 30
    spouse = get_spouse( cpl )
    spouse.age = 30
    empty!(head.assets)
    empty!(head.income)
    head.over_20_k_saving = false
    empty!(spouse.assets)
    empty!(spouse.income)
    spouse.over_20_k_saving = false
    bus = get_benefit_units( cpl )
    hres = init_household_result( cpl )
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,                
        cpl, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    hres.bus[1].pers[head.pid].income[LOCAL_TAXES] = 
        calc_council_tax( 
            cpl, 
            intermed.hhint, 
            sys.loctax.ct )
    calc_ctr!( 
        hres, cpl, intermed, 
        sys.uc, 
        sys.ctr, 
        sys.age_limits,
        sys.hours_limits,
        sys.child_limits,
        sys.minwage )
    @show hres.bus[1].ctr
    @show hres.bus[1].pers[head.pid].income[LOCAL_TAXES]
    @show hres.bus[1].pers[head.pid].income[COUNCIL_TAX_BENEFIT]
end