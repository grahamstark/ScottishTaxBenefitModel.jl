#
# Regressions for take-up of disability benefits.
# using just what's in the model datasets
#
# include("intro.jl")
# using STBRegressions

using ScottishTaxBenefitModel
using .Definitions
using .RunSettings: Settings
using CSV,DataFrames,GLM,RegressionTables


const settings = Settings()

#
# UK wide with Scottish dummy
#
frshh = CSV.File("$(MODEL_DATA_DIR)/model_households.tab" ) |> DataFrame
frspeople = CSV.File("$(MODEL_DATA_DIR)/model_people.tab") |> DataFrame

fm = innerjoin( frshh, frspeople, on=[:data_year, :hid ], makeunique=true )

fm = innerjoin( frshh, frspeople, on=[:data_year, :hid ], makeunique=true )
fm.age_sq = fm.age.^2
fm.deaf_blind=fm.registered_blind .| fm.registered_deaf .| fm.registered_partially_sighted
fm.yr = fm.data_year .- 2014
fm.any_dis = (
    fm.disability_vision .|
    fm.disability_hearing .|
    fm.disability_mobility .|
    fm.disability_dexterity .|
    fm.disability_learning .|
    fm.disability_memory .|
    fm.disability_other_difficulty .|
    fm.disability_mental_health .|
    fm.disability_stamina .|
    fm.disability_socially )
fm.adls_bad=fm.adls_are_reduced.==1
fm.adls_mid=fm.adls_are_reduced.==2
fm.rec_carers = fm.income_carers_allowance .> 0
fm.rec_dla = ( fm.income_dlamobility.>0.0) .| ( fm.income_dlaself_care .>0.0 )
fm.rec_dla_child = ( fm.rec_dla ) .& (fm.age .<= 16 )
fm.rec_dla_adult = ( fm.rec_dla ) .& (fm.age .> 16 )

fm.rec_dla_care = ( fm.income_dlaself_care .>0.0 )
fm.rec_dla_mob = ( fm.income_dlamobility.>0.0 )
fm.rec_pip = ( fm.income_personal_independence_payment_mobility.>0.0) .| ( fm.income_personal_independence_payment_daily_living .>0.0 )
fm.rec_pip_care = ( fm.income_personal_independence_payment_daily_living .>0.0 )
fm.rec_pip_mob = ( fm.income_personal_independence_payment_mobility.>0.0)
fm.rec_esa = ( fm.income_employment_and_support_allowance.>0.0)
fm.rec_aa = ( fm.income_attendance_allowance.>0.0)
fm.rec_carers = ( fm.income_carers_allowance.>0.0)
fm_rec_aa = ( fm.income_attendance_allowance.>0.0)
fm.scotland = fm.region .== 299999999
fm.male = fm.sex .== 1

# subsets
fm_working_age = fm[((fm.age .< 65).&(fm.age .> 16 )),:]
fm_pension_age = fm[(fm.age .>= 65),:]
fm_children = fm[(fm.age .<= 16),:]

#
# Regress on everything.
#
main_out = []

bens = [
  # :rec_dla_child, # in children - too many regressors
  :rec_carers,
  :rec_pip,
  :rec_pip_mob,
  :rec_pip_care,
  :rec_esa,
  :rec_dla_adult, # in adults
  :rec_dla_mob,
  :rec_dla_care,
  :rec_aa ]
	
  datasets = Dict(
    :rec_dla_child=>fm_children,
    :rec_carers=>fm,
    :rec_pip=>fm_working_age,
    :rec_pip_mob=>fm_working_age,
    :rec_pip_care=>fm_working_age,
    :rec_esa=>fm_working_age,
    :rec_dla_adult=>fm_working_age,
    :rec_dla_mob=>fm_working_age,
    :rec_dla_care=>fm_working_age,
    :rec_aa=>fm_pension_age )
    
    main_out=[]
	
