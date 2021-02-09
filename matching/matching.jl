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
const DIR="/mnt/data/"
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
	shs = CSV.File( fname; missingstrings=["NA",""] ) |> DataFrame
	lcnames = Symbol.(lowercase.(string.(names(shs))))
    rename!(shs,lcnames)
    shs[!,:datayear] .= year
    return shs
end


function loadfrs( year::Int, fname :: String ) :: DataFrame
	ystr = "$(year)$(year+1)"
	fname = "$(DIR)/frs/$(year)/tab/$(fname).tab"
	println( "loading '$fname'" )
	frs = CSV.File( fname; missingstrings=["-1"] ) |> DataFrame
	lcnames = Symbol.(lowercase.(string.(names(frs))))
    rename!(frs,lcnames)
    frs[!,:datayear] .= year
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
shhad16[!,:highest_income] = make_highest_hh_income_marker( shhad16 )
shhad17[!,:highest_income] = make_highest_hh_income_marker( shhad17 )
shhad18[!,:highest_income] = make_highest_hh_income_marker( shhad18 )

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


function shs_tenuremap( tenure :: Union{Int,Missing} ) :: Vector{Int}
    out = fill( -99, 3 )
    out[3] = 1
    if ismissing( tenure )
        out[1] = 6
        out[2] = 3
    elseif tenure == 1 # OO
        out[1] = 1
        out[2] = 1
    elseif tenure == 2
        out[1] = 2
        out[2] = 1
    elseif tenure == 3
        out[1] = 3
        out[2] = 2
    elseif tenure == 4
        out[1] = 4
        out[2] = 2
    elseif tenure == 5
        out[1] = 5
        out[2] = 2
    elseif tenure in [6, 999998, 999998]
        out[1] = 6
        out[2] = 3
    else
        @assert false "unmatched tenure $tenure";
    end      
    return out
end

function total_people( n :: Union{Int,Missing}, def :: Int ) :: Vector{Int}
    out = fill( def, 3 )
    if ismissing( n )
        return out
    end
    out[1] = n
    if n == 0
        out[2] = 0
    elseif n == 1
        out[2] = 1
    elseif n == 2
        out[2] = 2
    elseif n in 3:5
        out[2] = 3
    else
        out[2] = 4
    end
    out[3] = def
    out;
end
    
function frs_tenuremap( tentyp2 :: Union{Int,Missing} ) :: Vector{Int}
    out = fill( -99, 3 )
    out[3] = 1
    if ismissing( tentyp2 )
        out[1] = 6
        out[2] = 3
    elseif tentyp2 == 1
        out[1] = 3
        out[2] = 2
    elseif tentyp2 == 2
        out[1] = 4
        out[2] = 2
    elseif tentyp2 in [3,4]
        out[1] = 5
        out[2] = 2
    elseif tentyp2 == 5
        out[1] = 2
        out[2] = 1
    elseif tentyp2 == 6 
        out[1] = 1
        out[2] = 1
    elseif tentyp2 in 7:8
        out[1] = 6
        out[2] = 3        
    else
        @assert false "unmatched tentyp2 $tentyp2";
    end 
    return out
end

function to_i( i :: Union{Int,Missing} ) :: Int
    if ismissing(i)
        return -1
    end
    return i
end

function is_sp(i::Integer)
    i in 9:11
end

function setone( i :: Union{Int,Missing}, decider::Function ) :: Vector{Int}
    i = to_i( i )
    o = decider(i)
    return fill( o, 3 )
end

function setone( i :: Union{Int,Missing}, target :: Int = 1 ) :: Vector{Int}
    i = to_i( i )
    o = (i == target )
    return fill( o, 3 )
end

frs_tenuremap.(frs_all_years_scot_he.tentyp2)
shs_tenuremap.(shs_all_years.tenure)

shs_all_years.accsup1 .== 1 # sheltered accom SHS
frs_all_years_scot_he.shelter .== 1 # sheltered FRS

