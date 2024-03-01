### 
#
# Fuel regressions 
#

using Markdown
using CSV
using GLM
# using Makie
# using CairoMakie
using CategoricalArrays
using DataFrames
using RegressionTables
using StatsBase
using Formats
using Statistics
using StatsModels
using Colors
using Dates

using ScottishTaxBenefitModel
using .TimeSeriesUtils: parse_ons_date
using .HouseholdFromFrame

using .Utils

function fp( m )
	Format.format(m*100; precision=2 )*"%"
end

function fc( m )
	Format.format(m; precision=0, commas=true )
end

"""
must be a standard way of broadcasting but ..
"""
function isin( x, y... )
	for z in y
		# println( z )
	  	if x == z
			return 1
	  	end
	end
	return 0
end

#=
mm23 = CSV.File( "/mnt/data/prices/mm23/mm23_edited.csv")|>DataFrame
lcnames = Symbol.(lowercase.(string.(names(mm23))))
rename!( mm23, lcnames ) # jam lowercase names
mm23.date = parse_ons_date.( mm23.cdid )
=#

const SCJS_FILES = [
	"/mnt/data/scjs/1718/tab/scjs1718__nvf-main_y2_eul_20190508.tab",
	"/mnt/data/scjs/1819/tab/scjs1819_nvf-main_y3_eul-safeguarded_20210316_nvf.tab",
	"/mnt/data/scjs/1920/tab/scjs1920_nvf-main_y4_eul-safeguarded_20210322_nvf.tab"
	]

function loadtab( filename, datayear )
	scjsraw = CSV.File( filename )|>DataFrame
	lcnames = Symbol.(lowercase.(string.(names(scjsraw))))
	rename!( scjsraw, lcnames ) # jam lowercase names
	n = size( scjsraw )[1]
	scjsraw.datayear = fill( datayear, n )
	scjsraw
end

#
# Stack 2009/10-19/20 scjss
# 
scjsv = []
datayear = 2017
for fn in SCJS_FILES	
	global datayear
	push!(scjsv, loadtab( fn, datayear ))
	datayear += 1
end
scjsraw = vcat( scjsv...; cols=:intersect )

include( "scjs-mappings.jl")

# only those asked module 3: CIVIL; 
# see Userguide 4.6.4 Module C: Civil Law
scjsciv = scjsraw[scjsraw.qmodule.==3,:] 

# size checks should be 1,363 in 19/20 see table 3.1 tech report
by_year = groupby( scjsciv, :datayear )
for yrd in by_year 
	sz = size( yrd )[1]
	println( "count of hhlds for data year $(yrd.datayear[1]) = $sz")
end


