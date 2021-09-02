using Test
using ScottishTaxBenefitModel
using .Randoms


@testset "Randoms" begin
    rm  = "123456789"
    @test randchunk( rm, 1 ) ≈ 0.12345
    @test randchunk( rm, 1, 9 ) ≈ 0.123456789
    @test testp( rm, 0.2346, 2 ) # random from string is less than thresh
    @test ! testp( rm, 0.2344, 2 ) # random from string is > thresh
    r1 = strtobi(mybigrand())
    print( "r1 = $r1")
    c = randchunk( r1, 1 )
    print( "c=$c")
    b = testp( r1, 0.2, 1 )
    print( "b=$b" )
    if c > 0.2
        @test ! b 
    else
        @test b 
    end

    t = 0
    n = 1_000_000
    for i in 1:n
        r = strtobi(mybigrand())
        if testp( r, 0.2, 10 )
            t += 1
        end
    end
    pr = t/n
    @test isapprox( pr, 0.2, atol=0.0001)

end