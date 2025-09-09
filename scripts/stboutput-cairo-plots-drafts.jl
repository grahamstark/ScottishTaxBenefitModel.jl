@usingany CSV
@usingany DataFrames
@usingany StatsBase
@usingany PovertyAndInequalityMeasures
@usingany Observables
@usingany CairoMakie
@usingany GLM
@usingany Pluto
@usingany Format

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
    decile = 1
    colourno = 1
    for i in 1:nbins
        if bins[i] > deciles[decile,3]
            colourno = if colourno == 1
                2
            else 
                1
            end
            decile += 1
        end
        colours[i] = input_colours[colourno]        
    end
    colours
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


function ft(v::Vector) 
    return Format.format.(v./1000; precision=0, commas=true).*"k"
end

f2(v) = Format.format(v, precision=2, commas=true)

f0(v) = Format.format(v, precision=0, commas=true)

function draw_hbai_clone!( 
    f :: Figure, 
    res :: NamedTuple, 
    summary :: NamedTuple; 
    title :: AbstractString,
    subtitle :: AbstractString,
    bandwidth=10.0,
    sysno::Int, 
    measure::Symbol, 
    colours )
    edges = collect(0:bandwidth:2200)
    ih = summary.income_hists[1]
    ax = Axis( f[sysno,1], 
        title=title, 
        subtitle=subtitle,
        xlabel="£s pw, in £$(f0(bandwidth)) bands; shaded bands represent deciles.", 
        ylabel="Counts",
        ytickformat = ft)
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
    mheight=36_000*bandwidth # arbitrary height for mean/med lines
    povline = ih.median*0.6
    v1 = lines!( ax, [ih.median,ih.median], [0, mheight]; color=:grey16, label="Median £$(f2(ih.median))", linestyle=:dash )
    v2 = lines!( ax, [ih.mean,ih.mean], [0, mheight]; color=:chocolate4, label="Mean £$(f2(ih.mean))", linestyle=:dash )
    v3 = lines!( ax, [povline,povline], [0, mheight]; color=:olivedrab4, label="60% of median £$(f2(povline))", linestyle=:dash )
    axislegend(ax)
    return ax
end


function draw_hbai_thumbnail!( 
    f :: Figure, 
    res :: NamedTuple, 
    summary :: NamedTuple;
    title :: AbstractString,
    col = 1,
    row = 2,
    bandwidth=20.0,
    sysno::Int, 
    measure::Symbol, 
    colours )
    edges = collect(0:bandwidth:2200)
    ih = summary.income_hists[1]
    ax = Axis( f[row,col], title=title, yticklabelsvisible=false)
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
    mheight=36_000*bandwidth # arbitrary height for mean/med lines
    povline = ih.median*0.6
    v1 = lines!( ax, [ih.median,ih.median], [0, mheight]; color=:grey16, label="Median £$(f2(ih.median))", linestyle=:dash )
    v2 = lines!( ax, [ih.mean,ih.mean], [0, mheight]; color=:chocolate4, label="Mean £$(f2(ih.mean))", linestyle=:dash )
    v3 = lines!( ax, [povline,povline], [0, mheight]; color=:olivedrab4, label="60% of median £$(f2(povline))", linestyle=:dash )
    return ax
end

# 2nd bit is opacity
const PRE_COLOURS = [(:lightsteelblue3, 0.5) (:lightslategray,0.5)]
const POST_COLOURS = [(:peachpuff, 0.5) (:peachpuff3,0.5)]

hbaif1 = Figure(size=(742,525), fontsize = 10, fonts = (; regular = "Gill Sans"))
ax1 = draw_hbai_clone!( hbaif1, res, summ;
    title="Pre",
    subtitle = INEQ_INCOME_MEASURE_STRS[settings.ineq_income_measure ],
    sysno = 1,
    measure=Symbol(string(settings.ineq_income_measure )),
    colours=PRE_COLOURS)
ax2 = draw_hbai_thumbnail!( hbaif1, res, summ;
    title="Post",
    sysno = 2,
    bandwidth=20,
    measure=Symbol(string(settings.ineq_income_measure )),
    colours=POST_COLOURS)
linkxaxes!( ax1,ax2 )
save("hbai-clone-1.svg", hbaif1 )

hbaif2 = Figure(size=(2970,2100), fontsize = 25, fonts = (; regular = "Gill Sans"))
draw_hbai_clone!( hbaif2, res, summ;
    title="Incomes: Pre",
    subtitle=INEQ_INCOME_MEASURE_STRS[settings.ineq_income_measure ],
    sysno = 1,
    measure=Symbol(string(settings.ineq_income_measure )),
    colours=PRE_COLOURS)
draw_hbai_clone!( hbaif2, res, summ;
    title="Incomes: Post",
    subtitle=INEQ_INCOME_MEASURE_STRS[settings.ineq_income_measure ],
    sysno = 2,
    bandwidth=20,
    measure=Symbol(string(settings.ineq_income_measure )),
    colours=POST_COLOURS)

save("hbai-clone-2.svg", hbaif2 )
hbaif2
    
