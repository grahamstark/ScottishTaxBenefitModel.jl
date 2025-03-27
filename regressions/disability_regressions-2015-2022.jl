#
# Regressions for take-up of disability benefits.
# using just what's in the model datasets
# using the 2015-22 dataset with categorical vars

using CSV,DataFrames,GLM,RegressionTables

function hack_num_people( r :: DataFrameRow )::Int
  for p in 2:15
    k = Symbol("relationship_$(p)")
    s = r[k]
    if s == "Missing_Relationship"
      return p-1
    end
  end
  return 15 # never happens
end


frshh = CSV.File( "data/actual_data/model_households-2015-2022-w-enums-2.tab" ) |> DataFrame
frspeople = CSV.File( "data/actual_data/model_people-2015-2022-w-enums-2.tab") |> DataFrame

fm = innerjoin( frshh, frspeople, on=[:data_year, :hid ], makeunique=true )
for r in eachrow(fm)
  if r.adls_are_reduced == "Missing_ADLS_Inhibited"
    r.adls_are_reduced = "not_reduced"
  end
end

fm.age_sq = fm.age.^2
fm.num_people = hack_num_people.(eachrow( fm ))
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
# fm.adls_bad=fm.adls_are_reduced.==1
# fm.adls_mid=fm.adls_are_reduced.==2
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
fm.any_disability = fm.rec_dla_care .||
      fm.rec_dla_mob .|| 
      fm.rec_pip .|| 
      fm.rec_aa 
fm.any_carers = fm.rec_carers
fm.dis_score =     
  fm.disability_vision .+
  fm.disability_hearing .+
  fm.disability_mobility .+
  fm.disability_dexterity .+
  fm.disability_learning .+
  fm.disability_memory .+
  fm.disability_other_difficulty .+
  fm.disability_mental_health .+
  fm.disability_stamina .+
  fm.disability_socially .+
  fm.registered_blind .+
  (fm.registered_partially_sighted.*0.5) .+
  fm.registered_deaf .+
  fm.has_long_standing_illness
  for r in eachrow(fm)
    r.dis_score += if r.adls_are_reduced == "reduced_a_little"
      2.0
    elseif r.adls_are_reduced == "reduced_a_lot"
      1.0
    else
      0.0
    end
  end

fm.gives_care = fm.hours_of_care_given .> 0
fm.receives_care = fm.hours_of_care_received .> 0

fm.scotland = fm.region .== "Scotland"
# fm.male = fm.sex .== 1

# subsets
fm_working_age = fm[((fm.age .< 65).&(fm.age .>= 16 )),:]
fm_pension_age = fm[(fm.age .>= 65),:]
fm_children = fm[(fm.age .< 16),:]

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
  :rec_aa
   ]
	
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
   
terms = 
  Term( :region ) + 
  Term( :data_year )+
  Term( :sex )+
  Term( :age )+
  Term( :age_sq ) +
  Term( :num_people ) +
  Term( :has_long_standing_illness )+
  Term( :adls_are_reduced )+
  Term( :registered_blind )+
  Term( :registered_partially_sighted )+
  Term( :registered_deaf )+
  Term( :gives_care ) +
  Term( :receives_care ) +
  Term( :disability_dexterity )+
  Term( :disability_learning )+
  Term( :disability_memory )+
  Term( :disability_mental_health )+
  Term( :disability_mobility )+
  Term( :disability_socially )+
  Term( :disability_stamina )+
  Term( :disability_other_difficulty )

  #= old by-benefit code 
for target in bens
      ds = datasets[ target ]
      v = glm(
        Term( target ) ~ terms,
        ds,
        Binomial(),
        ProbitLink(), contrasts=Dict( :data_year=>DummyCoding()))
    push!( main_out, v )
    probkey = Symbol( "$(target)_prob" )
    ds[!, probkey] = predict( v )
    # all those who haven't got the benefit, ranked by highest->lowest modelled prob of receipt. Add these in 1st when modelling
    # more generous eligibility test.
    positive_candidates = ds[(ds[!,target] .== 0) .& (ds.region .== "Scotland"), [:data_year,:hid,:pid,:weight, probkey, target ]]   
    sort!(positive_candidates, probkey, rev=true )

    # all those who have got the benefit, ranked by lowest->highest modelled prob of receipt. Eliminate these 1st if modelling
    # a reduction in entitlement.
    negative_candidates = ds[(ds[!,target] .== 1) .& (ds.region .== "Scotland"), [:data_year,:hid,:pid,:weight, probkey, target ]]
    sort!(negative_candidates, probkey )
    CSV.write( "data/actual_data/positive_candidates_$(target).tab", positive_candidates )
    CSV.write( "data/actual_data/negative_candidates_$(target).tab", negative_candidates )
    println( "writing to data/actual_data/negative_candidates_$(target).tab")
end

RegressionTables.regtable( main_out ...;  render = LatexTable(), file="docs/disability_regressions-2015-22.tex" )
RegressionTables.regtable( main_out ... )

=#

function make_candidates( ds :: DataFrame, target::Symbol, dname :: String, probkey::Symbol )
  # all those who haven't got the benefit, ranked by highest->lowest modelled prob of receipt. Add these in 1st when modelling
  # more generous eligibility test.
  positive_candidates = ds[(ds[!,target] .== 0) .& (ds.region .== "Scotland"), [:data_year,:hid,:pid,:weight, probkey, target ]]   
  sort!(positive_candidates, probkey, rev=true )
  # all those who have got the benefit, ranked by lowest->highest modelled prob of receipt. Eliminate these 1st if modelling
  # a reduction in entitlement.
  negative_candidates = ds[(ds[!,target] .== 1) .& (ds.region .== "Scotland"), [:data_year,:hid,:pid,:weight, probkey, target ]]
  sort!(negative_candidates, probkey )
  CSV.write( "data/actual_data/positive_candidates_$(target)_$(dname).tab", positive_candidates; delim='\t' )
  CSV.write( "data/actual_data/negative_candidates_$(target)_$(dname).tab", negative_candidates; delim='\t' )
  println( "writing to data/actual_data/negative_candidates_$(target)_$(dname).tab")
end

#=
Now, again for amalgamated datasets.
=#
main_out = []
for target in [:any_disability,:any_carers]
    dsno = 0
    for ds in [fm_working_age,fm_pension_age]
        dsno += 1
        v = glm(
          Term( target ) ~ terms,
          ds,
          Binomial(),
          ProbitLink(), contrasts=Dict( :data_year=>DummyCoding()))
        push!( main_out, v )
        probkey = Symbol( "$(target)_prob" )
        ds[!, probkey] = predict( v )
        dname = dsno == 1 ? "working_age" : "pensioners"
        make_candidates( ds, target, dname, probkey )
      end
end

RegressionTables.regtable( main_out ...;  render = LatexTable(), file="docs/disability_regressions-2015-22.tex" )
RegressionTables.regtable( main_out ... )

dspp = vcat( fm_working_age, fm_pension_age )
make_candidates(dspp, :any_carers, "all_adults", :any_carers_prob )



#=
We have no child receips FUCKKKKK
so we can't regress...
So just make up a score
=#

sickkids = sort( fm_children[fm_children.region.=="Scotland",[:data_year,:hid,:pid,:weight, :dis_score ]],:dis_score, rev=true )
CSV.write( "data/actual_data/child_disabilities_ranked.tab", sickkids; delim='\t' )


