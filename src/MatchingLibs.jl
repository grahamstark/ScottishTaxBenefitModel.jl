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
    # FIXME cross dependency .ExampleHouseholdGetter,
    .Uprating,
    .RunSettings

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



islessscore( l1::MatchingLocation, l2::MatchingLocation ) = l1.score < l2.score
islessincdiff( l1::MatchingLocation, l2::MatchingLocation ) = l1.incdiff < l2.incdiff

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
        similar[i] = MatchingLocation( lr.case, lr.datayear, score, lr[incomesym], incdiff )
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

function map_example( example :: Household, donor :: DataFrame, matcher::Function )::MatchingLocation
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



function map_empstat( ie :: Int, default=9998 ):: Vector{Int}
    out = fill( default, 3 )
    out[1] = ie
    out[2] = ie in 1:2 ? 1 : 2
    return out
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

