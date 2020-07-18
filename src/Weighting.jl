module Weighting

using Reexport

using SurveyDataWeighting: do_reweighting, DistanceFunctionType, chi_square,
    d_and_s_type_a, d_and_s_type_b, constrained_chi_square, d_and_s_constrained,
    ITERATIONS_EXCEEDED

using DataFrames

using ScottishTaxBenefitModel
using .ModelHousehold
using .Definitions


export generate_weights, make_target_dataset, TARGETS, initialise_target_dataframe

# FIXME rewrite this to load from a file.

const NUM_HOUSEHOLDS = 2_477_000.0 # sum of all hhld types below

const TARGETS = [
    1_340_609.0, # 1 - M- Total in employment- aged 16+
    60_635, # 2 - M- Total unemployed- aged 16+
    745_379, # 3 - M- Total economically inactive- aged 16+
    1_301_248, # 4 - F- Total in employment- aged 16+
    59_302, # 5 - F- Total unemployed- aged 16+
    974_767, # 6 - F- Total economically inactive- aged 16+
    1_540_890, # 7 - owner occupied
    370_502, # 8 - private rented+rent free
    282_482, # 9 - housing association
    314_433, # 10 - las etc rented
    139_982, # 11 - M- 0 - 4
    153_297, # 12 - M- 5 - 9
    150_487, # 13 - M- 10 – 14
    144_172, # 14 - M- 15 - 19
    176_066, # 15 - M- 20 - 24
    191_145, # 16 - M- 25 - 29
    182_635, # 17 -  M- 30 - 34
    172_624, # 18 -  M- 35 - 39
    156_790, # 19 - M- 40 - 44
    174_812, # 20 -  M- 45 - 49
    193_940, # 21 -  M- 50 - 54
    190_775, # 22 -  M- 55 - 59
    166_852, # 23 -  M- 60 - 64
    144_460, # 24 -  M- 65 - 69
    132_339, # 25 -  M- 70 - 74
    87_886, # 26 -  M- 75 - 79
    104_741, # 27 - M- 80’+
    131_733, # 28 - F- 0 - 4
    146_019, # 29 - F- 5 - 9
    144_187, # 30 - F- 10 - 14
    137_786, # 31 - F- 15 - 19
    171_390, # 32 - F- 20 - 24
    191_110, # 33 - F- 25 - 29
    186_828, # 34 -  F- 30 - 34
    179_898, # 35 -  F- 35 - 39
    162_642, # 36 - F- 40 - 44
    186_646, # 37 -  F- 45 - 49
    207_150, # 38 -  F- 50 - 54
    202_348, # 39 -  F- 55 - 59
    177_841, # 40 -  F- 60 - 64
    154_984, # 41 -  F- 65 - 69
    146_517, # 42 -  F- 70 - 74
    108_065, # 43 -  F- 75 - 79
    165_153, # 44 -  F- 80+
    439_000, # 45 - 1 adult: male
    467_000, # 46 - 1 adult: female
    797_000, # 47 - 2 adults
    70_000, # 48 - 1 adult 1 child
    66_000, # 49 - 1 adult 2+ children
    448_000, # 50 - 2+ adults 1+ children
    190_000, # 51 - 3+ adults
    77_842, # 52 - CARER’S ALLOWANCE
    127_307, # 53 - AA
    431_461 ] # PIP or DLA

