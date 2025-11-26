using Test
using ScottishTaxBenefitModel
using .Utils
using .Definitions
using .GeneralTaxComponents

@enum A a b c d e

@testset "tests of miscellaneous functions" begin
    gr = Dict{A,Real}( a=>1.0, b=>2, e=> 4.1 )
    ne = Dict{A,Real}( c=>2, b=>9 )
    inc = Dict{A,Real}( a=>1, b=>1.0, c=>1, d =>1 )
    m = mult( data=gr, calculated=ne, included=inc )
    @test m == 12

    pid = 120181906404
    p = from_pid( pid )
    @test p.datasource == FRSSource
    @test p.year == 2018
    @test p.hid == 19064
    @test p.pno == 4

end

@testset "Stepped Tax" begin
    hval = [500_000.0, 1_000_001, 6_000_001]
    due = [0.0, 2000, 5000]
    rates = [0, 2000.0, 5000.0]
    bands = [1_000_000, 6_000_000]
    for i in eachindex(hval)
        sv = do_stepped_tax_calculation(
                taxable=hval[i],
                rates=rates,
                bands=bands,
                fixed_sum = true )
        @show sv
        @test sv.due == due[i]
    end
end