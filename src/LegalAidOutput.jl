module LegalAidOutput 

using CSV,
      DataFrames,
      StatsBase

using ScottishTaxBenefitModel
using .ModelHousehold,
    .Results,
    .Definitions,
    .LegalAidData,
    .RunSettings

#=
Output routines for Legal Aid, split out for manageability.
=#

"""
BU level output dataframe
"""
#=
function make_legal_aid_frame_bu( RT :: DataType, n :: Int ) :: DataFrame
    return DataFrame(
        hid       = zeros( BigInt, n ),
        sequence  = zeros( Int, n ),
        data_year  = zeros( Int, n ),        
        weight    = zeros(RT,n),
        weighted_people = zeros(RT,n),
        total = ones(RT,n),
        entitlement = fill( la_none, n ),
        bu_number = zeros( Int, n ),
        tenure    = fill( Missing_Tenure_Type, n ),
        marital_status = fill( Missing_Marital_Status, n ),
        employment_status = fill(Missing_ILO_Employment, n ),
        decile = zeros( Int, n ),
        in_poverty = fill( false, n ),
        ethnic_group = fill(Missing_Ethnic_Group, n ),
        disabled = fill(false,n),
        children = fill(false,n),
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
=#

function make_legal_aid_frame( RT :: DataType, n :: Int ) :: DataFrame
    return DataFrame(
        hid       = zeros( BigInt, n ),
        sequence  = zeros( Int, n ),
        weight    = zeros(RT,n),
        pid       = zeros( BigInt, n ),
        data_year  = zeros( Int, n ),        
        total = ones(RT,n),
        entitlement = fill( la_none, n ),
        bu_number = zeros( Int, n ),
        is_hh_head = fill( false, n ),
        is_bu_head = fill( false, n ),
        tenure    = fill( Missing_Tenure_Type, n ),
        marital_status = fill( Missing_Marital_Status, n ),
        employment_status = fill(Missing_ILO_Employment, n ),
        decile = zeros( Int, n ),
        in_poverty = fill( false, n ),
        ethnic_group = fill(Missing_Ethnic_Group, n ),
        disabled = fill(false,n),
        is_child = fill(false,n),
        num_children = zeros(Int,n),
        num_pensioners = zeros(Int,n),
        num_bus = zeros(Int,n),
        bu_size = zeros(Int,n),
        hh_size = zeros(Int,n),
        is_pensioner = fill(false,n),
        all_eligible = zeros(RT,n),
        mt_eligible = zeros(RT,n),
        passported = zeros(RT,n),
        any_contribution = zeros(RT,n),
        income_contribution = zeros(RT,n),
        capital_contribution = zeros(RT,n),
        disqualified_on_income = zeros(RT,n), 
        disqualified_on_capital = zeros(RT,n))
end

#=
function aggregate_to_bu( persf :: DataFrame ) :: DataFrame
    buf = copy( persf )
    bgroups = groupby( buf, [:hno,:buno])
    for bg in bgroups
       nkids = sum( bg.is_child )
       npens = sum( bg.is_pensioner )
       target = (buf.hid .== bg.hid).&(buf.buno .== bg.buno) .& (buf.is_bu_head .== true)
       @assert length( target ) == 1
       # buf[target,:]
    end
end
=#

function add_problem_probabilities( results :: DataFrame, probs :: DataFrame )
    rightjoin( results, probs; on = [:hid, :data_year, :pid ])
end


"""
called once per person 
"""
function fill_legal_aid_frame_row!( 
    pr :: DataFrameRow,
    lares :: OneLegalAidResult,
    hh :: Household,
    pers :: Person
    ;
    is_hh_head :: Bool,
    is_bu_head :: Bool,
    buno :: Int,
    num_pensioners :: Int,
    num_children   :: Int,
    num_bus :: Int,
    bu_size :: Int )

    pr.hid = hh.hid
    pr.pid = pers.pid
    pr.pno = pers.pno
    pr.is_hh_head = is_hh_head
    pr.is_bu_head = is_bu_head,
    pr.sequence = hh.sequence
    pr.data_year = hh.data_year
    pr.weight = hh.weight
    pr.bu_number = buno
    pr.bu_size = bu_size
    pr.hh_size = num_people(hh)
    pr.num_pensioners = num_pensioners
    pr.num_children = num_children
    pr.num_bus = num_bus
    pr.ethnic_group = pers.ethnic_group
    pr.employment_status = pers.employment_status
    pr.marital_status = pers.marital_status
    pr.disabled = is_disabled( pers )
    pr.is_child = pers.is_standard_child
    pr.all_eligible = lr.eligible | lr.passported
    pr.mt_eligible = lr.eligible
    pr.passported = lr.passported
    pr.any_contribution = (lr.capital_contribution + lr.income_contribution) > 0
    pr.capital_contribution = lr.capital_contribution > 0
    pr.income_contribution = lr.income_contribution > 0
    if lr.passported 
        pr.disqualified_on_income = false 
        pr.disqualified_on_capital = false
    else 
        pr.disqualified_on_income = ! lr.eligible_on_income
        pr.disqualified_on_capital = ! lr.eligible_on_capital
    end
    pr.entitlement = lr.entitlement
end

function add_to_frames!(
    lout     :: AllLegalOutput,
    settings :: Settings,
    hh       :: Household,
    hres     :: HouseholdResult,
    sysno    :: Integer )
    nbus = length(hres.bus)
    np = length( hh.people )
    bus = get_benefit_units( hh )
    npp = 0
    for buno in 1:nbus
        bup = 0
        for( pid, pers ) in bus[buno].people
            npp += 1
            bup += 1
            pfno = get_slot_for_person( pid, hh.data_year )
            fill_legal_aid_frame_row!( 
                pr :: DataFrameRow,
                lares :: OneLegalAidResult,
                hh :: Household,
                pers :: Person
                ;
                is_hh_head = is_head( hh, pers ),
                is_bu_head = is_head( bus[buno], pers ),
                buno = buno,
                num_pensioners = count( bu.people, ge_age, 65 ), # not exactly
                num_children  = num_children( bu ),
                num_bus = nbus,
                bu_size = num_people( bu ))
        end
    end
end

#=
"""
Called once per benefit unit. See run example below.
"""
function fill_legal_aid_frame_row!( 
    hr   :: DataFrameRow, 
    hh   :: Household, 
    hres :: HouseholdResult,
    buno :: Int;
    is_civil :: Bool )
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
    hr.disabled = has_disabled_member( bu )
    hr.children = num_children( bu ) > 0
    hr.any_pensioner = search( bu.people, ge_age, 65 )
    
    lr = is_civil ? hres.bus[buno].legalaid.civil : hres.bus[buno].legalaid.aa
    
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
    hr.entitlement = lr.entitlement
end
=#

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
    :disabled,
    :num_people,
    :children]

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
    return Format.format(val,commas=true,precision=0)
