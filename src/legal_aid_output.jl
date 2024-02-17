#=
Output routines for Legal Aid, split out for manageability.
=#

"""
BU level output dataframe
"""
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

"""
Called once per benefit unit. See run example below.
"""
function fill_legal_aid_frame_row!( 
    hr   :: DataFrameRow, 
    hh   :: Household, 
    hres :: HouseholdResult,
    buno :: Int )
    # println(names(hr))
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
    if lr.passported 
        hr.disqualified_on_income = false 
        hr.disqualified_on_capital = false
    else 
        hr.disqualified_on_income = ! lr.eligible_on_income
        hr.disqualified_on_capital = ! lr.eligible_on_capital
    end
end

export LA_BITS, LA_LABELS, LA_TARGETS, aggregate_all_legal_aid

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

const LA_TARGETS = [
    :employment_status,
    :tenure, 
    :ethnic_group, 
    :bu_number, 
    :marital_status, 
    :any_disabled,
    :num_people,
    :with_children]

"""
Combine the legal aid dataframe on the column `to_combine`, using either `weight` or `weighted_people`
return a dataframe (grouped?) with LA_BITS as colums and broken down values for one of TARGETS.
"""
function combine_one_legal_aid( df :: DataFrame, to_combine :: Symbol, weight_sym :: Symbol, wbits :: AbstractArray )::AbstractDataFrame
    gdf = groupby( df, to_combine )
    outf = combine( gdf, wbits .=>sum )
    labels = push!( [Utils.pretty(string(to_combine))], LA_LABELS... )
    rename!( outf, labels )
    outf
end

"""
Call `combine_one_legal_aid` on all the `TARGETS`
return a dictionary of (grouped?) dataframes 
"""
function aggregate_all_legal_aid( df :: DataFrame, weight_sym :: Symbol ) :: Dict
    alltab = Dict()
    # df is bu level & likely created with holes, so ...
    df = df[df.hid .>0,:]
    wbits = []
    # add weighted to la counts columns.
    for l in LA_BITS
        psym = Symbol( "wt_$(l)")
        df[:,psym] .= df[:,weight_sym].*df[:,l]
        push!( wbits, psym )
    end
    for t in LA_TARGETS
        gdp = combine_one_legal_aid( df, t, weight_sym, wbits )
        alltab[t] = gdp
    end
    return alltab
end

"""
Formatter for an all-counts dataframe.
See PrettyTable documentation for formatter
"""
function pt_fmt(val,row,col)
    if col == 1
      return Utils.pretty(string(val))
    end
    return Formatting.format(val,commas=true,precision=0)
end

#= 

Example

f = open( "somefile.md","w")
for t in TARGETS
           println(f, "### "*Utils.pretty(string(t))); println(f)
           pretty_table(f,dd[t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
           println(f)
       end
close(f)

for t in TARGETS
    println( Utils.pretty(string(t)))
    pretty_table(dd[t],formatters=pt_fmt, backend = Val(:markdown), :cell_first_line_only=true)
end
=#