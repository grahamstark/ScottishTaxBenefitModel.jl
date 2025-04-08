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


include( "matching/Common.jl")
import .Common as common
import .Common: MatchingLocation
include( "matching/Model.jl")
import .Model as model
include( "matching/LCF.jl")
import .LCF as lcf
include( "matching/WAS.jl")
import .WAS as was
include( "matching/SHS.jl")
import .SHS as shs

const NUM_SAMPLES = 20

function within(x;min=min,max=max) 
    return if x < min min elseif x > max max else x end
end

"""
Create a dataframe for storing all the matches. 
This has the FRS record and then 20 lcf records, with case,year,income and matching score for each.
"""
function makeoutdf( n :: Int ) :: DataFrame
    d = DataFrame(
    frs_sernum = zeros(Int, n),
    frs_datayear = zeros(Int, n),
    frs_income = zeros(n))
    for i in 1:NUM_SAMPLES
        case_sym = Symbol( "hhid_$i")
        datayear_sym = Symbol( "datayear_$i")
        score_sym = Symbol( "score_$i")
        income_sym = Symbol( "income_$i")
        d[!,case_sym] .= 0
        d[!,datayear_sym] .= 0
        d[!,score_sym] .= 0.0
        d[!,income_sym] .= 0.0
    end
    return d
end

function map_example( example :: Household, donor :: DataFrame, matcher::Function )::MatchingLocation
    matches = map_recip_row( example, donor, matcher )
    return matches[1]
end


#=
function model_row_shs_match( hh :: Household, lcf :: DataFrameRow ) :: MatchingLocation
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
=#

"""
return the top NUM_SAMPLES between hh and the donor dataset, with closeness defined by
the `matcher` function and then by income difference
"""
function match_recip_row( hh::Household, donor :: DataFrame, matcher :: Function ) :: Vector{MatchingLocation}
    drows, dcols = size(donor)
    i = 0
    similar = Vector{MatchingLocation}( undef, drows )
    for lr in eachrow(donor)
        i += 1
        similar[i] = matcher( hh, lr )
    end
    # sort by characteristics   
    similar = sort( similar; lt=common.islessscore, rev=true )[1:NUM_SAMPLES]
    # .. then the nearest income amongst those
    similar = sort( similar; lt=common.islessincdiff, rev=true )
    return similar
end

"""
Map the entire datasets.
"""
function map_all( 
    settings :: Settings, 
    donor    :: DataFrame, 
    matcher  :: Function,
    prefix   :: AbstractString;
    num_samples :: Integer ) :: DataFrame
    p = 0
    settings.num_households, 
    settings.num_people = 
        FRSHouseholdGetter.initialise( settings; reset=false )
    df = makeoutdf( settings.num_households )
    for hno in 1:settings.num_households
        hh = FRSHouseholdGetter.get_household( hno )
        println( "on hh $hno")
        df[ hno, :frs_sernum] = hh.hid
        df[ hno, :frs_datayear] = hh.data_year
        df[ hno, :frs_income] = hh.original_gross_income
        matches = match_recip_row( hh, donor, matcher ) 
        for i in 1:num_samples
            case_sym = Symbol( "hhid_$i")
            datayear_sym = Symbol( "datayear_$i")
            score_sym = Symbol( "score_$i")
            income_sym = Symbol( "income_$i")
            df[ hno, case_sym] = matches[i].case
            df[ hno, datayear_sym] = matches[i].datayear
            df[ hno, score_sym] = matches[i].score
            df[ hno, income_sym] = matches[i].income    
        end
    end
    return df
end

const ODIR = "data/matches/"

function everything_off_settings(data_source :: DataSource = FRSSource)::Settings
    settings = Settings()
    settings.data_source = data_source
    settings.num_households, settings.num_people=FRSHouseholdGetter.initialise(settings)
    settings.data_source = data_source
    settings.do_indirect_tax_calculations = false
    settings.wealth_method = no_method
    settings.weighting_strategy = use_supplied_weights
    return settings
end

function create_was_matches( data_source :: DataSource = FRSSource; num_samples=NUM_SAMPLES )
    settings = everything_off_settings(data_source)
    wass = MatchingLibs.was.create_subset()
    matches = map_all( settings, wass, was.model_row_match, "was"; num_samples=num_samples )
    matches.default_datayear = matches.datayear_1
    matches.default_hhld = matches.hhid_1
    CSV.write( "$(ODIR)was-matches.tab", matches; delim='\t')
    CSV.write( "$(ODIR)was-subset.tab", wass; delim='\t')
end

function create_shs_matches( data_source :: DataSource = FRSSource; num_samples=NUM_SAMPLES )
    settings = everything_off_settings(data_source)
    shss = shs.create_subset()
    matches = map_all( settings, shss, shs.model_row_match, "shs"; num_samples=num_samples )
    shs.hack_income_field_to_sample_freqs( matches, shss )
    CSV.write( "$(ODIR)shs-matches.tab", matches; delim='\t')
    CSV.write( "$(ODIR)shs-subset.tab", shss; delim='\t')
end

function create_lcf_matches( data_source :: DataSource = FRSSource; num_samples=NUM_SAMPLES )
    settings = everything_off_settings(data_source)
    lcfs = MatchingLibs.lcf.create_subset()
    matches = map_all( settings, lcfs, lcf.model_row_match, "shs"; num_samples=num_samples )
    matches.default_datayear = matches.datayear_1 # default selection just the 1st one
    matches.default_hhld = matches.hhid_1
    CSV.write( "$(ODIR)lcf-matches.tab", matches; delim='\t')
    CSV.write( "$(ODIR)lcf-subset.tab", lcfs; delim='\t')
end

end # module