using CSV,DataFrames,Statistics,StatsBase
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
    frs[!,:datayear] .= year-2000
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
    out = fill( -988, 3 )
    if ismissing( tenure ) || tenure >= 5
        return out;
    end
    out[3] = 1
    if tenure == 1 # OO
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

#
# level 1 -> actual number of people
# level 2
#   0 -> 0 (for kids)
#   1 -> 1
#   2 -> 2
#   3 -> 3:5
#   4 -> > 5
#
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
    out
end

"""
1. age (max 80)
2. age 5 year bands
3. age 20 year bands
"""
function age( age  :: Union{Int,Missing} )  :: Vector{Int}
    out = fill( -99, 3 )
    if ismissing( age )
        return out
    end
    age = min( 80, age )
    out[1] = age 
    out[2] = Int(trunc(age/5))
    out[3] = Int(trunc(age/20))
    return out
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
level 3 
1. any

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
    elseif typeacc in 6:7 
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

function assign!( df :: DataFrame, name :: Symbol, vals )
    n = size(vals[1])[1]
    m = size( df )[1]
    ET = eltype(vals[1])
    # println( vals )
    for i in 1:n
        sym = Symbol("$(String(name))_$(i)")
        println( "writing $sym $i" )
        df[!,sym] = zeros(ET,m)
        for j in 1:m
            df[j,sym] = vals[j][i]
        end
    end
end

#   SHS hihecon
# 	Value = 1.0	Label = A - Self employed
# 	Value = 2.0	Label = B - Employed full time
# 	Value = 3.0	Label = C - Employed part time
# 	Value = 4.0	Label = D - Looking after the home or family
# 	Value = 5.0	Label = E - Permanently retired from work
# 	Value = 6.0	Label = F - Unemployed and seeking work
# 	Value = 7.0	Label = G - At school
# 	Value = 8.0	Label = H - In further / higher education
# 	Value = 9.0	Label = I - Gov't work or training scheme
# 	Value = 10.0	Label = J - Permanently sick or disabled
# 	Value = 11.0	Label = K - Unable to work because of short-term illness or injury
# 	Value = 12.0	Label = L - Pre school / Not yet at school
# 	Value = 13.0	Label = Other (specify)
# 
# 
# 	FRS EMPSTATI
#   Value = 1.0	Label = Full-time Employee 
# 	Value = 2.0	Label = Part-time Employee 
# 	Value = 3.0	Label = Full-time Self-Employed 
# 	Value = 4.0	Label = Part-time Self-Employed 
# 	Value = 5.0	Label = Unemployed 
# 	Value = 6.0	Label = Retired 
# 	Value = 7.0	Label = Student 
# 	Value = 8.0	Label = Looking after family/home 
# 	Value = 9.0	Label = Permanently sick/disabled 
# 	Value = 10.0	Label = Temporarily sick/injured 
# 	Value = 11.0	Label = Other Inactive 

# Level 1
# 1 Full-time Employee 
# 2 Part-time Employee
# 3 Self Employed
# 4 Unemployed
# 5 Retired
# 6 Student
# 7 Looking after the home or family
# 8 Permanently sick/disabled
# 9 Temporarily sick/injured 
# 10 Other Inactive 

# level 2
# 1 employed
# 2 self-employed
# 3 retired
# 4 student
# 5 other, inc unemployed

# level3 
# 1 working
# 2 retired
# 3 not working

function frs_empstat( empstati :: Int ) :: Vector{Int}
    out = fill( 0, 3 )
    out[1] = empstati
    if empstati > 3 
        out[1] -= 1
    end
    if out[1] in 1:2
        out[2] = 1
    elseif out[1] in 3
        out[2] = 2
    elseif out[1] in 5
        out[2] = 3
    elseif out[1] in 6
        out[2] = 4
    elseif out[1] in [4,7,8,9,10]
        out[2] = 5
    else
        @assert false "empstati $empstati"
    end
    if out[1] in 1:3
        out[3] = 1
    elseif out[1] in 5
        out[3] = 2
    else
        out[3] = 3
    end    
    return out
