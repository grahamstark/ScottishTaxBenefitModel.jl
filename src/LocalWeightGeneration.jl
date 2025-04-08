module LocalWeightGeneration
#
# This module bundles together code for generating local level
# weights and adjusting incomes.
# 

using ScottishTaxBenefitModel
using .ModelHousehold
using .Definitions
using .FRSHouseholdGetter
using .RunSettings
using .Weighting
using SurveyDataWeighting
using CSV
using StatsBase
using PrettyTables
using DataFrames
using LinearAlgebra

include( joinpath(SRC_DIR,"targets","scotland-localities-2024.jl") )

export weight_to_la, INCLUDE_ALL, create_model_dataset, create_la_weights
    
const INCLUDE_OCCUP = 1
const INCLUDE_HOUSING = 2
const INCLUDE_BEDROOMS = 3
const INCLUDE_CT = 4
const INCLUDE_HCOMP = 5
const INCLUDE_EMPLOYMENT = 6
const INCLUDE_INDUSTRY = 7
const INCLUDE_HH_SIZE = 8
const INCLUDE_BROAD_CT = 9

const INCLUDE_ALL = Set{Integer}(
    [INCLUDE_OCCUP,
    INCLUDE_HOUSING,
    INCLUDE_BEDROOMS,
    INCLUDE_CT,
    INCLUDE_HCOMP,
    INCLUDE_EMPLOYMENT,
    INCLUDE_INDUSTRY,
    INCLUDE_HH_SIZE] )

function summarise_dfs( data :: DataFrame, targets::DataFrameRow, initial_weights::Vector )::DataFrame
    nrows, ncols = size( data )
    @show nrows ncols
    d = DataFrame()
    nms = names(data)
    for n in nms
        d[:,n] = zeros(12)
        # @show data[!,n]
        v = summarystats(data[!,n])
        d[1,n] = v.max
        d[2,n] = v.mean
        d[3,n] = v.median
        d[4,n] = v.nmiss
        d[5,n] = v.min
        d[6,n] = v.nobs
        d[7,n] = v.q25
        d[8,n] = v.q75
        d[9,n] = v.sd
        it = sum(data[!,n])*initial_weights[1]
        d[10,n] = targets[n]
        d[11,n] = it
        d[12,n] = (targets[n] - it )/ targets[n]
    end
    # sort numeric fields by abs proportional difference
    poss = sortperm(abs.(Vector(d[12,:])),rev=true)
    @show poss
    d = d[!,poss]
    insertcols!(d, 1, :names => ["Max","Mean","Median","N.Miss","Min","Nobs","Q25","Q75","SD","CENSUS TOTAL","FRS Crude","(c-f)/c"])
    return  d
end
        
