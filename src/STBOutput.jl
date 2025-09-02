module STBOutput

using DataFrames: 
    AbstractDataFrame,
    DataFrame, 
    DataFrameRow, 
    Not, 
    combine, 
    groupby, 
    rename!,
    select!, 
    sum,
    unstack

using PovertyAndInequalityMeasures
using CSV
using Format
using PrettyTables

using StatsBase
using ScottishTaxBenefitModel
using .Definitions
using .Utils
using .Results: 
    BenefitUnitResult,
    HouseholdResult,
    OneLegalAidResult,
    LegalAidResult,
    IndividualResult,
    total

using .STBIncomes
using .LegalAidOutput
using .ModelHousehold

using .FRSHouseholdGetter: 
    get_slot_for_household,
    get_people_slots_for_household,
    get_slot_for_person
    
using .RunSettings

using .SimplePovertyCounts: 
    GroupPoverty,
    calc_child_poverty

export 
    add_to_frames!,
    dump_frames,
    dump_summaries,
    fill_in_deciles_and_poverty!,
    hdiff,
    idiff,
    initialise_frames,
    irdiff,
    make_gain_lose,
    make_poverty_line,
    summarise_frames!,
    DUMP_FILE_DESCRIPTION

const DUMP_FILE_DESCRIPTION = 
"""
# Dump File Contents

* quantiles_1.tab - data for Lorenz curves and the deciles graph;
* quantiles_2.tab -
* income_summary_1.tab - aggregate incomes by income type, broken down by tenure, hh type, etc.;
* income_summary_2.tab -
* short_income_summary.tab - condensed version of the income data.
* poverty-inequality-metrs-child-poverty.md - rather hard to read dump of poverty, etc. tables in Markdown format;
* gainlose_1.md - Gainers and losers tables;
* gainlose_2.md -

## Other Tables

If present, these contain micro level data and are probably not needed by you:

* bu_1.tab -  Benefit Level
* bu_2.tab -
* hh_1.tab - Household Level
* hh_2.tab -
* income_1.tab - micro level detailed incomes data -
* income_2.tab -
* indiv_1.tab - micro level individual demographics
* indiv_2.tab -

### Note: 

* the `_2` (and upwards) indicates results for the changed systems; `_1` is the base;
* `.tab` extension indicated tab- delimited format (can be imported into spreadsheets);
* `.md` are markdown files (can be imported into most word-processors);
* There may also be `.svg` files: these are images in Scalable Vector Graphic format.

"""

# count of the aggregates added to the income_frame - total benefits and so on, plus 8 indirect fields
const EXTRA_INC_COLS = 18

function make_household_results_frame( n :: Int ) :: DataFrame
    make_household_results_frame( Float64, n )
end

function make_household_results_frame( RT :: DataType, n :: Int ) :: DataFrame
    DataFrame(
        hid       = zeros( BigInt, n ),
        sequence  = zeros( Int, n ),
        data_year  = zeros( Int, n ),
        
        weight    = zeros(RT,n),
        weighted_people = zeros(RT,n),
        hh_type   = zeros( Int, n ),
        num_people = zeros( Int, n ),
        tenure    = fill( Missing_Tenure_Type, n ),
        region    = fill( Missing_Standard_Region, n ),
        decile = zeros( Int, n ),
        in_poverty = fill( false, n ),
        bhc_net_income = zeros(RT,n),
        ahc_net_income = zeros(RT,n),
        # eq_scale = zeros(RT,n),
        eq_bhc_net_income = zeros(RT,n),
        eq_ahc_net_income = zeros(RT,n), # etc.
        income_taxes = zeros(RT,n),
        means_tested_benefits = zeros(RT,n),
        other_benefits = zeros(RT,n),
        scottish_income_tax = zeros(RT,n),
        indirect_taxes = zeros(RT,n),
        num_children = zeros(RT,n)
    )
end

function hdiff( df1 :: DataFrame, df2 :: DataFrame )
    p1 = index_of_field( df1, "bhc_net_income")
    p2 = index_of_field( df1, "num_children")-1
    return df_diff( df1, df2, p1, p2 )
end

function make_bu_results_frame( n :: Int ) :: DataFrame
    return make_bu_results_frame( Float64, n )
end

function make_bu_results_frame( RT :: DataType, n :: Int ) :: DataFrame
    DataFrame(
        hid       = zeros(BigInt,n),
        buno      = zeros( Int, n ),
        data_year = zeros( Int, n ),
        weight    = zeros(RT,n),
        bu_type   = zeros( Int, n ),
        tenure    = zeros( Int, n ),
        region    = zeros( Int, n ),
        decile = zeros( Int, n ),
        in_poverty = fill( false, n ),
        net_income = zeros(RT,n),
        
        income_taxes = zeros(RT,n),
        means_tested_benefits = zeros(RT,n),
        other_benefits = zeros(RT,n)
    )
end

function make_individual_results_frame( n :: Int ) :: DataFrame
    make_individual_results_frame( Float64, n )
end

