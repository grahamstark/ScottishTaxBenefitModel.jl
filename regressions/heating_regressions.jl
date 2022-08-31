### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using CSV
using GLM
using Makie
using CairoMakie
# using Plots
using DataFrames
using RegressionTables
using StatsBase
using Statistics
using StatsModels
using Colors

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

lcfraw = CSV.File( "/mnt/data/lcf/1920/tab/lcfs_2019_dvhh_ukanon.tab")|>DataFrame
lcnames = Symbol.(lowercase.(string.(names(lcfraw))))
rename!( lcfraw, lcnames ) # jam lowercase names

lcf = DataFrame()
lcf.age_u_18 = lcfraw.a020+lcfraw.a021+lcfraw.a022+lcfraw.a030+lcfraw.a031+lcfraw.a032
size(lcf.age_u_18)

lcf.summer = isin.( lcfraw.a055, 6,7,8 )
lcf.autumn = isin.( lcfraw.a055, 9,10,11 )
lcf.winter = isin.( lcfraw.a055, 12,1,2 )
lcf.spring = isin.( lcfraw.a055, 3,4,5 )

lcf.age_70_plus = lcfraw.a027 + lcfraw.a037
lcf.age_18_69 = lcfraw.a049-lcf.age_u_18-lcf.age_70_plus

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

lcf.sh_fuel = lcf.fuel ./ lcf.total_consumpt
lcf.sh_fuel_inc = lcf.fuel ./ lcf.weekly_net_inc

delete!( lcf, lcf.fuel .<= 0.0 )

delete!( lcf, (lcf.total_consumpt .<= 0.0) )

delete!( lcf, (lcf.total_expend .<= 0))

delete!( lcf, (lcf.housing .<= 0))

delete!( lcf, (lcf.weekly_net_inc .<= 0.0) )
delete!( lcf, lcf.weekly_net_inc .>= 1850 ) # tructation
delete!( lcf, lcf.sh_fuel_inc .> 0.5 ) # some weired outliers
delete!( lcf, lcf.sh_fuel_inc .< 0.01 )
#
# CSV.write( "/home/graham_s/lcf017_8.tab", lcf, delim='\t' )

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
   ss = summarystats(lcf[!,n])
   println( "$n : $ss ")
end


r1 = lm( @formula( sh_fuel ~ l_total_exp ), lcf )
r2 = lm( @formula( sh_fuel ~ l_total_exp + scotland ), lcf )
r3 = lm( @formula( sh_fuel ~ l_total_exp + scotland + owner + mortgaged + privrent + larent ), lcf )
r4 = lm( @formula( sh_fuel ~ l_total_exp + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom ), lcf )
r5 = lm( @formula( sh_fuel ~ l_total_exp + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus ), lcf )


r11 = lm( @formula( sh_fuel_inc ~ l_net_inc ), lcf )
r12 = lm( @formula( sh_fuel_inc ~ l_net_inc + scotland ), lcf )
r13 = lm( @formula( sh_fuel_inc ~ l_net_inc + scotland + owner + mortgaged + privrent + larent ), lcf )
r14 = lm( @formula( sh_fuel_inc ~ l_net_inc + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom ), lcf )
r15 = lm( @formula( sh_fuel_inc ~ l_net_inc + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus ), lcf )
r16 = lm( @formula( sh_fuel_inc ~ l_net_inc + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus  + winter + spring + summer), lcf )

r21 = lm( @formula( l_fuel ~ weekly_net_inc + weekly_net_inc^2 ), lcf )
r22 = lm( @formula( l_fuel ~ weekly_net_inc + weekly_net_inc^2 + scotland ), lcf )
r23 = lm( @formula( l_fuel ~ weekly_net_inc + weekly_net_inc^2 + scotland + owner + mortgaged + privrent + larent ), lcf )
r24 = lm( @formula( l_fuel ~ weekly_net_inc + weekly_net_inc^2 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom ), lcf )
r25 = lm( @formula( l_fuel ~ weekly_net_inc/1000 + (weekly_net_inc^2)/1000000 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus ), lcf )
r26 = lm( @formula( l_fuel ~ weekly_net_inc/1000 + (weekly_net_inc^2)/1000000 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus + winter + spring + summer ), lcf )


