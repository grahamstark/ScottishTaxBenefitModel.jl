using CSV,DataFrames
using ScottishTaxBenefitModel
using .Definitions
using .HouseholdFromFrame
#
# hack - insert a nation in the 'councils' slot 
# for uk wide FRS hh data
#
hh = read_hh( "data/actual_data/model_households-2015-2021-w-enums-2.tab") |> DataFrame

# force a type on the council col - initially all missing - not needed
# nrs,ncs = size(hh)
# hh.council = fill( :x, nrs )
for r in eachrow(hh)
    r.council = if r.region in [
        North_East, 
        North_West,
        Yorks_and_the_Humber,
        East_Midlands,
        West_Midlands,
        East_of_England,
        London,
        South_East,
        South_West]
        :ENGLAND
    elseif r.region == Scotland
        :SCOTLAND
    elseif r.region == Wales
        :WALES
    elseif r.region == Northern_Ireland
        :NIRELAND
    end
end

#
# the read_hh strips off the "X" from the big rand str, which is needed to save e.g. to spreadsheets
# so just put it back before saving.
#
hh.onerand = "X" .* hh.onerand

CSV.write( "data/actual_data/model_households-2015-2021-w-enums-2.tab", hh; delim='\t' )
hh2021 = hh[hh.data_year.== 2021,:]
CSV.write( "data/actual_data/model_households-2021-2021-w-enums-2.tab", hh2021; delim='\t' )
