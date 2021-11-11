module RunSettings
    #
    # This module contains things needed to control one run e.g. the output destination, number of households to use andd so on.
    #
    using Parameters

    export 
        Settings,
        DEFAULT_SETTINGS,
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
        total_taxes
        
    @enum TargetBCIncomes ahc_hh bhc_hh total_bens total_taxes
        
    @enum MT_Routing uc_full lmt_full modelled_phase_in
    @enum IneqIncomeMeasure bhc_net_income eq_bhc_net_income ahc_net_income eq_ahc_net_income
    @enum DataIncomeSource ds_hbai ds_frs 
    @with_kw mutable struct Settings
        uid :: Int = 1 # placeholder for maybe a user somewhere
        run_name :: String = "default_run"
        start_year :: Int = 2015
        end_year :: Int = 2018
        scotland_full :: Bool = true
        weighted :: Bool = false
        household_name = "model_households_scotland"
        people_name    = "model_people_scotland"
        dump_frames :: Bool = false
        num_households :: Int = 0
        num_people :: Int = 0
        prices_file = "indexes_sep_1_2021.tab"
        to_y :: Int = 2021
        to_q :: Int = 2
        output_dir :: String = joinpath(tempdir(),"output")
        means_tested_routing :: MT_Routing = uc_full
        poverty_line :: Real = -1.0
        ineq_income_measure  :: IneqIncomeMeasure = eq_bhc_net_income
        growth :: Real = 0.02 # for time to exit poverty
        income_data_source :: DataIncomeSource = ds_hbai
        do_marginal_rates  :: Bool = false
        do_replacement_rates :: Bool = false
        replacement_rate_hours :: Int = 30
        # We jam on 68 here since we don't want changes to pension age
        # in the parameters to affect the numbers of people in
        # mr/rr calculations.
        mr_rr_upper_age :: Int = 68
        target_bc_income :: TargetBCIncomes = ahc_hh 
        target_mr_rr_income :: TargetBCIncomes = ahc_hh 
        mr_incr = 0.01
    end

    const DEFAULT_SETTINGS = Settings()

end