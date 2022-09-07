### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using CSV
using GLM
using Makie
using CairoMakie
using DataFrames
using RegressionTables
using StatsBase
using Statistics
using StatsModels
using Colors
using Dates

using ScottishTaxBenefitModel
using .TimeSeriesUtils: parse_ons_date

"""
must be a standard way of broadcasting but ..
"""
function isin( x, y... )
	for z in y
		# println( z )
	  	if x == z
			return 1
	  	end
	end
	return 0
end

mm23 = CSV.File( "/mnt/data/prices/mm23/latest/mm23_edited.csv")|>DataFrame
lcnames = Symbol.(lowercase.(string.(names(mm23))))
rename!( mm23, lcnames ) # jam lowercase names
mm23.date = parse_ons_date.( mm23.cdid )

const LCF_HH_FILES = [
	"/mnt/data/lcf/0910/tab/2009_dvhh_ukanon.tab",
	"/mnt/data/lcf/1011/tab/2010_dvhh_ukanon.tab",
	"/mnt/data/lcf/1112/tab/2011_dvhh_ukanon.tab",
	"/mnt/data/lcf/1213/tab/2012_dvhh_ukanon.tab",
	"/mnt/data/lcf/1314/tab/2013_dvhh_ukanon.tab",
	"/mnt/data/lcf/1415/tab/2014_dvhh_ukanon.tab",
	"/mnt/data/lcf/1516/tab/2015-16_dvhh_ukanon.tab",
	"/mnt/data/lcf/1617/tab/2016_17__dvhh_ukanon.tab",
	"/mnt/data/lcf/1718/tab/dvhh_ukanon_2017-18.tab",
	"/mnt/data/lcf/1819/tab/2018_dvhh_ukanon.tab",
	"/mnt/data/lcf/1920/tab/lcfs_2019_dvhh_ukanon.tab"
]

function loadtab( filename )
	lcfraw = CSV.File( filename )|>DataFrame
	lcnames = Symbol.(lowercase.(string.(names(lcfraw))))
	rename!( lcfraw, lcnames ) # jam lowercase names
end

#
# Stack 2009/10-19/20 LCFs
#
lcfv = []
for fn in LCF_HH_FILES	
	push!(lcfv, loadtab( fn ))
end
lcfraw = vcat( lcfv...; cols=:intersect )

# d7bt = cpi all items 2015=100
# d7ch = CPI INDEX 04.5 : ELECTRICITY, GAS AND OTHER FUELS 2015=100

lcf = DataFrame()
lcf.age_u_18 = lcfraw.a020+lcfraw.a021+lcfraw.a022+lcfraw.a030+lcfraw.a031+lcfraw.a032

n = size(lcf.age_u_18)[1]
lcf.cpi = zeros(n)
lcf.cpi_ex_fuel = zeros(n)
lcf.cpi_fuel = zeros(n)

lcf.year = lcfraw.year
lcf.month = lcfraw.a055

#
# This is e.g January REIS and I don't know what REIS means 
#
for i in eachrow(lcf)
	if i.month > 20 
	  i.month -= 20
  	end
end

lcf.date = Date.(lcf.year,lcf.month)

for i in eachrow(lcf)
	prow = mm23[i.date .== mm23.date,:]
	@assert size(prow)[1] == 1
	prow = prow[1,:]
	i.cpi = prow.d7bt
	i.cpi_ex_fuel = prow.d7bt ## FIXME TODO non-fuel share use whole cpi for now.
	i.cpi_fuel = prow.d7ch
end

lcf.summer = isin.( lcfraw.a055, 6,7,8 )
lcf.autumn = isin.( lcfraw.a055, 9,10,11 )
lcf.winter = isin.( lcfraw.a055, 12,1,2 )
lcf.spring = isin.( lcfraw.a055, 3,4,5 )

lcf.age_70_plus = lcfraw.a027 + lcfraw.a037
lcf.age_18_69 = lcfraw.a049-lcf.age_u_18-lcf.age_70_plus
lcf.t_trend = lcfraw.year .- 2008
lcf.tenure = lcfraw.a122
lcf.dwelling = lcfraw.a116

