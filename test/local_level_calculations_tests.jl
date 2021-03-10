using Test
using ScottishTaxBenefitModel
using .ModelHousehold: Household, Person, People_Dict, is_single,
    default_bu_allocation, get_benefit_units, get_head, get_spouse, search,
    pers_is_disabled, pers_is_carer
using .ExampleHouseholdGetter
using .Definitions

using .LocalLevelCalculations: calc_lha, calc_bedroom_tax

using .STBParameters: HousingRestrictions

## FIXME don't need both
lmt = LegacyMeansTestedBenefitSystem{Float64}()
sys = get_system( scotland=true )



@testset "LHA" begin


end

@testset "Bedroom Tax" begin


end

@testset "Council Tax" begin


end
