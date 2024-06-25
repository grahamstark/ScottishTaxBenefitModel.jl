#=
 Ist Spreadsheet Examples from calculator 
 docs/legalaid/testcalcs.ods
=#

using Test
using Dates
using Format
using PrettyTables 
using Base.Threads
using ChunkSplitters
using ArgCheck

using DataFrames, CSV

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
    household_composition_1,
    is_single,
    num_people,
    num_children,
    num_std_bus,

    pers_is_carer,
    pers_is_disabled, 
    search,
    to_string

using .RunSettings: Settings 

using .STBParameters

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
using .LegalAidData
using .LegalAidOutput
# using .LegalAidRunner

using .SingleHouseholdCalculations: do_one_calc

using .STBOutput: LA_TARGETS

using .HTMLLibs

import .Runner

sys = get_system( year=2023, scotland=true )
print = PrintControls()

function lasettings()
    settings = Settings()
    settings.run_name = "Local Legal Aid Runner Test - base case"
    settings.export_full_results = true
    settings.do_legal_aid = true
    settings.wealth_method = other_method_1
    settings.requested_threads = 4
    settings.num_households, settings.num_people, nhh2 = 
        FRSHouseholdGetter.initialise( settings; reset=true )
    return settings
end

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

sys1 = deepcopy(sys)
sys1.legalaid.civil.included_capital = WealthSet([net_financial_wealth, net_physical_wealth ])
sys2 = deepcopy( sys1 )
# sys2.legalaid.civil.income_living_allowance = 1_000/WEEKS_PER_YEAR

@testset "Run From Standard Runner" begin
    settings = lasettings()
    settings.run_name="Test of LA running just in full model."
    settings.requested_threads = 4
    settings.wealth_method = other_method_1
    settings.run_name = "Direct Run"
    sys2 = deepcopy(sys1)
    settings.do_legal_aid = true

    results = Runner.do_one_run( settings, [sys1,sys2], obs )
    outf = summarise_frames!( results, settings )
    LegalAidOutput.dump_frames( outf.legalaid, settings; num_systems=2 )
    # @show results.legalaid
    LegalAidOutput.dump_tables( outf.legalaid, settings; num_systems=2)
end

@testset "LA utils tests" begin
    exp1 = Expense( false, 1.0, typemax(Float64))
    exp2 = Expense( true, 12.0, typemax(Float64))
    @test do_expense( 100, exp1 ) ≈ 100
    @test do_expense( 100, exp2 ) ≈ 12
end

