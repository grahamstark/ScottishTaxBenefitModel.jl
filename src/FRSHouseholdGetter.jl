module FRSHouseholdGetter

    using CSV
    import DataFrames: DataFrame
    
    import ScottishTaxBenefitModel: ModelHousehold, Definitions, HouseholdFromFrame
    
    using .Definitions
    import .ModelHousehold: Household, uprate!
    import .HouseholdFromFrame: load_hhld_from_frame
    
    export initialise, get_household, num_households
    
    ## See scripts/performance/hhld_example.jl for the rationalle behind this wrapper
    # 
    # If you're using a getter to get hhlds, wrap the array of hhlds in a struct, 
    # so you can give the
    # array a type and declare a constant. This aviods type instability which can murder 
    # performance of the getter.
    #
    struct HHWrapper 
        hhlds :: Vector{Household{Float64}}
    end
    
    const MODEL_HOUSEHOLDS = HHWrapper(Vector{Household{Float64}}(undef, 0 ))
    
    """
    return (number of households available, num people loaded inc. kids, num hhls in dataset (should always = item[1]))
    """
    function initialise(
            ;
            household_name :: String = "model_households",
            people_name :: String = "model_people",
            start_year = -1 ) :: Tuple
    
        global MODEL_HOUSEHOLDS
        hh_dataset = CSV.File("$(MODEL_DATA_DIR)/$(household_name).tab" ) |> DataFrame
        people_dataset = CSV.File("$(MODEL_DATA_DIR)/$(people_name).tab") |> DataFrame
        npeople = size( people_dataset)[1]
        nhhlds = size( hh_dataset )[1]
        resize!( MODEL_HOUSEHOLDS.hhlds, nhhlds )
        for hseq in 1:nhhlds
            MODEL_HOUSEHOLDS.hhlds[hseq] = load_hhld_from_frame( hseq, hh_dataset[hseq,:], people_dataset, FRS )
            uprate!( MODEL_HOUSEHOLDS.hhlds[hseq] )
        end
        (size(MODEL_HOUSEHOLDS.hhlds)[1],npeople,nhhlds)
    end
    
    function get_household( pos :: Integer ) :: Household
        MODEL_HOUSEHOLDS.hhlds[pos]
    end
    
    function get_num_households()::Integer
        return size( MODEL_HOUSEHOLDS.hhlds )[1]
    end

end # module
