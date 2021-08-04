using DataFrames: Highlighter
using StatsBase: self_avoid_sample!
# using ScottishTaxBenefitModel
using Test
using ScottishTaxBenefitModel



include( "testutils.jl")

include( "general_tests.jl")

include( "results_tests.jl")

include( "equivence_scale_tests.jl")

include( "historic_benefits_tests.jl")

include("non_means_tested_bens_tests.jl")

include( "income_tax_tests.jl")
include( "matching_tests.jl" )
include( "parameter_tests.jl")
include( "ni_tests.jl")

include( "legacy_mt_tests.jl")
include( "complete_mt_bens_tests.jl")

include( "complete_calc_tests.jl")
include( "uprating_tests.jl")
include( "social_security_age_tests.jl")
include( "minimum_wage_tests.jl")
include( "local_level_calculations_tests.jl" )

# These will only run if datasets are locally installed
if IS_LOCAL
	# These will only run if datasets are locally installed
    include( "household_tests.jl")
    include( "simple_runner_tests.jl")
	include( "weighting_tests.jl")
end
