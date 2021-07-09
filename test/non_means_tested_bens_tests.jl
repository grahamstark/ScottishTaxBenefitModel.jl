using Test
using ScottishTaxBenefitModel
using .ModelHousehold: Household, Person, People_Dict, is_single,
    default_bu_allocation, get_benefit_units, get_head, get_spouse, search,
    pers_is_disabled, pers_is_carer
using .ExampleHouseholdGetter
using .Definitions
using .TimeSeriesUtils: fy_from_bits
using .HistoricBenefits: make_benefit_ratios!, RATIO_BENS

using .Incomes
using .Intermediate: MTIntermediate, make_intermediate, apply_2_child_policy
using .NonMeansTestedBenefits: calc_widows_benefits, calc_state_pension
using .STBParameters: AttendanceAllowance, ChildBenefit, DisabilityLivingAllowance,
   CarersAllowance, PersonalIndependencePayment, ContributoryESA,
   WidowsPensions, BereavementSupport, RetirementPension, JobSeekersAllowance,
   NonMeansTestedSys

using .Results: LMTResults, init_household_result, BenefitUnitResult
using Dates

## FIXME don't need both
sys = get_system( scotland=true )
ruksys = get_system( scotland=false )

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
    make_benefit_ratios!( head.benefit_ratios, sph.interview_year, sph.interview_month )
    
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
    make_benefit_ratios!( head, sph.interview_year, sph.interview_month )
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
    