function make_incomes_frame( RT :: DataType, n :: Int; id = 1 ) :: DataFrame
    frame :: DataFrame = create_incomes_dataframe( RT, n )
    # extra calculated fields
    frame.employers_ni = zeros( n )
    frame.scottish_income_tax = zeros( n ) # i.e. excluding savings & dividends
    frame.total_benefits = zeros( n ) 
    frame.legacy_mtbs  = zeros( n )
    frame.means_tested_bens = zeros( n )
    frame.non_means_tested_bens = zeros( n )
    frame.sickness_illness = zeros( n )    
    frame.scottish_benefits = zeros( n )    
    frame.pension_relief_at_source = zeros( n )
    frame.VED = zeros(n)
    frame.fuel_duty = zeros(n)
    frame.VAT = zeros(n)
    frame.excise_beer = zeros(n)
    frame.excise_cider = zeros(n)
    frame.excise_wine = zeros(n)
    frame.excise_tobacco = zeros(n)
    frame.total_indirect = zeros(n)
    frame.net_cost = zeros( n )
    frame.net_inc_indirect = zeros( n )
    # add some crosstab fields ... 
    frame.id = fill( id, n )
    frame.data_year = zeros( Int, n )
    frame.sex = fill(Missing_Sex,n)
    frame.ethnic_group = fill(Missing_Ethnic_Group,n)
    frame.is_child = fill( false, n )
    frame.age_band  = zeros(Int,n)
    frame.employment_status = fill(Missing_ILO_Employment,n)
    frame.tenure    = fill( Missing_Tenure_Type, n )
    frame.region    = fill( Missing_Standard_Region, n )
    frame.decile = zeros( Int, n )
    frame.in_poverty = fill( false, n )
    frame.council = fill( Symbol( "No_Council"), n)
    return frame
end

"""
Change in the numeric fields of incomes 
"""
function idiff( d1 :: DataFrame, d2 :: DataFrame )
    # the numeric fields are between "income_tax" and "id"
    p1 = index_of_field( d1, "income_tax" )
    p2 = index_of_field( d1, "id")-1
    return df_diff( d1, d2, p1, p2 )        
end


function make_individual_results_frame( RT :: DataType, n :: Int ) :: DataFrame
    DataFrame(
        hid = zeros(BigInt,n),
        pid = zeros(BigInt,n),
        data_year = zeros(Int,n),
        weight = zeros(RT,n),
        sex = fill(Missing_Sex,n),
        ethnic_group = fill(Missing_Ethnic_Group,n),
        is_child = fill( false, n ),
        age_band  = zeros(Int,n),
        employment_status = fill(Missing_ILO_Employment,n),
        # ... and so on

        eq_bhc_net_income = zeros(RT,n),
        eq_ahc_net_income = zeros(RT,n),

        income_taxes = zeros(RT,n),
        means_tested_benefits = zeros(RT,n),
        other_benefits = zeros(RT,n),
        decile = zeros( Int, n ),
        in_poverty = fill( false, n ),

        income_tax = zeros(RT,n),
        it_non_savings = zeros(RT,n),
        it_savings = zeros(RT,n),
        it_dividends = zeros(RT,n),
        it_pension_relief_at_source = zeros(RT,n),
        ni_above_lower_earnings_limit = fill( false, n ),
        ni_total_ni = zeros(RT,n),
        ni_class_1_primary = zeros(RT,n),
        ni_class_1_secondary = zeros(RT,n),
        ni_class_2  = zeros(RT,n),
        ni_class_3  = zeros(RT,n),
        ni_class_4  = zeros(RT,n),
        assumed_gross_wage = Vector{Union{Real,Missing}}(missing, n),         
        metr = Vector{Union{Real,Missing}}(missing, n),
        tax_credit = zeros(RT,n),
        replacement_rate = Vector{Union{Real,Missing}}(missing, n),

        sf12 = zeros( RT,n ),
        sf6 = zeros(RT, n ),
        has_mental_health_problem = fill( false, n ),
        qualys = zeros( RT, n ),
        life_expectancy = zeros(RT, n ) )

end

function irdiff( d1 :: DataFrame, d2 :: DataFrame )
    # the numeric fields are between "income_tax" and "id"
    p1 = index_of_field( d1, "income_taxes" )
    p2 = size(d1)[2]
    return df_diff( d1, d2, p1, p2 )        
end

function initialise_frames( T::DataType, settings :: Settings, num_systems :: Integer  ) :: NamedTuple
    indiv = []
    bu = []
    hh = []
    income = []
    legalaid = nothing
    if settings.do_legal_aid
        legalaid = LegalAidOutput.AllLegalOutput(
            T; 
            num_systems=num_systems, 
            num_people=settings.num_people )
    end
    for s in 1:num_systems
        push!( indiv, make_individual_results_frame( T, settings.num_people ))
        push!( bu, make_bu_results_frame( T, settings.num_people )) # overstates but we don't actually know this at the start
        push!( hh, make_household_results_frame( T, settings.num_households ))
        push!( income, make_incomes_frame( T, settings.num_people )) # overstates but we don't actually know this at the start            
    end
    (; hh, bu, indiv, income, legalaid ) #, civil_legalaid_pers, civil_legalaid_bu, aa_legalaid_pers, aa_legalaid_bu )
