module STBOutput

using DataFrames
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
# Dump Directory Contents

* quantiles_1.csv - data for Lorenz curves and the deciles graph;
* quantiles_2.csv -
* income_summary_1.csv - aggregate incomes by income type, broken down by tenure, hh type, etc.;
* income_summary_2.csv -
* short_income_summary.csv - condensed version of the income data.
* poverty-inequality-metrs-child-poverty.md - rather hard to read dump of poverty, etc. tables in Markdown format;
* gain-lose-by-xxx-yy-vs-1.csv - Gainers and losers tables (breakdown=xxx, system=yy);
* incomes-histogram-yy.csv - histogram of income for system yy, plus means, median, max, min
* metrs-histogram-4.csv - likewise for Marginal Effective Tax Rates

## Other Tables

If present, these contain micro level data and are probably not needed by you:

* bu_1.csv -  Benefit Level
* bu_2.csv -
* hh_1.csv - Household Level
* hh_2.csv -
* income_1.csv - micro level detailed incomes data -
* income_2.csv -
* indiv_1.csv - micro level individual demographics
* indiv_2.csv -

### Note: 

* the `_2` (and upwards) indicates results for the changed systems; `_1` is the base;
* `.csv` extension indicated tab- delimited format (can be imported into spreadsheets);
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
        eq_scale_bhc = zeros(RT,n),
        eq_scale_ahc = zeros(RT,n),
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
        bhc_net_income = zeros(RT,n),
        ahc_net_income = zeros(RT,n),

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
    hr.eq_scale_bhc = hh.equivalence_scales.oecd_bhc
    hr.eq_scale_ahc = hh.equivalence_scales.oecd_ahc
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
    hres :: HouseholdResult,
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
    # hh level memo items
    pr.bhc_net_income = hres.bhc_net_income
    pr.ahc_net_income = hres.ahc_net_income
    # hr.eq_scale = hres.eq_scale
    pr.eq_bhc_net_income = hres.eq_bhc_net_income
    pr.eq_ahc_net_income = hres.eq_ahc_net_income

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
                hres,
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
        (:weighted_bhc_change=>sum ),
        (:weighted_pre_income=>sum ),
        (:weighted_post_income=>sum ))     # sum of bhc changes 
    gavch.avch = gavch.people_weighted_change_sum ./ gavch.weighted_people_sum # => average change for each group per person
    gavch.total_transfer = WEEKS_PER_YEAR.*gavch.weighted_bhc_change_sum./1_000_000 # total moved to/from that group £spa
    gavch.pct_change = 100.0 .* ((gavch.weighted_post_income_sum .- gavch.weighted_pre_income_sum)./gavch.weighted_pre_income_sum)
    # ... put av changes in the right order
    sort!( gavch, col )
    vhh.avch = gavch.avch
    vhh.pct_change = gavch.pct_change
    vhh.total_transfer = gavch.total_transfer
    # remove missing: Do we need this?
    glf = coalesce.( vhh, 0.0)
    # add an average change column
    colstr = pretty(string(col))
    metadata!( glf, "caption", "Table of Gainers and Losers by $colstr - Counts of Individuals."; style=:note)
    colmetadata!( glf, :pct_change,"label", "% Change In Income."; style=:note)
    colmetadata!( glf, :avch,"label", "Average Change In £s pw."; style=:note)
    colmetadata!( glf, :total_transfer,"label", "Total Transfer to/from this group."; style=:note)
    return glf
end

@enum PctDirection by_row by_col by_totals
export PctDirection, by_row, by_col, by_totals

