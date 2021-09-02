#
# add a random field to hhld and person dataframes
# 
using CSV,DataFrames,ScottishTaxBenefitModel.Randoms

people=CSV.File( "data/model_people_scotland.tab" )|>DataFrame
n = size(people)[1]
people.onerand=fill("",n)
for i in 1:n
    people[i,:onerand]=mybigrandstr()
end
CSV.write("data/model_people_scotland.tab", people, delim = "\t")

n = size(hhlds)[1]
hhld.onerand=fill("",n)
for i in 1:n
    hhlds[i,:onerand]=mybigrandstr()
end
CSV.write("data/model_households_scotland.tab", hhlds, delim = "\t")

# ... and so on for examples, UK data as needed.