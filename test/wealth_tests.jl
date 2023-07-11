using Test
using ScottishTaxBenefitModel
using .ModelHousehold
using .RunSettings
using StatsBase


@testset "simulated wealth distribution" begin
    num_households = 0
    settings = get_all_uk_settings_2023()
    rc = @timed begin
        num_households,total_num_people,nhh2 = 
            FRSHouseholdGetter.initialise( settings )
    end
    
    wealth = zeros( num_households )

    @time for hhno in 1:num_households
        hh = FRSHouseholdGetter.get_household( hhno )
        wealth[hhno] = hh.total_wealth
    end
    println( summarystats( wealth ))
end