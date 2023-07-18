module RunSettings
    #
    # This module contains things needed to control one run e.g. the output destination, number of households to use andd so on.
    #
    using Parameters
    
    using ScottishTaxBenefitModel
    using .Definitions
    using UUIDs
    using SurveyDataWeighting

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

        PovertyLineSource,
        pl_from_settings, 
        pl_first_sys,
        pl_current_sys,

        get_all_uk_settings_2023
        
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

    @with_kw mutable struct Settings
        uuid :: UUID = UUID("c2ae9c83-d24a-431c-b04f-74662d2ba07e")
        uid :: Int = 1 # placeholder for maybe a user somewhere
        run_name :: String = "default_run"
        start_year :: Int = 2015
        end_year :: Int = 2019
        scotland_full :: Bool = true
        weighted :: Bool = false
        
        # weighting stuff
        auto_weight = true
 
        data_dir :: String = MODEL_DATA_DIR
        household_name = "model_households_scotland"
        people_name    = "model_people_scotland"
        target_nation :: Nation = N_Scotland
        dump_frames :: Bool = false
        num_households :: Int = 0
        num_people :: Int = 0
        prices_file = "indexes.tab"
        to_y :: Int = 2022
        to_q :: Int = 3
        output_dir :: String = joinpath(tempdir(),"output")
        means_tested_routing :: MT_Routing = uc_full
        poverty_line :: Real = -1.0
        poverty_line_source :: PovertyLineSource = pl_first_sys
        ineq_income_measure  :: IneqIncomeMeasure = eq_bhc_net_income
        growth :: Real = 0.02 # for time to exit poverty
        income_data_source :: DataIncomeSource = ds_frs # ds_hbai
        do_marginal_rates  :: Bool = false
        do_replacement_rates :: Bool = false
        replacement_rate_hours :: Int = 30
        # We jam on age 68 here since we don't want changes to pension age
        # in the parameters to affect the numbers of people in
        # mr/rr calculations.
        mr_rr_upper_age :: Int = 68
        target_bc_income :: TargetBCIncomes = ahc_hh 
        target_mr_rr_income :: TargetBCIncomes = ahc_hh 
        mr_incr = 0.001
        requested_threads = 1
        impute_employer_pension = true
        benefit_generosity_estimates_available = true
        #
        # weights
        #
        weight_type :: DistanceFunctionType = constrained_chi_square
        lower_multiple :: Real = 0.20 # these values can be narrowed somewhat, to around 0.25-4.7
        upper_multiple :: Real = 5.0
        do_health_esimates = false 
        ## Elliot's email of June 21, 2023
        sf12_depression_limit = 45.60
        create_own_grossing = true
        use_average_band_d = false
        included_nations = [N_Scotland]
    end

    function get_all_uk_settings_2023()::Settings
        settings = Settings()
        settings.household_name = "model_households-2021-2021"
        settings.people_name    = "model_people-2021-2021"
        settings.target_nation :: Nation = N_UK
        settings.dump_frames :: Bool = false
        settings.num_households :: Int = 0
        settings.num_people :: Int = 0
        settings.prices_file = "indexes-july-2023.tab"
        settings.to_y :: Int = 2023
        settings.to_q :: Int = 1
        settings.auto_weight = false
        settings.use_average_band_d = true
        settings.benefit_generosity_estimates_available = false
        settings.requested_threads = 4
        settings.impute_employer_pension = false
        settings.included_nations = [N_Scotland,N_England,N_Wales]
        settings.means_tested_routing = modelled_phase_in
        return settings
    end

end