end


function fill_hh_frame_row!( hr :: DataFrameRow, hh :: Household, hres :: HouseholdResult )
    nps =  num_people(hh)
    hr.hid = hh.hid
    hr.sequence = hh.sequence
    hr.weight = hh.weight
    hr.data_year = hh.data_year
    hr.weighted_people = hh.weight*nps
    hr.num_people = nps
    hr.hh_type = num_people( hh ) ## FIXME
    hr.tenure = hh.tenure
    hr.region = hh.region
    hr.decile = -1
    hr.income_taxes = isum(hres.income, INCOME_TAXES )
    hr.means_tested_benefits = isum( hres.income, MEANS_TESTED_BENS )
    hr.other_benefits = isum( hres.income, NON_MEANS_TESTED_BENS )
    hr.bhc_net_income = hres.bhc_net_income
    hr.ahc_net_income = hres.ahc_net_income
    # hr.eq_scale = hres.eq_scale
    hr.eq_bhc_net_income = hres.eq_bhc_net_income
    hr.eq_ahc_net_income = hres.eq_ahc_net_income
    hr.indirect_taxes = total( hres.indirect )
    hr.num_children = num_children( hh )
end


function fill_bu_frame_row!(
    br :: DataFrameRow,
    hh :: Household,
    bres :: BenefitUnitResult )

    # ...

end

"""
return decile and poverty state for the income contain in the row
"""
function get_decile_and_poverty_state( 
    settings :: Settings, 
    hr :: DataFrameRow, 
    poverty_line :: Real,
    decs :: Vector ) :: Tuple
    isym = income_measure_as_sym( settings.ineq_income_measure )
    inc = hr[isym]
    in_poverty = inc <= poverty_line
    for i in 1:10
        if inc <= decs[i]
            return (i, in_poverty)
        end
    end
    return (10,in_poverty) # FIXME temp hack for something wrong with deciles for LA Western Isles
    @assert false "Decile for $inc hid $(hr.hid) is out-of-range. inc = $inc deciles=$(decs)"
end

"""
Add a decile and in-poverty marker to each hh and personal record.
"""
function fill_in_deciles_and_poverty!( 
    frames :: NamedTuple, 
    settings :: Settings, 
    poverty_lines :: Vector,
    deciles :: Vector )
    ns = size( frames.indiv )[1] # num systems        
    for sysno in 1:ns
        decs = deciles[sysno][:,3]
        hh = frames.hh[sysno]
        nhh = size(hh)[1]
        indiv = frames.indiv[sysno]
        income = frames.income[sysno]
        poverty_line = poverty_lines[sysno]
        bu = frames.bu[sysno]
        for hno in 1:nhh
            onehh = hh[hno,:]
            if onehh.hid > 0 # e.g. skip NI
                # println( "onehh.hid $(onehh.hid)  onehh.data_year $(onehh.data_year)")
                (decile, in_poverty) = get_decile_and_poverty_state( 
                    settings, onehh, poverty_line, decs )
                onehh.in_poverty = in_poverty
                onehh.decile = decile
                onehh.in_poverty = in_poverty
                # faster than matching hid 
                pseqs = get_people_slots_for_household( onehh.hid, onehh.data_year )
                @assert length(pseqs) > 0
                for pseq in pseqs 
                    # indiv[indiv.hid .== onehh.hid,:]
                    pers = indiv[pseq,:]
                    @assert (pers.hid == onehh.hid) && (pers.data_year == onehh.data_year)
                    pers.in_poverty = in_poverty
                    pers.decile = decile
                    pers.eq_bhc_net_income = onehh.eq_bhc_net_income
                    pers.eq_ahc_net_income = onehh.eq_ahc_net_income
                end
            end # not ni, etc.
        end
    end
end

function summarise_inc_frame( incd :: DataFrame ) :: DataFrame
    nrows = 80
    out = make_incomes_frame(Float64, nrows)
    out.label = fill("",nrows)
    
    # labels
    out[1,:label]="Grant Total £p.a"
    out[2,:label]="Counts"
    row = 3
    for em in instances( ILO_Employment )
        out[row,:label]="$em - £p.a"
        row += 1
        out[row,:label]="$em - counts"
        row += 1
    end
    for em in instances( Tenure_Type )
        out[row,:label]="$em - £p.a"
        row += 1
        out[row,:label]="$em - counts"
        row += 1
    end
    for a in 1:17
        em = age_str(a)
        out[row,:label]="$em - £p.a"
        row += 1
        out[row,:label]="$em - counts"
        row += 1
    end

    col = 3
    # FIXME is there something subtly wrong with the weighting here?
    for i in 1:(INC_ARRAY_SIZE+EXTRA_INC_COLS)
        col += 1
        # println( "on column $col")
        out[1,col] = sum( WEEKS_PER_YEAR .* incd[:,col] .* incd[:,:weight] ) # £mn 
        out[2,col] = sum((incd[:,col] .> 0) .* incd[:,:weight]) # counts
        row = 3
        for em in instances( ILO_Employment )
            selected = incd.employment_status.==em
            out[row,col] = sum( WEEKS_PER_YEAR .* incd[selected,col] .* incd[selected,:weight] ) # £mn          
            row += 1
            out[row,col] = sum((incd[selected,col] .> 0) .* incd[selected,:weight]) # Counts
            row += 1
        end
        for em in instances( Tenure_Type )
            selected = incd.tenure .== em
            out[row,col] =sum(  WEEKS_PER_YEAR .* incd[selected,col] .* incd[selected,:weight] ) # £mn          
            row += 1                
            out[row,col] = sum((incd[selected,col] .> 0) .* incd[selected,:weight]) # Counts
            row += 1
        end
        for a in 1:17
            selected = incd.age_band .== a
            out[row,col] = sum( WEEKS_PER_YEAR .* incd[selected,col] .* incd[selected,:weight] ) # £mn          
            row += 1
            out[row,col] = sum((incd[selected,col] .> 0) .* incd[selected,:weight]) # Counts
            row += 1
        end                
    end    
    # note that the Count field for the next two is meaningless
    out.total_indirect = out.VED + out.fuel_duty + out.VAT + out.excise_beer + out.excise_cider + out.excise_wine + 
        out.excise_tobacco
    out.net_inc_indirect = out.net_cost - out.total_indirect # 
    select!(out, Not([:pid,:hid,:weight])) # clear out pids 
    return out
