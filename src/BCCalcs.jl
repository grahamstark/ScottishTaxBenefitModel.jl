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

function local_getnet( data::Dict, gross : Real ) :: Real
    settings = Data[:settings]
    hh = Data[:hh]
    sys = Data[:sys]
    # FIXME generalise to all hh members
    head = get_head( hh )
    head.income[wage] = gross
    # fixme adust penconts etc.
    hres = do_one_calc( hh, sys, settings )
    return hres.ahc_net_income
end

function makebc(
    hh :: Household;
    sys :: TaxBenefitSystem,
    settings :: Settings,
    bcsettings :: BCSettings = BudgetConstraints.DEFAULT_SETTINGS ) :: NamedTuple
   
    data = Dict( :hh=>household, :params=>sys, :settings=>settings )
    bc = BudgetConstraints.makebc( data, local_getnet, bcsettings )
    annotations = annotate_bc( bc )
    ( points = pointstoarray( bc ), annotations = annotations )
end


end # module