#=
 Ist Spreadsheet Examples from calculator 
 docs/legalaid/testcalcs.ods
=#

using Test
using Dates
using Format
using PrettyTables 

using ScottishTaxBenefitModel

using .Utils: pretty

using .ModelHousehold: 
    Household, 
    Person, 
    People_Dict,     
    default_bu_allocation, 
    get_benefit_units, 
    get_head, 
    get_spouse, 
    has_disabled_member,
    is_single,
    num_people,
    num_children,
    pers_is_carer,
    pers_is_disabled, 
    search,
    to_string

using .RunSettings: Settings 

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
    to_string,
    BenefitUnitResult,
    HouseholdResult,
    OneLegalAidResult

using .Utils: 
    eq_nearest_p,
    to_md_table,
    make_crosstab,
    matrix_to_frame

using .ExampleHelpers

using .STBIncomes

using .GeneralTaxComponents:
    WEEKS_PER_MONTH,
    WEEKS_PER_YEAR

using .LegalAidCalculations: calc_legal_aid!

using .SingleHouseholdCalculations: do_one_calc

using .STBOutput: LA_TARGETS

using DataFrames, CSV
using .Monitor: Progress
using Observables

sys = get_system( year=2023, scotland=true )

function blank_incomes!( hh, wage; annual=true )
    for( pid, pers ) in hh.people
        empty!(pers.income)
        pers.cost_of_childcare = 0.0
        # and others
    end
    hhead = get_head( hh )
    income = wage
    if annual 
        income /= WEEKS_PER_YEAR
    end
    hhead.income[wages] = income 

end

@testset "LA utils tests" begin
    exp1 = Expense( false, 1.0, typemax(Float64))
    exp2 = Expense( true, 12.0, typemax(Float64))
    @test do_expense( 100, exp1 ) ≈ 100
    @test do_expense( 100, exp2 ) ≈ 12
end

@testset "AA from spreadsheet" begin
    hh = make_hh( adults = 1 )
    head = get_head( hh )
    head.age = 45
    println( "hhage $(head.age)")
    blank_incomes!( hh, 100; annual=false )
    hh.gross_rent = 0.0
    hh.net_housing_wealth = 0.0
    hh.net_financial_wealth = 1_000.0
    hh.net_pension_wealth = 0.0
    hres = init_household_result( hh )
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.aa )
    ares = hres.bus[1].legalaid.aa    
    @test ares.eligible
    @test to_nearest_p(ares.income_contribution,0)
    @test to_nearest_p(ares.disposable_income,100)
    @test to_nearest_p(ares.income_allowances,0.0)

    blank_incomes!( hh, 120; annual=false )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.aa )
    ares = hres.bus[1].legalaid.aa
    println( ares )

    @test ares.eligible
    @test to_nearest_p(ares.income_contribution,21.0)

    hh.net_financial_wealth = 1_800.0
    hres = init_household_result( hh )
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.aa )
    ares = hres.bus[1].legalaid.aa    
    @test ! ares.eligible
    @test ! ares.eligible_on_capital 
    @test ares.eligible_on_income 

    hh.net_financial_wealth = 1_700.0
    hres = init_household_result( hh )
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.aa )
    ares = hres.bus[1].legalaid.aa    
    @test ares.eligible
    @test ares.eligible_on_capital 
    @test ares.eligible_on_income 
    @test to_nearest_p(ares.income_contribution,21.0)

    add_spouse!( hh, 50, Female )
    blank_incomes!( hh, 130; annual=false )
    hres = init_household_result( hh )
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.aa )
    ares = hres.bus[1].legalaid.aa    
    @test ares.eligible
    @test ares.eligible_on_capital 
    @test ares.eligible_on_income 
    @test ares.capital_allowances ≈ 335
    @test ares.income_allowances ≈ 48.50
    @test ares.disposable_capital ≈ 1365.0
    @test ares.income_contribution ≈ 0.0
    println( ares )

    #
    # From: 
    # https://www.slab.org.uk/app/uploads/2023/04/Civil-assistance-Keycard-2023-24-1.pdf
    #
    hh = make_hh( adults = 1 )
    head = get_head( hh )
    head.age = 65
    hh.net_financial_wealth = 21_500 
    blank_incomes!( hh, 20; annual=false )
    println( "total hh after blank $(hh)" )
    hres = init_household_result( hh )
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.aa )
    ares = hres.bus[1].legalaid.aa    
    @test ares.disposable_capital ≈ 1_500 
    @test ares.capital_allowances ≈ 20_000
    @test ares.eligible
    @test ares.eligible_on_capital 
    @test ares.eligible_on_income 
    @test to_nearest_p(ares.income_contribution,0.0)
    println( "ares pen $ares")

    hh.net_financial_wealth = 25_000 
    blank_incomes!( hh, 20; annual=false )
    hres = init_household_result( hh )
    intermed = make_intermediate( 
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.aa )
    ares = hres.bus[1].legalaid.aa    
    @test ares.disposable_capital ≈ 5_000 
    @test ares.capital_allowances ≈ 20_000
    @test ! ares.eligible
    @test ! ares.eligible_on_capital 
    @test ares.eligible_on_income 
    @test to_nearest_p(ares.income_contribution,0.0)


    println( get_head( hh ))
