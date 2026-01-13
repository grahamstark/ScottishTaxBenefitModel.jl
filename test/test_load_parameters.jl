using Test
using ScottishTaxBenefitModel
using .STBParameters

@testset "Load Everything" begin
    for year in 2019:2026
        for scotland in [false,true]
            for autoweekly in [false,true]
                sys = get_default_system_for_fin_year( 
                    year; 
                    scotland=scotland, 
                    autoweekly=autoweekly )
                @test typeof(sys.scottish_child_payment.amounts) <: AbstractArray
                @test typeof(sys.scottish_child_payment.maximum_ages) <: AbstractArray
                @test eltype(sys.scottish_child_payment.amounts) <: AbstractFloat
                @test eltype(sys.scottish_child_payment.maximum_ages) <: Integer
            end
        end
    end
end