lcf.region =  lcfraw.gorx
lcf.economic_pos = lcfraw.a093
lcf.age_of_oldest = lcfraw.a065p
lcf.total_consumpt =  lcfraw.p600t

lcf.food_and_drink =  lcfraw.p601t
lcf.alcohol_tobacco =  lcfraw.p602t
lcf.clothing =  lcfraw.p603t
lcf.housing =  lcfraw.p604t
lcf.household_goods =  lcfraw.p605t
lcf.health =  lcfraw.p606t
lcf.transport =  lcfraw.p607t
lcf.communication =  lcfraw.p608t
lcf.recreation =  lcfraw.p609t
lcf.education =  lcfraw.p610t
lcf.restaurants_etc =  lcfraw.p611t
lcf.miscellaneous =  lcfraw.p612t
lcf.non_consumption =  lcfraw.p620tp
lcf.total_expend =  lcfraw.p630tp
lcf.equiv_scale =  lcfraw.oecdsc
lcf.weekly_net_inc =  lcfraw.p389p
lcf.fuel = lcfraw.p537t

lcf.l_fuel_price = log.( lcf.cpi_fuel ./ lcf.cpi_ex_fuel )

# shares should be of undeflated expend and income
lcf.sh_fuel = lcf.fuel ./ lcf.total_consumpt
lcf.sh_fuel_inc = lcf.fuel ./ lcf.weekly_net_inc

# then deflate
lcf.fuel .= 100.0 .* lcf.fuel ./ lcf.cpi_fuel
lcf.weekly_net_inc .= 100.0 .* lcf.weekly_net_inc ./ lcf.cpi

delete!( lcf, lcf.fuel .<= 0.0 )

delete!( lcf, (lcf.total_consumpt .<= 0.0) )

delete!( lcf, (lcf.total_expend .<= 0))

delete!( lcf, (lcf.housing .<= 0))

delete!( lcf, (lcf.weekly_net_inc .<= 0.0) )
delete!( lcf, lcf.weekly_net_inc .>= 1600 ) # tructation FIXME truncation varies by year
delete!( lcf, lcf.sh_fuel_inc .> 0.5 ) # some wierd outliers
delete!( lcf, lcf.sh_fuel_inc .< 0.01 )

lcf.l_total_cons = log.(lcf.total_consumpt )
lcf.l_total_exp = log.(lcf.total_expend )
lcf.l_net_inc = log.(lcf.weekly_net_inc )
lcf.l_fuel = log.(lcf.fuel )

lcf.scotland = lcf.region .== 11
lcf.owner = lcf.tenure .== 7
lcf.mortgaged = lcf.tenure .== 5 .|| lcf.tenure .== 5
lcf.privrent = lcf.tenure .== 3 .|| lcf.tenure .== 4 
lcf.larent = lcf.tenure .== 1
lcf.harent = lcf.tenure .== 2
lcf.other_ten = lcf.tenure .> 7 .|| lcf.tenure .< 1

#=
Value = 0.0	Label = Not Recorded
	Value = 1.0	Label = LA (furnished unfurnished)
	Value = 2.0	Label = Hsng Assn (furnished unfrnish)
	Value = 3.0	Label = Priv. rented (unfurn)
	Value = 4.0	Label = Priv. rented (furnished)
	Value = 5.0	Label = Owned with mortgage
	Value = 6.0	Label = Owned by rental purchase
	Value = 7.0	Label = Owned outright
	Value = 8.0	Label = Rent free
=#

#=
Value = 0.0	Label = Not Recorded
	Value = 1.0	Label = Whole house,bungalow-detached
	Value = 2.0	Label = Whole hse,bungalow-semi-dtchd
	Value = 3.0	Label = Whole house,bungalow-terraced
	Value = 4.0	Label = Purpose-built flat maisonette
	Value = 5.0	Label = Part of house converted flat
	Value = 6.0	Label = Others
	
	NOTE!! FRS has 6 = caravan 7=others
=#

