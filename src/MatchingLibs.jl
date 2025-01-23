module MatchingLibs

#
# A script to match records from 2019/19 to 2020/21 lcf to 2020 FRS
# strategy is to match to a bunch of characteristics, take the top 20 of those, and then
# match between those 20 on household income. 
# TODO
# - make this into a module and a bit more general-purpose;
# - write up, so why not just Engel curves?
#
using ScottishTaxBenefitModel
using .Definitions,
    .ModelHousehold,
    .FRSHouseholdGetter,
    # FIXME cross dependency .ExampleHouseholdGetter,
    .Uprating,
    .RunSettings

using CSV,
    DataFrames,
    Measures,
    StatsBase,
    ArgCheck,
    PrettyTables

export make_lcf_subset, 
    map_example, 
    load, 
    map_all_lcf_frs, 
    frs_lcf_match_row


s = instances( Socio_Economic_Group )

include( "matching/Common.jl")
include( "matching/Model.jl")
include( "matching/LCF.jl")
include( "matching/WAS.jl")
include( "matching/SHS.jl")

export TOPCODE, within, load, uprate_incomes!, checkdiffs

const NUM_SAMPLES = 20


#=
frs     | 2020 | househol | HHAGEGR4      | 1     | Age 16 to 19   | Age_16_to_19
frs     | 2020 | househol | HHAGEGR4      | 2     | Age 20 to 24   | Age_20_to_24
frs     | 2020 | househol | HHAGEGR4      | 3     | Age 25 to 29   | Age_25_to_29
frs     | 2020 | househol | HHAGEGR4      | 4     | Age 30 to 34   | Age_30_to_34
frs     | 2020 | househol | HHAGEGR4      | 5     | Age 35 to 39   | Age_35_to_39
frs     | 2020 | househol | HHAGEGR4      | 6     | Age 40 to 44   | Age_40_to_44
frs     | 2020 | househol | HHAGEGR4      | 7     | Age 45 to 49   | Age_45_to_49
frs     | 2020 | househol | HHAGEGR4      | 8     | Age 50 to 54   | Age_50_to_54
frs     | 2020 | househol | HHAGEGR4      | 9     | Age 55 to 59   | Age_55_to_59
frs     | 2020 | househol | HHAGEGR4      | 10    | Age 60 to 64   | Age_60_to_64
frs     | 2020 | househol | HHAGEGR4      | 11    | Age 65 to 69   | Age_65_to_69
frs     | 2020 | househol | HHAGEGR4      | 12    | Age 70 to 74   | Age_70_to_74
frs     | 2020 | househol | HHAGEGR4      | 13    | Age 75 or over | Age_75_or_over
=#

#=
    Value = 3.0	Label =  15 but under 20 yrs
    Value = 4.0	Label =  20 but under 25 yrs
    Value = 5.0	Label =  25 but under 30 yrs
    Value = 6.0	Label =  30 but under 35 yrs
    Value = 7.0	Label =  35 but under 40 yrs
    Value = 8.0	Label =  40 but under 45 yrs
    Value = 9.0	Label =  45 but under 50 yrs
    Value = 10.0	Label =  50 but under 55 yrs
    Value = 11.0	Label =  55 but under 60 yrs
    Value = 12.0	Label =  60 but under 65 yrs
    Value = 13.0	Label =  65 but under 70 yrs
    Value = 14.0	Label =  70 but under 75 yrs
    Value = 15.0	Label =  75 but under 80 yrs
    Value = 16.0	Label =  80 and over
=#


#=

hh gross income

lcf     | 2020 | dvhh            | P389p      |   1 | numeric | scale             | Normal weekly disposable hhld income - top-coded                                                                                                                                                |         1

p344p
lcf     | 2020 | dvhh            | p344p |   1 | numeric | scale             | Gross normal weekly household income - top-coded |         1
lcf     | 2020 | dvhh            | P352p      |   1 | numeric | scale             | Gross current income of household - top-coded    
frs     | 2020 | househol | HHINC    | 249 | numeric | scale             | HH - Total Household income                 |         1

