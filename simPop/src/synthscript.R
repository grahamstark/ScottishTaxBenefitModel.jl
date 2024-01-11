# Experimenting building a synthetic model datasets
library( tidyverse )
library( simPop )
library(naniar) # replace_wth_na

# why tibble::tibble??
hh <- read.delim("../data/model_households_scotland.tab") |> tibble()
pers <- read.csv("../data/model_people_scotland.tab") |> tibble()
glimpse((hh))
glimpse(pers)
hh$newhhid <- as.integer(1000000*(hh$data_year-2014) + hh$hid)
hh$region <- as.factor( hh$region)
hh$tenure <- as.factor( hh$tenure )
hh$ct_band <- as.factor( hh$ct_band )
hh$dwelling <- as.factor( hh$dwelling )
hh$quarter <- as.factor( hh$quarter )
hh$data_year <- as.factor( hh$data_year )
hh$interview_year <- as.factor( hh$interview_year )
hh$council <- as.factor( hh$council )

pers$is_hrp = as.factor( pers$is_hrp )
pers$from_child_record = as.factor( pers$from_child_record )
pers$default_benefit_unit = as.factor( pers$default_benefit_unit )

pers$data_year <- as.factor( pers$data_year)
pers$sex = as.factor( pers$sex )
pers$ethnic_group = as.factor( pers$ethnic_group )
pers$marital_status = as.factor( pers$marital_status )
pers$highest_qualification = as.factor( pers$highest_qualification )
pers$sic = as.factor( pers$sic )
pers$occupational_classification = as.factor( pers$occupational_classification )
pers$public_or_private = as.factor( pers$public_or_private )
pers$principal_employment_type = as.factor( pers$principal_employment_type )
pers$socio_economic_grouping = as.factor( pers$socio_economic_grouping )
pers$age_completed_full_time_education = as.factor( pers$age_completed_full_time_education )
pers$years_in_full_time_work = as.factor( pers$years_in_full_time_work )
pers$employment_status = as.factor( pers$employment_status )
pers$usual_hours_worked = as.factor( pers$usual_hours_worked )
pers$actual_hours_worked = as.factor( pers$actual_hours_worked )
pers$age_started_first_job = as.factor( pers$age_started_first_job )
pers$type_of_bereavement_allowance = as.factor( pers$type_of_bereavement_allowance )
pers$had_children_when_bereaved = as.factor( pers$had_children_when_bereaved )
pers$contracted_out_of_serps = as.factor(pers$contracted_out_of_serps)
pers$registered_blind = as.factor( pers$registered_blind )
pers$registered_partially_sighted = as.factor( pers$registered_partially_sighted )
pers$registered_deaf = as.factor( pers$registered_deaf )
pers$disability_vision = as.factor( pers$disability_vision )
pers$disability_hearing = as.factor( pers$disability_hearing )
pers$disability_mobility = as.factor( pers$disability_mobility )
pers$disability_dexterity = as.factor( pers$disability_dexterity )
pers$disability_learning = as.factor( pers$disability_learning )
pers$disability_memory = as.factor( pers$disability_memory )
pers$disability_mental_health = as.factor( pers$disability_mental_health )
pers$disability_stamina = as.factor( pers$disability_stamina )
pers$disability_socially = as.factor( pers$disability_socially )
pers$disability_other_difficulty = as.factor( pers$disability_other_difficulty )
pers$health_status = as.factor( pers$health_status )
pers$has_long_standing_illness = as.factor( pers$has_long_standing_illness )
pers$adls_are_reduced = as.factor( pers$adls_are_reduced )
pers$is_informal_carer = as.factor( pers$is_informal_carer )
pers$receives_informal_care_from_non_householder = as.factor( pers$receives_informal_care_from_non_householder )
pers$childcare_type = as.factor( pers$childcare_type )
pers$employer_provides_child_care = as.factor( pers$employer_provides_child_care )
pers$company_car_fuel_type = as.factor( pers$company_car_fuel_type )
pers$relationship_to_hoh = as.factor( pers$relationship_to_hoh )
pers$relationship_1 = as.factor( pers$relationship_1 )
pers$relationship_2 = as.factor( pers$relationship_2 )
pers$relationship_3 = as.factor( pers$relationship_3 )
pers$relationship_4 = as.factor( pers$relationship_4 )
pers$relationship_5 = as.factor( pers$relationship_5 )
pers$relationship_6 = as.factor( pers$relationship_6 )
pers$relationship_7 = as.factor( pers$relationship_7 )
pers$relationship_8 = as.factor( pers$relationship_8 )
pers$relationship_9 = as.factor( pers$relationship_9 )
pers$relationship_10 = as.factor( pers$relationship_10 )
pers$relationship_11 = as.factor( pers$relationship_11 )
pers$relationship_12 = as.factor( pers$relationship_12 )
pers$relationship_13 = as.factor( pers$relationship_13 )
pers$relationship_14 = as.factor( pers$relationship_14 )
pers$relationship_15 = as.factor( pers$relationship_15 )

pers <- pers |> replace_with_na(replace = list(
  had_children_when_bereaved = c(-1),
  jsa_type = c(-1),
  esa_type = c(-1),
  dlaself_care_type = c(-1),
  dlamobility_type = c(-1),
  attendance_allowance_type = c(-1),
  personal_independence_payment_daily_living_type = c(-1),
  personal_independence_payment_mobility_type = c(-1),
  adls_are_reduced = c(-1),
  how_long_adls_reduced = c(-1),
  company_car_fuel_type = c(-1),
  relationship_3 = c(-1),
  relationship_4 = c(-1),
  relationship_5 = c(-1),
  relationship_6 = c(-1),
  relationship_7 = c(-1),
  relationship_8 = c(-1),
  relationship_9 = c(-1),
  relationship_10 = c(-1),
  relationship_11 = c(-1),
  relationship_12 = c(-1),
  relationship_13 = c(-1),
  relationship_14 = c(-1)))

merged <- pers |> inner_join( hh, by=c( "hid", "data_year")) |> arrange( hid, data_year )
# merged |> group_by( newhhid ) |> count()
merged$newhhid

hsizes <- merged |> count( newhhid )
# add a field 'n' count of each hh 
merged <- merged |> left_join( hsizes ) 

glimpse( merged )
minp <- specifyInput( data = merged, hhid="hid", weight="weight", hhsize="n", strata="interview_year" )
simhh <- simStructure( data = minp, method="direct", basicHHvars=c("sex","age", "from_child_record"))
simhh <- simCategorical( simhh, additional =c("employment_status", "tenure"), method="multinom", nr_cpus=1)
# eusilcS
warnings()
glimpse( simhh )
