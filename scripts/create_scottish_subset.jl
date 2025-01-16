using CSV
using DataFrames
using ScottishTaxBenefitModel
using .Definitions
using .RunSettings

ADD_IN_MATCHING = true

settings = Settings()

household_name = "model_households-2015-2021-w-enums-2"
people_name = "model_people-2015-2021-w-enums-2"

hh_dataset = CSV.File("$(data_dir( settings ))/$(household_name).tab", delim='\t' ) |> DataFrame
people_dataset = CSV.File("$(data_dir( settings ))/$(people_name).tab", delim='\t') |> DataFrame

dropmissing!(people_dataset,:data_year) # kill!!! non hbai kids

scottish_hhlds = hh_dataset[(hh_dataset.region .== "Scotland"), :] #299999999),:]
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

CSV.write("$(data_dir( settings ))/model_households_scotland-2015-2021-w-enums-2.tab", scottish_hhlds, delim = "\t")
CSV.write("$(data_dir( settings ))/model_people_scotland-2015-2021-w-enums-2.tab", scottish_people, delim = "\t")

#
# write a 1 year all UK dataset while we're at it.
#
latest_year = maximum( hh_dataset.data_year )
uk_latest_hhlds = hh_dataset[(hh_dataset.data_year .== latest_year ),:]
uk_latest_people = semijoin( people_dataset, uk_latest_hhlds,on=[:hid,:data_year])
CSV.write("$(data_dir( settings ))/model_households-$(latest_year)-$(latest_year)-w-enums-2.tab", uk_latest_hhlds, delim = "\t")
CSV.write("$(data_dir( settings ))/model_people-$(latest_year)-$(latest_year)-w-enums-2.tab", uk_latest_people, delim = "\t")

