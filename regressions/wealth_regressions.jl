
#
#
#
summarystats( was.net_financial )
summarystats( was.net_physical )
summarystats( was.net_housing )
summarystats( was.total_pensions )

reg_is_in_debt_1 = glm( @formula( is_in_debt ~ 
    scotland + wales + london + # north_west + yorkshire +east_midlands + west_midlands+  east_of_england + south_east + south_west +
    detatched + semi + terraced + purpose_build_flat + #  bedrooms +
    owner + mortgaged + 
    female +
    employee + selfemp + unemployed + student + inactive + sick +   
    age_25_34 + age_35_44 + age_45_54 + age_55_64 +  age_65_74 + age_75_plus + log(weekly_gross_income) + managerial + intermediate + 
    num_adults + num_children), was, Binomial(), ProbitLink() )

reg_net_financial_1 = lm( @formula( net_financial  ~ 
    scotland + wales + london + # north_west + yorkshire +east_midlands + west_midlands+  east_of_england + south_east + south_west +
    detatched + semi + terraced + purpose_build_flat + #  bedrooms +
    owner + mortgaged +    
    female +
    employee + selfemp + unemployed + student + inactive + sick +   
    age_25_34 + age_35_44 + age_45_54 + age_55_64 + age_65_74 + age_75_plus + 
    weekly_gross_income + managerial + intermediate + 
    num_adults + num_children), was )

reg_net_financial_2 = lm( @formula( log(net_financial) ~ 
    scotland + wales + london + # north_west + yorkshire +east_midlands + west_midlands+  east_of_england + south_east + south_west +
    detatched + semi + terraced + purpose_build_flat + #  bedrooms +
    owner + mortgaged +    
    female +
    employee + selfemp + unemployed + student + inactive + sick +   
    age_25_34 + age_35_44 + age_45_54 + age_55_64 +  age_65_74 + age_75_plus + 
    log(weekly_gross_income) + managerial + intermediate + 
    num_adults + num_children), was[was.net_financial.>0,:] )

reg_net_financial_3 = lm( @formula( log(-net_financial) ~ 
    scotland + wales + london + # north_west + yorkshire +east_midlands + west_midlands+  east_of_england + south_east + south_west +
    detatched + semi + terraced + purpose_build_flat + #  bedrooms +
    owner + mortgaged +    
    female +
    employee + selfemp + unemployed + student + inactive + sick +   
    age_25_34 + age_35_44 + age_45_54 + age_55_64 +  age_65_74 + age_75_plus + 
    log(weekly_gross_income) + managerial + intermediate + 
    num_adults + num_children), was[was.net_financial.<0,:] )



reg_net_financial_4 = lm( @formula( net_financial  ~ scotland + wales + london + north_west + yorkshire +east_midlands + west_midlands+  east_of_england + south_east + south_west +#  bedrooms +
           age_25_34 + age_35_44 + age_45_54 + age_55_64 +  
           age_65_74 + age_75_plus + weekly_gross_income + managerial + intermediate + 
           num_adults + num_children), was )

reg_net_financial_5 = lm( @formula( net_financial  ~ scotland + wales + london + north_west + yorkshire +east_midlands + west_midlands+  east_of_england + south_east + south_west +#  bedrooms +
           age_25_34 + age_35_44 + age_45_54 + age_55_64 +  
           age_65_74 + age_75_plus + managerial + intermediate + 
           num_adults + num_children), was )

reg_net_financial_6 = lm( @formula( net_financial  ~ scotland + wales + london + north_west + yorkshire +east_midlands + west_midlands+  east_of_england + south_east + south_west +#  bedrooms +
           age_25_34 + age_35_44 + age_45_54 + age_55_64 +  
           age_65_74 + age_75_plus + managerial + intermediate ), was )
regtable( reg_is_in_debt_1, reg_net_financial_1, reg_net_financial_2, reg_net_financial_3, reg_net_financial_4, reg_net_financial_5, reg_net_financial_6; renderSettings = LatexTable(), file="docs/wealth/net_financial.tex")
regtable( reg_is_in_debt_1, reg_net_financial_1, reg_net_financial_2, reg_net_financial_3, reg_net_financial_4, reg_net_financial_5, reg_net_financial_6 )
           
