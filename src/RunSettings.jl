module RunSettings
    #
    # This module contains things needed to control one run e.g. the output destination, number of households to use andd so on.
    #
    using Pkg
    using Pkg.Artifacts
    using LazyArtifacts
    using Parameters
    using Preferences 
    using UUIDs
    using SurveyDataWeighting
    
    using ScottishTaxBenefitModel
    using .Definitions


    export 
        Settings,
        MT_Routing,
        uc_full,
        lmt_full,
        modelled_phase_in,

        IneqIncomeMeasure, 
        TargetBCIncomes,

        bhc_net_income,
        eq_bhc_net_income,
        ahc_net_income,
        eq_ahc_net_income,
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
        # DatasetType,
        # actual_data,
        # synthetic_data,
        
        get_all_uk_settings_2023,
        get_data_artifact
        
    @enum TargetBCIncomes ahc_hh bhc_hh total_bens total_taxes
        
    @enum MT_Routing uc_full lmt_full modelled_phase_in

    @enum IneqIncomeMeasure bhc_net_income eq_bhc_net_income ahc_net_income eq_ahc_net_income
    
    #
    # Overwrite FRS wages and SE income with 'SPId' HBAI data.
    #
    @enum DataIncomeSource ds_hbai ds_frs 

    # An arbitrary poverty line supplied in the settings, 60% of the base sys median income, 60% of the current 
    # sys median income. `pl_current_sys` seems more correct to me, but it's unintuaitive.
    @enum PovertyLineSource pl_from_settings pl_first_sys pl_current_sys

    export WeightingStrategy, use_supplied_weights, use_precomputed_weights,
        use_runtime_computed_weights, dont_use_weights
    @enum WeightingStrategy begin 
        use_supplied_weights = 1
        use_precomputed_weights = 2
        use_runtime_computed_weights = 3
        dont_use_weights = 4
    end
    #=
    mutable struct MiniSett
        prem :: LMTPremia
        dump_frames2 :: Bool
    end

    function default_minisett()::MiniSett
        prem2 = eval(Symbol(@load_preference("prem2"))) #  N_Scotland
        dump_frames2 = @load_preference( "dump_frames2")
        return MiniSett( prem2, dump_frames2 )
    end
    =#

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
        household_name = "model_households_scotland-2015-2021-w-enums-2"
        people_name  = "model_people_scotland-2015-2021-w-enums-2"
        target_nation :: Nation = eval(Symbol(@load_preference("target_nation", "N_Scotland"))) #  N_Scotland
        dump_frames :: Bool = @load_preference( "dump_frames", false )
        num_households :: Int = 0
        num_people :: Int = 0
        prices_file = @load_preference( "prices_file", "indexes.tab" )
        to_y :: Int = @load_preference( "to_y", 2024 )
        to_q :: Int = @load_preference( "to_q", 4 )
        output_dir :: String = joinpath(tempdir(),"output")
        means_tested_routing :: MT_Routing = eval( Symbol(@load_preference( "means_tested_routing", "modelled_phase_in" )))
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
        impute_employer_pension = @load_preference( "impute_employer_pension", true )
        benefit_generosity_estimates_available = @load_preference( "benefit_generosity_estimates_available", true )
        #
        # weights
        #
        weight_type = eval(Symbol(@load_preference( "weight_type", "constrained_chi_square")))
        lower_multiple = @load_preference( "lower_multiple", 0.20 )
        upper_multiple = @load_preference( "upper_multiple", 5.0)
        
        do_health_estimates = @load_preference( "do_health_estimates", false )
        ## Elliot's email of June 21, 2023
        sf12_depression_limit = @load_preference( "sf12_depression_limit", 45.60)
        create_own_grossing = @load_preference( "create_own_grossing", true)
        use_average_band_d = @load_preference( "use_average_band_d", false)
        included_nations = @load_preference( "included_nations", [N_Scotland])
        indirect_method = @load_preference( "indirect_method", matching )
        impute_fields_from_consumption = @load_preference( "impute_fields_from_consumption", true)
        indirect_matching_dataframe = @load_preference( "indirect_matching_dataframe", "lcf-frs-scotland-only-matches-2015-2021")
        expenditure_dataset = @load_preference( "expenditure_dataset", "lcf_subset-2018-2020")
        wealth_method = @load_preference( "wealth_method", no_method)
        wealth_matching_dataframe = @load_preference( "wealth_matching_dataframe", "was-wave-7-frs-scotland-only-matches-2015-2021-w3")
        wealth_dataset = @load_preference( "wealth_dataset", "was_wave_7_subset")
        do_indirect_tax_calculations = @load_preference( "do_indirect_tax_calculations", false)
        do_legal_aid = @load_preference( "do_legal_aid", true)
        legal_aid_probs_data = @load_preference( "legal_aid_probs_data", "civil-legal-aid-probs-scotland-2015-2012")
        export_full_results = @load_preference( "export_full_results", false)
        do_dodgy_takeup_corrections = @load_preference( "do_dodgy_takeup_corrections", false)
        data_source = @load_preference( "data_source", FRSSource)
        skiplist = @load_preference( "skiplist", "")
        do_local_run = @load_preference( "do_local_run", false )
        ccode = Symbol(@load_preference( "ccode", "" ))
        annual_rent_to_house_price_multiple = @load_preference( "annual_rent_to_house_price_multiple", 20.0 )
        included_data_years = @load_preference( "included_data_years", Int[] )
    end

    """
    The name, as an artifactString of the main dataset artifact e.g.
    'artifact"uk-frs-data" and so on.
    """
    function get_data_artifact( settings::Settings )::AbstractString
        return if settings.data_source == FRSSource
            if settings.target_nation == N_Scotland
                artifact"scottish-frs-data"
            elseif settings.target_nation == N_UK
                artifact"uk-frs-data"
            end            
        elseif settings.data_source == ExampleSource
            artifact"exampledata"
        elseif settings.data_source == SyntheticSource
            if settings.target_nation == N_Scotland
                artifact"scottish-synthetic-data"
            elseif settings.target_nation == N_UK
                artifact"uk-synthetic-data"
            end            
        end
    end

    function get_artifact(; name::String, source::String, scottish :: Bool )::AbstractString
        scuk = scottish ? "scottish" : "uk"
        return LazyArtifacts.@artifact_str("$(scuk)-$(source)-$(name)")
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
        settings.household_name = "model_households-2021-2021-w-enums-2"
        settings.people_name    = "model_people-2021-2021-w-enums-2"
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
        
        settings.indirect_method = matching
        settings.indirect_matching_dataframe = "frs2020_lcf2018-20_matches_all_uk"
        settings.expenditure_dataset = "lcf_subset-2018-2020"
        settings.wealth_method=imputation
        settings.do_indirect_tax_calculations = true
        settings.do_legal_aid = false
        settings.legal_aid_probs_data = ""
        return settings
    end

end