for target in bens
      v = glm(
        Term( target ) ~
          Term( :scotland ) + 
          Term( :data_year )+
          Term( :male )+
          Term( :age )+
          Term( :age_sq ) +
          Term( :has_long_standing_illness )+
          Term( :adls_bad )+
          Term( :adls_mid )+
          Term( :registered_blind )+
          Term( :registered_partially_sighted )+
          Term( :registered_deaf )+

          Term( :disability_dexterity )+
          Term( :disability_learning )+
          Term( :disability_memory )+
          Term( :disability_mental_health )+
          Term( :disability_mobility )+
          Term( :disability_socially )+
          Term( :disability_stamina )+
          Term( :disability_other_difficulty ),
        datasets[target ],
        Binomial(),
        ProbitLink(), contrasts=Dict( :data_year=>DummyCoding()))
    push!( main_out, v )
end

RegressionTables.regtable( main_out ...;  renderSettings = latexOutput("disability_regressions.tex"))
RegressionTables.regtable( main_out ... )

##
# significant ones only
#
# just over 
rec_carers = glm( @formula( rec_carers ~ male+age+age_sq+adls_bad+adls_mid+registered_deaf+disability_mental_health), fm, Binomial(), ProbitLink() )
rec_pip =  glm( @formula( rec_pip ~ scotland+data_year+has_long_standing_illness+adls_bad+adls_mid+disability_memory+disability_mental_health+disability_mobility ), fm_working_age, Binomial(), ProbitLink(), contrasts=Dict( :data_year=>DummyCoding()) )
rec_pip_care =  glm( @formula( rec_pip_care ~ scotland+data_year+has_long_standing_illness+adls_bad+adls_mid+disability_memory+disability_mental_health+disability_mobility ), fm_working_age, Binomial(), ProbitLink(), contrasts=Dict( :data_year=>DummyCoding()) )
rec_pip_mob =  glm( @formula( rec_pip_mob ~ scotland+data_year+registered_blind+has_long_standing_illness+adls_bad+adls_mid+disability_memory+disability_mental_health+disability_mobility ), fm_working_age, Binomial(), ProbitLink(), contrasts=Dict( :data_year=>DummyCoding()) )
rec_aa = glm( @formula( rec_aa ~ male+adls_bad+adls_mid+registered_blind+disability_dexterity+disability_mental_health+disability_mobility ), fm_pension_age, Binomial(), ProbitLink())

#
# v. simple child one that combines mob and care 
# 
rec_dla_child = glm( @formula( rec_dla_child ~ male+adls_bad+disability_mental_health ), fm_children, Binomial(), ProbitLink() )

RegressionTables.regtable( rec_carers, rec_pip, rec_pip_care, rec_pip_mob, rec_aa, rec_dla_child )

fm_working_age.pip_care_prob = predict( rec_pip_care )
fm_working_age.pip_mob_prob = predict( rec_pip_mob )
fm_pension_age.aa_prob = predict( rec_aa )
fm_children.dla_prob = predict( rec_dla_child )

#
# Everybody *Not* receiving pip_care or DLA, ranked by probability of receiving it
#
positive_candidates_pip_care = fm_working_age[(((fm_working_age.rec_pip_care .== false) .& (fm_working_age.rec_dla_care .== false)) .& (fm_working_age.scotland .== true)), [:data_year,:hid,:pid,:weight, :pip_care_prob,:rec_pip_care,:rec_dla_care,:scotland]]
sort!(positive_candidates_pip_care, :pip_care_prob, rev=true )
CSV.write( "data/disability/positive_candidates_pip_care.csv", positive_candidates_pip_care )

#
# *least* likely people to be on PIP Care who are on it
#
negative_candidates_pip_care = fm_working_age[((fm_working_age.rec_pip_care .== true) .& (fm_working_age.scotland .== true)), [:data_year,:hid,:pid,:weight, :pip_care_prob,:rec_pip_care,:rec_dla_care,:scotland]]
sort!(negative_candidates_pip_care, :pip_care_prob  )
CSV.write( "data/disability/negative_candidates_pip_care.csv", negative_candidates_pip_care )

