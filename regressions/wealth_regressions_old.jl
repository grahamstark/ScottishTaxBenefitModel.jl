
#
# old (unused WAS regressions)
#

include( "load_was.jl" )

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
