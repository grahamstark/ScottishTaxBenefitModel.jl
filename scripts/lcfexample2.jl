using DataFrames,CSV,GLM,Statistics


# Pkg.add( "ORCA")

using Plots, PlotlyJS
using Revise
using Unicode

plotlyjs()

DD226 = "/home/graham_s/OU/DD226/docs/"

# see https://github.com/JuliaPlots/Plots.jl/issues/897
# upscale = 2#8x upscaling in resolution
# fntsm = Plots.font("sans-serif", pointsize=round(10.0*upscale))
# fntlg = Plots.font("sans-serif", pointsize=round(14.0*upscale))
#default(titlefont=fntlg, guidefont=fntlg, tickfont=fntsm, legendfont=fntsm)
#default(size=(800*upscale,600*upscale)) #Plot canvas size
#default(dpi=300) #Only for PyPlot - presently broken


"""
a_string_or_symbol_like_this => "A String Or Symbol Like This"
"""
function pretty(a)
   s = string(a)
   s = strip(lowercase(s))
   s = replace(s, r"[_]" => " ")
   Unicode.titlecase(s)
end

kids_colour = "#ff762e"
kids_line_colour = "#aa360e" # "#ff762e"
nokids_colour = "#007aaf"
nokids_line_colour = "#0046af"

lcf = CSV.File( "$(DD226)activities/activity_3.csv") |> DataFrame
lcf = lcf[ (lcf.total_expend .< 3_000 ), : ] # chop off some outliers

CSV.write( "$(DD226)activities/activity_3_3000_max.csv", lcf )

exp_items = [
    "food_and_drink",
    "alcohol_tobacco",
    "clothing",
    "housing",
    "household_goods",
    "health",
    "transport",
    "communication",
    "recreation",
    "education",
    "restaurants_etc",
    "miscellaneous",
    "non_consumption"
    ]

for e in exp_items
    exp_s = Symbol(e)
    share_s = Symbol( "share_$(e)")
    lcf[!,share_s] = lcf[!,exp_s]./lcf[!,:total_expend]
end

lcf[!,:has_kids] = lcf[!,:age_u_18].>0

# shares and levels by kids
for sub in groupby(lcf,:has_kids)
    avg_food = mean(sub.food_and_drink)
    sh_food = mean(sub.share_food_and_drink)
    has_kids = maximum(sub.has_kids)
    println( "$has_kids $avg_food  $sh_food ")
end

lcf[!,:log_total_expend] = log.(lcf.total_expend)

# subsamples with/o kids
lcf_kids = lcf[(lcf.age_u_18 .> 0),:]
lcf_nokids = lcf[(lcf.age_u_18 .== 0),:]

println( mean( lcf_kids.share_food_and_drink))

println( mean( lcf_nokids.share_food_and_drink))

food_share_kids = lm( @formula( share_food_and_drink ~ total_expend), lcf_kids )

food_share_nokids = lm( @formula( share_food_and_drink ~ total_expend), lcf_nokids )

food_share_nokids = lm( @formula( share_food_and_drink ~ total_expend ), lcf_nokids )

food_share_kid_dummy = lm( @formula( share_food_and_drink ~ total_expend+has_kids), lcf )

food_share_kids_log = lm( @formula( share_food_and_drink ~ log_total_expend), lcf_kids )

food_share_nokids_log = lm( @formula( share_food_and_drink ~ log_total_expend), lcf_nokids )

food_share_nokids_log = lm( @formula( share_food_and_drink ~ log_total_expend), lcf_nokids )

food_share_kid_dummy_log = lm( @formula( share_food_and_drink ~ log_total_expend+has_kids), lcf )

median( lcf.total_expend)
mean(lcf.total_expend)

mdall = median( lcf.share_food_and_drink)
mean(lcf.share_food_and_drink)
median( lcf_kids.share_food_and_drink)
mean(lcf_kids.share_food_and_drink)
median( lcf_nokids.share_food_and_drink)
mean(lcf_nokids.share_food_and_drink)

function draw_graph( lcf :: DataFrame, item :: AbstractString, coeffs ::  AbstractArray )
    exp_s = Symbol(item)
    share_s = Symbol( "share_$(item)")
    label = pretty( item )
    pl1 = Plots.plot(
        lcf.total_expend,
        lcf[!,share_s],
        label = label,
        title="$label",
        xlabel = "Total Spending in £pw",
        ylabel = "$label Share",
        line=:scatter,
        markeralpha=0.5,
        linecolor=kids_colour,
        seriescolor=kids_colour,
        markersize=1,
        marker=:dot,
        markerstrokewidth=0,
        markercolor=kids_colour)

    exps = 30:1:3_000

    regression = coeffs[1].+(coeffs[2].*log.(exps))
    Plots.plot!(
        pl1,
        exps,
        regression,
        label = "$label Engel Curve",
        line=kids_line_colour)
    pl1
