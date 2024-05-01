using Roots

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
using .TimeSeriesUtils: FY_2021
using .Utils




const BASE_UUID = UUID("985c312f-129b-4acd-9e40-cb629d184183")

function initialise_settings()::Settings
    settings = Settings()
	settings.uuid = BASE_UUID
	settings.means_tested_routing = modelled_phase_in
    settings.run_name="run-$(date_string())"
	settings.income_data_source = ds_frs
	settings.dump_frames = false
	settings.do_marginal_rates = false
	settings.poverty_line = 100.0 # doesn't matter so long as +ive
	settings.requested_threads = 4
	settings.dump_frames = true
	return settings
end

const BASE_SETTINGS = initialise_settings()

settings = initialise_settings()

sys = get_default_system_for_date( FY_2021 )
chsys = deepcopy( sys )
chsys.scottish_child_payment.amount = 20.0

params = [sys, chsys]
            
# results = do_one_run( settings, params, obs )

mutable struct Thing
    a :: Float64
end

mutable struct RunParameters{T<:AbstractFloat}
    params :: TaxBenefitSystem{T}
    settings :: Settings
	base_cost :: T
end

function run( x :: Number, things :: RunParameters )
    obs = Observable( 
		Progress(settings.uuid, "",0,0,0,0))
    nsr = deepcopy( things.params.it.non_savings_rates )
    things.params.it.non_savings_rates .+= x
    results = do_one_run(things.settings, [things.params], obs )
    things.params.it.non_savings_rates = nsr
	summary = summarise_frames!(results,settings)
	nc = summary.income_summary[1][1,:net_cost]
	return round( nc - things.base_cost, digits=0 )
    # x^2 + things.params.it.non_savings_rates[1] 
end

function baserun_cost()
    obs = Observable( 
		Progress(settings.uuid, "",0,0,0,0))
	results = do_one_run(settings, [sys], obs )
	summary = summarise_frames!(results,settings)
	return summary.income_summary[1][1,:net_cost]
end

nc = baserun_cost()

things = RunParameters( chsys, settings, nc )

zerorun = ZeroProblem( run, 0.0 )

incch = solve( zerorun, things )

println( "incch=$incch")