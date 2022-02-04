module STBOutput

using DataFrames: DataFrame, DataFrameRow, Not, select!

using PovertyAndInequalityMeasures

using CSV

using StatsBase
using ScottishTaxBenefitModel
using .Definitions
using .Utils
using .GeneralTaxComponents:
    WEEKS_PER_YEAR

using .Results: 
    BenefitUnitResult,
    HouseholdResult,
    IndividualResult

using .STBIncomes

using .ModelHousehold

using .FRSHouseholdGetter: 
    get_slot_for_household,
    get_slot_for_person
    
using .RunSettings

using .SimplePovertyCounts: 
    GroupPoverty,
    calc_child_poverty

export 
    add_to_frames!,
    dump_frames,
    initialise_frames,
    summarise_frames,
    make_poverty_line,
    make_gain_lose,
    hdiff,
    idiff,
    irdiff

# count of the aggregates added to the income_frame - total benefits and so on
const EXTRA_INC_COLS = 10


    #=
    struct FrameStarts
        hh :: Integer
        bu :: Integer
        pers :: Integer
        income :: Integer
    end
    =#

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
            gross_decile = zeros( Int, n ),
            bhc_net_income = zeros(RT,n),
            ahc_net_income = zeros(RT,n),
            # eq_scale = zeros(RT,n),
            eq_bhc_net_income = zeros(RT,n),
            eq_ahc_net_income = zeros(RT,n), # etc.
            income_taxes = zeros(RT,n),
            means_tested_benefits = zeros(RT,n),
            other_benefits = zeros(RT,n),
            scottish_income_tax = zeros(RT,n),
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
            gross_decile = zeros( Int, n ),
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
        frame.net_cost = zeros( n )
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
        frame.gross_decile = zeros( Int, n )
        frame.council = fill( Symbol( "No_Council"), n)

        # ... and so on
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

         income_taxes = zeros(RT,n),
         means_tested_benefits = zeros(RT,n),
         other_benefits = zeros(RT,n),

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
         replacement_rate = Vector{Union{Real,Missing}}(missing, n))
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
        for s in 1:num_systems
            push!(indiv, make_individual_results_frame( T, settings.num_people ))
            push!(bu, make_bu_results_frame( T, settings.num_people )) # overstates but we don't actually know this at the start
            push!(hh, make_household_results_frame( T, settings.num_households ))
            push!(income, make_incomes_frame( T, settings.num_people )) # overstates but we don't actually know this at the start            
        end
        (hh=hh, bu=bu, indiv=indiv, income=income)
    end

    function fill_hh_frame_row!( hr :: DataFrameRow, hh :: Household, hres :: HouseholdResult )
        nps =  num_people(hh)
        hr.hid = hh.hid
        hr.sequence = hh.sequence
        hr.weight = hh.weight
        hr.data_year = hh.data_year
        hr.weighted_people = hh.weight*nps
        hr.num_people = nps
        hr.hh_type = -1
        hr.tenure = hh.tenure
        hr.region = hh.region
        hr.gross_decile = -1
        hr.income_taxes = isum(hres.income, INCOME_TAXES )
        hr.means_tested_benefits = isum( hres.income, MEANS_TESTED_BENS )
        hr.other_benefits = isum( hres.income, NON_MEANS_TESTED_BENS )
        hr.bhc_net_income = hres.bhc_net_income
        hr.ahc_net_income = hres.ahc_net_income
        # hr.eq_scale = hres.eq_scale
        hr.eq_bhc_net_income = hres.eq_bhc_net_income
        hr.eq_ahc_net_income = hres.eq_ahc_net_income
        hr.num_children = num_children( hh )
    end


    function fill_bu_frame_row!(
        br :: DataFrameRow,
        hh :: Household,
        bres :: BenefitUnitResult )

        # ...

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
        select!(out, Not([:pid,:hid,:weight])) # clear out pids 
        return out
    end
 
    function fill_inc_frame_row!( 
        ir :: DataFrameRow, 
        hh :: Household,
        pers :: Person,
        pres :: IndividualResult,
        from_child_record :: Bool )

        STBIncomes.fill_inc_frame_row!( 
            ir, pers.pid, hh.hid, hh.weight, pres.income )
        # some aggregate income fields    
        ir.income_tax -=  pres.it.pension_relief_at_source   
        ir.employers_ni = pres.ni.class_1_secondary
        ir.scottish_income_tax = pres.it.non_savings_tax - pres.it.pension_relief_at_source
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
        ir.gross_decile = -1
        ir.council = hh.council
        ir.employment_status = pers.employment_status
        ir.age_band = age_range( pers.age )
        ir.is_child = from_child_record
        ir.employers_ni = pres.ni.class_1_secondary
        ir.net_cost = isum( pres.income, NET_COST ) - ir.pension_relief_at_source
        
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
        frames :: NamedTuple,
        hh     :: Household,
        hres   :: HouseholdResult,
        sysno  :: Integer,
        num_systems :: Integer  )

        
        hfno = get_slot_for_household( hh.hid, hh.data_year )
        fill_hh_frame_row!( 
            frames.hh[sysno][hfno, :], hh, hres)
        nbus = length(hres.bus)
        np = length( hh.people )
        bus = get_benefit_units( hh )
        pfbu = 0
        for buno in 1:nbus
            # this won't work at the moment & isn't used
            # fill_bu_frame_row!( frames.bu[sysno][bfno,:], hh, hres.bus[buno])
            for( pid, pers ) in bus[buno].people
                pfno = get_slot_for_person( pid, hh.data_year )
                # pfbu += 1
                from_child_record = pid in bus[buno].children
                fill_pers_frame_row!(
                    frames.indiv[sysno][pfno,:],
                    hh,
                    pers,
                    hres.bus[buno].pers[pid],
                    from_child_record )
                fill_inc_frame_row!(
                    frames.income[sysno][pfno,:],
                    hh,
                    pers,
                    hres.bus[buno].pers[pid],
                    from_child_record )
                    
            end # person loop
        end # bu loop
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

    function make_poverty_line( hhs :: DataFrame, settings :: Settings ) :: Real
        income = income_measure_as_sym( settings.ineq_income_measure )
        deciles = PovertyAndInequalityMeasures.binify( hhs, 10, :weighted_people, income )
        return deciles[5,3]*(2.0/3.0)
    end

    function make_gain_lose( post :: DataFrame, pre :: DataFrame, measure :: Symbol )::NamedTuple
        pre_inc = pre[:,measure]
        post_inc = post[:,measure]
        n = size(post_inc)[1]
        diff = zeros(n)
        # so check for 0 pre income
        for i in 1:n 
            if pre_inc[i] != 0
                diff[i] = (pre_inc[i]-post_inc[i])/pre_inc[i]
            end
        end
        # println( "diff=$diff n=$n")
        popn = sum(post[:,:weighted_people])
        gainers = (diff.>=0.01).*post[:,:weighted_people]
        sg = sum(gainers)
        losers = (diff.<= -0.01).*post[:,:weighted_people]
        sl = sum(losers)
        nc = (abs.(diff).< 0.01).*post[:,:weighted_people]
        sn = sum(nc)
        @assert sg+sl+sn ≈ popn "sg=$sg + sl=$sl + sn=$sn !≈ popn=$popn"
        return ( gainers=sg, losers=sl,nc=sn, popn = popn )
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

    function summarise_frames( 
        frames :: NamedTuple,
        settings :: Settings ) :: NamedTuple
        ns = size( frames.indiv )[1] # num systems
        income_summary = []
        gain_lose = []
        poverty = []
        inequality = []
        deciles = []
        quantiles = []
        metrs = []
        poverty_line = []
        child_poverty = []
        income_measure = income_measure_as_sym( settings.ineq_income_measure )

        for sysno in 1:ns
            push!( metrs, metrs_to_hist( frames.indiv[sysno] ))
            push!(income_summary, 
                summarise_inc_frame(frames.income[sysno]))
            push!( deciles, 
                PovertyAndInequalityMeasures.binify( 
                    frames.hh[sysno], 
                    10, 
                    :weighted_people, 
                    income_measure ))
            push!( quantiles, 
                PovertyAndInequalityMeasures.binify( 
                    frames.hh[sysno], 
                    50, 
                    :weighted_people, 
                    income_measure  ))
                
            ineq = make_inequality(
                frames.hh[sysno], 
                :weighted_people, 
                income_measure  )
            push!( inequality, ineq )
            push!(  
                poverty,
                PovertyAndInequalityMeasures.make_poverty( 
                    frames.hh[sysno], 
                    settings.poverty_line, 
                    settings.growth, 
                    :weighted_people, 
                    income_measure ))
            push!( poverty_line, settings.poverty_line )
            cp = calc_child_poverty( 
                settings.poverty_line, 
                frames.hh[sysno],
                measure=income_measure
            )
            push!( child_poverty, cp )
        end   
        return ( 
            quantiles=quantiles, 
            deciles = deciles, 
            income_summary = income_summary, 
            poverty=poverty, 
            inequality=inequality, 
            metrs = metrs, 
            child_poverty=child_poverty,
            poverty_line = settings.poverty_line )
    end

    ## FIXME eventually, move this to DrWatson
    function dump_frames(
        settings :: Settings,
        frames :: NamedTuple )
        ns = size( frames.indiv )[1] # num systems
        fbase = basiccensor(settings.run_name)
        mkpath(settings.output_dir)
        for fno in 1:ns
            fname = "$(settings.output_dir)/$(fbase)_$(fno)_hh.csv"
            CSV.write( fname, frames.hh[fno] )
            fname = "$(settings.output_dir)/$(fbase)_$(fno)_bu.csv"
            CSV.write( fname, frames.bu[fno] )
            fname = "$(settings.output_dir)/$(fbase)_$(fno)_pers.csv"
            CSV.write( fname, frames.indiv[fno] )
            fname = "$(settings.output_dir)/$(fbase)_$(fno)_income.csv"
            CSV.write( fname, frames.income[fno] )
            income_summary = summarise_inc_frame(frames.income[fno])
            fname = "$(settings.output_dir)/$(fbase)_$(fno)_income-summary.csv"
            CSV.write( fname, income_summary )

        end
    end

end # STBOutput
