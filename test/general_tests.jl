using Test
using ScottishTaxBenefitModel
using .Utils
using .Definitions

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

    @test Definitions.load_data_path( default="Fred", which=:model_data_dirxx ) == "Fred"
    if Sys.isunix()
        # @test Definitions.load_data_path( default="Fred", which=:model_data_dir ) == "/home/graham_s/julia/vw/ScottishTaxBenefitModel/data/"
    end
    if Sys.iswindows()
        @test Definitions.load_data_path( default="Fred", which=:model_data_dir ) == "C:\\Users\\gks56\\julia\\vw\\ScottishTaxBenefitModel\\data\\"
    end
end