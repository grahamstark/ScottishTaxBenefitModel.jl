using Test
using ScottishTaxBenefitModel
using .ModelHousehold: Household, Person, People_Dict, is_single,
    default_bu_allocation, get_benefit_units, get_head, get_spouse, search,
    pers_is_disabled, pers_is_carer
using .ExampleHouseholdGetter
using .Definitions

using .LocalLevelCalculations: calc_lha, calc_bedroom_tax, apply_size_criteria, make_la_to_brma_map, LA_BRMA_MAP, lookup

using .STBParameters

## FIXME don't need both
lmt = LegacyMeansTestedBenefitSystem{Float64}()
sys = get_system( scotland=true )



@testset "LHA and assoc. mappings" begin
    # basic test/retrieve 
    println( LA_BRMA_MAP )
    @test LA_BRMA_MAP.map[:S12000049] == :S33000009
    lmt
    @test lookup( sys.hr.brmas, :S12000049, 4 ) == 322.19
end

@testset "Bedroom Tax" begin


end

@testset "Council Tax" begin


end
