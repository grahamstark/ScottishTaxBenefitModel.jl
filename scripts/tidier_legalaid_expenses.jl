using Tidier,DataFrames,CSV

df = CSV.File( "/tmp/output/test_of_inferred_capital_2_off_1_legal_aid_civil.tab")|>DataFrame

.......................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................
@chain df begin
         @group_by( entitlement )
         @summarize( 
            mean_childcare = sum( childcare * weight )/sum(weight),
            mean_housing = sum( housing * weight )/sum(weight),
            mean_work_expenses = sum( work_expenses * weight )/sum(weight),
            mean_repayments = sum( repayments * weight )/sum(weight),
            mean_maintenance = sum( maintenance * weight )/sum(weight),
            mean_outgoings = sum( outgoings * weight )/sum(weight))
end