end

function draw_all_graphs( dataf :: DataFrame, results :: Dict ) :: Dict
    rhs = [1,:log_total_expend]
    graphs = Dict()
    for e in exp_items
       exp_s = Symbol(e)
       share_s = Symbol( "share_$(e)")
       graphs[ share_s ] = draw_graph( dataf, e, coef(results[share_s]))
    end
    graphs
end


function make_predictions!( dataf :: DataFrame )
    rhs = [1,:log_total_expend]
    results = Dict()
    for e in exp_items
       exp_s = Symbol(e)
       share_s = Symbol( "share_$(e)")
       predicted_s = Symbol( "predicted_$(e)")
       lhs = term( share_s )
       rhst = term.(rhs)
       f = lhs ~ foldl( +, rhst )
       results[share_s] = lm( f, dataf )
       dataf[!,predicted_s] = predict(results[share_s],dataf)
    end
    results
end

full_results = make_predictions!( lcf )
all_graphs = draw_all_graphs( lcf, full_results )

kid_results = make_predictions!( lcf_kids )

nokid_results = make_predictions!( lcf_nokids )


#
# pyplot()
#

pl1 = Plots.plot(
    lcf_kids.total_expend,
    lcf_kids.share_food_and_drink,
    label = "With Children",
    title="Food Engel Curves",

    xlabel = "Total Spending in £pw",
    ylabel = "Food Share",
    line=:scatter,
    markeralpha=0.5,
    linecolor=kids_colour,
    seriescolor=kids_colour,
    markersize=1,
    marker=:dot,
    markerstrokewidth=0,
    markercolor=kids_colour)
Plots.plot!(
    pl1,
    lcf_nokids.total_expend,
    lcf_nokids.share_food_and_drink,
    label = "Without Children",
    line=:scatter,
    markeralpha=0.5,
    linecolor=nokids_colour,
    seriescolor=nokids_colour,
    markersize=1,
    marker=:dot,
    markerstrokewidth=0,
    markercolor=nokids_colour)

exps = 20:1:3_000

coeffs_kids = coef(kid_results[:share_food_and_drink])
regression_kids = coeffs_kids[1].+(coeffs_kids[2].*log.(exps))
Plots.plot!(
    pl1,
    exps,
    regression_kids,
    label = "With Children Engel Curve",
    line=kids_line_colour)

coeffs_nokids = coef(nokid_results[:share_food_and_drink])
regression_nokids = coeffs_nokids[1].+(coeffs_nokids[2].*log.(exps))
Plots.plot!(
    pl1,
    exps,
    regression_nokids,
    label = "Without Children Engel Curve",
    line=:line,
    linecolor=nokids_line_colour )

function total_for_share( share :: Real; α :: Real, β :: Real ) :: Real
    exp( (share-α)/β)
end

inc_kids = total_for_share( mdall, α=coeffs_kids[1], β=coeffs_kids[2])
inc_nokids = total_for_share( mdall, α=coeffs_nokids[1], β=coeffs_nokids[2])

v = zeros(size(exps)[1])
v .= mdall
Plots.plot!(
   pl1,
   exps,
   v,
   label = "Median Food Share",
   line=:line,
   linewidth=2,
   linestyle=:dot,
   linecolor=:black )

Plots.plot!(
   pl1,
   [inc_kids, inc_kids],
   [0.0, mdall ],
   annotations=(inc_kids, 0, Plots.text("B", pointsize=8, halign=:right, valign=:center, font=:serif, color=kids_line_colour)),
    label = "",
   linestyle=:dot,
    line=:line,
    linewidth=2,
   linecolor=:black )

Plots.plot!(
  pl1,
  [inc_nokids, inc_nokids],
  [0.0, mdall ],
  annotations=(inc_nokids, 0, Plots.text("A", pointsize=8, halign=:right, valign=:center, font=:serif, color=nokids_line_colour)),
  label="",
  line=line,
  linestyle=:dot,
  linewidth=2,
  linecolor=:black )

Plots.savefig( pl1, "food_and_drink_engel_curve.png" )