#
# Quaids-ish
#
r31 = lm( @formula( sh_fuel_inc ~ l_net_inc + l_net_inc^2 ), lcf )
r32 = lm( @formula( sh_fuel_inc ~ l_net_inc + l_net_inc^2 + scotland ), lcf )
r33 = lm( @formula( sh_fuel_inc ~ l_net_inc + l_net_inc^2 + scotland + owner + mortgaged + privrent + larent ), lcf )
r34 = lm( @formula( sh_fuel_inc ~ l_net_inc + l_net_inc^2 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom ), lcf )
r35 = lm( @formula( sh_fuel_inc ~ l_net_inc + l_net_inc^2 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus ), lcf )
r36 = lm( @formula( sh_fuel_inc ~ l_net_inc + l_net_inc^2 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus + winter + spring + summer ), lcf )
#                                     2 	       3         4        5           6          7         8             9      10          11          12         13          14           15   

#
# Cubic
#
r41 = lm( @formula( sh_fuel_inc ~ l_net_inc + l_net_inc^2 + l_net_inc^3 ), lcf )
r42 = lm( @formula( sh_fuel_inc ~ l_net_inc + l_net_inc^2 + l_net_inc^3 + scotland ), lcf )
r43 = lm( @formula( sh_fuel_inc ~ l_net_inc + l_net_inc^2 + l_net_inc^3 + scotland + owner + mortgaged + privrent + larent ), lcf )
r44 = lm( @formula( sh_fuel_inc ~ l_net_inc + l_net_inc^2 + l_net_inc^3 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom ), lcf )
r45 = lm( @formula( sh_fuel_inc ~ l_net_inc + l_net_inc^2 + l_net_inc^3 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus ), lcf )
r46 = lm( @formula( sh_fuel_inc ~ l_net_inc + l_net_inc^2 + l_net_inc^3 + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus  + winter + spring + summer), lcf )

RegressionTables.regtable( r1, r2, r3, r4, r5 )
RegressionTables.regtable( r11, r12, r13, r14, r15, r16 )
RegressionTables.regtable( r21, r22, r23, r24, r25, r26 )
RegressionTables.regtable( r31, r32, r33, r34, r35, r36 )
RegressionTables.regtable( r41, r42, r43, r44, r45, r46 )
CSV.write( "lcf_fuel_2020.csv", lcf )

hist( lcf.weekly_net_inc )
hist( lcf.total_expend )
hist( lcf.total_consumpt )
scatter( lcf.weekly_net_inc, lcf.total_expend )


predfuel=lcf.weekly_net_inc.*predict( r15 )
scatter( lcf.weekly_net_inc,  predfuel)