end

function fill_inc_frame_row!( 
    ir :: DataFrameRow, 
    hh :: Household,
    pers :: Person,
    pres :: IndividualResult,
    from_child_record :: Bool )
    # println( names(ir))
    STBIncomes.fill_inc_frame_row!( 
        ir, pers.pid, hh.hid, hh.weight, pres.income )
    # some aggregate income fields    
    # ir.income_tax -=  pres.it.pension_relief_at_source   
    ir.employers_ni = pres.ni.class_1_secondary
    
    ## FIXME the pension_relief thing might not be quite right
    ir.scottish_income_tax = pres.it.non_savings_tax # - pres.it.pension_relief_at_source

    ir.total_benefits = isum( pres.income, BENEFITS ) 
    ir.legacy_mtbs  = isum( pres.income, LEGACY_MTBS )
    ir.means_tested_bens = isum( pres.income, MEANS_TESTED_BENS )
    ir.non_means_tested_bens  = isum( pres.income, NON_MEANS_TESTED_BENS )
    ir.sickness_illness = isum( pres.income, SICKNESS_ILLNESS )
    ir.scottish_benefits = isum( pres.income, SCOTTISH_BENEFITS )
    ir.pension_relief_at_source = pres.it.pension_relief_at_source
    


    ir.tenure = hh.tenure
    ir.data_year = hh.data_year
    ir.region = hh.region
    ir.decile = -1
    ir.council = hh.council
    ir.employment_status = pers.employment_status
    ir.age_band = age_range( pers.age )
    ir.is_child = from_child_record
    ir.employers_ni = pres.ni.class_1_secondary
    ir.net_cost = isum( pres.income, NET_COST ) + ir.pension_relief_at_source
    
end

function fill_pers_frame_row!(
    pr :: DataFrameRow,
    hh :: Household,
    pers :: Person,
    pres :: IndividualResult,
    from_child_record :: Bool )
    pr.hid = hh.hid
    pr.pid = pers.pid
    pr.data_year = hh.data_year
    pr.weight = hh.weight
    pr.sex = pers.sex
    pr.age_band  = age_range( pers.age )
    pr.employment_status = pers.employment_status
    pr.ethnic_group = pers.ethnic_group
    pr.is_child = from_child_record

    pr.income_taxes = isum( pres.income, INCOME_TAXES)
    pr.means_tested_benefits = isum( pres.income, MEANS_TESTED_BENS )
    pr.other_benefits = isum( pres.income, NON_MEANS_TESTED_BENS )

    pr.income_tax = pres.income[INCOME_TAX]
    pr.it_non_savings = pres.it.non_savings_tax
    pr.it_savings = pres.it.savings_tax
    pr.it_dividends = pres.it.dividends_tax
    pr.it_pension_relief_at_source = pres.it.pension_relief_at_source

    pr.ni_above_lower_earnings_limit = pres.ni.above_lower_earnings_limit
    pr.ni_total_ni = pres.income[NATIONAL_INSURANCE]
    pr.ni_class_1_primary = pres.ni.class_1_primary
    pr.ni_class_1_secondary = pres.ni.class_1_secondary
    pr.ni_class_2  = pres.ni.class_2
    pr.ni_class_3  = pres.ni.class_3
    pr.ni_class_4  = pres.ni.class_4
    pr.assumed_gross_wage = pres.ni.assumed_gross_wage
    if pres.metr != -12345.0 # missing indicator
        pr.metr = pres.metr
    end
    pr.replacement_rate = pres.replacement_rate        
end

