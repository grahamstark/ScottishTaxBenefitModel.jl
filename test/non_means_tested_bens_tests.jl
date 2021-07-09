using Test
using ScottishTaxBenefitModel
using .ModelHousehold: 
    Household, 
    Person, 
    People_Dict, 
    is_single,
    default_bu_allocation, 
    get_benefit_units, 
    get_head, 
    get_spouse, 
    search,
    pers_is_disabled, 
    pers_is_carer,
    num_children

using .GeneralTaxComponents: 
    WEEKS_PER_MONTH,
    WEEKS_PER_YEAR
    
using .ExampleHouseholdGetter
using .Definitions

using .TimeSeriesUtils: fy_from_bits
using .HistoricBenefits: make_benefit_ratios!, RATIO_BENS

using .Incomes
using .Intermediate: MTIntermediate, make_intermediate, apply_2_child_policy
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
    calc_post_tax_calc_non_means_tested!
    
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

using Dates

## FIXME don't need both
sys = get_system( scotland=true )
ruksys = get_system( scotland=false )

@testset "CB" begin
    cb = sys.nmt_bens.child_benefit
    itsys_scot :: IncomeTaxSys = get_default_it_system( year=2019, scotland=true )
    sph = deepcopy(EXAMPLES[single_parent_hh])
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
    sph = deepcopy(EXAMPLES[single_parent_hh])
    head = get_head( sph )
    disable_seriously!( head )
    head.pip_daily_living_type = standard_pip
    head.pip_mobility_type = enhanced_pip
    pl,pm = calc_pip( head, pip )
    @test (pl+pm) ≈ 119.90
end

@testset "AA" begin
    aa = sys.nmt_bens.attendance_allowance
    sph = deepcopy(EXAMPLES[single_parent_hh])
    head = get_head( sph )
    disable_seriously!( head )
    head.attendance_allowance_type = high 
    a = calc_attendance_allowance( head, aa )
    @test a ≈ 87.65
end

@testset "DLA" begin
    dla = sys.nmt_bens.dla
    sph = deepcopy(EXAMPLES[single_parent_hh])
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
    sph = deepcopy(EXAMPLES[single_parent_hh])
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
    sph = deepcopy(EXAMPLES[single_parent_hh])
    head = get_head( sph )
    head.income[maternity_allowance] = 123
    m = calc_maternity_allowance( head, mat )
    @test m ≈ 148.68

end

@testset "Carers" begin
    
end

@testset "JSA" begin
    
end

@testset "Widows" begin
    bp = sys.nmt_bens.bereavement
    wp = sys.nmt_bens.widows_pension
    sph = deepcopy(EXAMPLES[single_parent_hh])
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
    hh = deepcopy( EXAMPLES[single_hh])
    fy = fy_from_bits( hh.interview_year, hh.interview_month )    
    bu = get_benefit_units( hh )[1]
    head = get_head( bu )
    head.income[state_pension] = 100.0
    make_benefit_ratios!( head, hh.interview_year, hh.interview_month )
    head.age = age_now(65)
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
    
end

@testset "Post-Tax NMT" begin
    
end