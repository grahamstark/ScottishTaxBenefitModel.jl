module BCCalcs

# 
# This module provides a simple driver for the budget constraint routine.
#
using BudgetConstraints
using DataFrames

using ScottishTaxBenefitModel
using .Definitions
using .RunSettings
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
    pid = data[:pid]
    person = nothing
    if pid == -1
        person = get_head( hh )
    else
        person = hh.people[pid]
    end
    set_wage!( person, gross, wage; switch_status=true )
    # fixme adust penconts etc.
    # println( "local_getnet: person.usual_hours_worked=$(person.usual_hours_worked) pid=$(person.pid) wage=$wage gross set to $(person.income[wages])")
    hres = do_one_calc( hh, sys, settings )
    # println( "head's calculated income = $(hres.bus[1].pers[person.pid].income)")
    return hres
end

function getnet( data::Dict, gross::Real ) :: Real
    hres = local_getnet( data, gross )
    net = get_net_income( hres; target = data[:settings].target_bc_income )  
    # println( "got net as $net")
    return net
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
    s *= "<br>"
    if r.reduction > 0
        m = md_format(r.cap)
        s *= "<b>Benefit Cap</b> = $m<br>"    
        m = md_format(r.reduction)
        s *= "<b>Benefits Reduced By:</b> = $m<br>"    
    end
    m = md_format(hres.net_housing_costs)
    s *= "<b>Net Housing Costs</b> = $m<br>"
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
    pid        :: BigInt = BigInt(-1),
    bcsettings :: BCSettings = BudgetConstraints.DEFAULT_SETTINGS ) :: DataFrame
    max_gross = wage*120
    lbcset = BCSettings(
        bcsettings.mingross,
        max_gross,
        bcsettings.increment,
        bcsettings.tolerance,
        false, # don't round numbers, since that causes charting problems
        bcsettings.maxdepth
    )
    data = Dict( :hh=>deepcopy(hh), 
        :sys=>sys, 
        :settings=>settings, 
        :wage => wage, 
        :pid=>pid )
    bc = BudgetConstraints.makebc( data, getnet, lbcset )
    a = pointstoarray( bc )
    annotations = annotate_bc( bc )
    N = size( a )[1]

    out = DataFrame( 
        gross = zeros(N), 
        net=zeros(N), 
        mr = zeros(N), 
        credit=zeros(N), 
        cap = zeros(N),
        reduction = zeros(N), 
        label=Array{String}(undef,N),
        simplelabel=Array{String}(undef,N),
        label_p1 = Array{String}(undef,N),
        label_pch = Array{Any}(undef,N))
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
        r.label = inctostr( hres.income; round_inc=false )
        # FIXME aggregate this to HH Level
        r.cap = hres.bus[1].bencap.cap
        r.reduction = hres.bus[1].bencap.reduction
        r.simplelabel = tosimplelabel( r, hres )
        hres2 = local_getnet( data, a[i,1]+bcsettings.increment ) 
        r.label_p1 = inctostr( hres2.income; round_inc=false )
        diffpct =  100*(hres2.income - hres.income)./bcsettings.increment
        r.label_pch = non_zeros(diffpct) # ; round_inc=false )      
    end
    return out
end


end # module