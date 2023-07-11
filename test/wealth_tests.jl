using Test
using ScottishTaxBenefitModel
using .Inferences: infer_wealth!
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
    v = nothing
    wealth = zeros( num_households )
    regressors = zeros( num_households, 28 )
    @time for hhno in 1:num_households
        hh = FRSHouseholdGetter.get_household( hhno )
        v = infer_wealth!( hh  )
        hrp = get_head(hh)
        # println(hrp.socio_economic_grouping)
        wealth[hhno] = hh.total_wealth
        # println(v[:,2]')
        regressors[hhno,:] = v[:,2]'
    end
    println( summarystats( wealth ))

    for c in 1:28
        s = sum( regressors[:,c])/num_households
        l = v[c,1]
        println( " avg(reg[$l]) = $s" )
    end

    include( "../regressions/wealth_regressions.jl")


end