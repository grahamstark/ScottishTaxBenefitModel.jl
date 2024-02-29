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
using Statistics
using StatsModels
using Colors
using Dates

using ScottishTaxBenefitModel
using .TimeSeriesUtils: parse_ons_date
using .HouseholdFromFrame

using .Utils

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
	"/mnt/data/scjs/1920/tab/scjs1920_nvf-main_y4_eul-safeguarded_20210322_nvf.tab",
	"/mnt/data/scjs/1819/tab/scjs1819_nvf-main_y3_eul-safeguarded_20210316_nvf.tab",
	"/mnt/data/scjs/1718/tab/scjs1718__nvf-main_y2_eul_20190508.tab" ]

function loadtab( filename )
	scjsraw = CSV.File( filename )|>DataFrame
	lcnames = Symbol.(lowercase.(string.(names(scjsraw))))
	rename!( scjsraw, lcnames ) # jam lowercase names
end

#
# Stack 2009/10-19/20 scjss
#
scjsv = []
for fn in SCJS_FILES	
	push!(scjsv, loadtab( fn ))
end
scjsraw = vcat( scjsv...; cols=:intersect )

include( "scjs-mappings.jl")

reg_home = glm( @formula( civ_home ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
   log(hhinc) + qdeth3 +  is_limited + is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsraw, Binomial(), ProbitLink())

reg_money = glm( @formula( civ_money ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
   log(hhinc) + qdeth3 +  is_limited + is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsraw, Binomial(), ProbitLink())

reg_unfairness = glm( @formula( civ_unfairness ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
   log(hhinc) + qdeth3 +  is_limited + is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsraw, Binomial(), ProbitLink())

reg_neighbours = glm( @formula( civ_neighbours ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
   log(hhinc) + qdeth3 +  is_limited + is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsraw, Binomial(), ProbitLink())

reg_divorce = glm( @formula( civ_divorce ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
   log(hhinc) + qdeth3 +  is_limited + is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsraw, Binomial(), ProbitLink())

reg_employment = glm( @formula( civ_employment ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
	log(hhinc) + qdeth3 +  is_limited + is_carer + has_condition + qhstat + iloclass + 
	iloclass + qdlegs + age + agesq + qdgen ) , scjsraw, Binomial(), ProbitLink())

regtable( reg_home, reg_money, reg_unfairness, reg_neighbours, reg_divorce, reg_employment;
	below_statistic = TStat, digits = 4, file="initial-regs.txt")


r2_home = glm( @formula( civ_home ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + 
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsraw, Binomial(), ProbitLink())
r2_money = glm( @formula( civ_money ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + 
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsraw, Binomial(), ProbitLink())
r2_unfairness = glm( @formula( civ_unfairness  ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + 
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsraw, Binomial(), ProbitLink())
r2_neighbours = glm( @formula( civ_neighbours ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + 
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsraw, Binomial(), ProbitLink())
r2_divorce = glm( @formula( civ_divorce ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + 
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsraw, Binomial(), ProbitLink())
r2_employment = glm( @formula( civ_employment ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + 
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsraw, Binomial(), ProbitLink())
regtable( r2_home, r2_money, r2_unfairness, r2_neighbours, r2_divorce, r2_employment;
	below_statistic = TStat, digits = 4, file="edited-regs.txt")


#
# only sig
#
f3_home = @formula( civ_home ~ has_condition + divorced_or_separated + 
	health_good_or_better + lives_in_flat + single_parent  + age + agesq ) 
r3_home = glm( f3_home, scjsraw, Binomial(), ProbitLink())

f3_money = @formula( civ_money ~ has_condition + 
	health_good_or_better + lives_in_flat + single_parent  + age + agesq )
r3_money = glm( f3_money, scjsraw, Binomial(), ProbitLink())

f3_unfairness = @formula( civ_unfairness  ~ has_condition + 
	non_white + lives_in_flat +  age + agesq ) 
r3_unfairness = glm( f3_unfairness, scjsraw, Binomial(), ProbitLink())

f3_neighbours = @formula( civ_neighbours ~ has_condition + divorced_or_separated + 
	health_good_or_better + lives_in_flat + age + agesq ) 
r3_neighbours = glm( f3_neighbours, scjsraw, Binomial(), ProbitLink())

f3_divorce = @formula( civ_divorce ~ divorced_or_separated + single_parent  + age + agesq ) 
r3_divorce = glm( f3_divorce, scjsraw, Binomial(), ProbitLink())

f3_employment = @formula( civ_employment ~ out_of_labour_market +  + age + agesq ) 
r3_employment = glm( f3_employment, scjsraw, Binomial(), ProbitLink())

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
	from_child_record=fm.from_child_record )


add_predicts!( civil_probs, "divorce", r3_divorce, fm )
add_predicts!( civil_probs, "home", r3_home, fm )
add_predicts!( civil_probs, "money", r3_money, fm )
add_predicts!( civil_probs, "unfairness", r3_unfairness, fm )
add_predicts!( civil_probs, "neighbours", r3_neighbours, fm )
add_predicts!( civil_probs, "employment", r3_employment, fm )

cpnc = civil_probs[civil_probs.from_child_record.==0,:]

mean(cpnc.divorce_prediction)
mean( scjsraw.civ_divorce  )
mean( predict( r3_divorce ))

mean(cpnc.home_prediction)
mean( scjsraw.civ_home )
mean( predict( r3_home ))

mean(cpnc.money_prediction)
mean( scjsraw.civ_money  )
mean( predict( r3_money ))

mean(cpnc.unfairness_prediction)
mean( scjsraw.civ_unfairness  )
mean( predict( r3_unfairness ))

mean(cpnc.neighbours_prediction)
mean( scjsraw.civ_neighbours  )
mean( predict( r3_neighbours ))

mean(cpnc.employment_prediction)
mean( scjsraw.civ_employment  )
mean( predict( r3_employment ))

CSV.write( "data/civil-legal-aid-probs-scotland-2015-2012.tab",civil_probs; delim='\t' )