#
# Everybody *Not* receiving pip_mobility or DLA, ranked by probability of receiving it. For a more generous test, we go down this list.
#
positive_candidates_pip_mob = fm_working_age[((fm_working_age.rec_pip_mob .== false) .& (fm_working_age.rec_dla_mob .== false) .& (fm_working_age.scotland .== true)), [:data_year,:hid,:pid,:weight, :pip_mob_prob,:rec_pip_mob,:rec_dla_care,:scotland]]
sort!(positive_candidates_pip_mob, :pip_mob_prob, rev=true )
CSV.write( "data/disability/positive_candidates_pip_mob.csv", positive_candidates_pip_mob )

#
# *least* likely people to be on PIP Mobility who are actually on it. If we want a less generous test, we go down this list.
#
negative_candidates_pip_mob = fm_working_age[((fm_working_age.rec_pip_mob .== true) .& (fm_working_age.scotland .== true)), [:data_year,:hid,:pid,:weight, :pip_mob_prob,:rec_pip_mob,:rec_dla_care,:scotland]]
sort!(negative_candidates_pip_mob, :pip_mob_prob )
CSV.write( "data/disability/negative_candidates_pip_mob.csv", negative_candidates_pip_mob )

#
# ditto for AA amongst pension age
#
positive_candidates_aa = fm_pension_age[((fm_pension_age.rec_aa .== false) .& (fm_pension_age.scotland .== true)), [:data_year,:hid,:pid,:weight, :aa_prob,:rec_aa,:scotland]]
sort!(positive_candidates_aa, :aa_prob, rev=true )
CSV.write( "data/disability/positive_candidates_aa.csv", positive_candidates_aa )
#
# *least* likely people to be on AA who are actually on it. If we want a less generous test, we go down this list.
#
negative_candidates_aa = fm_pension_age[((fm_pension_age.rec_aa .== true) .& (fm_pension_age.scotland .== true)), [:data_year,:hid,:pid,:weight, :aa_prob,:rec_aa,:scotland]]
sort!(negative_candidates_aa, :aa_prob )

CSV.write( "data/disability/negative_candidates_aa.csv", negative_candidates_aa )

#
# ditto for DLA amongst children
#
positive_candidates_aa = fm_pension_age[((fm_pension_age.rec_aa .== false) .& (fm_pension_age.scotland .== true)), [:data_year,:hid,:pid,:weight, :aa_prob,:rec_aa,:scotland]]
sort!(positive_candidates_aa, :aa_prob, rev=true )
CSV.write( "data/disability/positive_candidates_aa.csv", positive_candidates_aa )
#
# *least* likely people to be on AA who are actually on it. If we want a less generous test, we go down this list.
#
negative_candidates_aa = fm_pension_age[((fm_pension_age.rec_aa .== true) .& (fm_pension_age.scotland .== true)), [:data_year,:hid,:pid,:weight, :aa_prob,:rec_aa,:scotland]]
sort!(negative_candidates_aa, :aa_prob )

CSV.write( "data/disability/negative_candidates_aa.csv", negative_candidates_aa )



positive_candidates_dla_children = fm_children[((fm_children.rec_dla .== false) .& (fm_children.scotland .== true)), [:data_year,:hid,:pid,:weight, :dla_prob,:rec_dla,:scotland]]
sort!(positive_candidates_dla_children, :dla_prob, rev=true )
CSV.write( "data/disability/positive_candidates_dla_children.csv", positive_candidates_dla_children )
#
# *least* likely people to be on AA who are actually on it. If we want a less generous test, we go down this list.
#
negative_candidates_dla_children = fm_children[((fm_children.rec_dla .== true) .& (fm_children.scotland .== true)), [:data_year,:hid,:pid,:weight, :dla_prob,:rec_dla,:scotland]]
sort!(negative_candidates_dla_children, :dla_prob )
CSV.write( "data/disability/negative_candidates_dla_children.csv", negative_candidates_dla_children )
