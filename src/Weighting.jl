module Weighting
#
# This module has routines and target constants to re-weight our main dataset so it hits current or future totals for employment, 
# population by age and so on. See:
#
# Creedy, John. 2003. ‘Survey Reweighting for Tax Microsimulation Modelling’. Treasury Working Paper Series 03/17. 
# New Zealand Treasury. http://ideas.repec.org/p/nzt/nztwps/03-17.html.
# 
# for an overview of how this works, and the `SurveyDataWeighting` module for implementation details.
#
# The targets we currently weight for are:
#
# * Employment and Unemployment (from NOMIS)
# * Tenure Type (from Scotgov)
# * Household Type (from NRS)
# * Receipts of disability/caring benefits (Stat-Explore)
# * population in 5- year age bands
# * household totals by local authority.
#
# 82 targets in all, presently.
#
using DataFrames

using SurveyDataWeighting: 
    DistanceFunctionType, 
    chi_square,
    constrained_chi_square,
    d_and_s_constrained,
    d_and_s_type_a,
    d_and_s_type_b,
    do_reweighting

using ScottishTaxBenefitModel
using .Definitions
using .ModelHousehold
using .RunSettings
using .Utils


export 
    DEFAULT_TARGETS, 
    generate_weights, 
    initialise_target_dataframe,
    make_target_dataset
#
# all possible datasets - we could just comment out ones we're not using 
#
include(joinpath(SRC_DIR,"targets","scotland-2022.jl"))
include(joinpath(SRC_DIR,"targets","scotland-2025.jl"))
include(joinpath(SRC_DIR,"targets","scotland-2026.jl"))
include(joinpath(SRC_DIR,"targets","wales-2023.jl"))
include(joinpath(SRC_DIR,"targets","wales-longterm.jl"))

#
# See `weighting_target_set_creation.md`
# and `data/targets/aug-2022-updates/aug-22target_generation_worksheet.ods`
# and the blog notes.
# 
# 2_477_000.0 # sum of all hhld types below

function make_target_dataset( nhhlds :: Integer, 
    initialise_target_dataframe :: Function,
    make_target_row! :: Function ) :: Matrix
    df :: DataFrame = initialise_target_dataframe( nhhlds )
    for hno in 1:nhhlds
        hh = FRSHouseholdGetter.get_household( hno )
        make_target_row!( df[hno,:], hh )
    end
    m = Matrix{Float64}(df) 

    # consistency
    nr,nc = size(m)
    # no column is all zero - since only +ive cells possible this is the easiest way
    for c in 1:nc 
        @assert sum(m[:,c]) != 0 "all zero column $c"
    end
    # no row all zero
    for r in 1:nr
        @assert sum(m[r,:] ) != 0 "all zero row $r"
    end
    return m
end

"""
TODO add wales stuff here. maybe a year override?
"""
function get_targets( settings :: Settings )::NamedTuple
    if settings.weighting_target_year == 2026
        # we have hh and all people versions of 2025 targets, so ..
        targets = if settings.include_institutional_population
            DEFAULT_TARGETS_SCOTLAND_2026_INC_INSTITUTIONAL
        else
            DEFAULT_TARGETS_SCOTLAND_2026_HHLD_ONLY
        end
        return (;
            household_total = sum( targets[42:47]), 
            targets = targets,
            initialise_target_dataframe = initialise_target_dataframe_scotland_2026,
            make_target_row! = make_target_row_scotland_2026! )
    elseif settings.weighting_target_year == 2025
        # we have hh and all people versions of 2025 targets, so ..
        targets = if settings.include_institutional_population
            DEFAULT_TARGETS_SCOTLAND_2025_INC_INSTITUTIONAL
        else
            DEFAULT_TARGETS_SCOTLAND_2025_HHLD_ONLY
        end
        return (;
            household_total =sum( targets[42:47]), 
            targets = targets,
            initialise_target_dataframe = initialise_target_dataframe_scotland_2025,
            make_target_row! = make_target_row_scotland_2025! )
    elseif settings.weighting_target_year in 2023:2024
        return (;
            household_total = NUM_HOUSEHOLDS_SCOTLAND_2024,
            targets = DEFAULT_TARGETS_SCOTLAND_2024, # no institutional 
            initialise_target_dataframe = initialise_target_dataframe_scotland_2022, # 2022 maker is unchanged
            make_target_row! = make_target_row_scotland_2022! )
    elseif settings.weighting_target_year in 2022
        return (;
            household_total = NUM_HOUSEHOLDS_SCOTLAND_2022,
            targets = DEFAULT_TARGETS_SCOTLAND_2022, # no institutional 
            initialise_target_dataframe = initialise_target_dataframe_scotland_2022,
            make_target_row! = make_target_row_scotland_2022! )
    end
    # die