inc = collect(1:2000)
pred15 = zeros(2000)
c15 = coef(r15)
v15 = zeros(14)
v15[1] = 1 # const
v15[3] = 1 # scotland
v15[5] = 1 # mortgaged
v15[8] = 1 # detatched
v15[12] = 2 # 2 child
v15[13] = 2 # 2 non pens adult
for i in 1:2000
	v15[2] = log(inc[i])
	pred15[i] = inc[i] * (c15'v15)
	# println("$i = $pred")
end

c12 = coef(r12)
v12 = ones(3)
pred12 = zeros(2000)
for i in 1:2000
	v12[2] = log(inc[i])
	pred12[i] = inc[i]*(v12'*c12)
	# println("$i = $pred")
end




pp1 = plot( inc, pred15 )
pp2 = plot( lcf.l_net_inc, lcf.sh_fuel_inc,color = :grey, markersize = 1 )

p15 = lcf.weekly_net_inc.*GLM.predict(r15)
# plot!( pp2, lcf.weekly_net_inc, p15 )
# ,color = :red, markersize = 1)

save( "pp1.svg", pp1 )
save( "pp2.svg", pp2 )


pred35 = zeros(2000)
c35 = coef(r35)
v35 = zeros(15)
v35[1] = 1 # const
v35[4] = 1 # scotland
v35[6] = 1 # mortgaged
v35[9] = 1 # detatched
v35[13] = 2 # 2 child
v35[14] = 2 # 2 non pens adult
for i in 100:2000
	v35[2] = log(inc[i])
	v35[3] = v35[2]^2
	pred35[i] = inc[i] * (c35'v35)
	# println("$i = $pred")
end
summarystats(predict(r35).*lcf.weekly_net_inc)
plot35 = plot( inc[100:2000], pred35[100:2000] )
save( "plot35.svg", plot35 )



pred45 = zeros(2000)
c45 = coef(r45)
v45 = zeros(16)
v45[1] = 1 # const
v45[5] = 1 # scotland
v45[7] = 1 # mortgaged
v45[10] = 1 # detatched
v45[14] = 2 # 2 child
v45[15] = 2 # 2 non pens adult
for i in 100:2000
	v45[2] = log(inc[i])
	v45[3] = v45[2]^2
	v45[4] = v45[2]^3
	pred45[i] = inc[i] * (c45'v45)
	# println("$i = $pred")
end

summarystats(predict(r45).*lcf.weekly_net_inc)
plot45 = plot( inc[100:2000], pred45[100:2000] )
save( "plot45.svg", plot45 )

function predict35( r :: StatsModels.TableRegressionModel, incomes :: AbstractArray, dummies :: Dict{Int,Int} ) :: Vector
	c = coef( r ) ## extract coefs
	vals = zeros( size(c)[1])
	vals[1] = 1 # intercept
	for (k,v) in dummies
		println( "setting $k to $v")
		vals[k] = v
	endi
	println( vals )
	pred = zeros( size(incomes)[1] )
	i = 0
 	for inc in incomes
		i += 1
		vals[2] = log(inc)
		vals[3] = vals[2]^2		
		pred[i] = inc * (c'vals)
		# println("$i = $pred")
	end
	pred
end

CairoMakie.activate!(type = "pdf")
f = Figure(resolution = (1200, 800))
incs = 100:2000
Axis( f[1,1], 
	title="Fuel Expenditure: Actual vs Modelled 2019/20",
	xlabel = "Net Income £pw",
	ylabel = "Fuel Spending £pw")
# scotland, morgaged, detatched 2kids, 2 adults
# scotland, LA, Flat, 1 pensioner

#
# pensioners
#
ps = lcf[((lcf.age_70_plus .> 0).&& (lcf.age_u_18 .== 0)), : ]
predPens = predict35( r35, 100:1000, Dict([4=>1, 5=>1, 10=>1, 15=>2 ]))
s1 = plot!( ps.weekly_net_inc, ps.fuel,color = "slategray3", markersize = 2 )
p1 = plot!( 100:1000, predPens, color="navyblue", markersize= 3 )

#
# childless
# see: https://juliagraphics.github.io/Colors.jl/stable/namedcolors/ for a colo[u]r name list
pn = lcf[((lcf.age_70_plus .== 0) .&& (lcf.age_u_18 .== 0)), : ]
predFamNC = predict35( r35, 100:2000, Dict([4=>1, 6=>1, 9=>1, 13=>0, 14=>2 ]))
s2 = plot!( pn.weekly_net_inc, pn.fuel, color = "indianred1", markersize = 2 )
p2 = plot!( 100:2000, predFamNC, color="red4", markersize= 3 )

#
# w/children
#
pc = lcf[(lcf.age_u_18 .> 0), : ]
predFam2 = predict35( r35, 100:2000, Dict([4=>1, 6=>1, 9=>1, 13=>2, 14=>2 ]))

s3 = plot!( pc.weekly_net_inc, pc.fuel,color = "darkgreen", markersize = 2 )
p3 = plot!( 100:2000, predFam2, color="seagreen", markersize= 3 )

Legend( f[1,2], [[s1,p1], [s2,p2], [s3,p3]], ["Pensioners", "Childless", "W/Children"])

save( "f.pdf", f )

