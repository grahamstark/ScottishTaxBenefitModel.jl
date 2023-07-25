
#
#

include( "load_was.jl" )


#
summarystats( was.net_financial )
summarystats( was.net_physical )
summarystats( was.net_housing )
summarystats( was.total_pensions )

reg_is_in_debt_1 = glm( @formula( is_in_debt ~ 
    scotland + wales + london + 
    detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    owner + mortgaged + 
    employee + selfemp + unemployed + student + inactive + sick +   
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + weekly_net_income + managerial + intermediate + 
    num_adults + num_children), was, Binomial(), ProbitLink() )

reg_net_financial_1 = lm( @formula( net_financial  ~ 
    scotland + wales + london + 
    detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    owner + mortgaged +    
    employee + selfemp + unemployed + student + inactive + sick +   
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + 
    weekly_net_income + managerial + intermediate + 
    num_adults + num_children), was )

reg_net_financial_2 = lm( @formula( log(net_financial) ~ 
    scotland + wales + london + 
    detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    owner + mortgaged +    
    employee + selfemp + unemployed + student + inactive + sick +   
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + 
    log(weekly_net_income) + managerial + intermediate + 
    num_adults + num_children), was[was.net_financial.>0,:] )

reg_net_financial_3 = lm( @formula( log(-net_financial) ~ 
    scotland + wales + london + 
    detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    owner + mortgaged +    
    employee + selfemp + unemployed + student + inactive + sick +   
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + 
    log(weekly_net_income) + managerial + intermediate + 
    num_adults + num_children), was[was.net_financial.<0,:] )



reg_net_financial_4 = lm( @formula( net_financial  ~ scotland + wales + london + hbedrmr7 +
           hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + 
           hrp_u_75 + weekly_net_income + managerial + intermediate + 
           num_adults + num_children), was )

reg_net_financial_5 = lm( @formula( net_financial  ~ scotland + wales + london + hbedrmr7 +
           hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + 
           hrp_u_75 + managerial + intermediate + 
           num_adults + num_children), was )

reg_net_financial_6 = lm( @formula( net_financial  ~ scotland + wales + london + hbedrmr7 +
           hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + 
           hrp_u_75 + managerial + intermediate ), was )
regtable( reg_is_in_debt_1, reg_net_financial_1, reg_net_financial_2, reg_net_financial_3, reg_net_financial_4, reg_net_financial_5, reg_net_financial_6; renderSettings = latexOutput("total_hh_disagg_wealth.tex") )
regtable( reg_is_in_debt_1, reg_net_financial_1, reg_net_financial_2, reg_net_financial_3, reg_net_financial_4, reg_net_financial_5, reg_net_financial_6 )
           
reg_net_physical_1 = lm( @formula( net_physical  ~ 
    scotland + wales + london + 
    detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    owner + mortgaged +    
    employee + selfemp + unemployed + student + inactive + sick +   
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + 
    weekly_net_income + managerial + intermediate + 
    num_adults + num_children), was[was.net_physical.>0,:] )

reg_net_physical_2 = lm( @formula( log(net_physical) ~ 
    scotland + wales + london + 
    detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    owner + mortgaged +    
    employee + selfemp + unemployed + student + inactive + sick +   
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + 
    log(weekly_net_income) + managerial + intermediate + 
    num_adults + num_children), was[was.net_physical.>0,:] )

reg_net_physical_3 = lm( @formula( log(net_physical) ~ 
    scotland + wales + london + 
    detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + 
    log(weekly_net_income) + managerial + intermediate + 
    num_adults + num_children), was[was.net_physical.>0,:] )

regtable( reg_net_physical_1, reg_net_physical_2,reg_net_physical_3 ; renderSettings = latexOutput("net_physical.tex") )
regtable( reg_net_physical_1, reg_net_physical_2,reg_net_physical_3 )


reg_net_housing_1 = lm( @formula( net_housing ~ scotland + wales + london + detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + weekly_net_income + managerial + intermediate + 
    num_adults + num_children), was[was.net_housing .>0,:] )

reg_net_housing_2 = lm( @formula( log(net_housing) ~ scotland + wales + london + detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + 
    log(weekly_net_income) + managerial + intermediate + 
    num_adults + num_children), was[(was.net_housing .>0).&(was.weekly_net_income .>0),:] )

has_pension = glm( @formula( has_pension_wealth ~ scotland + wales + london + detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + weekly_net_income + managerial + intermediate + 
    num_adults + num_children), was, Binomial(), ProbitLink() )

reg_total_pensions_1 = lm( @formula( total_pensions  ~ scotland + wales + london + detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + weekly_net_income + managerial + intermediate + 
    num_adults + num_children), was[was.total_pensions.>0,:] )
reg_total_pensions_2 = lm( @formula( log(total_pensions)  ~ scotland + wales + london + detatched + semi + terraced + purpose_build_flat + hbedrmr7 +
    hrp_u_25 + hrp_u_35 + hrp_u_45 + hrp_u_55 + hrp_u_65 + hrp_u_75 + 
    log(weekly_net_income) + managerial + intermediate + 
    num_adults + num_children), was[(was.total_pensions.>0).&(was.weekly_net_income .> 0),:] )

regtable( reg_net_financial_1, reg_net_physical_1, reg_total_pensions_1, reg_net_housing_1 ; renderSettings = latexOutput("total_hh_disagg_wealth.tex") )
regtable( reg_net_financial_1, reg_net_physical_1, reg_total_pensions_1, reg_net_housing_1 )

#=
p6 = [exp.(predict(r6)) wasw.total_wealth]
    p7 = predict(r7)
    
    
    println(coef(r6))
=#