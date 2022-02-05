using Test
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
    num_children,
    pers_is_carer,
    pers_is_disabled, 
    search

using .GeneralTaxComponents: 
    WEEKS_PER_MONTH,
    WEEKS_PER_YEAR
    
using .ExampleHouseholdGetter
using .Definitions

using .TimeSeriesUtils: fy_from_bits
using .HistoricBenefits: 
    RATIO_BENS,
    make_benefit_ratios!
    

using .STBIncomes
using .Intermediate: 
    MTIntermediate, 
    apply_2_child_policy,
    make_intermediate
    
using .NonMeansTestedBenefits: 
    calc_widows_benefits, 
    calc_state_pension,
    calc_child_benefit!,
    calc_pip,
    calc_attendance_allowance,
    calc_dla,
    calc_esa,
    calc_maternity_allowance,
    calc_carers_allowance,
    calc_jsa,
    calc_pre_tax_non_means_tested!,
    calc_post_tax_non_means_tested!
    
using .IncomeTaxCalculations: 
    calc_income_tax!

using .STBParameters: 
    AttendanceAllowance, 
    ChildBenefit, 
    DisabilityLivingAllowance,
    CarersAllowance, 
    PersonalIndependencePayment, 
    ContributoryESA,
    WidowsPensions, 
    BereavementSupport, 
    RetirementPension, 
    JobSeekersAllowance,
    NonMeansTestedSys

using .Results: 
    LMTResults, 
    BenefitUnitResult,
    init_household_result

using .ExampleHelpers

using Dates

## FIXME don't need both
sys = get_system( scotland=true )
ruksys = get_system( scotland=false )
itsys_scot = get_default_it_system( year=2019, scotland=true )

@testset "CB" begin
    cb = sys.nmt_bens.child_benefit
    sph = get_example( single_parent_hh )
    hhres = init_household_result( sph )
    bu = get_benefit_units( sph )[1]
    head = get_head( bu )
    hp = head.pid
    bures = hhres.bus[1]
    @test num_children( bu ) == 2
    calc_child_benefit!( bures, bu, cb )
    @test bures.pers[hp].income[GUARDIANS_ALLOWANCE] == 0
    @test bures.pers[hp].income[CHILD_BENEFIT] ≈ 34.40
    # one of two is now non-related
    head.relationships[320190010302] = Other_relative
    calc_child_benefit!( bures, bu, cb )
    @test bures.pers[hp].income[GUARDIANS_ALLOWANCE] == 17.20
    @test bures.pers[hp].income[CHILD_BENEFIT] ≈ 34.40
    # cap - 2k over so £20 pw reduction
    head.income = Incomes_Dict{Float64}() # clear other incomes
    head.income[wages] = 52_000/WEEKS_PER_YEAR
    
    hhres = init_household_result( sph )
    bures = hhres.bus[1]
    # for total income calculation
    calc_income_tax!(
        bures,
        head,
        nothing,
        itsys_scot )

    calc_child_benefit!( bures, bu, cb )
    @test bures.pers[hp].income[GUARDIANS_ALLOWANCE] == 17.20
    @test bures.pers[hp].income[CHILD_BENEFIT] ≈ (34.40 - 20)
end

@testset "PIP" begin
    pip = sys.nmt_bens.pip
    sph = get_example( single_parent_hh )
    head = get_head( sph )
    disable_seriously!( head )
    head.pip_daily_living_type = standard_pip
    head.pip_mobility_type = enhanced_pip
    pl,pm = calc_pip( head, pip )
    @test (pl+pm) ≈ 119.90
end

@testset "AA" begin
    aa = sys.nmt_bens.attendance_allowance
    sph = get_example( single_parent_hh )
    head = get_head( sph )
    disable_seriously!( head )
    head.attendance_allowance_type = high 
    a = calc_attendance_allowance( head, aa )
    @test a ≈ 87.65
end

@testset "DLA" begin
    dla = sys.nmt_bens.dla
    sph = get_example( single_parent_hh )
    head = get_head( sph )
    disable_seriously!( head )
    head.dla_self_care_type = mid
    dd,dm = calc_dla( head, dla )
    @test dd ≈ 58.70
    @test dm == 0
    head.dla_mobility_type = high
    dd,dm = calc_dla( head, dla )
    @test dd ≈ 58.70
    @test dm ≈ 61.20  
end

@testset "ESA" begin
    esa = sys.nmt_bens.esa
    sph = get_example( single_parent_hh )
    head = get_head( sph )
    head.esa_type = contributory_jsa
    e = calc_esa( head, esa )
    @test e ≈ 73.10
    head.age = 22
    e = calc_esa( head, esa )
    @test e ≈ 57.90
    # should put them in `has_limited_capactity_for_work_activity`
    disable_seriously!( head )
    head.age = 50
    e = calc_esa( head, esa )
    @test e ≈ 73.10 + 38.55        
