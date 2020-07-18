module Weighting

using SurveyDataWeighting,DataFrames

using ScottishTaxBenefitModel
using .ModelHousehold

export generate_weights, make_target_dataset, TARGETS

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


function make_target_row!( data :: Matrix, hh :: ModelHousehold, pos :: Integer )

end

function make_target_dataset( nhhlds :: Integer ) :: Matrix

end

function generate_weights( nhhlds :: Integer, targets :: Vector ) :: Vector

end

end # package