julia> summarystats( lcfhh.p344p )
Summary Stats:
Length:         5400
Missing Count:  0
Mean:           872.313711
Minimum:        0.000000
1st Quartile:   432.048923
Median:         744.151615
3rd Quartile:   1172.362500
Maximum:        2420.030000 ## TOPCODED


julia> summarystats( frshh.hhinc )
Summary Stats:
Length:         16364
Missing Count:  0
Mean:           855.592520
Minimum:        -7024.000000
1st Quartile:   380.000000
Median:         636.000000
3rd Quartile:   1070.000000
Maximum:        30084.000000

=#


islessscore( l1::LCFLocation, l2::LCFLocation ) = l1.score < l2.score
islessincdiff( l1::LCFLocation, l2::LCFLocation ) = l1.incdiff < l2.incdiff

"""
Match one row in the FRS (recip) with all possible lcf matches (donor). Intended to be general
but isn't really any more. FIXME: pass in a saving function so we're not tied to case/datayear.
"""
function match_recip_row( recip, donor :: DataFrame, matcher :: Function, incomesym=:income ) :: Vector{LCFLocation}
    drows, dcols = size(donor)
    i = 0
    similar = Vector{LCFLocation}( undef, drows )
    for lr in eachrow(donor)
        i += 1
        score, incdiff = matcher( recip, lr )
        similar[i] = LCFLocation( lr.case, lr.datayear, score, lr[incomesym], incdiff )
    end
    # sort by characteristics   
    similar = sort( similar; lt=islessscore, rev=true )[1:NUM_SAMPLES]
    # .. then the nearest income amongst those
    similar = sort( similar; lt=islessincdiff, rev=true )[1:NUM_SAMPLES]
    return similar
end



"""
Map the entire datasets.
"""
function map_all_lcf_frs( recip :: DataFrame, donor :: DataFrame, matcher :: Function )::DataFrame
    p = 0
    nrows = size(recip)[1]
    df = makeoutdf( nrows, "lcf" )
    for fr in eachrow(recip); 
        p += 1
        println(p)
        df[ hno, :frs_sernum] = fr.sernum
        df[ hno, :frs_datayear] = fr.datayear
        df[ hno, :frs_income] = fr.income
        matches = match_recip_row( fr, donor, matcher ) 
        for i in 1:NUM_SAMPLES
            lcf_case_sym = Symbol( "lcf_case_$i")
            lcf_datayear_sym = Symbol( "lcf_datayear_$i")
            lcf_score_sym = Symbol( "lcf_score_$i")
            lcf_income_sym = Symbol( "lcf_income_$i")
            df[ hno, lcf_case_sym] = matches[i].case
            df[ hno, lcf_datayear_sym] = matches[i].datayear
            df[ hno, lcf_score_sym] = matches[i].score
            df[ hno, lcf_income_sym] = matches[i].income    
        end
        if p > 10000000
            break
        end
    end
    return df
end

function map_example( example :: Household, donor :: DataFrame, matcher::Function )::LCFLocation
    matches = map_recip_row( example, donor, matcher )
    return matches[1]
end



function map_socio( socio :: Int, default=9998 ) :: Vector{Int}
    out = fill( default, 3 )
    out[1] = socio
    out[2] = if socio in 1:5
        1
    elseif socio !== 10
        2
    else
        3
    end
    out[3] = socio == 10 ? 2 : 1
    out
end


function map_marital( ms :: Int, default=9998 ) :: Vector{Int}
    out = fill( default, 3 )
    out[1] = ms
    out[2] = ms in [1,2] ? 1 : 2
    return out
end


"""
Missing_Marital_Status = -1
   Married_or_Civil_Partnership = 1
   Cohabiting = 2
   Single = 3
   Widowed = 4
   Separated = 5
   Divorced_or_Civil_Partnership_dissolved = 6
"""
function model_map_marital( mar :: Marital_Status ):: Vector{Int} 
    im = Int( mar )
    @assert im in 1:6 "im missing $mar = $im"
    return map_marital(im)
