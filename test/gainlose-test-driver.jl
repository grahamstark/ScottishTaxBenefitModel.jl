using ScottishTaxBenefitModel
using .STBParameters,.STBOutput,.RunSettings,.Runner
using .Monitor: Progress

using StatsBase,Observables,DataFrames,PrettyTables

settings = Settings()
@time settings.num_households, settings.num_people, nhh2 = FRSHouseholdGetter.initialise( settings; reset=false )
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
tot = 0
of = on(obs) do p
    global tot
    println(p)

    tot += p.step
    println(tot)
end

sys1 = get_default_system_for_fin_year( 2025; scotland=true )
sys2 = get_default_system_for_fin_year( 2025; scotland=true, autoweekly=false )
# turn on the ppt ...
sys2.loctax.ppt.abolished = false
# .. and turn off CT
sys2.loctax.ct.abolished = true
sys2.loctax.ppt.local_bands = []
sys2.loctax.ppt.local_rates = [0.7]
weeklyise!(sys2)

frames = Runner.do_one_run( settings, [sys1,sys2] ,obs );
summary = summarise_frames!( frames, settings );


gls2=STBOutput.make_gain_lose(;
    prehh=frames.hh[1],
    posthh=frames.hh[2],
    incomes_col=Symbol( settings.ineq_income_measure))
