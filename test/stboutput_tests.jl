using ScottishTaxBenefitModel
using Observables
using .STBOutput
using .RunSettings
using .GeneralTaxComponents
using .STBParameters
using .Runner: do_one_run
using .RunSettings
using .Utils
using .Monitor: Progress
using .ExampleHelpers

using DataFrames
using Test


settings = RunSettings.get_all_uk_settings_2023()
settings.do_marginal_rates = false
settings.poverty_line=100.0 # arbit

# observer = Observer(Progress("",0,0,0))
tot = 0
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)

    tot += p.step
    # println(tot)
end

@testset "basic gain lose tests" begin
    change = [10,2,4,5,3]
    change_bhc = [5,6,7,8,9]
    w = [200,300,200,100,100]
    people = [2,2,2,2,2]
    weighted_people = w .* people
    weighted_bhc_change = w .* change_bhc
    people_weighted_change = weighted_people .* change
    d = DataFrame( 
        weight                 = w,
        change                 = change,
        i                      = [1,1,2,2,2],
        people_weighted_change = people_weighted_change,
        weighted_bhc_change    = weighted_bhc_change,
        weighted_people        = weighted_people )
    ogl = STBOutput.one_gain_lose( d, :i )
    println(ogl)
    @test ogl."Total Transfer £m" ≈ [sum(weighted_bhc_change[1:2])*WEEKS_PER_YEAR/1_000_000, sum(weighted_bhc_change[3:5])*WEEKS_PER_YEAR/1_000_000]
    @test ogl."Average Change(£pw)" ≈ [5.2,4.0]
    @test sum( ogl."No Change") == 0
    @test sum( ogl."Gain £1.01-£10" ) == sum(d.weighted_people)

    d.change = [-20,-10,0,9,88]
    ogl = STBOutput.one_gain_lose( d, :i )
    @test sum( ogl."No Change") == 400
    @test sum( ogl."Lose £10.01+") == 400
    @test sum( ogl."Gain £10.01+") == 200
    println(ogl)
end

function avs(x::AbstractMatrix):Real
    s = 0
    nr,nc = size(x)
    for i in 2:nr
        s += sum(x[i,2:nc-1])*x[i,nc]
    end
    s *= 1000*365.25/7
end


@testset "gain/lose on real data" begin



end