end


function map_empstat( ie :: Int, default=9998 ):: Vector{Int}
    out = fill( default, 3 )
    out[1] = ie
    out[2] = ie in 1:2 ? 1 : 2
    return out
end

"""
   Missing_ILO_Employment = -1
   Full_time_Employee = 1
   Part_time_Employee = 2
   Full_time_Self_Employed = 3
   Part_time_Self_Employed = 4
   Unemployed = 5
   Retired = 6
   Student = 7
   Looking_after_family_or_home = 8
   Permanently_sick_or_disabled = 9
   Temporarily_sick_or_injured = 10
   Other_Inactive = 11
"""
function model_map_empstat( ie :: ILO_Employment  ) :: Vector{Int} #  
    out = if ie in [Full_time_Employee,Part_time_Employee]
        1
    elseif ie in [Full_time_Self_Employed,Part_time_Self_Employed ]
        2
    elseif ie == Unemployed
        3
    elseif ie == Retired 
        7
    elseif ie == Student
        4
    elseif ie == Looking_after_family_or_home
        5
    elseif ie in [Permanently_sick_or_disabled,Temporarily_sick_or_injured]
        6
    elseif ie in [Other_Inactive,Missing_ILO_Employment]
        8
    else
        @assert false "unmapped empstat $empstat = $ie"
    end
    return map_empstat( Int(out) )
end


"""

North_East = 1
North_West = 2
Yorks_and_the_Humber = 3
East_Midlands = 4
West_Midlands = 5
East_of_England = 6
London = 7
South_East = 8
South_West = 9
Wales = 10
Scotland = 11 
Northern_Ireland = 12

Heavily weight Scotland, then n england, then midland/wales, 0 London/SE
NOTE 2.0 1.0 0.5 0.1 
"""
function region_score_scotland(
    a3 :: Vector{Int}, b3 :: Vector{Int}, weights = [2.0,1.0,0.5,0.1,0])::Float64
    @argcheck a3[1] == 11
    return if a3[1] == b3[1] # scotland
        weights[1]
    else 
        if b3[1] in [1,2,3 ] # neast, nwest, yorks
            weights[2]
        elseif b3[1] in [ 4, 5, 10, 12] # e/w midlands, wales
            weights[3]
        elseif b3[1] in [8] #South_West
            weights[4]
        else # london, seast
            weights[5]
        end 
    end
end

"""
Match one row in the FRS (recip) with all possible lcf matches (donor). Intended to be general
but isn't really any more. FIXME: pass in a saving function so we're not tied to case/datayear.
"""
#=
function match_recip_row( recip, donor :: DataFrame, matcher :: Function ) :: Vector{LCFLocation}
    drows, dcols = size(donor)
    i = 0
    similar = Vector{LCFLocation}( undef, drows )
    for lr in eachrow(donor)
        i += 1
        score, incdiff = matcher( recip, lr )
        similar[i] = LCFLocation( lr.case, lr.datayear, score, lr.income, incdiff )
    end
    # sort by characteristics   
    similar = sort( similar; lt=islessscore, rev=true )[1:NUM_SAMPLES]
    # .. then the nearest income amongst those
    similar = sort( similar; lt=islessincdiff, rev=true )[1:NUM_SAMPLES]
    return similar
end

=#


"""
"""

