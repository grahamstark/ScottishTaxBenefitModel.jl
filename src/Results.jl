module Results

    import ScottishTaxBenefitModel:
      Definitions,
      NationalInsuranceCalculations,
      IncomeTaxCalculations
    using Parameters: @with_kw
    using .Definitions
    using DataFrames
    using CSV
    using .IncomeTaxCalculations: ITResult
    using .NationalInsuranceCalculations: NIResult

    export IndividualResult,
        BenefitUnitResult,
        HouseholdResult,
        make_household_results_frame,
        make_bu_results_frame,
        make_individual_results_frame

    @with_kw mutable struct IndividualResult{IT<:Integer, RT<:Real}
       ni = NIResult{IT,RT}()
       it = ITResult{IT,RT}()
       # ...
    end

    @with_kw mutable struct BenefitUnitResult{RT<:Real}
        net_income :: RT = zero(RT)
        eq_net_income :: RT = zero(RT)
    end

    @with_kw mutable struct HouseholdResult{RT<:Real}
        bhc_net_income :: RT = zero(RT)
        eq_bhc_net_income :: RT = zero(RT)
        ahc_net_income :: RT = zero(RT)
        eq_ahc_net_income :: RT = zero(RT)
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
         eq_ahc_net_income = zeros(RT,n)) # etc.

         metr = zeros(RT,n),
         tax_credit = zeros(RT,n),
         vat = zeros(RT,n),
         other_indirect = zeros(RT,n),
         total_indirect = zeros(RT,n))
    end


end
