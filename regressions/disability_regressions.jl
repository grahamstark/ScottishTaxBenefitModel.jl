#
# Regressions for take-up of disability benefits.
# using just what's in the model datasets
#
include("intro.jl")
using STBRegressions

const STB_MODEL="/home/graham_s/julia/vw/ScottishTaxBenefitModel/"
const STB_DATA_DIR="$STB_MODEL/data/"

frshh = CSV.File( "$STB_DATA_DIR/model_households.tab" ) |> DataFrame
frspeople = CSV.File( "$STB_DATA_DIR/model_people.tab" ) |> DataFrame

fm = innerjoin( frshh, frspeople, on=[:data_year, :hid ] )

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
fm.rec_dla = ( fm.income_dlamobility.>0.0) .| ( fm.income_dlaself_care .>0.0 )
fm.rec_dla_care = ( fm.income_dlaself_care .>0.0 )
fm.rec_dla_mob = ( fm.income_dlamobility.>0.0 )
fm.rec_pip = ( fm.income_personal_independence_payment_mobility.>0.0) .| ( fm.income_personal_independence_payment_daily_living .>0.0 )
fm.rec_pip_care = ( fm.income_personal_independence_payment_daily_living .>0.0 )
fm.rec_pip_mob = ( fm.income_personal_independence_payment_mobility.>0.0)
fm.rec_esa = ( fm.income_employment_and_support_allowance.>0.0)
fm.rec_aa = ( fm.income_attendence_allowance.>0.0)
fm.rec_carers = ( fm.income_carers_allowance.>0.0)
fm_rec_aa = ( fm.income_attendence_allowance.>0.0)
fm.scotland = fm.region .== 299999999
fm.male = fm.sex .== 1

# subsets
fm_working_age = fm[((fm.age .< 65).&(fm.from_child_record.!= 1)),:]
fm_pension_age = fm[(fm.age .>= 65),:]

#
# TODO attendance allowance
# regressions
#
targets = Dict(
  :rec_aa=>fm_pension_age,
  :rec_pip=>fm_working_age,
  :rec_pip_mob=>fm_working_age,
  :rec_pip_care=>fm_working_age,
  :rec_esa=>fm_working_age,
  :rec_dla=>fm,
  :rec_dla_mob=>fm,
  :rec_dla_care=>fm )


main_out = []

for( target, dataset ) in targets
    # note: using `Term(..)` like this allows
    #
    push!(main_out, glm(
      (
        Term( target ) ~
          Term( :data_year )+
          Term( :scotland )+
          Term( :male )+
          Term( :age )+
          Term( :age )&Term(:age)+
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
          Term( :disability_other_difficulty )),
      dataset,
      Binomial(),
      ProbitLink(),
      contrasts=Dict( :data_year=>DummyCoding()
      )
    ))
end

RegressionTables.regtable( main_out ... )
