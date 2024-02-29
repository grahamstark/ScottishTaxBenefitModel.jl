using DataFrames: Highlighter
using StatsBase: self_avoid_sample!
# using ScottishTaxBenefitModel
using Test
using ScottishTaxBenefitModel

include( "testutils.jl")
include( "test_utils_tests.jl")
include( "randoms_tests.jl")
include( "general_tests.jl")
include( "results_tests.jl")
include( "equivence_scale_tests.jl")
include( "historic_benefits_tests.jl")
include("non_means_tested_bens_tests.jl")
include("benefit_generosity_tests.jl")
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
include( "scottish_benefits_tests.jl" )
include( "ubi_tests.jl")
include( "output_tests.jl")
include( "vs_policy_in_practice_tests.jl")
include( "vs_age_uk_tests.jl")
include( "affordability_tests.jl")
include( "stboutput_tests.jl")
include( "household_adjuster_tests.jl")
include( "utils_tests.jl")

# These will only run if datasets are locally installed
if IS_LOCAL
	# These will only run if datasets are locally installed
    include( "household_tests.jl")
    include( "consumption_data_tests.jl")
	# FIXME needs rewritten to match new Weighting code include( "weighting_tests.jl")
    include( "uc_transition_tests.jl")
    include( "simple_runner_tests.jl")
    include( "equaliser_tests.jl")
    include( "expenditure_tests.jl")
    include( "health_regressions_tests.jl")
    include( "all_uk_runner_tests.jl")
    include( "wealth_tests.jl")
    include( "legal_aid_calculations_tests.jl")
    # include( "indirect_taxes_tests.jl")
end
