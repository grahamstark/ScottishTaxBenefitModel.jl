using ScottishTaxBenefitModel
using Test

##  for Travis - must be a better way ...
if ! ( "src/" in LOAD_PATH )
    push!( LOAD_PATH, "src/")
end

include( "income_tax_tests.jl")
include( "parameter_test.jl")
include( "household_tests.jl")
include( "simple_runner_tests.jl")

@testset "ScottishTaxBenefitModel.jl" begin
    # Write your tests here.
end
