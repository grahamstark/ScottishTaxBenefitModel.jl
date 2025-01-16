
using CSV
using Pkg.Artifacts
using LazyArtifacts
#
#
#
const WDIR = joinpath(MODEL_DATA_DIR, "wales", "projections")

function loaddf_wales_longterm()::DataFrame
    return CSV.File( joinpath(artifact"augdata","popn-targets-wales-2020-2040.csv"))|>DataFrame
end

const TARGET_DF_LONG_TERM_WALES :: DataFrame = loaddf_wales_longterm()

export one_years_targets_wales
"""
Got to be a simpler way, but .. 
"""
function one_years_targets_wales( year :: Int )::NamedTuple
    # a vector, by converting to a matrix & extracting 1 column, skipping 1st field (year)
    row = TARGET_DF_LONG_TERM_WALES[(TARGET_DF_LONG_TERM_WALES.year .== year),:][1,:]
    targets = Vector( row )[2:end]
    num_households = 
        row.v_1_adult + 
        row.v_2_adults + 
        row.v_1_adult_1_plus_children + 
        row.v_3_plus_adults + 
        row.v_2_plus_adults_1_plus_children
    return  ( ; targets, num_households )
end

function initialise_target_dataframe_wales_longterm( n :: Integer ) :: DataFrame
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

function make_target_row_wales_longerm!( row :: DataFrameRow, hh :: Household )
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
