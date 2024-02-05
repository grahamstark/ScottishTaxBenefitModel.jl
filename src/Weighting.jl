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
using .ModelHousehold
using .Definitions

export 
    DEFAULT_TARGETS, 
    generate_weights, 
    initialise_target_dataframe,
    make_target_dataset
#
# all possible datasets - we could just comment out ones we're not using 
#
include(joinpath(SRC_DIR,"targets","scotland-2022.jl"))
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

#
# generate weights for the dataset and
#
#
function generate_weights(
    nhhlds :: Integer;
    weight_type :: DistanceFunctionType = constrained_chi_square,
    lower_multiple :: Real = 0.20, # these values can be narrowed somewhat, to around 0.25-4.7
    upper_multiple :: Real = 5,
    household_total :: Real = NUM_HOUSEHOLDS_SCOTLAND_2024,
    targets :: Vector = DEFAULT_TARGETS_SCOTLAND_2024,
    initialise_target_dataframe :: Function = initialise_target_dataframe_scotland_2022,
    make_target_row! :: Function = make_target_row_scotland_2022! ) :: Vector

    data :: Matrix = make_target_dataset( 
        nhhlds, 
        initialise_target_dataframe, 
        make_target_row! )
    nrows = size( data )[1]
    ncols = size( data )[2]
    ## FIXME parameterise this
    initial_weights = ones(nhhlds)*household_total/nhhlds
    println( "initial_weights $(initial_weights[1])")

     # any smaller min and d_and_s_constrained fails on this dataset
    weights = do_reweighting(
         data               = data,
         initial_weights    = initial_weights,
         target_populations = targets,
         functiontype       = weight_type,
         lower_multiple     = lower_multiple,
         upper_multiple     = upper_multiple,
         tol                = 0.000001 )
    # println( "results for method $weight_type = $(rw.rc)" )
    # @assert rw.rc[:error] == 0 "non zero return code from weights gen $(rw.rc)"
    # weights = rw.weights
    weighted_popn = (weights' * data)'
    # println( "weighted_popn = $weighted_popn" )
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
    return weights
end

end # package