lcf.detatched = lcf.dwelling .== 1
lcf.semi = lcf.dwelling .== 2
lcf.terraced = lcf.dwelling .== 3
lcf.flat = lcf.dwelling .== 4 .|| lcf.dwelling .== 5
lcf.other_accom = lcf.dwelling .== 6 .|| lcf.dwelling .== 7

for n in names(lcf)
	println( n )
	if n != "date"
	   	ss = summarystats(lcf[!,n])
	   	println( "$n : $ss ")
	end
end


r1 = lm( @formula( sh_fuel ~ l_fuel_price + l_total_exp ), lcf )
r2 = lm( @formula( sh_fuel ~ l_total_exp + scotland ), lcf )
r3 = lm( @formula( sh_fuel ~ l_total_exp + scotland + owner + mortgaged + privrent + larent ), lcf )
r4 = lm( @formula( sh_fuel ~ l_total_exp + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom ), lcf )
r5 = lm( @formula( sh_fuel ~ l_total_exp + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus ), lcf )


r11 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  ), lcf )
r12 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + scotland ), lcf )
r13 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + scotland + owner + mortgaged + privrent + larent ), lcf )
r14 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom ), lcf )
r15 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus ), lcf )
r16 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus  + winter + spring + summer), lcf )

r21 = lm( @formula( l_fuel ~ weekly_net_inc + weekly_net_inc^2 ), lcf )
r22 = lm( @formula( l_fuel ~ weekly_net_inc + weekly_net_inc^2 + scotland ), lcf )
r23 = lm( @formula( l_fuel ~ weekly_net_inc + weekly_net_inc^2 + scotland + owner + mortgaged + privrent + larent + t_trend ), lcf )
r24 = lm( @formula( l_fuel ~ weekly_net_inc + weekly_net_inc^2 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom  + t_trend ), lcf )
r25 = lm( @formula( l_fuel ~ weekly_net_inc/1000 + (weekly_net_inc^2)/1000000 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus  + t_trend ), lcf )
r26 = lm( @formula( l_fuel ~ weekly_net_inc/1000 + (weekly_net_inc^2)/1000000 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus + winter + spring + summer  + t_trend ), lcf )


#
# Quaids-ish
#
r31 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + l_net_inc^2 ), lcf )
r32 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + l_net_inc^2 + scotland ), lcf )
r33 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + l_net_inc^2 + scotland + owner + mortgaged + privrent + larent + t_trend ), lcf )
r34 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + l_net_inc^2 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + t_trend ), lcf )
r35 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + l_net_inc^2 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus + t_trend ), lcf )
r36 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + l_net_inc^2 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus + winter + spring + summer + t_trend ), lcf )
#                                     2 	       3         4        5           6          7         8             9      10          11          12         13          14           15   

#
# Cubic
#
r41 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + l_net_inc^2 + l_net_inc^3 ), lcf )
r42 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + l_net_inc^2 + l_net_inc^3 + scotland ), lcf )
r43 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + l_net_inc^2 + l_net_inc^3 + scotland + owner + mortgaged + privrent + larent + t_trend  ), lcf )
r44 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + l_net_inc^2 + l_net_inc^3 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + t_trend  ), lcf )
r45 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + l_net_inc^2 + l_net_inc^3 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus + t_trend  ), lcf )
r46 = lm( @formula( sh_fuel_inc ~ l_fuel_price + l_net_inc  + l_net_inc^2 + l_net_inc^3 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus  + winter + spring + summer + t_trend ), lcf )
#                                  1       2             3            4               5       6        7            8         9       10           11        12     13            14         15          16             17        18       19       20       21

RegressionTables.regtable( r1, r2, r3, r4, r5 )
RegressionTables.regtable( r11, r12, r13, r14, r15, r16 )
RegressionTables.regtable( r21, r22, r23, r24, r25, r26 )
RegressionTables.regtable( r31, r32, r33, r34, r35, r36 )

RegressionTables.regtable( r41, r42, r43, r44, r45, r46 )

