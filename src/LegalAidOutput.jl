
#=
Output routines for Legal Aid, split out for manageability.
=#
module LegalAidOutput 

using CSV,
      DataFrames,
      Format,
      PrettyTables,
      StatsBase,
      ArgCheck

using ScottishTaxBenefitModel
# FIXME explicit imports
using .Definitions,
    .FRSHouseholdGetter,
    .LegalAidData,
    .ModelHousehold,
    .Results,
    .RunSettings,
    .Utils,
    .GeneralTaxComponents

export AllLegalOutput, LegalOutput, summarise_la_output!

mutable struct LegalOutput
    num_systems :: Int
    data :: Vector{DataFrame}
    breakdown_bu :: Vector{AbstractDict}
    breakdown_pers :: Vector{AbstractDict}
    cases_pers :: Vector{AbstractDict}
    costs_pers :: Vector{AbstractDict}
    crosstab_bu :: Vector{AbstractMatrix}
    crosstab_bu_examples :: Vector{AbstractMatrix}
    crosstab_pers :: Vector{AbstractMatrix} # Vector{Dict{String,AbstractMatrix}}
    crosstab_pers_examples :: Vector{AbstractMatrix}
    summary_tables :: Vector{AbstractDataFrame}
end

mutable struct AllLegalOutput
    aa :: LegalOutput
    civil :: LegalOutput
end

mutable struct PropensitiesWrapper 
    civil_propensities :: DataFrame
    aa_propensities :: DataFrame
end

PROPENSITIES = PropensitiesWrapper(
        DataFrame(),
        DataFrame())


function create_propensities( lout :: LegalAidOutput.AllLegalOutput; reset_results = false )
    if (size( PROPENSITIES.civil_propensities )[1] <= 1) || reset_results
        PROPENSITIES.civil_propensities = create_wide_propensities( 
            lout.civil.data[1], 
            LegalAidData.CIVIL_COSTS )
        PROPENSITIES.aa_propensities = create_wide_propensities( 
            lout.aa.data[1], 
            LegalAidData.AA_COSTS )
    end
end


"""
Hacky hacky: reallocated some of the `la_full` props to `la_passported`
where `la_passported` is zero. This fixes some problems where entitlement falls but costs go up.
I'm tired and this is a mess.
@param props 
@param subjects a list of LA claim types
"""
function fixup_props!( props :: DataFrame, subjects :: Vector )
    for r in eachrow(props)
        for subject in subjects
            cost_col = Symbol( "$(subject)_cost")
            prop_col = Symbol( "$(subject)_prop")
            if (r[prop_col] == 0) && (r.la_status == la_passported)
                println( "fixing up $subject")
                @show r
                
                alt = props[ ((props.sex.== r.sex) .& 
                        (props.la_status .== la_full) .&
                        (props.age2 .== r.age2)), :]
                prop = 0.0
                if size( alt )[1] == 1
                    cases = r.popn*alt[1,prop_col]
                    prop = cases/(r.popn+alt.popn[1])
                    r[prop_col] = prop
                    r[cost_col] = alt[1,cost_col]
                    println( "cost set to $(r[cost_col])")
                end
                props[ ((props.sex.== r.sex) .& 
                        (props.la_status .== la_full) .&
                        (props.age2 .== r.age2)), prop_col] .= prop
            end
        end # for
    end # for
    # if 
end # func

#=
function fixup_props!( props :: DataFrame, subjects :: Vector )
    for r in eachrow(props)
        for subject in subjects
            cost_col = Symbol( "$(subject)_cost")
            prop_col = Symbol( "$(subject)_prop")
            if r[prop_col] == 0 && r.la_status == "la_passported"
                println( "fixing zero for $cost_col sex=$(r.sex) age2=$(r.age2)")
                alt = props[ ((props.sex.== r.sex) .& 
                        (props.la_status .== "la_full") .&
                        (props.age2 .== r.age2)), :]
                cases = alt.popn[1]*alt[1,prop_col]
                prop = cases/(r.popn+alt.popn[1])
                println( "subject $subject cases $cases prop $prop" )
                r[prop_col] = prop
                r[cost_col] = alt[1,cost_col]
                props[ ((props.sex.== r.sex) .& 
                        (props.la_status .== "la_full") .&
                        (props.age2 .== r.age2)), prop_col] .= prop
            end
        end # for
    end # for
