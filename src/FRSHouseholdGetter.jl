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
        OneIndex,
        uprate!

    using .HouseholdFromFrame: 
        load_hhld_from_frame

    using .RunSettings: Settings

    using .Weighting: 
        generate_weights

    using .Uprating: load_prices

    export 
        initialise, 
        get_household, 
        num_households, 
        get_household_of_person
    
    ## See scripts/performance/hhld_example.jl for the rationalle behind this wrapper
    # 
    # If you're using a getter to get hhlds, wrap the array of hhlds in a struct, 
    # so you can give the
    # array a type and declare a constant. This aviods type instability which can murder 
    # performance of the getter.
    #
    struct HHWrapper 
        hhlds      :: Vector{Household{Float64}}
        weight     :: Vector{Float64}   
        dimensions :: Vector{Int}  
        hh_map     :: Dict{OneIndex,Int}   
        pers_map   :: Dict{OneIndex,Int}
    end
    
    const MODEL_HOUSEHOLDS = 
        HHWrapper(
            Vector{Household{Float64}}(undef, 0 ), 
            zeros(Float64,0),
            zeros(Int,3),
            Dict{OneIndex,Int}(),
            Dict{OneIndex,Int}())
    
    """
    Initialise the dataset. If this has already been done, do nothing unless 
    `reset` is true.
    return (number of households available, num people loaded inc. kids, num hhls in dataset (should always = item[1]))
    """
    function initialise(
            settings :: Settings;            
            reset :: Bool = false ) :: Tuple
    
        global MODEL_HOUSEHOLDS
        nhh = size( MODEL_HOUSEHOLDS.hhlds )[1]
        if( nhh > 0 ) && ( ! reset )
            # weird syntax to make tuple from array; 
            # see e.g. https://discourse.julialang.org/t/array-to-tuple/9024
            return (MODEL_HOUSEHOLDS.dimensions...,) 
        end
        load_prices( settings )
        hh_dataset = CSV.File("$(MODEL_DATA_DIR)/$(settings.household_name).tab" ) |> DataFrame
        people_dataset = CSV.File("$(MODEL_DATA_DIR)/$(settings.people_name).tab") |> DataFrame
        npeople = size( people_dataset)[1]
        nhhlds = size( hh_dataset )[1]
        resize!( MODEL_HOUSEHOLDS.hhlds, nhhlds )
        resize!( MODEL_HOUSEHOLDS.weight, nhhlds )
        MODEL_HOUSEHOLDS.weight .= 0
        
        for hseq in 1:nhhlds
            hh = load_hhld_from_frame( hseq, hh_dataset[hseq,:], people_dataset, FRS, settings )
            MODEL_HOUSEHOLDS.hhlds[hseq] = hh
            uprate!( hh )
            MODEL_HOUSEHOLDS.hh_map[OneIndex( hh.hid, hh.data_year )] = hseq
            for pid in keys(hh.people)
                MODEL_HOUSEHOLDS.pers_map[OneIndex( pid, hh.data_year )] = hseq
            end
        end
        # println( "made pers_map as $(MODEL_HOUSEHOLDS.pers_map)")
        @time weight = generate_weights( nhhlds)
        for i in eachindex( weight )
            MODEL_HOUSEHOLDS.weight[i] = weight[i]
        end
        MODEL_HOUSEHOLDS.dimensions.=
            size(MODEL_HOUSEHOLDS.hhlds)[1],
            npeople,
            nhhlds
        return (MODEL_HOUSEHOLDS.dimensions...,)
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
        return get_household( pos )
    end
    
    function get_num_households()::Integer
        return size( MODEL_HOUSEHOLDS.hhlds )[1]
    end

end # module
