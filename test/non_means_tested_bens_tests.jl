using Test
using ScottishTaxBenefitModel
using .ModelHousehold: Household, Person, People_Dict, is_single,
    default_bu_allocation, get_benefit_units, get_head, get_spouse, search,
    pers_is_disabled, pers_is_carer
using .ExampleHouseholdGetter
using .Definitions
using .NonMeansTestedBenefits:  
    calc_widows_bens

using .Incomes
using .Intermediate: MTIntermediate, make_intermediate, apply_2_child_policy
    
using .STBParameters: AttendanceAllowance, ChildBenefit, DisabilityLivingAllowance,
   CarersAllowance, PersonalIndependencePayment, ContributoryESA,
   WidowsPensions, BereavementSupport, RetirementPension, JobSeekersAllowance,
   NonMeansTestedBenefits

using .Results: LMTResults, init_household_result, BenefitUnitResult
using Dates

## FIXME don't need both
sys = get_system( scotland=true )
ruksys = get_system( scotland=false )

@testset "Widows" begin
    examples = get_ss_examples()
    sph = deepcopy(EXAMPLES[single_parent_hh])
end
    