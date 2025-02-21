module SHS
using ..Common 
import ..Model

using ScottishTaxBenefitModel
using .RunSettings
using .Definitions

import ScottishTaxBenefitModel.MatchingLibs.Common

using CSV,
    DataFrames,
    Measures,
    StatsBase,
    ArgCheck

# DIR = "/media/graham_s/Transcend/data/"
DIR = "/mnt/data/"

function loadshs( dyear::Int )::DataFrame
    year = dyear - 2000
    ystr = "$(year)$(year+1)"
    fname = "$(DIR)/shs/$(ystr)/tab/shs20$(year)_social_public.tab"
    println( "loading '$fname'" )
    shs = CSV.File( fname; 
        missingstring=["NA",""],normalizenames=true,
        types=Dict(:UNIQIDNEW=>String)) |> DataFrame
    lcnames = Symbol.(lowercase.(string.(names(shs))))
    rename!(shs,lcnames)
    shs[!,:datayear] .= dyear
    
    return shs
end


"""
Stack scottish household surveys. 
"""
function create_shs( years :: UnitRange ) :: DataFrame
    n = length(years)
    shs = Array{DataFrame}(undef,n)
    i = 0
    for year in years
        i += 1
        shs[i] = loadshs(year)
    end
    return vcat( shs...; cols=:intersect )
end

"""
     SHS Tenure
     Pos. = 56	Variable = tenure	Variable label = Tenure - SHS but non-harmonised version
     This variable is    numeric, the SPSS measurement level is NOMINAL
     	Value label information for tenure
     	Value = 1.0	Label = Owned outright
     	Value = 2.0	Label = Buying with help of loan/mortgage
     	Value = 3.0	Label = Rent – LA
     	Value = 4.0	Label = Rent - HA, Co-op
     	Value = 5.0	Label = Rent - private landlord
     	Value = 6.0	Label = Other
     	Value = 999998.0	Label = Don't know
     	Value = 999999.0	Label = Refused
     
          FRS TENURE
     
     os. = 258	Variable = TENTYP2	Variable label = Tenure type
     This variable is    numeric, the SPSS measurement level is NOMINAL
     SPSS user missing values = -9.0 thru -1.0
     	Value label information for TENTYP2
     	Value = 1.0	Label = LA / New Town / NIHE / Council rented 
     	Value = 2.0	Label = Housing Association / Co-Op / Trust rented 
     	Value = 3.0	Label = Other private rented unfurnished 
     	Value = 4.0	Label = Other private rented furnished 
     	Value = 5.0	Label = Owned with a mortgage (includes part rent / part own) 
     	Value = 6.0	Label = Owned outright 
     	Value = 7.0	Label = Rent-free 
     	Value = 8.0	Label = Squats

     harmonised tenure
     
     1 -> OO
     2 -> Mortgaged
     3 -> LA/Council Rented
     4 -> HA Rented
     5 -> Private Rented
     6 -> Other

     coarsened tenure
     1 -> Owned
     2 -> Rented
     3 -> Other
"""
function tenuremap( tenure :: Union{Int,Missing} ) :: Vector{Int}
    if ismissing( tenure ) # || tenure >= 5
        return [rand(Int),rand(Int)];
    end
    t1, t2 = if tenure == 1 # OO
        1,1
    elseif tenure == 2
        2,1
    elseif tenure == 3
        3,2
    elseif tenure == 4
        4,2
    elseif tenure == 5
        5,2
    elseif tenure in [6, 7]
        6,3
    else
        @assert false "unmatched tenure $tenure"
    end
    return [t1,t2]
end

"""
Harmonised FRS tenure, as above
"""
function shs_model_tenure( tenure :: Tenure_Type )::Vector{Int}
    t1, t2 = if tenure == Owned_outright
        1,1
    elseif tenure == Mortgaged_Or_Shared
        2,1
    elseif tenure == Council_Rented
        3, 2
    elseif tenure == Housing_Association
        4, 2
    elseif tenure in [Private_Rented_Unfurnished,Private_Rented_Furnished]
        5, 2
    else
        6, 3
    end
    return [t1,t2]
end

"""
     level 1 -> actual number of people
     level 2
       0 -> 0 (for kids)
       1 -> 1
       2 -> 2
       3 -> 3:5
       4 -> > 5
     level 3 
      1 adult -> 0
      2 adults -> 1
      > 2 adults -> 2
      0 child -> 0
      > 0 child -> 1
"""
function total_people( n :: Union{Int,Missing}, is_child :: Bool ) :: Vector{Int}
    out = fill( 0, 3 )
    if ismissing( n )
        return rand(Int,3)
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
    if is_child # any children
       out[3] = out[2] > 0 ? 1 : 0
    else
       @assert out[2] > 0 "no adults"
       if out[2] == 1
            out[3] == 0
       elseif out[2] == 2
            out[3] = 1
       else
           out[3] = 2
       end
    end
    return out
end


"""
1. age (max 80)
2. age 5 year bands
3. age 20 year bands
"""
function age( age  :: Union{Int,Missing} )  :: Vector{Int}
    out = fill( 0, 3 )
    if ismissing( age )
        return out
    end
    age = min( 80, age )
    out[1] = age 
    out[2] = Int(trunc(age/5))
    out[3] = Int(trunc(age/20))
    return out
