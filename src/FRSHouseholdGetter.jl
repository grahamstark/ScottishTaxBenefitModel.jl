module FRSHouseholdGetter

    using CSV
    using DataFrames: DataFrame
    
    using ScottishTaxBenefitModel
    
    using .Definitions
    
    using .ModelHousehold: 
        Household, 
        uprate!

    using .HouseholdFromFrame: 
        load_hhld_from_frame

    using .Weighting: 
        generate_weights
    
    export initialise, get_household, num_households
    
    ## See scripts/performance/hhld_example.jl for the rationalle behind this wrapper
    # 
    # If you're using a getter to get hhlds, wrap the array of hhlds in a struct, 
    # so you can give the
    # array a type and declare a constant. This aviods type instability which can murder 
    # performance of the getter.
    #
    struct HHWrapper 
        hhlds  :: Vector{Household{Float64}}
        weight :: Vector{Float64}   
        dimensions :: Vector{Int}     
    end
    
    const MODEL_HOUSEHOLDS = 
        HHWrapper(Vector{Household{Float64}}(undef, 0 ), zeros(Float64,0),zeros(Int,3))
    
    """
    Initialise the dataset. If this has already been done, do nothing unless 
    `reset` is true.
    return (number of households available, num people loaded inc. kids, num hhls in dataset (should always = item[1]))
    """
    function initialise(
            ;
            household_name :: String = "model_households_scotland",
            people_name :: String = "model_people_scotland",
            start_year = -1,
            reset :: Bool = false ) :: Tuple
    
        global MODEL_HOUSEHOLDS
        nhh = size( MODEL_HOUSEHOLDS.hhlds )[1]
        if( nhh > 0 ) && ( ! reset )
            # weird syntax to make tuple from array; 
            # see e.g. https://discourse.julialang.org/t/array-to-tuple/9024
            return (MODEL_HOUSEHOLDS.dimensions...,) 
        end
        hh_dataset = CSV.File("$(MODEL_DATA_DIR)/$(household_name).tab" ) |> DataFrame
        people_dataset = CSV.File("$(MODEL_DATA_DIR)/$(people_name).tab") |> DataFrame
        npeople = size( people_dataset)[1]
        nhhlds = size( hh_dataset )[1]
        resize!( MODEL_HOUSEHOLDS.hhlds, nhhlds )
        resize!( MODEL_HOUSEHOLDS.weight, nhhlds )
        MODEL_HOUSEHOLDS.weight .= 0
        
        for hseq in 1:nhhlds
            MODEL_HOUSEHOLDS.hhlds[hseq] = load_hhld_from_frame( hseq, hh_dataset[hseq,:], people_dataset, FRS )
            uprate!( MODEL_HOUSEHOLDS.hhlds[hseq] )
        end
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
    
    function get_num_households()::Integer
        return size( MODEL_HOUSEHOLDS.hhlds )[1]
    end

end # module