@testset "AA from spreadsheet" begin
    hh = make_hh( adults = 1 )
    @test num_std_bus(hh) == 1
    @test household_composition_1(hh) == single_person
    settings = Settings()
    settings.wealth_method = imputation 
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
        DEFAULT_NUM_TYPE,
        settings,
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.aa, sys.nmt_bens, sys.age_limits )
    ares = hres.bus[1].legalaid.aa    
    @test ares.eligible
    @test to_nearest_p(ares.income_contribution,0)
    @test to_nearest_p(ares.disposable_income,100)
    @test to_nearest_p(ares.income_allowances,0.0)

    blank_incomes!( hh, 120; annual=false )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.aa, sys.nmt_bens, sys.age_limits )
    ares = hres.bus[1].legalaid.aa
    println( ares )

    @test ares.eligible
    @test to_nearest_p(ares.income_contribution,21.0)

    hh.net_financial_wealth = 1_800.0
    hres = init_household_result( hh )
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.aa, sys.nmt_bens, sys.age_limits )
    ares = hres.bus[1].legalaid.aa    
    @test ! ares.eligible
    @test ! ares.eligible_on_capital 
    @test ares.eligible_on_income 

    hh.net_financial_wealth = 1_700.0
    hres = init_household_result( hh )
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.aa, sys.nmt_bens, sys.age_limits )
    ares = hres.bus[1].legalaid.aa    
    @test ares.eligible
    @test ares.eligible_on_capital 
    @test ares.eligible_on_income 
    @test to_nearest_p(ares.income_contribution,21.0)

    add_spouse!( hh, 50, Female )
    blank_incomes!( hh, 130; annual=false )
    hres = init_household_result( hh )
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.aa, sys.nmt_bens, sys.age_limits )
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
        DEFAULT_NUM_TYPE,
        settings,
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.aa, sys.nmt_bens, sys.age_limits )
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
        DEFAULT_NUM_TYPE,
        settings,
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.aa, sys.nmt_bens, sys.age_limits )
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
    settings = Settings()
    settings.wealth_method = imputation 
    # FIXME read the spreadsheet in and automate this.

    # 1) single adult 25k no expenses 1k capital
    hh = make_hh( adults = 1 )
    blank_incomes!( hh, 25_000)
    hh.gross_rent = 0.0
    hh.net_housing_wealth = 0.0
    hh.net_financial_wealth = 1_000.0
    hh.net_pension_wealth = 0.0
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil, sys.nmt_bens, sys.age_limits )
    cres = hres.bus[1].legalaid.civil
    @test to_nearest_p(cres.income_contribution*WEEKS_PER_YEAR,14004.77)
    @test to_nearest_p(cres.disposable_income*WEEKS_PER_YEAR,25_000)
    @test to_nearest_p(cres.income_allowances*WEEKS_PER_YEAR,0.0)
    @test !cres.passported
    @test cres.eligible

    # 2) as above but married 

    add_spouse!( hh, 50, Female )
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    blank_incomes!( hh, 25_000 )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil, sys.nmt_bens, sys.age_limits )
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
        DEFAULT_NUM_TYPE,
        settings,
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil, sys.nmt_bens, sys.age_limits )
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
        DEFAULT_NUM_TYPE,
        settings,
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil, sys.nmt_bens, sys.age_limits )
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
        DEFAULT_NUM_TYPE,
        settings,
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil, sys.nmt_bens, sys.age_limits )
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
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil, sys.nmt_bens, sys.age_limits )
    cres = hres.bus[1].legalaid.civil
    @test cres.passported

    # plus 200pw housing
    hh.gross_rent = 10_000/WEEKS_PER_YEAR
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    head = get_head(hh)
    hres = init_household_result( hh )
    calc_legal_aid!( hres, hh, intermed, sys.legalaid.civil, sys.nmt_bens, sys.age_limits )
    cres = hres.bus[1].legalaid.civil
    @test to_nearest_p( cres.income_contribution*WEEKS_PER_YEAR,276.54)
    @test to_nearest_p( cres.capital_contribution, 4_147 )
    @test to_nearest_p( cres.disposable_income*WEEKS_PER_YEAR,4_359.00  )
    @test to_nearest_p( cres.income_allowances*WEEKS_PER_YEAR,10_641)
    @test !cres.passported
    @test cres.eligible
    println( head )
    println( cres )
    HTMLLibs.format( hh, hres, hres; settings=settings, print=PrintControls() )
end
  
@testset "Expenses Test" begin

end

@testset "Extra Allowance Test" begin
    settings = Settings()
    settings.wealth_method = imputation 
 
    hh = get_example(single_parent_hh)
    head = get_head(hh)
    blank_incomes!( hh, 35_000 )
    
    sys3 = deepcopy(sys1)
    sys3.legalaid.civil.premia.family_lone_parent = 100.0
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh,  
        sys.hours_limits,
        sys.age_limits,
        sys.child_limits )
    pre = init_household_result( hh )
    calc_legal_aid!( pre, hh, intermed, sys1.legalaid.civil, sys1.nmt_bens, sys1.age_limits )
    post = init_household_result( hh )
    calc_legal_aid!( post, hh, intermed, sys3.legalaid.civil, sys1.nmt_bens, sys1.age_limits )
    r1 = pre.bus[1].legalaid.civil
    r2 = post.bus[1].legalaid.civil
    @assert r1.extra_allowances ≈ 0 "1 should be 0 was $(pre.bus[1].legalaid.civil.extra_allowances)"
    @assert r2.extra_allowances ≈ 100 "2 should be 100 was $(post.bus[1].legalaid.civil.extra_allowances)"
    @assert (r1.disposable_income - r2.disposable_income) ≈ 100 "inc should be 100 lower is r1=$(r1.disposable_income) r2=$(r2.disposable_income)"
    @show HTMLLibs.format( pre.bus[1].legalaid.civil, post.bus[1].legalaid.civil )

    sys3.legalaid.civil.premia.family = 50
    pre = init_household_result( hh )
    calc_legal_aid!( pre, hh, intermed, sys1.legalaid.civil, sys1.nmt_bens, sys1.age_limits )
    post = init_household_result( hh )
    calc_legal_aid!( post, hh, intermed, sys3.legalaid.civil, sys1.nmt_bens, sys1.age_limits )
    r1 = pre.bus[1].legalaid.civil
    r2 = post.bus[1].legalaid.civil
    @assert r1.extra_allowances ≈ 0 "1 should be 0 was $(pre.bus[1].legalaid.civil.extra_allowances)"
    @assert r2.extra_allowances ≈ 150 "2 should be 100+50 was $(post.bus[1].legalaid.civil.extra_allowances)"
    @assert (r1.disposable_income - r2.disposable_income) ≈ 150 "inc should be 100 lower is r1=$(r1.disposable_income) r2=$(r2.disposable_income)"
    @show HTMLLibs.format( pre.bus[1].legalaid.civil, post.bus[1].legalaid.civil )
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

