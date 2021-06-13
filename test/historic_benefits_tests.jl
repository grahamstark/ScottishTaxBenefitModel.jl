using Test
using ScottishTaxBenefitModel.HistoricBenefits
using ScottishTaxBenefitModel.Definitions

include( "testutils.jl")

## NOTE this test has the 2019 OBR data and 2019Q4 as a target jammed on - will need
## changing with update versions

@testset "historic tests" begin
 
    be_99 = 66.75
    pe_99 = 66.75
    @test benefit_ratio(
        1999,
        be_99,
        bereavement_allowance_or_widowed_parents_allowance_or_bereavement
    ) ≈ 1

    @test benefit_ratio(
        2020,
        be_99,
        bereavement_allowance_or_widowed_parents_allowance_or_bereavement
    ) ≈ be_99/121.95

    @test benefit_ratio(
        1999,
        pe_99,
        state_pension
    ) ≈ 1


end