end


=#
        
"""
This is the base of the costs model
entitlement = out.civil.data[1]  or out.aa

"""
function create_base_propensities( 
    entitlement :: DataFrame,
    costs :: DataFrame ) :: NamedTuple

    function rn( s :: AbstractString ) :: String
        matches = match(r"(.*)_1",s)
        if ! isnothing(matches)
           return matches[1]*"_prop"
        end
        if s in ["hsm", "age2", "sex", "popn", "case_freq", "la_status" ]        
            return s
        end
        return s*"_cost"
     end

    subjects = levels( costs.hsm )   # divorce and so on 
    entitlement.la_status = entitlement.entitlement # match names in the actual output
    # so this is the calculated entitlements, individual level, grouped by entitlement, age & sex
    entitlement_grp = groupby(entitlement, [:la_status, :age2, :sex])
    # and these are the SLAB costs, grouped by same and also by problem type (hsm = Higher Subject)
    costs_grp4 = groupby( costs, [:hsm, :la_status, :age2, :sex])
    # .. and without the subject to get a quick and dirty way to get total costs
    costs_grp3 = groupby( costs, [:la_status, :age2, :sex])
    # make a dataframe class by types of claim, la entitlement, age & sex
    n = size( entitlement_grp )[1]*(1+length(subjects)) 
    out = DataFrame( 
        hsm = fill("",n ), 
        age2 = fill("",n), 
        sex = fill(Male,n),
        case_freq = zeros(n), 
        case_count = zeros(n), 
        costs_total = zeros(n), 
        popn = zeros(n),        
        la_status = fill( la_none, n ),
        costs_max = zeros(n), 
        costs_mean = zeros(n), 
        costs_median = zeros(n), 
        costs_min = zeros(n), 
        costs_nmiss = zeros(n), 
        costs_nobs = zeros(n), 
        costs_q25 = zeros(n), 
        costs_q75 = zeros(n))
    i = 0
    
    for (k,v) in pairs( entitlement_grp )
        for hsm in subjects # divorce ... 
            i += 1
            lout = out[i,:]
            lout.popn = sum( v.weight )
            lout.sex = k.sex
            lout.age2 = k.age2
            lout.hsm = hsm
            lout.la_status = k.la_status
            # now, look up corresponding costs data: first make a key to disagg grouped dataframe
            costk = make_key( 
                la_status = k.la_status, 
                hsm = hsm,
                age = k.age2,
                sex = k.sex )
            # @show costk
            # then look up & fill if there are records for the costs for that combo 
            # FIXME won't work properly for "Adults with incapacity" since there isn't a status for this in the costs
            if haskey( costs_grp4, costk ) 
                cv = costs_grp4[costk] 
                r = summarystats( cv.totalpaid ./ 1000.0 ) # in 000s
                lout.case_count = size(cv)[1]
                lout.costs_total = sum( cv.totalpaid )
                lout.costs_max = r.max     
                lout.costs_mean = r.mean
                lout.costs_median = r.median  
                lout.costs_min = r.min
                lout.costs_nmiss = r.nmiss   
                lout.costs_nobs = r.nobs
                lout.costs_q25 = r.q25     
                lout.costs_q75 = r.q75
                lout.case_freq = r.nobs / lout.popn 
            end
        end # each subject
        # total 
        i += 1
        lout = out[i,:]
        lout.popn = sum( v.weight )
        lout.sex = k.sex
        lout.age2 = k.age2
        lout.hsm = "aa_total"
        lout.la_status = k.la_status
        # now, look up corresponding costs data: first make a key to disagg grouped dataframe
        costk = make_key( 
            la_status = k.la_status, 
            age = k.age2,
            sex = k.sex )
        # @show costk
        # then look up & fill if there are records for the costs for that combo 
        # FIXME won't work properly for "Adults with incapacity" since there isn't a status for this in the costs
        if haskey( costs_grp3, costk ) 
            cv = costs_grp3[costk] 
            r = summarystats( cv.totalpaid  ) # in 000s
            lout.costs_max = r.max     
            lout.costs_mean = r.mean
            lout.costs_median = r.median  
            lout.costs_min = r.min
            lout.costs_nmiss = r.nmiss   
            lout.costs_nobs = r.nobs
            lout.costs_q25 = r.q25     
            lout.costs_q75 = r.q75
            lout.case_freq = r.nobs / lout.popn 
        end
    end
    sort!( out, [:hsm,:la_status,:sex, :age2])
    av_costs_by_type = unstack(out[!,[:hsm,:sex,:age2,:popn,:la_status,:costs_mean]],:hsm,:costs_mean)


    rename!( av_costs_by_type, Utils.basiccensor.(names(av_costs_by_type)))
    cases_by_type = unstack(out[!,[:hsm,:sex,:age2,:la_status,:popn,:case_freq]],:hsm,:case_freq)
    rename!( cases_by_type, Utils.basiccensor.(names(cases_by_type)))
    # join the av costs and propensities together
    cost_and_count = hcat( av_costs_by_type, cases_by_type, makeunique=true )
    # fix the auto renaming: _1 => _cases and so on
    rename!( rn, cost_and_count )

    # Hack for adults_with_incapacity, since these are effectively outside 
    # of the means-test. Make a uniform takeup and cost so we always 
    # get the same output regardless of entitlements when weighred up.
    awi = costs[ costs.hsm .== "Adults with incapacity", :] 
    @assert size( awi )[1] > 0
    awicost = sum( awi.totalpaid )
    awicount = length( awi.totalpaid )
    popn = sum( entitlement.weight )
    cost_and_count.adults_with_incapacity_cost .= awicost/(awicount*1000) # in 000s
    cost_and_count.adults_with_incapacity_prop .= awicount/popn

    println( "create_base_propensities cost_and_count=")
    @show cost_and_count
    fixup_props!( cost_and_count, Utils.basiccensor.(subjects))
    return (; cost_and_count, long_data=out )