end

function shs_empstat( hihecon :: Union{Missing,Int} ) :: Vector{Int}
    out = fill( 0, 3 )
    if ismissing(hihecon) # value 14 not documented 
        return fill( -990, 3 )
    end
    if hihecon > 13 
        return fill( -989, 3 )
    end
    if  hihecon == 1
        out[1] = 3
    elseif hihecon == 2
        out[1] = 1
    elseif hihecon == 3
        out[1] = 2
    elseif hihecon == 4
        out[1] = 7
    elseif hihecon == 5
        out[1] = 5
    elseif hihecon == 6
        out[1] = 4
    elseif hihecon in [7,9,13]
        out[1] = 10
    elseif hihecon == 8
        out[1] = 6
    elseif hihecon == 10
        out[1] = 8
    elseif hihecon == 11
        out[1] = 9
    else    
        @assert false "hihecon $hihecon"
    end
    if out[1] in 1:2
        out[2] = 1
    elseif out[1] in 3
        out[2] = 2
    elseif out[1] in 5
        out[2] = 3
    elseif out[1] in 6
        out[2] = 4
    elseif out[1] in [4,7,8,9,10]
        out[2] = 5
    else
        @assert false "out[1] $(out[1])"
    end
    if out[1] in 1:3
        out[3] = 1
    elseif out[1] in 4
        out[3] = 2
    else
        out[3] = 3
    end     
    return out
end

# 
# 
# FRS ethgr3
# 
# Pos. = 512	Variable = ETHGR3	Variable label = Ethnicity of Adult (harmonised version)
# This variable is  numeric, the SPSS measurement level is NOMINAL
# SPSS user missing values = -9.0 thru -1.0
# 	Value label information for ETHGR3
# 	Value = 1.0	Label = White 
# 	Value = 2.0	Label = Mixed/ Multiple ethnic groups 
# 	Value = 3.0	Label = Asian/ Asian British 
# 	Value = 4.0	Label = Black/ African/ Caribbean/ Black British 
# 	Value = 5.0	Label = Other ethnic group 
# 	
# SHS  hih_eth2012
# 	
# Pos. = 35	Variable = HIH_ETH2012	Variable label = Ethnic origin of HiH
# This variable is  numeric, the SPSS measurement level is SCALE
# 	Value label information for HIH_ETH2012
# 	Value = 1.0	Label = White
# 	Value = 2.0	Label = Minority ethnic groups
# 	Value = 3.0	Label = Don't know
# 	Value = 4.0	Label = Refused	

#
# out
# level1
# 1-> White
# 2-> Non White
# level2
# 1-> Any
# level3
# 1-> Any

function frs_ethnic( ethgr3 :: Int ) :: Vector{Int}
    out = fill( 1, 3 )
    out[1] = ethgr3 == 1 ? 1 : 2
    return out
end

function shs_ethnic( hih_eth2012 :: Union{Missing,Int} ) :: Vector{Int}
    out = fill( 1, 3 )
    if ismissing(hih_eth2012) # value 14 not documented 
        return fill( -986, 3 )
    end
    if hih_eth2012 > 2
        return out
    end
    out[1] = hih_eth2012 == 1 ? 1 : 2
    return out
end

#
# annual hh net income
#  mean(collect(skipmissing(shs_all_years.annetinc)))
# SHS mean: 27,046.418224914407 median 23,000.0
# mean(collect(skipmissing(frs_all_years_scot_he.hhinc*52)))
# FRS mean 37,704.65 median 28,184.0

