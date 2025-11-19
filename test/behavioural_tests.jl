using Test

using ScottishTaxBenefitModel
using .Definitions
using .SFCBehavioural

# This is a placeholder file for behavioural tests.

# Do we need an external 'correct results' to run the tests against?
# The SFC workbook does this at the aggregate level, but the code runs on individuals
# and then aggregates. Plus the aggregates would not be the same.
# We could recreate the worbook but with up to date rates, thresholds, and for a single 
# person in each band.


@testset "SFCBehavioural Tests 1" begin
    @test "freedom" != "slavery"
end

@testset "SFCBehavioural Tests 2" begin
    @test ! (2+2 == 5)
end