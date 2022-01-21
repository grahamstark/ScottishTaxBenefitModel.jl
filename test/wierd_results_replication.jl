# Not tests as such; 
# just some code to track down weird shit ftom the 1st 2
# simulations front ends
# 
using Test

using UUIDs
using Observables

using ScottishTaxBenefitModel
using .BCCalcs
using .Definitions
using .ExampleHelpers
using .FRSHouseholdGetter
using .GeneralTaxComponents
using .ModelHousehold
using .Monitor
using .Runner
using .RunSettings
using .SimplePovertyCounts: GroupPoverty
using .SingleHouseholdCalculations
using .STBIncomes
using .STBOutput
using .STBParameters
using .Utils

const BASE_UUID = UUID("985c312f-129b-4acd-9e40-cb629d184183")

function load_system()::TaxBenefitSystem
	sys = load_file( joinpath( Definitions.MODEL_PARAMS_DIR, "sys_2021_22.jl" ))
	#
	# Note that as of Budget21 removing these doesn't actually happen till May 2022.
	#
	load_file!( sys, joinpath( Definitions.MODEL_PARAMS_DIR, "sys_2021-uplift-removed.jl"))
	# uc taper to 55
	load_file!( sys, joinpath( Definitions.MODEL_PARAMS_DIR, "budget_2021_uc_changes.jl"))
	weeklyise!( sys )
	return sys
end

function initialise_settings()::Settings
    settings = Settings()
	settings.uuid = BASE_UUID
	settings.means_tested_routing = modelled_phase_in
    settings.run_name="run-$(date_string())"
	settings.income_data_source = ds_frs
	settings.dump_frames = true
	settings.do_marginal_rates = true
	settings.requested_threads = 4
	settings.dump_frames = true
	return settings
end

const BASE_SETTINGS = initialise_settings()

#
# a) 1p on income tax - total raised  £412m. > total income tax +405
#
@testset "1p income tax" begin
    sys = load_system()
	settings = initialise_settings()
	settings.run_name = "plus_1p_income_tax"
    chsys = deepcopy( sys )
    obs = Observable( 
		Progress(settings.uuid, "",0,0,0,0))
	chsys.it.non_savings_rates[1:3] .+= 0.01
    results = do_one_run( settings, [sys, chsys], obs )
end

#
# b) increasing scottish child payment - some METRs go 20-30 -> 10-20
#
@testset "scottish child payment" begin
	settings = initialise_settings()
	settings.run_name = "scottish_child_payment"
	sys = load_system()
    chsys = deepcopy( sys )
    obs = Observable( 
		Progress(settings.uuid, "",0,0,0,0))
	chsys.scottish_child_payment.amount = 20.0
    results = do_one_run( settings, [sys, chsys], obs )
end

#
# b) cutting basic 20-19 : a few losers
#
# Gainers	4,158	0.08
# Losers	718	0.01
# Unchanged	5,461,124	99.91
@testset "scottish child payment" begin
	settings = initialise_settings()
	settings.run_name = "scottish_child_payment"
	sys = load_system()
    chsys = deepcopy( sys )
    obs = Observable( 
		Progress(settings.uuid, "",0,0,0,0))
		chsys.it.non_savings_rates[1:3] .-= 0.01
    results = do_one_run( settings, [sys, chsys], obs )
end