# SHS SOC hihsoc
# Pos. = 1410	Variable = hihsoc	Variable label = HIH Social Occupational Classification
# This variable is  numeric, the SPSS measurement level is NOMINAL
# 	Value label information for hihsoc
# 	Value = 1.0	Label = MANAGERS, DIRECTORS AND SENIOR OFFICIALS
# 	Value = 2.0	Label = PROFESSIONAL OCCUPATIONS
# 	Value = 3.0	Label = ASSOCIATE PROFESSIONAL AND TECHNICAL OCCUPATIONS
# 	Value = 4.0	Label = ADMINISTRATIVE AND SECRETARIAL OCCUPATIONS
# 	Value = 5.0	Label = SKILLED TRADES OCCUPATIONS
# 	Value = 6.0	Label = CARING, LEISURE AND OTHER SERVICE OCCUPATIONS
# 	Value = 7.0	Label = SALES AND CUSTOMER SERVICE OCCUPATIONS
# 	Value = 8.0	Label = PROCESS, PLANT AND MACHINE OPERATIVES
# 	Value = 9.0	Label = ELEMENTARY OCCUPATIONS
# 	Value = -9.0	Label = NO INFORMATION
# 
# FRS
# Pos. = 425	Variable = SOC2010	Variable label = Standard Occupational Classification
# This variable is  numeric, the SPSS measurement level is NOMINAL
# SPSS user missing values = -9.0 thru -1.0
# 	Value label information for SOC2010
# 	Value = 0.0	Label = Undefined 
# 	Value = 1000.0	Label = Managers Directors & Senior Officials 
# 	Value = 2000.0	Label = Professional Occupations 
# 	Value = 3000.0	Label = Associate Prof. & Technical Occupations 
# 	Value = 4000.0	Label = Admin & Secretarial Occupations 
# 	Value = 5000.0	Label = Skilled Trades Occupations 
# 	Value = 6000.0	Label = Caring leisure and other service occupations 
# 	Value = 7000.0	Label = Sales & Customer Service 
# 	Value = 8000.0	Label = Process, Plant & Machine Operatives 
# 	Value = 9000.0	Label = Elementary Occupations 
#
# level 1
# as hisoc if 1:9 else 0
# level2
# 0 -> undefined
# 1 -> 1..2
# 2 -> 3,4,7
# 3 -> 5,8
# 4 -> 6,9
# level2
# 1 -> all
# 11,000 undefined occs in shs, 263 in FRS
# 
function map_social( soc :: Int ) :: Vector{Int}
    out = fill(0,3)    
    if ! (soc in 1:9) 
        return [0,0,1]
    end
    out[1] = soc
    if soc in 1:2
        out[2] = 1
    elseif soc in [3,4,7]
        out[2] = 2
    elseif soc in [5,8]
         out[2] = 3
    elseif soc in [6,9]
         out[2] = 4
    else
        @assert false "soc=$soc"
    end
    out[3]=1
    return out
end

function shs_map_social( hihsoc :: Union{Missing,Int} ) :: Vector{Int}
    if ismissing(hihsoc)
        return [0,0,1]
    end
    return map_social( hihsoc )
end

function frs_map_social( soc2010 )
    return map_social( Int(soc2010/1000))
end

function data_year( dy :: Int ) :: Vector{Int}
    return [dy,1,1]
end


#
# Create donor  (SHS) and recipient (FRS) datasets.
#
donor = DataFrame( datayear=shs_all_years.datayear, uniqidnew=shs_all_years.uniqidnew )
recip = DataFrame( datayear=frs_all_years_scot_he.datayear, sernum=frs_all_years_scot_he.sernum )

# add placeholders for N matches

n_matches = 200
n_rows = size( recip )[1]
for i in 1:n_matches
   idkey = Symbol( "shs_uniqidnew_$(i)" )
   ykey = Symbol( "shs_datayear_$(i)" )
   recip[!,idkey] = fill("",n_rows)
   recip[!,ykey] = fill(0,n_rows)
   
end

