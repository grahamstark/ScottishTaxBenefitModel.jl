module FRSHouseholdGetter
    
    #
    # This module retrieves the main dataset. The data is retrieved from CSV files and assembled once, including generating sample weights,
    # but it can then be accessed multiple times in a session. Retrieval is currently by index (1,2,3...) only but retrieval by sernum/datayear,
    # or by some sort of query interface might be added later.
    # 

    using CSV
    using DataFrames: DataFrame
    
    using ScottishTaxBenefitModel
    
    using .Definitions
    
    using .ModelHousehold: 
        Household, 
        uprate!

    using .HouseholdFromFrame: 
        create_regression_dataframe,
        load_hhld_from_frame

    using .RunSettings: Settings

    using .Weighting: 
        generate_weights

    using .Uprating: load_prices

    export 
        initialise, 
        get_household, 
        num_households, 
        get_household_of_person,
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

    struct HHWrapper 
        hhlds      :: Vector{Household{Float64}}
        weight     :: Vector{Float64}   
        dimensions :: Vector{Int}  
        hh_map     :: Dict{OneIndex,HHPeople}   
        pers_map   :: Dict{OneIndex,OnePos}
    end
    
    const MODEL_HOUSEHOLDS = 
        HHWrapper(
            Vector{Household{Float64}}(undef, 0 ), 
            zeros(Float64,0),
            zeros(Int,3),
            Dict{OneIndex,HHPeople}(),
            Dict{OneIndex,Int}())
    
    mutable struct RegWrapper # I don't understand why I need 'mutable' here, but..
        data :: DataFrame
    end

    # fixme I don't see how to make this a constant 
    REG_DATA :: DataFrame = DataFrame()
    
    """
    Initialise the dataset. If this has already been done, do nothing unless 
    `reset` is true.
    return (number of households available, num people loaded inc. kids, num hhls in dataset (should always = item[1]))
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
        hh_dataset = CSV.File("$(settings.data_dir)/$(settings.household_name).tab" ) |> DataFrame
        people_dataset = CSV.File("$(settings.data_dir)/$(settings.people_name).tab") |> DataFrame
        npeople = size( people_dataset)[1]
        nhhlds = size( hh_dataset )[1]
        resize!( MODEL_HOUSEHOLDS.hhlds, nhhlds )
        resize!( MODEL_HOUSEHOLDS.weight, nhhlds )
        MODEL_HOUSEHOLDS.weight .= 0
        
        pseq = 0
        for hseq in 1:nhhlds
            hh = load_hhld_from_frame( hseq, hh_dataset[hseq,:], people_dataset, FRS, settings )
            MODEL_HOUSEHOLDS.hhlds[hseq] = hh
            uprate!( hh )
            pseqs = []
            for pid in keys(hh.people)
                pseq += 1
                push!( pseqs, pseq )
                MODEL_HOUSEHOLDS.pers_map[OneIndex( pid, hh.data_year )] = OnePos(hseq,pseq)
            end
            MODEL_HOUSEHOLDS.hh_map[OneIndex( hh.hid, hh.data_year )] = HHPeople( hseq, pseqs)
            
        end
        # default weighting using current Scotland settings; otherwise do manually
        if settings.auto_weight && settings.target_nation == N_Scotland
            @time weight = generate_weights( 
                nhhlds;
                weight_type = settings.weight_type,
                lower_multiple = settings.lower_multiple,
                upper_multiple = settings.upper_multiple )
            for i in eachindex( weight ) # just assign weight = weight?
                MODEL_HOUSEHOLDS.weight[i] = weight[i]
            end
        else
            for hseq in 1:nhhlds # just assign weight = weight?
                MODEL_HOUSEHOLDS.weight[hseq] = MODEL_HOUSEHOLDS.hhlds[hseq].weight
            end
        end
        MODEL_HOUSEHOLDS.dimensions.=
            size(MODEL_HOUSEHOLDS.hhlds)[1],
            npeople,
            nhhlds

        REG_DATA = create_regression_dataframe( hh_dataset, people_dataset )

        return (MODEL_HOUSEHOLDS.dimensions...,)
    end

    function get_regression_dataset()::DataFrame
        REG_DATA
    end

    function get_household( pos :: Integer ) :: Household
        hh = MODEL_HOUSEHOLDS.hhlds[pos]
        hh.weight = MODEL_HOUSEHOLDS.weight[pos]
        return hh
    end

    function get_household( hid :: BigInt, datayear :: Int ) :: Household
        pos :: Int = MODEL_HOUSEHOLDS.hh_map[ OneIndex( hid, datayear) ]
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

end # module