end

function create_wide_propensities(
    entitlement :: DataFrame,
    costs :: DataFrame ) :: DataFrame
    return create_base_propensities( 
        entitlement, costs ).cost_and_count
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
        household_composition = fill( single_person, n ),
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

        uc_entitlement = zeros(n),
        uc_income = zeros(n),
        extra_allowances = zeros(n),

        capital = zeros(n),
        childcare = zeros(n),
        housing = zeros(n),        
        work_expenses = zeros(n),
        repayments = zeros(n),
        maintenance = zeros(n),
        outgoings = zeros(n),

        income_contribution_amt = zeros(n),
        capital_contribution_amt = zeros(n),
        
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

function summarise_expenses( df :: DataFrame ) :: GroupedDataFrame
    dfh = df[df.is_bu_head.==true,:]
    groupby( dfh, [:entitlement] )
end

"""
Add the propensities for each type of LA to the calculated entitlement data, matching on sex,age,entitlement type.
results: df with calculated entitlements, contributions and demographics. See `make_legal_aid_frame` above.
problem_probs: NOT NEEDED this is the file civil-legal-aid-probs-scotland-2015-2012 (should be '21') derived from the Scottish Crime and Justice Survey. It's not really used anymore.
propensities: this is the probability of a person of some age/sex/entitlement status claiming each type of legal aid under either AA or Civil. See `create_propensities`/`create_base_propensities`.
"""
function merge_in_probs_and_props( 
    results :: DataFrame,
    problem_probs :: DataFrame,
    propensities :: DataFrame )
    rsize = size( results )[1]
    r = leftjoin( 
        results, 
        problem_probs; 
        on = [:hid, :data_year, :pid ], 
        makeunique=true)
    # @show names(r)
    # @show names(propensities)
    r = leftjoin( 
        r, 
        propensities;
        on = [:age2=>:age2,:sex=>:sex,:entitlement=>:la_status ],
        makeunique=true) # unique shouldn't be needed here??
    @assert size(r)[1] == rsize # no shorter
    # Needed since leftjoin puts unmatched right at the end
    # ?? bu_number prob not needed.
    sort!( r, [:hid, :data_year, :pid, :bu_number ])
    return r #[ r.from_child_record .!= 1,:] - we're adding children now
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
    pr.tenure = hh.tenure
    pr.household_composition = household_composition_1( hh )
    pr.decile = hh.equiv_original_income_decile
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
    pr.age = pers.age
    pr.age2 = agestr2( pers.age )
    pr.sex = pers.sex
    pr.all_eligible = lr.eligible | lr.passported
    pr.mt_eligible = lr.eligible
    pr.passported = lr.passported
    pr.any_contribution = (lr.capital_contribution + lr.income_contribution) > 0
    pr.capital_contribution = lr.capital_contribution > 0
    pr.income_contribution = lr.income_contribution > 0

    pr.income_contribution_amt = lr.income_contribution
    pr.capital_contribution_amt = lr.capital_contribution
    
    pr.uc_entitlement = lr.uc_entitlement
    pr.uc_income = lr.uc_income
    pr.extra_allowances = lr.extra_allowances

    pr.capital = lr.capital
    pr.childcare = lr.childcare
    pr.housing = lr.housing 
    pr.work_expenses = lr.work_expenses
    pr.repayments = lr.repayments
    pr.maintenance = lr.maintenance
    pr.outgoings = lr.outgoings

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
        end # people in bu
    end # bus
