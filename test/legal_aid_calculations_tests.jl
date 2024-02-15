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

using .IncomeTaxCalculations: 
    calc_income_tax!

using .Definitions
 
using .Intermediate: 
    MTIntermediate, 
    apply_2_child_policy,
    make_intermediate 

using .Results: 
    BenefitUnitResult,
    OneLegalAidResult,    
    init_household_result, 
    init_benefit_unit_result, 
    to_string

using .Results: 
    BenefitUnitResult,
    HouseholdResult,
    LegalAidResult,
    OneLegalAidResult

using .Utils: 
    eq_nearest_p,
    to_md_table    
using .ExampleHelpers

using .GeneralTaxComponents:
    WEEKS_PER_MONTH,
    WEEKS_PER_YEAR
using .LegalAidCalculations: calc_legal_aid!

sys = get_system( year=2023, scotland=true )

function blank_incomes!( hh, wage )
    for( pid, pers ) in hh.people
        empty!(pers.income)
        pers.cost_of_childcare = 0.0
        # and others
    end
    hhead = get_head( hh )
    income = wage/WEEKS_PER_YEAR
    hhead.income[wages] = income 

end

@testset "Ist Spreadsheet Examples from calculator" begin
    
    hh = make_hh( adults = 1 )
    blank_incomes!( hh, 25_000 )
    hh.gross_rent = 0.0
    hh.net_housing_wealth = 0.0
    hh.net_financial_wealth = 1_000.0
    hh.net_pension_wealth = 0.0
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil )
    println(sys.legalaid.civil)
    cres = hres.legalaid.civil
    println( cres )
    @test to_nearest_p(cres.income_contribution*WEEKS_PER_YEAR,14004.77)
    @test to_nearest_p(cres.disposable_income*WEEKS_PER_YEAR,25_000)
    @test !cres.passported
    @test cres.eligible
    # ROUNDING @test to_nearest_p(cres.allowances,0.0)
    add_spouse!( hh, 50, Female )
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    blank_incomes!( hh, 25_000 )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil )
    cres = hres.legalaid.civil
    println( "With Spouse $cres" )
    # println(hh)
    add_child!( hh, 12, Male )
    add_child!( hh, 10, Female )
    blank_incomes!( hh, 25_000 )
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil )
    cres = hres.legalaid.civil
    println( "With Spouse + 2 children $cres" )
    println(hh.people[320190000203].relationship_to_hoh)
    hh.net_financial_wealth = 10_000.0
    blank_incomes!( hh, 25_000 )
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil )
    cres = hres.legalaid.civil
    println( "With 10k capital + 2 children $cres" )
    hh.net_financial_wealth = 12_000.0
    blank_incomes!( hh, 25_000 )
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil )
    cres = hres.legalaid.civil
    println( "With 12k capital + 2 children $cres" )
    head = get_head(hh)
    hres = init_household_result( hh )
    head.income[UNIVERSAL_CREDIT] = 1.0
    
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil )
    cres = hres.legalaid.civil
    println( "With UC  + 2 children $cres" )

end