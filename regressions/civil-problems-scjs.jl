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
using Format
using Statistics
using StatsModels
using Colors
using Dates

using ScottishTaxBenefitModel
using .TimeSeriesUtils: parse_ons_date
using .HouseholdFromFrame
using .RunSettings

using .Utils

include( "../scripts/comparisons_skeleton.jl")

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

# const DDIR = "/media/graham_s/Transcend/data/" # local version
const DDIR = "/mnt/data/"

const SCJS_FILES = [
	"$(DDIR)/scjs/1718/tab/scjs1718__nvf-main_y2_eul_20190508.tab",
	"$(DDIR)/scjs/1819/tab/scjs1819_nvf-main_y3_eul-safeguarded_20210316_nvf.tab",
	"$(DDIR)/scjs/1920/tab/scjs1920_nvf-main_y4_eul-safeguarded_20210322_nvf.tab",
	"$(DDIR)/scjs/2122/tab/p16472_scjs_y6_nvf_ukds_240314.tab"
	]

function loadtab( filename, datayear )
	scjsraw = CSV.File( filename )|>DataFrame
	lcnames = Symbol.(lowercase.(string.(names(scjsraw))))
	rename!( scjsraw, lcnames ) # jam lowercase names
	n = size( scjsraw )[1]
	scjsraw.datayear = fill( datayear, n )
	# mapping hacks
	if datayear == 2021
		scjsraw.qdgen = scjsraw.qdsex_01 # gender of respondennt
		scjsraw.qdeth3 = scjsraw.qdeth4 # race pointlessly renamed - same mapping
	end
	scjsraw
end

#
# Stack 2017-2021 scjss, skipping 2020
# 
function load_all_scjs()
	scjsv = []
	datayears = [2017,2018,2019,2021] # skip COVID!
	nd = 1
	for fn in SCJS_FILES	
		push!(scjsv, loadtab( fn, datayears[nd] ))
		nd += 1
	end
	return vcat( scjsv...; cols=:intersect )
end

# only those asked module 3: CIVIL; 
# see Userguide 4.6.4 Module C: Civil Law
scjsraw = load_all_scjs()

include( "scjs-mappings.jl")

scjsciv = scjsraw[scjsraw.qmodule.==3,:] 
CSV.write( "$(DDIR)/NINE/datasets/scjs-2017-22.tab", scjsraw; delim='\t')
CSV.write( "$(DDIR)/NINE/datasets/scjs-civil-only-2017-22.tab", scjsciv; delim='\t')

# size checks should be 1,363 in 19/20 see table 3.1 tech report
by_year = groupby( scjsciv, :datayear )
for yrd in by_year 
	sz = size( yrd )[1]
	println( "count of hhlds for data year $(yrd.datayear[1]) = $sz")
end


reg_home = glm( @formula( civ_home ~ datayear + taburbrur + simd_quint + hhcomp + acctype + tenure + qdgen +
   log(hhinc) + qdeth3 +  is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ), scjsciv, Binomial(), ProbitLink())

reg_money = glm( @formula( civ_money ~ datayear + taburbrur + simd_quint+hhcomp + acctype + tenure + qdgen +
   log(hhinc) + qdeth3 +  is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ), scjsciv, Binomial(), ProbitLink())

