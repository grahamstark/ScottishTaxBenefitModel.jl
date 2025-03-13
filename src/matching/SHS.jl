module SHS
using ..Common 
import ..Model

using ScottishTaxBenefitModel
using .RunSettings
using .Definitions
using .ModelHousehold
import ScottishTaxBenefitModel.MatchingLibs.Common
import ScottishTaxBenefitModel.MatchingLibs.Common: score as cscore, MatchingLocation
import ScottishTaxBenefitModel.MatchingLibs.Model as model
using CSV,
    DataFrames,
    Measures,
    StatsBase,
    ArgCheck

# DIR = "/media/graham_s/Transcend/data/"
DIR = "/mnt/data/"

function add_sample_freqs!( shs :: DataFrame )
    nrows,ncols = size( shs )
    shs_councils = CSV.File( "data/merging/la_mappings.csv"; delim=',') |> DataFrame
    target_pops = CSV.File( "data/merging/hhlds_and_people_2022_nrs_estimates.csv" ) |> DataFrame
    lacounts = sort(countmap(shs.lad_2017))
    all_hhs = sum(target_pops.hhlds_2022)
    freqs = Dict{Symbol,Real}()
    for (la,pop) in lacounts
        println( "on $la" ); 
        hhc = target_pops[target_pops.code .== la,:hhlds_2022][1]
        weight = pop/hhc
        freqs[la] = weight
        println( "$la = $invfreq")
    end
    shs.council_freq = zeros(nrows)
    for r in eachrow( shs )
        r.council_freq = freqs[r.lad_2017]
    end
end


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

function create_subset( ):: DataFrame 
    shss = create_shs( 2019:2022 )
    shss = DataFrame(
        uniqidnew = parse.(Int,shss.uniqidnew),
        datayear = shss.datayear, 
        # accsup1 = shss.accsup1,
        tenure = shss.tenure, 
        hb1 = shss.hb1,
        hb2 = coalesce.(shss.hb2,-1), # detatched, terraced .. missing if hn1 != 1
        hc4 = shss.hc4, 
        hhtype_new = shss.hhtype_new,
        totads = shss.totads, 
        numkids = shss.numkids, 
        hihage = shss.hihage, 
        hihecon = shss.hihecon, 
        hih_eth2012 = shss.hih_eth2012, 
        hihsoc = shss.hihsoc, 
        hh_net_income = shss.tothinc,
        council  = shss.council,	# 18	local authority	nominal	a1	4	left
        la_groupings = shss.area,	# 19	shs local authority groupings	nominal	f8.2	10	right
        health_board = shss.hlthbd2019, #	20	health board (2019 classification) - standard geography codes	nominal	a9	9	left
        health_board_code = shss.hlth19,	# 21	health board (2019 classification)	nominal	f2	8	right
        simd = shss.md20quin,	# 22	simd 2020 - 1 = 20% most deprived to 5 = 20% least deprived	nominal	f1	8	right
        geog_code = shss.rtpsegis, #	23	rtp geography code	nominal	a9	9	left
        rtp_area = shss.rtparea,	# 24	rtp area	scale	f2	8	right
        hhsize = shss.numbhh )
        # local authority designation 2017 version, via a wee lookup.
        # note this fills in 66 missing cases with a randomly chosen lad_2017 code.
    dropmissing!( shss )
    shss.lad_2017 = Definitions.scodefind.( shss.council )
    return shss
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
function map_tenure( tenure :: Union{Int,Missing} ) :: Vector{Int}
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
function model_to_shs_map_tenure( tenure :: Tenure_Type )::Vector{Int}
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
function map_empstat( hihecon :: Union{Missing,Int} ) :: Vector{Int}
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

function shs_model_map_empstat( empl :: ILO_Employment ) :: Vector{Int}
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

"""
white=1
nonwhite = 2
"""
function map_ethnic( hih_eth2012 :: Union{Missing,Int} ) :: Vector{Int}
    if ismissing(hih_eth2012) 
        return rand(Int,1)
    end
    return hih_eth2012 == 1 ? [1] : [2]
end

"""
white=1
nonwhite = 2
"""
function shs_model_map_ethnic( ethgr :: Ethnic_Group ) :: Vector{Int}
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
        return rand(Int,2)
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
note: hb2 is missing if hb1 != 1 (so not a house)
"""
function map_accom( hb1 :: Union{Missing,Int}, hb2 :: Union{Missing,Int} ) :: Vector{Int}
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
function model_to_shs_map_accom( dwelling :: DwellingType ):: Vector{Int}
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

function model_row_shs_match(
    hh :: Household, wass :: DataFrameRow ) :: MatchingLocation
    head = get_head(hh)
    t = 0.0
    return 
end

function model_row_match( 
    hh :: Household, shss :: DataFrameRow ) :: MatchingLocation
    head = get_head(hh)   
    cts = model.counts_for_match( hh )
    t = 0.0
    # map_one!.( (shs_summaries,), (:shelter,), shss.accsup1 )
    t += cscore( map_tenure(shss.tenure), model_to_shs_map_tenure( hh.tenure ))
    t += cscore( map_accom(shss.hb1, shss.hb2), model_to_shs_map_accom(hh.dwelling)) 
    t += cscore( Common.map_bedrooms(shss.hc4 ), Common.map_bedrooms( hh.bedrooms )) 
    t += cscore( map_composition(shss.hhtype_new ), model_shs_map_composition( household_composition_1(hh)))
    t += cscore( Common.map_total_people(shss.totads ), Common.map_total_people( cts.num_adults )) 
    t += cscore( Common.map_total_people( shss.numkids ) ,Common.map_total_people(cts.num_children )) 
    t += cscore( Common.map_age(shss.hihage ), Common.map_age(head.age )) 
    t += cscore( map_empstat(shss.hihecon ), shs_model_map_empstat(head.employment_status)) 
    t += cscore( map_ethnic(shss.hih_eth2012 ), shs_model_map_ethnic(head.ethnic_group))
    t += cscore( map_social( shss.hihsoc ), shs_model_map_social( head.occupational_classification )) 
    return  MatchingLocation( shss.uniqidnew, shss.datayear, t, 0.0, 0.0 ) 
end # func model_row_match


end # Module