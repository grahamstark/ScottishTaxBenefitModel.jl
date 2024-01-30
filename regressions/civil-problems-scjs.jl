### 
#
# Fuel regressions 
#

using Markdown
using CSV
using GLM
using Makie
using CairoMakie
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
   log(hhinc) + qdeth3 +  is_limited + is_carer + has_condition + qhstat + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsraw, Binomial(), ProbitLink())

reg_money = glm( @formula( civ_money ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
   log(hhinc) + qdeth3 +  is_limited + is_carer + has_condition + qhstat + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsraw, Binomial(), ProbitLink())

reg_unfairness = glm( @formula( civ_unfairness ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
   log(hhinc) + qdeth3 +  is_limited + is_carer + has_condition + qhstat + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsraw, Binomial(), ProbitLink())

reg_neighbours = glm( @formula( civ_neighbours ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
   log(hhinc) + qdeth3 +  is_limited + is_carer + has_condition + qhstat + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsraw, Binomial(), ProbitLink())

reg_divorce = glm( @formula( civ_divorce ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
   log(hhinc) + qdeth3 +  is_limited + is_carer + has_condition + qhstat + 
   iloclass + qdlegs + age + agesq + qdgen ) , scjsraw, Binomial(), ProbitLink())

reg_employment = glm( @formula( civ_employment ~ taburbrur + simd_quint+hhcomp + acctype + tenure + 
	log(hhinc) + qdeth3 +  is_limited + is_carer + has_condition + qhstat + 
	iloclass + qdlegs + age + agesq + qdgen ) , scjsraw, Binomial(), ProbitLink())

regtable( reg_home, reg_money, reg_unfairness, reg_neighbours, reg_divorce, reg_employment;
	below_statistic = TStat, digits = 4, file="initial-regs.txt")