using CSV,DataFrames
#
# load all 3 shs social datasets
#
const DIR="/mnt/transcend/data/"

function coarse_match( 
	recip :: DataFrameRow, 
	donor :: DataFrame, 
	vars  :: Vector{Symbol},
	max_matches :: Int,
	max_coarsens :: Int ) :: NamedTuple
	nobs = size( donor )[1]
	nvars = size( vars )[1]
	c_level = ones(Int,nvars)
	qualities = zeros(Int,nobs)
	quality = 0
	prevmatches = fill( false, nobs )
	
	matches = fill( true, nobs )
	for nc in 2:max_coarsens
		for nv in 1:nvars
			matches = fill( true, nobs )
			for n in 1:nvars
				# so, if sym[1] = :a and c_level[1] = 1 then :a_1 and so on
				sym = Symbol("$(String(vars[n]))_$(c_level[n])") # everything
				println( "n = $n using sym $(sym)" )
				matches .&= (donor[sym] .== r1[sym])			
			end
			c_level[nv] = nc
			println( "c_level now $(c_level) matches $(matches)" )
			nmatches = sum( matches )
			println( "nmatches $nmatches max_matches $max_matches quality $quality" )
			quality += 1
			newmatches = prevmatches .⊻ matches
			println( "newmatches $(newmatches) prevmatches=$prevmatches" )
			qualities[newmatches] .= quality
			prevmatches = matches
			println( "end of loop" )
			if nmatches >= max_matches
				return (matches=matches,qualities=qualities)
			end
		end # vars
	end # coarse
	return (matches=matches,qualities=qualities)
end

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

shh16 = hh16[(hh16.gvtregn .== 299999999),:]
shh17 = hh17[(hh17.gvtregn .== 299999999),:]
shh18 = hh18[(hh18.gvtregn .== 299999999),:]


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
                      


# CSV.write( "$(DIR)/shs/merged_soc/shs_16_17_18_merged_common_vars.tab", hhad ) 
# s1618all = vcat(s16,s17,s18;cols=:union)
# CSV.write( "$(DIR)/shs/merged_soc/s16_17_18_merged_all_vars.tab", s1618all )

donor = DataFrame( sernum=[1,2,3,4], a_1=[1,2,3,4], a_2=[8,2,3,1], b_1=[1,2,3,4], b_2=[6,7,7,8] )

n = 10000
donor = DataFrame( sernum=collect(1:n), a_1=rand(1:50,n), b_1=rand(100:1500,n))
# coarsend
donor.a_2 = donor.a_1 .<= 25
donor.b_2 = donor.b_1 .<= 600

m = 5000
recip = DataFrame( sernum=collect(1:m), a_1=rand(2:500,m), b_1=rand(11:17,m))
# coarsend
recip.a_2 = recip.a_1 .<= 230
recip.b_2 = recip.b_1 .<= 700

r1 = recip[1,:]

matches = coarse_match( 
	r1,
	donor,
	[:a, :b],
	10,
	25 )
end


matches = donor.a_1 .== r1.a_1
matches .&= (donor[:b_1] .== r1[:b_1])