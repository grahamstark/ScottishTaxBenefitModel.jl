import Test: @testset, @test

using ScottishTaxBenefitModel

using .FRSHouseholdGetter: 
    get_household, 
    get_num_households,
    initialise

using .ModelHousehold: 
    Household, 
    Person

using .Weighting: 
    DEFAULT_TARGETS, 
    generate_weights, 
    initialise_target_dataframe,
    make_target_dataset
using .ExampleHelpers
    
using CSV
using Tables

start_year=2015

println( "num_households=$(get_num_households())")

#if get_num_households() == 0
@time nhh,total_num_people,nhh2 = initialise( DEFAULT_SETTINGS )

#end

function lsum(v::Vector)
    reduce(+,v)
end

@testset "weighting tests" begin
    nhh = get_num_households()
    hhlds_in_popn = lsum( DEFAULT_TARGETS[42:48]) # sum of all hhld types
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

    open( "scotmat.csv", "w" ) do io
         CSV.write(io, Tables.table(data))
    end

    for c in 1:nc
        @test( sum(data[:,c]) > 0 )
    end

    @time weights = generate_weights(nhh)

    weighted_popn = (weights' * data)'
    @test weighted_popn ≈ DEFAULT_TARGETS
    for c in 1:nc
        diffpc = 100*(weighted_popn[c]-DEFAULT_TARGETS[c])/DEFAULT_TARGETS[c]
        println( "$c $(DEFAULT_TARGETS[c])\t$(weighted_popn[c])\t$diffpc%")
    end

end
