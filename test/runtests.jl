# using ScottishTaxBenefitModel
using Test
using ScottishTaxBenefitModel

#
# full dataset is available .. 
# 
is_local = isdir("/mnt/data/frs/")
#
# is_local = haskey( ENV, "JULIA_IS_LOCALLY_INSTALLED" ) # fixme param
#
include( "general_tests.jl")
include( "testutils.jl")

include( "matching_tests.jl" )
include( "income_tax_tests.jl")
include( "parameter_tests.jl")
include( "ni_tests.jl")

include( "legacy_mt_tests.jl")
include( "complete_mt_bens_tests.jl")

include( "complete_calc_tests.jl")
include( "uprating_tests.jl")
include( "social_security_tests_2.jl")
include( "minimum_wage_tests.jl")
include( "local_level_calculations_tests.jl" )

if is_local
	# These will only run if datasets are locally installed
    include( "household_tests.jl")
    include( "weighting_tests.jl")
    include( "simple_runner_tests.jl")
end
