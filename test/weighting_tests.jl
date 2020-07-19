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
    hhlds_in_popn = sum( DEFAULT_TARGETS[42:48]) # sum of all hhld types
    data = make_target_dataset( nhh )
    nr,nc = size(data)

    @test nr == nhh
    @test nc == size( DEFAULT_TARGETS )[1]

    initial_weights = ones(nhh)*hhlds_in_popn/nr

    initial_weighted_popn = (initial_weights' * data)'

    println( "initial-weighted_popn vs targets" )
    println( "target\tinitial\t%diff" )
    for c in 1:nc
        diffpc = 100*(initial_weighted_popn[c]-DEFAULT_TARGETS[c])/DEFAULT_TARGETS[c]
        println( "$c $(DEFAULT_TARGETS[c])\t$(initial_weighted_popn[c])\t$diffpc%")
    end

    # open( "data/scotmat.csv", "w" ) do io
    #     writedlm(io, data)
    # end

    for c in 1:nc
        @test( sum(data[:,c]) > 0 )
    end

    weights = generate_weights(nhh)

    weighted_popn = (weights' * data)'
    @test weighted_popn ≈ DEFAULT_TARGETS
end