RegressionTables.regtable( r41, r42, r43, r44, r45, r46; renderSettings = latexOutput("docs/fuel/reg4.tex"))
RegressionTables.regtable( r41, r42, r43, r44, r45, r46; renderSettings = htmlOutput("docs/fuel/reg4.html"))
RegressionTables.regtable( r41, r42, r43, r44, r45, r46; renderSettings = asciiOutput("docs/fuel/reg4.txt"))

CSV.write( "data/lcf_fuel_2010-2020.csv", lcf )

hist( lcf.weekly_net_inc )
hist( lcf.total_expend )
hist( lcf.total_consumpt )
scatter( lcf.weekly_net_inc, lcf.total_expend )

#=
positions in full regression with cubic term
l_fuel_price + 2
l_net_inc  + 3
l_net_inc^2 + 4
l_net_inc^3 + 5
scotland + 6
owner + 7
mortgaged + 8
privrent + 9
larent + 10
detatched + 11
terraced + 12
flat + 13
other_accom + 14
age_u_18 + 15
age_18_69 + 16
age_70_plus  + 17
winter + 18
spring + 19
summer + 20
t_trend + 21
=#

function predict46( 
	r :: StatsModels.TableRegressionModel, 
	incomes :: AbstractArray, 
	nonzeros :: Dict{Int,Int} ) :: Vector
	c = coef( r ) ## extract coefs
	vals = zeros( size(c)[1])
	vals[1] = 1 # intercept
	for (k,v) in nonzeros
		println( "setting $k to $v")
		vals[k] = v
	end
	println( vals )
	pred = zeros( size(incomes)[1] )
	i = 0
 	for inc in incomes
		i += 1
		vals[2] = 0.0 # mean of log(p0/p1)
		vals[3] = log(inc)
		vals[4] = vals[3]^2		
		vals[5] = vals[3]^3		
		pred[i] = inc * (c'vals)
		# println("$i = $pred")
	end
	pred
end

const INCS = 100:1500
CairoMakie.activate!(type = "pdf")
fig1 = Figure(resolution = (1200, 800))
Axis( fig1[1,1], 
	title="Fuel Expenditure: Actual vs Modelled 2010-2020",
	xlabel = "Net Income £pw (constant 2015 prices)",
	ylabel = "Fuel Spending £pw (constant 2015 prices)")
#
# pensioner couple
#
ps = lcf[((lcf.age_70_plus .> 0).&& (lcf.age_u_18 .== 0)), : ]
predPens = predict46( r46, INCS, Dict([6=>1, 7=>1, 12=>1, 17=>2, 21=>11 ]))
s1 = plot!( ps.weekly_net_inc, ps.fuel,color = "cornflowerblue", markersize = 1 )
p1 = plot!( INCS, predPens, color="navyblue", markersize= 2 )

#
# 2ad childless
# see: https://juliagraphics.github.io/Colors.jl/stable/namedcolors/ for a colo[u]r name list
pn = lcf[((lcf.age_70_plus .== 0) .&& (lcf.age_u_18 .== 0)), : ]
predFamNC = predict46( r46, INCS, Dict([6=>1, 7=>1, 11=>1, 15=>0, 16=>2, 21=>11 ]))
s2 = plot!( pn.weekly_net_inc, pn.fuel, color = "indianred1", markersize = 1 )
p2 = plot!( INCS, predFamNC, color="red4", markersize= 2 )

#
# 2 ad w/children
#
pc = lcf[(lcf.age_u_18 .> 0), : ]
predFam2 = predict46( r46, INCS, Dict([6=>1, 7=>1, 11=>1, 15=>2, 16=>2, 21=>11 ]))
s3 = plot!( pc.weekly_net_inc, pc.fuel,color = "darkgreen", markersize = 1 )
p3 = plot!( INCS, predFam2, color="seagreen", markersize= 2 )

Legend( fig1[1,2], [[s1,p1], [s2,p2], [s3,p3]], ["Pensioners", "Childless", "W/Children"])

save( "docs/fuel/energy_model_sketch.pdf", fig1 )

println( coef( r46 ))