function test_costs( 
    label :: String,
    propensities :: DataFrame,
    costs :: DataFrame  )
    prop_grp = groupby( propensities, [:hsm])
    cost_grp = groupby( costs, [:hsm])
    for (k,v) in pairs( prop_grp )
        if k.hsm != "aa_total"
            entcost = sum(v.popn .* v.case_freq .* v.costs_mean )
            # can't reuse key, so..
            ck = NamedTuple( [:hsm => k.hsm] )
            cgc = cost_grp[ck]
            @show ck
            actcost = sum( cgc.totalpaid )
            @assert isapprox(entcost,actcost/1000; rtol=0.1) "$label : fail cost for $k actual $actcost modelled $entcost" 
        end
    end
end

@testset "Capital versions" begin
    settings = lasettings()
	# Observer as a global.
	n = settings.num_households 
    capdf = DataFrame( 
        hid = fill(BigInt(0), n ),
        data_year = fill(0, n ),
        cap_matching = zeros(n),
        cap_imputation = zeros(n),
        cap_no_method = zeros(n),
        cap_other_method_1 = zeros(n))
    for capt in [ 
            matching,
            imputation,
            no_method,
            other_method_1]
        settings.num_households, 
        settings.num_people = 
            FRSHouseholdGetter.initialise( settings; reset=true )
        settings.wealth_method = capt
        for hno in 1:n
            hh = FRSHouseholdGetter.get_household( hno )
            cf = capdf[hno,:]
            intermed = make_intermediate( 
                DEFAULT_NUM_TYPE,
                settings,
                hh, 
                sys.hours_limits, 
                sys.age_limits, 
                sys.child_limits )
            col = Symbol("cap_$capt") 
            cf[col] = intermed.hhint.net_financial_wealth 
            cf.hid = hh.hid
            cf.data_year = hh.data_year  
        end
    end
    pfname = "$(settings.output_dir)/capcompare-w3.tab"
    CSV.write( pfname, capdf; delim='\t' )
end

@testset "effect of mortgage" begin
    global tot
    tot = 0
    settings = lasettings()

    settings.run_name = "Include_mortgage_repayments off"
    sys2 = deepcopy(sys1)
    systems = [sys1, sys2]
    sys2.legalaid.civil.include_mortgage_repayments = false
    @time results = Runner.do_one_run( settings, systems, obs )
    outf = summarise_frames!( results, settings )
    LegalAidOutput.dump_tables( outf.legalaid, settings; num_systems=2 )
end

#=
@testset "using LegalAidRunner" begin
    global tot
    tot = 0
    settings = lasettings()

    settings.run_name = "Local Legal Aid Runner Test V2"
    sys2 = deepcopy(sys1)
    systems = [sys1, sys2]

    @time laout = LegalAidRunner.do_one_run( settings, systems, obs )
    LegalAidOutput.dump_frames( laout, settings; num_systems=2 )
    
    println( "run complete")
    civil_propensities = LegalAidOutput.create_base_propensities( 
        laout.civil.data[1], 
        LegalAidData.CIVIL_COSTS ).long_data
    aa_propensities = LegalAidOutput.create_base_propensities( 
        laout.aa.data[1], 
        LegalAidData.AA_COSTS ).long_data
    pfname = "$(settings.output_dir)/legal_aid_civil_propensities.tab"
    CSV.write( pfname, LegalAidOutput.PROPENSITIES.civil_propensities; delim='\t' )
    pfname = "$(settings.output_dir)/legal_aid_aa_propensities.tab"
    CSV.write( pfname, LegalAidOutput.PROPENSITIES.aa_propensities; delim='\t' )
    test_costs( "Civil", 
        civil_propensities, LegalAidData.CIVIL_COSTS )
    test_costs( "AA", 
        aa_propensities, LegalAidData.AA_COSTS )
    
end

@testset "inferred vs FRS capital" begin
    # FIXME does nothing now needs 2 runs with settings.wealth_method changed
    sys2 = deepcopy(sys1)
    systems = [sys1, sys2]
    settings = lasettings()
    settings.run_name = "Test of inferred capital 2 off"
    sys2.legalaid.civil.use_inferred_capital = false
    @time laout = LegalAidRunner.do_one_run( settings, systems, obs )
    LegalAidOutput.dump_tables( laout, settings; num_systems=2 )
    LegalAidOutput.dump_frames( laout, settings; num_systems=2 )

