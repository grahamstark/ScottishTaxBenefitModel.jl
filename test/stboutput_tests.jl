using ScottishTaxBenefitModel
using .STBOutput
using DataFrames
using Test


settings = get_all_uk_settings_2023()
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

    w = [200,300,200,100,100]
    d = DataFrame( weight=w./2,i=[1,1,2,2,2],change=[10,2,4,5,3],change_bhc=[5,6,7,8,9],weighted_people=w)
    d.weighted_change = d.weighted_people.*d.change
    ogl = STBOutput.one_gain_lose( d, :i )
    println(ogl)
    @test ogl."Total Transfer £m" ≈ [(5+6)*250*WEEKS_PER_YEAR/1_000_000, 24*200*WEEKS_PER_YEAR/1_000_000]
    @test ogl."Average Change(£pw)" ≈ [5.2,4.0]
    @test sum( ogl."No Change") == 0
    @test sum( ogl."Gain £1.01-£10" ) == sum(d.weighted_people)

    d.change = [-20,-10,0,9,88]
    ogl = STBOutput.one_gain_lose( d, :i )
    @test sum( ogl."No Change") == 200
    @test sum( ogl."Lose £10.01+") == 200
    @test sum( ogl."Gain £10.01+") == 100
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
