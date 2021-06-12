# Snippets
using StatsBase,CSV,DataFrames
# dist of everyone on a benefit
countmap(people.income_widows_payment)

# extract some info on everyone with some benefit 
people[((people.income_bereavement_allowance_or_widowed_parents_allowance_or_bereavement.>0).& .! ismissing.(people.income_bereavement_allowance_or_widowed_parents_allowance_or_bereavement)),[:age,:sex,:income_bereavement_allowance_or_widowed_parents_allowance_or_bereavement,:data_year]]