end 

#
# generate weights for the dataset and
#
#
function generate_weights(
    nhhlds :: Integer;
    initial_weights  = nothing,
    weight_type :: DistanceFunctionType = constrained_chi_square,
    lower_multiple :: Real = 0.20, # these values can be narrowed somewhat, to around 0.25-4.7
    upper_multiple :: Real = 5,
    household_total :: Real = NUM_HOUSEHOLDS_SCOTLAND_2025,
    targets :: Vector = DEFAULT_TARGETS_SCOTLAND_2025,
    initialise_target_dataframe :: Function = initialise_target_dataframe_scotland_2025,
    make_target_row! :: Function = make_target_row_scotland_2025! ) :: Tuple

    function check_data( d, nrows, ncols )
        zrows = Int[]
        for r in 1:nrows
            if sum( d[r,:] ) == 0
                push!(zrows,r)
            end
        end
        zcols = Int[]
        @assert length(zrows) == 0 "data has all-zero rows for rows $(zrows)"
        for c in 1:ncols
            if sum( d[:,c] ) == 0
                push!(zcols,c)
            end
        end
        @assert length(zcols) == 0 "data has all-zero cols $(zcols)"
    end

    data :: Matrix = make_target_dataset( 
        nhhlds, 
        initialise_target_dataframe, 
        make_target_row! )
    # println( data )
    nrows, ncols = size( data )
    check_data( data, nrows, ncols )
    # default initial weights as all equal 
    if isnothing( initial_weights ) 
        initial_weights = ones(nhhlds)*household_total/nhhlds
    end
    println( "initial_weights $(initial_weights[1])")
    # any smaller min and d_and_s_constrained fails on this dataset
    @assert size(data)[2] == length(targets) "mismatch sizes data=$(size(data)[2]) targets=$(length(targets))"
    weights = do_reweighting(
         data               = data,
         initial_weights    = initial_weights,
         target_populations = targets,
         functiontype       = weight_type,
         lower_multiple     = lower_multiple,
         upper_multiple     = upper_multiple,
         tol                = 0.000001 )
    weighted_popn = (weights' * data)'
    println( "weighted_popn = $weighted_popn" )
    @assert weighted_popn ≈ targets

    if weight_type in [constrained_chi_square, d_and_s_constrained ]
      # check the constrainted methods keep things inside ll and ul
        for r in 1:nrows
            @assert weights[r] <= initial_weights[r]*upper_multiple
            @assert weights[r] >= initial_weights[r]*lower_multiple
        end
    end
    for hno in 1:nhhlds
        hh = FRSHouseholdGetter.get_household( hno )
        hh.weight = weights[hno]
    end
    return weights, data
end

function generate_weights( settings::Settings )
    household_total,
    targets, # no institutional,
    initialise_target_dataframe,
    make_target_row! = get_targets( settings )
    initial_weights = if settings.weighting_relative_to_ons_weights
        weights = zeros( settings.num_households )
        for hno in 1:settings.num_households
            hh = FRSHouseholdGetter.get_household( hno )
            weights[hno] = hh.default_weight
        end
        popsum = sum( weights )
        wscale = household_total/popsum
        weights .* wscale
    else # uniform unitial weights
        ones(settings.num_households)*household_total/settings.num_households
    end 
    @time weights, data = generate_weights( 
        settings.num_households;
        initial_weights = initial_weights,
        weight_type = settings.weight_type,
        lower_multiple = settings.lower_multiple,
        upper_multiple = settings.upper_multiple,
        household_total = household_total,
        targets = targets, # no institutional,
        initialise_target_dataframe = initialise_target_dataframe,
        make_target_row! = make_target_row! )
    return weights, data
end

end # package