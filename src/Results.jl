module Results

    import ScottishTaxBenefitModel:
      Definitions,
      NationalInsuranceCalculations,
      IncomeTaxCalculations
    using Parameters: with_kw
    using .Definitions
    using DataFrames
    using CSV
    using .IncomeTaxCalculations: ITResult
    using .NationalInsuranceCalculations: NIResult

    export IndividualResults, BenefitUnitResults,HouseholdResults

    @with_kw mutable struct IndividualResults{IT<:Integer, RT<:Real}
       ni = NIResult{IT,RT}()
       it = ITResult{IT,RT}()
       # ...
    end

    function make_household_results_frame()

    end

    function make_bu_results_frame()::DataFrame

    end

    function make_individual_results_frame( n :: IR ) :: DataFrame
        make_individual_results_frame( Float64, n )
    end

    function make_individual_results_frame( RT :: DataType, n :: Int ) :: DataFrame
       DataFrame(
         pid = zeros(BIGINT,n),
         weight = zeros(RT,n),
         sex = zeros(Int,n),
         age_band  = zeros(Int,n),
         employment = zeros(Int,n),

         gross_income = zeros(RT,n),
         net_income  = zeros(RT,n)
         total_taxes = zeros(RT,n),
         total_benefits = zeros(RT,n),
         income_tax = zeros(RT,n),

         it_non_savings = zeros(RT,n),
         it_savings = zeros(RT,n),
         it_dividends = zeros(RT,n),

         ni_above_lower_earnings_limit = fill( false, n )
         ni_total_ni = zeros(RT,n)
         ni_class_1_primary = zeros(RT,n)
         ni_class_1_secondary = zeros(RT,n)
         ni_class_2  = zeros(RT,n)
         ni_class_3  = zeros(RT,n)
         ni_class_4  = zeros(RT,n)
         assumed_gross_wage = zeros(RT,n)


         benefit1 = zeros(RT,n),
         benefit2 = zeros(RT,n),
         basic_income = zeros(RT,n),
         net_income = zeros(RT,n),
         metr = zeros(RT,n),
         tax_credit = zeros(RT,n),
         vat = zeros(RT,n),
         other_indirect = zeros(RT,n),
         total_indirect = zeros(RT,n))
    end


end
