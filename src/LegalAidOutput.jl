
#=
Output routines for Legal Aid, split out for manageability.
=#
module LegalAidOutput 

using CSV,
      DataFrames,
      StatsBase

using ScottishTaxBenefitModel
# FIXME explicit imports
using .Definitions,
    .FRSHouseholdGetter,
    .LegalAidData,
    .ModelHousehold,
    .Results,
    .RunSettings,
    .Utils 

export AllLegalOutput, LegalOutput, summarise_la_output!

mutable struct LegalOutput
    num_systems :: Int
    data :: Vector{DataFrame}
    breakdown_bu :: Vector{AbstractDict}
    breakdown_pers :: Vector{AbstractDict}
    crosstab_bu :: Vector{AbstractMatrix}
    crosstab_pers :: Vector{Dict{String,AbstractMatrix}}
end

mutable struct AllLegalOutput
    aa :: LegalOutput
    civil :: LegalOutput
end

function make_legal_aid_frame( RT :: DataType, n :: Int ) :: DataFrame
    return DataFrame(
        hid       = zeros( BigInt, n ),
        sequence  = zeros( Int, n ),
        weight    = zeros(RT,n),
        pid       = zeros( BigInt, n ),
        data_year  = zeros( Int, n ),        
        total = ones(RT,n),
        entitlement = fill( la_none, n ),
        pno   = zeros( Int, n ),
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
        num_people_in_bu = zeros(Int,n),
        num_people_in_hh = zeros(Int,n),
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

function add_problem_probabilities( results :: DataFrame )
    r = innerjoin( results, LegalAidData.LA_PROB_DATA; on = [:hid, :data_year, :pid ], makeunique=true)
    return r[ r.from_child_record .!= 1,:]
end


"""
called once per person 
"""
function fill_legal_aid_frame_row!( 
    pr :: DataFrameRow,
    lr :: OneLegalAidResult,
    hh :: Household,
    pers :: Person
    ;
    is_hh_head :: Bool,
    is_bu_head :: Bool,
    buno :: Int,
    num_pensioners :: Int,
    num_children   :: Int,
    num_bus :: Int,
    num_people_in_bu :: Int )

    pr.hid = hh.hid
    pr.pid = pers.pid
    pr.pno = pers.pno
    pr.is_hh_head = is_hh_head
    pr.is_bu_head = is_bu_head
    pr.sequence = hh.sequence
    pr.data_year = hh.data_year
    pr.weight = hh.weight
    pr.bu_number = buno
    pr.num_people_in_bu = num_people_in_bu
    pr.num_people_in_hh = num_people(hh)
    pr.num_pensioners = num_pensioners
    pr.num_children = num_children
    pr.num_bus = num_bus
    pr.ethnic_group = pers.ethnic_group
    pr.employment_status = pers.employment_status
    pr.marital_status = pers.marital_status
    pr.disabled = pers_is_disabled( pers )
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
        bu = bus[buno]
        num_pensioners = ModelHousehold.count( bu.people, ge_age, 65 ) # ?? why qual ??
        ncs = num_children( bu )
        num_people_in_bu = num_people( bu )
        for( pid, pers ) in bus[buno].people
            npp += 1
            bup += 1
            is_hh_head = hh.head_of_household == pers.pid
            is_bu_head = is_head( bu, pers )
            pfno = get_slot_for_person( pid, hh.data_year )
            fill_legal_aid_frame_row!( 
                lout.civil.data[sysno][pfno,:],
                hres.bus[buno].legalaid.civil,
                hh,
                pers
                ;
                is_hh_head = is_hh_head,
                is_bu_head = is_bu_head,
                buno = buno,
                num_pensioners = num_pensioners, # not exactly
                num_children  = ncs,
                num_bus = nbus,
                num_people_in_bu = num_people_in_bu)
            fill_legal_aid_frame_row!( 
                lout.aa.data[sysno][pfno,:],
                hres.bus[buno].legalaid.aa,
                hh,
                pers
                ;
                is_hh_head = is_hh_head,
                is_bu_head = is_bu_head,
                buno = buno,
                num_pensioners = num_pensioners,
                num_children  = ncs,
                num_bus = nbus,
                num_people_in_bu = num_people_in_bu)
            end
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
    :disabled,
    :num_people_in_bu,
    :num_children]

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