reg_unfairness = glm( @formula( civ_unfairness ~ datayear + taburbrur + simd_quint+hhcomp + acctype + tenure + qdgen +
   log(hhinc) + qdeth3 +  is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsciv, Binomial(), ProbitLink())

reg_neighbours = glm( @formula( civ_neighbours ~ datayear + taburbrur + simd_quint+hhcomp + acctype + tenure + qdgen +
   log(hhinc) + qdeth3 +  is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsciv, Binomial(), ProbitLink())

reg_divorce = glm( @formula( civ_divorce ~ datayear + taburbrur + simd_quint+hhcomp + acctype + tenure + qdgen +
   log(hhinc) + qdeth3 +  is_carer + has_condition + qhstat + iloclass + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsciv, Binomial(), ProbitLink())

reg_employment = glm( @formula( civ_employment ~ datayear + taburbrur + simd_quint+hhcomp + acctype + tenure + qdgen +
	log(hhinc) + qdeth3 +  is_carer + has_condition + qhstat + iloclass + 
	iloclass + qdlegs + age + agesq + qdgen ) , scjsciv, Binomial(), ProbitLink())

reg_health = glm( @formula( civ_health ~ datayear + taburbrur + simd_quint+hhcomp + acctype + tenure + qdgen +
	log(hhinc) + qdeth3 +  is_carer + has_condition + qhstat + iloclass + 
	iloclass + qdlegs + age + agesq + qdgen ) , scjsciv, Binomial(), ProbitLink())
	

regtable( reg_home, reg_money, reg_unfairness, reg_neighbours, reg_divorce, reg_employment, reg_health;
	below_statistic = TStat, digits = 4, file="tmp/initial-regs.txt")


r2_home = glm( @formula( civ_home ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + qdgen +
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsciv, Binomial(), ProbitLink())
r2_money = glm( @formula( civ_money ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + qdgen +
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsciv, Binomial(), ProbitLink())
r2_unfairness = glm( @formula( civ_unfairness  ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + qdgen +
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsciv, Binomial(), ProbitLink())
r2_neighbours = glm( @formula( civ_neighbours ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + qdgen +
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsciv, Binomial(), ProbitLink())
r2_divorce = glm( @formula( civ_divorce ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + qdgen +
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsciv, Binomial(), ProbitLink())
r2_employment = glm( @formula( civ_employment ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + qdgen +
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsciv, Binomial(), ProbitLink())
r2_health = glm( @formula( civ_health ~ out_of_labour_market + is_carer + has_condition + divorced_or_separated + qdgen +
	health_good_or_better + non_white+ lives_in_flat + single_parent  + age + agesq ) , scjsciv, Binomial(), ProbitLink())
regtable( r2_home, r2_money, r2_unfairness, r2_neighbours, r2_divorce, r2_employment, r2_health;
	below_statistic = TStat, digits = 4, file="tmp/edited-regs.txt")


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

f3_health = @formula( civ_health ~ has_condition + 
	health_good_or_better + lives_in_flat + age + agesq )
r3_health = glm( f3_health, scjsciv, Binomial(), ProbitLink())

regtable( r3_home, r3_money, r3_unfairness, r3_neighbours, r3_divorce, r3_employment, r3_health;
	below_statistic = TStat, digits = 4, file="tmp/edited-regs2.txt")


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

# scoth = CSV.File( "data/model_households_scotland-2015-2021.tab") |> DataFrame
# scotp = CSV.File( "data/model_people_scotland-2015-2021.tab") |> DataFrame

settings = Settings()
settings.included_data_years = [] # all years, even if we don't want them in the sim
scoth, scotp = get_raw_data( settings; reset=true )

fm = create_regression_dataframe( scoth, scotp )

n = size( fm )[1]
fm.civ_home = zeros( n )
fm.civ_money = zeros( n )
fm.civ_divorce = zeros( n )
fm.civ_neighbours = zeros( n )
fm.civ_unfairness = zeros( n )
fm.civ_employment = zeros( n )
fm.civ_health = zeros( n )

civil_probs = DataFrame( 
	data_year = fm.data_year, 
	hid=fm.hid, 
	pid = fm.pid, 
	pno = fm.pno, 
	weight = fm.weight, # hack for checking
	from_child_record=fm.from_child_record )


add_predicts!( civil_probs, "divorce", r3_divorce, fm )
add_predicts!( civil_probs, "home", r3_home, fm )
add_predicts!( civil_probs, "money", r3_money, fm )
add_predicts!( civil_probs, "unfairness", r3_unfairness, fm )
add_predicts!( civil_probs, "neighbours", r3_neighbours, fm )
add_predicts!( civil_probs, "employment", r3_employment, fm )
add_predicts!( civil_probs, "health", r3_health, fm )

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
summarise( "health" , r3_employment, cpnc, scjsciv)

CSV.write( "$(DDIR)scjs/civil-legal-aid-probs-scotland-2017-2021.tab",civil_probs; delim='\t' )