function create_was_frs_matching_dataset( settings :: Settings  ) :: Tuple

    function addtodf( df::DataFrame, label, n, row::Int, data::Vector)
        @assert size(data)[1] == n "data=$(size(data)[1]) n = $n"
        for i in 1:n
            k = Symbol( "$(label)_$(i)")
            df[row,k] = data[i]
        end
    end

    settings.num_households, settings.num_people, nhh2 = 
           FRSHouseholdGetter.initialise( settings; reset=false )
    was_dataset = CSV.File(joinpath(data_dir( settings ),settings.wealth_dataset))|>DataFrame
    nwas = size( was_dataset )[1]
    wasset = DataFrame()
    frsset = DataFrame()
    for v in WAS_TARGET_VARS
        k = v[1]
        n = v[2]
        for i in 1:n
            key = Symbol( "$(k)_$(i)")
            wasset[!,key] = zeros( Int, nwas )
            frsset[!,key] = zeros( Int, settings.num_households )
        end
    end
    println( names(wasset))
    hno = 0
    for was in eachrow( was_dataset )
        hno += 1
        addtodf( 
            wasset, 
            "age",
            WAS_TARGET_VARS["age"], 
            hno, 
            was_frs_age_map(was.age_head, 9997 ))
        addtodf( 
            wasset, 
            "region",
            WAS_TARGET_VARS["region"], 
            hno,  
            frs_regionmap( was.region, 9997 ))
        addtodf( 
            wasset, 
            "accom",
            WAS_TARGET_VARS["accom"], 
            hno,  
            lcf_accmap( was.accom, 9997 ))
        addtodf( 
            wasset, 
            "tenure",
            WAS_TARGET_VARS["tenure"], 
            hno,  
            frs_tenuremap( was.tenure, 9997 ))
        addtodf( 
            wasset, 
            "socio",
            WAS_TARGET_VARS["socio"], 
            hno, 
            map_socio( was.socio_economic_head, 9997 ))
        addtodf( 
            wasset, 
            "empstat",
            WAS_TARGET_VARS["empstat"], 
            hno, 
            map_empstat( was.empstat_head, 9997 ))
        addtodf( 
            wasset, 
            "sex",
            WAS_TARGET_VARS["sex"], 
            hno, 
            [was.sex_head] )
        addtodf( 
            wasset, 
            "marital",
            WAS_TARGET_VARS["marital"], 
            hno, 
            map_marital( was.marital_status_head, 9997 ) )
        addtodf( 
            wasset, 
            "year",
            WAS_TARGET_VARS["year"], 
            hno, 
            [was.year] )
        addtodf( 
            wasset, 
            "wages",
            WAS_TARGET_VARS["wages"], 
            hno, 
            [was.any_wages] )
        addtodf( 
            wasset, 
            "selfemp",
            WAS_TARGET_VARS["selfemp"], 
            hno, 
            [was.any_selfemp] )
        addtodf( 
            wasset, 
            "pensions",
            WAS_TARGET_VARS["pensions"], 
            hno, 
            [was.any_pension_income] )
        addtodf( 
            wasset, 
            "degree",
            WAS_TARGET_VARS["degree"], 
            hno, 
            [was.has_degree] )
        addtodf( 
            wasset, 
            "children",
            WAS_TARGET_VARS["degree"], 
            hno, 
            [was.num_children] )
        addtodf( 
            wasset, 
            "children",
            WAS_TARGET_VARS["children"], 
            hno, 
            person_map(was.num_children, 9997))
        addtodf( 
            wasset, 
            "adults",
            WAS_TARGET_VARS["adults"], 
            hno, 
            person_map(was.num_adults, 9997))
    end
    for hno in 1:settings.num_households
        hh = FRSHouseholdGetter.get_household(hno)
        any_wages, any_selfemp, any_pension_income, has_female_adult, income = do_hh_sums( hh )
        hrp = get_head( hh )
        addtodf( 
            frsset, 
            "age",
            WAS_TARGET_VARS["age"], 
            hno, 
            was_model_age_grp( hrp.age ))
        addtodf( 
            frsset,
            "region", 
            WAS_TARGET_VARS["region"], 
            hno, 
            model_regionmap( hh.region ))
        addtodf( 
            frsset,
            "accom", 
            WAS_TARGET_VARS["accom"], 
            hno, 
            model_accommap( hh.dwelling ))
        addtodf( 
            frsset, 
            "tenure",
            WAS_TARGET_VARS["tenure"], 
            hno,  
            model_tenuremap( hh.tenure ))
        addtodf( 
            frsset, 
            "socio",
            WAS_TARGET_VARS["socio"], 
            hno, 
            model_map_socio( hrp.socio_economic_grouping ))
        addtodf( 
            frsset, 
            "empstat",
            WAS_TARGET_VARS["empstat"], 
            hno, 
            model_map_empstat( hrp.employment_status ))
        addtodf( 
            frsset, 
            "sex",
            WAS_TARGET_VARS["sex"], 
            hno, 
            [Int(hrp.sex)] )
        addtodf( 
            frsset, 
            "marital",
            WAS_TARGET_VARS["marital"], 
            hno, 
            model_map_marital(hrp.marital_status ) )
        addtodf( 
            frsset, 
            "year",
            WAS_TARGET_VARS["year"], 
            hno, 
            [hh.interview_year] )
        addtodf( 
            frsset, 
            "wages",
            WAS_TARGET_VARS["wages"], 
            hno, 
            [any_wages] )
        addtodf( 
            frsset, 
            "selfemp",
            WAS_TARGET_VARS["selfemp"], 
            hno, 
            [any_selfemp] )
        addtodf( 
            frsset, 
            "pensions",
            WAS_TARGET_VARS["pensions"], 
            hno, 
            [any_pension_income] )
        addtodf( 
            frsset, 
            "degree",
            WAS_TARGET_VARS["degree"], 
            hno, 
            [highqual_degree_equiv(hrp.highest_qualification)] )
        addtodf( 
            frsset, 
            "children",
            WAS_TARGET_VARS["children"], 
            hno, 
            person_map( num_children(hh), 9999))
        addtodf( 
            frsset, 
            "adults",
            WAS_TARGET_VARS["adults"], 
            hno, 
            person_map( num_adults( hh ), 9999))
                                
        end
    return frsset,wasset
