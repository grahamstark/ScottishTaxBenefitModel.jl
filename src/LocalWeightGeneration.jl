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

export weight_to_la, INCLUDE_ALL, create_model_dataset
    
const INCLUDE_OCCUP = 1
const INCLUDE_HOUSING = 2
const INCLUDE_BEDROOMS = 3
const INCLUDE_CT = 4
const INCLUDE_HCOMP = 5
const INCLUDE_EMPLOYMENT = 6
const INCLUDE_INDUSTRY = 7
const INCLUDE_HH_SIZE = 8

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
        d[:,n] = zeros(11)
        # @show data[!,n]
        v = summarystats(data[!,n])
        d[1,n] = v.max
        d[3,n] = v.mean
        d[4,n] = v.median
        d[5,n] = v.nmiss
        d[6,n] = v.min
        d[7,n] = v.nobs
        d[8,n] = v.q25
        d[9,n] = v.q75
        d[10,n] = v.sd
        it = sum(data[!,n])*initial_weights[1]
        d[11,n] = (targets[n] - it )/ targets[n]
    end
    poss = sortperm(abs.(Vector(d[11,:])),rev=true)
    @show poss
    return d[!,poss] #, d[11,poss]
end
        
function weight_to_la( 
    settings :: Settings,
    model_data :: DataFrame, 
    household_total :: Real,
    all_council_data :: DataFrameRow,
    included_categories :: Set{Integer} )
    nhhlds = size(model_data)[1]
    targets, tnames = make_target_list_2024( 
        all_council_data, included_categories ) 
    data = select(model_data, tnames)
    initial_weights = ones(nhhlds)*household_total/nhhlds
    @show initial_weights[1:20] household_total nhhlds
    pt = summarise_dfs( data, targets, initial_weights )
    pretty_table(pt)
    # @show diffs
    @show near_collinear_cols( data )
    mdata = Matrix(data)
    vtargets = Vector(targets)
    # println( "calculating for $code; hh total $hhtotal")
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
    summarystats( weights )
    return weights
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

EXCLUDE_CT = Set{Integer}(
    [LocalWeightGeneration.INCLUDE_OCCUP,
    LocalWeightGeneration.INCLUDE_HOUSING,
    LocalWeightGeneration.INCLUDE_BEDROOMS,
    # INCLUDE_CT,
    LocalWeightGeneration.INCLUDE_HCOMP,
    LocalWeightGeneration.INCLUDE_EMPLOYMENT,
    LocalWeightGeneration.INCLUDE_INDUSTRY])
    # LocalWeightGeneration.INCLUDE_HH_SIZE] )

merged_census_files = LocalWeightGeneration.load_census_2024()
settings = Settings()
settings.lower_multiple = 0.01
settings.upper_multiple = 100.0  

settings.num_households, settings.num_people = FRSHouseholdGetter.initialise( settings )
df = LocalWeightGeneration.create_model_dataset( 
    settings,
    LocalWeightGeneration.initialise_model_dataframe_scotland_la, 
    LocalWeightGeneration.make_model_dataframe_row! )

targets = merged_census_files[merged_census_files.authority_code.==:S12000039,:][1,:]
           
weight_to_la( 
    settings,
    df, 
    targets.total_hhlds,
    targets,
    EXCLUDE_CT)

=#

function create_la_weights( 
    settings :: Settings,
    initialise_target_dataframe :: Function,
    make_target_row! :: Function )
    @time settings.num_households, settings.num_people, nhh2 = 
        FRSHouseholdGetter.initialise( settings; reset=false )
    # initial version for checking
    hh_dataframe = create_model_dataset(
        settings.num_households,
        initialise_target_dataframe_scotland_la,
        make_model_dataframe_row! )



    errors = []
    wides = Set([:S12000013] ) # h-Eileanan Siar""Angus", "East Lothian", "East Renfrewshire", "Renfrewshire", "East Dunbartonshire", "North Ayrshire", "West Dunbartonshire", "Shetland Islands", "Orkney Islands", "Inverclyde", "Midlothian", "Argyll and Bute", "East Ayrshire", "Dundee City", "Na h-Eileanan Siar", "South Lanarkshire", "Clackmannanshire", "West Lothian", "Falkirk", "Moray", "South Ayrshire", "City of Edinburgh", "Aberdeenshire", "North Lanarkshire"])
    verywides = Set([:S12000010, :S12000019, :S12000011, :S12000035, :S12000045] ) 
    #"East Lothian", "Midlothian", "East Renfrewshire", "Argyll and Bute", "East Dunbartonshire"])
    s = Set()
    settings.lower_multiple = 0.01
    settings.upper_multiple = 50.0  

    outweights = DataFrame()

    outweights.data_year = zeros(Int,settings.num_households)
    outweights.hid = zeros(BigInt,settings.num_households)
    outweights.uhid = zeros(BigInt,settings.num_households)
    for href in 1:settings.num_households
        mhh = get_household( href )
        outweights.uhid[href] = mhh.uhid
        outweights.hid[href] = mhh.hid
        outweights.data_year[href] = mhh.data_year
    end

    for code in allfs.authority_code
        println( "on $code")

        council_data = all_councils_census[
            all_councils_census.authority_code .== council,:][1,:]
            try
                # FIXME messing with globals for empl, hhsize, which break some authorities
                if code in verywides
                #    INCLUDE_EMPLOYMENT = false
                #    INCLUDE_HH_SIZE = false
                elseif code in wides     
                #    INCLUDE_EMPLOYMENT = true
                #    INCLUDE_HH_SIZE = true
                #    settings.lower_multiple = 0.001
                #    settings.upper_multiple = 100.0            
                else
                #    INCLUDE_HH_SIZE = true
                #    INCLUDE_EMPLOYMENT = true            
                end
                w = weight_to_la( settings, allfs, code, settings.num_households )
                println("OK")
                outweights[!,code] = w
            catch e
                println( "error $e")
                push!( errors, (; e, code ))
                push!(s, code )
            end

        end
    end
    # println( errors )
    # println(s)
end 

# CSV.write( joinpath( DDIR, "la-frs-weights-scotland-2024.tab"), outweights; delim='\t')

# weights = CSV.File( joinpath( DDIR, "la-frs-weights-scotland-2024.tab") ) |> DataFrame 



