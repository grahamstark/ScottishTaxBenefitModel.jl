
#=
Output routines for Legal Aid, split out for manageability.
=#
module LegalAidOutput 

using CSV,
      DataFrames,
      Format,
      PrettyTables,
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
        age = zeros(n),
        age2 = fill("",n), # age as a string to match 
        sex = fill( Male, n ),

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
    pr.age = pers.age,
    pr.age2 = agestr2( pers.age ),
    pr.sex = pers.sex,
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

export LA_BITS, LA_LABELS, LA_TARGETS, aggregate_all_legal_aid, crosstab_to_df

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

function make_entitlement_strs()
    s = collect(pretty.(string.(instances( LegalAidStatus ))))
    push!(s,"Totals")
    return s
end

const ENTITLEMENT_STRS = make_entitlement_strs()

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
        post.entitlement,
        pre.entitlement;
        weights=weights )[1] # discard the labels
end

"""
Fixed silly Crosstab with entitlement wired in because my general crosstab is 
breaking in a way I can't work out.
pre is the row, post is the col, cells above the diagonal represent gains, below losses.
"""
function crappycrosstab( 
    pre :: DataFrame, 
    post :: DataFrame, 
    problem="no_problem", 
    estimate="prediction"  ) :: Matrix
    m = zeros(4,4)
    s1 = size( pre )
    s2 = size( post )
    @assert s1 == s2
    num_rows = s1[1]
    weights = Weights(pre.weight) 
    # @assert pre.weight .≈ post.weight
    if problem != "no_problem"
        col = Symbol( "$(problem)_$estimate")
        weights = Weights( pre[:,col] .* pre.weight)
    end
    for r in 1:num_rows
        prer = pre[r,:]
        postr = post[r,:]
        @assert (prer.pid == postr.pid) && (prer.data_year == postr.data_year) && (prer.weight ≈ postr.weight )
        prev = Int( prer.entitlement )+1
        postv = Int( postr.entitlement )+1
        # pre is the row post is the col. Julia arrays are row first, then col
        m[postv,prev] += weights[r]
    end
    return m
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
                    # FIXME fancy crosstab is breaking:: More unitests
                    la.crosstab_pers[sysno-1][k] = la_crosstab( data1, data, p, est )
                end # estimates          
            end # problems
            la.crosstab_bu[sysno-1] = la_crosstab( budata1, budata )
        end # sysno > 1
    end
end

function summarise_la_output!( la :: AllLegalOutput )
    summarise_la_output!( la.civil )
    summarise_la_output!( la.aa )
end

"""

"""
function dump_frames( la :: AllLegalOutput, settings :: Settings, num_systems::Integer )
    runname = Utils.basiccensor(settings.run_name)
    for sysno in 1:num_systems
        fname = "$(settings.output_dir)/$(runname)_$(sysno)_legal_aid_civil.csv"
        CSV.write( fname, la.civil.data[sysno] )
        fname = "$(settings.output_dir)/$(runname)_$(sysno)_legal_aid_aa.csv"
        CSV.write( fname, la.aa.data[sysno] )
    end
end

function dump_tables(  laout :: AllLegalOutput, settings :: Settings, num_systems :: Integer )
    runname = Utils.basiccensor(settings.run_name)
    for sysno in 1:num_systems 
        outfname = "$(settings.output_dir)/$(runname)-main_la_tables-$(sysno).md"
        println( "writing to $outfname")
        f = open( outfname,"w")
        println( f, "# Run : $(settings.run_name) - Main Tables")
        for t in LA_TARGETS
            println(f, "\n## "*Utils.pretty(string(t))); println(f)        
            println(f,"### Civil Legal Aid")
            println(f, "\n#### a) Benefit Units "); 
            pretty_table(f,laout.civil.breakdown_bu[sysno][t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
            println(f, "\n#### b) Individuals "); 
            pretty_table(f,laout.civil.breakdown_pers[sysno][t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
            println(f,"### Advice and Assistance")
            println(f, "\n#### a) Benefit Units "); 
            pretty_table(f,laout.aa.breakdown_bu[sysno][t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
            println(f, "\n#### b) Individuals "); 
            pretty_table(f,laout.aa.breakdown_pers[sysno][t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
            println(f)
        end
        close(f)
    end
    
    f = open( "$(settings.output_dir)/$(runname)-la_crosstabs.md","w")
    println( f, "# Run : $(settings.run_name) - Cross Table Civil Entitlement")
    for sysno in 2:num_systems 
        ctno = sysno - 1 # since table 1 is 2 vs 1 and so on
        println( f, "##  System $sysno vs System 1  Benefit Unit Level" )
        pc = Utils.matrix_to_frame( laout.civil.crosstab_bu[ctno], ENTITLEMENT_STRS, ENTITLEMENT_STRS  )
        pretty_table(f,pc,formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
        println( f, "### cross table AA entitlement")
        pa =  Utils.matrix_to_frame( laout.aa.crosstab_bu[ctno], ENTITLEMENT_STRS, ENTITLEMENT_STRS  )
        pretty_table(f,pa,formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
        for p in LegalAidData.PROBLEM_TYPES
            for est in LegalAidData.ESTIMATE_TYPES
                println( f, "\n### System $sysno vs system 1: Personal Level Problem $p estimate $(est) \n\n")
                k = "$(p)-$(est)"
                pa =  Utils.matrix_to_frame( laout.civil.crosstab_pers[ctno][k], ENTITLEMENT_STRS, ENTITLEMENT_STRS  )
                pretty_table(f,pa,formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
            end
        end
    end # systems
    close(f)
end

function crosstab_to_df( ct :: Matrix ) :: DataFrame
    Utils.matrix_to_frame( ct, ENTITLEMENT_STRS, ENTITLEMENT_STRS  )
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
