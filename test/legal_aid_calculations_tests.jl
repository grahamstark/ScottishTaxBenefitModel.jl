#=
 Ist Spreadsheet Examples from calculator 
 docs/legalaid/testcalcs.ods
=#

using Test
using Dates
using Formatting
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
    to_md_table    
using .ExampleHelpers

using .STBIncomes

using .GeneralTaxComponents:
    WEEKS_PER_MONTH,
    WEEKS_PER_YEAR

using .LegalAidCalculations: calc_legal_aid!

using .SingleHouseholdCalculations: do_one_calc

using DataFrames, CSV
using .Monitor: Progress
using Observables

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

function make_legal_aid_frame( RT :: DataType, n :: Int ) :: DataFrame
    return DataFrame(
        hid       = zeros( BigInt, n ),
        sequence  = zeros( Int, n ),
        data_year  = zeros( Int, n ),        
        weight    = zeros(RT,n),
        weighted_people = zeros(RT,n),
        total = ones(RT,n),
        bu_number = zeros( Int, n ),
        num_people = zeros( Int, n ),
        tenure    = fill( Missing_Tenure_Type, n ),
        marital_status = fill( Missing_Marital_Status, n ),
        employment_status = fill(Missing_ILO_Employment, n ),
        decile = zeros( Int, n ),
        in_poverty = fill( false, n ),
        ethnic_group = fill(Missing_Ethnic_Group, n ),
        any_disabled = fill(false,n),
        with_children = fill(false,n),
        any_pensioner = fill(false,n),
        all_eligible = zeros(RT,n),
        mt_eligible = zeros(RT,n),
        passported = zeros(RT,n),
        any_contribution = zeros(RT,n),
        income_contribution = zeros(RT,n),
        capital_contribution = zeros(RT,n),
        disqualified_on_income = zeros(RT,n), 
        disqualified_on_capital = zeros(RT,n))
end

function fill_legal_aid_frame_row!( 
    hr   :: DataFrameRow, 
    hh   :: Household, 
    hres :: HouseholdResult,
    buno :: Int )
    hr.hid = hh.hid
    hr.sequence = hh.sequence
    hr.data_year = hh.data_year
    hr.weight = hh.weight
    bu = get_benefit_units( hh )[buno]
    nps = num_people( bu )
    hr.num_people = nps
    hr.bu_number = buno
    hr.weighted_people = hh.weight*nps
    hr.tenure = hh.tenure
    # hr.in_poverty
    head = get_head( bu )
    hr.ethnic_group = head.ethnic_group
    hr.employment_status = head.employment_status
    hr.marital_status = head.marital_status
    hr.any_disabled = has_disabled_member( bu )
    hr.with_children = num_children( bu ) > 0
    lr = hres.bus[buno].legalaid.civil
    hr.all_eligible = lr.eligible | lr.passported
    hr.mt_eligible = lr.eligible
    hr.passported = lr.passported
    hr.any_contribution = (lr.capital_contribution + lr.income_contribution) > 0
    hr.capital_contribution = lr.capital_contribution > 0
    hr.income_contribution = lr.income_contribution > 0
    hr.disqualified_on_income = ! lr.eligible_on_income
    hr.disqualified_on_capital = ! lr.eligible_on_capital
end

function larun()
    settings = Settings()
    tot = 0
    obs = Observable( Progress(settings.uuid,"",0,0,0,0))
    of = on(obs) do p
        println(p)
        tot += p.step
        println(tot)
    end  
    sys = [
        get_default_system_for_fin_year(2023; scotland=true), 
        get_default_system_for_fin_year( 2023; scotland=true )]    
    settings.do_marginal_rates = false
    @time settings.num_households, settings.num_people, nhh2 = initialise( settings, reset=false )
    df = make_legal_aid_frame( Float64, settings.num_households*2 )
    nbus = 0
    println( "settings.num_households = $(settings.num_households)")
    for hno in 1:settings.num_households
        hh = get_household(hno)
        rc = do_one_calc( hh, sys[1], settings )        
        if(hno % 1000) == 0
            println( ModelHousehold.to_string(hh) )
            println( Results.to_string(rc.bus[1]))
        end
        bus = get_benefit_units(hh)
        for buno in 1:size(bus)[1]
            nbus += 1
            fill_legal_aid_frame_row!( df[nbus,:], hh, rc, buno ) 
        end
    end
    df[1:nbus,:]
end

const LA_BITS=[
    :total, 
    :all_eligible,
    :passported,
    :mt_eligible,
    :any_contribution,
    :income_contribution,
    :capital_contribution,
    :disqualified_on_income,
    :disqualified_on_capital]
const LA_LABELS = [
    "Total",
    "All Eligible",
    "Passported",
    "Eligible On Means Test",
    "Any Contribution",
    "Income Contribution",
    "Capital Contribution",
    "Disqualified on Income",
    "Disqualified on Capital"]
const TARGETS = [
    :employment_status,
    :tenure, 
    :ethnic_group, 
    :bu_number, 
    :marital_status, 
    :any_disabled,
    :num_people,
    :with_children]

function one_combine( df :: DataFrame, to_combine :: Symbol, weight_sym :: Symbol )::AbstractDataFrame
    wbits = []
    for l in LA_BITS
        psym = Symbol( "wt_$(l)")
        df[:,psym] .= df[:,weight_sym].*df[:,l]
        push!( wbits, psym )
    end
    gdf = groupby( df, to_combine )
    outf = combine( gdf, wbits .=>sum )
    labels = push!( [Utils.pretty(string(to_combine))], LA_LABELS... )
    rename!( outf, labels )
    outf
end

function aggregate_all( df :: DataFrame, weight_sym :: Symbol ) :: Dict
    alltab = Dict()
    for t in TARGETS
        gdp = one_combine( df, t, weight_sym )
        alltab[t] = gdp
    end
    alltab
end

"""
See PrettyTable documentation for formatter
"""
function pt_fmt(val,row,col)
    if col == 1
      return Utils.pretty(string(val))
    end
    return Formatting.format(val,commas=true,precision=0)
end




@testset "Create an output table" begin
    df = larun()
end