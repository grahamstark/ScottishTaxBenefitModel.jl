### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ fb37684a-0e82-11ec-227f-4595b4e5fa74
begin
	
	using Pkg
	 # activate the shared project environment
    Pkg.activate("/home/graham_s/julia/vs/ScottishTaxBenefitMode/")
	# Pkg.activate(Base.current_project())
	# Pkg.add( "https://github.com/grahamstark/ScottishTaxBenefitModel.jl" )
	using ScottishTaxBenefitModel
	using .Definitions
	using .RunSettings: Settings
	using CSV,DataFrames,GLM,RegressionTables
	
end

# ╔═╡ f00633e2-af9c-46cf-b4e6-2bf403d10392
begin
	
const settings = Settings()

frshh = CSV.File("$(MODEL_DATA_DIR)/model_households.tab" ) |> DataFrame
frspeople = CSV.File("$(MODEL_DATA_DIR)/model_people.tab") |> DataFrame

end

# ╔═╡ dc101061-f980-4fba-b223-8bbb88a7218f
begin
	
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
fm_working_age = fm[((fm.age .< 65).&(fm.from_child_record.!= 1)),:]
fm_pension_age = fm[(fm.age .>= 65),:]

	
sum( fm.scotland )
	size( fm )
	
end

# ╔═╡ 5d54d384-2b8e-4729-ab4a-dba5858c6f10
sum(fm_pension_age.rec_aa)

# ╔═╡ 187d3bbe-489b-485b-9db6-b3a44ef22c49
begin

bens = [
  :rec_carers,
  :rec_pip,
  :rec_pip_mob,
  :rec_pip_care,
  :rec_esa,
  :rec_dla,
  :rec_dla_mob,
  :rec_dla_care,
  :rec_aa ]
	
	
datasets = Dict(
  :rec_carers=>fm,
  :rec_pip=>fm_working_age,
  :rec_pip_mob=>fm_working_age,
  :rec_pip_care=>fm_working_age,
  :rec_esa=>fm_working_age,
  :rec_dla=>fm_working_age,
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
	main_out
end


# ╔═╡ faa4a768-baf0-4c79-a2e3-1c18b2ce903b
dla_1=glm(@formula(rec_dla ~ scotland + male+age+age^2+has_long_standing_illness+data_year+adls_bad+adls_mid+registered_blind+registered_partially_sighted+registered_deaf+disability_dexterity+disability_memory+disability_mental_health +disability_mobility+disability_socially+disability_stamina+disability_learning+disability_other_difficulty), fm_working_age, Binomial(), ProbitLink(), contrasts=Dict( :data_year=>DummyCoding()) )


# ╔═╡ Cell order:
# ╠═fb37684a-0e82-11ec-227f-4595b4e5fa74
# ╠═f00633e2-af9c-46cf-b4e6-2bf403d10392
# ╠═dc101061-f980-4fba-b223-8bbb88a7218f
# ╠═5d54d384-2b8e-4729-ab4a-dba5858c6f10
# ╠═187d3bbe-489b-485b-9db6-b3a44ef22c49
# ╠═faa4a768-baf0-4c79-a2e3-1c18b2ce903b