s = "<table>\n"
n  = 0
for( k, v ) in all_graphs
    global n, s
    n += 1
    if (n % 2 == 1)
        s *= "    <tr>"
    end
    ks = String(k)*"_single.png"
    s *= "<td><img src='/images/$ks' alt='Engel curve'/></td>"
    if n % 2 == 0
        s *= "</tr>\n"
    end
end
s *= "<table>\n"
println(s)

Plots.savefig( pl1, "food_and_drink_engel_curve.png" )

for( k, v ) in all_graphs
    ks = String(k)*"_single.png"
    Plots.savefig( v, ks )
end

# This is greatly complicated by the large number of households reporting zero for alcohol and tobacco spending. One approach is simply to delete the zeros and estimate over
# just the non-abstemious households.

lcf_kids_drunk = lcf_kids[lcf_kids.alcohol_tobacco.>0,:]
lcf_nokids_drunk = lcf_nokids[lcf_nokids.alcohol_tobacco.>0,:]
nalkies = size(lcf[lcf.alcohol_tobacco.>0,:])[1]
median_alcohol = median(lcf[lcf.alcohol_tobacco.>0,:alcohol_tobacco])
mean_alcohol = mean(lcf[lcf.alcohol_tobacco.>0,:alcohol_tobacco])

barten_kids = coef( lm( @formula( alcohol_tobacco ~ total_expend ), lcf_kids_drunk ))
barten_nokids = coef( lm( @formula( alcohol_tobacco ~ total_expend ), lcf_nokids_drunk ))

function eqbart( level :: Real, coeffs :: AbstractVector ) :: Real
    (level-coeffs[1])/coeffs[2]
end

am_kids = eqbart( mean_alcohol, barten_kids )
am_nokids = eqbart( mean_alcohol, barten_nokids )

eqscale = am_kids/am_nokids


barten_pl = Plots.plot(
    lcf_kids_drunk.total_expend,
    lcf_kids_drunk.alcohol_tobacco,
    label = "With Children",
    title="Barten's Method",
    xlabel = "Total Spending in £pw",
    ylabel = "Alcohol and Tobacco Spending",
    line=:scatter,
    markeralpha=0.5,
    linecolor=kids_colour,
    seriescolor=kids_colour,
    markersize=1,
    marker=:dot,
    markerstrokewidth=0,
    markercolor=kids_colour)
Plots.plot!(
    barten_pl,
    lcf_nokids_drunk.total_expend,
    lcf_nokids_drunk.alcohol_tobacco,
    label = "Without Children",
    line=:scatter,
    markeralpha=0.5,
    linecolor=nokids_colour,
    seriescolor=nokids_colour,
    markersize=1,
    marker=:dot,
    markerstrokewidth=0,
    markercolor=nokids_colour)

exps = 20:1:3_000

# fixme actually only need 2 points of course ... just copied from the log version ..
barten_kids_pred = barten_kids[1].+(barten_kids[2].*exps)
barten_nokids_pred = barten_nokids[1].+(barten_nokids[2].*exps)
Plots.plot!(
    barten_pl,
    exps,
    barten_kids_pred,
    label = "With Children Linear Relationship",
    line=kids_line_colour)

Plots.plot!(
    barten_pl,
    exps,
    barten_nokids_pred,
    label = "Without Children Linear Relationship",
    line=nokids_line_colour)

v = zeros(size(exps)[1])
v .= mean_alcohol
Plots.plot!(
   barten_pl,
   exps,
   v,
   label = "Mean Alcohol and Tobacco Spending",
   line=:line,
   linewidth=2,
   linestyle=:dot,
   linecolor=:black )


Plots.plot!(
  barten_pl,
  [am_kids, am_kids],
  [0.0, mean_alcohol ],
  annotations=(am_kids, 0, Plots.text("B", pointsize=8, halign=:right, valign=:center, font=:serif, color=kids_line_colour)),
   label = "",
  linestyle=:dot,
   line=:line,
   linewidth=2,
  linecolor=:black )

Plots.plot!(
 barten_pl,
 [am_nokids, am_nokids],
 [0.0, mean_alcohol ],
 annotations=(am_nokids, 0, Plots.text("A", pointsize=8, halign=:right, valign=:center, font=:serif, color=nokids_line_colour)),
 label="",
 line=line,
 linestyle=:dot,
 linewidth=2,
 linecolor=:black )

Plots.savefig( barten_pl, "barten_example.png" )