end # function 

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
    :household_composition,
    :sex,
    :age2,
    :decile,
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
always use cost from pre.
If state falls, use the propensity from the lower state and vice versa.  
Together these should stop costs and takeup sometimes rising as elig is cut, and vice versa.
"""
function make_post_consistent_with_pre!(; 
    post :: DataFrame, 
    pre :: DataFrame,
    cost_items :: Vector,
    prop_items :: Vector )
    @argcheck size(pre)[1] == size(post)[1]
    n = size(pre)[1]
    @show cost_items
    @show prop_items
    for i in 1:n
        r2 = post[i,:]
        r1 = pre[i,:]
        for c in cost_items # always use base cost
            r2[c] = r1[c] 
        end
        @assert (r1.hid == r2.hid) && (r1.pid == r2.pid) && (r1.data_year == r2.data_year)
        if r2.entitlement > r1.entitlement 
            # *worse* entitlement post, since enum is passported,full...  
            # Always use lower take prop of pre/post
            for p in prop_items
                 r2[p] = min( r2[p], r1[p])
            end
            # println("worsened; ")
        elseif r2.entitlement < r1.entitlement
            for p in prop_items # improved; always use higher prop
                r2[p] = max( r2[p], r1[p])
            end
        end
    end
end

"""
Combine the legal aid dataframe on the column `to_combine`, using either `weight` or `weighted_people`
return a dataframe (grouped?) with LA_BITS as columns and broken down values for one of TARGETS.
"""
function combine_one_legal_aid( 
    df :: DataFrame, 
    to_combine :: Symbol, 
    weighted_cols :: AbstractArray,
    labels :: AbstractArray )::AbstractDataFrame
    gdf = groupby( df, to_combine )
    outf = combine( gdf, weighted_cols .=>sum )
    sort!( df, to_combine )
    # column names: add `Tenure`, 'Employment' or whatever as the 1st entry
    labels = push!( [Utils.pretty(string(to_combine))], labels... )
    # .. then rename the columns to these 
    rename!( outf, labels )
    # @show outf
    sort!( outf)
    return coalesce.(outf,0) # fix missings
end

function combine_costs(
    df :: DataFrame,
    to_combine :: Symbol,
    weighted_cols :: AbstractArray ):: AbstractDataFrame

end

function fixup_totals!( df :: DataFrame )
    df[!,begin+1] .= 0.0
    for r in eachrow( df )
       r[begin+1] = sum( r[(begin+1):end]) 
    end
end

"""
cost_items - names of each:
  - costs: la type costs columns
  - props: la type propensities
  - labels: pretty print label
