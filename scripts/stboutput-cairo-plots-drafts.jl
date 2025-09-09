@usingany CSV
@usingany DataFrames
@usingany StatsBase
@usingany PovertyAndInequalityMeasures
@usingany Observables
@usingany CairoMakie
@usingany GLM
@usingany Pluto

# include("landman-to-sb-mappings.jl")

pv = PovertyAndInequalityMeasures # shortcut

using ScottishTaxBenefitModel
using 
    .DataSummariser,
    .Definitions,
    .FRSHouseholdGetter,
    .HouseholdFromFrame,
    .ModelHousehold,
    .Monitor, 
    .Results,
    .Runner, 
    .RunSettings,
    .SingleHouseholdCalculations,
    .STBIncomes,
    .STBOutput,
    .STBParameters,
    .Uprating,
    .Utils,
    .Weighting


# one run of scotben 24 sys
tot = 0
obs = Observable( Progress(Base.UUID("c2ae9c83-d24a-431c-b04f-74662d2ba07e"),"",0,0,0,0))
Observable(Progress(Base.UUID("c2ae9c83-d24a-431c-b04f-74662d2ba07e"), "", 0, 0, 0, 0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
    println(tot)
end
sys = STBParameters.get_default_system_for_fin_year( 2025 )

function onerun( settings::Settings, systems :: Vector )::Tuple
    global tot
    settings.num_households, settings.num_people, nhhs2 = 
            FRSHouseholdGetter.initialise( settings; reset=false )
    res = Runner.do_one_run( settings, systems, obs )
    summary = summarise_frames!( res, settings )
    return summary, res
end


function colourbins( input_colours, bins::Vector, deciles::Matrix )
    nbins = length(bins)-1
    colours = fill(input_colours[1],nbins)
    colour = colours[1]
    decile = 1
    colourno = 1
    for i in 1:nbins
        colours[i] = input_colours[colourno]
        if bins[i] >= deciles[decile,3]
            colourno = if colourno == 1
                2
            else 
                1
            end
            decile += 1
        end
    end
    colours
end


function draw_hbai_clone!( 
    f :: Figure, 
    res :: NamedTuple, 
    summary :: NamedTuple; 
    sysno::Int, 
    measure::Symbol, 
    colours )
    edges = collect(0:10:2200)
    ih = summary.income_hists[1]
    ax = Axis( f[1,sysno], title="HBAI Clone Experiment", 
        xlabel="£s pw", 
        ylabel="Count")
    deciles = summary.deciles[sysno]
    deccols = colourbins( colours, edges, deciles ) #ih.hist.edges[1], summary.deciles[1])
    incs = deepcopy(res.hh[sysno][!,measure])
    incs = max.( 0.0, incs )
    incs = min.(2200, incs )
    h = hist!( ax, 
        incs;
        weights=res.hh[1].weighted_people,
        bins=edges, 
        color = deccols )
    v1 = lines!( ax, [ih.median,ih.median], [0, 350_000]; color=:grey16, label="Median", linestyle=:dash )
    v2 = lines!( ax, [ih.mean,ih.mean], [0, 350_000]; color=:chocolate4, label="Mean", linestyle=:dash )
    if sys == 1
        axislegend(ax)
    end
end


settings = Settings()
settings.weighting_relative_to_ons_weights = true
settings.requested_threads = 4
settings.lower_multiple,
settings.upper_multiple = if settings.weighting_relative_to_ons_weights
    0.65, 3.7
else
    0.62, 5.8
end
sys = STBParameters.get_default_system_for_fin_year( 2025 )
summ, res = onerun( settings, [sys, sys])

function draw_hbai_clone!( 
    f :: Figure, 
    res :: NamedTuple, 
    summary :: NamedTuple; 
    bandwidth=10.0,
    sysno::Int, 
    measure::Symbol, 
    colours )
    edges = collect(0:bandwidth:2200)
    ih = summary.income_hists[1]
    ax = Axis( f[sysno,1], title="HBAI Clone Experiment", 
        xlabel="£s pw", 
        ylabel="Count")
    deciles = summary.deciles[sysno]
    deccols = colourbins( colours, edges, deciles ) #ih.hist.edges[1], summary.deciles[1])
    incs = deepcopy(res.hh[sysno][!,measure])
    incs = max.( 0.0, incs )
    incs = min.(2200, incs )
    h = hist!( ax, 
        incs;
        weights=res.hh[1].weighted_people,
        bins=edges, 
        color = deccols )
    mheight=12_000*bandwidth # arbitrary height for mean/med lines
    v1 = lines!( ax, [ih.median,ih.median], [0, mheight]; color=:grey16, label="Median", linestyle=:dash )
    v2 = lines!( ax, [ih.mean,ih.mean], [0, mheight]; color=:chocolate4, label="Mean", linestyle=:dash )
    if sysno == 1
        axislegend(ax)
    end
end


function draw_hbai_thumbnail!( 
    f :: Figure, 
    res :: NamedTuple, 
    summary :: NamedTuple;
    xpos = 1,
    ypos = 2,
    bandwidth=20.0,
    sysno::Int, 
    measure::Symbol, 
    colours )
    edges = collect(0:bandwidth:2200)
    ih = summary.income_hists[1]
    ax = Axis( f[xpos,ypos], title="HBAI Clone Experiment")
    deciles = summary.deciles[sysno]
    deccols = colourbins( colours, edges, deciles ) #ih.hist.edges[1], summary.deciles[1])
    incs = deepcopy(res.hh[sysno][!,measure])
    incs = max.( 0.0, incs )
    incs = min.(2200, incs )
    h = hist!( ax, 
        incs;
        weights=res.hh[1].weighted_people,
        bins=edges, 
        color = deccols )
end


hbaif = Figure()
draw_hbai_clone!( hbaif, res, summ;
    sysno = 1,
    measure=Symbol(string(settings.ineq_income_measure )),
    colours=[:lightsteelblue3, :lightslategray])
draw_hbai_thumbnail!( hbaif, res, summ;
    sysno = 2,
    bandwidth=20,
    measure=Symbol(string(settings.ineq_income_measure )),
    colours=[:lightsteelblue3, :lightslategray])

save("hbai-clone.svg", hbaif )


hbaif = Figure()
draw_hbai_clone!( hbaif, res, summ;
    sysno = 1,
    measure=Symbol(string(settings.ineq_income_measure )),
    colours=[:lightsteelblue3, :lightslategray])
draw_hbai_clone!( hbaif, res, summ;
    sysno = 2,
    bandwidth=20,
    measure=Symbol(string(settings.ineq_income_measure )),
    colours=[:lightsteelblue3, :lightslategray])

save("hbai-clone.svg", hbaif )
hbaif
    

