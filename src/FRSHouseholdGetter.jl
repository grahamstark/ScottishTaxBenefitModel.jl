module FRSHouseholdGetter
    
    #
    # This module retrieves the main dataset. The data is retrieved from CSV files and assembled once, including generating sample weights,
    # but it can then be accessed multiple times in a session. Retrieval is currently by index (1,2,3...) only but retrieval by sernum/datayear,
    # or by some sort of query interface might be added later.
    # 

    using CSV
    using DataFrames: DataFrame, DataFrameRow, AbstractDataFrame
    using StatsBase
    using Parameters
    
    using ScottishTaxBenefitModel
    
    using .Definitions
    
    using .ModelHousehold: 
        Household,
        infer_house_price!,
        num_people, 
        uprate!

    using .HouseholdFromFrame: 
        create_regression_dataframe,
        load_hhld_from_frame

    using .RunSettings 

    using .Uprating: load_prices

    using .Utils:get_quantiles

    using .LegalAidData
    using .ConsumptionData
    using .WealthData
    using .WeightingData

    export 
        initialise, 
        get_data_years,
        get_household, 
        num_households, 
        not_in_skiplist,
        get_household_of_person,
        get_interview_years,
        get_regression_dataset, 
        get_people_slots_for_household,
        get_slot_for_person,
        get_slot_for_household
    
    ## See scripts/performance/hhld_example.jl for the rationalle behind this wrapper
    # 
    # If you're using a getter to get hhlds, wrap the array of hhlds in a struct, 
    # so you can give the
    # array a type and declare a constant. This aviods type instability which can murder 
    # performance of the getter.
    #

    struct OnePos
        hseq :: Int
        pseq :: Int
    end

    struct HHPeople
        hseq :: Int
        pseqs :: Vector{Int}
    end

    mutable struct HHWrapper 
        hhlds      :: Vector{Household{Float64}}
        # weight     :: Vector{Float64}   
        dimensions :: Vector{Int}  
        hh_map     :: Dict{OneIndex,HHPeople}   
        pers_map   :: Dict{OneIndex,OnePos}
        data_years :: Vector{Int}
        interview_years :: Vector{Int}
    end
    
    const MODEL_HOUSEHOLDS = 
        HHWrapper(
            Vector{Household{Float64}}(undef, 0 ), 
            # zeros(Float64,0),
            zeros(Int,3),
            Dict{OneIndex,HHPeople}(),
            Dict{OneIndex,Int}(),
            zeros(0),
            zeros(0))
    const BACKUP_HOUSEHOLDS = 
        HHWrapper(
            Vector{Household{Float64}}(undef, 0 ), 
            # zeros(Float64,0),
            zeros(Int,3),
            Dict{OneIndex,HHPeople}(),
            Dict{OneIndex,Int}(),
            zeros(0),
            zeros(0))

    function backup()
        #= BACKUP_HOUSEHOLDS.hhlds = similar( MODEL_HOUSEHOLDS.hhlds )
        if length( BACKUP_HOUSEHOLDS.hhlds ) == 0
            for i in eachindex( MODEL_HOUSEHOLDS.hhlds )
                push!(BACKUP_HOUSEHOLDS.hhlds, deepcopy( MODEL_HOUSEHOLDS.hhlds[i]))
            end
        else
            for i in eachindex( MODEL_HOUSEHOLDS.hhlds )
                BACKUP_HOUSEHOLDS.hhlds[i] =  deepcopy( MODEL_HOUSEHOLDS.hhlds[i])
            end
        end
        =#
        BACKUP_HOUSEHOLDS.hhlds = deepcopy(MODEL_HOUSEHOLDS.hhlds)
        BACKUP_HOUSEHOLDS.dimensions = deepcopy( MODEL_HOUSEHOLDS.dimensions )
        BACKUP_HOUSEHOLDS.hh_map     = deepcopy( MODEL_HOUSEHOLDS.hh_map     )
        BACKUP_HOUSEHOLDS.pers_map   = deepcopy( MODEL_HOUSEHOLDS.pers_map   )
        BACKUP_HOUSEHOLDS.data_years = deepcopy( MODEL_HOUSEHOLDS.data_years )
        BACKUP_HOUSEHOLDS.interview_years = deepcopy( MODEL_HOUSEHOLDS.interview_years )
    end

    function restore()
        #=
        for i in eachindex( BACKUP_HOUSEHOLDS.hhlds )
            MODEL_HOUSEHOLDS.hhlds[i] = deepcopy( BACKUP_HOUSEHOLDS.hhlds[i])
        end
        =#
        MODEL_HOUSEHOLDS.hhlds      = deepcopy( BACKUP_HOUSEHOLDS.hhlds )
        MODEL_HOUSEHOLDS.dimensions = deepcopy( BACKUP_HOUSEHOLDS.dimensions )
        MODEL_HOUSEHOLDS.hh_map     = deepcopy( BACKUP_HOUSEHOLDS.hh_map )
        MODEL_HOUSEHOLDS.pers_map   = deepcopy( BACKUP_HOUSEHOLDS.pers_map )
        MODEL_HOUSEHOLDS.data_years = deepcopy( BACKUP_HOUSEHOLDS.data_years )
        MODEL_HOUSEHOLDS.interview_years = deepcopy( BACKUP_HOUSEHOLDS.interview_years )
    end
        
    mutable struct RegWrapper # I don't understand why I need 'mutable' here, but..
        data :: DataFrame
    end

    function get_skiplist( settings :: Settings )::DataFrame 
        df = DataFrame( hid=zeros(BigInt,0), data_year=zeros(Int,0), reason=fill("",0))
        if settings.skiplist != ""
            fname = main_datasets( settings ).skiplist
            df = CSV.File( fname )|>DataFrame
        end
        return df
    end

    """
    Insert into data a pair of basic deciles in the hh data based on actual pre-model income and eq scale
    """
    function fill_in_deciles!(settings::Settings)
        nhhs = MODEL_HOUSEHOLDS.dimensions[1]
        inc = zeros(nhhs)
        eqinc = zeros(nhhs)
        w = zeros(nhhs)
        for hno in 1:nhhs
            hh = get_household(hno)
            inc[hno] = hh.original_gross_income
            eqinc[hno] = hh.original_gross_income / hh.equivalence_scales.oecd_bhc 
            w[hno] = hh.weight*num_people(hh) # person level deciles
        end
        # HACK HACK HACK - need to add gross inc to Scottish subset and uprate it
        if sum( inc ) ≈ 0
            return
        end
        wt = Weights(w)
        # FIXME duplication here
        incbreaks = quantile(inc,wt,[0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9])
        incdecs = get_quantiles( inc, incbreaks )
        eqbreaks = quantile(eqinc,wt,[0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9])
        eqdecs = get_quantiles( eqinc, eqbreaks )
        for hno in 1:nhhs
            hh = get_household(hno)
            hh.original_income_decile = incdecs[hno]
            hh.equiv_original_income_decile = eqdecs[hno]
        end
        # idiot check - 10 deciles each roughtly the same
        deccheck = zeros(10)
        for hno in 1:nhhs   
            hh = get_household(hno)        
            dec = hh.original_income_decile
            @assert dec in 1:10
            deccheck[dec] += hh.weight*num_people(hh) 
        end
        # popns can be quite a bit off whem weighting to a locality
        for i in 1:10
            println( "$i : $(deccheck[i])" )
        end
        rtol = if settings.do_local_run 
            0.1
        else
            0.03
        end
        for dc in deccheck
            prop = dc/deccheck[1]
            @assert isapprox( prop, 1, rtol=rtol ) "Counts in Deciles seem very uneven: prop vs [1]=$(prop) abs diff $(dc - deccheck[1])."
        end 
    end

    # fixme I don't see how to make this a constant 
    REG_DATA :: DataFrame = DataFrame()

    """
    This hh not in skiplist
    """
    function not_in_skiplist( hr :: DataFrameRow, skiplist :: DataFrame )::Bool
        if size(skiplist)[1] == 0
            return true
        end 
        sk = skiplist[ (skiplist.data_year .== hr.data_year ) .&
                  (skiplist.hid .== hr.hid ),:]
        return size(sk)[1] == 0 # not in skiplist
    end


    @with_kw mutable struct PopAndWage
        popn=zeros(100_000) 
        wage=zeros(100_000)
        mean = 0.0
        median = 0.0
        ratio = 1.0
        sdev = 0.0
        n=0
    end

    function addone!( pw :: PopAndWage, wage::Real, weight::Real )
        pw.n += 1
        pw.popn[pw.n] = weight
        pw.wage[pw.n] = wage
    end

    function summarise!( pw :: PopAndWage; 
        sex :: Union{Sex,Nothing}, 
        is_ft :: Union{Bool,Nothing},
        ccode :: Symbol )
        if pw.n > 0
            pw.wage = pw.wage[1:pw.n]
            pw.popn = pw.popn[1:pw.n]
            pw.mean = mean( pw.wage, Weights(pw.popn))
            pw.median = median( pw.wage, Weights(pw.popn))
            pw.sdev = std( pw.wage, Weights(pw.popn))
            pw.wage = zeros(0)
            pw.popn = zeros(0)
            wd = WeightingData.get_earnings_data(; sex = sex, is_ft = is_ft, council=ccode )
            #@show pw.mean
            #@show wd.Mean
            if ! ismissing( wd.Mean )
                pw.ratio = wd.Mean/pw.mean
            end
            #@show pw.ratio            
        end
    end

    """
    Make dictionary of wages from the model to match to the LA NOMIS data from WeightingData.jl+
    and use this to adjust average wages to match the ratio between the two.
    """
    function create_earnings_ratios( 
        settings :: Settings )::Dict
        popns = Dict{String,PopAndWage}()
        for sex in [Male,Female,nothing]
            for is_ft in [true,false,nothing]
                key = WeightingData.make_wage_key(; sex=sex, is_ft=is_ft)
                popns[key] = PopAndWage()
            end
        end
        # @show settings.num_households
        for hno in 1:settings.num_households
            hh = get_household(hno)
            for (pid,ad) in hh.people
                # @show ad 
                if ad.employment_status in [Full_time_Employee,
                    Part_time_Employee]
                    key = WeightingData.make_wage_key(; sex=ad.sex, is_ft=ad.employment_status == Full_time_Employee )
                    addone!( popns[key], ad.income[wages], hh.weight )
                    allsexk = WeightingData.make_wage_key(; is_ft=ad.employment_status == Full_time_Employee )
                    addone!( popns[allsexk], ad.income[wages], hh.weight )
                    allk = WeightingData.make_wage_key(;  )
                    addone!( popns[allk], ad.income[wages], hh.weight )
                    # full time workers both sexes
                    allftk = WeightingData.make_wage_key(; sex = ad.sex )
                    addone!( popns[allftk], ad.income[wages], hh.weight )                    
                end
            end
        end        
        for sex in [Male,Female]
            for is_ft in [true,false]
                key = WeightingData.make_wage_key(; sex=sex, is_ft=is_ft)
                summarise!(popns[key]; sex = sex, is_ft = is_ft, ccode=settings.ccode )
                println( "summarising $key ")
            end
        end
        #=
        for hno in 1:settings.num_households
            hh = get_household(hno)
            for (pid,ad) in hh.people
                ratio = 1.0
                if ad.employment_status in [Full_time_Employee,
                    Full_time_Self_Employed]
                    key = WeightingData.make_wage_key(; sex=ad.sex, is_ft=true )
                    ratio = popns[key].ratio
                elseif ad.employment_status in [Part_time_Employee,
                    Part_time_Self_Employed]
                    key = WeightingData.make_wage_key(; sex=ad.sex, is_ft=false )
                    ratio = popns[key].ratio
                end
                if haskey( ad.income, wages )
                    # @show ad.income[wages]
                    # @show ratio
                    ad.income[ wages ] *= ratio
                end
                if haskey( ad.income, self_employment_income )
                    ad.income[ self_employment_income ] *= ratio
                end
            end
        end
        =#
        return popns
    end

    function set_local_weights_and_incomes!( settings::Settings; reset::Bool)
        for hno in eachindex(MODEL_HOUSEHOLDS.hhlds) 
            MODEL_HOUSEHOLDS.hhlds[hno].council = settings.ccode
            WeightingData.set_weight!( MODEL_HOUSEHOLDS.hhlds[hno], settings )
            WeightingData.update_local_incomes!( MODEL_HOUSEHOLDS.hhlds[hno], settings )
        end
        fill_in_deciles!(settings)
    end

    function create_local_income_ratios(settings::Settings; reset::Bool)::Dict
        for hno in eachindex(MODEL_HOUSEHOLDS.hhlds) 
            MODEL_HOUSEHOLDS.hhlds[hno].council = settings.ccode
            WeightingData.set_weight!( MODEL_HOUSEHOLDS.hhlds[hno], settings )
        end
        ratios = create_earnings_ratios( settings )
        return ratios
    end

    """
    Initialise the dataset. If this has already been done, do nothing unless 
    `reset` is true.
    return (number of households available, num people loaded inc. kids, num hhls in dataset (should always = item[1]), and a valuw
    that's nothing if not a local run, else the funny ratios dict)
    """
    function initialise(
            settings :: Settings;            
            reset :: Bool = false ) :: Tuple
    
        global MODEL_HOUSEHOLDS
        global REG_DATA 
        nhh = size( MODEL_HOUSEHOLDS.hhlds )[1]
        if( nhh > 0 ) && ( ! reset )
            # weird syntax to make tuple from array; 
            # see e.g. https://discourse.julialang.org/t/array-to-tuple/9024
            return (MODEL_HOUSEHOLDS.dimensions...,) 
        end
        load_prices( settings )
        if settings.indirect_method == matching 
            ConsumptionData.init( settings; reset = reset )
        end
        if settings.wealth_method == matching 
            WealthData.init( settings; reset = reset )
        end
        if settings.do_legal_aid
            LegalAidData.init( settings; reset = reset )
        end
        skiplist = get_skiplist( settings )
        ds = main_datasets( settings )
        dataset_artifact = get_data_artifact( settings )
        hh_dataset = HouseholdFromFrame.read_hh( 
            joinpath( dataset_artifact, "households.tab")) # CSV.File( ds.hhlds ) |> DataFrame
        people_dataset = HouseholdFromFrame.read_pers( 
            joinpath( dataset_artifact, "people.tab"))
        npeople = 0; # size( people_dataset)[1]
        nhhlds = size( hh_dataset )[1]
        resize!( MODEL_HOUSEHOLDS.hhlds, nhhlds )
        pseq = 0
        hseq = 0
        dseq = 0
        for hdata in eachrow( hh_dataset )            
            if not_in_skiplist( hdata, skiplist )
                hseq += 1
                hh = load_hhld_from_frame( dseq, hdata, people_dataset, settings )
                npeople += num_people(hh)
                MODEL_HOUSEHOLDS.hhlds[hseq] = hh
                if settings.wealth_method == matching 
                    WealthData.find_wealth_for_hh!( hh, settings, 1 ) # fixme allow 1 to vary somehow Lee Chung..
                end
                uprate!( hh, settings )
                if( settings.indirect_method == matching ) && (settings.do_indirect_tax_calculations)
                    ConsumptionData.find_consumption_for_hh!( hh, settings, 1 ) # fixme allow 1 to vary somehow Lee Chung..
                    if settings.impute_fields_from_consumption
                        ConsumptionData.impute_stuff_from_consumption!(hh,settings)
                    end
                end
                pseqs = []
                for pid in keys(hh.people)
                    pseq += 1
                    push!( pseqs, pseq )
                    MODEL_HOUSEHOLDS.pers_map[OneIndex( pid, hh.data_year )] = OnePos(hseq,pseq)
                end
                MODEL_HOUSEHOLDS.hh_map[OneIndex( hh.hid, hh.data_year )] = HHPeople( hseq, pseqs)
                if ! (hh.data_year in MODEL_HOUSEHOLDS.data_years )
                    push!( MODEL_HOUSEHOLDS.data_years, hh.data_year )
                end
                if settings.do_legal_aid
                    LegalAidData.add_la_probs!( hh )
                end
                if ! (hh.interview_year in MODEL_HOUSEHOLDS.interview_years )
                    push!( MODEL_HOUSEHOLDS.interview_years, hh.interview_year )
                end
                infer_house_price!( hh, settings )
            end # don't skip
        end
        resize!( MODEL_HOUSEHOLDS.hhlds, hseq )
        # resize!( MODEL_HOUSEHOLDS.weight, hseq )
        nhhlds = size( MODEL_HOUSEHOLDS.hhlds )[1]
        MODEL_HOUSEHOLDS.dimensions.=
            size(MODEL_HOUSEHOLDS.hhlds)[1],
            npeople,
            nhhlds
        REG_DATA = create_regression_dataframe( hh_dataset, people_dataset )
        # Save a copy of the dataset before we maybe mess with council weights
        WeightingData.init_national_weights( settings, reset=reset )
        for hno in eachindex(MODEL_HOUSEHOLDS.hhlds) 
            WeightingData.set_weight!( MODEL_HOUSEHOLDS.hhlds[hno], settings )
        end
        fill_in_deciles!(settings)
        backup()
        return (MODEL_HOUSEHOLDS.dimensions...,)
    end

    """
    Save some of the bits that are generated internally.
    FIXME: add an extract function
    """
    function extract_weights_and_deciles( 
        settings :: Settings,
        filename :: String  )
        fname = joinpath(settings.output_dir, "$(filename).tab" )
        f = open( fname, "w")
        println( f, "hid\tdata_year\tweight\tdecile")
        for hno in 1:settings.num_households
            hh = get_household(hno)
            println(f, hh.hid, '\t', hh.data_year, '\t', hh.weight, '\t', hh.equiv_original_income_decile)
        end
        close(f)
    end

    function get_regression_dataset()::DataFrame
        return REG_DATA
    end
    
    """
    A vector of the data years in the actual data e.g.2014,2020 ..
    """
    function get_data_years()::Vector{Integer}
        return MODEL_HOUSEHOLDS.data_years
    end

    """
    A vector of the interview years in the actual data e.g.2014,2020 ..
    """
    function get_interview_years()::Vector{Integer}
        return MODEL_HOUSEHOLDS.interview_years
    end

    function get_household( pos :: Integer ) :: Household
        hh = MODEL_HOUSEHOLDS.hhlds[pos]
        # hh.weight = MODEL_HOUSEHOLDS.weight[pos]
        return hh
    end

    function get_household( hid :: BigInt, datayear :: Int ) :: Household
        pos :: Int = MODEL_HOUSEHOLDS.hh_map[ OneIndex( hid, datayear) ].hseq
        return get_household( pos )
    end

    function get_household( oi :: OneIndex ) :: Household
        pos :: Int = MODEL_HOUSEHOLDS.hh_map[ oi ].hseq
        return get_household( pos )
    end

    function get_household_of_person( pid :: BigInt, datayear :: Int ) :: Union{Nothing,Household}
        pos = get( MODEL_HOUSEHOLDS.pers_map, OneIndex( pid, datayear), nothing )
        if pos === nothing
            return nothing
        end
        return get_household( pos.hseq )
    end

    function get_slot_for_household( hid :: BigInt, datayear :: Int  ) :: Int
        return MODEL_HOUSEHOLDS.hh_map[ OneIndex( hid, datayear) ].hseq
    end

    function get_people_slots_for_household( hid :: BigInt, datayear :: Int ) :: Vector{Int}
        return MODEL_HOUSEHOLDS.hh_map[ OneIndex( hid, datayear) ].pseqs
    end

    function get_slot_for_person( pid :: BigInt, datayear :: Int  ) :: Int
        return MODEL_HOUSEHOLDS.pers_map[ OneIndex( pid, datayear) ].pseq
    end
    
    function get_num_households()::Integer
        return size( MODEL_HOUSEHOLDS.hhlds )[1]
    end

    function get_num_people()::Integer
        return MODEL_HOUSEHOLDS.dimensions[2]
    end

end # module