"""
function make_summary_table( 
    pre :: DataFrame, 
    post :: DataFrame,
    cost_items :: NamedTuple ) :: DataFrame
    @argcheck size(pre) == size(post)
    tab = DataFrame( 
        labels=["Cases","Gross Cost","Contributions","Net Cost"],
        pre=zeros(4),
        post=zeros(4),
        change=zeros(4))
    nrows,ncols = size( pre )
    ccc = LegalAidData.CIVIL_COST # alias
    for i in 1:ncols
        tab[2,3] += sample( 
            ccc[
                ccc.categorydescription.=="Contact", 
                :totalpaid])
    end
    return tab
end

"""
Call `combine_one_legal_aid` on all the `TARGETS`

return a dictionary of grouped dataframes 
"""
function aggregate_all_legal_aid( 
    df :: DataFrame, 
    weight_sym :: Symbol, 
    target_columns :: AbstractVector,
    labels :: AbstractVector,
    target_costs :: AbstractVector = [];
    fixup_totals = false ) :: Dict
    # in case there are holes in the dataframe, for example when created at BU levels.
    df = df[df.hid .>0,:]
    weighted_cols = []
    # Make summing easier by add weighted columms to la counts columns.
    # LA_BITS are the column headers: numbers of cases, numbers of those
    # eligible and so on. So for eligibble (1/0), add wt_eligible, and so on.
    for i in eachindex(target_columns)
        tc = target_columns[i]
        psym = Symbol( "wt_$(tc)")
        if length(target_costs) > 0
            tcost = target_costs[i]
            df[:,psym] .= df[:,weight_sym].*df[:,tc].*df[:,tcost]
        else
            df[:,psym] .= df[:,weight_sym].*df[:,tc]
        end
        push!( weighted_cols, psym )
    end
    # Make a dictionary of tables of la results, broken dowb by tenure, employment,
    # etc.
    # pass one thing from LA_TARGETS (tenure, employment etc) as a grouping
    # variable to the combine function.
    alltab = Dict()
    for t in LA_TARGETS
        gdp = combine_one_legal_aid( df, t, weighted_cols, labels )
        if fixup_totals
            fixup_totals!( gdp )
        end
        alltab[t] = gdp
    end
    return alltab
end

"""