reg_net_physical_1 = lm( @formula( net_physical  ~ 
    scotland + wales + london + # north_west + yorkshire +east_midlands + west_midlands+  east_of_england + south_east + south_west +
    detatched + semi + terraced + purpose_build_flat + #  bedrooms +
    owner + mortgaged +    
    female +
    employee + selfemp + unemployed + student + inactive + sick +   
    age_25_34 + age_35_44 + age_45_54 + age_55_64 +  age_65_74 + age_75_plus + 
    weekly_gross_income + managerial + intermediate + 
    num_adults + num_children), was[was.net_physical.>0,:] )

reg_net_physical_2 = lm( @formula( log(net_physical) ~ 
    scotland + wales + london + # north_west + yorkshire +east_midlands + west_midlands+  east_of_england + south_east + south_west +
    detatched + semi + terraced + purpose_build_flat + #  bedrooms +
    owner + mortgaged +    
    female +
    employee + selfemp + unemployed + student + inactive + sick +   
    age_25_34 + age_35_44 + age_45_54 + age_55_64 +  age_65_74 + age_75_plus + 
    log(weekly_gross_income) + managerial + intermediate + 
    num_adults + num_children), was[was.net_physical.>0,:] )

reg_net_physical_3 = lm( @formula( log(net_physical) ~ 
    scotland + wales + london + # north_west + yorkshire +east_midlands + west_midlands+  east_of_england + south_east + south_west +
    detatched + semi + terraced + purpose_build_flat + #  bedrooms +
    female +
    age_25_34 + age_35_44 + age_45_54 + age_55_64 +  age_65_74 + age_75_plus + 
    log(weekly_gross_income) + managerial + intermediate + 
    num_adults + num_children), was[was.net_physical.>0,:] )

regtable( reg_net_physical_1, reg_net_physical_2,reg_net_physical_3 ; renderSettings = LatexTable(), file="docs/wealth/net_physical.tex")
regtable( reg_net_physical_1, reg_net_physical_2,reg_net_physical_3 )


reg_net_housing_1 = lm( @formula( net_housing ~ 
    scotland + wales + london + north_west + yorkshire +east_midlands + west_midlands+  east_of_england + south_east + south_west +
    detatched + semi + terraced + purpose_build_flat + #  bedrooms +
    employee + selfemp + unemployed + student + inactive + sick +   
    female +
    owner + 
    age_25_34 + age_35_44 + age_45_54 + age_55_64 +  age_65_74 + age_75_plus + 
    weekly_gross_income + managerial + intermediate + 
    num_adults + num_children), was[was.net_housing .>0,:] )

reg_net_housing_2 = lm( @formula( log(net_housing) ~ 
    scotland + wales + london + north_west + yorkshire +east_midlands + west_midlands+  east_of_england + south_east + south_west +
    detatched + semi + terraced + purpose_build_flat + #  bedrooms +
    employee + selfemp + unemployed + student + inactive + sick +   
    female +
    owner +
    age_25_34 + age_35_44 + age_45_54 + age_55_64 +  age_65_74 + age_75_plus + 
    log(weekly_gross_income) + managerial + intermediate + 
    num_adults + num_children), was[(was.net_housing .>0).&(was.weekly_gross_income .>0),:] )

regtable( reg_net_housing_1, reg_net_housing_2 ; renderSettings = LatexTable(), file="docs/wealth/net_housing.tex")
regtable( reg_net_housing_1, reg_net_housing_2 )
    

has_pension = glm( @formula( has_pension_wealth ~ 
    scotland + wales + london + # north_west + yorkshire +
    # east_midlands + west_midlands + east_of_england + 
    # south_east + south_west +
    detatched + semi + terraced + purpose_build_flat + # #  bedrooms +
    unemployed + student + inactive + sick +       
    female +
    age_25_34 + age_35_44 + age_45_54 + age_55_64 +  age_65_74 + age_75_plus + 
    employee + selfemp + unemployed + student + inactive + sick +       
    owner + mortgaged + 
    log(weekly_gross_income) + managerial + intermediate + 
    num_adults + num_children), was, Binomial(), ProbitLink() )