end
    
"""
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

"""
function empstat( hihecon :: Union{Missing,Int} ) :: Vector{Int}
    if ismissing(hihecon) || (hihecon > 13 ) # value 14 not documented 
        return rand(Int,3)
    end
    o1, o2, o3 = if  hihecon == 1 # Self employed
        3 ,2, 1
    elseif hihecon == 2  # Employed full tim
        1, 1, 1
    elseif hihecon == 3 #  Employed part time
        2, 1, 1
    elseif hihecon == 4 # Looking after the home or family, 
        7, 5, 3 
    elseif hihecon == 5 # Permanently retired from wor
        5, 3, 2
    elseif hihecon in [6,9] # Unemployed and seeking work,  Gov't work or training scheme
        4, 5, 3
    elseif hihecon == 13 # Other (specify)
        10, 5, 3
    elseif hihecon in [7,12,8] # At school,  Pre school / Not yet at school??, In further / higher education
        6, 4, 3
    elseif hihecon == 10 # Permanently sick or disabled
        8, 5, 3
    elseif hihecon == 11 # Unable to work because of short-term illness or injury
        9, 5, 3
    else    
        @assert false "hihecon $hihecon"
    end
    return [o1, o2, o3]
end

function shs_model_empstat( empl :: ILO_Employment ) :: Vector{Int}
    o1, o2, o3 = if empl == Full_time_Employee
        1, 1, 1
    elseif empl == Part_time_Employee
        2, 1, 1
    elseif empl in [Full_time_Self_Employed,Part_time_Self_Employed]
        3 ,2, 1
    elseif empl == Unemployed
        4, 5, 3
    elseif empl == Retired
        5, 3, 2
    elseif empl == Student
        6, 4, 3
    elseif empl == Looking_after_family_or_home
        7, 5, 3 
    elseif empl == Permanently_sick_or_disabled
        8, 5, 3
    elseif empl == Temporarily_sick_or_injured
        9, 5, 3
    elseif empl == Other_Inactive
        10, 5, 3
    end
    return [o1, o2, o3]
end

function ethnic( hih_eth2012 :: Union{Missing,Int} ) :: Vector{Int}
    if ismissing(hih_eth2012) 
        return rand(Int,1)
    end
    return hih_eth2012 == 1 ? [1] : [2]
end

function shs_model_ethnic( ethgr :: Ethnic_Group ) :: Vector{Int}
    return ethgr == White ? [1] : [2]
end


#=
     SHS SOC hihsoc
     Pos. = 1410	Variable = hihsoc	Variable label = HIH Social Occupational Classification
     This variable is  numeric, the SPSS measurement level is NOMINAL
     	Value label information for hihsoc
     	Value = 1.0	Label = MANAGERS, DIRECTORS AND SENIOR OFFICIALS
     	Value = 2.0	Label = PROFESSIONAL OCCUPATIONS
     	Value = 3.0	Label = ASSOCIATE PROFESSIONAL AND TECHNICAL OCCUPATIONS
     	Value = 4.0	Label = ADMINISTRATIVE AND SECRETARIAL OCCUPATIONS
     	Value = 5.0	Label = SKILLED TRADES OCCUPATIONS
     	Value = 6.0	Label = CARING, LEISURE AND OTHER SERVICE OCCUPATIONS
     	Value = 7.0	Label = SALES AND CUSTOMER SERVICE OCCUPATIONS
     	Value = 8.0	Label = PROCESS, PLANT AND MACHINE OPERATIVES
     	Value = 9.0	Label = ELEMENTARY OCCUPATIONS
     	Value = -9.0	Label = NO INFORMATION
     
     FRS
     Pos. = 425	Variable = SOC2010	Variable label = Standard Occupational Classification
     This variable is  numeric, the SPSS measurement level is NOMINAL
     SPSS user missing values = -9.0 thru -1.0
     	Value label information for SOC2010
     	Value = 0.0	Label = Undefined 
     	Value = 1000.0	Label = Managers Directors & Senior Officials 
     	Value = 2000.0	Label = Professional Occupations 
     	Value = 3000.0	Label = Associate Prof. & Technical Occupations 
     	Value = 4000.0	Label = Admin & Secretarial Occupations 
     	Value = 5000.0	Label = Skilled Trades Occupations 
     	Value = 6000.0	Label = Caring leisure and other service occupations 
     	Value = 7000.0	Label = Sales & Customer Service 
     	Value = 8000.0	Label = Process, Plant & Machine Operatives 
     	Value = 9000.0	Label = Elementary Occupations 
    
     level 1
     as hisoc if 1:9 else 0
     level2
     0 -> undefined
     1 -> 1..2
     2 -> 3,4,7
     3 -> 5,8
     4 -> 6,9
     level2
     1 -> all
     11,000 undefined occs in shs, 263 in FRS
     
