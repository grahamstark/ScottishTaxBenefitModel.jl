# Not tests as such; 
# just some code to track down weird shit ftom the 1st 2
# simulations front ends
# 
using Test

using UUIDs
using Observables
using CSV

using ScottishTaxBenefitModel
using .BCCalcs
using .Definitions
using .ExampleHelpers
using .FRSHouseholdGetter
using .GeneralTaxComponents
using .ModelHousehold
using .Monitor
using .Results
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

f = open("weird_results.md", "w");

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

function get_and_print(
	f :: IOStream,
	hid :: BigInt, 
	datayear :: Int, 
	settings :: Settings,
	params   :: Vector{TaxBenefitSystem{T}} ) where T
	num_systems = size(params)[1]
	hh = get_household( hid, datayear )
	println( f, ModelHousehold.to_string(hh) )
	for sysno in 1:num_systems
		res = do_one_calc( hh, params[sysno], settings )
		println( f, "### RESULTS FOR SYSTEM $sysno")
		println( f, Results.to_string( res ))
	end
end


#
# a) increasing scottish child payment - some METRs go 20-30 -> 10-20
#
@testset "scottish child payment metrs" begin
	settings = initialise_settings()
	settings.run_name = "scottish_child_payment"
	sys = load_system()
    chsys = deepcopy( sys )
    obs = Observable( 
		Progress(settings.uuid, "",0,0,0,0))
	chsys.scottish_child_payment.amount = 20.0
	params = [sys, chsys]
    results = do_one_run( settings, params, obs )
	p = collect(keys(skipmissing( results.indiv[1].metr )))
	ip1 = results.indiv[1][p,:]
	ip2 = results.indiv[2][p,:]
	d = irdiff( ip1, ip2 )
	targets = d[(abs.(d.metr) .> 0.00001),[:hid,:pid,:data_year,:metr,:means_tested_benefits]]
	println( f, "# scottish child payment metrs\n")
	CSV.write( "scottish_child_payment_metrs.csv", targets )
	for t in eachrow( targets )
		get_and_print( 
			f,
			t.hid, 
			t.data_year, 
			settings,
			params )		

	end
	n = size( results.indiv[1] )[1]
	for i in 1:n
		r1 = results.indiv[1][i,:]
		r2 = results.indiv[2][i,:]
		println( r1.hid )
		if r1.metr === missing 
			@assert r2.metr === missing
		else 
			@assert r1.metr ≈ r2.metr "r1.metr ≈ r2.metr r1=$(r1.metr) ≈ r2=$(r2.metr) " 
		end
	end
	m1 = STBOutput.metrs_to_hist( results.indiv[1] )
	m2 = STBOutput.metrs_to_hist( results.indiv[2] )
	println(m1.hist.weights)
	println(m2.hist.weights)
	@assert m1.mean ≈ m2.mean
	@assert m1.hist.weights ≈ m2.hist.weights

end


#
# b) 1p on income tax - total raised  £412m. > total income tax +405
#
@testset "1p income tax" begin
    sys = load_system()
	settings = initialise_settings()
	settings.run_name = "plus_1p_income_tax"
    chsys = deepcopy( sys )
    obs = Observable( 
		Progress(settings.uuid, "",0,0,0,0))
	chsys.it.non_savings_rates[1:3] .+= 0.01
	params = [sys, chsys]
    results = do_one_run( settings, params, obs )
	d = idiff( results.income[1], results.income[2] )
	targets = d[(d.income_tax.>0),[:hid,:pid,:data_year,:income_tax]]
	println( f, "# +1p income tax\n")
	CSV.write( "1p_income_tax.csv", targets )
	i = 0
	for t in eachrow( targets )
		i += 1
		if i < 10
			get_and_print( 
				f,
				t.hid, 
				t.data_year, 
				settings,
				params )		
		end
	end
end

#
# c) cutting basic 20-19 : a few losers
#
# Gainers	4,158	0.08
# Losers	718	0.01 <- pension contributions, no tax payable
# Unchanged	5,461,124	99.91
@testset "-1p income tax" begin
	settings = initialise_settings()
	settings.run_name = "minus_1p_income_tax"
	sys = load_system()
    chsys = deepcopy( sys )
    obs = Observable( 
		Progress(settings.uuid, "",0,0,0,0))
		chsys.it.non_savings_rates[1:3] .-= 0.01
	params = [sys, chsys]
    results = do_one_run( settings, params, obs )
	d = hdiff( results.hh[1], results.hh[2] )
	targets = d[(d.bhc_net_income.<0),[:hid,:data_year,:bhc_net_income]]
	println( f, "# -1p income tax\n")
	CSV.write( "m1p_income_tax.csv", targets )
	for t in eachrow( targets )
		get_and_print( 
			f,
			t.hid, 
			t.data_year, 
			settings,
			params )		

	end
end

close( f )
