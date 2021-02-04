using Test
using ScottishTaxBenefitModel

#
# FIXME better just to check the needed FRS/HBAI files are there, as in 
# PovertyAndInequality.jl ??
#
is_local = haskey( ENV, "JULIA_IS_LOCALLY_INSTALLED" )

include( "general_tests.jl")
include( "testutils.jl")

include( "income_tax_tests.jl")
include( "parameter_tests.jl")
include( "ni_tests.jl")

include( "legacy_mt_tests.jl")
include( "complete_mt_bens_tests.jl")

include( "complete_calc_tests.jl")
include( "uprating_tests.jl")
include( "social_security_tests_2.jl")
include( "minimum_wage_tests.jl")

include( "housing_restrictions_tests.jl" )

if is_local
    include( "household_tests.jl")
    include( "weighting_tests.jl")
    include( "simple_runner_tests.jl")
end