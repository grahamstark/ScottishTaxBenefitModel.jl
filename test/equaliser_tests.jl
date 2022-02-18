using Test
using ScottishTaxBenefitModel
using Observables
using .ModelHousehold: count,Household, le_age, ge_age
using .Results: aggregate!, init_household_result
using ScottishTaxBenefitModel.Runner: do_one_run
using .Intermediate: MTIntermediate, make_intermediate    
using .UBI: calc_UBI!,make_ubi_post_adjustments! 
using .STBParameters
using .STBIncomes
using .ExampleHelpers
using .Monitor: Progress
using .TheEqualiser
using .STBOutput

sys = get_system( scotland=true )
sys.ubi.abolished = false

settings = Settings()
settings.do_marginal_rates = false
settings.poverty_line=100.0 # arbit

# observer = Observer(Progress("",0,0,0))
tot = 0
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)

    tot += p.step
    println(tot)
end

@testset "Eq UBI Tests" begin
    base = get_system( scotland = true )
    sys = get_system( scotland = true )
    sys.ubi.abolished = false
    base_res = do_one_run(
        settings,
        [base],
        obs )
    summary = summarise_frames(base_res,settings)
    base_cost = summary.income_summary[1][1,:net_cost]
    
    eq = equalise( 
        eq_it, 
        sys, 
        settings, 
        base_cost, 
        obs )
    println( "needs tax rise of $eq")
    sys.it.non_savings_rates .+= eq
    ubi_res = do_one_run(
        settings,
        [sys],
        obs )
    ubi_summary = summarise_frames(ubi_res,settings)
    ubi_cost = ubi_summary.income_summary[1][1,:net_cost]
   
    net_cost = ubi_cost - base_cost
    println( "net_cost=$net_cost" )
  
end