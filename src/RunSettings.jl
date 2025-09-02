module RunSettings
    #
    # This module contains things needed to control one run e.g. the output destination, number of households to use andd so on.
    #
    using Pkg
    using LazyArtifacts
    using LazyArtifacts
    using Parameters
    using Preferences 
    using UUIDs
    using SurveyDataWeighting

    using ScottishTaxBenefitModel
    using .Definitions
    using .Utils    


    export 
        Settings,
        MT_Routing,
        uc_full,
        lmt_full,
        modelled_phase_in,
        MT_ROUTING_STRS,

        IneqIncomeMeasure, 
        TargetBCIncomes,

        bhc_net_income,
        eq_bhc_net_income,
        ahc_net_income,
        eq_ahc_net_income,
        INEQ_INCOME_MEASURE_STRS,
        DataIncomeSource,
        ds_hbai,
        ds_frs,

        ahc_hh, 
        bhc_hh, 
        total_bens, 
        total_taxes,
        main_datasets,
        example_datasets,

        PovertyLineSource,
        pl_from_settings, 
        pl_first_sys,
        pl_current_sys,
        POVERTY_LINE_SOURCE_STRS,
        # DatasetType,
        # actual_data,
        # synthetic_data,
        WeightingStrategy, 
        use_supplied_weights, 
        use_precomputed_weights,
        use_runtime_computed_weights, 
        dont_use_weights, 
        WEIGHTING_STRATEGY_STRS,
        
        get_all_uk_settings_2023,
        get_data_artifact

        
    @enum TargetBCIncomes ahc_hh bhc_hh total_bens total_taxes
        
    @enum MT_Routing uc_full lmt_full modelled_phase_in
    const MT_ROUTING_STRS = Dict([
        uc_full=>"Universal Credit Fully Implemented",
        lmt_full=>"Everyone on Legacy Means Tested Benefits",
        modelled_phase_in => "Modelled Phase in of UC"
    ])

    @enum IneqIncomeMeasure bhc_net_income eq_bhc_net_income ahc_net_income eq_ahc_net_income
    
    const INEQ_INCOME_MEASURE_STRS = Dict([
        eq_bhc_net_income =>"Equivalised Before Housing Costs",
	    bhc_net_income => "Before Housing Costs",
	    ahc_net_income => "After Housing Costs",
	    eq_ahc_net_income => "Equivalised After Housing Costs"])
    #
    # Overwrite FRS wages and SE income with 'SPId' HBAI data.
    #
    @enum DataIncomeSource ds_hbai ds_frs 
    
    # An arbitrary poverty line supplied in the settings, 60% of the base sys median income, 60% of the current 
    # sys median income. `pl_current_sys` seems more correct to me, but it's unintuaitive.
    @enum PovertyLineSource pl_from_settings pl_first_sys pl_current_sys
    const POVERTY_LINE_SOURCE_STRS = Dict([
        pl_from_settings => "Pre-computed in Settings",
        pl_first_sys => "Computed as 60% AHC/BHC from 1st parameter system",
        pl_current_sys => "Computed seperately as 60% AHC/BHC from each parameter system"])

    @enum WeightingStrategy begin 
        use_supplied_weights = 1
        use_precomputed_weights = 2
        use_runtime_computed_weights = 3
        dont_use_weights = 4
    end
    const WEIGHTING_STRATEGY_STRS = Dict([
        use_supplied_weights => "Use ONS Suppied weights (DONT DO THIS!)",
        use_precomputed_weights => "Use Pre-computed weights (Only if using default years)",
        use_runtime_computed_weights => "Compute weights ar runtime",
        dont_use_weights => "Don't use weights; count all households as 1"])



    # @enum DatasetType actual_data synthetic_data # FIXME this duplicates `DataSource` in `.Definitions``
    
    # settings loaded automatically from the Project.toml section 'preferences.ScottishTaxBenefitModel' 
    # and maybe overwritten in LocalPreferences.toml
    # FIXME clear out all the duplications of Scotland in this
    @with_kw mutable struct Settings
        uuid :: UUID = UUID("c2ae9c83-d24a-431c-b04f-74662d2ba07e")
        uid :: Int = 1 # placeholder for maybe a user somewhere
        run_name = @load_preference( "default_run_name", "default_run" )
        scotland_full :: Bool = true
        weighting_strategy :: WeightingStrategy = eval( Symbol(@load_preference( "weighting_strategy", "use_precomputed_weights" )))
        target_nation :: Nation = eval(Symbol(@load_preference("target_nation", "N_Scotland"))) #  N_Scotland
        dump_frames :: Bool = @load_preference( "dump_frames", false )
        num_households :: Int = 0
        num_people :: Int = 0
        prices_file = @load_preference( "prices_file", "indexes.tab" )
        to_y :: Int = @load_preference( "to_y", 2024 )
        to_q :: Int = @load_preference( "to_q", 4 )
        output_dir :: String = joinpath(tempdir(),"output")
        means_tested_routing :: MT_Routing = eval( Symbol(@load_preference( "means_tested_routing", "uc_full" )))
        disability_routing :: MT_Routing = eval( Symbol(@load_preference( "disability_routing", "modelled_phase_in" )))
        poverty_line :: Real = -1.0
        poverty_line_source :: PovertyLineSource = eval( Symbol(@load_preference( "poverty_line_source", "pl_first_sys")))
        ineq_income_measure  :: IneqIncomeMeasure = eval( Symbol(@load_preference( "ineq_income_measure", "eq_bhc_net_income" )))
        growth :: Real = 0.02 # for time to exit poverty
        income_data_source :: DataIncomeSource = ds_frs # ds_hbai !! not used
        do_marginal_rates  :: Bool = @load_preference( "do_marginal_rates", false )
        do_replacement_rates :: Bool = @load_preference( "do_replacement_rates", false )
        replacement_rate_hours :: Int = @load_preference( "replacement_rate_hours", 30 )
        # We jam on age 68 here since we don't want changes to pension age
        # in the parameters to affect the numbers of people in
        # mr/rr calculations.
        mr_rr_upper_age :: Int = @load_preference("mr_rr_upper_age", 68 )
        target_bc_income :: TargetBCIncomes = eval(Symbol(@load_preference("target_bc_income", "ahc_hh" )))
        target_mr_rr_income :: TargetBCIncomes = eval(Symbol(@load_preference("target_mr_rr_income", "ahc_hh" )))
        mr_incr = @load_preference( "mr_incr", 0.001 )
        requested_threads = @load_preference( "requested_threads", 1 )
        impute_employer_pension  :: Bool = @load_preference( "impute_employer_pension", true )
        benefit_generosity_estimates_available :: Bool = @load_preference( "benefit_generosity_estimates_available", true )
 
        do_health_estimates :: Bool = @load_preference( "do_health_estimates", false )
        ## Elliot's email of June 21, 2023
        sf12_depression_limit = @load_preference( "sf12_depression_limit", 45.60)
        create_own_grossing :: Bool = @load_preference( "create_own_grossing", true) # ?? not needed?
        use_average_band_d :: Bool = @load_preference( "use_average_band_d", false)
        included_nations = @load_preference( "included_nations", [N_Scotland])
        impute_fields_from_consumption :: Bool = @load_preference( "impute_fields_from_consumption", true)
        
        indirect_method :: ExtraDataMethod = eval(Symbol(@load_preference( "indirect_method", matching )))
        wealth_method :: ExtraDataMethod = eval(Symbol(@load_preference( "wealth_method", matching )))
        
        use_shs :: Bool = @load_preference( "use_shs", true )
        do_indirect_tax_calculations :: Bool = @load_preference( "do_indirect_tax_calculations", false)
        
        # legal aid        
        do_legal_aid  :: Bool = @load_preference( "do_legal_aid", false )
        legal_aid_probs_data = @load_preference( "legal_aid_probs_data", "civil-legal-aid-probs-scotland-2017-2021")
        civil_payment_rate :: Real =  @load_preference( "civil_payment_rate", 1.0 )
        aa_payment_rate :: Real = @load_preference( "aa_payment_rate", 1.0 )

        export_full_results :: Bool = @load_preference( "export_full_results", false)
        do_dodgy_takeup_corrections :: Bool  = @load_preference( "do_dodgy_takeup_corrections", false)
        data_source :: DataSource = eval(Symbol(@load_preference( "data_source", FRSSource )))
        skiplist = @load_preference( "skiplist", "")
        do_local_run :: Bool  = @load_preference( "do_local_run", false )
        ccode :: Symbol = Symbol(@load_preference( "ccode", "" ))
        annual_rent_to_house_price_multiple = @load_preference( "annual_rent_to_house_price_multiple", 20.0 )
        included_data_years = @load_preference( "included_data_years", Int[] )
        legal_aid_costs_strategy :: LegalAidCostsStrategy = eval(Symbol(@load_preference( "legal_aid_costs_strategy", la_individual_costs )))
        #
        # weights
        #
        weight_type = eval(Symbol(@load_preference( "weight_type", "constrained_chi_square")))
        lower_multiple = @load_preference( "lower_multiple", 0.64 )
        upper_multiple = @load_preference( "upper_multiple", 5.9)
        include_institutional_population :: Bool  = @load_preference( "include_institutional_population", false )        
        weighting_target_year = @load_preference( "weighting_target_year", 2025 )
    end

    """
    The name, as an artifactString of the main dataset artifact e.g.
    'qualified_artifact( uk-frs-data ) and so on.
    """
    function get_data_artifact( settings::Settings )::AbstractString
        return if settings.data_source == FRSSource
            if settings.target_nation == N_Scotland
                qualified_artifact( "scottish-frs-data" )
            elseif settings.target_nation == N_UK
                qualified_artifact( "uk-frs-data" )
            end            
        elseif settings.data_source == ExampleSource
            qualified_artifact( "example_data" )
        elseif settings.data_source == SyntheticSource
            if settings.target_nation == N_Scotland
                qualified_artifact( "scottish-synthetic-data" )
            elseif settings.target_nation == N_UK
                qualified_artifact( "uk-synthetic-data" )
            end            
        end
    end

    function get_artifact(; name::String, source::String, scottish :: Bool )::AbstractString
        scuk = scottish ? "scottish" : "uk"
        # name = get_artifact_name( name )
        return qualified_artifact("$(scuk)-$(source)-$(name)")
    end

    function main_datasets( settings :: Settings ) :: NamedTuple
        artd = get_data_artifact( settings )
        return ( 
            hhlds = joinpath( artd, "households.tab" ),
            people = joinpath( artd, "people.tab" )
        )
    end

    """
    Hacky prebuilt settings for the Northumbria model.
    """
    function get_all_uk_settings_2023()::Settings
        settings = Settings()
        settings.target_nation :: Nation = N_UK
        settings.dump_frames :: Bool = false
        settings.num_households :: Int = 0
        settings.num_people :: Int = 0
        settings.prices_file = "indexes-july-2023.tab"
        settings.to_y :: Int = 2024
        settings.to_q :: Int = 3
        settings.weighting_strategy = use_supplied_weights
        settings.use_average_band_d = true
        settings.benefit_generosity_estimates_available = false
        settings.requested_threads = 4
        settings.impute_employer_pension = false
        settings.included_nations = [N_Scotland,N_England,N_Wales]
        settings.means_tested_routing = modelled_phase_in
        settings.use_shs = false        
        settings.indirect_method = matching
        settings.wealth_method = imputation
        settings.do_indirect_tax_calculations = true
        settings.do_legal_aid = false
        settings.legal_aid_probs_data = ""
        return settings
    end

end
