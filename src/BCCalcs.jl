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
using .Utils

export makebc

function local_getnet( data::Dict, gross::Real ) :: HouseholdResult
    settings = data[:settings]
    hh = data[:hh]
    sys = data[:sys]
    wage = data[:wage]
    
    # FIXME generalise to all hh members
    head = get_head( hh )
    set_wage!( head, gross, wage )
    # fixme adust penconts etc.
    hres = do_one_calc( hh, sys, settings )
    return hres
end

function getnet( data::Dict, gross::Real ) :: Real
    return local_getnet( data, gross ).ahc_net_income
end

"""
Non-table html version of the point labelling thing for plotlyjs labels, since pjs only 
accepts br,b,i and a few others html tags.
"""
function tosimplelabel( 
    r :: DataFrameRow,
    hres :: HouseholdResult ) :: String
    
    s = "<br>"
    m = md_format(r.net)
    s *= s *= "<b>Net Income (after housing costs)</b> = <b>$m</b><br><br>"
    for i in instances(Incomes)
        if hres.income[i] != 0
            m = md_format(hres.income[i])
            n = iname(i)
            s *= "<b>$n</b> = $m<br>"
        end
    end
    m = md_format(hres.net_housing_costs)
    s *= "<b>Net Housing Costs</b> = $m<br>"
    s *= "<br>"
    if abs(r.mr) < 9999
        m = md_format(r.mr*100)
        s *= "<b>Marginal Tax Rate</b> = $(m)%<br>"
        m = md_format(r.credit)
        s *= "<b>Tax Credit</b> = $m<br>"
    else
        s *= "<b>Discontinuity</b><br>"
    end

    return s
end

function makebc(
    hh         :: Household,
    sys        :: TaxBenefitSystem,
    settings   :: Settings,
    wage       :: Real = 10.0,
    bcsettings :: BCSettings = BudgetConstraints.DEFAULT_SETTINGS ) :: DataFrame
    lbcset = BCSettings(
        bcsettings.mingross,
        1_200.0,
        bcsettings.increment,
        bcsettings.tolerance,
        false, # don't round numbers, since that causes charting problems
        bcsettings.maxdepth
    )
    data = Dict( :hh=>deepcopy(hh), :sys=>sys, :settings=>settings, :wage => wage )
    bc = BudgetConstraints.makebc( data, getnet, lbcset )
    a = pointstoarray( bc )
    annotations = annotate_bc( bc )
    N = size( a )[1]

    out = DataFrame( gross = zeros(N), net=zeros(N), mr = zeros(N), credit=zeros(N), 
        label=Array{String}(undef,N),simplelabel=Array{String}(undef,N))
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
        r.label = inctostr( hres.income )
        r.simplelabel = tosimplelabel( r, hres )
    end
    return out
end


end # module