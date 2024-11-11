module RunSettings
    #
    # This module contains things needed to control one run e.g. the output destination, number of households to use andd so on.
    #
    using Pkg
    using Pkg.Artifacts
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
        data_dir,
        get_skiplist,

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
    @with_kw mutable struct Settings
        uuid :: UUID = UUID("c2ae9c83-d24a-431c-b04f-74662d2ba07e")
        uid :: Int = 1 # placeholder for maybe a user somewhere
        run_name = @load_preference( "default_run_name", "default_run" )
        scotland_full :: Bool = true
        weighted = @load_preference( "use_weighting", true )
        auto_weight = @load_preference( "auto_weight", true )
        data_dir :: String = MODEL_DATA_DIR # DELETE
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
        lower_multiple = eval(Symbol(@load_preference( "lower_multiple", "0.20 # these values can be narrowed somewhat, to around 0.25-4.7")))
        upper_multiple = eval(Symbol(@load_preference( "upper_multiple", "5.0")))
        
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
                
    end

    #=
    function load_settings!( settings::Settings )
        settings.run_name = @load_preference( "default_run_name")
        settings.scotland_full = true
        settings.weighted = @load_preference( "use_weighting")
        settings.auto_weight = @load_preference( "auto_weight")
        settings.data_dir = MODEL_DATA_DIR # DELETE
        settings.household_name = "model_households_scotland-2015-2021-w-enums-2"
        settings.people_name  = "model_people_scotland-2015-2021-w-enums-2"
        settings.target_nation = eval(Symbol(@load_preference("target_nation"))) #  N_Scotland
        settings.dump_frames = @load_preference( "dump_frames")
        # num_households  = 0
        # num_people :: Int = 0
        settings.prices_file = "indexes.tab"
        settings.to_y = @load_preference( "to_y" )
        settings.to_q = @load_preference( "to_q" )
        # settings.output_dir = joinpath(tempdir(),"output")
        settings.means_tested_routing = eval( Symbol(@load_preference( "means_tested_routing" )))
        # settings.poverty_line = -1.0
        settings.poverty_line_source = eval( Symbol(@load_preference( "poverty_line_source")))
        settings.ineq_income_measure = eval( Symbol(@load_preference( "ineq_income_measure" )))
        # settings.growth :: Real = 0.02 # for time to exit poverty
        settings.income_data_source = ds_frs # ds_hbai !! not used
        settings.do_marginal_rates = @load_preference( "do_marginal_rates" )
        settings.do_replacement_rates = @load_preference( "do_replacement_rates" )
        settings.replacement_rate_hours = @load_preference( "replacement_rate_hours" )
    end
    =#

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

    function data_dir( settings :: Settings ) :: String
        ds = if settings.data_source == FRSSource
            "actual_data"
        elseif settings.data_source == ExampleSource
            "example_data"
        elseif settings.data_source == SyntheticSource
            "synthetic_data"
        end
        return joinpath( settings.data_dir, ds )
    end

    """
    Default live data dir
    """
    function data_dir()::String
        return data_dir( Settings() )
    end

    """
    Make a tuple with "hhlds=>" and "people=>" with full paths to example datasets.
    """
    function example_datasets( settings :: Settings ) :: NamedTuple
        # FIXME data_dir with just the src, not settings.
        tmpsrc = settings.data_source
        settings.data_source = ExampleSource
        dd = data_dir( settings )
        settings.data_source = tmpsrc
        return ( 
            hhlds = joinpath( dd, "example_households-w-enums.tab" ),
            people = joinpath( dd, "example_people-w-enums.tab" ),
            skiplist = ""
        )
    end  

    """
    Make a tuple with "hhlds=>" and "people=>" with full paths to main datasets.
    """
    function main_datasets( settings :: Settings ) :: NamedTuple
        dd = data_dir( settings )
        return ( 
            hhlds = joinpath( dd, settings.household_name*".tab" ),
            people = joinpath( dd, settings.people_name*".tab" ),
            skiplist = joinpath( dd, settings.skiplist*".tab" )
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
        settings.auto_weight = false
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