end

@testset "sp premia" begin
    settings = lasettings()
    settings.wealth_method = imputation 

    settings.requested_threads = 4
    settings.run_name = "sing par premia"
    sys2 = deepcopy(sys1)
    sys2.legalaid.civil.premia.family_lone_parent = 2000.0/52
    sys2.legalaid.aa.premia.family_lone_parent = 2000.0/52

    systems = [sys1, sys2]
    @time laout = LegalAidRunner.do_one_run( settings, systems, obs )
    examples = laout.aa.crosstab_pers_examples[1]
    LegalAidOutput.dump_frames( laout, settings; num_systems=2 )
    LegalAidOutput.dump_tables( laout, settings; num_systems=2)
    @show examples
    #=
    for hid in examples[3,1]
        
        hh,res = LegalAidRunner.calculate_one( hid, [sys1, sys2 ] )
        @show hh
        @show res[1]
        @show res[2]
    end
    =#
end


@testset "uc limits" begin
    settings = lasettings()
    settings.requested_threads = 4
    settings.run_name = "uc limits"
    sys2 = deepcopy(sys1)
    sys2.legalaid.civil.uc_limit = 25.0 #/WEEKS_PER_YEAR
    sys2.legalaid.aa.uc_limit = 25.0 #/WEEKS_PER_YEAR
    sys2.legalaid.civil.uc_limit_type = uc_min_payment
    sys2.legalaid.aa.uc_limit_type = uc_min_payment
    systems = [sys1, sys2]
    @time laout = LegalAidRunner.do_one_run( settings, systems, obs )
    examples = laout.aa.crosstab_pers_examples[1]
    LegalAidOutput.dump_frames( laout, settings; num_systems=2 )
    LegalAidOutput.dump_tables( laout, settings; num_systems=2)
    @show examples
    #=
    for hid in examples[3,1]
        
        hh,res = LegalAidRunner.calculate_one( hid, [sys1, sys2 ] )
        @show hh
        @show res[1]
        @show res[2]
    end
    =#
end

"""
Fixme turn this into something slightly generic.
"""
function nothing_increased_and_something_reduced(
    ;
    pre :: DataFrame,
    post :: DataFrame,
    label :: String )::String
    @argcheck size(pre) == size(post)
    @argcheck names(pre) == names(post)
    out =""
    nms = names(pre)
    nrows, ncols = size( pre )
    someimproved = false
    someworse = false
    for c in 2:ncols # skip label col at start
        for r in 1:nrows
            # these are costs so up is worse.
            if pre[r,c] > (post[r,c]+0.00001)
                someworse = true
            elseif post[r,c] > (pre[r,c]+0.00001)
                @show pre
                @show post
                out = "IMPROVEMENT for category $(pre[r,1]) type $(nms[c]) table $label"
                break
            end
        end # rows
    end # cols
    if ! someworse
        out = "NO Worseing for any field table $label"
    end
    return out
end

@testset "No Passporting - should always reduce costs and eligibility." begin
    settings = lasettings()
    settings.requested_threads = 4
    settings.run_name = "No Passporting"
    sys2 = deepcopy(sys1)
    sys2.legalaid.civil.passported_benefits=[]
    sys2.legalaid.aa.passported_benefits=[]
    systems = [sys1, sys2]
    @time laout = LegalAidRunner.do_one_run( settings, systems, obs )
    LegalAidOutput.dump_frames( laout, settings; num_systems=2 )
    LegalAidOutput.dump_tables( laout, settings; num_systems=2)
    for t in LA_TARGETS
        println( setdiff( 
            names( laout.civil.cases_pers[1][t]),
            names( laout.civil.cases_pers[2][t])))
        @test nothing_increased_and_something_reduced(
            pre=laout.civil.cases_pers[1][t],
            post=laout.civil.cases_pers[2][t],
            label="Civil cases table $t" ) == ""
        @test nothing_increased_and_something_reduced(
            pre=laout.civil.costs_pers[1][t],
            post=laout.civil.costs_pers[2][t],
            label="Civil cost table $t" ) == ""
        @test nothing_increased_and_something_reduced(
            pre=laout.aa.cases_pers[1][t],
            post=laout.aa.cases_pers[2][t],
            label="AA count table $t" ) == ""
        @test nothing_increased_and_something_reduced(
            pre=laout.aa.costs_pers[1][t],
            post=laout.aa.costs_pers[2][t],
            label="AA cost table $t" ) == ""
    end # breakdown loop
end # testset
=#



  