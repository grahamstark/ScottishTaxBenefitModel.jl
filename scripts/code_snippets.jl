# Snippets
using StatsBase,CSV,DataFrames
# dist of everyone on a benefit
countmap(people.income_widows_payment)

# extract some info on everyone with some benefit 
people[((people.income_personal_independence_payment.>0).& .! ismissing.(people.income_personal_independence_payment)),
    [:age,:sex,:income_personal_independence_payment,:type_of_bereavement_allowance,:data_year]]

people[((people.income_personal_independence_payment_daily_living.>0).& .! ismissing.(people.income_personal_independence_payment_daily_living)),
    [:age,:sex,:income_personal_independence_payment_daily_living,:income_personal_independence_payment_mobility,:data_year]]

i = 0
for r in eachrow(people[((people.income_personal_independence_payment_daily_living.>0).& .! ismissing.(people.income_personal_independence_payment_daily_living)),
    [:age,:sex,:income_personal_independence_payment_daily_living,:income_personal_independence_payment_mobility,:data_year]])
    i += 1
    println("$i $(r.age) $(r.age) $(r.income_personal_independence_payment_daily_living) $(r.income_personal_independence_payment_mobility)")
end
