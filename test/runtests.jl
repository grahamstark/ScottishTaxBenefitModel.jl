# using ScottishTaxBenefitModel
using Test
using ScottishTaxBenefitModel

is_local = haskey( ENV, "JULIA_IS_LOCALLY_INSTALLED" ) # fixme param

include( "income_tax_tests.jl")
include( "parameter_tests.jl")
include( "ni_tests.jl")
include( "legacy_mt_tests.jl")
if is_local
# This will only run locally
    include( "household_tests.jl")
    include( "simple_runner_tests.jl")
end

@testset "ScottishTaxBenefitModel.jl" begin
    # Write your tests here.
end