"""

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

function cost_item_names( 
    wideds ::AbstractDataFrame )::NamedTuple
    costs=[]
    props=[]
    labels=[]
    for i in sort(names(wideds))
      m = match( r"(.*)_cost", i )
      if ! isnothing(m)
        push!( costs, Symbol( "$(m[1])_cost" ))
        push!( props, Symbol( "$(m[1])_prop" )) 
        push!( labels, pretty( m[1] ))
    end; end
    (;costs, props, labels)
end

"""
Are two dfs the same size, are the id fields in sync? 
For crosstabbing. Throws an exception if not.
"""
function df_idiot_check( 
    df1::AbstractDataFrame, 
    df2::AbstractDataFrame,
    cols = [:hid, :bu_number, :data_year, :pno])
    sz1=size(df1)
    sz2=size(df2)
    @assert sz1[1] == sz2[1] "size mismatch $sz1 $sz2"
    for c in cols
        if ! all( df1[!,c] .== df2[!,c] )
            CSV.write("tmp/df1-error.tab", df1; delim='\t' )
            CSV.write("tmp/df2-error.tab", df2; delim='\t' )
            n = 0
            for i in 1:sz1[1]
                preh = df1[i,c]
                posth = df2[i,c]
                if (preh !== posth) && (n < 20)
                    n += 1
                    println( "differ at pos $i preh=$preh posth=$posth")
                end
            end
            @assert false "col mismatch $c"
        end # some differ
    end # each check col
end

function la_crosstab( 
    pre :: DataFrame, 
    post :: DataFrame, 
    problem="no_problem", 
    estimate="prediction" ) :: Tuple
    df_idiot_check(pre, post)
    weights = Weights(pre.weight) 
    if problem != "no_problem"
        col = Symbol( "$(problem)_$estimate")
        weights = Weights( pre[:,col] .* pre.weight)
    end
    
    crosstab, rowlabels, collabels, examples = make_crosstab( 
        post.entitlement,
        pre.entitlement;
        weights=weights,
        max_examples = 10 ) 
    exs = size( examples )
    # Convert example positions into hhseq/datayear pairs, so
    # we can retrieve the hhld easily.
    full_examples = Array{Vector{OneIndex}}(undef,exs[1],exs[2])
    for r in 1:exs[1]
        for c in 1:exs[2]
            full_examples[r,c] = Vector{OneIndex}()
            for i in examples[r,c]
                prer = pre[i,:]
                seqy = OneIndex( prer.hid, prer.data_year )
                if ! (seqy in full_examples[r,c])
                    push!( full_examples[r,c], seqy )
                end
            end
        end
    end
    return crosstab, full_examples
end

"""
Fixed silly Crosstab with entitlement wired in because my general crosstab is 
breaking in a way I can't work out.
pre is the row, post is the col, cells above the diagonal represent gains, below losses.
"""
#=
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
=#

function summarise_la_output!( 
    la :: LegalOutput,
    propensities :: DataFrame, 
    is_aa :: Bool )
    # base data 
    data1 = merge_in_probs_and_props( 
        la.data[1], 
        LegalAidData.LA_PROB_DATA,
        propensities )
    budata1 = data1[data1.is_bu_head, : ] 
    for sysno in 1:la.num_systems
        data = merge_in_probs_and_props( 
            la.data[sysno], 
            LegalAidData.LA_PROB_DATA,
            propensities )
        cost_items = cost_item_names( data )
        make_post_consistent_with_pre!(; 
            post = data, 
            pre  = data1,
            prop_items = cost_items.props, 
            cost_items = cost_items.costs )
        budata = data[data.is_bu_head,:] 
        la.breakdown_pers[sysno] = aggregate_all_legal_aid( 
            data, 
            :weight, 
            LA_BITS, 
            LA_LABELS )
        la.breakdown_bu[sysno]  = aggregate_all_legal_aid( 
            budata, 
            :weight, 
            LA_BITS, 
            LA_LABELS )
        
        la.cases_pers[sysno] = aggregate_all_legal_aid( 
            data, 
            :weight, 
            cost_items.props, 
            cost_items.labels;
            fixup_totals=true )
        la.costs_pers[sysno] = aggregate_all_legal_aid( 
                data, 
                :weight, 
                cost_items.props, 
                cost_items.labels,
                cost_items.costs;
                fixup_totals=true )
        
        if sysno > 1
            #=
            for p in LegalAidData.PROBLEM_TYPES
                for est in LegalAidData.ESTIMATE_TYPES
                    k = "$(p)-$(est)"
                    # FIXME fancy crosstab is breaking:: More unitests
                    la.crosstab_pers[sysno-1][k] = la_crosstab( data1, data, p, est )
                end # estimates          
            end # problems
            =#
            la.crosstab_pers[sysno-1], la.crosstab_pers_examples[sysno-1] = 
                la_crosstab( data1, data )
            la.crosstab_bu[sysno-1], la.crosstab_bu_examples[sysno-1] = 
                la_crosstab( budata1, budata )

            la.summary_tables[sysno-1] = make_summary_tab(data1, data, is_aa )
        end # sysno > 1
    end
end

function summarise_la_output!( 
    la :: AllLegalOutput )
    println( "summary: civil")
    summarise_la_output!( la.civil, PROPENSITIES.civil_propensities, false )
    println( "summary: aa")
    summarise_la_output!( la.aa, PROPENSITIES.aa_propensities, true )
end

"""