#
# fill the rows in the output dataframes for this hhld
#
function add_to_frames!(
    settings :: Settings,
    frames :: NamedTuple,
    hh     :: Household,
    hres   :: HouseholdResult,
    sysno  :: Integer,
    num_systems :: Integer  )
    hfno = get_slot_for_household( hh.hid, hh.data_year )
    #=
    if hh.hid < 20
        println( "adding hh $(hh.hid) sysno=$sysno")
    end
    =#
    fill_hh_frame_row!( 
        frames.hh[sysno][hfno, :], hh, hres)
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
            #=
            if hh.hid < 0
                println( "pid=$pid data_year=$(hh.data_year) pfno=$pfno sysno=$sysno")
            end
            =#
            @assert pfno > 0 "pfno non-positive for pid=$pid data_year=$(hh.data_year) pfno=$pnfo"
            # pfbu += 1
            from_child_record = pid in bus[buno].children
            incrow = frames.income[sysno][pfno,:]
            fill_pers_frame_row!(
                frames.indiv[sysno][pfno,:],
                hh,
                pers,
                hres.bus[buno].pers[pid],
                from_child_record )
            fill_inc_frame_row!(
                incrow,
                hh,
                pers,
                hres.bus[buno].pers[pid],
                from_child_record )
            if pers.is_hrp # record VAT etc. once per hh
                incrow.VED = hres.indirect.VED 
                incrow.fuel_duty = hres.indirect.fuel_duty
                incrow.VAT = hres.indirect.VAT
                incrow.excise_beer = hres.indirect.excise_beer
                incrow.excise_cider = hres.indirect.excise_cider
                incrow.excise_wine = hres.indirect.excise_wine
                incrow.excise_tobacco = hres.indirect.excise_tobacco        
            end
        end # person loop
    end # bu loop

    @assert np == npp "not all people allocated; actual people=$np allocated people $npp"
    if settings.do_legal_aid
        LegalAidOutput.add_to_frames!( frames.legalaid, settings, hh, hres, sysno )
    end
end

"""
got to be a better way...
"""
function income_measure_as_sym( i :: IneqIncomeMeasure)::Symbol
    return if i == bhc_net_income
        :bhc_net_income
    elseif i == ahc_net_income
        :ahc_net_income
    elseif i == eq_ahc_net_income
        :eq_ahc_net_income
    elseif i == eq_bhc_net_income
        :eq_bhc_net_income
    end   
end

function eq_income_measure( i :: IneqIncomeMeasure )
    return i in [bhc_net_income, eq_bhc_net_income ] ? eq_bhc_net_income : eq_ahc_net_income
end

"""
fixme: convert to array 0.4,0.6,0.8 ... deep std near ...
"""
function make_poverty_line( hhs :: DataFrame, settings :: Settings ) :: Real
    income = income_measure_as_sym( settings.ineq_income_measure )
    deciles = PovertyAndInequalityMeasures.binify( hhs, 10, :weighted_people, income )
    return deciles[5,3]*0.6
end

const GL_COLNAMES = [
    "Lose £10.01+",
    "Lose £1.01-£10",
    "No Change",
    "Gain £1.01-£10",
    "Gain £10.01+"
] 

function gl( vf :: Number ) :: String
    v = round(vf; digits=2)
    return if v <= -10.01
        GL_COLNAMES[1]
    elseif v <= -1.01
        GL_COLNAMES[2]
    elseif v >= 10.01
        GL_COLNAMES[5]
    elseif v >= 1.01
        GL_COLNAMES[4]
    else
        GL_COLNAMES[3]
    end
end

function one_gain_losesz( size :: Int ) :: DataFrame
    d = DataFrame()
    d.Name = [] 
    n = 0
    for i in 1:n
        push!(d.Name,i)
    end
    for c in GL_COLNAMES
        d[:,Symbol(c)] = zeros(n)
    end
    d.Total = zeros(n)
    d
end

function one_gain_lose_df( T :: Type ) :: DataFrame
    d = DataFrame()
    d.Name = [] 
    n = 0
    for i in instances(T)
        push!( d.Name, i )
        n += 1
    end
    for c in GL_COLNAMES
        d[:,Symbol(c)] = zeros(n)
    end
    d.Total = zeros(n)
    d
end

"""
NOT USED
"""
function make_gain_lose_static( 
    prehh :: DataFrame, 
    posthh :: DataFrame, 
    incomes_col :: Symbol ) :: NamedTuple
    ten_gl = one_gain_lose_df( Tenure_Type )
    children_gl = one_gain_losez( 10 )

    @assert size( prehh ) == size( posthh )
    nrs = size( prehh )[1]
    for i in 1:nrs
        ten = prehh[i,:tenure]
        nkids = prehh[i,:num_children]
        gain = posthh[i, incomes_col] - prehh[i,incomes_col]
        changecol = Symbol( gl( gain ))
        ten_gl[ten .== ten_gl.name,changecol] .= prehh.weighted_people
        ten_gl[ten .== ten_gl.name].Total .= prehh.weighted_people
        children_gl[nkids .== children_gl.name,changecol] .= prehh.weighted_people
        children_gl[nkids .== children_gl.name].Total .= prehh.weighted_people

    end
    #=
    ten_gl = one_gain_lose_df( :tenure )
    dec_gl = one_gain_lose_df( :decile )
    children_gl = one_gain_lose_df( 7 )
    hhtype_gl = one_gain_lose_df( dhh, :hh_type )
    =#   
    (; ten_gl, children_gl )
