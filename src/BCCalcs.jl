module BCCalcs

# 
# This module provides a simple driver for the budget constraint routine.
#
using BudgetConstraints

using ScottishTaxBenefitModel
using .Definitions
using .RunSettings: Settings
using .SingleHouseholdCalculations
using .ModelHousehold
using .STBParameters
using .STBIncomes 

export makebc

function local_getnet( data::Dict, gross::Real ) :: Real
    settings = data[:settings]
    hh = data[:hh]
    sys = data[:sys]
    wage = data[:wage]
    
    # FIXME generalise to all hh members
    head = get_head( hh )
    head.income[wages] = gross
    h = gross/wage
    head.usual_hours_worked = h     
    head.employment_status = if h < 5 
        Unemployed
    elseif h < 30 
        Part_time_Employee
    else
        Full_time_Employee
    end

    # fixme adust penconts etc.
    hres = do_one_calc( hh, sys, settings )
    return hres.ahc_net_income
end

function makebc(
    hh         :: Household,
    sys        :: TaxBenefitSystem,
    settings   :: Settings,
    bcsettings :: BCSettings = BudgetConstraints.DEFAULT_SETTINGS ) :: NamedTuple
    
    lbcset = BCSettings(
        bcsettings.mingross,
        1_200.0,
        bcsettings.increment,
        bcsettings.tolerance,
        false, # don't round numbers, since that causes charting problems
        bcsettings.maxdepth
    )
    data = Dict( :hh=>deepcopy(hh), :sys=>sys, :settings=>settings, :wage => 10.0 )
    bc = BudgetConstraints.makebc( data, local_getnet, lbcset )
    annotations = annotate_bc( bc )
    ( points = pointstoarray( bc ), annotations = annotations )
end


end # module