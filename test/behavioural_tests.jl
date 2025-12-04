using Test

using ScottishTaxBenefitModel
using .Definitions
using .SFCBehavioural


# -----------------------------------------------------------------------------
# Helper functions (replicated from module for standalone testing)
# -----------------------------------------------------------------------------

function lookup_band_index(x::Real, edges::AbstractVector)::Int
    for i in 1:(length(edges)-1)
        if edges[i] <= x < edges[i+1]
            return i
        end
    end
    return length(edges) - 1
end
const L_TIE_EDGES = SFCBehavioural.TIE_EDGES .* WEEKS_PER_YEAR

function lookup_tie(taxable_income::Real)::Float64
    idx = lookup_band_index(taxable_income, L_TIE_EDGES)
    return SFCBehavioural.TIE_RATES[idx]
end


"""
    calc_intensive_margin(; taxable_income, mtr_baseline, mtr_reform, ni_baseline, ni_reform)

Calculate the intensive margin behavioural response for a single individual.

Returns the change in tax revenue due to intensive margin response (negative = less revenue).
"""
function calc_intensive_margin(;
    taxable_income::Float64,
    mtr_baseline::Float64,
    mtr_reform::Float64,
    ni_baseline::Float64,
    ni_reform::Float64 )::Float64
    # Marginal retention rates
    mrr_baseline = 1.0 - mtr_baseline - ni_baseline
    mrr_reform = 1.0 - mtr_reform - ni_reform
    
    # Percentage change in MRR
    mrr_pct_change = mrr_baseline == 0.0 ? 0.0 : (mrr_reform / mrr_baseline - 1.0)
    
    # TIE for this income level
    tie = lookup_tie(taxable_income)
    
    # Change in taxable income
    taxable_change = tie * mrr_pct_change * taxable_income
    
    # Tax impact at reform marginal rate
    intensive_change = taxable_change * mtr_reform
    
    return intensive_change
end


# This is a placeholder file for behavioural tests.

# Do we need an external 'correct results' to run the tests against?
# The SFC workbook does this at the aggregate level, but the code runs on individuals
# and then aggregates. Plus the aggregates would not be the same.
# We could recreate the worbook but with up to date rates, thresholds, and for a single 
# person in each band.


# -----------------------------------------------------------------------------
# Test Case Structure
# -----------------------------------------------------------------------------

struct IntensiveMarginTestCase
    name::String
    description::String
    taxable_income::Float64      # Annual taxable income (post-allowance)
    mtr_baseline::Float64        # Baseline marginal IT rate
    mtr_reform::Float64          # Reform marginal IT rate
    ni_baseline::Float64         # Baseline NI rate
    ni_reform::Float64           # Reform NI rate
    expected_intensive::Float64  # Expected intensive margin change (£)
    tolerance::Float64           # Acceptable difference (£)
end

# -----------------------------------------------------------------------------
# Define Your 7 Test Cases
# -----------------------------------------------------------------------------
# Fill in the expected_intensive values from your case study calculations

test_cases = [
    
    IntensiveMarginTestCase(
        "Case 1: Starter rate taxpayer",
        "Describe the scenario here",
        2_500.0,      # taxable_income
        0.19,          # mtr_baseline
        0.20,          # mtr_reform (example: 1pp increase)
        0.08,          # ni_baseline
        0.08,          # ni_reform
        -0.103,           # TODO: expected_intensive - fill in your value
        0.002            # tolerance (£)
    ),
    
    IntensiveMarginTestCase(
        "Case 2: Basic rate taxpayer",
        "Describe the scenario here",
        10_000.0,      # taxable_income
        0.20,          # mtr_baseline
        0.21,          # mtr_reform
        0.08,          # ni_baseline
        0.08,          # ni_reform
        -0.438,           # TODO: expected_intensive - fill in your value
        0.002            # tolerance
    ),
    
    IntensiveMarginTestCase(
        "Case 3: Higher rate taxpayer (lower end)",
        "Describe the scenario here",
        50_000.0,      # taxable_income
        0.42,          # mtr_baseline
        0.43,          # mtr_reform
        0.02,          # ni_baseline
        0.02,          # ni_reform
        -38.393,       # expected_intensive - fill in your value
        1.0            # tolerance
    ),
    
    IntensiveMarginTestCase(
        "Case 4: Higher rate taxpayer (upper end)",
        "Describe the scenario here",
        85_000.0,      # taxable_income
        0.45,          # mtr_baseline
        0.46,          # mtr_reform
        0.02,          # ni_baseline
        0.02,          # ni_reform
        -147.547,      # expected_intensive - fill in your value
        1.0            # tolerance
    ),
    
    IntensiveMarginTestCase(
        "Case 5: £150k-£300k band",
        "Describe the scenario here",
        175_000.0,     # taxable_income
        0.48,          # mtr_baseline
        0.49,          # mtr_reform
        0.02,          # ni_baseline
        0.02,          # ni_reform
        -600.25,       # expected_intensive - fill in your value
        5.0            # tolerance (higher for larger amounts)
    ),
    
    IntensiveMarginTestCase(
        "Case 6: £300k-£500k band",
        "Describe the scenario here",
        340_000.0,     # taxable_income
        0.48,          # mtr_baseline
        0.49,          # mtr_reform
        0.02,          # ni_baseline
        0.02,          # ni_reform
        -1_832.6,      # expected_intensive - fill in your value
        10.0           # tolerance
    ),
    
    IntensiveMarginTestCase(
        "Case 7: Top earner (£500k+)",
        "Describe the scenario here",
        600_000.0,     # taxable_income
        0.48,          # mtr_baseline
        0.49,          # mtr_reform
        0.02,          # ni_baseline
        0.02,          # ni_reform
        -4_410.0,      # expected_intensive - fill in your value
        20.0           # tolerance
    ),
]

# -----------------------------------------------------------------------------
# Run Tests
# -----------------------------------------------------------------------------

@testset "Intensive Margin Tests" begin
    for tc in test_cases
        @testset "$(tc.name)" begin
            calculated = calc_intensive_margin(
                taxable_income = tc.taxable_income,
                mtr_baseline = tc.mtr_baseline,
                mtr_reform = tc.mtr_reform,
                ni_baseline = tc.ni_baseline,
                ni_reform = tc.ni_reform
            )
            @test isapprox(calculated, tc.expected_intensive, atol=tc.tolerance)
        end
    end
end