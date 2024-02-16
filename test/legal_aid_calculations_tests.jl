#=
 Ist Spreadsheet Examples from calculator 
 docs/legalaid/testcalcs.ods
=#

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
using .STBParameters:
    do_expense,
    Expense,
    ScottishLegalAidSys

using .IncomeTaxCalculations: 
    calc_income_tax!

using .Definitions
 
using .Intermediate: 
    MTIntermediate, 
    apply_2_child_policy,
    make_intermediate 

using .Results: 
    get_indiv_result,
    init_household_result, 
    init_benefit_unit_result, 
    to_string
    BenefitUnitResult,
    LegalAidResult,
    HouseholdResult,
    OneLegalAidResult

using .Utils: 
    eq_nearest_p,
    to_md_table    
using .ExampleHelpers

using .STBIncomes

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

@testset "LA utils tests" begin
    exp1 = Expense( false, 1.0, typemax(Float64))
    exp2 = Expense( true, 12.0, typemax(Float64))
    @test do_expense( 100, exp1 ) ≈ 100
    @test do_expense( 100, exp2 ) ≈ 12
end

@testset "Ist Spreadsheet Examples from calculator docs/legalaid/testcalcs.ods" begin
    
    # FIXME read the spreadsheet in and automate this.

    # 1) single adult 25k no expenses 1k capital
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
    cres = hres.bus[1].legalaid.civil
    @test to_nearest_p(cres.income_contribution*WEEKS_PER_YEAR,14004.77)
    @test to_nearest_p(cres.disposable_income*WEEKS_PER_YEAR,25_000)
    @test to_nearest_p(cres.allowances*WEEKS_PER_YEAR,0.0)
    @test !cres.passported
    @test cres.eligible

    # 2) as above but married 

    add_spouse!( hh, 50, Female )
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    blank_incomes!( hh, 25_000 )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil )
    cres = hres.bus[1].legalaid.civil

    @test to_nearest_p(cres.income_contribution*WEEKS_PER_YEAR,11_475.77)
    @test to_nearest_p( cres.capital_contribution, 0 )
    @test to_nearest_p(cres.disposable_income*WEEKS_PER_YEAR,22_471)
    @test to_nearest_p(cres.allowances*WEEKS_PER_YEAR,2_529)
    @test !cres.passported
    @test cres.eligible

    # 3) 2 young children

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
    cres = hres.bus[1].legalaid.civil
    @test to_nearest_p( cres.income_contribution*WEEKS_PER_YEAR,4055.77)
    @test to_nearest_p( cres.capital_contribution, 0 )
    @test to_nearest_p( cres.disposable_income*WEEKS_PER_YEAR,14_359)
    @test to_nearest_p( cres.allowances*WEEKS_PER_YEAR,10_641)
    @test !cres.passported
    @test cres.eligible

    # 4) add 10k capital

    hh.net_financial_wealth = 10_000.0
    blank_incomes!( hh, 25_000 )
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil )
    cres = hres.bus[1].legalaid.civil
    
    @test to_nearest_p( cres.income_contribution*WEEKS_PER_YEAR,4055.77)
    @test to_nearest_p( cres.capital_contribution, 2147 )
    @test to_nearest_p( cres.disposable_income*WEEKS_PER_YEAR,14_359)
    @test to_nearest_p( cres.allowances*WEEKS_PER_YEAR,10_641)
    @test !cres.passported
    @test cres.eligible

    # 5) 12k capital

    hh.net_financial_wealth = 12_000.0
    blank_incomes!( hh, 25_000 )
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil )
    cres = hres.bus[1].legalaid.civil
    head = get_head(hh)
    hres = init_household_result( hh )
    @test to_nearest_p( cres.income_contribution*WEEKS_PER_YEAR,4055.77)
    @test to_nearest_p( cres.capital_contribution, 4_147 )
    @test to_nearest_p( cres.disposable_income*WEEKS_PER_YEAR,14_359)
    @test to_nearest_p( cres.allowances*WEEKS_PER_YEAR,10_641)
    @test !cres.passported
    @test cres.eligible
    
    # 6) passporting check 

    headres = get_indiv_result( hres, head.pid )
    headres.income[UNIVERSAL_CREDIT] = 1.0    
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil )
    cres = hres.bus[1].legalaid.civil
    @test cres.passported

    # plus 200pw housing
    hh.gross_rent = 10_000/WEEKS_PER_YEAR
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    head = get_head(hh)
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil )
    cres = hres.bus[1].legalaid.civil
    
    @test to_nearest_p( cres.income_contribution*WEEKS_PER_YEAR,276.54)
    @test to_nearest_p( cres.capital_contribution, 4_147 )
    @test to_nearest_p( cres.disposable_income*WEEKS_PER_YEAR,4_359.00  )
    @test to_nearest_p( cres.allowances*WEEKS_PER_YEAR,10_641)
    @test !cres.passported
    @test cres.eligible

end