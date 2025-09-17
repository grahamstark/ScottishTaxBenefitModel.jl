using ShareAdd

using ScottishTaxBenefitModel
using .DataSummariser
using .Definitions
using .FRSHouseholdGetter
using .HouseholdFromFrame
using .Intermediate
using .ModelHousehold
using .Monitor: Progress
using .Runner
using .Results
using .RunSettings
using .SingleHouseholdCalculations: do_one_calc
using .STBOutput
using .STBParameters

using .Utils
using .Weighting

@usingany UUIDs,CairoMakie,CSV,DataFrames,StatsBase,DataStructures,Pluto,Chairmarks

const DEFAULT_SYS = get_default_system_for_fin_year(2025; scotland=true)

obs = Observable( Progress(UUID("c2ae9c83-d24a-431c-b04f-74662d2ba07e"),"",0,0,0,0))
of = on(obs) do p
    global tot
    tot += p.step
    println(p)
end

function draw_mr_hists( systems :: Vector, results :: NamedTuple )
    f = Figure()
    ax = Axis(f[1,1],
        title="Marginal Effective Tax Rates", 
        xlabel=" METRs(%)", 
        ylabel="Freq" )
    i = 0
    for ind in results.indiv
        i += 1
        m1=ind[.! ismissing.(ind.metr),:]
        m1.metr = Float64.( m1.metr ) # Coerce away from missing type.
        # (correct) v. high MRs at cliff edges.
        m1.metr = min.( 200.0, m1.metr )
        density!( ax, m1.metr; label=systems[i].name, weights=m1.weight)
    end
    axislegend()
    f
end

function select_anomalies( results :: NamedTuple )::DataFrame
    ind = results.indiv[1]
    m1 = ind[.! ismissing.(ind.metr),:]
    fn=m1[m1.metr .> 10000,:]
    return fn[!,[:data_year,:hid,:pid]]
end

function examine_one_hh( hid :: BigInt, data_year::Int, sys :: TaxBenefitSystem, settings::Settings )::Tuple
    hh = FRSHouseholdGetter.get_household( hid, data_year )
    res = do_one_calc( hh, sys, settings )
    subres = nothing
    if settings.do_marginal_rates
        for (pid,pers) in hh.people
            if ( ! pers.is_standard_child) && ( pers.age <= settings.mr_rr_upper_age )
                pers.income[wages] += settings.mr_incr
                subres = do_one_calc( hh, sys, settings )            
                subhhinc = get_net_income( subres; target=settings.target_mr_rr_income )
                hhinc = get_net_income( res; target=settings.target_mr_rr_income )
                pres = get_indiv_result( res, pid )
                pres.metr = round( 
                    100.0 * (1-((subhhinc-hhinc)/settings.mr_incr)),
                    digits=7 )                           
                pers.income[wages] -= settings.mr_incr                        
                # println( "wage set back to $(pers.income[wages]) metr is $(pres.metr)")
            end # working age
        end # people
    end # do mrs
    hh, res, subres
end

function fes_settings()::Settings
    settings = Settings()
    settings.output_dir = "/home/graham_s/FES/"
    settings.do_marginal_rates = false
    settings.dump_frames = true
    settings.requested_threads = 6
    settings.do_replacement_rates = true
    settings.do_marginal_rates = true
    return settings
end

tot = 0

function fes_run( settings :: Settings, systems::Vector )::Tuple
    # delete higher rates
    global tot
    tot = 0
    results = nothing
    summaries = nothing 
    rtime = @be begin
        results = do_one_run( settings, systems, obs )
        summaries = summarise_frames!( results, settings )
    end
    dump_summaries( settings, summaries )
    @show Chairmarks.summarize( rtime )
    summaries, results
end

sys2 = deepcopy(SYS)
sys2.it.non_savings_rates = sys2.it.non_savings_rates[1:3]
sys2.it.non_savings_thresholds = sys2.it.non_savings_thresholds[1:2]
sys2.name = "All rates above 21% abolished."
sys3 = deepcopy(SYS)
sys3.it.non_savings_rates .-= 0.01
sys3.name = "1p less on all bands."
systems = [SYS,sys2,sys3]
settings = fes_settings()
@time settings.num_households, settings.num_people, nhh2 = 
    FRSHouseholdGetter.initialise( settings; reset=false )
    
label = "all-higher-rates-abolished"
settings.run_name="run-$(label)-$(date_string())"
summaries, results = fes_run( settings, systems )