"""
function dump_frames( la :: AllLegalOutput, settings :: Settings; num_systems::Integer )
    runname = Utils.basiccensor(settings.run_name)
    for sysno in 1:num_systems
        fname = "$(settings.output_dir)/$(runname)_$(sysno)_legal_aid_civil.tab"
        CSV.write( fname, la.civil.data[sysno]; delim='\t' )
        fname = "$(settings.output_dir)/$(runname)_$(sysno)_legal_aid_aa.tab"
        CSV.write( fname, la.aa.data[sysno]; delim='\t' )
    end
end

function dump_tables(  laout :: AllLegalOutput, settings :: Settings; num_systems :: Integer )
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
            println(f, "\n#### c) Individuals - cases "); 
            pretty_table(f,laout.civil.cases_pers[sysno][t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
            println(f, "\n#### d) Individuals - costs "); 
            pretty_table(f,laout.civil.costs_pers[sysno][t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
           
            
            println(f,"### Advice and Assistance")
            println(f, "\n#### a) Benefit Units "); 
            pretty_table(f,laout.aa.breakdown_bu[sysno][t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
            println(f, "\n#### b) Individuals "); 
            pretty_table(f,laout.aa.breakdown_pers[sysno][t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
            println(f, "\n#### c) Individuals - cases "); 
            pretty_table(f,laout.aa.cases_pers[sysno][t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
            println(f, "\n#### c) Individuals - costs "); 
            pretty_table(f,laout.aa.costs_pers[sysno][t],formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
            println(f)
        end
        close(f)
    end
    
    f = open( "$(settings.output_dir)/$(runname)-la_crosstabs.md","w")
    println( f, "# Run : $(settings.run_name) - Cross Table Civil Entitlement")
    for sysno in 2:num_systems 
        ctno = sysno - 1 # since table 1 is 2 vs 1 and so on
        println( f, "##  System $sysno vs System 1 Summary Table - CIVIL" )
        pretty_table(
            f, 
            laout.civil.summary_tables[ctno], 
            backend = Val(:markdown), 
            cell_first_line_only=true)
        println( f, "##  System $sysno vs System 1  Benefit Unit Level" )
        pc = Utils.matrix_to_frame( laout.civil.crosstab_bu[ctno], ENTITLEMENT_STRS, ENTITLEMENT_STRS  )
        pretty_table(f,pc,formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
        println( f, "##  System $sysno vs System 1 Summary Table - AA" )
        pretty_table(
            f, 
            laout.aa.summary_tables[ctno], 
            backend = Val(:markdown), 
            cell_first_line_only=true)
        println( f, "### cross table AA entitlement")
        pa =  Utils.matrix_to_frame( laout.aa.crosstab_bu[ctno], ENTITLEMENT_STRS, ENTITLEMENT_STRS  )
        pretty_table(f, pa, formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)

        println( f, "##  System $sysno vs System 1 Personal Level" )
        pc = Utils.matrix_to_frame( laout.civil.crosstab_pers[ctno], ENTITLEMENT_STRS, ENTITLEMENT_STRS  )
        pretty_table(f,pc,formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
        println( f, "### cross table AA entitlement - Personal Level")
        pa =  Utils.matrix_to_frame( laout.aa.crosstab_pers[ctno], ENTITLEMENT_STRS, ENTITLEMENT_STRS  )
        pretty_table(f, pa, formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)

        #=
        for p in LegalAidData.PROBLEM_TYPES
            for est in LegalAidData.ESTIMATE_TYPES
                println( f, "\n### System $sysno vs system 1: Personal Level Problem $p estimate $(est) \n\n")
                k = "$(p)-$(est)"
                pa =  Utils.matrix_to_frame( laout.civil.crosstab_pers[ctno][k], ENTITLEMENT_STRS, ENTITLEMENT_STRS  )
                pretty_table(f,pa,formatters=pt_fmt, backend = Val(:markdown), cell_first_line_only=true)
            end
        end
        =#
    end # systems
    close(f)
end

function crosstab_to_df( ct :: Matrix ) :: DataFrame
    Utils.matrix_to_frame( ct, ENTITLEMENT_STRS, ENTITLEMENT_STRS  )
end

"""
FIXME not used as it's really slow
"""
function get_sample_case_cost( 
    hsm:: AbstractString, 
    # status::String, 
    sex::AbstractString, 
    age2::AbstractString,
    contrib::Number,
    is_aa :: Bool )::Number
    costs = is_aa ? LegalAidData.CIVIL_COSTS : LegalAidData.AA_COSTS 
    paid = costs[(costs.age2.==age2) .& (costs.sex.==sex) .& (costs.hsm_censored .== hsm ),:totalpaid]
    npaid = size(paid)[1]
    tot = 0.0
    for i in 1:npaid
        tot += min( contrib, paid[i])
    end
    println( "hsm $hsm npaid $npaid tot")
    return npaid == 0 ? 0.0 : tot/npaid
end

function summary_frame()
    return  DataFrame( 
        labels=["Cases","Gross Cost","Contributions","Net Cost"],
        pre=zeros(4),
        post=zeros(4),
        change=zeros(4))
end


"""
pre: results with merged propensities
post: results with merged propensities
FIXME: clean this up drastically
"""
function make_summary_tab(
    pre :: DataFrame,
    post :: DataFrame,
    is_aa :: Bool;
    weight_sym = :weight )
    @argcheck size(pre)[1]==size(post)[1]
    nrows,ncols = size(pre)    
    weeks = is_aa ? 1.0 : WEEKS_PER_YEAR
    is_aa = true
    tab = summary_frame()
    prop_cols = [
        "adults_with_incapacity",
        "contact_or_parentage",
        "family_or_matrimonial_other",
        "other",
        "residence"]
    tsize = size(prop_cols)[1]
    for row in 1:nrows
        pr = pre[row,:]
        po = post[row,:]
        w = pr[weight_sym]
        @assert w == po[weight_sym]
        max_contrib_pr = 
            pr.income_contribution_amt*weeks
            pr.capital_contribution_amt
        max_contrib_po = 
            po.income_contribution_amt*weeks
            po.capital_contribution_amt
        @show po
        for i in 1:tsize 
            tc = Symbol(prop_cols[i]*"_prop")
            tcost = Symbol(prop_cols[i]*"_cost")
            tab[1,2] += w*pr[tc]
            tab[1,3] += w*po[tc]
            tab[2,2] += w*pr[tc]*pr[tcost]
            tab[2,3] += w*po[tc]*pr[tcost]
            # scase_pr = get_sample_case_cost( prop_cols[i], pr.sex, pr.age2, max_contrib_pr, is_aa )/1000.0
            # scase_po = get_sample_case_cost( prop_cols[i], pr.sex, pr.age2, max_contrib_po, is_aa )/1000.0
            tab[3,2] += w*pr[tc]*max_contrib_pr/1000 #*scase_pr # 
            tab[3,3] += w*po[tc]*max_contrib_po/1000 # scase_po # 
        end
    end
    tab[4,2] = tab[2,2] - tab[3,2]
    tab[4,3] = tab[2,3] - tab[3,3]
    tab[:,4] = tab[:,3] .- tab[:,2]
    return tab
end

function LegalOutput( T; num_systems::Integer, num_people::Integer )
    datas = Vector{DataFrame}(undef,0)
    breakdown_bu = Vector{Dict}(undef,0)
    breakdown_pers = Vector{Dict}(undef,0)
    cases_pers = Vector{Dict}(undef,0)
    costs_pers = Vector{Dict}(undef,0) # Vector{Matrix}(undef,0) # 
    crosstab_bu = Vector{Matrix}(undef,0)
    crosstab_bu_examples = Vector{Matrix}(undef,0)
    crosstab_pers = Vector{Matrix}(undef,0) # Vector{Dict{String,Matrix}}(undef,0)
    crosstab_pers_examples = Vector{Matrix}(undef,0)
    summary_tables = Vector{DataFrame}(undef,0)
    for sysno in 1:num_systems
        push!( datas, make_legal_aid_frame( T, num_people ))
        push!( breakdown_pers, Dict())
        push!( breakdown_bu, Dict())
        push!( cases_pers, Dict())
        push!( costs_pers, Dict())
        push!( breakdown_bu, Dict())
        if sysno < num_systems
            push!(crosstab_pers, fill(T,4,4)) # Dict()) # )
            push!( crosstab_pers_examples, fill(Int[],4,4))    
            push!(crosstab_bu, fill(T,4,4))
            push!( crosstab_bu_examples, fill(Int[],4,4))    
            push!(summary_tables, summary_frame());
    
        end
    end
    LegalOutput( 
        num_systems, 
        datas, 
        breakdown_bu, 
        breakdown_pers, 
        cases_pers, 
        costs_pers, 
        crosstab_bu, 
        crosstab_bu_examples,
        crosstab_pers,
        crosstab_pers_examples,
        summary_tables )
end

function AllLegalOutput( T; num_systems::Integer, num_people::Integer )
    AllLegalOutput( 
        LegalOutput( T; num_systems=num_systems, num_people=num_people ),
        LegalOutput( T; num_systems=num_systems, num_people=num_people))
end
    

end # module
