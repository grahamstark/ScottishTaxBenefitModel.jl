using CSV
using GLM
# using Makie
# using CairoMakie
using DataFrames
using RegressionTables
using StatsBase
using Statistics
using StatsModels
# using Colors
using Dates

was = CSV.File( "/mnt/data/was/UKDA-7215-tab/tab/was_round_7_hhold_eul_march_2022.tab") |> DataFrame

was.north_east = was.gorr7 .== 1
was.north_west = was.gorr7 .== 2
was.yorkshire = was.gorr7 .== 4
was.east_midlands = was.gorr7 .== 5
was.west_midlands = was.gorr7 .== 6
was.east_of_england = was.gorr7 .== 7
was.london = was.gorr7 .== 8
was.south_east = was.gorr7 .== 9
was.south_west = was.gorr7 .== 10
was.wales = was.gorr7 .== 11
was.scotland = was.gorr7 .== 12

was.hrp_u_25  =  was.HRPDVAge8r7 .== 2
was.hrp_u_35 =  was.HRPDVAge8r7 .== 3
was.hrp_u_45 =  was.HRPDVAge8r7 .== 4
was.hrp_u_55 =  was.HRPDVAge8r7 .== 5
was.hrp_u_65 =  was.HRPDVAge8r7 .== 6
was.hrp_u_75 =  was.HRPDVAge8r7 .== 7
was.hrp_75_plus = was.HRPDVAge8r7 .== 8
was.weekly_net_income = was.HHNetIncMthR7 ./ 4.35
was.owner = was.ten1r7 .== 1
was.mortgaged = was.ten1r7 .== 2 .|| was.ten1r7 .== 3
was.renter = was.ten1r7 .== 4 # should never happen
was.detatched = (was.accomr7 .== 1) .& (was.hsetyper7 .== 1)
was.semi = (was.accomr7 .== 1) .& (was.hsetyper7 .== 2)
was.terraced = (was.accomr7 .== 1) .& (was.hsetyper7 .== 3)
was.purpose_build_flat = (was.accomr7 .== 2) .& (was.flttypr7 .== 1) 
was.converted_flat = (was.accomr7 .== 2) .& (was.flttypr7 .== 2) 
was.ctamtr7 # council tax amount 
was.managerial = was.hrpnssec3r7 .== 1
was.intermediate = was.hrpnssec3r7 .== 2
was.routine = was.hrpnssec3r7 .== 3
was.total_wealth = was.TotWlthR7
was.num_children = was.numchildr7
was.num_adults = was.dvhsizer7 - was.num_children

#
# wealth
#

r4 = lm( @formula( TotWlthR7 ~ scotland + wales + london + owner + detatched + semi + terraced + purpose_build_flat + HBedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + weekly_net_income + managerial + intermediate + 
    num_adults + num_children), was )

# log version - what about negative net wealth?
wasw = was[ (was.total_wealth .> 0.0).&(was.weekly_net_income.>0), : ]
wasw.log_weekly_net_income = log.(wasw.weekly_net_income)
wasw.log_total_wealth = log.(wasw.total_wealth)
r5 = lm( @formula( log_total_wealth ~ scotland + wales + london + owner + mortgaged + detatched + semi + terraced + purpose_build_flat + HBedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + log_weekly_net_income + managerial + intermediate + 
    num_adults + num_children  ), wasw )
    
r6 = lm( @formula( log_total_wealth ~ north_west + yorkshire + east_midlands + west_midlands + 
    east_of_england + london + south_east + south_west + wales + scotland + 
    owner + mortgaged + detatched + semi + terraced + purpose_build_flat + HBedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + managerial + intermediate + 
    num_adults + num_children  ), wasw )

r7 = lm( @formula( total_wealth ~ north_west + yorkshire + east_midlands + west_midlands + 
    east_of_england + london + south_east + south_west + wales + scotland + 
    owner + mortgaged + detatched + semi + terraced + purpose_build_flat + HBedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + managerial + intermediate + 
    num_adults + num_children  ), was )

regtable( r4, r5 ; renderSettings = latexOutput("total_hh_wealth.tex") )
regtable( r4, r5 )

regtable( r7, r6 ; renderSettings = latexOutput("total_hh_wealth.tex") )
regtable( r7, r6 )



p6 = [exp.(predict(r6)) wasw.total_wealth]
p7 = predict(r7)
println( " predicted (log):\n ", summarystats( p6[:,1]))
println( " predicted (linear):\n ", summarystats( p7[:,1]))

println( " actual:\n ", summarystats( p6[:,2]))

println( " actual (inc neg):\n ", summarystats( was.total_wealth ))

println(coef(r6))

# house price
#

# TotWlthR5

washh = was[(was.hvaluer7 .> 0).&(was.weekly_net_income.>0),:]
washh.log_weekly_net_income = log.(washh.weekly_net_income)
washh.log_hprice = log.( washh.hvaluer7)


r1 = lm( @formula( log_hprice ~ scotland + wales + london + owner + detatched + semi + terraced + purpose_build_flat + HBedrmr7 ), washh )
r2 = lm( @formula( log_hprice ~ scotland + wales + london + owner + detatched + semi + terraced + purpose_build_flat + HBedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 ), washh )

r3 = lm( @formula( log_hprice ~ scotland + wales + london + owner + detatched + semi + terraced + purpose_build_flat + HBedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + log_weekly_net_income + managerial + intermediate ), washh )

[exp.(predict(r3)) washh.hvaluer7]

regtable( r1, r2, r3, ; renderSettings = latexOutput("houseprices.tex") )
regtable( r1, r2, r3 )
