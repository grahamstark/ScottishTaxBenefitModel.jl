
const WDIR = joinpath(MODEL_DATA_DIR, "wales", "projections")

function loaddf()::DataFrame
    CSV.File( joinpath(WDIR,"popn-targets-2020-2040.csv"))|>DataFrame
end

const TARGET_DF :: DataFrame = loaddf()

"""
Got to be a simpler way, but .. 
"""
function onerow( d :: DataFrame, year :: Int )::Vector
    # a vector, by converting to a matrix & extracting 1 column, skipping 1st field (year)
    Matrix(popn[(popn.year .== year),:])[1,2:end]
end

function initialise_target_dataframe_xx( n :: Integer ) :: DataFrame
    df = DataFrame(
        m_u16 = zeros(n),
        m_age16_64 = zeros(n),
        m_age65_plus = zeros(n),
        f_u16 = zeros(n),
        f_age16_64 = zeros(n),
        f_age65_plus = zeros(n),
        v_1_adult = zeros(n),
        v_2_adults = zeros(n),
        v_1_adult_1_plus_children = zeros(n),
        v_3_plus_adults = zeros(n),
        v_2_plus_adults_1_plus_children = zeros(n)
    )
    return df
end

function make_target_rowxx!( row :: DataFrameRow, hh :: Household )
    num_male_ads = 0
    num_female_ads = 0
    num_u_16s = 0
    for (pid,pers) in hh.people
        if( pers.age < 16 )
            num_u_16s += 1;
        end
        if pers.sex == Male
            if( pers.age >= 16 )
                num_male_ads += 1;
            end
            if pers.age <= 15
                row.m_u16 += 1
            elseif pers.age <= 64
                row.m_age16_64 += 1
            else
                row.m_age65_plus += 1
            end
        else  # female
            if( pers.age >= 16 )
                num_female_ads += 1;
            end
            if pers.age <= 15
                row.f_u16 += 1
            elseif pers.age <= 64
                row.f_age16_64 += 1
            else
                row.f_age65_plus += 1
            end
        end # female
    end # people loop
    num_people = num_u_16s+num_male_ads+num_female_ads
    num_adults = num_male_ads+num_female_ads
    if num_people == 1
        row.v_1_adult = 1
    elseif num_adults == 1
        @assert num_u_16s > 0
        row.v_1_adult_1_plus_children = 1
    elseif num_adults == 2 && num_u_16s == 0
        row.v_2_adults = 1
    elseif num_adults > 2 && num_u_16s == 0
        row.v_3_plus_adults = 1
    elseif num_adults >= 2 && num_u_16s > 0
        row.v_2_plus_adults_1_plus_children = 1
    else
        @assert false "should never get here num_male_ads=$num_male_ads num_female_ads=$num_female_ads num_u_16s=$num_u_16s"
    end
end

function make_target_datasetxx( nhhlds :: Integer ) :: Matrix
    df :: DataFrame = initialise_target_dataframe_xx( nhhlds )
    for hno in 1:nhhlds
        hh = FRSHouseholdGetter.get_household( hno )
        make_target_rowxx!( df[hno,:], hh )
    end
    return Matrix{Float64}(df) # convert( Matrix, df )
end

function generate_weights_xx(
    nhhlds :: Integer;
    weight_type :: DistanceFunctionType = constrained_chi_square,
    lower_multiple :: Real = 0.20, # these values can be narrowed somewhat, to around 0.25-4.7
    upper_multiple :: Real = 5,
    targets :: Vector = DEFAULT_TARGETS ) :: Vector
    println( "targets=$targets")
    data :: Matrix = make_target_datasetxx( nhhlds )
    # println( "target dataset=$data" )
    nrows = size( data )[1]
    ncols = size( data )[2]
    ## FIXME parameterise this
    NUM_HOUSEHOLDSx = sum( targets[7:end])
    println( "NUM_HOUSEHOLDSx=$NUM_HOUSEHOLDSx")
    initial_weights = ones(nhhlds)*NUM_HOUSEHOLDSx/nhhlds
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
