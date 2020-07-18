import Test: @testset, @test
import ScottishTaxBenefitModel.FRSHouseholdGetter: initialise, get_household
import ScottishTaxBenefitModel.ModelHousehold: Household, Person
import ScottishTaxBenefitModel.Weighting: generate_weights, make_target_dataset, TARGETS, initialise_target_dataframe

start_year=2015

@testset "weighting tests" begin

      @test 1+1==2
      df = initialise_target_dataframe(100)
end
