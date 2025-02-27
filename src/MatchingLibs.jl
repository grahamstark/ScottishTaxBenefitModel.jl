module MatchingLibs

#
# A script to match records from 2019/19 to 2020/21 lcf to 2020 FRS
# strategy is to match to a bunch of characteristics, take the top 20 of those, and then
# match between those 20 on household income. 
# TODO
# - make this into a module and a bit more general-purpose;
# - write up, so why not just Engel curves?
#

using CSV,
    DataFrames,
    Measures,
    StatsBase,
    ArgCheck,
    PrettyTables

using ScottishTaxBenefitModel
using .Definitions,
    .ModelHousehold,
    .FRSHouseholdGetter,
    .Uprating,
    .RunSettings

export map_example, 
    load, 
    map_all_lcf_frs, 
    frs_lcf_match_row


include( "matching/Common.jl")
import .Common as common
include( "matching/Model.jl")
import .Model as model
include( "matching/LCF.jl")
import .LCF as lcf
include( "matching/WAS.jl")
import .WAS as was
include( "matching/SHS.jl")
import .SHS as shs

const NUM_SAMPLES = 20

struct MatchingLocation{T<: AbstractFloat}
    case :: Int
    datayear :: Int
    score :: T
    income :: T
    incdiff :: T
end

islessscore( l1::MatchingLocation, l2::MatchingLocation ) = l1.score < l2.score
islessincdiff( l1::MatchingLocation, l2::MatchingLocation ) = l1.incdiff < l2.incdiff

const TOPCODE = 2420.03

function within(x;min=min,max=max) 
    return if x < min min elseif x > max max else x end
end

"""
Match one row in the FRS (recip) with all possible lcf matches (donor). Intended to be general
but isn't really any more. FIXME: pass in a saving function so we're not tied to case/datayear.
"""
function match_recip_row( recip, donor :: DataFrame, matcher :: Function, incomesym=:income ) :: Vector{MatchingLocation}
    drows, dcols = size(donor)
    i = 0
    similar = Vector{MatchingLocation}( undef, drows )
    for lr in eachrow(donor)
        i += 1
        score, incdiff = matcher( recip, lr )
        similar[i] = MatchingLocation{Float64}( lr.case, lr.datayear, score, lr[incomesym], incdiff )
    end
    # sort by characteristics   
    similar = sort( similar; lt=islessscore, rev=true )[1:NUM_SAMPLES]
    # .. then the nearest income amongst those
    similar = sort( similar; lt=islessincdiff, rev=true )[1:NUM_SAMPLES]
    return similar
end


"""
Absolute difference in income, scaled by max difference (TOPCODE,since the possible range is zero to the top-coding)
"""
function compare_income( hhinc :: Real, p344p :: Real, topcode=TOPCODE ) :: Real
    # top & bottom code hhinc to match the lcf p344
    # hhinc = max( 0, hhinc )
    # hhinc = min( TOPCODE, hhinc ) 
    1-abs( hhinc - p344p )/topcode # topcode is also the range 
end


"""
Create a dataframe for storing all the matches. 
This has the FRS record and then 20 lcf records, with case,year,income and matching score for each.
"""
function makeoutdf( n :: Int, prefix :: AbstractString ) :: DataFrame
    d = DataFrame(
    frs_sernum = zeros(Int, n),
    frs_datayear = zeros(Int, n),
    frs_income = zeros(n))
    for i in 1:NUM_SAMPLES
        case_sym = Symbol( "$(prefix)_case_$i")
        datayear_sym = Symbol( "$(prefix)_datayear_$i")
        score_sym = Symbol( "$(prefix)_score_$i")
        income_sym = Symbol( "$(prefix)_income_$i")
        d[!,case_sym] .= 0
        d[!,datayear_sym] .= 0
        d[!,score_sym] .= 0.0
        d[!,income_sym] .= 0.0
    end
    return d
end

