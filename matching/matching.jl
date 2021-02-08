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
const DIR="/mnt/transcend/data/"
const SCOTLAND=299999999

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

#
# Load all 3 shs social datasets
#
s16=loadshs(2016)
s17=loadshs(2017)
s18=loadshs(2018)

#
# Load 3 FRS hhld datasets, and then make Scotland only subsets.
#
hh16 = loadfrs( 2016, "househol" )
hh17 = loadfrs( 2017, "househol" )
hh18 = loadfrs( 2018, "househol" )

shh16 = hh16[(hh16.gvtregn .== SCOTLAND),:]
shh17 = hh17[(hh17.gvtregn .== SCOTLAND),:]
shh18 = hh18[(hh18.gvtregn .== SCOTLAND),:]

#
# FRS Adult datasets.
#
ad16 = loadfrs( 2016, "adult" )
ad17 = loadfrs( 2017, "adult" )
ad18 = loadfrs( 2018, "adult" )

#
# joined household and adult FRS records, Scotland only
#
shhad16=innerjoin( ad16,shh16, on=:sernum; makeunique=true )
shhad17=innerjoin( ad17,shh17, on=:sernum; makeunique=true )
shhad18=innerjoin( ad18,shh18, on=:sernum; makeunique=true )

#
# now, delete all but the adult with the highest income, since this is  
# 
shhad16.highest_income = make_highest_hh_income_marker( shhad16 )
shhad17.highest_income = make_highest_hh_income_marker( shhad17 )
shhad18.highest_income = make_highest_hh_income_marker( shhad18 )

# some dumps, just for curiousity
shhad18[:,[:sernum,:person,:indinc,:highest_income]] 
# check for mbu members 2nd+ bus
shhad18[((shhad18.highest_income.==1) .& (shhad18.person.>2)),[:sernum,:person,:indinc,:highest_income]]

#
# Stack all 3 years FRS.
# 
frs_all_years_scot_he = vcat(
	shhad16[shhad16.highest_income,:],
	shhad17[shhad17.highest_income,:],
	shhad18[shhad18.highest_income,:];
	cols=:intersect)
                      
# ... 
# Stack shs.
# 
shs_all_years = vcat(
    s16,
    s17,
    s18,
    cols=:intersect
)

#
# Create donor  (SHS) and recipient (FRS) datasets.
#
donor_ds = DataFrame() # shs
recipient = DataFrame() # frs

# SHS Tenure
# Pos. = 56	Variable = tenure	Variable label = Tenure - SHS but non-harmonised version
# This variable is    numeric, the SPSS measurement level is NOMINAL
# 	Value label information for tenure
# 	Value = 1.0	Label = Owned outright
# 	Value = 2.0	Label = Buying with help of loan/mortgage
# 	Value = 3.0	Label = Rent – LA
# 	Value = 4.0	Label = Rent - HA, Co-op
# 	Value = 5.0	Label = Rent - private landlord
# 	Value = 6.0	Label = Other
# 	Value = 999998.0	Label = Don't know
# 	Value = 999999.0	Label = Refused
# 
# # FRS TENURE
# 
# os. = 258	Variable = TENTYP2	Variable label = Tenure type
# This variable is    numeric, the SPSS measurement level is NOMINAL
# SPSS user missing values = -9.0 thru -1.0
# 	Value label information for TENTYP2
# 	Value = 1.0	Label = LA / New Town / NIHE / Council rented 
# 	Value = 2.0	Label = Housing Association / Co-Op / Trust rented 
# 	Value = 3.0	Label = Other private rented unfurnished 
# 	Value = 4.0	Label = Other private rented furnished 
# 	Value = 5.0	Label = Owned with a mortgage (includes part rent / part own) 
# 	Value = 6.0	Label = Owned outright 
# 	Value = 7.0	Label = Rent-free 
# 	Value = 8.0	Label = Squats

# harmonised tenure
# 
# 1 -> OO
# 2 -> Mortgaged
# 3 -> LA/Council Rented
# 4 -> HA Rented
# 5 -> Private Rented
# 6 -> Other

# coarsened tenure
# 1 -> Owned
# 2 -> Rented
# 3 -> Other

# _3
# 1 -> Any


function shs_tenuremap( tenure :: Int ) :: Vector{Int}
    out = fill( -99, 3 )
    out[3] = 1
    if tenure == 1 # OO
        out[1] = 1
        out[2] = 1
    elseif tenure == 2
        out[1] = 2
        out[2] = 1
    elseif tenure in 3:4
        out[1] = 5
        out[2] = 2
    elseif 
        
    end        
end

function frs_tenuremap( tentype2 :: Int ) :: Vector{Int}

end
