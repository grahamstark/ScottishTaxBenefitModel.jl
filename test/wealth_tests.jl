using Test
using ScottishTaxBenefitModel
using .Inferences: infer_wealth!
using .ModelHousehold
using .OtherTaxes: calculate_other_taxes!
using .Results
using .RunSettings
using .STBIncomes

using StatsBase


@testset "Wealth Tax" begin
    sys = get_system( year=2023, scotland=true )
    sys.othertaxes.wealth_tax = 0.01
    hh = make_hh()
    println( INCOME_TAXES )
    for w in [0,1_000,100_000.0,1_000_000.0]
        hh.total_wealth = w
        hres = init_household_result( hh )
        calculate_other_taxes!( hres, hh, sys.othertaxes )
        aggregate!( hh, hres )
        @test hres.income[OTHER_TAX] ≈ w*sys.othertaxes.wealth_tax
        println( "hres.bhc_net_income=$(hres.bhc_net_income)" )
    end
end

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

    println( "north_east", ":",mean( was.north_east ))
    println( "north_west", ":",mean( was.north_west ))
    println( "yorkshire", ":",mean( was.yorkshire ))
    println( "east_midlands", ":",mean( was.east_midlands ))
    println( "west_midlands", ":",mean( was.west_midlands ))
    println( "east_of_england", ":",mean( was.east_of_england ))
    println( "london", ":",mean( was.london ))
    println( "south_east", ":",mean( was.south_east ))
    println( "south_west", ":",mean( was.south_west ))
    println( "wales", ":",mean( was.wales ))
    println( "scotland", ":",mean( was.scotland ))
    
    println( "hrp_u_25", ":",mean( was.hrp_u_25 ))
    println( "hrp_u_35", ":",mean( was.hrp_u_35 ))
    println( "hrp_u_45", ":",mean( was.hrp_u_45 ))
    println( "hrp_u_55", ":",mean( was.hrp_u_55 ))
    println( "hrp_u_65", ":",mean( was.hrp_u_65 ))
    println( "hrp_u_75", ":",mean( was.hrp_u_75 ))
    println( "hrp_75_plus", ":",mean( was.hrp_75_plus ))
    println( "weekly_net_income", ":",mean( was.weekly_net_income ))
    println( "owner", ":",mean( was.owner ))
    println( "mortgaged", ":",mean( was.mortgaged ))
    println( "renter", ":",mean( was.renter ))
    println( "detatched", ":",mean( was.detatched ))
    println( "semi", ":",mean( was.semi ))
    println( "terraced", ":",mean( was.terraced ))
    println( "purpose_build_flat", ":",mean( was.purpose_build_flat ))
    println( "converted_flat", ":",mean( was.converted_flat ))
    println( "ctamtr7", ":",mean( was.ctamtr7 ))
    println( "managerial", ":",mean( was.managerial ))
    println( "intermediate", ":",mean( was.intermediate ))
    println( "routine", ":",mean( was.routine ))
    println( "total_wealth", ":",mean( was.total_wealth ))
    println( "num_children", ":",mean( was.num_children ))
    println( "num_adults", ":",mean( was.num_adults ))
    
end