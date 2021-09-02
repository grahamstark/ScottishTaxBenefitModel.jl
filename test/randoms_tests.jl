using Test
using ScottishTaxBenefitModel: Randoms


@testset "Randoms" begin
    r1 = mybigrand()
    print( "r1 = $r1")
    c = randchunk( r1, 1 )
    print( "c=$c")
    b = testp( r1, 0.2, 1 )
    print( "b=$b" )
    if c < 20_000
        @test ! b 
    else
        @test b 
    end
end