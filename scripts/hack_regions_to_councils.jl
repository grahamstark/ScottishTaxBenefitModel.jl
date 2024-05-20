using CSV,DataFrames

#
# hack - insert a nation in the 'councils' slot 
# for uk wide FRS hh data
#
hh = CSV.File( "../data/model_households-2015-2021.tab") |> DataFrame

nrs,ncs = size(hh)
hh.council = fill( :x, nrs )
for r in eachrow(hh)
    r.council = if r.region in 112000001:112000009
        :ENGLAND
    elseif r.region == 299999999
        :SCOTLAND
    elseif r.region == 399999999
        :WALES
    elseif r.region == 499999999
        :NIRELAND
    end
end

CSV.write( "../data/model_households-2015-2021.tab", hh )

