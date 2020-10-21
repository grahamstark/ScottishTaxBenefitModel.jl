# using ScottishTaxBenefitModel
using Test
using ScottishTaxBenefitModel

is_local = haskey( ENV, "JULIA_IS_LOCALLY_INSTALLED" ) # fixme param

include( "general_tests.jl")
include( "testutils.jl")

include( "income_tax_tests.jl")
include( "parameter_tests.jl")
include( "ni_tests.jl")
include( "legacy_mt_tests.jl")
include( "complete_calc_tests.jl")
include( "uprating_tests.jl")
include( "social_security_tests_2.jl")

if is_local
# This will only run locally
    include( "household_tests.jl")
    include( "weighting_tests.jl")
    include( "simple_runner_tests.jl")
end