module RunSettings

    using Parameters

    export 
        Settings,
        DEFAULT_SETTINGS,
        MT_Routing,
        uc_full,
        lmt_full,
        modelled_phase_in

    @enum MT_Routing uc_full lmt_full modelled_phase_in
    @with_kw mutable struct Settings
        run_name :: String = "default_run"
        start_year :: Int = 2015
        end_year :: Int = 2018
        scotland_full :: Bool = true
        weighted :: Bool = false
        household_name = "model_households_scotland"
        people_name    = "model_people_scotland"
        num_households :: Int = 0
        num_people :: Int = 0
        to_y :: Int = 2019
        to_q :: Int = 4
        output_dir :: String = joinpath(tempdir(),"output")
        # ... and so on
        means_tested_routing :: MT_Routing = uc_full
    end

    const DEFAULT_SETTINGS = Settings()

end