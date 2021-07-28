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
    end
    
    const MODEL_HOUSEHOLDS = HHWrapper(Vector{Household{Float64}}(undef, 0 ), zeros(Float64,0))
    
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
        # this `zeros` is needed because `generate_weights` below calls `get_household`
        # before the weights vector is created,
        # so we need to fill the weights vector(s) with something just
        # to prevent a bounds error. The zeros are ignored in `Weights`.
        MODEL_HOUSEHOLDS.weight = zeros( nhhlds )
        @time MODEL_HOUSEHOLDS.weight = generate_weights( nhhlds)

        (size(MODEL_HOUSEHOLDS.hhlds)[1],npeople,nhhlds)
    end
    
    function get_household( pos :: Integer ) :: Household
        hh = MODEL_HOUSEHOLDS.hhlds[pos]
        hh.weight = MODEL_HOUSEHOLDS.weight[pos]
    end
    
    function get_num_households()::Integer
        return size( MODEL_HOUSEHOLDS.hhlds )[1]
    end

end # module
