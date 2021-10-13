using Test
using ScottishTaxBenefitModel
using .ModelHousehold: 
    Household,
    get_benefit_units,
    get_head

using .STBIncomes 

using .Results: 
    BenefitUnitResult,
    HouseholdResult,
    HousingResult,
    IndividualResult,
    ITResult,
    LMTCanApplyFor,
    LMTIncomes,
    LMTResults,
    LocalTaxes,
    NIResult, 

    aggregate_tax,
    aggregate!,
    has_any,
    init_benefit_unit_result,
    init_household_result,
    map_incomes,
    to_string,
    total
using .ExampleHelpers
#
#
#

@testset "Results record creation and summation" begin
    sph = get_example( single_parent_hh )
    sph.gross_rent = 200.0
    sph.water_and_sewerage = 0
    sph.mortgage_payment = 0

    hrs :: HouseholdResult = init_household_result( sph )
    head :: Person = get_head(sph)
    hp = head.pid
    headr :: IndividualResult = hrs.bus[1].pers[hp]
    headr.income[INCOME_TAX] = 100.0
    aggregate!( sph, hrs )
    @test hrs.income[INCOME_TAX] == 100.0
    @test hrs.bus[1].income[INCOME_TAX] == 100.0
    # check we don't ever double-count
    aggregate!( sph, hrs )
    @test hrs.income[INCOME_TAX] == 100.0
    @test hrs.bus[1].income[INCOME_TAX] == 100.0
    headr.income[WAGES] = 1_000.0
    aggregate!( sph, hrs )
    @test hrs.income[WAGES] == 1_000.0
    @test hrs.bus[1].income[WAGES] == 1_000.0
    @test has_any( hrs, WAGES ) 
    @test ! has_any( hrs, SELF_EMPLOYMENT_INCOME ) 

    @test total( hrs, WAGES ) == 1_000.0
    @test total( hrs, SELF_EMPLOYMENT_INCOME ) == 0.0
    println( inctostr( hrs.income ))

    others = 0.2868852459+3.1912568306+30.0+9.95

    @test hrs.bhc_net_income ≈ 900.0+others
    @test hrs.ahc_net_income ≈ 700.0+others

    # multiple benefit units example
    mbhh = get_example( mbu )
    bus = get_benefit_units(mbhh)
    mhead =  get_head(bus[3])
    mhp = mhead.pid

    mhead2 =  get_head(bus[2])
    mhp2 = mhead2.pid

    mhrs  = init_household_result( mbhh )
    mheadr = mhrs.bus[3].pers[mhp]
    mheadr.income[WAGES] = 500.0

    mheadr.ni.class_1_primary = 123.12
    mheadr.it.non_savings_tax = 321.21

    mheadr2 = mhrs.bus[2].pers[mhp2]
    mheadr2.ni.class_1_primary = 100
    mheadr2.it.non_savings_tax = 200

    t_wages = total( mhrs, WAGES )
    mheadr.income[LOCAL_TAXES] = 100
    aggregate!( mbhh, mhrs )

    @test mhrs.bhc_net_income ≈ t_wages
    @test mhrs.ahc_net_income ≈ t_wages - 100 - mbhh.gross_rent

    @test mhrs.income[LOCAL_TAXES] == 100
    @test mhrs.bus[1].income[LOCAL_TAXES] == 0
    @test mhrs.bus[3].income[LOCAL_TAXES] == 100
    
    @test total( mhrs, LOCAL_TAXES ) == 100
    @test has_any( mhrs, LOCAL_TAXES )
    @test has_any( mhrs, LOCAL_TAXES, CHILD_BENEFIT )
    @test has_any( mhrs, [LOCAL_TAXES, CHILD_BENEFIT] )
    @test ! has_any( mhrs, CHILD_BENEFIT,INCOME_SUPPORT )
    @test ! has_any( mhrs, [CHILD_BENEFIT,INCOME_SUPPORT] )

    it, ni = aggregate_tax( mhrs.bus[2] )
    @test ni.class_1_primary == 100
    @test it.non_savings_tax == 200
    @test it.taxable_income == 0

end
    
