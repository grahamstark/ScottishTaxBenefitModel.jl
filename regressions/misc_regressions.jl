
fm = innerjoin( frshh, frspeople, on=[:data_year, :hid ] )

summarystats( fm[:tenure])

adddummies!( fm, hhv[:tentyp2], alias="tenure", use_value_as_label=true, missings_to_zero=true)
adddummies!( fm, hhv[:gvtregn], alias="region", use_value_as_label=false, missings_to_zero = true )

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

adddummies!(fm, hha[:heathad], alias="health_status" )
countmap(frsadult.HEATHAD)

print(countmap(frsadult.HEALTH1)) # long-standing illness
# Do you have any physical or mental health conditions or illnesses lasting or
# expected to last for 12 months or more?
print(countmap(frsadult.CONDIT)) # 'Whether condition limits day to day activities'
# Does your condition or illness/do any of your conditions or illnesses reduce your
# ability to carry-out day-to-day activities?

print(countmap(frsadult.DDATREP1)) # ever, but not now illness,disability limited activities
print(countmap(frsadult.DDAPROG1)) # ever, but not now: DDAPROG1 progressive illness 1 = adls down a little 2=lot

countmap(frsadult.LIMITL)
"For how long has your ability to carry-out day-to-day activities been reduced?"

# TODO fm = innerjoin( fm, frsadult, on=[:data_year, :hid ] )
make_enumerated_type( "Illness_Length", hha[:limitl ] )

println( make_enumerated_type( "Illness_Length", hha[:limitl ], true, true ))


println( make_enumerated_type( "ADLS_Inhibited", hha[:condit ], true, true ))


println( make_enumerated_type( "Long_Standing_Illness", hha[:health1 ], true, true ))

fm.adls_bad=fm.adls_are_reduced.==1
fm.adls_mid=fm.adls_are_reduced.==2
fm.rec_dla = ( fm.income_dlamobility.>0.0) .| ( fm.income_dlaself_care .>0.0 )
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

fm_working_age = fm[((fm.age .< 65).&(fm.from_child_record.!= 1)),:]
fm_pension_age = fm[(fm.age .>= 65),:]

dla_1=glm(@formula(rec_dla ~ male+age+age^2+has_long_standing_illness), fm, Binomial(), ProbitLink())
dla_2=glm(@formula(rec_dla ~ male+age+age^2+has_long_standing_illness+adls_are_reduced), fm, Binomial(), ProbitLink() )
dla_3=glm(@formula(rec_dla ~ male+age+age^2+has_long_standing_illness+adls_are_reduced+registered_blind), fm, Binomial(), ProbitLink() )
dla_4=glm(@formula(rec_dla ~ male+age+age^2+has_long_standing_illness+adls_are_reduced+registered_blind+registered_deaf), fm, Binomial(), ProbitLink() )
dla_5=glm(@formula(rec_dla ~ male+age+age^2+has_long_standing_illness+adls_bad+registered_blind+registered_deaf), fm, Binomial(), ProbitLink() )
dla_6=glm(
  @formula(
    rec_dla ~
      data_year+
      scotland+
      male+
      age+
      age^2+
      has_long_standing_illness+
      adls_bad+
      adls_mid+
      registered_blind+
      registered_partially_sighted+
      registered_deaf+
      disability_dexterity+
      disability_learning+
      disability_memory+
      disability_mental_health+
      disability_mobility+
      disability_socially+
      disability_stamina+
      disability_other_difficulty),
  fm,
  Binomial(),
  ProbitLink(),
  contrasts=Dict( :data_year=>DummyCoding()
  )
)

pred=StatsBase.predict(dla_1)

tab_dla = RegressionTables.regtable(dla_1,dla_2,dla_3,dla_4,dla_5,dla_6)

esa_1=glm(@formula(rec_esa ~ male+age+age^2+has_long_standing_illness), fm_working_age, Binomial(), ProbitLink())
esa_2=glm(@formula(rec_esa ~ male+age+age^2+has_long_standing_illness+adls_are_reduced), fm_working_age, Binomial(), ProbitLink() )
esa_3=glm(@formula(rec_esa ~ male+age+age^2+has_long_standing_illness+adls_are_reduced+registered_blind), fm_working_age, Binomial(), ProbitLink() )
esa_4=glm(@formula(rec_esa ~ male+age+age^2+has_long_standing_illness+adls_are_reduced+registered_blind+registered_deaf), fm_working_age, Binomial(), ProbitLink() )
esa_5=glm(@formula(rec_esa ~ male+age+age^2+has_long_standing_illness+adls_bad+registered_blind+registered_deaf), fm_working_age, Binomial(), ProbitLink() )
esa_6=glm(
  @formula(
    rec_esa ~
      data_year+
      scotland+
      male+
      age+
      age^2+
      has_long_standing_illness+
      adls_bad+
      adls_mid+
      registered_blind+
      registered_partially_sighted+
      registered_deaf+
      disability_dexterity+
      disability_learning+
      disability_memory+
      disability_mental_health+
      disability_mobility+
      disability_socially+
      disability_stamina+
      disability_other_difficulty),
  fm_working_age,
  Binomial(),
  ProbitLink(),
  contrasts=Dict( :data_year=>DummyCoding()
  )
)

pred=StatsBase.predict(esa_1)

tab_esa = RegressionTables.regtable(esa_1,esa_2,esa_3,esa_4,esa_5,esa_6)


pip_1=glm(@formula(rec_pip ~ male+age+age^2+has_long_standing_illness), fm_working_age, Binomial(), ProbitLink())
pip_2=glm(@formula(rec_pip ~ male+age+age^2+has_long_standing_illness+adls_are_reduced), fm_working_age, Binomial(), ProbitLink() )
pip_3=glm(@formula(rec_pip ~ male+age+age^2+has_long_standing_illness+adls_are_reduced+registered_blind), fm_working_age, Binomial(), ProbitLink() )
pip_4=glm(@formula(rec_pip ~ male+age+age^2+has_long_standing_illness+adls_are_reduced+registered_blind+registered_deaf), fm_working_age, Binomial(), ProbitLink() )
pip_5=glm(@formula(rec_pip ~ male+age+age^2+has_long_standing_illness+adls_bad+registered_blind+registered_deaf), fm_working_age, Binomial(), ProbitLink() )
pip_6=glm(
  @formula(
    rec_pip ~
      data_year+
      scotland+
      male+
      age+
      age^2+
      has_long_standing_illness+
      adls_bad+
      adls_mid+
      registered_blind+
      registered_partially_sighted+
      registered_deaf+
      disability_dexterity+
      disability_learning+
      disability_memory+
      disability_mental_health+
      disability_mobility+
      disability_socially+
      disability_stamina+
      disability_other_difficulty),
  fm_working_age,
  Binomial(),
  ProbitLink(),
  contrasts=Dict( :data_year=>DummyCoding()
  )
)

pred=StatsBase.predict(pip_1)

tab_pip = RegressionTables.regtable(pip_1,pip_2,pip_3,pip_4,pip_5,pip_6)

aa_6=glm(
  @formula(
    rec_aa ~
      data_year+
      scotland+
      male+
      age+
      age^2+
      has_long_standing_illness+
      adls_bad+
      adls_mid+
      registered_blind+
      registered_partially_sighted+
      registered_deaf+
      disability_dexterity+
      disability_learning+
      disability_memory+
      disability_mental_health+
      disability_mobility+
      disability_socially+
      disability_stamina+
      disability_other_difficulty),
  fm_pension_age,
  Binomial(),
  ProbitLink(),
  contrasts=Dict( :data_year=>DummyCoding()
  )
)

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
