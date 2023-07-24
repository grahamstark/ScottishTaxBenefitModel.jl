
#
# old (unused WAS regressions)
#

include( "load_was.jl" )


# house price
#
summarystats( was.net_financial )
summarystats( was.net_physical )
summarystats( was.net_housing )
summarystats( was.total_pensions )

reg_net_financial_1 = lm( @formula( net_financial  ~ scotland + wales + london + detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
           hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + 
           hrp_u_75 + weekly_net_income + managerial + intermediate + 
           num_adults + num_children), was )

reg_net_financial_2 = lm( @formula( net_financial  ~ scotland + wales + london + hbedrmr7 +
           hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + 
           hrp_u_75 + weekly_net_income + managerial + intermediate + 
           num_adults + num_children), was )

reg_net_financial_3 = lm( @formula( net_financial  ~ scotland + wales + london + hbedrmr7 +
           hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + 
           hrp_u_75 + managerial + intermediate + 
           num_adults + num_children), was )

reg_net_financial_4 = lm( @formula( net_financial  ~ scotland + wales + london + hbedrmr7 +
           hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + 
           hrp_u_75 + managerial + intermediate ), was )


reg_net_physical_1 = lm( @formula( net_physical  ~ scotland + wales + london + detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + weekly_net_income + managerial + intermediate + 
    num_adults + num_children), was )
reg_net_physical_2 = lm( @formula( net_physical  ~ scotland + wales + london + detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + weekly_net_income + managerial + intermediate + 
    num_adults + num_children), was )

reg_total_pensions_1 = lm( @formula( total_pensions  ~ scotland + wales + london + detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + weekly_net_income + managerial + intermediate + 
    num_adults + num_children), was[was.total_pensions.>0,:] )

reg_net_housing_1 = lm( @formula( net_housing ~ scotland + wales + london + detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + weekly_net_income + managerial + intermediate + 
    num_adults + num_children), was[was.net_housing .>0,:] )

regtable( reg_net_financial_1, reg_net_physical_1, reg_total_pensions_1, reg_net_housing_1 ; renderSettings = latexOutput("total_hh_disagg_wealth.tex") )
regtable( reg_net_financial_1, reg_net_physical_1, reg_total_pensions_1, reg_net_housing_1 )

regtable( reg_net_financial_1, reg_net_financial_2, reg_net_financial_3, reg_net_financial_4; renderSettings = latexOutput("total_hh_disagg_wealth.tex") )
regtable( reg_net_financial_1, reg_net_financial_2, reg_net_financial_3, reg_net_financial_4 )
#=
p6 = [exp.(predict(r6)) wasw.total_wealth]
    p7 = predict(r7)
    
    
    println(coef(r6))
=#