end

function la_crosstab( pre :: DataFrame, post :: DataFrame ) :: AbstractMatrix
    return make_crosstab( 
        pre.entitlement, 
        post.entitlement; 
        weights=Weights(pre.weight) )[1] # discard the labels
end

mutable struct LegalOutput
    num_systems :: Int
    data :: Vector{DataFrame}
    breakdown_bu :: Vector{AbstractDict}
    breakdown_pers :: Vector{AbstractDict}
    crosstab_bu :: Vector{AbstractMatrix}
    crosstab_pers :: Vector{AbstractMatrix}
end

mutable struct AllLegalOutput
    aa :: LegalOutput
    civil :: LegalOutput
end

function LegalOutput( T; num_systems::Integer, num_people::Integer )
    datas = Vector{DataFrame}(undef,0)
    breakdown_bu = Vector{Dict}(undef,0)
    breakdown_pers = Vector{Dict}(undef,0)
    crosstab_bu = Vector{Matrix}(undef,0)
    crosstab_pers = Vector{Matrix}(undef,0)
    for sysno in 1:num_systems
        push!( data, make_legal_aid_frame_bu( T, num_people ))
        push!( breakdowns_pers, Dict())
        push!( breakdowns_bu, Dict())
        if sysno < num_systems
            push!(crosstabs_pers, fill(T,4,4))
            push!(crosstabs_bu, fill(T,4,4))
        end
    end
    LegalOutput( num_systems, datas, breakdowns_bu, breakdowns_pers, crosstabs_bu, crosstabs_pers )
end

function AllLegalOutput( T; num_systems::Integer, num_people::Integer )
    AllLegalOutput( 
        LegalOutput( T; num_systems=num_systems, num_people=num_people ),
        LegalOutput( T; num_systems=num_systems, num_people=num_people))
end

function summarise_la_output!( la :: LegalOutput )
    for sysno in 1:la.num_systems
        data = la.data[sysno]
        budata = data[data.is_bu_head,:] 
        la.breakdown_pers[sysno] = aggregate_all_legal_aid( data,:weight )
        la_breakdown_bu[sysno]  = aggregate_all_legal_aid( budata,:weight )
        if sysno > 1
            la.crosstab_pers[sysno-1] = la_crosstab( data, la.data[1] )
            la.crosstab_bu[sysno-1] = la_crosstab( budata, la.data[1][la.data[1].is_bu_head, : ] )
        end
    end
end

function summarise_la_output!( la :: AllLegalOutput )
    summarise_la_output!( la.civil )
    summarise_la_output!( la.aa )
end

function dump_frames( la :: AllLegalOutput, settings :: Settings )
    for sysno in 1:la.aa_bu.num_systems
        fname = "$(settings.output_dir)/$(fbase)_$(sysno)_legal_aid_civil.csv"
        CSV.write( fname, la.civil.data[sysno] )
        fname = "$(settings.output_dir)/$(fbase)_$(sysno)_legal_aid_aa.csv"
        CSV.write( fname, la.aa.data[sysno] )
    end
end

end