reg_total_pensions_1 = lm( @formula( total_pensions ~ 
    scotland + wales + london + 
    # north_west + yorkshire +east_midlands + west_midlands + east_of_england + 
    south_east + south_west +
    detatched + semi + terraced + purpose_build_flat + # #  bedrooms +
    female +
    owner + mortgaged +    
    age_25_34 + age_35_44 + age_45_54 + age_55_64 +  age_65_74 + age_75_plus + 
    employee + selfemp + unemployed + student + inactive + sick +       
    owner + mortgaged +    
    weekly_gross_income + managerial + intermediate + 
    num_adults + num_children), was[was.total_pensions.>0,:] )

reg_total_pensions_2 = lm( @formula( log(total_pensions)  ~ 
    scotland + wales + london + # north_west + yorkshire +east_midlands + west_midlands+  east_of_england + south_east + south_west +
    detatched + semi + terraced + purpose_build_flat + #  bedrooms +
    female +
    owner + mortgaged +    
    age_25_34 + age_35_44 + age_45_54 + age_55_64 +  age_65_74 + age_75_plus + 
    employee + selfemp + unemployed + student + inactive + sick +       
    log(weekly_gross_income) + managerial + intermediate + 
    num_adults + num_children), was[(was.total_pensions.>0).&(was.weekly_gross_income .> 0),:] )

regtable( has_pension, reg_total_pensions_1, reg_total_pensions_2; renderSettings = LatexTable(), file="total_pensions.tex")
regtable( has_pension, reg_total_pensions_1, reg_total_pensions_2 )
    
final_regs = OrderedDict([
    :is_in_debt=>reg_is_in_debt_1, 
    :net_financial_wealth=>reg_net_financial_2, 
    :net_debt=>reg_net_financial_3, 
    :net_physical_wealth=>reg_net_physical_2, 
    :has_pension=>has_pension, 
    :net_pension_wealth=>reg_total_pensions_2, 
    :net_housing_wealth=>reg_net_housing_2 ])

regtable( collect(values(final_regs))... ; renderSettings = LatexTable(), file="docs/wealth/total_hh_disagg_wealth_logs.html")
regtable( collect(values(final_regs))... )

#=
for i in 1:size(final_regs)[1]
    CSV.write( "data/2023-4/uk_wealth_regressions/$(final_titles[i]).tab", 
        DataFrame(coeftable(final_regs[i]));delim='\t')
end
=#

#=
p5 = [predict(reg_net_financial_1) was[!,:net_financial]]

p6 = [exp.(predict(reg_net_financial_2)) was[was.net_financial.>0,:net_financial]]

v=exp.(predict(reg_net_physical_2))

Random.seed!(0)

## Example predict net physical

#e=rand(Normal(0,0.75),n)

# summary actual

n = size( reg_net_physical_1.mf.data.net_physical )[1]
# summary predicted - understates
wpd2 = predict( reg_net_physical_2 )
# std deviation of residuals - should also check for normality
sdf2 = std(residuals(reg_net_physical_2))
# random residuals with mean 0 same sd
edf2 = rand(Normal(0,sdf2), n)
# summary of predicted + random - same mean
summarystats(reg_net_physical_1.mf.data.net_physical)
summarystats( exp.(wpd2 ))
summarystats( exp.( wpd2+edf2 ))

n = size( reg_net_physical_1.mf.data.net_physical )[1]
# summary predicted - understates
wpd2 = predict( reg_net_physical_2 )
# std deviation of residuals - should also check for normality
sdf2 = std(residuals(reg_net_physical_2))
# random residuals with mean 0 same sd
edf2 = rand(Normal(0,sdf2), n)
# summary of predicted + random - same mean
summarystats(reg_net_physical_1.mf.data.net_physical)
summarystats( exp.(wpd2 ))
summarystats( exp.( wpd2+edf2 ))

for f in 1:size(final_regs)[1]
    println( final_titles[f], "  : ", dispersion( final_regs[f].model ))
    println( summarystats( exp.(predict( final_regs[f]))))

end
=#