reg_home = glm( @formula( civ_home ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
   log(hhinc) + qdeth3 +  is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsciv, Binomial(), ProbitLink())

reg_money = glm( @formula( civ_money ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
   log(hhinc) + qdeth3 +  is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsciv, Binomial(), ProbitLink())

reg_unfairness = glm( @formula( civ_unfairness ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
   log(hhinc) + qdeth3 +  is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsciv, Binomial(), ProbitLink())

reg_neighbours = glm( @formula( civ_neighbours ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
   log(hhinc) + qdeth3 +  is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsciv, Binomial(), ProbitLink())

reg_divorce = glm( @formula( civ_divorce ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
   log(hhinc) + qdeth3 +  is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsciv, Binomial(), ProbitLink())

reg_employment = glm( @formula( civ_employment ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
	log(hhinc) + qdeth3 +  is_carer + has_condition + qhstat + iloclass + 
	iloclass + qdlegs + age + agesq + qdgen ) , scjsciv, Binomial(), ProbitLink())

regtable( reg_home, reg_money, reg_unfairness, reg_neighbours, reg_divorce, reg_employment;
	below_statistic = TStat, digits = 4, file="initial-regs.txt")


r2_home = glm( @formula( civ_home ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + 
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsciv, Binomial(), ProbitLink())
r2_money = glm( @formula( civ_money ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + 
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsciv, Binomial(), ProbitLink())
r2_unfairness = glm( @formula( civ_unfairness  ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + 
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsciv, Binomial(), ProbitLink())
r2_neighbours = glm( @formula( civ_neighbours ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + 
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsciv, Binomial(), ProbitLink())
r2_divorce = glm( @formula( civ_divorce ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + 
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsciv, Binomial(), ProbitLink())
r2_employment = glm( @formula( civ_employment ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + 
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsciv, Binomial(), ProbitLink())
regtable( r2_home, r2_money, r2_unfairness, r2_neighbours, r2_divorce, r2_employment;
	below_statistic = TStat, digits = 4, file="edited-regs.txt")


#
# only sig
#
f3_home = @formula( civ_home ~ has_condition + 
	health_good_or_better + lives_in_flat + single_parent  + age + agesq ) 
r3_home = glm( f3_home, scjsciv, Binomial(), ProbitLink())

f3_money = @formula( civ_money ~ has_condition + 
	health_good_or_better + lives_in_flat + single_parent  + age + agesq )
r3_money = glm( f3_money, scjsciv, Binomial(), ProbitLink())

f3_unfairness = @formula( civ_unfairness  ~ has_condition + 
	non_white + age + agesq ) 
r3_unfairness = glm( f3_unfairness, scjsciv, Binomial(), ProbitLink())

f3_neighbours = @formula( civ_neighbours ~ has_condition + 
	health_good_or_better + lives_in_flat + age + agesq ) 
r3_neighbours = glm( f3_neighbours, scjsciv, Binomial(), ProbitLink())

f3_divorce = @formula( civ_divorce ~ divorced_or_separated + single_parent  + age + agesq ) 
r3_divorce = glm( f3_divorce, scjsciv, Binomial(), ProbitLink())

f3_employment = @formula( civ_employment ~ out_of_labour_market +  + age + agesq ) 
r3_employment = glm( f3_employment, scjsciv, Binomial(), ProbitLink())

regtable( r3_home, r3_money, r3_unfairness, r3_neighbours, r3_divorce, r3_employment;
	below_statistic = TStat, digits = 4, file="edited-regs2.txt")


"""
"""
function make_predicts( model, raw_data )
	form = formula( model )
	# see: https://juliastats.org/StatsModels.jl/stable/api/#StatsModels.TableRegressionModel
	# I don't know why it's done like this 
	mat = ModelMatrix( ModelFrame( form, raw_data )).m
	preds = predict( model, mat, interval=:confidence )
end

function add_predicts!( df :: DataFrame, prefix::String, model, raw_data )
	preds = make_predicts( model, raw_data )
	df[:,Symbol( "$(prefix)_lower")] = preds.lower
	df[:,Symbol( "$(prefix)_prediction")] = preds.prediction
	df[:,Symbol( "$(prefix)_upper")] = preds.upper
end

scoth = CSV.File( "data/model_households_scotland-2015-2021.tab") |> DataFrame
scotp = CSV.File( "data/model_people_scotland-2015-2021.tab") |> DataFrame
fm = create_regression_dataframe( scoth, scotp )

n = size( fm )[1]
fm.civ_home = zeros( n )
fm.civ_money = zeros( n )
fm.civ_divorce = zeros( n )
fm.civ_neighbours = zeros( n )
fm.civ_unfairness = zeros( n )
fm.civ_employment = zeros( n )

civil_probs = DataFrame( 
	data_year = fm.data_year, 
	hid=fm.hid, 
	pid = fm.pid, 
	pno = fm.pno, 
	weight = fm.weight/7, # hack for checking
	from_child_record=fm.from_child_record )


add_predicts!( civil_probs, "divorce", r3_divorce, fm )
add_predicts!( civil_probs, "home", r3_home, fm )
add_predicts!( civil_probs, "money", r3_money, fm )
add_predicts!( civil_probs, "unfairness", r3_unfairness, fm )
add_predicts!( civil_probs, "neighbours", r3_neighbours, fm )
add_predicts!( civil_probs, "employment", r3_employment, fm )

cpnc = civil_probs[civil_probs.from_child_record.==0,:]

function summarise( prefix::String, model, cpnc :: DataFrame, scjsciv :: DataFrame )
	println( "## $(titlecase(prefix)) \n\n```\n" )
	lower = cpnc[:,Symbol( "$(prefix)_lower")].*100
	central = cpnc[:,Symbol( "$(prefix)_prediction")].*100
	upper = cpnc[:,Symbol( "$(prefix)_upper")].*100
	println( "### Imputed Probabilities on FRS Data (%s)\n")
	println( "#### Lower Bound 95%")
	println(summarystats( lower ))
	println( "#### Central")
	println(summarystats( central ))
	println( "#### Upper Bound 95%")
	println(summarystats( upper ))
	mean_occurs = fp(mean( scjsciv[:,Symbol("civ_$(prefix)")]  ))
	mean_predicted = fp(mean( predict( model )))

	popn_totals_lower = fc(sum( lower .* cpnc.weight ./ 100)) 
	popn_totals_central = fc(sum( central .* cpnc.weight./ 100 )) 
	popn_totals_upper = fc(sum( upper .* cpnc.weight ./ 100)) 

	println( "actual data: prop occurrences i data $mean_occurs mean prediction = $mean_predicted " )
	println( "modelled total problems : lower $popn_totals_lower  central = $popn_totals_central upper $popn_totals_upper (per 3 years)")
	println( "\n\n```")
end

summarise( "divorce", r3_divorce, cpnc, scjsciv)
summarise( "home", r3_home, cpnc, scjsciv)
summarise( "money", r3_money, cpnc, scjsciv)
summarise( "unfairness", r3_unfairness, cpnc, scjsciv)
summarise( "neighbours", r3_neighbours, cpnc, scjsciv)
summarise( "employment" , r3_employment, cpnc, scjsciv)

CSV.write( "data/civil-legal-aid-probs-scotland-2015-2012.tab",civil_probs; delim='\t' )