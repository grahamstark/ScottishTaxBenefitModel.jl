module Runner
    #
    #
    # This module is the main entry point for Scotben. 
    # It runs all the calculations over a collection of households and stores the results in dataframes.
    #
    using Base.Threads

    using Pkg, LazyArtifacts
    using LazyArtifacts
    using Parameters: @with_kw
    using DataFrames
    using CSV
    using Observables

    using BudgetConstraints: BudgetConstraint
  
    using ScottishTaxBenefitModel

    using .Definitions
    using .Utils
    using .STBParameters
    using .STBIncomes
    using .STBOutput
    using .Monitor: Progress
    using .RunSettings
    using .BenefitGenerosity:
        adjust_disability_eligibility!, 
        initialise

    using .ModelHousehold: 
        Household, 
        Person, 
        get_benefit_units

    using .Results: 
        BenefitUnitResult,
        HouseholdResult,
        IndividualResult,
        get_net_income,
        get_indiv_result
        
    import .FRSHouseholdGetter

    using .DataSummariser:get_raw_data! 
    using .Uprating: load_prices
    
    using .SingleHouseholdCalculations: do_one_calc
    
    export 
        do_one_run,
        summarise_inc_frame 

    # this is to remove a nasty cross-dependency
    include( "legal_aid_costs_runner.jl")

    function do_one_run(
        settings :: Settings,
        params   :: Vector{TaxBenefitSystem{T}},
        observer :: Observable ) :: NamedTuple where T # fixme simpler way of declaring this?
        num_threads = min( nthreads(), settings.requested_threads )
        println( "starting $num_threads threads")

        num_systems = size( params )[1]
        observer[]=Progress( settings.uuid, "do-one-run-start", 0, 0, 0, 0 )
        load_prices( settings, false )
        if settings.num_households == 0
            observer[]= Progress( settings.uuid, "weights", 0, 0, 0, 0  )
            @time settings.num_households, settings.num_people, nhh2 = 
                FRSHouseholdGetter.initialise( settings )
            if settings.benefit_generosity_estimates_available
                BenefitGenerosity.initialise()  
            end
        end
        if settings.do_legal_aid && (settings.legal_aid_costs_strategy == la_individual_costs)
            # This setting change is a hack to stop recursion, since la_initialise calls run.
            settings.legal_aid_costs_strategy = la_no_costs
            la_initialise( settings, observer )   
            settings.legal_aid_costs_strategy = la_individual_costs
        end
        full_results = Array{HouseholdResult}(undef,0,0)
        # fixme if we have one are threads OK? I think yes
        if settings.export_full_results
            full_results = Array{HouseholdResult}(undef,num_systems,settings.num_households)
        end
        # vary generosity of disability benefits
        if settings.benefit_generosity_estimates_available
            observer[]= Progress( 
                settings.uuid, "disability_eligibility", 0, 0, 0, settings.num_households )
            for sysno in 1:num_systems
                adjust_disability_eligibility!( params[sysno].nmt_bens )
            end
        end
        # scotland - hacky calibration of Child Disability Payment
        if settings.target_nation == N_Scotland
            for sysno in 1:num_systems
                params[sysno].nmt_bens.scdp.care_thresholds,
                params[sysno].nmt_bens.scdp.mobility_thresholds = 
                    NonMeansTestedBenefits.calibrate_child_disability(
                        settings,
                        params[sysno].nmt_bens.scdp.care_cases,
                        params[sysno].nmt_bens.scdp.mobility_cases )
            end
        end
        start,stop = make_start_stops( settings.num_households, num_threads )
        frames :: NamedTuple = initialise_frames( T, settings, num_systems )
        observer[] =Progress( settings.uuid, "starting",0, 0, 0, settings.num_households )
        @time @threads for thread in 1:num_threads
            for hno in start[thread]:stop[thread]
                hh = FRSHouseholdGetter.get_household( hno )
                nation = nation_from_region( hh.region )
                if nation in settings.included_nations
                    if hno % 100 == 0
                        observer[] =Progress( settings.uuid, "run",thread, hno, 100, settings.num_households )
                    end
                    for sysno in 1:num_systems
                        res = do_one_calc( hh, params[sysno], settings )
                        if settings.do_marginal_rates
                            for (pid,pers) in hh.people
                                #
                                # `from_child_record` sorts out 17+ in education.
                                #
                                if ( ! pers.is_standard_child) && ( pers.age <= settings.mr_rr_upper_age )
                                    # FIXME choose between SE and Wage depending on which is
                                    # bigger, or empoyment status
                                    # println( "wage was $(pers.income[wages])")
                                    pers.income[wages] += settings.mr_incr
                                    subres = do_one_calc( hh, params[sysno], settings )            
                                    subhhinc = get_net_income( subres; target=settings.target_mr_rr_income )
                                    hhinc = get_net_income( res; target=settings.target_mr_rr_income )
                                    pres = get_indiv_result( res, pid )
                                    pres.metr = round( 
                                        100.0 * (1-((subhhinc-hhinc)/settings.mr_incr)),
                                        digits=7 )                           
                                    pers.income[wages] -= settings.mr_incr                        
                                    # println( "wage set back to $(pers.income[wages]) metr is $(pres.metr)")
                                end # working age
                            end # people
                        end # mrs
                        if settings.do_replacement_rates
                            for (pid,pers) in hh.people
                                if ( ! pers.is_standard_child ) && ( pers.age <= settings.mr_rr_upper_age )
                                    # FIXME TODO need to be careful with hours and so on
                                end # working age
                            end # people
                        end
                        add_to_frames!( settings, frames, hh, res,  sysno, num_systems )
                        if settings.export_full_results
                            full_results[sysno,hno] = res
                        end
                    end # sysno
                end # included in nations 
            end #household loop
        end # threads
        if settings.dump_frames 
            observer[]= Progress( settings.uuid, "dumping_frames", 0, 0, 0, 0 )
            dump_frames( settings, frames )
        end
        observer[]= Progress( settings.uuid, "do-one-run-end", -99, -99, -99, -99 )
        # FIXME. This should not be needed, but see: https://github.com/JuliaLang/julia/issues/50658 and the out-of-memory issues with the pppc server.
        GC.gc()
        if settings.export_full_results
            frames = (; frames..., full_results )
        end
        return frames
    end # do one run

end # module