"""
Score for one of our 3-level matches 1 for exact 0.5 for partial 1, 0.1 for partial 2
"""
function score( a3 :: Vector{Int}, b3 :: Vector{Int})::Float64
    @argcheck length(a3) == length(b3)
    l = length(a3)
    return if a3[1] == b3[1]
        1.0
    elseif (l >= 2) && (a3[2] == b3[2])
        0.5
   + elseif (l >= 3) && (a3[3] == b3[3])
        0.1
    else
        0.0
    end
end

"""
Score for comparison between 2 ints: 1 for exact, 0.5 for within 2 steps, 0.1 for within 5. FIXME look at this again.
"""
function score( a :: Int, b :: Int ) :: Float64
    return if a == b
        1.0
    elseif abs( a - b ) < 2
        0.5
    elseif abs( a - b ) < 5
        0.1
    else
        0.0
    end
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

function map_example( example :: Household, donor :: DataFrame, matcher::Function )::MatchingLocation
    matches = map_recip_row( example, donor, matcher )
    return matches[1]
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
    region :: Standard_Region, weights = [2.0,1.0,0.5,0.2,0.1])::Float64
    return if region == Scotland
        weights[1]
        elseif region in [
            North_East,
            North_West,
            Yorks_and_the_Humber,
            Wales,
            Northern_Ireland] # neast, nwest, yorks
            weights[2]
        elseif region in [ 
            East_of_England,
            East_Midlands,
            West_Midlands] # e/w midlands, wales
            weights[3]
        elseif region in [
            South_East,
            South_West]
            weights[4]
        elseif region in [London] # London
            weights[5]
        else
            @assert false "unmapped region $region"
        end 
end

"""
Match one row in the FRS (recip) with all possible lcf matches (donor). Intended to be general
but isn't really any more. FIXME: pass in a saving function so we're not tied to case/datayear.
"""
#=
function match_recip_row( recip, donor :: DataFrame, matcher :: Function ) :: Vector{MatchingLocation}
    drows, dcols = size(donor)
    i = 0
    similar = Vector{MatchingLocation}( undef, drows )
    for lr in eachrow(donor)
        i += 1
        score, incdiff = matcher( recip, lr )
        similar[i] = MatchingLocation( lr.case, lr.datayear, score, lr.income, incdiff )
    end
    # sort by characteristics   
    similar = sort( similar; lt=islessscore, rev=true )[1:NUM_SAMPLES]
    # .. then the nearest income amongst those
    similar = sort( similar; lt=islessincdiff, rev=true )[1:NUM_SAMPLES]
    return similar
end

=#


#=
function model_row_was_match( 
    hh :: Household, 
    was :: DataFrameRow ) :: Tuple
    t = 0.0
    incdiff = 0.0
    hrp = get_head( hh )
    t += score( Model.map_age_hrp( hrp.age ), 
        WAS.map_age_hrp(was.age_head )) # ok
    t += region_score_scotland( 
        Model.map_region( hh.region ), 
        WAS.map_region( was.region, 9997 ),
        [1.5,0.8,0.3,0.2,0.1]) 
    t += score( Model.map_accom( hh.dwelling ), WAS.map_accom( was.accom, 9997 ))
    
    t += score( Model.map_tenure( hh.tenure ),  WAS.map_tenure( was.tenure, 9997 ))

    t += score( model_map_socio( hrp.socio_economic_grouping ),  
        map_socio( was.socio_economic_head, 9997 ))
    t += score( model_map_empstat( hrp.employment_status ), map_empstat( was.empstat_head, 9997 ))
    t += Int(hrp.sex) == was.sex_head ? 1 : 0
    t += score( model_map_marital(hrp.marital_status ), map_marital( was.marital_status_head, 9997 ))
    # t += score( hh.data_year, was.year )
    any_wages, any_selfemp, any_pension_income, has_female_adult, income = do_hh_sums( hh )

    #     hh_composition 
    t += any_wages == was.any_wages ? 1 : 0
    t += any_selfemp ==  was.any_selfemp ? 1 : 0
    t += any_pension_income == was.any_pension_income ? 1 : 0
     
    t += highqual_degree_equiv(hrp.highest_qualification) == was.has_degree ? 1 : 0

    t += score( person_map(num_children( hh ),9999), person_map(was.num_children,9997 ))
    t += score( person_map(num_adults( hh ),9999), person_map(was.num_adults,9997))
    incdiff = compare_income( income, was.weekly_gross_income )
    return t, incdiff