end
"""
Convoluted approach to making an IFS style Gain-Lose table
@param dhh - a little frame with a bunch of categories and a net-income field (change)
@param col - which of the symbols to build a gl table from.
@return gl table as a dataframe.
"""
function one_gain_lose( dhh :: DataFrame, col :: Symbol ) :: DataFrame
    # add a column of strings - "Lose over £10" and so on - from the 'change' column
    dhh.gainlose = gl.(dhh.change)
    # group by some column (decile, tenure, etc) and then 
    ghh = combine(groupby( dhh, [col,:gainlose] ),(:weighted_people=>sum))
    colnames = [String(col), GL_COLNAMES...]
    vhh = unstack( ghh, :gainlose, :weighted_people_sum )
    n = size( vhh )[1]
    missn = setdiff( colnames, names(vhh))
    for m in missn
        vhh[:,m] = zeros(n)
    end
    ns = Symbol.(colnames)
    select!( sort!(vhh, col), ns... )
    # average change table, grouped by col 
    gavch = combine( groupby( dhh, [col]),
        (:people_weighted_change=>sum), # changes in selected income var * hhweight * people count
        (:weighted_people=>sum), # hh weight * people count
        (:weight=>sum),          # sum of hh weights
        (:weighted_bhc_change=>sum ))     # sum of bhc changes 
    gavch.avch = gavch.people_weighted_change_sum ./ gavch.weighted_people_sum # => average change for each group per person
    gavch.total_transfer = WEEKS_PER_YEAR.*gavch.weighted_bhc_change_sum./1_000_000 # total moved to/from that group £spa
    # ... put av changes in the right order
    sort!( gavch, col )
    vhh.avch = gavch.avch
    vhh.total_transfer = gavch.total_transfer
    # remove missing: Do we need this?
    glf = coalesce.( vhh, 0.0)
    # add an average change column
    return glf
end

@enum PctDirection by_row by_col by_totals
export PctDirection, by_row, by_col, by_totals

function to_percentages( table :: DataFrame, direction :: PctDirection ) :: DataFrame

end

const GL_MIN = 0.10
const MAX_EXAMPLES = 50

function make_gain_lose( 
    prehh :: DataFrame, 
    posthh :: DataFrame, 
    incomes_col :: Symbol ) :: NamedTuple

    dhh = DataFrame( 
        hid = prehh.hid,
        data_year  = prehh.data_year,
        weighted_people = prehh.weighted_people,
        weight = prehh.weight,
        weighted_bhc_change = prehh.weight.*(posthh.bhc_net_income - prehh.bhc_net_income),
        tenure = prehh.tenure, 
        region = prehh.region,
        decile = prehh.decile,
        hh_type = prehh.hh_type,
        num_children = Int.(prehh.num_children),            
        in_poverty = prehh.in_poverty,
        change = posthh[:, incomes_col] - prehh[:,incomes_col])
    dhh.people_weighted_change = (dhh.change .* dhh.weighted_people) # for average gains 
    ten_gl = one_gain_lose( dhh, :tenure )
    dec_gl = one_gain_lose( dhh, :decile )
    children_gl = one_gain_lose( dhh, :num_children )
    hhtype_gl = one_gain_lose( dhh, :hh_type )
    reg_gl = one_gain_lose( dhh, :region )
    # FIXME this is vvv problematic
    poverty_gl = one_gain_lose( dhh, :in_poverty )
    # some overall changes - easier way?
    gainers = sum( dhh[dhh.change .> GL_MIN, :weighted_people] )
    losers = sum( dhh[dhh.change .< -GL_MIN, :weighted_people] )
    # sample gain/lose
    ex_gainers = Array{OneIndex}(undef,MAX_EXAMPLES)
    n_gainers = 0
    ex_losers = Array{OneIndex}(undef,MAX_EXAMPLES)
    n_losers = 0
    ex_ncs  = Array{OneIndex}(undef,MAX_EXAMPLES)
    n_ncs = 0
    for i in eachrow( dhh )
        if (i.change > GL_MIN) && (n_gainers < MAX_EXAMPLES)
            n_gainers += 1
            ex_gainers[n_gainers] = OneIndex( i.hid, i.data_year ) 
        elseif (i.change < -GL_MIN) && (n_losers < MAX_EXAMPLES)
            n_losers += 1
            ex_losers[n_losers] = OneIndex( i.hid, i.data_year ) 
        elseif ( -GL_MIN <= i.change <= GL_MIN ) && (n_ncs < MAX_EXAMPLES )
            n_ncs += 1
            ex_ncs[n_ncs] = OneIndex( i.hid, i.data_year ) 
        end
    end

    popn = sum( dhh.weighted_people )
    nc = popn - gainers - losers
    return (;
        ten_gl, 
        dec_gl,
        children_gl,
        hhtype_gl,    
        reg_gl, # careful for Scotland only        
        ex_gainers=ex_gainers[1:n_gainers], 
        ex_losers=ex_losers[1:n_losers],
        ex_ncs=ex_ncs[1:n_ncs], 
        gainers=gainers, 
        losers=losers,
        nc=nc, 
        popn = popn)