end # create_was_frs_matching_dataset

function checkall( filename = "was_matchchecks.md" )
    settings = Settings()
    frsset, wasset = create_was_frs_matching_dataset( settings )
    outf = open( joinpath( "tmp", filename), "w")
    for (k,i) in WAS_TARGET_VARS
        tabs = compareone( frsset, wasset, k, i )
        println( outf, "## $k")
        for t in tabs
            println( outf, t )
            println( outf )
        end
    end
    close( outf )
end

"""
Map the entire datasets.
"""
function map_all_was( 
    settings :: Settings, 
    donor :: DataFrame, 
    matcher :: Function ) :: DataFrame
    p = 0
    settings.num_households, 
    settings.num_people = 
        FRSHouseholdGetter.initialise( settings; reset=false )

    df = makeoutdf( settings.num_households, "was" )
    for hno in 1:settings.num_households
        hh = FRSHouseholdGetter.get_household( hno )
        println( "on hh $hno")
        df[ hno, :frs_sernum] = hh.hid
        df[ hno, :frs_datayear] = hh.data_year
        df[ hno, :frs_income] = hh.original_gross_income
        matches = match_recip_row( hh, donor, matcher, :weekly_gross_income ) 
        for i in 1:NUM_SAMPLES
            was_case_sym = Symbol( "was_case_$i")
            was_datayear_sym = Symbol( "was_datayear_$i")
            was_score_sym = Symbol( "was_score_$i")
            was_income_sym = Symbol( "was_income_$i")
            df[ hno, was_case_sym] = matches[i].case
            df[ hno, was_datayear_sym] = matches[i].datayear
            df[ hno, was_score_sym] = matches[i].score
            df[ hno, was_income_sym] = matches[i].income    
        end
        if p > 10000000
            break
        end
    end
    return df
end

function create_frs_was_matches( data_source :: DataSource = FRSSource )
    settings = Settings()
    settings.data_source = data_source
    was_dataset = CSV.File(joinpath(data_dir( settings ),settings.wealth_dataset)*".tab")|>DataFrame    
    map_all_was( settings, was_dataset, model_was_match )
end

end # module

