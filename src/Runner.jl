module Runner

using BudgetConstraints: BudgetConstraint

    using Parameters: @with_kw
    using DataFrames: DataFrame, DataFrameRow

    using ScottishTaxBenefitModel:
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
    using .Weighting: generate_weights
    using .ModelHousehold: Household, Person, get_benefit_units
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

    struct FrameStarts
        hh :: Integer
        bu :: Integer
        pers :: Integer
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
            tenure    = fill( Missing_Tenure_Type, n ),
            region    = fill( Missing_Standard_Region, n ),
            gross_decile = zeros( Int, n ),
            bhc_net_income = zeros(RT,n),
            ahc_net_income = zeros(RT,n),
            eq_scale = zeros(RT,n),
            eq_bhc_net_income = zeros(RT,n),
            eq_ahc_net_income = zeros(RT,n), # etc.
            income_taxes = zeros(RT,n),
            means_tested_benefits = zeros(RT,n),
            other_benefits = zeros(RT,n))
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
            eq_net_income = zeros(RT,n),
            income_taxes = zeros(RT,n),
            means_tested_benefits = zeros(RT,n),
            other_benefits = zeros(RT,n)
            ) # etc.
    end

    function make_individual_results_frame( n :: Int ) :: DataFrame
        make_individual_results_frame( Float64, n )
    end

    function make_individual_results_frame( RT :: DataType, n :: Int ) :: DataFrame
       DataFrame(
         pid = zeros(BIGINT,n),
         weight = zeros(RT,n),
         sex = zeros(Missing_Sex,n),
         age_band  = zeros(Int,n),
         employment = zeros(Missing_ILO_Employment,n),
         # ... and so on

         income_taxes = zeros(RT,n),
         means_tested_benefits = zeros(RT,n),
         other_benefits = zeros(RT,n),

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

    function initialise_frames( settings :: RunSettings, num_systems :: Integer, RT::DataType  ) :: NamedTuple
        indiv = fill( make_individual_results_frame( RT, settings.num_people ), num_systems )
        bu = fill( make_bu_results_frame, settings.num_people ) # overstates but we don't actually know this at the start
        hh = fill( make_hh_results_frame, settings.num_households )
        (hh=hh, bu=bu, indiv=indiv)
    end

    function fill_hh_frame_row!( hr :: DataFrameRow, hh :: Household, hres :: HouseholdResult )
        hr.hid = hh.hid
        hr.data_year = hh.data_year
        hr.weight = hh.weight
        hr.hh_type = -1
        hr.tenure = hh.tenure
        hr.region = hh.region
        hr.gross_decile = -1
        hr.income_taxes = hres.income_taxes
        hr.means_tested_benefits = hr.means_tested_benefits
        hr.other_benefits = hr.other_benefits
        hr.bhc_net_income = hres.bhc_net_income
        hr.ahc_net_income = hres.ahc_net_income
        hr.eq_scale = hres.eq_scale
        eq_bhc_net_income = hres.eq_bhc_net_income
        eq_ahc_net_income = hres.eq_ahc_net_income
    end

    function fill_bu_frame_row!(
        br :: DataFrameRow,
        hh :: Household,
        bres :: BenefitUnitResult )

        # ...

    end

    function fill_pers_frame_row!(
        pr :: DataFrameRow,
        hh :: Household,
        pers :: Person,
        pres :: IndividualResult )

        pr.pid = pers.pid
        pr.weight = hh.weight
        pr.sex = pers.sex
        pr.age_band  = -1 # TODO
        pr.employment = pers.employment_status

        pr.income_taxes = pres.income_taxes
        pr.means_tested_benefits = pres.means_tested_benefits
        pr.other_benefits = pres.other_benefits

        pr.income_tax = pres.it.total_tax
        pr.it_non_savings = pres.it.non_savings
        pr.it_savings = pres.it.savings
        pr.it_dividends = pres.it.dividends

        pr.ni_above_lower_earnings_limit = pres.ni.above_lower_earnings_limit
        pr.ni_total_ni = pres.ni.total_ni
        pr.ni_class_1_primary = pres.ni.class_1_primary
        pr.ni_class_1_secondary = pres.ni.class_1_secondary
        pr.ni_class_2  = pres.ni.class_2
        pr.ni_class_3  = pres.ni.class_3
        pr.ni_class_4  = pres.ni.class_4
        pr.assumed_gross_wage = pres.ni.assumed_gross_wage

        # benefit1 = zeros(RT,n),
        # benefit2 = zeros(RT,n),
        # basic_income = zeros(RT,n),
        # gross_income = zeros(RT,n),
        # net_income = zeros(RT,n),
        #
        # bhc_net_income = zeros(RT,n),
        # ahc_net_income = zeros(RT,n),
        # eq_scale = -1.0
        # eq_bhc_net_income = zeros(RT,n),
        # eq_ahc_net_income = zeros(RT,n), # etc.
        #
        # metr = zeros(RT,n),
        # tax_credit = zeros(RT,n),
        # vat = zeros(RT,n),
        # other_indirect hres.bus[buno]= zeros(RT,n),
        # total_indirect = zeros(RT,n))
    end

    function add_to_frames!(
        frames :: NamedTuple,
        sysno  :: Integer,
        hh     :: Household,
        hres   :: HouseholdResult,
        frame_starts :: FrameStarts )

        fill_hh_frame_row!( frames.hh[sysno][frame_starts.hh, :], hh, hres)
        bfno = frame_starts.bu
        pfno = frame_starts.pers
        nbus = length(hres.bu)
        npeople = 0
        bus = get_benefit_units( hh )
        for buno in 1:nbus
            fill_bu_frame( frames.bu[sysno][bfno,:], hh, hres.bus[buno])
            for( pid, pers ) in bus[buno].people
                fill_pers_frame_row!(
                    frames.pers[sysno][pfno,:],
                    hh,
                    pers,
                    hres.bus[buno].pers[pid] )
                pfno += 1
            end # person loop
            bfno += 1
        end # buno
        return FrameStarts( frame_starts.hh + 1, bfno, pfno )
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

        frames = initialise_frames( settings, num_systems, RT )
        frame_starts = FrameStarts(1,1,1)
        @time for hno in 1:settings.num_households
            hh = FRSHouseholdGetter.get_household( hno )
            # print("$hh,")
            for sysno in 1:num_systems
                res = do_one_calc( hh, params[sysno] )
                frame_starts = add_to_frames!( frames, hh, res,  sysno, frame_starts )
            end
        end #household loop
    end # do one run

end
