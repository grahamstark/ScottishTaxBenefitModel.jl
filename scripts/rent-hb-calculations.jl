using DataFrames
using CSV
using Formatting
using Observables

using ScottishTaxBenefitModel
using .BCCalcs
using .Definitions
using .ExampleHelpers
using .ExampleHouseholdGetter
using .FRSHouseholdGetter
using .GeneralTaxComponents
using .HealthRegressions
using .ModelHousehold
using .Monitor
using .Runner
using .RunSettings
using .SimplePovertyCounts: GroupPoverty
using .SingleHouseholdCalculations
using .STBIncomes
using .STBOutput
using .STBParameters
using .TheEqualiser
using .Utils


  
function make_default_settings() :: Settings
    # settings = Settings()
    settings = get_all_uk_settings_2023()
    settings.do_marginal_rates = false
    settings.requested_threads = 4
    settings.means_tested_routing = uc_full
    settings.do_health_esimates = true
    # settings.ineq_income_measure = bhc_net_income # FIXME TEMP
    return settings
  end
  
DEFAULT_SETTINGS = make_default_settings()

function screen_obs()::Observable
    obs = Observable( Progress(DEFAULT_SETTINGS.uuid, "",0,0,0,0))
    completed = 0
    of = on(obs) do p
        if p.phase == "do-one-run-end"
          completed = 0
        end
        completed += p.step
        @info "monitor completed=$completed p = $(p)"
    end
    return obs
end

function load_system(; scotland = false )::TaxBenefitSystem
    sys = load_file( joinpath( Definitions.MODEL_PARAMS_DIR, "sys_2023_24_ruk.jl"))
    if scotland 
        load_file!( sys, joinpath( Definitions.MODEL_PARAMS_DIR, "sys_2023_24_scotland.jl"))
    end
    weeklyise!( sys )
    return sys
end

function run( 
        pct :: Real,
        obs :: Observable,
        settings = DEFAULT_SETTINGS ) :: Real
    sys1 = load_system( scotland=false ) 
    sys1.adjustments.pct_housing[5] = 1 + (pct/100) 
    results = do_one_run( settings, [sys1], obs )
    summary = summarise_frames!( results, settings, do_gain_lose = false )
    return summary.income_summary[1][1,:means_tested_bens]
end  

obs = screen_obs()
DEFAULT_SETTINGS.num_households, DEFAULT_SETTINGS.num_people, nhh2 = 
    FRSHouseholdGetter.initialise( DEFAULT_SETTINGS; reset=false ) # force UK dataset 

costs = []
changes = []
for pct in -100:20:100
    costch = run( pct, obs )
    push!( costs, costch)
    push!( changes, pct )
end
out = DataFrame( costs=costs, changes=changes )
out.hcosts = (out.costs .- out.costs[1])
out.pct = (out.hcosts ./ out.hcosts[6]) .* 100.0

d.changes = d.changes .+ 100

#= pretty picture - won't work here as Makie not a dependency of STB

f = Figure(size=(1024,1024 ))
update_theme!(fontsize=24)
update_theme!(fonts=(; regular="Gill Sans"))
a = Axis(f[1,1],xlabel="Rents (% of current)",ylabel="Housing Support (% of current)", title="Gross Rents vs Housing Support")
lines!(a,d.changes, d.pct)
save("/home/graham_s/tmp/hb-elasticity.png", f )
save("/home/graham_s/tmp/hb-elasticity.svg", f )
=#