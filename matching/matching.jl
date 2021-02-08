using CSV,DataFrames
using ScottishTaxBenefitModel
using .Utils: coarse_match
#
# Scripts for creating a merged FRS (recipient) and SHS (donor) datase
# see the following:
# 
# * match routine `` in [.Utils](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/Utils.jl)
# * [blog post](https://stb-blog.virtual-worlds.scot/articles/2021/02/07/matching-notes.html) (includes some references);
# * test cases [matching_tests.jl]()https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/test/matching_tests.jl
# 
#
# load all 3 shs social datasets
#
const DIR="/mnt/transcend/data/"
const SCOTLAND=299999999

function loadshs( year::Int )::DataFrame
	year -= 2000
	ystr = "$(year)$(year+1)"
	fname = "$(DIR)/shs/$(ystr)/tab/shs20$(year)_social_public.tab"
	println( "loading '$fname'" )
	shs = CSV.File( fname; missingstrings=["NA"] ) |> DataFrame
	lcnames = Symbol.(lowercase.(string.(names(shs))))
    names!(shs,lcnames)
    shs.datayear = year
    return shs
end


function loadfrs( year::Int, fname :: String ) :: DataFrame
	ystr = "$(year)$(year+1)"
	fname = "$(DIR)/frs/$(year)/tab/$(fname).tab"
	println( "loading '$fname'" )
	frs = CSV.File( fname; missingstrings=["-1"] ) |> DataFrame
	lcnames = Symbol.(lowercase.(string.(names(frs))))
    names!(frs,lcnames)
    frs.datayear = year
    return frs
end


s16=loadshs(2016)
s17=loadshs(2017)
s18=loadshs(2018)

hh16 = loadfrs( 2016, "househol" )
hh17 = loadfrs( 2017, "househol" )
hh18 = loadfrs( 2018, "househol" )

shh16 = hh16[(hh16.gvtregn .== SCOTLAND),:]
shh17 = hh17[(hh17.gvtregn .== SCOTLAND),:]
shh18 = hh18[(hh18.gvtregn .== SCOTLAND),:]


ad16 = loadfrs( 2016, "adult" )
ad17 = loadfrs( 2017, "adult" )
ad18 = loadfrs( 2018, "adult" )

shhad16=innerjoin( ad16,shh16, on=:sernum; makeunique=true )
shhad17=innerjoin( ad17,shh17, on=:sernum; makeunique=true )
shhad18=innerjoin( ad18,shh18, on=:sernum; makeunique=true )


function make_highest_hh_income_marker( hhad :: DataFrame ) :: Vector{Bool}
	sns = unique(hhad.sernum)
	n = size( hhad )[1]
	highest_income = fill( false, n )
	pers_count = 0
	for sn in sns
		ads = hhad[ (hhad.sernum .== sn),:]
		max_inc_in_hh = -9999999999999999.99
		richest_in_hh = -1   # pos in this hh of richest member
		richest_array_count = -1 # pos in the overall array of richest hh member
		adno = 0
		for ad in eachrow(ads)
			adno += 1
			pers_count += 1
			inc = ad.indinc === missing ? 0.0 : Float64( ad.indinc )
			if inc > max_inc_in_hh
				max_inc_in_hh = inc
				richest_array_count = pers_count
				richest_in_hh = adno
			end
		end
		if richest_in_hh > 2
			println( "sernum=$sn max_inc_in_hh=$max_inc_in_hh richest_in_hh=$richest_in_hh " )
		end
		@assert richest_in_hh > 0
		highest_income[richest_array_count] = true
	end
	return highest_income
end

shhad16.highest_income = make_highest_hh_income_marker( shhad16 )
shhad17.highest_income = make_highest_hh_income_marker( shhad17 )
shhad18.highest_income = make_highest_hh_income_marker( shhad18 )

shhad18[:,[:sernum,:person,:indinc,:highest_income]] 
# mbu members 2nd+ bus
shhad18[((shhad18.highest_income.==1) .& (shhad18.person.>2)),[:sernum,:person,:indinc,:highest_income]]


shh_ad_highest_comm = vcat(
	shhad16[shhad16.highest_income,:],
	shhad17[shhad17.highest_income,:],
	shhad18[shhad18.highest_income,:];
	cols=:intersect)
                      