end

@testset "Maternity" begin
    mat = sys.nmt_bens.maternity
    sph = get_example( single_parent_hh )
    head = get_head( sph )
    head.income[maternity_allowance] = 123
    m = calc_maternity_allowance( head, mat )
    @test m ≈ 148.68

end

@testset "Carers" begin
    care = sys.nmt_bens.carers
    sph = get_example( single_parent_hh )
    head = get_head( sph )
    hp = head.pid
    unemploy!( head )
    head.hours_of_care_given = 60
    hhres = init_household_result( sph )
    bures = hhres.bus[1]
    # for total income calculation
    calc_income_tax!(
        bures,
        head,
        nothing,
        itsys_scot )
    pres = bures.pers[hp]    
    c = calc_carers_allowance( head, pres, care )
    @test c ≈ 66.15
    employ!( head )
    hhres = init_household_result( sph )
    bures = hhres.bus[1]    
    calc_income_tax!(
        bures,
        head,
        nothing,
        itsys_scot )
    pres = bures.pers[hp]    
    c = calc_carers_allowance( head, pres, care )
    @test c == 0.0
end

@testset "JSA" begin
    sph = get_example( single_parent_hh )
    head = get_head( sph )
    hp = head.pid
    unemploy!( head )
    head.jsa_type = contributory_jsa
    head.age = 23
    j = calc_jsa( head, sys.nmt_bens.jsa, sys.hours_limits )
    @test j ≈ 57.90
    head.age = 50
    j = calc_jsa( head, sys.nmt_bens.jsa, sys.hours_limits  )
    @test j ≈ 73.10
    employ!( head )
    j = calc_jsa( head, sys.nmt_bens.jsa, sys.hours_limits  )
    @test j ≈ 0.0    
end

@testset "Widows" begin
    bp = sys.nmt_bens.bereavement
    wp = sys.nmt_bens.widows_pension
    sph = get_example( single_parent_hh )
    fy = fy_from_bits( sph.interview_year, sph.interview_month )
    @test fy == 2019

    bu = get_benefit_units( sph )[1]
    head = get_head( bu )
    # old style 
    head.income[bereavement_allowance_or_widowed_parents_allowance_or_bereavement] = 100.0
    head.bereavement_type = widowed_parents    
    make_benefit_ratios!( head, sph.interview_year, sph.interview_month )
    
    p = calc_widows_benefits( head, true, bp, wp )
    @test p ≈ wp.standard_rate*100.0/119.9 # sys.widows_pension.standard_rate
    head.bereavement_type = bereavement_allowance
    p = calc_widows_benefits( head, true, bp, wp )
    @test p ≈ bp.lump_sum_higher*2/3 + bp.higher
    
end

@testset "State Pension" begin
    rp = sys.nmt_bens.pensions
    hh = get_example( single_hh )
    fy = fy_from_bits( hh.interview_year, hh.interview_month )    
    bu = get_benefit_units( hh )[1]
    head = get_head( bu )
    head.income[state_pension] = 100.0
    make_benefit_ratios!( head, hh.interview_year, hh.interview_month )
    head.age = age_now(66)
    # female over pension age but too young to have been on old pension
    p = calc_state_pension( 
        head, 
        rp,
        sys.age_limits )
    @test p == rp.new_state_pension
    head.age = age_now(60)
    # under pension age
    p = calc_state_pension( 
        head, 
        rp,
        sys.age_limits )
    @test p == 0 # under pension age
    head.age = age_now(70)
    p = calc_state_pension( 
        head, 
        rp,
        sys.age_limits )
    @test p ≈ rp.cat_a*100.0/129.2
end
    

@testset "Pre-Tax NMT" begin
    for exn in instances( SS_Examples )
        hh = get_example( exn )
        println( "on $exn")
        hhres = init_household_result( hh )
        calc_pre_tax_non_means_tested!( 
            hhres, # :: HouseholdResult,
            hh,    #    :: Household,
            sys.nmt_bens, #   :: NonMeansTestedSys,
            sys.hours_limits, #  :: HoursLimits,
            sys.age_limits ) # :: AgeLimits ) 
    end
end

@testset "Post-Tax NMT" begin
    for exn in instances( SS_Examples )
        hh = get_example( exn )
        println( "on $exn")
        hhres = init_household_result( hh )
        calc_post_tax_non_means_tested!( 
            hhres, # :: HouseholdResult,
            hh,    #    :: Household,
            sys.nmt_bens, #   :: NonMeansTestedSys,
            sys.age_limits ) # :: AgeLimits ) 
    end
end