"""
Generate 6x6 matrix of movements in and out of 
[ 0.3, 0.4, 0.6, 0.8, 1 ] x median income (plus tot r/c)
(using settings.ineq_income_measure).
"""
function make_povtrans_matrix( 
    indiv1::DataFrame,
    indiv2::DataFrame,
    settings :: Settings )::Matrix

    function pstate( m, povs )::Int
        i = 0
        for p in povs
            i += 1
            if m <= p
                return i
            end
        end
        return i+1
    end

    @assert size(indiv1) == size(indiv2)
    @assert indiv1.weight ≈ indiv1.weight
    nrows, ncols = size( indiv1 )
    trans = zeros(6,6)
    isym = income_measure_as_sym( settings.ineq_income_measure )
    inc1 = indiv1[!,isym]
    inc2 = indiv2[!,isym]
    med1 = median(inc1, Weights(indiv1.weight ))
    povs = med1 .* [ 0.3, 0.4, 0.6, 0.8 ]
    @show povs
    for r in 1:nrows
        weight = indiv1[r,:weight]
        p1 = pstate(inc1[r], povs)
        p2 = pstate(inc2[r], povs)
        trans[p1,p2] += weight
        trans[p1,6]+= weight
        trans[6,p2]+= weight
        trans[6,6]+= weight
    end
    return trans
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
        weighted_bhc_change = prehh.weight.*(posthh.bhc_net_income - prehh.bhc_net_income), # actual incomes change
        tenure = prehh.tenure, 
        region = prehh.region,
        decile = prehh.decile,
        hh_type = prehh.hh_type,
        num_children = Int.(prehh.num_children),            
        in_poverty = prehh.in_poverty,
        change = posthh[:, incomes_col] - prehh[:,incomes_col],
        pre_income = prehh[:,incomes_col],
        post_income = posthh[:,incomes_col],
        weighted_pre_income = prehh.weight.*prehh[:,incomes_col],
        weighted_post_income = prehh.weight.*posthh[:,incomes_col])
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

"""
Produce data for Metrs as a bar chart, plus mean, median
"""
function metrs_to_hist( indiv :: DataFrame ) :: NamedTuple
    # these 2 convoluted lines make this draw only
    # over the non-missing (children, retired)
    p = collect(keys(skipmissing( indiv.metr )))
    indp = indiv[p,[:metr, :weight]] # just non missing
    indp.metr = Float64.(indp.metr) # median doesn't like union{missing,..}
    # so .. <=0, >0 <=10, >10<=20 and so on
    # skip near-infinite mrs mwhen averaging
    maxmtr = maximum(indp.metr)
    minmtr = minimum(indp.metr)
    sensible = indp[(indp.metr.<150),:]
    if size(sensible)[1] > 0
        medmtr = median( sensible.metr, Weights(sensible.weight))
        meanmtr = mean( sensible.metr, Weights(sensible.weight))
        hist = fit( Histogram, indp.metr, Weights( indp.weight ), [-Inf, 0.0000, 10.0, 20.0, 30.0, 50.0, 80.0, 100.0, Inf], closed=:left )
    end
    return ( max=maxmtr, min=minmtr, median=medmtr, mean=meanmtr, hist=hist)
end

"""
Produce data for HBAI graph clone: hist in £10 blocks, median, truncated at [0,2000).
FIXME near dup of metrs_to_hist - just pass in ranges to common function? 
FIXME inconsistent call from the other summary tables.
minr and maxr are from HBAI diagram
"""
function incomes_to_hist( 
    hh :: DataFrame; 
    income_measure=:eq_bhc_net_income, 
    minr=0.0,
    maxr=1500.0,
    bandwidth=10 )::NamedTuple
    incs = deepcopy(hh[:,income_measure])
    # constrain the graph as in HBAI    
    incs = max.( incs, minr)
    incs = min.( incs, maxr)
    maxinc = maximum(incs)
    mininc = minimum(incs)
    medinc = median( incs, Weights(hh.weighted_people))
    meaninc = mean( incs, Weights(hh.weighted_people))
    @show medinc meaninc
    ranges = collect( minr:bandwidth:maxr )
    push!( ranges,Inf)
    hist = fit( Histogram, incs, Weights( hh.weighted_people ), ranges, closed=:left )
    # check I've understood fit(Hist correctly ..
    @assert hist.weights[1] ≈ sum( hh.weighted_people[ incs .< hist.edges[1][2] ]) "$(hist.weights[1]) ≈ $(sum( hh.weighted_people[ incs .<= minr ])) $hist"
    @assert hist.weights[end] ≈ sum( hh.weighted_people[ incs .>= maxr ]) "$(hist.weights[end]) ≈ $(sum( hh.weighted_people[ incs .>= maxr ])) $hist"
    return ( max=maxinc, min=mininc, median=medinc, mean=meaninc, hist=hist )
