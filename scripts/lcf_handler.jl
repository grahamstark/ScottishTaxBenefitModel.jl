using CSV
using DataFrames

lcfraw = CSV.File( "/mnt/data/lcf/1718/tab/tab/dvhh_ukanon_2017-18.tab" ) |> DataFrame
lcf = DataFrame()

lcf[!,:age_u_18]=lcfraw[!,:A020]+lcfraw[!,:A021]+lcfraw[!,:A022]+lcfraw[!,:A030]+lcfraw[!,:A031]+lcfraw[!,:A032]
lcf[!,:age_18_plus]=lcfraw[!,:A049]-lcf[!,:age_u_18]
lcf[!,:tenure_type] =  lcfraw[!,:A122]
lcf[!,:region] =  lcfraw[!,:Gorx]
lcf[!,:economic_pos] =  lcfraw[!,:A093]
lcf[!,:age_of_oldest] =  lcfraw[!,:a065p]

lcf[!,:total_consumpt] =  lcfraw[!,:P600t]
lcf[!,:food_and_drink] =  lcfraw[!,:P601t]
lcf[!,:alcohol_tobacco] =  lcfraw[!,:P602t]
lcf[!,:clothing] =  lcfraw[!,:P603t]
lcf[!,:housing] =  lcfraw[!,:P604t]
lcf[!,:household_goods] =  lcfraw[!,:P605t]
lcf[!,:health] =  lcfraw[!,:P606t]
lcf[!,:transport] =  lcfraw[!,:P607t]
lcf[!,:communication] =  lcfraw[!,:P608t]
lcf[!,:recreation] =  lcfraw[!,:P609t]
lcf[!,:education] =  lcfraw[!,:P610t]
lcf[!,:restaurants_etc] =  lcfraw[!,:P611t]
lcf[!,:miscellaneous] =  lcfraw[!,:P612t]
lcf[!,:non_consumption] =  lcfraw[!,:P620tp]
lcf[!,:total_expend] =  lcfraw[!,:P630tp]
lcf[!,:equiv_scale] =  lcfraw[!,:OECDSc]
lcf[!,:weekly_net_inc] =  lcfraw[!,:P389p]


deleterows!( lcf, (lcf[!,:total_consumpt] .< 0.0) )

deleterows!( lcf, (lcf[!,:total_expend] .<0))

deleterows!( lcf, (lcf[!,:housing] .<0))

deleterows!( lcf, (lcf[!,:weekly_net_inc] .< 0.0) )

CSV.write( "/home/graham_s/lcf017_8.tab", lcf, delim='\t' )

lcf[!,:l_total_cons] = log.(lcf[!,:total_consumpt ])
lcf[!,:l_food] = log.(lcf[!,:food_and_drink ])
lcf[!,:l_alc_tob] = log.(lcf[!,:alcohol_tobacco ])
lcf[!,:l_cloth] = log.(lcf[!,:clothing ])
lcf[!,:l_housing] = log.(lcf[!,:housing ])
lcf[!,:l_h_goods] = log.(lcf[!,:household_goods ])
lcf[!,:l_health] = log.(lcf[!,:health ])
lcf[!,:l_transport] = log.(lcf[!,:transport ])
lcf[!,:l_comms] = log.(lcf[!,:communication ])
lcf[!,:l_rec] = log.(lcf[!,:recreation ])
lcf[!,:l_educ] = log.(lcf[!,:education ])
lcf[!,:l_rest_etc] = log.(lcf[!,:restaurants_etc ])
lcf[!,:l_misc] = log.(lcf[!,:miscellaneous ])
lcf[!,:l_non_cons] = log.(lcf[!,:non_consumption ])
lcf[!,:l_total_exp] = log.(lcf[!,:total_expend ])
lcf[!,:l_net_inc] = log.(lcf[!,:weekly_net_inc ])
