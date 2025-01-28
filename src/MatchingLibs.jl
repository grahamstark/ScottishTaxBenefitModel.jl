module MatchingLibs

#
# A script to match records from 2019/19 to 2020/21 lcf to 2020 FRS
# strategy is to match to a bunch of characteristics, take the top 20 of those, and then
# match between those 20 on household income. 
# TODO
# - make this into a module and a bit more general-purpose;
# - write up, so why not just Engel curves?
#

#=
example import
julia> import ScottishTaxBenefitModel.MatchingLibs.LCF as lcf

julia> import ScottishTaxBenefitModel.MatchingLibs.Common as com

julia> import ScottishTaxBenefitModel.MatchingLibs.Model as mm

julia> import ScottishTaxBenefitModel.MatchingLibs.WAS as was
=#



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

export map_example, 
    load, 
    map_all_lcf_frs, 
    frs_lcf_match_row


s = instances( Socio_Economic_Group )

include( "matching/Common.jl")
import .Common 
import .Common: MatchingLocation
include( "matching/Model.jl")
import .Model 
include( "matching/LCF.jl")
import .LCF
include( "matching/WAS.jl")
import .WAS
include( "matching/SHS.jl")
import .SHS

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
We're JUST going to use the model dataset here
"""
function model_row_was_match( 
    hh :: Household, 
    was :: DataFrameRow ) :: Tuple
    t = 0.0
    incdiff = 0.0
    hrp = get_head( hh )
    t += score( Model.map_age_hrp( hrp.age ), 
        WAS.map_age_hrp(was.age_head, 9997 )) # ok
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


function match_row_lcf_model( hh :: Household, lcf :: DataFrameRow ) :: Tuple
    hrp = get_head( hh )
    t = 0.0
    t += score( tenuremap( lcf.a121 ), Model.tenuremap( hh.tenure ))
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