module Runner
    #
    # This model actually runs all the calculations over a collection of households and stores the results in dataframes.
    # Presently it also contains code to summarise the output dataframes. FIXME output needs to be in own module.
    #
    using Parameters: @with_kw
    using DataFrames: DataFrame, DataFrameRow, Not, select!
    using CSV

    using BudgetConstraints: BudgetConstraint

    using ScottishTaxBenefitModel

    using .Definitions
    using .Utils
    using .STBParameters
    using .STBIncomes
    using .STBOutput

    using .RunSettings:
        Settings
    
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
        IndividualResult
        
    import .FRSHouseholdGetter
        
    using .Uprating: load_prices
    
    using .SingleHouseholdCalculations: do_one_calc
    
    export 
        do_one_run,
        summarise_inc_frame 

    # fixme move the output stuff (mostly) to an Output.jl module

    function do_one_run(
        settings :: Settings,
        params   :: Vector{TaxBenefitSystem{T}} ) :: NamedTuple where T # fixme simpler way of declaring this?
        num_systems = size( params )[1]
        println("start of do_one_run; using $(settings.means_tested_routing) routing")
        load_prices( settings, false )
        for p in 1:num_systems
            println("sys $p")
            println(params[p].it)
        end
        if settings.num_households == 0
            println( "getting households" )
            @time settings.num_households, settings.num_people, nhh2 = 
                FRSHouseholdGetter.initialise( settings )
            BenefitGenerosity.initialise( MODEL_DATA_DIR*"/disability/" )       
        end

        # vary generosity of disability benefits
        for sysno in 1:num_systems
            adjust_disability_eligibility!( params[sysno].nmt_bens )
        end
                

        frames :: NamedTuple = initialise_frames( T, settings, num_systems )
        frame_starts = FrameStarts(0,0,0,0)
        println( "starting run " )
        @time for hno in 1:settings.num_households
            hh = FRSHouseholdGetter.get_household( hno )
            if hno % 100 == 0
                println( "on household hno $hno hid=$(hh.hid) year=$(hh.interview_year)")
            end
            for sysno in 1:num_systems
                res = do_one_calc( hh, params[sysno], settings )
                frame_starts = add_to_frames!( frames, hh, res,  sysno, frame_starts, num_systems )
            end
        end #household loop
        println( "dumping frames" )
        # dump_frames( settings, frames )
        return frames
    end # do one run

end # module