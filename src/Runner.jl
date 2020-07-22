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
    using .Results: IndividualResult,
        BenefitUnitResult,
        HouseholdResult
    using .FRSHouseholdGetter: initialise, get_household
    using .SingleHouseholdCalculations: do_one_calc
    export do_one_run!,RunSettings

    @with_kw mutable struct RunSettings
        start_year :: Integer = 2015
        end_year :: Integer = 2018
        scotland_only :: Bool = true
        household_name = "model_households_scotland"
        people_name    = "model_people_scotland"
        num_households :: Integer = 0
        num_people :: Integer = 0
        # ...
    end

    function make_household_results_frame( n :: Int ) :: DataFrame
        make_household_results_frame( Float64, n )
    end

    function make_household_results_frame( RT :: DataType, n :: Int ) :: DataFrame
        DataFrame(
            hid       = zeros( BIGINT,n),
            data_year = zeros( Int, n ),
            weight    = zeros(RT,n),
            hh_type   = zeros( Int, n ),
            tenure    = zeros( Int, n ),
            region    = zeros( Int, n ),
            gross_decile = zeros( Int, n ),
            bhc_net_income = zeros(RT,n),
            ahc_net_income = zeros(RT,n),
            eq_scale = zeros(RT,n),
            eq_bhc_net_income = zeros(RT,n),
            eq_ahc_net_income = zeros(RT,n)) # etc.

    end

    function make_bu_results_frame( n :: Int ) :: DataFrame
        return make_bu_results_frame( Float64, n )
    end

    function make_bu_results_frame( RT :: DataType, n :: Int ) :: DataFrame
        DataFrame(
            hid       = zeros(BIGINT,n),
            buno      = zeros( Int, n ),
            data_year = zeros( Int, n ),
            weight    = zeros(RT,n),
            bu_type   = zeros( Int, n ),
            tenure    = zeros( Int, n ),
            region    = zeros( Int, n ),
            gross_decile = zeros( Int, n ),
            net_income = zeros(RT,n),
            eq_scale   = zeros(RT,n),
            eq_net_income = zeros(RT,n)) # etc.
    end

    function make_individual_results_frame( n :: Int ) :: DataFrame
        make_individual_results_frame( Float64, n )
    end

    function make_individual_results_frame( RT :: DataType, n :: Int ) :: DataFrame
       DataFrame(
         pid = zeros(BIGINT,n),
         weight = zeros(RT,n),
         sex = zeros(Int,n),
         age_band  = zeros(Int,n),
         employment = zeros(Int,n),

         total_taxes = zeros(RT,n),
         total_benefits = zeros(RT,n),
         income_tax = zeros(RT,n),

         it_non_savings = zeros(RT,n),
         it_savings = zeros(RT,n),
         it_dividends = zeros(RT,n),

         ni_above_lower_earnings_limit = fill( false, n ),
         ni_total_ni = zeros(RT,n),
         ni_class_1_primary = zeros(RT,n),
         ni_class_1_secondary = zeros(RT,n),
         ni_class_2  = zeros(RT,n),
         ni_class_3  = zeros(RT,n),
         ni_class_4  = zeros(RT,n),
         assumed_gross_wage = zeros(RT,n),

         benefit1 = zeros(RT,n),
         benefit2 = zeros(RT,n),
         basic_income = zeros(RT,n),
         gross_income = zeros(RT,n),
         net_income = zeros(RT,n),

         bhc_net_income = zeros(RT,n),
         ahc_net_income = zeros(RT,n),
         eq_scale = zeros(RT,n),
         eq_bhc_net_income = zeros(RT,n),
         eq_ahc_net_income = zeros(RT,n), # etc.

         metr = zeros(RT,n),
         tax_credit = zeros(RT,n),
         vat = zeros(RT,n),
         other_indirect = zeros(RT,n),
         total_indirect = zeros(RT,n))
    end



    function do_one_run!(
        settings :: RunSettings,
        params :: Vector{TaxBenefitSystem{IT,RT}} ) where IT <: Integer where RT<:Real
        num_systems = size( params )[1]

        if settings.num_households == 0
            @time settings.num_households,
                settings.num_people,
                nhh2 = initialise(
                        household_name = settings.household_name,
                        people_name    = settings.people_name,
                        start_year     = settings.start_year )
                @time weights = generate_weights( settings.num_households )
        end

        @time for hno in 1:settings.num_households
            hh = FRSHouseholdGetter.get_household( hno )
            print("$hh,")
            for sys in params
                res = do_one_calc( hh, sys )
            end
        end


    end

end
