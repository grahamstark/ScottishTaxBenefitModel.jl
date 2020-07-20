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

    @with_kw mutable struct individual_results
       ni = NIResult()
       it = ITResult()
       # ...
    end

    function make_household_results_frame()

    end

    function make_bu_results_frame()::DataFrame

    end

    function make_individual_results_frame( NR :: DataType=Float64; n :: IR ) :: DataFrame
       DataFrame(
         pid = zeros(BIGINT,n),
         weight = zeros(NR,n),
         sex = zeros(Int,n),
         age_band  = zeros(Int,n),
         employment = zeros(Int,n),

         gross_income = zeros(NR,n),
         net_income  = zeros(NR,n)
         total_taxes = zeros(NR,n),
         total_benefits = zeros(NR,n),
         income_tax = zeros(NR,n),
         it_non_savings = zeros(NR,n),
         it_savings = zeros(NR,n),
         it_dividends = zeros(NR,n),

         ni_above_lower_earnings_limit = fill( false, n )
         ni_total_ni = zeros(NR,n)
         ni_class_1_primary = zeros(NR,n)
         ni_class_1_secondary = zeros(NR,n)
         ni_class_2  = zeros(NR,n)
         ni_class_3  = zeros(NR,n)
         ni_class_4  = zeros(NR,n)
         assumed_gross_wage = zeros(NR,n)


         benefit1 = zeros(NR,n),
         benefit2 = zeros(NR,n),
         basic_income = zeros(NR,n),
         net_income = zeros(NR,n),
         metr = zeros(NR,n),
         tax_credit = zeros(NR,n),
         vat = zeros(NR,n),
         other_indirect = zeros(NR,n),
         total_indirect = zeros(NR,n))
    end


end
