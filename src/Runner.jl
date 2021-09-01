module Runner
    #
    # This model actually runs all the calculations over a collection of households and stores the results in dataframes.
    # Presently it also contains code to summarise the output dataframes. FIXME output needs to be in own module.
    #
    using Parameters: @with_kw
    using DataFrames: DataFrame, DataFrameRow, Not, select!
    using CSV

    using BudgetConstraints: BudgetConstraint

    using ScottishTaxBenefitModel:
        Definitions,
        Incomes,
        FRSHouseholdGetter,
        GeneralTaxComponents,
        ModelHousehold,
        Results,
        RunSettings,
        SingleHouseholdCalculations,
        STBParameters,
        Utils,
        Weighting

    using .Definitions
    using .Utils
    using .STBParameters
    using .Incomes

    using .RunSettings:
        Settings
    
    using .GeneralTaxComponents:
        WEEKS_PER_YEAR

    using .ModelHousehold: 
        Household, 
        Person, 
        get_benefit_units

    using .Results: 
        BenefitUnitResult,
        HouseholdResult,
        IndividualResult
        
    using .FRSHouseholdGetter: 
        get_household,
        initialise
        
    using .Uprating: load_prices
    
    using .SingleHouseholdCalculations: do_one_calc
    
    export 
        do_one_run!,
        summarise_inc_frame 

    # fixme move the output stuff (mostly) to an Output.jl module

    struct FrameStarts
        hh :: Integer
        bu :: Integer
        pers :: Integer
        income :: Integer
    end

    function make_household_results_frame( n :: Int ) :: DataFrame
        make_household_results_frame( Float64, n )
    end

    function make_household_results_frame( RT :: DataType, n :: Int ) :: DataFrame
        DataFrame(
            hid       = zeros( BigInt, n ),
            sequence  = zeros( Int, n ),
            weight    = zeros(RT,n),
            hh_type   = zeros( Int, n ),
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
            scottish_income_tax = zeros(RT,n)
        )
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

    function make_individual_results_frame( RT :: DataType, n :: Int ) :: DataFrame
       DataFrame(
         hid = zeros(BigInt,n),
         pid = zeros(BigInt,n),
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
         assumed_gross_wage = zeros(RT,n),

         benefit1 = zeros(RT,n),
         benefit2 = zeros(RT,n),
         basic_income = zeros(RT,n),
         gross_income = zeros(RT,n),
         net_income = zeros(RT,n),

         bhc_net_income = zeros(RT,n),
         ahc_net_income = zeros(RT,n),
         # eq_scale = zeros(RT,n),
         eq_bhc_net_income = zeros(RT,n),
         eq_ahc_net_income = zeros(RT,n), # etc.

         metr = zeros(RT,n),
         tax_credit = zeros(RT,n),
         vat = zeros(RT,n),
         other_indirect = zeros(RT,n),
         total_indirect = zeros(RT,n))
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
        hr.hid = hh.hid
        hr.sequence = hh.sequence
        hr.weight = hh.weight
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
        eq_bhc_net_income = hres.eq_bhc_net_income
        eq_ahc_net_income = hres.eq_ahc_net_income
    end


    function fill_bu_frame_row!(
        br :: DataFrameRow,
        hh :: Household,
        bres :: BenefitUnitResult )

        # ...

    end


    function summarise_inc_frame( incd :: DataFrame ) :: DataFrame
        nrows = 80
        out = create_incomes_dataframe(Float64, nrows)
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
        for i in 1:INC_ARRAY_SIZE
            col += 1
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

        Incomes.fill_inc_frame_row!( 
            ir, pers.pid, hh.hid, hh.weight, pres.income )
        ir.tenure = hh.tenure
        ir.data_year = hh.data_year
        ir.region = hh.region
        ir.gross_decile = -1
        ir.council = hh.council
        ir.employment_status = pers.employment_status
        ir.age_band = age_range( pers.age )
        ir.is_child = from_child_record
    end

    function fill_pers_frame_row!(
        pr :: DataFrameRow,
        hh :: Household,
        pers :: Person,
        pres :: IndividualResult,
        from_child_record :: Bool )
        pr.hid = hh.hid
        pr.pid = pers.pid
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

        # benefit1 = zeros(RT,n),
        # benefit2 = zeros(RT,n),
        # basic_income = zeros(RT,n),
        # gross_income = zeros(RT,n),
        # net_income = zeros(RT,n),
        #
        # bhc_net_income = zeros(RT,n),
        # ahc_net_income = zeros(RT,n),
        # eq_scale = -1.0
        # eq_bhc_net_income = zeros(RT,n),
        # eq_ahc_net_income = zeros(RT,n), # etc.
        #
        # metr = zeros(RT,n),
        # tax_credit = zeros(RT,n),
        # vat = zeros(RT,n),
        # other_indirect hres.bus[buno]= zeros(RT,n),
        # total_indirect = zeros(RT,n))
    end

    #
    # fill the rows in the output dataframes for this hhld
    # frame_starts holds 1 minus the start positions for his hhld
    # in the frames
    #
    function add_to_frames!(
        frames :: NamedTuple,
        hh     :: Household,
        hres   :: HouseholdResult,
        sysno  :: Integer,
        frame_starts :: FrameStarts,
        num_systems :: Integer  )

        hfno = frame_starts.hh+1
        fill_hh_frame_row!( frames.hh[sysno][hfno, :], hh, hres)
        bfno = frame_starts.bu
        pfno = frame_starts.pers
        nbus = length(hres.bus)
        np = length( hh.people )
        bus = get_benefit_units( hh )
        pfbu = 0
        for buno in 1:nbus
            bfno += 1
            fill_bu_frame_row!( frames.bu[sysno][bfno,:], hh, hres.bus[buno])
            for( pid, pers ) in bus[buno].people
                pfno += 1
                pfbu += 1
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
        # println( "num people $np num bus $nbus pfno $pfno")
        # if pfno <= 5
        #    println( frames.indiv[sysno][1:5,:] )
        # end
        @assert (pfno - frame_starts.pers) == np "mismatch (pfno $pfno - frame_starts.pers $(frame_starts.pers) != $np"
        @assert pfbu == np "mismatch (pfbu $pfbu != np $np"
        # send back an incremented set of positions only
        # once we've done the last system
        if sysno == num_systems
            return FrameStarts( hfno, bfno, pfno, pfno )
        else
            return frame_starts
        end
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

    function do_one_run!(
        settings :: Settings,
        params   :: Vector{TaxBenefitSystem{T}} ) :: NamedTuple where T # fixme simpler way of declaring this?
        num_systems = size( params )[1]
        println("start of do_one_run; params:")
        load_prices( settings, false )
        for p in 1:num_systems
            println("sys $p")
            println(params[p].it)
        end
        if settings.num_households == 0
            println( "getting households" )
            @time settings.num_households,
                settings.num_people,
                nhh2 = initialise(
                        household_name = settings.household_name,
                        people_name    = settings.people_name,
                        start_year     = settings.start_year )
        end
        frames :: NamedTuple = initialise_frames( T, settings, num_systems )
        frame_starts = FrameStarts(0,0,0,0)
        println( "starting run " )
        @time for hno in 1:settings.num_households
            hh = FRSHouseholdGetter.get_household( hno )
            if hno % 100 == 0
                println( "on household hno $hno hid=$(hh.hid) year=$(hh.interview_year)")
            end
            for sysno in 1:num_systems
                res = do_one_calc( hh, params[sysno] )
                frame_starts = add_to_frames!( frames, hh, res,  sysno, frame_starts, num_systems )
            end
        end #household loop
        println( "dumping frames" )
        dump_frames( settings, frames )
        return frames
    end # do one run

end # module