end

function make_gain_lose( post :: DataFrame, pre :: DataFrame, settings :: Settings )::NamedTuple
    income = income_measure_as_sym( settings.ineq_income_measure )
    return make_gain_lose( post, pre, income )
end

function metrs_to_hist( indiv :: DataFrame ) :: NamedTuple
    # these 2 convoluted lines make this draw only
    # over the non-missing (children, retired)
    p = collect(keys(skipmissing( indiv.metr )))
    indp = indiv[p,[:metr, :weight]] # just non missing
    # so .. <=0, >0 <=10, >10<=20 and so on
    # skip near-infinite mrs mwhen averaging
    mmtr = mean( indp[(indp.metr.<150),:].metr, Weights(indp[(indp.metr.<150),:].weight))
    hist = fit( Histogram, indp.metr, Weights( indp.weight ), [-Inf, 0.00001, 10.0, 20.0, 30.0, 50.0, 80.0, 100.0, Inf], closed=:right )
    return ( mean=mmtr, hist=hist)
end

"""
Overall summary table made from summary.income_summary tables, with 1 being the base.
Transpose the 1st three rows of these table. Assumes there's a col `label` at the end
and that the totals are in the 1st 3 rows. This will break badly
if the format of the income_summary tables changes.
"""
function make_short_cost_summary( income_summaries :: Vector )::DataFrame 
    cost_summaries = []
    # There's an `id` field right after the data rows, so...
    last_data_row = findfirst(x->x=="id",names(income_summaries[1]))-1 # label is a col at the end.        
    i = 0
    for s in income_summaries # round each income table
        i+=1
        # Take 1st 3 cols of the 1st transposed matrix, inc labels, and just 2:3 (with the numbers) for the subsequent ones.
        start_col = i == 1 ? 1 : 2 
        summary = permutedims(s,:label,makeunique=true)[1:last_data_row,start_col:3]
        # 1st number col is money amounts in £s pa
        summary[!,end-1] ./= 1_000_000 # costs in £m
        # .. second is counts.
        summary[!,end] ./= 1_000 # counts in 000s
        push!(cost_summaries, summary)
    end
    # Make into one big dataframe.
    costsummary = hcat( cost_summaries..., makeunique=true )
    # Make labels on LHS look nice.
    costsummary[!,1] = pretty.(costsummary[!,1])
    costsummary
end

"""
Make the main summary tables from a set of results dataframes.
"""
function summarise_frames!( 
    frames :: NamedTuple,
    settings :: Settings;
    do_gain_lose :: Bool = true ) :: NamedTuple
    ns = size( frames.indiv )[1] # num systems
    income_summary = []
    gain_lose = []
    poverty = []
    inequality = []
    deciles = []
    quantiles = []
    metrs = []
    poverty_lines = []
    child_poverty = [] 
    income_measure = income_measure_as_sym( settings.ineq_income_measure )
    poverty_line = if settings.poverty_line_source == pl_from_settings
        settings.poverty_line
    elseif settings.poverty_line_source == pl_first_sys
        make_poverty_line( frames.hh[1], settings )
    else
        -1.0 # make sure we crash if not set
    end

    for sysno in 1:ns
        # poverty relative to current system median
        if settings.poverty_line_source == pl_current_sys
            poverty_line = make_poverty_line( frames.hh[sysno], settings )
        end
        push!( metrs, metrs_to_hist( frames.indiv[sysno] ))
        println( "metrs to hist done")
        push!(income_summary, 
            summarise_inc_frame(frames.income[sysno]))
        println( "income summary")
        push!( deciles, 
            PovertyAndInequalityMeasures.binify( 
                frames.hh[sysno], 
                10, 
                :weighted_people, 
                income_measure ))
        println( "deciles")
        push!( quantiles, 
            PovertyAndInequalityMeasures.binify( 
                frames.hh[sysno], 
                50, 
                :weighted_people, 
                income_measure  ))
        println( "quantiles")
            
        ineq = make_inequality(
            frames.hh[sysno], 
            :weighted_people, 
            income_measure  )
        push!( inequality, ineq )
        println( "inequality")
        push!(  
            poverty,
            PovertyAndInequalityMeasures.make_poverty( 
                frames.hh[sysno], 
                poverty_line, 
                settings.growth, 
                :weighted_people, 
                income_measure ))
        println( "poverty")
        push!( poverty_lines, poverty_line )
        cp = calc_child_poverty( 
            poverty_line, 
            frames.hh[sysno],
            measure=income_measure
        )
        println( "child poverty")
        push!( child_poverty, cp )
    end   
    @time fill_in_deciles_and_poverty!(
        frames, 
        settings, 
        poverty_lines,
        deciles )
    println( "fill in deciles and poverty")
    if do_gain_lose
        for sysno in 1:ns 
            push!( gain_lose,
                make_gain_lose( 
                    frames.hh[1], # FIXME add setting for comparison system
                    frames.hh[sysno],
                    income_measure )) 
        end
        println( "gain lose")
    end    
    if settings.do_legal_aid
        # note we're now always reseting these propensities
        # since some base assumptions might change e.g. capital modelling.
        # FIXME this is not thread-safe
        LegalAidOutput.create_propensities( frames.legalaid; reset_results = true  )
        LegalAidOutput.summarise_la_output!( settings, frames.legalaid )
    end
    short_income_summary = make_short_cost_summary( income_summary )
    return ( ;
        quantiles, 
        deciles, 
        income_summary, 
        poverty, 
        inequality, 
        metrs, 
        child_poverty,
        gain_lose,
        poverty_lines,
        short_income_summary,
        legalaid = frames.legalaid )