assign!( recip, :shelter, setone.( frs_all_years_scot_he.shelter ))
assign!( recip, :tenure, frs_tenuremap.(frs_all_years_scot_he.tentyp2))
assign!( recip, :singlepar, setone.(frs_all_years_scot_he.hhcomps, is_sp))
assign!( recip, :numadults, total_people.( frs_all_years_scot_he.adulth, -777 ))
assign!( recip, :numkids, total_people.( frs_all_years_scot_he.depchldh, -776 ))
assign!( recip, :acctype, frs_btype.( frs_all_years_scot_he.typeacc ))
assign!( recip, :agehigh, age.( frs_all_years_scot_he.age80 ))
assign!( recip, :empstathigh, frs_empstat.( frs_all_years_scot_he.empstati ))
assign!( recip, :ethnichigh, frs_ethnic.( frs_all_years_scot_he.ethgr3 ))
assign!( recip, :sochigh, frs_map_social.( frs_all_years_scot_he.soc2010 ))
assign!( recip, :datayear, data_year.( frs_all_years_scot_he.datayear ))
 
assign!( donor, :shelter, setone.( shs_all_years.accsup1 ))
assign!( donor, :tenure, shs_tenuremap.(shs_all_years.tenure))
assign!( donor, :singlepar, setone.( shs_all_years.hhtype_new, 3 ))
assign!( donor, :numadults, total_people.( shs_all_years.totads, -888 ))
assign!( donor, :numkids, total_people.( shs_all_years.totkids, -887 ))
assign!( donor, :acctype, shs_btype.( shs_all_years.hb1, shs_all_years.hb2))
assign!( donor, :agehigh, age.( shs_all_years.hihage ))
assign!( donor, :empstathigh, shs_empstat.( shs_all_years.hihecon ))
assign!( donor, :ethnichigh, shs_ethnic.( shs_all_years.hih_eth2012 ))
assign!( donor, :sochigh, shs_map_social.( shs_all_years.hihsoc ))
assign!( donor, :datayear, data_year.( shs_all_years.datayear ))

#
# save everything
#
CSV.write( "data/merging/shs_donor_data.tab", donor )
CSV.write( "data/merging/frs_recip_data.tab", recip )
CSV.write( "data/merging/shs_all_years.tab", shs_all_years )
CSV.write( "data/merging/frs_all_years_scot_he.tab", frs_all_years_scot_he )

donor = CSV.File( "data/merging/shs_donor_data.tab"; types=Dict(:uniqidnew => String))|>DataFrame

targets = [:shelter,:tenure,:acctype,:singlepar,:numadults,:numkids,:empstathigh,:sochigh,:agehigh,:ethnichigh,:datayear]

function print_matches( matches )
    tm = sum( matches.matches)
    println( "mot matches= $tm" )
    cc=StatsBase.counts(matches.quality)
    for i in 1:size(cc)[1]
        if cc[i] !== 0
            println( "$(i-10) = $(cc[i])")
        end
    end
end

struct Matchstruct
    quality   :: Int
    uniqidnew :: String
    datayear  :: Int 
end

i = 0
matches = nothing
riter = eachrow( recip )
for r1 in riter
    global matches,i
    i += 1
    if( i > 10 )
        # break;
    end
    matches = Utils.coarse_match( 
        r1,
        donor,
        targets,
        3 )
    donor_indexes = 
    if i % 100 == 0
        print_matches( matches )
    end
end

function shuffle_blocks( a :: Vector ) :: Vector
    sort!( a, by = x -> x.quality )
    out = fill( a[1], 0 )
    block = fill( a[1], 0)
    n = size(a)[1]
    last = a[1]
    # println("n=$n a=$a")
    for i in 1:n
        if a[i].quality == last.quality
            # println("pushing $(a[i])")
            push!( block, a[i] )
        else
            println("adding block $(block)")
            last = a[i]
            shuffle!( block )
            out = vcat( out, block )
            resize!( block, 0 )
            push!( block,a [i] )
        end
    end
    if size(block)[1] > 0
        shuffle!( block )
        out = vcat( out, block )
    end
    return out
end