end

"""
Dump out histogram, means, etc. as 2-col delimited data. 
`incs` one of the named tuples created by `incomes_to_hist` or `metrs_to_hist`
"""
function write_hist( filename::String, incs::NamedTuple; delim='\t')
    d = DataFrame( 
        edges_upper_limit=incs.hist.edges[1][2:end], 
        population=incs.hist.weights )
    # add stats at bottom
    push!(d, ["mean", incs.mean]; promote=true ) # since col1 is float only otherwise
    push!(d, ["median", incs.median])
    push!(d, ["min", incs.min])
    push!(d, ["max", incs.max])
    CSV.write( filename, d; delim=delim )
end

"""
Overall summary table made from summary.income_summary tables, with 1 being the base.
Transpose the 1st three rows of that table. Assumes there's a col `label` at the end
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
    metadata!(costsummary, "caption", "Total Costs (£m pa) and Caseloads (1000s)")
    colmetadata!( costsummary, 1,"label", "Item",)
    colmetadata!( costsummary, 2,"label", "Before - £mn p.a.",)
    colmetadata!( costsummary, 3,"label", "Before - 000s",)
    colmetadata!( costsummary, 4,"label", "After - £mn p.a.",)
    colmetadata!( costsummary, 5,"label", "After - 000s",)
    costsummary
end

const V_SHORT_COST_ITEMS = pretty.([
    :income_tax,
    :national_insurance,
    :employers_ni,
    :scottish_income_tax,
    :total_benefits,
    :means_tested_bens,
    :universal_credit,
    :non_means_tested_bens,
    :sickness_illness,
    :scottish_benefits])
const V_SHORT_COST_LABELS = [
    "Total Income Tax",
    "Employee's National Insurance",
    "Employer's National Insurance",
    "Scottish Income Tax",
    "Total Benefit Spending",
    "All Means Tested Benefits",
    "Universal Credit",
    "Non Means Tested Benefits",
    "Disability, Sickness-Related Benefits",
    "Scottish Benefits" ]

"""
3 cols: pre, post, change
"""
function make_very_short_cost_summary( cost_summary :: DataFrame, cost_items, cost_labels )::DataFrame
    n = length(cost_items)
    d = DataFrame( item=cost_labels, pre=zeros(n), post=zeros(n), change=zeros(n))
    for i in 1:n
        p = cost_summary.label .== cost_items[i]
        row = cost_summary[p,:][1,:]
        d.pre[i] = row[2]
        d.post[i] = row[4]
        d.change[i] = d.post[i] - d.pre[i]
    end
    metadata!( d, "caption", "Total Costs (£m pa)")
    colmetadata!( d, 1,"label", "Item",)
    colmetadata!( d, 2,"label", "Before - £m pa",)
    colmetadata!( d, 3,"label", "After - £m pa",)
    return d
end

"""
return tuple with goodies. All raw numbers.
"""
function make_headline_figures( 
    income_summary1 :: DataFrame,
    income_summary2 :: DataFrame,
    inequality1 :: InequalityMeasures,
    inequality2 :: InequalityMeasures,
    poverty1 :: PovertyMeasures,
    poverty2 :: PovertyMeasures,
    gain_lose :: NamedTuple,
    income_hists1 :: NamedTuple,
    income_hists2 :: NamedTuple,
    metrs1 :: Union{Nothing,NamedTuple},
    metrs2 :: Union{Nothing,NamedTuple},
     )::NamedTuple
    r1 = income_summary1[1,:]
    r2 = income_summary2[1,:]
    net1 = r1.net_inc_indirect
    net2 = r2.net_inc_indirect
    ben1 = r1.total_benefits
    ben2 = r2.total_benefits
    tax1 = r1.income_tax+r1.national_insurance+r1.employers_ni
    tax2 = r2.income_tax+r2.national_insurance+r2.employers_ni
    palma1 = inequality1.palma
    palma2 = inequality2.palma
    gini1 = inequality1.gini
    gini2 = inequality2.gini
    pov_headcount1 = poverty1.foster_greer_thorndyke[1]
    pov_headcount2 = poverty2.foster_greer_thorndyke[1]
    median_income1 = income_hists1.median
    median_income2 = income_hists2.median
    mean_income1 = income_hists1.mean
    mean_income2 = income_hists2.mean
    median_metr1,
    median_metr2,
    mean_metr1,
    mean_metr2 = if isnothing( metrs1 )
        -1,-1,-1,-1
    else 
        metrs1.median,
        metrs2.median,
        metrs1.mean,
        metrs2.mean
    end
    Δtax = tax2 - tax1
    Δben = ben2 - ben1
    return (; 
        gainers = gain_lose.gainers,
        losers = gain_lose.losers,
        no_change = gain_lose.nc,
        median_metr1,
        median_metr2,
        Δmedian_metr = median_metr2 - median_metr1,
        mean_metr1,
        mean_metr2,
        Δmean_metr = mean_metr2 - mean_metr1,
        median_income1,
        median_income2,
        Δmedian_income = median_income2 - median_income1,
        mean_income1,
        mean_income2,
        Δmean_income = mean_income2 - mean_income1,        
        ben1,
        ben2,
        tax1, 
        tax2,
        palma1,
        palma2,
        gini1,
        gini2,
        pov_headcount1,
        pov_headcount2,
        Δtax,
        Δben,
        net_cost = net1 - net2, # note 1-2 here
        net_direct = Δtax - Δben, 
        Δpalma = palma2 - palma1,
        Δgini = gini2 - gini1,
        Δpov_headcount = pov_headcount2 - pov_headcount1 )
end

function decs_to_df( onedec :: Matrix )::DataFrame
    d = DataFrame( onedec, ["Cumulative Population","Cumulative Income","Income Break","Average Income"] )
    metadata!(d, "caption", "Cumulative Income/Populations Shares, Income Breaks and Averages")
    colmetadata!(d, 1,"label", "% Population",)
    colmetadata!(d, 2,"label", "% Income",)
    colmetadata!(d, 3,"label", "Income Break; £s pw",)
    colmetadata!(d, 4,"label", "Average Income; £s pw",)
    return d
end

function povtrans_matrix_to_df( pmat :: Matrix )::DataFrame
    labels = ["V.Deep (<=30%)",
                "Deep (<=40%)",
                "In Poverty (<=60%)",
                "Near Poverty (<=80%)",
                "Not in Poverty",
            "Total"]
    d = DataFrame( pmat, labels )
    insertcols!(d,1,:""=> labels )
    metadata!(d, "caption", "Movements in and out of poverty (counts of individuals) (Before in cols, after in rows).")
    return d
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
    income_hists = []
    povtrans_matrix = []
    povtrans_matrix_df = []
    headline_figures = []
    quantiles_df = []
    deciles_df = []
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
        if settings.do_marginal_rates
            push!( metrs, metrs_to_hist( frames.indiv[sysno] ))
            println( "metrs to hist done")
        end
        push!( income_hists, incomes_to_hist(
            frames.hh[sysno], 
            income_measure=income_measure ))
        push!(income_summary, 
            summarise_inc_frame(frames.income[sysno]))
        println( "income summary")
        onedec = PovertyAndInequalityMeasures.binify( 
                frames.hh[sysno], 
                10, 
                :weighted_people, 
                income_measure )
        onedecdf = decs_to_df(onedec)

        push!( deciles, 
            onedec )
        push!( deciles_df, 
            onedecdf )
        
        println( "deciles")
        onequant = PovertyAndInequalityMeasures.binify( 
                frames.hh[sysno], 
                50, 
                :weighted_people, 
                income_measure  )
        push!( quantiles, onequant )
        onequantdf = decs_to_df(onequant) 
        push!( quantiles_df, onequantdf )
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
        povtrans = make_povtrans_matrix(
            frames.indiv[1], 
            frames.indiv[sysno], 
            settings
        )
        povtrans_df = povtrans_matrix_to_df( povtrans )
        push!( povtrans_matrix, povtrans )
        push!( povtrans_matrix_df, povtrans_df )
    end   
    fill_in_deciles_and_poverty!(
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
    very_short_income_summary = make_very_short_cost_summary( 
        short_income_summary, V_SHORT_COST_ITEMS, V_SHORT_COST_LABELS )
    for sysno in 1:ns
        # check for uncomputed METRs 
        metrs1, metrs2 = if settings.do_marginal_rates
            metrs[1],
            metrs[sysno]
        else
            nothing, nothing
        end
        push!( headline_figures, make_headline_figures(
            income_summary[1],
            income_summary[sysno],
            inequality[1],
            inequality[sysno],
            poverty[1],
            poverty[sysno],
            gain_lose[sysno],
            income_hists[1],
            income_hists[sysno],
            metrs1,
            metrs2 ))
    end
    
    return ( ;
        headline_figures,
        quantiles, 
        quantiles_df, 
        deciles, 
        deciles_df,
        income_summary, 
        poverty, 
        inequality, 
        metrs, 
        child_poverty,
        gain_lose,
        poverty_lines,
        short_income_summary,
        very_short_income_summary,
        income_hists,
        povtrans_matrix,
        povtrans_matrix_df,
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
    fname = joinpath( outdir, "short_income_summary.csv")
    CSV.write( fname, summary.short_income_summary;delim=',' )
    fname = joinpath( outdir, "poverty-inequality-metrs-child-poverty.md")
    io = open( fname, "w")
    for fno in 1:ns
        fname = joinpath( outdir, "quantiles_$(fno).csv")
        CSV.write(fname, DataFrame(summary.quantiles[fno],
            [:population_share,:income_share,:income_threshold,:average_income]);delim=',' )
        fname = joinpath( outdir, "income_summary_$(fno).csv")
        CSV.write(fname, summary.income_summary[fno];delim=',' )

        println(io, "## Inequality Sys#$(fno)")
        println(io,to_md_table(summary.inequality[fno]))
        println(io, "## Poverty Sys#$(fno)")
        println(io,to_md_table(summary.poverty[fno]))
        println(io, "## Child Poverty Sys#$(fno)")
        println(io, to_md_table(summary.child_poverty[fno]))
        println(io, "## Poverty Line#$(fno)")
        println(io, summary.poverty_lines[fno])

        if fno > 1
            CSV.write( joinpath( outdir, "gain-lose-by-tenure-$(fno)-vs-1.csv"), summary.gain_lose[fno].ten_gl)
            CSV.write( joinpath( outdir, "gain-lose-by-deciles-$(fno)-vs-1.csv"), summary.gain_lose[fno].dec_gl)
            CSV.write( joinpath( outdir, "gain-lose-by-num-children-$(fno)-vs-1.csv"), summary.gain_lose[fno].children_gl)
            CSV.write( joinpath( outdir, "gain-lose-by-household Type-$(fno)-vs-1.csv"), summary.gain_lose[fno].hhtype_gl)
            CSV.write( joinpath( outdir, "gain-lose-by-region-\$(fno)-vs-1.csv"), summary.gain_lose[fno].reg_gl)
        end
        write_hist(joinpath( outdir, "incomes-histogram-$(fno).csv"), summary.income_hists[fno] )
        if settings.do_marginal_rates
            write_hist(joinpath( outdir, "metrs-histogram-$(fno).csv"), summary.metrs[fno] )
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
        fname = joinpath( outdir, "hh_$(fno).csv")
        CSV.write( fname, frames.hh[fno] ; append=append,delim=',')
        fname = joinpath( outdir, "bu_$(fno).csv")
        CSV.write( fname, frames.bu[fno]; append=append,delim=',' )
        fname = joinpath( outdir, "indiv_$(fno).csv")
        CSV.write( fname, frames.indiv[fno];append=append,delim=',' )
        fname = joinpath( outdir, "income_$(fno).csv")
        CSV.write( fname, frames.income[fno]; append=append,delim=',' )
    end
end

end # Module STBOutput