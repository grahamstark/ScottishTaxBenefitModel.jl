import Test: @testset, @test
import ScottishTaxBenefitModel.FRSHouseholdGetter: initialise, get_household, num_households
import ScottishTaxBenefitModel.ModelHousehold: Household, Person
import ScottishTaxBenefitModel.Weighting: generate_weights, make_target_dataset, DEFAULT_TARGETS, initialise_target_dataframe

start_year=2015

if num_households() == 0
      initialise()
end

@testset "weighting tests" begin

      df = initialise_target_dataframe(100)
      nhh = num_households()
      weights = generate_weights(nhh)
end
