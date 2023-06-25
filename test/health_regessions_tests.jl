using Test

using ScottishTaxBenefitModel

using .Definitions
using .ModelHousehold
using .Results
using .ExampleHelpers
using .HealthRegressions: get_sf_6d

@testset "get_death_prob" begin
   

end

@testset "get_sfd6 Examples" begin
    # just make something up pro. tem.
    quintiles = [100,200,300,400,50000000]

    for (hht,hh) in get_all_examples()
        for inc in quintiles
            inc -= 1
            sf16 = get_sf_6d( hh = hh, eq_bhc_net_income=inc, quintiles=quintiles )
            for (pid,sf) in sf16
                @test 0 < sf6 < 1
                pers = hh.people[pid]
                println( "income $inc hh $hht age $(pers.age) sex $(pers.sex) sf $sf")
            end # people in hh
        end # quintiles
    end # example loop
end

@testset "get_sfd6 Live Data" begin
    

    
end