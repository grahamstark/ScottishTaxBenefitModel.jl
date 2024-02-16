
function make_legal_aid_frame( RT :: DataType, n :: Int ) :: DataFrame
    return DataFrame(
        hid       = zeros( BigInt, n ),
        sequence  = zeros( Int, n ),
        data_year  = zeros( Int, n ),        
        weight    = zeros(RT,n),
        weighted_people = zeros(RT,n),
        total = ones(RT,n),
        bu_number = zeros( Int, n ),
        num_people = zeros( Int, n ),
        tenure    = fill( Missing_Tenure_Type, n ),
        marital_status = fill( Missing_Marital_Status, n ),
        employment_status = fill(Missing_ILO_Employment, n ),
        decile = zeros( Int, n ),
        in_poverty = fill( false, n ),
        ethnic_group = fill(Missing_Ethnic_Group, n ),
        any_disabled = fill(false,n),
        with_children = fill(false,n),
        any_pensioner = fill(false,n),
        all_eligible = zeros(RT,n),
        mt_eligible = zeros(RT,n),
        passported = zeros(RT,n),
        any_contribution = zeros(RT,n),
        income_contribution = zeros(RT,n),
        capital_contribution = zeros(RT,n),
        disqualified_on_income = zeros(RT,n), 
        disqualified_on_capital = zeros(RT,n))
end

function fill_legal_aid_frame_row!( 
    hr   :: DataFrameRow, 
    hh   :: Household, 
    hres :: HouseholdResult,
    buno :: Int )
    hr.hid = hh.hid
    hr.sequence = hh.sequence
    hr.data_year = hh.data_year
    hr.weight = hh.weight
    bu = get_benefit_units( hh )[buno]
    nps = num_people( bu )
    hr.num_people = nps
    hr.bu_number = buno
    hr.weighted_people = hh.weight*nps
    hr.tenure = hh.tenure
    # hr.in_poverty
    head = get_head( bu )
    hr.ethnic_group = head.ethnic_group
    hr.employment_status = head.employment_status
    hr.marital_status = head.marital_status
    hr.any_disabled = has_disabled_member( bu )
    hr.with_children = num_children( bu ) > 0
    lr = hres.bus[buno].legalaid.civil
    hr.all_eligible = lr.eligible | lr.passported
    hr.mt_eligible = lr.eligible
    hr.passported = lr.passported
    hr.any_contribution = (lr.capital_contribution + lr.income_contribution) > 0
    hr.capital_contribution = lr.capital_contribution > 0
    hr.income_contribution = lr.income_contribution > 0
    hr.disqualified_on_income = ! lr.eligible_on_income
    hr.disqualified_on_capital = ! lr.eligible_on_capital
end

function larun()
    settings = Settings()
    tot = 0
    obs = Observable( Progress(settings.uuid,"",0,0,0,0))
    of = on(obs) do p
        println(p)
        tot += p.step
        println(tot)
    end  
    sys = [
        get_default_system_for_fin_year(2023; scotland=true), 
        get_default_system_for_fin_year( 2023; scotland=true )]    
    settings.do_marginal_rates = false
    @time settings.num_households, settings.num_people, nhh2 = initialise( settings, reset=false )
    df = make_legal_aid_frame( Float64, settings.num_households*2 )
    nbus = 0
    println( "settings.num_households = $(settings.num_households)")
    for hno in 1:settings.num_households
        hh = get_household(hno)
        rc = do_one_calc( hh, sys[1], settings )        
        if(hno % 1000) == 0
            println( ModelHousehold.to_string(hh) )
            println( Results.to_string(rc.bus[1]))
        end
        bus = get_benefit_units(hh)
        for buno in 1:size(bus)[1]
            nbus += 1
            fill_legal_aid_frame_row!( df[nbus,:], hh, rc, buno ) 
        end
    end
    df[1:nbus,:]
end

const LA_BITS=[
    :total, 
    :all_eligible,
    :passported,
    :mt_eligible,
    :any_contribution,
    :income_contribution,
    :capital_contribution,
    :disqualified_on_income,
    :disqualified_on_capital]
const LA_LABELS = [
    "Total",
    "All Eligible",
    "Passported",
    "Eligible On Means Test",
    "Any Contribution",
    "Income Contribution",
    "Capital Contribution",
    "Disqualified on Income",
    "Disqualified on Capital"]
const TARGETS = [
    :employment_status,
    :tenure, 
    :ethnic_group, 
    :bu_number, 
    :marital_status, 
    :any_disabled,
    :num_people,
    :with_children]

function combine_one_legal_aid( df :: DataFrame, to_combine :: Symbol, weight_sym :: Symbol )::AbstractDataFrame
    wbits = []
    for l in LA_BITS
        psym = Symbol( "wt_$(l)")
        df[:,psym] .= df[:,weight_sym].*df[:,l]
        push!( wbits, psym )
    end
    gdf = groupby( df, to_combine )
    outf = combine( gdf, wbits .=>sum )
    labels = push!( [Utils.pretty(string(to_combine))], LA_LABELS... )
    rename!( outf, labels )
    outf
end

function aggregate_all_legal_aid( df :: DataFrame, weight_sym :: Symbol ) :: Dict
    alltab = Dict()
    for t in TARGETS
        gdp = combine_one_legal_aid( df, t, weight_sym )
        alltab[t] = gdp
    end
    return alltab
end

"""
See PrettyTable documentation for formatter
"""
function pt_fmt(val,row,col)
    if col == 1
      return Utils.pretty(string(val))
    end
    return Formatting.format(val,commas=true,precision=0)
end