end
=#

function model_row_shs_match(
    hh :: Household, wass :: DataFrameRow ) :: Tuple
    head = get_head(hh)
    t = 0.0

    return t, incdiff
end

function model_row_was_match( 
    hh :: Household, wass :: DataFrameRow ) :: Tuple
    head = get_head(hh)
    t = 0.0
    cts = mm.counts_for_match( hh )   
    t += score( was.map_tenure(wass.tenure), mm.map_tenure( hh.tenure ))
    t += score( was.map_accom(wass.accom), was.model_to_was_map_accom(hh.dwelling)) 
    # bedrooms to common
    t += score( common.map_bedrooms(wass.bedrooms), common.map_bedrooms( hh.bedrooms ))
    t += score( was.map_household_composition(wass.household_type), 
                was.model_was_map_household_composition( household_composition_1(hh)))
    t += score( wass.any_wages, cts.any_wages )
    t += score( wass.any_pension_income, cts.any_pension_income )  
    t += score( wass.any_selfemp, cts.any_selfemp )
    t += score( common.map_total_people( wass.num_adults ), common.map_total_people(cts.num_adults ))
    t += score( common.map_total_people(wass.num_children ), common.map_total_people(cts.num_children )) 
    t += score( was.map_age_bands(wass.age_head), was.model_was_map_age_bands( head.age ))
    t += score( was.map_marital(wass.marital_status_head), mm.map_marital( head.marital_status))
    t += score( was.map_socio(wass.socio_economic_head), was.model_was_map_socio( head.socio_economic_grouping) )
    t += score( was.map_empstat(wass.empstat_head), was.model_was_map_empstat( head.employment_status))
    t += region_score_scotland( Standard_Region(wass.region))
    incdiff = compare_income( lcf.income, income )
    return t, incdiff 
end

function match_row_lcf_model( hh :: Household, lcf :: DataFrameRow ) :: Tuple
    hrp = get_head( hh )
    t = 0.0
    t += score( map_tenure( lcf.a121 ), Model.map_tenure( hh.tenure ))
    t += score( regionmap( lcf.gorx ), Model.regionmap( hh.region ))
    # !!! both next missing in 2020 LCF FUCKKK 
    # t += score( accmap( lcf.a116 ), frs_accmap( frs.typeacc ))
    # t += score( rooms( lcf.a111p, 998 ), rooms( frs.bedroom6, 999 ))
    t += score( age_hrp(  lcf.a065p ), age_hrp( Model.age_grp( hrp.age )))
    t += score( composition_map( lcf.a062 ), Model.composition_map( hh ))
    any_wages, any_selfemp, any_pension_income, has_female_adult, income = Model.do_hh_sums( hh )
    t += lcf.any_wages == any_wages ? 1 : 0
    t += lcf.any_pension_income == any_pension_income ? 1 : 0
    t += lcf.any_selfemp == any_selfemp ? 1 : 0
    t += lcf.hrp_unemployed == hrp.employment_status == Unemployed ? 1 : 0
    # !!!!! FUCK ethnic deleted from 2022 lcf public release.
    # t += lcf.hrp_non_white == hrp.ethnic_group !== White ? 1 : 0
    # t += lcf.datayear == frs.datayear ? 0.5 : 0 # - a little on same year FIXME use date range
    # t += lcf.any_disabled == frs.any_disabled ? 1 : 0 -- not possible in LCF??
    t += Int(lcf.has_female_adult) == Int(has_female_adult) ? 1 : 0
    t += score( lcf.num_children, num_children( hh) )
    t += score( lcf.num_people, num_people(hh) )
    # fixme should we include this at all?
    incdiff = compare_income( lcf.income, income )
    t += 10.0*incdiff
    return t,incdiff
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