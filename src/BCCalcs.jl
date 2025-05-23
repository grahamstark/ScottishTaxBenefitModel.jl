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

export makebc, recensor

# character labels for charts; lower roman, greek, then upper 
const LABELS = collect(union('a':'z','α':'ω','A':'Z','Α':'Ω'))

"""
return up to 102 1 chars from Roman and Greek, upper then lower. Repeat once if n>102 die if > 204.
"""
function get_char_labels( n :: Int )
    l = length(LABELS)
    return if n <= l
        LABELS[1:n]
    else 
        nx = n-l
        vcat(LABELS,LABELS[1:nx])
    end
end

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

function to_md_list( r :: DataFrameRow, hres :: HouseholdResult )::String
    s = """

    """
    m = md_format(r.net)
    s *= s *= "* **Net Income (after housing costs)** = $m\n"
    for i in instances(Incomes)
        if hres.income[i] != 0
            m = md_format(hres.income[i])
            n = iname(i)
            s *= "* **$n** = $m\n"
        end
    end
    s *= "\n"
    if r.reduction > 0
        m = md_format(r.cap)
        s *= "* **Benefit Cap** = $m\n"    
        m = md_format(r.reduction)
        s *= "* **Benefits Reduced By:** = $m\n"    
    end
    m = md_format(hres.net_housing_costs)
    s *= "* **Net Housing Costs** = $m\n"
    if abs(r.mr) < 9999
        m = md_format(r.mr*100)
        s *= "* **Marginal Tax Rate** = $(m)%\n"
        m = md_format(r.credit)
        s *= "* **Tax Credit** = $m\n"
    else
        s *= "* **Discontinuity**"
    end

    s *= """

    """
    s
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

"""
Non-table html version of the point labelling thing for plotlyjs labels, since pjs only 
accepts br,b,i and a few others html tags. FIXME FINISH THIS
"""
function tohtmltable( 
    r :: DataFrameRow,
    hres :: HouseholdResult ) :: String
    
    s = "<table class='table'>"
    m = md_format(r.net)
    s *= s *= "<tr><th>Net Income (after housing costs)</th><td>$m</td></tr>"
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
    s *= "</table>"
    return s
end


function makebc(
    hh         :: Household,
    sys        :: TaxBenefitSystem,
    settings   :: Settings,
    wage       :: Real = 10.0,  
    pid        :: BigInt = BigInt(-1),
    bcsettings :: BCSettings = BudgetConstraints.DEFAULT_SETTINGS;
    to_html = true ) :: DataFrame
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
        simplelabel=fill("",N),
        label_p1 = fill("",N),
        label_pch = Array{Any}(undef,N))

    for i in 1:30
        lk = Symbol( "item_$(i)")
        vk = Symbol( "value_$(i)")
        out[!,lk] = fill("",N)
        out[!,vk] = zeros( N )
    end
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
        lv = 0
        for i in instances(Incomes)
            if hres.income[i] != 0
                lv += 1
                lk = Symbol( "item_$(lv)")
                vk = Symbol( "value_$(lv)")
                r[lk] = iname(i)
                r[vk] = round(hres.income[i];digits=2)
            end
        end
        # FIXME aggregate this to HH Level
        r.cap = hres.bus[1].bencap.cap
        r.reduction = hres.bus[1].bencap.reduction
        if to_html 
            r.simplelabel = tosimplelabel( r, hres )
        else
            r.simplelabel = to_md_list(r, hres )
        end
        hres2 = local_getnet( data, a[i,1]+bcsettings.increment ) 
        r.label_p1 = inctostr( hres2.income; round_inc=false )
        diffpct =  100*(hres2.income - hres.income)./bcsettings.increment
        r.label_pch = non_zeros(diffpct) # ; round_inc=false )      
    end
    out.char_labels = get_char_labels(N)
    return out
end


"""
Re-censor the data, since permissive in BCCalcs
"""
function recensor(df::DataFrame)::DataFrame
    nrows,ncols = size(df)
    dfo = similar(df)
    or = 0
    # println( "#1 nrows=$nrows")
    for r in 1:nrows-1
        r1=df[r,:]
        r2=df[r+1,:]
        # println( "$(r1.gross) $(r2.gross) $(r1.net) $(r2.net)")
        if isapprox(r1.gross,r2.gross; atol=0.001)&&(isapprox(r1.net,r2.net; atol=0.001))
            ; # println( "same row $r $(r+1)")
        else
            or += 1
            dfo[or,:] = r1
        end
    end
    dfo[!,:char_labels] = get_char_labels(nrows)
    return dfo[1:or,:]
end

end # module