function la_crosstab( pre :: DataFrame, post :: DataFrame, problem="no_problem", estimate="prediction" ) :: AbstractMatrix
    weights = Weights(pre.weight) 
    if problem != "no_problem"
        col = Symbol( "$(problem)_$estimate")
        weights = Weights( pre[:,col] .* pre.weight)
    end
        
    return make_crosstab( 
        pre.entitlement, 
        post.entitlement; 
        weights=weights )[1] # discard the labels
end

function summarise_la_output!( la :: LegalOutput )
    # base data 
    data1 = add_problem_probabilities( la.data[1] )
    budata1 = data1[data1.is_bu_head, : ] 
    for sysno in 1:la.num_systems
        data = add_problem_probabilities( la.data[sysno] )
        budata = data[data.is_bu_head,:] 
        la.breakdown_pers[sysno] = aggregate_all_legal_aid( data,:weight )
        la.breakdown_bu[sysno]  = aggregate_all_legal_aid( budata,:weight )
        if sysno > 1
            for p in LegalAidData.PROBLEM_TYPES
                for est in LegalAidData.ESTIMATE_TYPES
                    k = "$(p)-$(est)"
                    la.crosstab_pers[sysno-1][k] = la_crosstab( data, data1, p, est )
                end # estimates          
            end # problems
            la.crosstab_bu[sysno-1] = la_crosstab( budata, budata1 )
        end # sysno > 1
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


function LegalOutput( T; num_systems::Integer, num_people::Integer )
    datas = Vector{DataFrame}(undef,0)
    breakdown_bu = Vector{Dict}(undef,0)
    breakdown_pers = Vector{Dict}(undef,0)
    crosstab_bu = Vector{Matrix}(undef,0)
    crosstab_pers = Vector{Dict{String,Matrix}}(undef,0)
    for sysno in 1:num_systems
        push!( datas, make_legal_aid_frame( T, num_people ))
        push!( breakdown_pers, Dict())
        push!( breakdown_bu, Dict())
        if sysno < num_systems
            push!(crosstab_pers, Dict()) # fill(T,4,4))
            push!(crosstab_bu, fill(T,4,4))
        end
    end
    LegalOutput( num_systems, datas, breakdown_bu, breakdown_pers, crosstab_bu, crosstab_pers )
end

function AllLegalOutput( T; num_systems::Integer, num_people::Integer )
    AllLegalOutput( 
        LegalOutput( T; num_systems=num_systems, num_people=num_people ),
        LegalOutput( T; num_systems=num_systems, num_people=num_people))
end
    

end # module

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


#=
    legalaid = []
    if settings.do_legal_aid

    end

    legal_crosstabs = []
    if settings.do_legal_aid
        for sysno in 2:ns
            civtab = la_crosstab( frames.civil_legalaid_bu[1], frames.civil_legalaid_bu[sysno] )
            push!( legal_crosstabs, civtab )
            aatab = la_crosstab( frames.aa_legalaid_bu[1], frames.aa_legalaid_bu[sysno] )
            push!( legal_crosstabs, aatab )
        end
    end


        legaldics = ( ; ) # named tuple with nothing
        if settings.do_legal_aid
            civil_legalaid_bus = aggregate_all_legal_aid( frames.civil_legalaid_bu[sysno],:weight )
            civil_legalaid_people = aggregate_all_legal_aid( frames.civil_legalaid_bu[sysno],:weighted_people )
            aa_legalaid_bus = aggregate_all_legal_aid( frames.aa_legalaid_bu[sysno],:weight )
            aa_legalaid_people = aggregate_all_legal_aid( frames.aa_legalaid_bu[sysno],:weighted_people )
            legaldics = (; civil_legalaid_bus, civil_legalaid_people, aa_legalaid_bus, aa_legalaid_people,  )            
        end
        push!( legalaid, legaldics )

=#