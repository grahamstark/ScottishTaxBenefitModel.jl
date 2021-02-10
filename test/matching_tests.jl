using Test
using ScottishTaxBenefitModel
using .Utils:coarse_match

using DataFrames, CSV


function l_coarse_match( 
    recip :: DataFrameRow, 
    donor :: DataFrame, 
    vars  :: Vector{Symbol},
    max_matches :: Int,
    max_coarsens :: Int ) :: NamedTuple
    nobs = size( donor )[1]
    nvars = size( vars )[1]
    c_level = ones(Int,nvars)
    num_tries = zeros(Int,nobs)
    results = fill(-99,nobs,nvars)
    
    for row in 1:nobs
        for col in 1:nvars
            for cs in 1:max_coarsens
                sym = Symbol("$(String(vars[col]))_$(cs)")
                if(donor[row,sym] == recip[sym])
                    results[row,col] = cs
                    break;
                end
            end # coarsens
        end # match vars
    end # rows
    matches = fill( true, nobs )  
    quality = fill( 0, nobs )
    for row in 1:nobs
        for col in 1:nvars
            if results[row,col] == -99
                matches[row] = false
                quality[row] = -9
                break;
            else
                quality[row] += results[row,col]^2 # maybe
            end
        end
     end
     targetq = maximum( quality )
     nmatches = sum( matches )
     nvars = size( vars )[1]
     if( nmatches >= max_matches )||( nvars == 1 ) 
        return (matches=matches,quality=quality)
     end
     
end

#
# Donor and Recipient each have 2 fields `a` and `b` filled with random
# integers. 2 levels: _1 with exact numbers and 2 with 0/1 coarsened versions
# so matches can be, since both have to match & `a` is coarsened before `b`
# quality  a_1 a_2 b_1 b_2
#    1      X   -   X   - 
#    2      -   X   X   - 
#    3      -   -   X   X 

printrows= false

n = 10_000
donor = DataFrame( sernum=collect(1:n), a_1=rand(1:50,n), b_1=rand(100:1500,n))
# coarsend
donor.a_2 = (donor.a_1 .<= 25)
donor.b_2 = (donor.b_1 .<= 600)

m = 5_000
recip = DataFrame( sernum=collect(1:m), a_1=rand(2:50,m), b_1=rand(110:1700,m))
# coarsend
recip.a_2 = (recip.a_1 .<= 25)
recip.b_2 = (recip.b_1 .<= 600)
max_matches = 25


@testset "simple matching case" begin
    i = 0
    for r1 in eachrow(recip)
        # r1 = recip[1,:]
        i += 1
        if i > 250
            break
        end
        if printrows
            println("r1=$r1")
        end
        matches = l_coarse_match( 
            r1,
            donor,
            [:a, :b],
            max_matches,
            2 )
        # println(matches)
        donor.quality = matches.quality
        matchedrows = donor[matches.matches,:]
        # @test sum( matches.matches ) >= max_matches
        n = 0
        for match in eachrow( matchedrows )
            if printrows
                println( "on match=$(match)" )
            end
            @test match.quality in 1:8
            if match.quality == 2                                  
                @test (match.a_1 == r1.a_1)&&(match.b_1 == r1.b_1) # `a` and `b` should match fine.
            elseif match.quality == 5
                @test ! ((match.a_1 == r1.a_1)&&(match.b_1 == r1.b_1)) # can't be a q=1 match
                @test ((match.a_2 == r1.a_2)&&(match.b_1 == r1.b_1)||
                       (match.a_1 == r1.a_1)&&(match.b_2 == r1.b_2))# should be a_2 matches coarse, b_1 matches fine
            elseif match.quality == 8
                if printrows
                    println( "q=3; r1=$r1" )
                    println( "q=3; match=$match" )
                end
                @test ! ((match.a_1 == r1.a_1)&&(match.b_1 == r1.b_1)) # can't be a q=1 match
                @test ! ((match.a_2 == r1.a_2)&&(match.b_1 == r1.b_1)) # can't be a q=2 match
                @test (match.a_2 == r1.a_2)&&(match.b_2 == r1.b_2) # should be `a` and `b` match coarse
            end                                       
            
        end
    end # each recipient
end # testset

