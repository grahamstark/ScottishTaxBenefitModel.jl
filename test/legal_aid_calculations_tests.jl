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

@testset "Ist Spreadsheet Examples from calculator" begin
    
    hh = make_hh( adults = 1 )
    for( pid, pers ) in hh.people
        empty!(pers.income)
        pers.cost_of_childcare = 0
        println( pers.income )
    end
    hh.gross_rent = 0.0
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    hhead = get_head( hh )
    income = 25_000/WEEKS_PER_YEAR
    hhead.income[wages] = income 
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil )
    println( hres.legalaid.civil )
end