function initialise_target_dataframe( n :: Integer ) :: DataFrame
    df = DataFrame(
        m_total_in_employment = zeros(n),
        m_total_unemployed = zeros(n),
        m_total_economically_inactive = zeros(n),
        f_total_in_employment = zeros(n),
        f_total_unemployed = zeros(n),
        f_total_economically_inactive = zeros(n),
        owner_occupied = zeros(n),
        private_rented_plus_rent_free = zeros(n),
        housing_association = zeros(n),
        las_etc_rented = zeros(n),
        m_0_4 = zeros(n),
        m_5_9 = zeros(n),
        m_10_14 = zeros(n),
        m_15_19 = zeros(n),
        m_20_24 = zeros(n),
        m_25_29 = zeros(n),
        m_30_34 = zeros(n),
        m_35_39 = zeros(n),
        m_40_44 = zeros(n),
        m_45_49 = zeros(n),
        m_50_54 = zeros(n),
        m_55_59 = zeros(n),
        m_60_64 = zeros(n),
        m_65_69 = zeros(n),
        m_70_74 = zeros(n),
        m_75_79 = zeros(n),
        m_80_plus = zeros(n),
        f_0_4 = zeros(n),
        f_5_9 = zeros(n),
        f_10_14 = zeros(n),
        f_15_19 = zeros(n),
        f_20_24 = zeros(n),
        f_25_29 = zeros(n),
        f_30_34 = zeros(n),
        f_35_39 = zeros(n),
        f_40_44 = zeros(n),
        f_45_49 = zeros(n),
        f_50_54 = zeros(n),
        f_55_59 = zeros(n),
        f_60_64 = zeros(n),
        f_65_69 = zeros(n),
        f_70_74 = zeros(n),
        f_75_79 = zeros(n),
        f_80_plus = zeros(n),
        v_1_adult_male = zeros(n),
        v_1_adult_female = zeros(n),
        v_2_adults = zeros(n),
        v_1_adult_1_child = zeros(n),
        v_1_adult_2_plus_children = zeros(n),
        v_2_plus_adults_1_plus_children = zeros(n),
        v_3_plus_adults = zeros(n),
        carers_allowance = zeros(n),
        aa = zeros(n),
        pip_or_dla = zeros(n)
    )
    return df
end

function make_target_row!( row :: DataFrameRow, hh :: Household )
    num_male_ads = 0
    num_female_ads = 0
    num_u_16s = 0
    for pers in hh.people
        if( pers.age < 16 )
            num_u_16s += 1;
        end
        if pers.sex == Male

            if( pers.age >= 16 )
                num_male_ads += 1;
            end
            if pers.employment_status in [
                Full_time_Employee = 1
                Part_time_Employee = 2
                Full_time_Self_Employed = 3
                Part_time_Self_Employed = 4
                ]
                row.m_total_in_employment += 1
            elseif pers.employment_status in [Unemployed]
                row.m_total_unemployed += 1
            else
                row.m_total_economically_inactive += 1 # delete!
            end
            if pers.age <= 4
                row.m_0_4 += 1
            elseif pers.age <= 9
                row.m_5_9 += 1
            elseif pers.age <= 14
                row.m_10_14 += 1
            elseif pers.age <= 19
                row.m_15_19 += 1
            elseif pers.age <= 24
                row.m_20_24 += 1
            elseif pers.age <= 29
                row.m_25_29 += 1
            elseif pers.age <= 34
                row.m_30_34 += 1
            elseif pers.age <= 39
                row.m_35_39 += 1
            elseif pers.age <= 44
                row.m_40_44 += 1
            elseif pers.age <= 49
                row.m_45_49 += 1
            elseif pers.age <= 54
                row.m_50_54 += 1
            elseif pers.age <= 59
                row.m_55_59 += 1
            elseif pers.age <= 64
                row.m_60_64 += 1
            elseif pers.age <= 69
                row.m_65_69 += 1
            elseif pers.age <= 74
                row.m_70_74 += 1
            elseif pers.age <= 79
                row.m_75_79 += 1
            else
                row.m_80_plus += 1
            end
        else  # female
            if( pers.age >= 16 )
                num_female_ads += 1;
            end
            if pers.employment_status in [
                Full_time_Employee = 1
                Part_time_Employee = 2
                Full_time_Self_Employed = 3
                Part_time_Self_Employed = 4
                ]
                row.f_total_in_employment += 1
            elseif pers.employment_status in [Unemployed]
                row.f_total_unemployed += 1
            else
                row.f_total_economically_inactive += 1
            end
            if pers.age <= 4
                row.f_0_4 += 1
            elseif pers.age <= 9
                row.f_5_9 += 1
            elseif pers.age <= 14
                row.f_10_14 += 1
            elseif pers.age <= 19
                row.f_15_19 += 1
            elseif pers.age <= 24
                row.f_20_24 += 1
            elseif pers.age <= 29
                row.f_25_29 += 1
            elseif pers.age <= 34
                row.f_30_34 += 1
            elseif pers.age <= 39
                row.f_35_39 += 1
            elseif pers.age <= 44
                row.f_40_44 += 1
            elseif pers.age <= 49
                row.f_45_49 += 1
            elseif pers.age <= 54
                row.f_50_54 += 1
            elseif pers.age <= 59
                row.f_55_59 += 1
            elseif pers.age <= 64
                row.f_60_64 += 1
            elseif pers.age <= 69
                row.f_65_69 += 1
            elseif pers.age <= 74
                row.f_70_74 += 1
            elseif pers.age <= 79
                row.f_75_79 += 1
            else
                row.f_80_plus += 1
            end


        end # female
        if pers.income[carers_allowance] > 0
            row.carers_allowance += 1
        end
        if pers.income[attendance_allowance] > 0
            row.attendance_allowance += 1
        end
        if pers.income[personal_independence_payment_daily_living] > 0 ||
           pers.income[personal_independence_payment_mobility] > 0 ||
           pers.income[dlaself_care] > 0 ||
           pers.income[dlamobility] > 0
           row.pip_or_dla += 1
       end
    end # people
    if owner_occupier(hh.tenure)
        row.owner_occupied = 1
    elseif hh.tenure == LA_or_New_Town_or_NIHE_or_Council_rented
        row.las_etc_rented = 1
    elseif hh.tenure == Housing_Association_or_Co_Op_or_Trust_rented
        row.housing_association = 1
    else
        row.private_rented_plus_rent_free = 1
    end
    num_people = num_u_16s+num_male_ads+num_female_ads
    num_adults = num_male_ads+num_female_ads
    if num_people == 1
        if num_male_ads == 1
            row.v_1_adult_male = 1
        else
            row.v_1_adult_female = 1
        end
    elseif num_adults == 1
        if num_u_16s == 1
            row.v_1_adult_1_child = 1
        else
            row.v_1_adult_2_plus_children = 1
        end
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

