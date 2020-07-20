module Runner

import BudgetConstraints: BudgetConstraint

    using Parameters: @with_kw

    import ScottishTaxBenefitModel:
        GeneralTaxComponents,
        Definitions,
        Utils,
        STBParameters,
        Results,
        FRSHouseholdGetter,
        ModelHousehold,
        SingleHouseholdCalculations,
        Weighting

    using .Definitions
    using .Utils
    using .STBParameters
    import .Weighting: generate_weights
    using .ModelHousehold: Household
    using .Results:


    export do_one_run!,RunSettings

    @with_kw mutable struct RunSettings
        start_year :: Integer = 2015
        end_year :: Integer = 2018
        scotland_only :: Bool = true
        household_name = "model_households_scotland",
        people_name    = "model_people_scotland",
        num_households :: Integer = 0
        num_people :: Integer = 0
        # ...
    end

    function do_one_run!(
        settings :: RunSettings,
        params :: Vector{TaxBenefitSystem{IT,RT}} ) where IT <: Integer where RT<:Real
        num_systems = size( params )[1]

        if settings.num_households == 0
            @time settings.num_houseolds,
                settings.num_people,
                nhh2 = initialise(
                        household_name = settings.household_name,
                        people_name    = settings.people_name,
                        start_year     = settings.start_year )
                @time weights = generate_weights( settings.num_households )
        end

        @time for hno in 1:settings.num_households
            hh = FRSHouseholdGetter.get_household( hhno )
            for sys in params
                res = do_one_calc( hh, sys )
            end
        end


    end

end