end

@testset "Civil Legal Aid: Ist Spreadsheet Examples from calculator docs/legalaid/testcalcs.ods" begin
    
    # FIXME read the spreadsheet in and automate this.

    # 1) single adult 25k no expenses 1k capital
    hh = make_hh( adults = 1 )
    blank_incomes!( hh, 25_000)
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
    @test to_nearest_p(cres.income_allowances*WEEKS_PER_YEAR,0.0)
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
    @test to_nearest_p(cres.income_allowances*WEEKS_PER_YEAR,2_529)
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
    @test to_nearest_p( cres.income_allowances*WEEKS_PER_YEAR,10_641)
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
    @test to_nearest_p( cres.income_allowances*WEEKS_PER_YEAR,10_641)
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
    @test to_nearest_p( cres.income_allowances*WEEKS_PER_YEAR,10_641)
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
    @test to_nearest_p( cres.income_allowances*WEEKS_PER_YEAR,10_641)
    @test !cres.passported
    @test cres.eligible
    println( head )
    println( cres )

end

"""
See PrettyTable documentation for formatter
"""
function pt_fmt(val,row,col)
    if col == 1
      return Utils.pretty(string(val))
    end
    return Format.format(val,commas=true,precision=0)
end

@testset "Create an output table" begin
    settings = Settings()
    sys1 = deepcopy(sys)
    sys1.legalaid.civil.included_capital = WealthSet([net_financial_wealth])
    sys2 = deepcopy( sys1 )
    entstrs = collect(pretty.(string.(instances( LegalAidStatus ))))
    outf, gl = do_basic_run( settings, [sys1,sys2]; reset=false )
    f = open( "la_tables_v1_civil_and_aa.md","w")
    for t in LA_TARGETS
        println(f, "\n## "*Utils.pretty(string(t))); println(f)        
        println(f,"### Civil Legal Aid")
        println(f, "\n#### a) Benefit Units "); 
        pretty_table(f,outf.legalaid[1].civil.breakdown_bu[t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
        println(f, "\n#### b) Individuals "); 
        pretty_table(f,outf.legalaid[1].civil.breakdown_pers[t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
        println(f,"### Advice and Assistance")
        println(f, "\n#### a) Benefit Units "); 
        pretty_table(f,outf.legalaid[1].aa.breakdown_bu[t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
        println(f, "\n#### b) Individuals "); 
        pretty_table(f,outf.legalaid[1].aa.breakdown_pers[t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
        println(f)
    end
    
    println( f, "### cross table civil entitlement")
    pc = matrix_to_frame( outf.legalaid[1].civil.crosstab_bu, entstrs, entstrs )
    pretty_table(f,pc,formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
    println( f, "### cross table AA entitlement")
    pa =  matrix_to_frame( outf.legalaid[1].aa.crosstab_bu, entstrs, entstrs )
    pretty_table(f,pa,formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)



    close(f)

    


end