#Pos. = 58	Variable = hb1	Variable label = hb1 - Is the household's accommodation...
# SHS Accomodation
#
# This variable is  numeric, the SPSS measurement level is NOMINAL
# SPSS user missing values = -1.0 thru None
# 	Value label information for hb1
# 	Value = 1.0	Label = House or bungalow
# 	Value = 2.0	Label = A flat, maisonette or apartment (including ) 
# 	Value = 3.0	Label = Other, including room(s), caravan/mobile homes
# 
# Pos. = 59	Variable = hb2	Variable label = hb2 - Is it...
# This variable is  numeric, the SPSS measurement level is SCALE
# SPSS user missing values = -1.0 thru None
# 	Value label information for hb2
# 	Value = 1.0	Label = Detached
# 	Value = 2.0	Label = Semi-detached
# 	Value = 3.0	Label = or terraced/end of terrace?
#
#
# 
# FRS TYPEACC
#  1     | Whole house/bungalow, detached    
#  2     | Whole house/bungalow, semi-detache
#  3     | Whole house/bungalow, terraced    
#  4     | Purpose-built flat or maisonette  
#  5     | Converted house/building          
#  6     | Caravan/Mobile home or Houseboat  
#  7     | Other                             

"""
level 1
1.     | Whole house/bungalow, detached    
2.     | Whole house/bungalow, semi-detache
3.     | Whole house/bungalow, terraced    
4.     | Purpose-built flat or maisonette/Converted house/building  
5.     | Caravan/Mobile home or Houseboat, Other  
level 2
1.     House    
2.     Flat
3.     Other
"""
function frs_btype( typeacc :: Union{Missing,Int} ) :: Vector{Int}
    out = fill( 1, 3 )
    if ismissing(typeacc)
        return out
    end
    if typeacc < 5
        out[1] = typeacc
    elseif typeacc == 5
        out[1] = 4
    elseif in 6:7 
        out[1] = 5
    else
        @assert false "typeac $typacc not recognised" 
    end
    if typeacc in 1:3
        out[2] = 1
    elseif typeacc in 4:5
        out[2] = 2
    elseif typeacc in 6:7
        out[2] = 3
    end        
    return out
end

function shs_btype( hb1 :: Union{Missing,Int}, hb2 :: Union{Missing,Int} ) :: Vector{Int}
    out = fill( -886, 3 )
    if ismissing(hb1)
        return fill( -991, 3 )
    end
    if hb1 == 1
        if hb2 == 1
            out[1] = 1
        elseif hb2 == 2
            out[1] = 2
        elseif hb2 == 3
            out[1] = 3
        else
            @assert false "hb2=$hb2"
        end
    elseif hb1 == 2
        out[1] = 4
    elseif hb1 == 3
        out[1] = 5
    else
        @assert false "unrecognised hb1 $hb1"
    end
    out[2] = hb1
    return out
end


#

# shelter
# 
# accsup1 shs 1=yes 2=no
# shelter frs 1=yes 2=no
# 
# frs CTREB
# shs hh57_08 == 1 (? maybe 2 bus)
# 
# hhsize shs
# totads shs   adulth frs
# totkids shs  /depchldh frs/comp
# totpeeps (hhsize?)
# 
#  
# single parent hhtype_new == 3  shs hhcomps in 9:11 frs
# 
# accom type TYPEACC hb1

function assign2!( df :: DataFrame, name :: Symbol, vals )
    n = size(vals[1])[1]
    m = size( df )[1]
    ET = eltype(vals[1])
    # println( vals )
    for i in 1:n
        sym = Symbol("$(String(name))_$(i)")
        println( "wriring $sym $i" )
        df[!,sym] = zeros(ET,m)
        for j in 1:m
            df[j,sym] = vals[j][i]
        end
    end
end


donor = DataFrame( datayear=shs_all_years.datayear, uniqidnew=shs_all_years.uniqidnew )
recip = DataFrame( datayear=frs_all_years_scot_he.datayear, sernum=frs_all_years_scot_he.sernum )

assign2!( recip, :shelter, setone.( frs_all_years_scot_he.shelter ))
assign2!( recip, :tenure, frs_tenuremap.(frs_all_years_scot_he.tentyp2))
assign2!( recip, :singlepar, setone.(frs_all_years_scot_he.hhcomps, is_sp))
assign2!( recip, :numadults, total_people.( frs_all_years_scot_he.adulth, -777 ))
assign2!( recip, :numkids, total_people.( frs_all_years_scot_he.depchldh, -776 ))
assign2!( recip, :acctype, frs_btype.( frs_all_years_scot_he.typeacc ))

assign2!( donor, :shelter, setone.( shs_all_years.accsup1 ))
assign2!( donor, :tenure, shs_tenuremap.(shs_all_years.tenure))
assign2!( donor, :singlepar, setone.( shs_all_years.hhtype_new, 3 ))
assign2!( donor, :numadults, total_people.( shs_all_years.totads, -888 ))
assign2!( donor, :numkids, total_people.( shs_all_years.totkids, -887 ))
assign2!( donor, :acctype, shs_btype.(shs_all_years.hb1, shs_all_years.hb2))

