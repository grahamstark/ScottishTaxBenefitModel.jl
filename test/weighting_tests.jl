import Test: @testset, @test
import ScottishTaxBenefitModel.FRSHouseholdGetter: initialise, get_household, get_num_households
import ScottishTaxBenefitModel.ModelHousehold: Household, Person
import ScottishTaxBenefitModel.Weighting: generate_weights, make_target_dataset, DEFAULT_TARGETS, initialise_target_dataframe
using ScottishTaxBenefitModel

start_year=2015

println( "num_households=$(get_num_households())")

if get_num_households() == 0
      nhh,total_num_people,nhh2 = initialise(
            household_name = "model_households_scotland",
            people_name    = "model_people_scotland",
            start_year = start_year )

end



@testset "weighting tests" begin

      nhh = get_num_households()
      mat = make_target_dataset( nhh )

      open( "data/scotmat.csv", "w" ) do io
         writedlm(io, mat)
      end

      nr,nc=size(mat)
      for c in 1:nc
            @test( sum(mat[:,c]) > 0 )
      end
      weights = generate_weights(nhh)
end
