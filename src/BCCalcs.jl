module BCCalcs

# 
# This module provides a simple driver for the budget constraint routine.
#
using BudgetConstraints
using DataFrames

using ScottishTaxBenefitModel
using .Definitions
using .RunSettings: Settings
using .SingleHouseholdCalculations
using .ModelHousehold
using .STBParameters
using .STBIncomes 
using .Results

export makebc

function local_getnet( data::Dict, gross::Real ) :: HouseholdResult
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
    return hres
end

function getnet( data::Dict, gross::Real ) :: Real
    return local_getnet( data, gross ).ahc_net_income
end

function makebc(
    hh         :: Household,
    sys        :: TaxBenefitSystem,
    settings   :: Settings,
    bcsettings :: BCSettings = BudgetConstraints.DEFAULT_SETTINGS ) :: DataFrame
    lbcset = BCSettings(
        bcsettings.mingross,
        1_200.0,
        bcsettings.increment,
        bcsettings.tolerance,
        false, # don't round numbers, since that causes charting problems
        bcsettings.maxdepth
    )
    data = Dict( :hh=>deepcopy(hh), :sys=>sys, :settings=>settings, :wage => 10.0 )
    bc = BudgetConstraints.makebc( data, getnet, lbcset )
    a = pointstoarray( bc )
    annotations = annotate_bc( bc )
    N = size( a )[1]

    out = DataFrame( gross = zeros(N), net=zeros(N), mr = zeros(N), credit=zeros(N), label=Array{String}(undef,N))
    # fill the data frame
    for i in 1:N
        r = out[i,:]
        r.gross = a[i,1]
        r.net = a[i,2]
        if i < N
            r.mr = annotations[i].marginalrate
            r.credit = annotations[i].taxcredit
        else 
            r.mr = annotations[i-1].marginalrate
            r.credit = annotations[i-1].taxcredit
        end
        hres = local_getnet( data, a[i,1] ) 
        # FIXME add a really nice labelling thing here with changes between gross and gross+1
        r.label = inctostr(  hres.income )
    end
    return out
end


end # module