function make_target_dataset( nhhlds :: Integer ) :: Matrix
    df :: DataFrame = initialise_target_dataframe( nhhlds )
    for hno in 1:nhhlds
        hh = FRSHouseholdGetter.get_household( hno )
        make_target_row!( df[hno,:], hh )
    end
    return convert( Matrix, df )
end

#
# generate weights for the dataset and
#
#
function generate_weights(
    nhhlds :: Integer;
    weight_type :: DistanceFunctionType = constrained_chi_square,
    lower_multiple :: Real = 0.20,
    upper_multiple :: Real = 2.19,
    targets :: Vector = DEFAULT_TARGETS  ) :: Vector

    data :: Matrix = make_target_dataset( nhhlds )
    nrows = size( data )[1]
    ncols = size( data )[2]
    ## FIXME parameterise this
    initial_weights = ones(nhhlds)*NUM_HOUSEHOLDS/nhhlds
     # any smaller min and d_and_s_constrained fails on this dataset
    rw = do_reweighting(
         data               = data,
         initial_weights    = initial_weights,
         target_populations = targets,
         functiontype       = weight_type,
         lower_multiple     = lower_multiple,
         upper_multiple     = upper_multiple,
         tolx               = 0.000001,
         tolf               = 0.000001 )
    println( "results for method $m = $rw" )
    weights = rw.weights
    weighted_popn = (weights' * data)'
    println( "weighted_popn = $weighted_popn" )
    @assert weighted_popn ≈ target_populations

    if weight_type in [constrained_chi_square, d_and_s_constrained ]
      # check the constrainted methods keep things inside ll and ul
        for r in 1:nrows
            @assert weights[r] .<= initial_weights[r]*upper_multiple
            @assert weights[r] .>= initial_weights[r]*lower_multiple
        end
    end
    for hno in 1:nhhlds
        hh = FRSHouseholdGetter.get_household( hno )
        hh.weight = weights[hno]
    end
    return weights
end

end # package