end


function fm(v, r,c) 
    return if c == 1
        v
    elseif c < 7
        Format.format(v, precision=0, commas=true)
    else
        Format.format(v, precision=2, commas=true)
    end
    s
end

"""

"""
function format_gainlose(io::IOStream, title::String, gl::DataFrame)
    gl[!,1] = pretty.(gl[!,1])
    pretty_table(io, gl[!,1:end-1]; 
        backend = Val(:markdown),
        formatters=fm,alignment=[:l,fill(:r,6)...],
        title = title,
        header=["",
            "Lose £10.01+",
            "Lose £1.01-£10",
            "No Change",
            "Gain £1.01-£10",
            "Gain £10.01+",
            "Av. Change"])
end

"""
Write everything from the summaries into a directory
constructed from the settings output filename and the run name.
Writes CSV for the income summaries and quantiles and markdown for the rest.
"""
function dump_summaries( settings :: Settings, summary :: NamedTuple )
    ns = length( summary.income_summary ) # num systems
    outdir = joinpath( settings.output_dir, basiccensor( settings.run_name )) 
    mkpath( outdir )
    open(joinpath( outdir, "index.md"), "w") do lio
        println( lio, DUMP_FILE_DESCRIPTION )
    end
    fname = joinpath( outdir, "short_income_summary.tab")
    CSV.write( fname, summary.short_income_summary; delim='\t' )
    fname = joinpath( outdir, "poverty-inequality-metrs-child-poverty.md")
    io = open( fname, "w")
    for fno in 1:ns
        fname = joinpath( outdir, "quantiles_$(fno).tab")
        CSV.write(fname, DataFrame(summary.quantiles[fno],
            [:population_share,:income_share,:income_threshold,:average_income]); delim='\t' )
        fname = joinpath( outdir, "income_summary_$(fno).tab")
        CSV.write(fname, summary.income_summary[fno]; delim='\t' )

        println(io, "## Inequality Sys#$(fno)")
        println(io,to_md_table(summary.inequality[fno]))
        println(io, "## Poverty Sys#$(fno)")
        println(io,to_md_table(summary.poverty[fno]))

        println(io, "## METRs Histogram Sys#$(fno)")
        println(io, summary.metrs[fno])
        println(io, "## Child Poverty Sys#$(fno)")
        println(io, to_md_table(summary.child_poverty[fno]))
        println(io, "## Poverty Line#$(fno)")
        println(io, summary.poverty_lines[fno])
        # gain lose in 1 big file FIXME improve formatting
        fname = joinpath( outdir, "gainlose_$(fno).md")
        open( fname, "w") do gl_io 
            println( "Gain-Lose Tables: system $(fno) vs system 1\n")
            println( gl_io, "## Tenure\n\n")
            format_gainlose( gl_io, "Tenure", summary.gain_lose[fno].ten_gl)
            println( gl_io, "## Deciles\n\n")
            format_gainlose( gl_io, "Deciles", summary.gain_lose[fno].dec_gl)
            println( gl_io, "## Children\n\n")
            format_gainlose( gl_io, "Num Children", summary.gain_lose[fno].children_gl)
            println( gl_io, "## HH Type\n\n")
            format_gainlose( gl_io, "Household Type", summary.gain_lose[fno].hhtype_gl)
            println( gl_io, "## Region\n\n")
            format_gainlose( gl_io, "Region", summary.gain_lose[fno].reg_gl)
        end
    end
    close(io)
    if settings.do_legal_aid
        LegalAidOutput.dump_tables( summary.legalaid, settings; num_systems=nc )            
    end
end

"""
Dump the raw dataframes to a directory make from settings.output dir and the run name.
"""
function dump_frames(
    settings :: Settings,
    frames :: NamedTuple;
    append :: Bool = false )
    ns = size( frames.indiv )[1] # num systems
    outdir = joinpath( settings.output_dir, basiccensor( settings.run_name )) 
    mkpath( outdir )
    for fno in 1:ns
        fname = joinpath( outdir, "hh_$(fno).tab")
        CSV.write( fname, frames.hh[fno] ; append=append, delim='\t')
        fname = joinpath( outdir, "bu_$(fno).tab")
        CSV.write( fname, frames.bu[fno]; append=append, delim='\t' )
        fname = joinpath( outdir, "indiv_$(fno).tab")
        CSV.write( fname, frames.indiv[fno];append=append, delim='\t' )
        fname = joinpath( outdir, "income_$(fno).tab")
        CSV.write( fname, frames.income[fno]; append=append, delim='\t' )
    end
end

end # Module STBOutput