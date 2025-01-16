#
# FIXME straight copy of Scotland with names changed
# make this a function with country/code
#
using CSV
using DataFrames
using ScottishTaxBenefitModel
using .Definitions
using .RunSettings

ADD_IN_MATCHING = false

household_name = "model_households"
people_name = "model_people"

hh_dataset = CSV.File("$(data_dir())/$(household_name).tab", delim='\t' ) |> DataFrame
people_dataset = CSV.File("$(data_dir())/$(people_name).tab", delim='\t') |> DataFrame

dropmissing!(people_dataset,:data_year) # kill!!! non hbai kids

scottish_hhlds = hh_dataset[(hh_dataset.region .== 399999999),:]
scottish_people = semijoin(people_dataset, scottish_hhlds,on=[:hid,:data_year])

if ADD_IN_MATCHING
    shs_matches = CSV.File( "$(MATCHING_DIR)/mapped_from_shs_vars.tab" )|>DataFrame
    #
    # mh = innerjoin(scottish_hhlds,shs_matches,on=[:data_year,:hid],makeunique=true)
    # @assert size(mh)[1] == size( scottish_hhlds )[1]
    # match in previously calculated councils - no need for actual join
    #
    scottish_hhlds.council = shs_matches.council
    scottish_hhlds.nhs_board = shs_matches.nhs_board
    scottish_hhlds.bedrooms = shs_matches.bedrooms
end

CSV.write("$(data_dir())/model_households_wales.tab", scottish_hhlds, delim = "\t")
CSV.write("$(data_dir())/model_people_wales.tab", scottish_people, delim = "\t")