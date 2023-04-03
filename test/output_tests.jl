using Test
using CSV
using DataFrames
using StatsBase
using BenchmarkTools
using PrettyTables

using ScottishTaxBenefitModel
using ScottishTaxBenefitModel.RunSettings: Settings, MT_Routing
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames!, make_gain_lose

@testset "basic gain lose" begin
    pre = DataFrame( income=[1,2,3], weighted_people=[1,1,1]);
    post = DataFrame( income=[3,2,1], weighted_people=[1,1,1]);
    gl = make_gain_lose( pre, post, :income )
    @test gl.gainers == 1
    @test gl.losers == 1
    @test gl.nc == 1
    @test gl.popn == 3
end

@testset "povery line" begin

end