=#
function map_social( soc :: Union{Int,Missing} ) :: Vector{Int}
    if ismissing(soc)
        return rand(Int,3)
    end
    if ! (soc in 1:9) 
        return [0,0]
    end
    s2 = if soc in 1:2
        1
    elseif soc in [3,4,7]
        2
    elseif soc in [5,8]
        3
    elseif soc in [6,9]
         4
    else
        @assert false "soc=$soc"
    end
    return [soc,s2]
end

function shs_model_map_social( soc :: Standard_Occupational_Classification ) :: Vector{Int}
    # @argcheck socio in 1:12
    o = Int(soc) ÷ 1000
    return map_social(o)
end


function bedrooms( rooms :: Union{Missing,Int} ) :: Vector{Int}
    rooms = min(6, rooms )
    out = fill(0,3)    
    if (ismissing(rooms) || (rooms == 0 )) 
        return [0,0, 1]
    end
    out = fill(0,3)   
    out[1] = rooms
    out[2] = min( rooms, 3)
    out[3] = rooms == 1 ? 1 : 2
    return out
end

"""
Pos. = 2,761	Variable = hb1	Variable label = hb1 - Is the household's accommodation...

This variable is    numeric, the SPSS measurement level is NOMINAL
	Value label information for hb1
	Value = 1.0	Label = House or bungalow
	Value = 2.0	Label = A flat, maisonette or apartment (including ) 
	Value = 3.0	Label = Other, including room(s), caravan/mobile homes

Pos. = 108	Variable = hb2	Variable label = hb2 - Is it...
This variable is    numeric, the SPSS measurement level is NOMINAL
	Value label information for hb2
	Value = 1.0	Label = Detached
	Value = 2.0	Label = Semi-detached
	Value = 3.0	Label = or terraced/end of terrace?

out: detatached = 1
    semi = 2
    terrace = 3
    all flats = 4
    all other = 5

"""
function accomtype( hb1 :: Union{Missing,Int}, hb2 :: Union{Missing,Int} ) :: Vector{Int}
    out = fill( 0, 2 )
    if ismissing(hb1)
        return out
    end
    if hb1 == 1 # House or bungalow
        if hb2 == 1 
            out[1] = 1 # Detached
        elseif hb2 == 2
            out[1] = 2 #  Semi-detached
        elseif hb2 == 3
            out[1] = 3 # or terraced/end of terrace?
        else
            @assert false "hb2=$hb2"
        end
    elseif hb1 == 2 # flat, etc
        out[1] = 4
    elseif hb1 == 3
        out[1] = 5  # Other, including room(s), caravan/mobile homes
    else
        @assert false "unrecognised hb1 $hb1"
    end
    out[2] = hb1
    return out
end


"""
In:
   dwell_na = -1
   detatched = 1
   semi_detached = 2
   terraced = 3
   flat_or_maisonette = 4
   converted_flat = 5
   caravan = 6
   other_dwelling = 7
Out:
   detatched = 1
   semi_detached = 2
   terraced = 3
   flat 4
   other 5
   with na distributed randomly
"""
function model_to_shs_accommap( dwelling :: DwellingType ):: Vector{Int}
    if dwelling == dwell_na
        println( "na dwelling ")
        dwelling = rand([detatched,semi_detached,terraced,flat_or_maisonette,converted_flat])
    end
    id1, id2 = if dwelling in [detatched,semi_detached,terraced]
        Int(dwelling), 1
    elseif dwelling in [flat_or_maisonette,converted_flat ]
        4, 2
    else
        5, 3
    end
    return [id1,id2]
end


"""

hhtype_new

    Value = 1.0	Label = Single adult
	Value = 2.0	Label = Small adult
	Value = 3.0	Label = Single parent
	Value = 4.0	Label = Small family
	Value = 5.0	Label = Large family
	Value = 6.0	Label = Large adult
	Value = 7.0	Label = Older smaller
	Value = 8.0	Label = Single pensioner


out 
  single_person 1 1
  single_parent 2 2
  w_kids        3 2
  other         4 3

"""
function map_composition( hhtype_new :: Union{Int,Missing} )::Vector{Int}
    if ismissing(hhtype_new)
        return rand(Int,2)
    end
    c1, c2 = if hhtype_new == 1
        1, 1
    elseif hhtype_new == 3
        2,2
    elseif hhtype_new in [4,5]
        3,2
    elseif hhtype_new in [2,6,7,8]
        4,3
    else
        @assert false "unmatched hhtype_new $hhtype_new"
    end 
    return [c1,c2]
end

"""
see map_composition
   
Model composition:

   single_person = 1
   single_parent = 2 
   couple_wo_children = 3 
   couple_w_children = 4 
   mbus_wo_children = 5 
   mbus_w_children = 6

to:
  single_person 1 1
  single_parent 2 2
  w_kids        3 2
  other         4 3

"""
function model_shs_map_composition( comp :: HouseholdComposition1 )::Vector{Int}
    c1, c2 = if comp == single_person
        1,1
    elseif comp == single_parent 
        2,2
    elseif comp in [couple_wo_children, mbus_wo_children]
        4,3 
    elseif comp in [couple_w_children, mbus_w_children]
        3,2
    end
    return [c1,c2]
end


end # Module