function weight_to_la( 
    settings :: Settings,
    model_data :: DataFrame, 
    household_total :: Real,
    all_council_data :: DataFrameRow,
    included_categories :: Set{Integer} )
    nhhlds = size(model_data)[1]
    targets, tnames, full_targets = make_target_list_2024( 
        all_council_data, included_categories ) 
    data = select(model_data, tnames)
    initial_weights = ones(nhhlds)*household_total/nhhlds
    # @show initial_weights[1:20] household_total nhhlds
    pt = summarise_dfs( data, targets, initial_weights )
    pretty_table(pt)
    @show near_collinear_cols( data; tol=1e-9 )
    mdata = Matrix(data)
    vtargets = Vector(targets)
    weights = do_reweighting(
         data               = mdata,
         initial_weights    = initial_weights,
         target_populations = vtargets,
         functiontype       = settings.weight_type,
         lower_multiple     = settings.lower_multiple,
         upper_multiple     = settings.upper_multiple,
         tol                = 0.000001 )
    weighted_popn = (weights'*mdata)'
    println( "weighted_popn = $weighted_popn" )
    @assert weighted_popn ≈ vtargets       
    if settings.weight_type in [constrained_chi_square, d_and_s_constrained ]
    # check the constrainted methods keep things inside ll and ul
        for r in 1:nhhlds
            @assert weights[r] <= initial_weights[r]*settings.upper_multiple
            @assert weights[r] >= initial_weights[r]*settings.lower_multiple
        end
    end
    overallsums = (weights'*Matrix(model_data))' # so, including things ommitted for colinearity - should add more or less back up 
    overall_compare = DataFrame( names = names(model_data), weighted_populations=overallsums, target_populations = collect(values(full_targets)))
    overall_compare.difference = overall_compare.weighted_populations - overall_compare.target_populations
    return weights, tnames, overall_compare
end

function create_model_dataset( 
    settings :: Settings, 
    initialise_target_dataframe :: Function,
    make_target_row! :: Function ) :: DataFrame
    df :: DataFrame = initialise_target_dataframe( settings.num_households )
    for hno in 1:settings.num_households
        hh = FRSHouseholdGetter.get_household( hno )
        make_target_row!( df[hno,:], hh )
    end
     # println(m)
    nr,nc = size(df)
    nm = names(df)
    i = 0
    for col in eachcol(df)
        i += 1
        # col = df[!,c]
        if eltype(col) <: Number
            @assert sum(col) != 0 "all zero column $(nm[i])"
        end
    end
    # no row all zero
    for r in 1:nr
        row = df[r,:]
        s = 0.0
        for c in row
            if typeof(c) <: Number
                s += c
            end
        end
        @assert s != 0 "all zero row $r"
    end
    return df
end

#=

using Revise
using ScottishTaxBenefitModel
using .ModelHousehold
using .Definitions
using .FRSHouseholdGetter
using .RunSettings
using .Weighting
using .LocalWeightGeneration
using SurveyDataWeighting
using CSV
using StatsBase
using PrettyTables
using DataFrames

merged_census_files = load_census_2024()
settings = Settings()

settings.num_households, settings.num_people = FRSHouseholdGetter.initialise( settings )
df = create_model_dataset( 
    settings,
    initialise_model_dataframe_scotland_la, 
    make_model_dataframe_row! )

targets = merged_census_files[merged_census_files.authority_code.==:S12000050,:][1,:] 
# :S12000049 S1200001 3S12000027 North Lanarkshire S12000050
=#

# FIXME replace hcomp & hh_size with a single fancier hh composition variable
const INCLUDES_URBAN = Set{Integer}([
    INCLUDE_OCCUP,
    INCLUDE_HOUSING,
    INCLUDE_BEDROOMS,
    INCLUDE_CT,
    # INCLUDE_HCOMP,
    INCLUDE_EMPLOYMENT,
    INCLUDE_INDUSTRY,
    INCLUDE_HH_SIZE,
    ])

const INCLUDES_RURAL = Set{Integer}([
    INCLUDE_OCCUP,
    INCLUDE_HOUSING,
    INCLUDE_BEDROOMS,
    INCLUDE_CT,
    # INCLUDE_BROAD_CT,
    # INCLUDE_HCOMP,
    INCLUDE_EMPLOYMENT,
    INCLUDE_INDUSTRY,
    INCLUDE_HH_SIZE,
    ])

const INCLUDES_SEMI_URBAN = Set{Integer}([
    INCLUDE_OCCUP,
    INCLUDE_HOUSING,
    INCLUDE_BEDROOMS,
    INCLUDE_CT,
    # INCLUDE_BROAD_CT,
    # INCLUDE_HCOMP,
    INCLUDE_EMPLOYMENT,
    INCLUDE_INDUSTRY,
    INCLUDE_HH_SIZE,
    ])

const URBAN = Set([ :S12000036, :S12000042,  :S12000049 ])
const SEMI_URBAN = Set([:S12000033, :S12000034, :S12000041, :S12000005,:S12000006,:S12000008,
    :S12000045, :S12000010, :S12000011, :S12000047, :S12000018, :S12000019,
    :S12000021, :S12000050, :S12000048, :S12000038, :S12000026, :S12000028,
    :S12000029, :S12000030, :S12000039, :S12000040, :S12000014])
const RURAL = Set([:S12000035, :S12000017, :S12000020, :S12000013, 
    :S12000023, :S12000027])

function create_la_weights( settings :: Settings )
    merged_census_files = load_census_2024()
    
    settings.num_households, settings.num_people = initialise( settings )
    outweights = DataFrame()
    outweights.data_year = zeros(Int, settings.num_households)
    outweights.hid = zeros(BigInt, settings.num_households)
    outweights.uhid = zeros(BigInt, settings.num_households)
    for href in 1:settings.num_households
        mhh = get_household( href )
        outweights.uhid[href] = mhh.uhid
        outweights.hid[href] = mhh.hid
        outweights.data_year[href] = mhh.data_year
    end
    df = create_model_dataset( 
        settings,
        initialise_model_dataframe_scotland_la, 
        make_model_dataframe_row! )
    
    for row in eachrow( merged_census_files[1:end-1,:] )
        targets = merged_census_files[merged_census_files.authority_code.==row.authority_code,:][1,:] 
        println( "targets.Authority=$(targets.Authority)")
        incls = INCLUDES_RURAL
        if row.authority_code in RURAL
            settings.lower_multiple = 0.0
            settings.upper_multiple = 20.0
            incls = INCLUDES_RURAL 
        elseif row.authority_code in SEMI_URBAN 
            settings.lower_multiple = 0.00
            settings.upper_multiple = 10.0
            incls = INCLUDES_SEMI_URBAN
        elseif row.authority_code in URBAN 
            settings.lower_multiple = 0.0
            settings.upper_multiple = 7.0
            incls = INCLUDES_URBAN
        else
            @assert false "missing $(row.authority_code)"
        end
        wts, targetnames, comparisons = weight_to_la( 
            settings,
            df, 
            targets.total_hhlds,
            targets,
            incls )        
        outweights[!,row.authority_code] = wts
    end # la loop
    return outweights 
end # create_la_weights

end # module