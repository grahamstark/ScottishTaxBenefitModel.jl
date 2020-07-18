module Weighting

using SurveyDataWeighting,DataFrames

using ScottishTaxBenefitModel
using .ModelHousehold
using .Definitions

export generate_weights, make_target_dataset, TARGETS, initialise_target_dataframe

# FIXME rewrite this to load from a file.
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
    150_487, # 13 - M- 0 – 4
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
        m_0_4 = zeros(n),
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

end

function make_target_dataset( nhhlds :: Integer ) :: Matrix

end

function generate_weights( nhhlds :: Integer, targets :: Vector ) :: Vector

end

end # package
