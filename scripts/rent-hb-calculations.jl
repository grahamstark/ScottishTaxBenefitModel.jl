using DataFrames
using Formatting

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
  
const DEFAULT_SETTINGS = make_default_settings()

function load_system(; scotland = false )::TaxBenefitSystem
    sys = load_file( joinpath( Definitions.MODEL_PARAMS_DIR, "sys_2023_24_ruk.jl"))
    if scotland 
        load_file!( sys, joinpath( Definitions.MODEL_PARAMS_DIR, "sys_2023_24_scotland.jl"))
    end
    weeklyise!( sys )
    return sys
end

function do_one_conjoint_run!( facs :: Factors, obs :: Observable; settings = DEFAULT_SETTINGS ) :: NamedTuple
    sys1 = load_system( scotland=false ) 
    sys2 = deepcopy(sys1)
    sys = [sys1, sys2 ]
    results = do_one_run( settings, sys, obs )

end    