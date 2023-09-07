module Definitions
#
# This module contains enumerated types and constants that are used throughout the model.
#
using ScottishTaxBenefitModel
using ScottishTaxBenefitModel.Utils
using Parameters
using JSON3
import Base.sum

export 
   Employment_Status,  # mapped from empstat
   Employee, 
   Missing_Employment_Status,
   Self_employed,   
   FRS_DIR, 
   HBAI_DIR,
   MATCHING_DIR,
   MODEL_DATA_DIR, 
   MODEL_DATA_DIR, 
   MODEL_PARAMS_DIR, 
   PRICES_DIR, 
   PROJECT_DIR,
   TEST_DIR,
   SRC_DIR,
   DOCS_DIR,
   SCRIPTS_DIR 


"""
Inefficient but works ... load a path 'which' from a json file etc/config.json
with default if config isn't there or which isn't in the file. Loads the
whole file each time but hey ho. FIXME remove CONFIG_DIR/move to Utils???
"""
function load_data_path( ; default :: String, which::Symbol ) :: String
   jpath = joinpath(CONFIG_DIR, "config.json" )
   if ! isfile( jpath )
      return default
   end
   jfile = JSON3.read( jpath )
   if ! haskey( jfile, which )
      return default
   end
   return jfile[which]
end

const MODEL_NAME       = "Scottish Tax Benefit Model" 
# FIXME these might be better at the top of ScottishTaxBenefitModel.jl itself
const PROJECT_DIR      = joinpath(dirname(pathof(ScottishTaxBenefitModel)),".." )
const MODEL_PARAMS_DIR = joinpath( PROJECT_DIR, "params" )
const SCRIPTS_DIR      = joinpath( PROJECT_DIR, "scripts" )
const TEST_DIR         = joinpath( PROJECT_DIR, "test" )
const DOCS_DIR         = joinpath( PROJECT_DIR, "docs" )
const SRC_DIR          = joinpath( PROJECT_DIR, "src" )
const CONFIG_DIR       = joinpath( PROJECT_DIR, "etc" )


const DEF_MODEL_DATA_DIR   = joinpath( PROJECT_DIR, "data" )
const MODEL_DATA_DIR   = load_data_path( which=:model_data_dir, default=DEF_MODEL_DATA_DIR )
const PRICES_DIR       = joinpath( MODEL_DATA_DIR, "prices", "indexes" )
const MATCHING_DIR     = joinpath( MODEL_DATA_DIR, "merging" )

const RAW_DATA         = load_data_path( which=:raw_data, default="/mnt/data/" )
const FRS_DIR          = joinpath( RAW_DATA, "/frs/" )
const HBAI_DIR         = joinpath( RAW_DATA, "/hbai/" )

export NUM_REPEATS
const NUM_REPEATS = 30 # simulates a longer calculation

export LegacyOrUC, legacy_bens, uc_bens
@enum LegacyOrUC legacy_bens uc_bens

#
# update this every time you add data, update prices, etc.
#
@with_kw struct CreationDates
   data = Date( 2022, 08, 16 )
   # target_set_target_date = Date( 2022, 06, 01 ) # roughly 
   target_set = Date( 2022, 08, 12 )
   uprating = Date( 2022, 04, 08 )
   uc_transition = Date(2022, 02, 01 ) # feb 2022
   pip_dla_historic = Date(2022, 08, 12 )
   benefit_generosity = Date(2022, 08, 12 )
end

#
# FIXME TODO shorten enum names; capitalise consistently
#

export old_style, new_style, OldOrNew
@enum OldOrNew begin
   missing_style = -1
   old_style = 1
   new_style = 2
end

export BereavementType,
   missing_bereave,
   bereavement_allowance,
   widowed_parents,
   bereavement_support
   
@enum BereavementType begin
   missing_bereave = -1
   bereavement_allowance = 1
   widowed_parents = 2
   bereavement_support = 3 # old style 1 off payment. Only recorded in 2015 FRS I think
end

export Illness_Length  # mapped from limitl
export Less_than_six_months, Between_six_months_and_12_months, v_12_months_or_more
export Missing_Illness_Length, RT

export DwellingType,  dwell_na, detatched, semi_detached, terraced,
   flat_or_maisonette, converted_flat, caravan, other_dwelling

@enum DwellingType begin
   dwell_na = -1
   detatched = 1
   semi_detached = 2
   terraced = 3
   flat_or_maisonette = 4
   converted_flat = 5
   caravan = 6
   other_dwelling = 7
end

@enum Illness_Length begin  # mapped from limitl
   Missing_Illness_Length = -1
   Less_than_six_months = 1
   Between_six_months_and_12_months = 2
   v_12_months_or_more = 3
end

@enum PIPType begin
    no_pip = -1
    standard_pip = 1
    enhanced_pip = 2
end
export PIPType, no_pip, standard_pip, enhanced_pip

@enum LowMiddleHigh begin
    missing_lmh = -1 # fixme global change to "no_lmh"
    low = 1
    mid = 2
    high = 3
end
export LowMiddleHigh, missing_lmh, low, mid, high


export ADLS_Inhibited  # mapped from condit
export reduced_a_lot, reduced_a_little, not_reduced
export Missing_ADLS_Inhibited

@enum ADLS_Inhibited begin  # mapped from condit
   Missing_ADLS_Inhibited = -1
   reduced_a_lot = 1
   reduced_a_little = 2
   not_reduced = 3
end

@enum Employment_Status begin  # mapped from empstat
   Missing_Employment_Status = -1
   Employee = 1
   Self_employed = 2
end


export ILO_Employment  # mapped from empstati
export Full_time_Employee,
       Part_time_Employee,
       Full_time_Self_Employed,
       Part_time_Self_Employed,
       Unemployed,
       Retired,
       Student,
       Looking_after_family_or_home,
       Permanently_sick_or_disabled,
       Temporarily_sick_or_injured,
       Other_Inactive
export Missing_ILO_Employment

@enum ILO_Employment begin  # mapped from empstati
   Missing_ILO_Employment = -1
   Full_time_Employee = 1
   Part_time_Employee = 2
   Full_time_Self_Employed = 3
   Part_time_Self_Employed = 4
   Unemployed = 5
   Retired = 6
   Student = 7
   Looking_after_family_or_home = 8
   Permanently_sick_or_disabled = 9
   Temporarily_sick_or_injured = 10
   Other_Inactive = 11
end


export Ethnic_Group  # mapped from ethgr3
export White,
       Mixed_or_Multiple_ethnic_groups,
       Asian_or_Asian_British,
       Black_or_African_or_Caribbean_or_Black_British,
       Other_ethnic_group,
       Ethnic_Not_Declared
export Missing_Ethnic_Group

@enum Ethnic_Group begin  # mapped from ethgr3
   Missing_Ethnic_Group = -1
   White = 1
   Mixed_or_Multiple_ethnic_groups = 2
   Asian_or_Asian_British = 3
   Black_or_African_or_Caribbean_or_Black_British = 4
   Other_ethnic_group = 5
   Ethnic_Not_Declared = 6
end


export Ethnic_Scotland  # mapped from ethgrps
export Scottish,
       Other_British,
       Irish,
       Gypsy_or_Traveller,
       Polish,
       Any_other_white_ethnic_group,
       Any_mixed_or_multiple_ethnic_group,
       Pakistani_Pakistani_Scottish_or_Pakistani_British,
       Indian_Indian_Scottish_or_Indian_British,
       Bangladeshi_Bangladeshi_Scottish_or_Bangladeshi_British,
       Chinese_Chinese_Scottish_or_Chinese_British,
       Any_other_Asian,
       African_African_Scottish_or_African_British,
       Any_other_African,
       Caribbean_Caribbean_Scottish_or_Caribbean_British,
       Black_Black_Scottish_or_Black_British,
       Any_other_Caribbean_or_Black,
       Arab_Arab_Scottish_or_Arab_British,
       Any_other_ethnic_group
export Missing_Ethnic_Scotland

@enum Ethnic_Scotland begin  # mapped from ethgrps
   Missing_Ethnic_Scotland = -1
   Scottish = 1
   Other_British = 2
   Irish = 3
   Gypsy_or_Traveller = 4
   Polish = 5
   Any_other_white_ethnic_group = 6
   Any_mixed_or_multiple_ethnic_group = 7
   Pakistani_Pakistani_Scottish_or_Pakistani_British = 8
   Indian_Indian_Scottish_or_Indian_British = 9
   Bangladeshi_Bangladeshi_Scottish_or_Bangladeshi_British = 10
   Chinese_Chinese_Scottish_or_Chinese_British = 11
   Any_other_Asian = 12
   African_African_Scottish_or_African_British = 13
   Any_other_African = 14
   Caribbean_Caribbean_Scottish_or_Caribbean_British = 15
   Black_Black_Scottish_or_Black_British = 16
   Any_other_Caribbean_or_Black = 17
   Arab_Arab_Scottish_or_Arab_British = 18
   Any_other_ethnic_group = 19
end


export Sex  # mapped from sex
export Male, Female
export Missing_Sex

@enum Sex begin  # mapped from sex
   Missing_Sex = -1
   Male = 1
   Female = 2
end


export Health_Status  # mapped from heathad
export Very_Good, Good, Fair, Bad, Very_Bad
export Missing_Health_Status

@enum Health_Status begin  # mapped from heathad
   Missing_Health_Status = -1
   Very_Good = 1
   Good = 2
   Fair = 3
   Bad = 4
   Very_Bad = 5
end


export Marital_Status  # mapped from marital
export Married_or_Civil_Partnership,
       Cohabiting,
       Single,
       Widowed,
       Separated,
       Divorced_or_Civil_Partnership_dissolved
export Missing_Marital_Status

@enum Marital_Status begin  # mapped from marital
   Missing_Marital_Status = -1
   Married_or_Civil_Partnership = 1
   Cohabiting = 2
   Single = 3
   Widowed = 4
   Separated = 5
   Divorced_or_Civil_Partnership_dissolved = 6
end


export Qualification_Type  # mapped from dvhiqual
export Doctorate_or_MPhil,
       Masters_PGCE_or_some_other_post_graduate_degree,
       Degree_inc_foundation_degree_or_professional_institute_member,
       Teaching_qualification_excluding_PGCE,
       Any_other_foreign_qualification_at_degree_level,
       Any_other_work_related_or_vocational_qualification_at_degr,
       Any_other_professional_qualification_at_degree_level,
       Other_Higher_Education_qualification_below_degree_level,
       Nursing_or_other_medical_qualification_not_yet_mentioned,
       Diploma_in_higher_education,
       HNC_or_HND,
       BTEC_BEC_TEC_EdExcel_or_LQL_at_higher_level_Higher_Lev,
       SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_higher_level_level,
       NVQ_or_SVQ_Level_4,
       NVQ_or_SVQ_Level_5,
       RSA_or_OCR_a_higher_diploma_or_OCR_Level_4,
       A_Level_or_GCE_in_Applied_Subjects_or_equivalent,
       Welsh_Baccalaureate_at_Advanced_level,
       Scottish_Baccalaureate,
       International_Baccalaureate,
       AS_level_or_equivalent,
       Certificate_of_6th_Year_Studies_CSYS_Scotland,
       Access_to_Higher_Education,
       Advanced_Higher_or_Higher_or_Intermediate_or_Access_Qualification_Sc,
       Skills_for_work_Higher,
       ONC_or_OND,
       BTEC_BEC_TEC_EdExcel_or_LQL_at_Nat_Cert_or_Nat_Dipl_leve,
       SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_full_Nat_Cert_Level,
       New_Diploma_an_Advanced_diploma_level3,
       New_Diploma_a_Progression_diploma_level_3,
       NVQ_or_SVQ_Level_3,
       GNVQ_or_GSVQ_Advanced,
       RSA_or_OCR_an_advanced_diploma_or_advanced_certificate_or_OCR_L,
       City_and_Guilds_advanced_craft_or_part_3,
       Welsh_Baccalaureate_at_the_Intermediate_level,
       O_Level_or_equivalent_five_or_more,
       Standard_Grade_or_Ordinary_Grade_or_Lower_Scotland_five_or,
       GCSE_or_equivalent_five_or_more,
       CSE_five_or_more,
       Scottish_National_level_5,
       Skills_for_work_National_level_5,
       BTEC_BEC_TEC_EdExcel_or_LQL_first_diploma_or_general_diplo,
       SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_first_diploma_or_genera,
       New_Diploma_a_Higher_diploma_level_2,
       NVQ_or_SVQ_Level_2,
       GNVQ_or_GSVQ_Full_Intermediate,
       RSA_or_OCR_a_diploma_or_OCR_Level_2,
       City_and_Guilds_craft_or_part_2,
       Any_other_qualification_high_school_leavers_qualification,
       BTEC_BEC_TEC_EdExcel_or_LQL,
       BTEC_BEC_TEC_EdExcel_or_LQL_first_cert_or_general_cert_Le,
       SCOTVEC_SCOTEC_or_SCOTBEC_Scotland,
       SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_first_cert_or_general_c,
       SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_modules_towards_Nat,
       New_Diploma,
       New_Diploma_Foundation_Diploma_level_1,
       Welsh_Baccalaureate,
       Welsh_Baccalaureate_at_the_foundation_level,
       NVQ_or_SVQ,
       NVQ_or_SVQ_Level_1,
       GNVQ_or_GSVQ,
       GNVQ_or_GSVQ_Part_One_Intermediate,
       GNVQ_or_GSVQ_Full_Foundation,
       GNVQ_or_GSVQ_Part_One_Foundation,
       O_Level_or_equivalent,
       O_Level_or_equivalent_fewer_than_5,
       Standard_Grade_or_Ordinary_Grade_or_Lower_Scotland,
       Standard_Grade_or_Ordinary_Grade_or_Lower_Scotland_fewer_t,
       GCSE_or_equivalent,
       GCSE_or_equivalent_fewer_than_5,
       Scottish_National_level_1_to_4,
       Scottish_National_level,
       Skills_for_work_National_level_3_and_4,
       Skills_for_work,
       CSE,
       CSE_fewer_than_5,
       RSA_or_OCR,
       RSA_or_OCR_some_other_RSA_including_Stage_I_II_and_III_or_OC,
       City_and_Guilds,
       City_and_Guilds_foundation_or_part_1,
       YT_Certificate_or_YTP,
       Key_Skills_or_Core_Skills_Scotland_or_Essential_Skills_Wales,
       Basic_Skills_skills_for_life_or_literacy_or_numeracy_or_language,
       Entry_Level_Qualifications,
       Award_Certificate_or_Diploma_at_entry_level_levels_1_to_8,
       Any_other_professional_or_vocational_or_foreign_qualifications
export Missing_Highest_Qualification

@enum Qualification_Type begin  # mapped from dvhiqual
   Missing_Highest_Qualification = -1
   Doctorate_or_MPhil = 1
   Masters_PGCE_or_some_other_post_graduate_degree = 2
   Degree_inc_foundation_degree_or_professional_institute_member = 3
   Teaching_qualification_excluding_PGCE = 4
   Any_other_foreign_qualification_at_degree_level = 5
   Any_other_work_related_or_vocational_qualification_at_degr = 6
   Any_other_professional_qualification_at_degree_level = 7
   Other_Higher_Education_qualification_below_degree_level = 8
   Nursing_or_other_medical_qualification_not_yet_mentioned = 9
   Diploma_in_higher_education = 10
   HNC_or_HND = 11
   BTEC_BEC_TEC_EdExcel_or_LQL_at_higher_level_Higher_Lev = 12
   SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_higher_level_level = 13
   NVQ_or_SVQ_Level_4 = 14
   NVQ_or_SVQ_Level_5 = 15
   RSA_or_OCR_a_higher_diploma_or_OCR_Level_4 = 16
   A_Level_or_GCE_in_Applied_Subjects_or_equivalent = 17
   Welsh_Baccalaureate_at_Advanced_level = 18
   Scottish_Baccalaureate = 19
   International_Baccalaureate = 20
   AS_level_or_equivalent = 21
   Certificate_of_6th_Year_Studies_CSYS_Scotland = 22
   Access_to_Higher_Education = 23
   Advanced_Higher_or_Higher_or_Intermediate_or_Access_Qualification_Sc = 24
   Skills_for_work_Higher = 25
   ONC_or_OND = 26
   BTEC_BEC_TEC_EdExcel_or_LQL_at_Nat_Cert_or_Nat_Dipl_leve = 27
   SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_full_Nat_Cert_Level = 28
   New_Diploma_an_Advanced_diploma_level3 = 29
   New_Diploma_a_Progression_diploma_level_3 = 30
   NVQ_or_SVQ_Level_3 = 31
   GNVQ_or_GSVQ_Advanced = 32
   RSA_or_OCR_an_advanced_diploma_or_advanced_certificate_or_OCR_L = 33
   City_and_Guilds_advanced_craft_or_part_3 = 34
   Welsh_Baccalaureate_at_the_Intermediate_level = 35
   O_Level_or_equivalent_five_or_more = 36
   Standard_Grade_or_Ordinary_Grade_or_Lower_Scotland_five_or = 37
   GCSE_or_equivalent_five_or_more = 38
   CSE_five_or_more = 39
   Scottish_National_level_5 = 40
   Skills_for_work_National_level_5 = 41
   BTEC_BEC_TEC_EdExcel_or_LQL_first_diploma_or_general_diplo = 42
   SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_first_diploma_or_genera = 43
   New_Diploma_a_Higher_diploma_level_2 = 44
   NVQ_or_SVQ_Level_2 = 45
   GNVQ_or_GSVQ_Full_Intermediate = 46
   RSA_or_OCR_a_diploma_or_OCR_Level_2 = 47
   City_and_Guilds_craft_or_part_2 = 48
   Any_other_qualification_high_school_leavers_qualification = 49
   BTEC_BEC_TEC_EdExcel_or_LQL = 50
   BTEC_BEC_TEC_EdExcel_or_LQL_first_cert_or_general_cert_Le = 51
   SCOTVEC_SCOTEC_or_SCOTBEC_Scotland = 52
   SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_first_cert_or_general_c = 53
   SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_modules_towards_Nat = 54
   New_Diploma = 55
   New_Diploma_Foundation_Diploma_level_1 = 56
   Welsh_Baccalaureate = 57
   Welsh_Baccalaureate_at_the_foundation_level = 58
   NVQ_or_SVQ = 59
   NVQ_or_SVQ_Level_1 = 60
   GNVQ_or_GSVQ = 61
   GNVQ_or_GSVQ_Part_One_Intermediate = 62
   GNVQ_or_GSVQ_Full_Foundation = 63
   GNVQ_or_GSVQ_Part_One_Foundation = 64
   O_Level_or_equivalent = 65
   O_Level_or_equivalent_fewer_than_5 = 66
   Standard_Grade_or_Ordinary_Grade_or_Lower_Scotland = 67
   Standard_Grade_or_Ordinary_Grade_or_Lower_Scotland_fewer_t = 68
   GCSE_or_equivalent = 69
   GCSE_or_equivalent_fewer_than_5 = 70
   Scottish_National_level_1_to_4 = 71
   Scottish_National_level = 72
   Skills_for_work_National_level_3_and_4 = 73
   Skills_for_work = 74
   CSE = 75
   CSE_fewer_than_5 = 76
   RSA_or_OCR = 77
   RSA_or_OCR_some_other_RSA_including_Stage_I_II_and_III_or_OC = 78
   City_and_Guilds = 79
   City_and_Guilds_foundation_or_part_1 = 80
   YT_Certificate_or_YTP = 81
   Key_Skills_or_Core_Skills_Scotland_or_Essential_Skills_Wales = 82
   Basic_Skills_skills_for_life_or_literacy_or_numeracy_or_language = 83
   Entry_Level_Qualifications = 84
   Award_Certificate_or_Diploma_at_entry_level_levels_1_to_8 = 85
   Any_other_professional_or_vocational_or_foreign_qualifications = 86
end

# FIXME this stuff needs checked thoroughly.

export 
   highqual_degree_equiv, 
   highqual_other_he,
   highqual_alevel_equiv, 
   highqual_gcse_equiv, 
   highqual_other, 
   no_qualification

function no_qualification( q :: Qualification_Type ) :: Bool
   q == Missing_Highest_Qualification
end

function highqual_degree_equiv( q :: Qualification_Type ) :: Bool
   q in [Doctorate_or_MPhil,
      Masters_PGCE_or_some_other_post_graduate_degree,
      Degree_inc_foundation_degree_or_professional_institute_member,
      Teaching_qualification_excluding_PGCE,
      Any_other_foreign_qualification_at_degree_level,
      Any_other_work_related_or_vocational_qualification_at_degr,
      Any_other_professional_qualification_at_degree_level]

end

function highqual_other_he( q :: Qualification_Type ) :: Bool
   q in [
      BTEC_BEC_TEC_EdExcel_or_LQL_at_higher_level_Higher_Lev,
      SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_higher_level_level,
      Other_Higher_Education_qualification_below_degree_level,
      Nursing_or_other_medical_qualification_not_yet_mentioned,
      HNC_or_HND,
      Diploma_in_higher_education ]
end


function highqual_alevel_equiv( q :: Qualification_Type ) :: Bool
   q in [
      NVQ_or_SVQ_Level_4,
      NVQ_or_SVQ_Level_5,
      RSA_or_OCR_a_higher_diploma_or_OCR_Level_4,
      A_Level_or_GCE_in_Applied_Subjects_or_equivalent,
      Welsh_Baccalaureate_at_Advanced_level,
      Scottish_Baccalaureate,
      Welsh_Baccalaureate,
      International_Baccalaureate,
      AS_level_or_equivalent,
      Certificate_of_6th_Year_Studies_CSYS_Scotland,
      Access_to_Higher_Education,
      Advanced_Higher_or_Higher_or_Intermediate_or_Access_Qualification_Sc,
      Skills_for_work_Higher,
      ONC_or_OND,
      BTEC_BEC_TEC_EdExcel_or_LQL_at_Nat_Cert_or_Nat_Dipl_leve,
      SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_full_Nat_Cert_Level,
      New_Diploma_an_Advanced_diploma_level3,
      New_Diploma_a_Progression_diploma_level_3,
      NVQ_or_SVQ_Level_3,
      GNVQ_or_GSVQ_Advanced,
      RSA_or_OCR_an_advanced_diploma_or_advanced_certificate_or_OCR_L,
      City_and_Guilds_advanced_craft_or_part_3,
      Welsh_Baccalaureate_at_the_Intermediate_level ]
end

function highqual_gcse_equiv( q :: Qualification_Type ) :: Bool
   q in [
      O_Level_or_equivalent_five_or_more,
      Standard_Grade_or_Ordinary_Grade_or_Lower_Scotland_five_or,
      GCSE_or_equivalent_five_or_more,
      CSE_five_or_more,
      Scottish_National_level_5,
      Skills_for_work_National_level_5,
      O_Level_or_equivalent,
      O_Level_or_equivalent_fewer_than_5,
      Standard_Grade_or_Ordinary_Grade_or_Lower_Scotland,
      Standard_Grade_or_Ordinary_Grade_or_Lower_Scotland_fewer_t,
      GCSE_or_equivalent,
      GCSE_or_equivalent_fewer_than_5,
      Scottish_National_level_1_to_4,
      Scottish_National_level,
      Skills_for_work_National_level_3_and_4,
      Skills_for_work,
      CSE,
      CSE_fewer_than_5,
      Welsh_Baccalaureate_at_the_foundation_level,
      NVQ_or_SVQ,
      NVQ_or_SVQ_Level_1,
      GNVQ_or_GSVQ,
      GNVQ_or_GSVQ_Part_One_Intermediate,
      GNVQ_or_GSVQ_Full_Foundation,
      GNVQ_or_GSVQ_Part_One_Foundation    
   ]
end

function highqual_other( q :: Qualification_Type ) :: Bool
   q in [
      BTEC_BEC_TEC_EdExcel_or_LQL_first_diploma_or_general_diplo,
      SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_first_diploma_or_genera,
      New_Diploma_a_Higher_diploma_level_2,
      NVQ_or_SVQ_Level_2,
      GNVQ_or_GSVQ_Full_Intermediate,
      RSA_or_OCR_a_diploma_or_OCR_Level_2,
      City_and_Guilds_craft_or_part_2,
      Any_other_qualification_high_school_leavers_qualification,
      BTEC_BEC_TEC_EdExcel_or_LQL,
      BTEC_BEC_TEC_EdExcel_or_LQL_first_cert_or_general_cert_Le,
      SCOTVEC_SCOTEC_or_SCOTBEC_Scotland,
      SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_first_cert_or_general_c,
      SCOTVEC_SCOTEC_or_SCOTBEC_Scotland_modules_towards_Nat,
      New_Diploma,
      New_Diploma_Foundation_Diploma_level_1,
      RSA_or_OCR,
      RSA_or_OCR_some_other_RSA_including_Stage_I_II_and_III_or_OC,
      City_and_Guilds,
      City_and_Guilds_foundation_or_part_1,
      YT_Certificate_or_YTP,
      Key_Skills_or_Core_Skills_Scotland_or_Essential_Skills_Wales,
      Basic_Skills_skills_for_life_or_literacy_or_numeracy_or_language,
      Entry_Level_Qualifications,
      Award_Certificate_or_Diploma_at_entry_level_levels_1_to_8,
      Any_other_professional_or_vocational_or_foreign_qualifications
   ]
end


export Standard_Region  # mapped from gvtregn
export North_East,
       North_West,
       Yorks_and_the_Humber,
       East_Midlands,
       West_Midlands,
       East_of_England,
       London,
       South_East,
       South_West,
       Scotland,
       Wales,
       Northern_Ireland
export Missing_Standard_Region

@enum Standard_Region begin  # mapped from gvtregn
   Missing_Standard_Region = -1
   North_East = 112000001
   North_West = 112000002
   Yorks_and_the_Humber = 112000003
   East_Midlands = 112000004
   West_Midlands = 112000005
   East_of_England = 112000006
   London = 112000007
   South_East = 112000008
   South_West = 112000009
   Scotland = 299999999
   Wales = 399999999
   Northern_Ireland = 499999999
end

export nation_from_region, Nation, N_England, N_Scotland, N_Wales, N_Northern_Ireland, N_UK, N_GB, N_rUK

@enum Nation begin
   N_England = 199999999
   N_Scotland = 299999999
   N_Wales = 399999999
   N_Northern_Ireland = 499999999
   ## NOTE these 3 are Made up numbers
   N_UK = 599999999
   N_GB = 699999999
   N_rUK = 799999999
end

function nation_from_region( r :: Standard_Region ) :: Nation
   return if r in [North_East,
      North_West,
      Yorks_and_the_Humber,
      East_Midlands,
      West_Midlands,
      East_of_England,
      London,
      South_East,
      South_West]
         N_England
   elseif r == Scotland 
      N_Scotland
   elseif r == Wales
      N_Wales
   elseif r == Northern_Ireland 
      N_Northern_Ireland
   else
      @assert false "failed to map $r"
   end
end


export Socio_Economic_Group  # mapped from nssec
export Employers_in_large_organisations,
       Higher_managerial_occupations,
       Higher_professional_occupations_New_self_employed,
       Lower_prof_and_higher_technical_Traditional_employee,
       Lower_managerial_occupations,
       Higher_supervisory_occupations,
       Intermediate_clerical_and_administrative,
       Employers_in_small_organisations_non_professional,
       Own_account_workers_non_professional,
       Lower_supervisory_occupations,
       Lower_technical_craft,
       Semi_routine_sales,
       Routine_sales_and_service,
       Never_worked,
       Full_time_student,
       Not_classified_or_inadequately_stated,
       Not_classifiable_for_other_reasons
export Missing_Socio_Economic_Group

@enum Socio_Economic_Group begin  # mapped from nssec
   Missing_Socio_Economic_Group = -1
   Employers_in_large_organisations = 1
   Higher_managerial_occupations = 2
   Higher_professional_occupations_New_self_employed = 3
   Lower_prof_and_higher_technical_Traditional_employee = 4
   Lower_managerial_occupations = 5
   Higher_supervisory_occupations = 6
   Intermediate_clerical_and_administrative = 7
   Employers_in_small_organisations_non_professional = 8
   Own_account_workers_non_professional = 9
   Lower_supervisory_occupations = 10
   Lower_technical_craft = 11
   Semi_routine_sales = 12
   Routine_sales_and_service = 13
   Never_worked = 14
   Full_time_student = 15
   Not_classified_or_inadequately_stated = 16
   Not_classifiable_for_other_reasons = 17
end


export SIC_2007  # mapped from sic
export Undefined_SIC,
       Crop_and_animal_production_hunting_and_related_serviceX,
       Forestry_and_logging,
       Fishing_and_aquaculture,
       Mining_of_coal_and_lignite,
       Extraction_of_crude_petroleum_and_natural_gas,
       Mining_of_metal_ores,
       Other_mining_and_quarrying,
       Mining_support_service_activities,
       Manufacture_of_food_products,
       Manufacture_of_beverages,
       Manufacture_of_tobacco_products,
       Manufacture_of_textiles,
       Manufacture_of_wearing_apparel,
       Manufacture_of_leather_and_related_products,
       Manufacture_of_wood_and_of_products_of_wood_and_corkX,
       Manufacture_of_paper_and_paper_products,
       Printing_and_reproduction_of_recorded_media,
       Manufacture_of_coke_and_refined_petroleum_products,
       Manufacture_of_chemicals_and_chemical_products,
       Manufacture_of_basic_pharmaceutical_products_andX,
       Manufacture_of_rubber_and_plastic_products,
       Manufacture_of_other_non_metallic_mineral_products,
       Manufacture_of_basic_metals,
       Manufacture_of_fabricated_metal_products_except_machineryX,
       Manufacture_of_computer_electronic_and_optical_products,
       Manufacture_of_electrical_equipment,
       Manufacture_of_machinery_and_equipment_nec,
       Manufacture_of_motor_vehicles_trailers_and_semi_trailers,
       Manufacture_of_other_transport_equipment,
       Manufacture_of_furniture,
       Other_manufacturing,
       Repair_and_installation_of_machinery_and_equipment,
       Electricity_gas_steam_and_air_conditioning_supply,
       Water_collection_treatment_and_supply,
       Sewerage,
       Waste_collection_treatment_and_disposal_activitiesX,
       Remediation_activities_and_other_waste_management_services,
       Construction_of_buildings,
       Civil_engineering,
       Specialised_construction_activities,
       Wholesale_and_retail_trade_and_repair_of_motor_vehiclesX,
       Wholesale_trade_except_of_motor_vehicles_and_motorcycles,
       Retail_trade_except_of_motor_vehicles_and_motorcycles,
       Land_transport_and_transport_via_pipelines,
       Water_transport,
       Air_transport,
       Warehousing_and_support_activities_for_transportation,
       Postal_and_courier_activities,
       Accommodation,
       Food_and_beverage_service_activities,
       Publishing_activities,
       Motion_picture_video_and_television_programme_productionX,
       Programming_and_broadcasting_activities,
       Telecommunications,
       Computer_programming_consultancy_and_related_activities,
       Information_service_activities,
       Financial_service_activities_except_insurance_and_pensionX,
       Insurance_reinsurance_and_pension_funding_exceptX,
       Activities_auxiliary_to_financial_services_and_insuranceX,
       Real_estate_activities,
       Legal_and_accounting_activities,
       Activities_of_head_offices_management_consultancyX,
       Architectural_and_engineering_activities_technical_testingX,
       Scientific_research_and_development,
       Advertising_and_market_research,
       Other_professional_scientific_and_technical_activities,
       Veterinary_activities,
       Rental_and_leasing_activities,
       Employment_activities,
       Travel_agency_tour_operator_and_other_reservation_serviceX,
       Security_and_investigation_activities,
       Services_to_buildings_and_landscape_activities,
       Office_administrative_office_support_and_other_businessX,
       Public_administration_and_defence_compulsory_socialX,
       Education,
       Human_health_activities,
       Residential_care_activities,
       Social_work_activities_without_accommodation,
       Creative_arts_and_entertainment_activities,
       Libraries_archives_museums_and_other_cultural_activities,
       Gambling_and_betting_activities,
       Sports_activities_and_amusement_and_recreation_activities,
       Activities_of_membership_organisations,
       Repair_of_computers_and_personal_and_household_goods,
       Other_personal_service_activities,
       Activities_of_households_as_employers_of_domestic_personnel,
       Undifferentiated_goods_and_services_producing_activitiesX,
       Activities_of_extraterritorial_organisations_and_bodies
export Missing_SIC_2007

@enum SIC_2007 begin  # mapped from sic
   Missing_SIC_2007 = -1
   Undefined_SIC = 0
   Crop_and_animal_production_hunting_and_related_serviceX = 1
   Forestry_and_logging = 2
   Fishing_and_aquaculture = 3
   Mining_of_coal_and_lignite = 5
   Extraction_of_crude_petroleum_and_natural_gas = 6
   Mining_of_metal_ores = 7
   Other_mining_and_quarrying = 8
   Mining_support_service_activities = 9
   Manufacture_of_food_products = 10
   Manufacture_of_beverages = 11
   Manufacture_of_tobacco_products = 12
   Manufacture_of_textiles = 13
   Manufacture_of_wearing_apparel = 14
   Manufacture_of_leather_and_related_products = 15
   Manufacture_of_wood_and_of_products_of_wood_and_corkX = 16
   Manufacture_of_paper_and_paper_products = 17
   Printing_and_reproduction_of_recorded_media = 18
   Manufacture_of_coke_and_refined_petroleum_products = 19
   Manufacture_of_chemicals_and_chemical_products = 20
   Manufacture_of_basic_pharmaceutical_products_andX = 21
   Manufacture_of_rubber_and_plastic_products = 22
   Manufacture_of_other_non_metallic_mineral_products = 23
   Manufacture_of_basic_metals = 24
   Manufacture_of_fabricated_metal_products_except_machineryX = 25
   Manufacture_of_computer_electronic_and_optical_products = 26
   Manufacture_of_electrical_equipment = 27
   Manufacture_of_machinery_and_equipment_nec = 28
   Manufacture_of_motor_vehicles_trailers_and_semi_trailers = 29
   Manufacture_of_other_transport_equipment = 30
   Manufacture_of_furniture = 31
   Other_manufacturing = 32
   Repair_and_installation_of_machinery_and_equipment = 33
   Electricity_gas_steam_and_air_conditioning_supply = 35
   Water_collection_treatment_and_supply = 36
   Sewerage = 37
   Waste_collection_treatment_and_disposal_activitiesX = 38
   Remediation_activities_and_other_waste_management_services = 39
   Construction_of_buildings = 41
   Civil_engineering = 42
   Specialised_construction_activities = 43
   Wholesale_and_retail_trade_and_repair_of_motor_vehiclesX = 45
   Wholesale_trade_except_of_motor_vehicles_and_motorcycles = 46
   Retail_trade_except_of_motor_vehicles_and_motorcycles = 47
   Land_transport_and_transport_via_pipelines = 49
   Water_transport = 50
   Air_transport = 51
   Warehousing_and_support_activities_for_transportation = 52
   Postal_and_courier_activities = 53
   Accommodation = 55
   Food_and_beverage_service_activities = 56
   Publishing_activities = 58
   Motion_picture_video_and_television_programme_productionX = 59
   Programming_and_broadcasting_activities = 60
   Telecommunications = 61
   Computer_programming_consultancy_and_related_activities = 62
   Information_service_activities = 63
   Financial_service_activities_except_insurance_and_pensionX = 64
   Insurance_reinsurance_and_pension_funding_exceptX = 65
   Activities_auxiliary_to_financial_services_and_insuranceX = 66
   Real_estate_activities = 68
   Legal_and_accounting_activities = 69
   Activities_of_head_offices_management_consultancyX = 70
   Architectural_and_engineering_activities_technical_testingX = 71
   Scientific_research_and_development = 72
   Advertising_and_market_research = 73
   Other_professional_scientific_and_technical_activities = 74
   Veterinary_activities = 75
   Rental_and_leasing_activities = 77
   Employment_activities = 78
   Travel_agency_tour_operator_and_other_reservation_serviceX = 79
   Security_and_investigation_activities = 80
   Services_to_buildings_and_landscape_activities = 81
   Office_administrative_office_support_and_other_businessX = 82
   Public_administration_and_defence_compulsory_socialX = 84
   Education = 85
   Human_health_activities = 86
   Residential_care_activities = 87
   Social_work_activities_without_accommodation = 88
   Creative_arts_and_entertainment_activities = 90
   Libraries_archives_museums_and_other_cultural_activities = 91
   Gambling_and_betting_activities = 92
   Sports_activities_and_amusement_and_recreation_activities = 93
   Activities_of_membership_organisations = 94
   Repair_of_computers_and_personal_and_household_goods = 95
   Other_personal_service_activities = 96
   Activities_of_households_as_employers_of_domestic_personnel = 97
   Undifferentiated_goods_and_services_producing_activitiesX = 98
   Activities_of_extraterritorial_organisations_and_bodies = 99
end

#
# FIXME simplfy names
#
export Standard_Occupational_Classification  # mapped from soc2010
export Undefined_SOC,
       Managers_Directors_and_Senior_Officials,
       Professional_Occupations,
       Associate_Prof_and_Technical_Occupations,
       Admin_and_Secretarial_Occupations,
       Skilled_Trades_Occupations,
       Caring_leisure_and_other_service_occupations,
       Sales_and_Customer_Service,
       Process_Plant_and_Machine_Operatives,
       Elementary_Occupations
export Missing_Standard_Occupational_Classification

@enum Standard_Occupational_Classification begin  # mapped from soc2010
   Missing_Standard_Occupational_Classification = -1
   Undefined_SOC = 0
   Managers_Directors_and_Senior_Officials = 1000
   Professional_Occupations = 2000
   Associate_Prof_and_Technical_Occupations = 3000
   Admin_and_Secretarial_Occupations = 4000
   Skilled_Trades_Occupations = 5000
   Caring_leisure_and_other_service_occupations = 6000
   Sales_and_Customer_Service = 7000
   Process_Plant_and_Machine_Operatives = 8000
   Elementary_Occupations = 9000
end


export Tenure_Type  # mapped from tentyp2
export Council_Rented,
       Housing_Association,
       Private_Rented_Unfurnished,
       Private_Rented_Furnished,
       Mortgaged_Or_Shared,
       Owned_outright,
       Rent_free,
       Squats
export Missing_Tenure_Type,is_owner_occupier,renter, is_social_renter, is_private_renter

@enum Tenure_Type begin  # mapped from tentyp2
   Missing_Tenure_Type = -1
   Council_Rented = 1
   Housing_Association = 2
   Private_Rented_Unfurnished = 3
   Private_Rented_Furnished = 4
   Mortgaged_Or_Shared = 5
   Owned_outright = 6
   Rent_free = 7
   Squats = 8
end


"""
FIXME: should be `is_renter` for consistency.
"""
function renter(tt::Tenure_Type)::Bool
   tt < Mortgaged_Or_Shared
end

function is_owner_occupier(tt::Tenure_Type)::Bool
   tt in [Mortgaged_Or_Shared, Owned_outright]
end

function is_social_renter( tt::Tenure_Type)::Bool
   tt in [Council_Rented, Housing_Association]
end

function is_private_renter( tt::Tenure_Type)::Bool
   tt in [Private_Rented_Furnished, Private_Rented_Unfurnished]
end



export CT_Band  # mapped from ctband
export Band_A,
       Band_B,
       Band_C,
       Band_D,
       Band_E,
       Band_F,
       Band_G,
       Band_H,
       Band_I,
       Household_not_valued_separately
export Missing_CT_Band

@enum CT_Band begin  # mapped from ctband
   Missing_CT_Band = -1
   Band_A = 1
   Band_B = 2
   Band_C = 3
   Band_D = 4
   Band_E = 5
   Band_F = 6
   Band_G = 7
   Band_H = 8
   Band_I = 9
   Household_not_valued_separately = 10
end

export Disability_Type,
       Disability_Dict,
       vision,
       hearing,
       mobility,
       dexterity,
       learning,
       memory,
       mental_health,
       stamina,
       socially,
       other_difficulty

@enum Disability_Type begin  # mapped from "disd01..10" "cdisd01..10"
   vision = 1
   hearing = 2
   mobility = 3
   dexterity = 4
   learning = 5
   memory = 6
   mental_health = 7
   stamina = 8
   socially = 9
   other_difficulty = 10
end
Disability_Dict = Dict{Disability_Type,T} where T<:Real

export Incomes_Type, Incomes_Dict, Incomes_Set, Expenses

export wages,
       self_employment_income,
       self_employment_expenses,
       self_employment_losses,
       odd_jobs,
       private_pensions,
       national_savings,
       bank_interest,
       stocks_shares,
       individual_savings_account,
       # dividends,
       property,
       royalties,
       bonds_and_gilts,
       other_investment_income,
       other_income,
       alimony_and_child_support_received,
       health_insurance,
       alimony_and_child_support_paid,
       care_insurance,
       trade_unions_etc,
       friendly_societies,
       work_expenses,
       avcs,
       other_deductions,
       loan_repayments,
       student_loan_repayments,
       pension_contributions_employee,
       pension_contributions_employer,
       education_allowances,
       foster_care_payments,
       student_grants,
       student_loans,
       income_tax,
       national_insurance,
       local_taxes,
       free_school_meals,
       dlaself_care,
       dlamobility,
       child_benefit,
       pension_credit,
       state_pension,
       bereavement_allowance_or_widowed_parents_allowance_or_bereavement,
       armed_forces_compensation_scheme,
       war_widows_or_widowers_pension,
       severe_disability_allowance,
       attendance_allowance, ## FIXME SP!
       carers_allowance,
       jobseekers_allowance,
       industrial_injury_disablement_benefit,
       employment_and_support_allowance,
       incapacity_benefit,
       income_support,
       maternity_allowance,
       maternity_grant_from_social_fund,
       funeral_grant_from_social_fund,
       any_other_ni_or_state_benefit,
       trade_union_sick_or_strike_pay,
       friendly_society_benefits,
       private_sickness_scheme_benefits,
       accident_insurance_scheme_benefits,
       hospital_savings_scheme_benefits,
       government_training_allowances,
       guardians_allowance,
       widows_payment,
       unemployment_or_redundancy_insurance,
       winter_fuel_payments,
       child_winter_heating_assistance_payment,
       dwp_third_party_payments_is_or_pc,
       dwp_third_party_payments_jsa_or_esa,
       social_fund_loan_repayment_from_is_or_pc,
       social_fund_loan_repayment_from_jsa_or_esa,
       extended_hb,
       permanent_health_insurance,
       any_other_sickness_insurance,
       critical_illness_cover,
       working_tax_credit,
       child_tax_credit,
       working_tax_credit_lump_sum,
       child_tax_credit_lump_sum,
       housing_benefit,
       universal_credit,
       personal_independence_payment_daily_living,
       personal_independence_payment_mobility,
       scottish_child_payment,
       job_start_payment,
       troubles_permanent_disablement,
       child_disability_payment_care,
       child_disability_payment_mobility,
       pupil_development_grant,
    
       other_benefits

@enum Incomes_Type begin
   wages = 1
   self_employment_income = 2
   self_employment_expenses = 3
   self_employment_losses = 4
   odd_jobs = 5
   private_pensions = 6
   national_savings = 7
   bank_interest = 8
   stocks_shares = 9
   individual_savings_account = 10
   # dividends = 11 ### FIXME NOT USED NEEDS DELETED. Use stocks_shares instead
   property = 12
   royalties = 13
   bonds_and_gilts = 14
   other_investment_income = 15
   other_income = 16
   alimony_and_child_support_received = 17
   health_insurance = 18
   alimony_and_child_support_paid = 19
   care_insurance = 20
   trade_unions_etc = 21
   friendly_societies = 22
   work_expenses = 23
   avcs = 24
   other_deductions = 25
   loan_repayments = 26
   student_loan_repayments = 27
   pension_contributions_employee = 28
   pension_contributions_employer = 29
   education_allowances = 30
   foster_care_payments = 31
   student_grants = 32
   student_loans = 33
   income_tax = 34
   national_insurance = 35
   local_taxes = 36
   free_school_meals = 37

   dlaself_care = 2001
   dlamobility = 2002
   child_benefit = 2003
   pension_credit = 2004
   state_pension = 2005
   bereavement_allowance_or_widowed_parents_allowance_or_bereavement = 2006
   armed_forces_compensation_scheme = 2008
   war_widows_or_widowers_pension = 2009
   severe_disability_allowance = 2010
   attendance_allowance = 2012
   carers_allowance = 2013
   jobseekers_allowance = 2014
   industrial_injury_disablement_benefit = 2015
   employment_and_support_allowance = 2016
   incapacity_benefit = 2017
   income_support = 2019
   maternity_allowance = 2021
   maternity_grant_from_social_fund = 2022
   funeral_grant_from_social_fund = 2024
   any_other_ni_or_state_benefit = 2030
   trade_union_sick_or_strike_pay = 2031
   friendly_society_benefits = 2032
   private_sickness_scheme_benefits = 2033
   accident_insurance_scheme_benefits = 2034
   hospital_savings_scheme_benefits = 2035
   government_training_allowances = 2036
   guardians_allowance = 2037
   widows_payment = 2060
   unemployment_or_redundancy_insurance = 2061
   winter_fuel_payments = 2062
   child_winter_heating_assistance_payment = 2063
   dwp_third_party_payments_is_or_pc = 2065
   dwp_third_party_payments_jsa_or_esa = 2066
   social_fund_loan_repayment_from_is_or_pc = 2069
   social_fund_loan_repayment_from_jsa_or_esa = 2070
   extended_hb = 2078
   permanent_health_insurance = 2081
   any_other_sickness_insurance = 2082
   critical_illness_cover = 2083
   working_tax_credit = 2090
   child_tax_credit = 2091
   working_tax_credit_lump_sum = 2092
   child_tax_credit_lump_sum = 2093
   housing_benefit = 2094
   universal_credit = 2095
   personal_independence_payment_daily_living = 2096
   personal_independence_payment_mobility = 2097

   scottish_child_payment = 2112
   job_start_payment = 2115
   troubles_permanent_disablement = 2116
   child_disability_payment_care = 2121
   child_disability_payment_mobility = 2122
   pupil_development_grant = 2123

   other_benefits = 3000
end

Incomes_Dict = Dict{Incomes_Type,T} where T<:Real
Incomes_Set = Set{Incomes_Type}


export sum 

function Base.sum( i :: Incomes_Dict{T}, which :: Incomes_Set ) :: T where T <: Number
   z = zero(T)
   t = intersect( which, keys(i))
   for k in t
      v += i[k]
  end
  v
end

function ran( start :: Incomes_Type, stop :: Incomes_Type ) :: Incomes_Set
   s = Incomes_Set()
   for k in instances(Incomes_Type)
       if k >= from 
           push!(s,k)
           if k == to
               break
           end
       end
   end
   s
end

function Base.sum( i :: Incomes_Dict{T}; start :: Incomes_Type, stop :: Incomes_Type ) :: T where T <: Number
   z = zero(T)
   s = rand( start, stop )
   return sum( i, s )
end


const Expenses = Incomes_Set([
   permanent_health_insurance,
   health_insurance,
   alimony_and_child_support_paid,
   care_insurance,
   trade_unions_etc,
   friendly_societies,
   self_employment_expenses,
   work_expenses,
   pension_contributions_employee,
   pension_contributions_employer, # kinda sorta
   avcs,
   other_deductions,
   loan_repayments,
   student_loan_repayments
])

export Asset_Type, Asset_Dict, Asset_Set

export A_Current_account,
       A_NSB_Ordinary_account,
       A_NSB_Investment_account,
       A_Not_Used,
       A_Savings_investments_etc,
       A_Government_Gilt_Edged_Stock,
       A_Unit_or_Investment_Trusts,
       A_Stocks_Shares_Bonds_etc,
       A_PEP,
       A_National_Savings_capital_bonds,
       A_Index_Linked_National_Savings_Certificates,
       A_Fixed_Interest_National_Savings_Certificates,
       A_Pensioners_Guaranteed_Bonds,
       A_SAYE,
       A_Premium_bonds,
       A_National_Savings_income_bonds,
       A_National_Savings_deposit_bonds,
       A_First_Option_bonds,
       A_Yearly_Plan,
       A_ISA,
       A_Fixd_Rate_Svngs_Bonds_or_Grntd_Incm_Bonds_or_Grntd_Growth_Bonds,
       A_GEB,
       A_Basic_Account,
       A_Credit_Unions,
       A_Endowment_Policy_Not_Linked,
       A_Post_Office_Card_Account,
       A_Informal_Assets,
       A_Friendly_Society_Investment
export Missing_Asset_Type

@enum Asset_Type begin  # mapped from assetype
   Missing_Asset_Type = -1
   A_Current_account = 1
   A_NSB_Ordinary_account = 2
   A_NSB_Investment_account = 3
   A_Not_Used = 4
   A_Savings_investments_etc = 5
   A_Government_Gilt_Edged_Stock = 6
   A_Unit_or_Investment_Trusts = 7
   A_Stocks_Shares_Bonds_etc = 8
   A_PEP = 9
   A_National_Savings_capital_bonds = 10
   A_Index_Linked_National_Savings_Certificates = 11
   A_Fixed_Interest_National_Savings_Certificates = 12
   A_Pensioners_Guaranteed_Bonds = 13
   A_SAYE = 14
   A_Premium_bonds = 15
   A_National_Savings_income_bonds = 16
   A_National_Savings_deposit_bonds = 17
   A_First_Option_bonds = 18
   A_Yearly_Plan = 19
   A_ISA = 21
   A_Fixd_Rate_Svngs_Bonds_or_Grntd_Incm_Bonds_or_Grntd_Growth_Bonds = 25
   A_GEB = 26
   A_Basic_Account = 27
   A_Credit_Unions = 28
   A_Endowment_Policy_Not_Linked = 29
   A_Post_Office_Card_Account = 30
   A_Friendly_Society_Investment = 31
   A_Informal_Assets = 32
end

@enum Included_In_Pay_Type begin  # mapped from assetype
   ssp = 1
   smp = 2
   mileage = 4
   motoring_expenses = 5
   spp = 6
   sap = 7
end

Included_In_Pay_Dict = Dict{Included_In_Pay_Type,T} where T<:Real

export Included_In_Pay_Type,
   ssp,
   smp,
   mileage,
   motoring_expenses,
   spp,
   sap,
   Included_In_Pay_Dict

Asset_Dict = Dict{Asset_Type,T} where T<:Real
Asset_Set = Set{Asset_Type}

export Relationship  # mapped from relhrp
export
       This_Person,
       Spouse,
       Cohabitee,
       Son_or_daughter_incl_adopted,
       Step_son_or_daughter,
       Foster_child,
       Son_in_law_or_daughter_in_law,
       Parent,
       Step_parent,
       Foster_parent,
       Parent_in_law,
       Brother_or_sister_incl_adopted,
       Step_brother_or_sister,
       Foster_brother_or_sister,
       Brother_or_sister_in_law,
       Grand_child,
       Grand_parent,
       Other_relative,
       Other_non_relative,
       Civil_Partner,
       Missing_Relationship

@enum Relationship begin  # mapped from relhrp
   Missing_Relationship = -1
   This_Person = 0 # GKS added
   Spouse = 1
   Cohabitee = 2
   Son_or_daughter_incl_adopted = 3
   Step_son_or_daughter = 4
   Foster_child = 5
   Son_in_law_or_daughter_in_law = 6
   Parent = 7
   Step_parent = 8
   Foster_parent = 9
   Parent_in_law = 10
   Brother_or_sister_incl_adopted = 11
   Step_brother_or_sister = 12
   Foster_brother_or_sister = 13
   Brother_or_sister_in_law = 14
   Grand_child = 15
   Grand_parent = 16
   Other_relative = 17
   Other_non_relative = 18
   Civil_Partner = 20
end

export Relationship_Dict
Relationship_Dict = Dict{BigInt,Relationship}

export Employment_Type  # mapped from etype
export An_Employee,
       Running_a_business_or_prof_practice,
       Partner_in_a_business_or_practice,
       Working_for_myself,
       Sub_Contractor,
       Doing_freelance_work,
       Self_employed_in_some_other_way
export Missing_Employment_Type

@enum Employment_Type begin  # mapped from etype
   Missing_Employment_Type = -1
   An_Employee = 1
   Running_a_business_or_prof_practice = 2
   Partner_in_a_business_or_practice = 3
   Working_for_myself = 4
   Sub_Contractor = 5
   Doing_freelance_work = 6
   Self_employed_in_some_other_way = 7
end


export Employment_Sector  # mapped from jobsect
export Private, Public
export Missing_Employment_Sector

@enum Employment_Sector begin  # mapped from jobsect
   Missing_Employment_Sector = -1
   Private = 1
   Public = 2
end

export Account_Type  # mapped from account
export Current_account,
       NSB_Direct_Saver,
       NSB_Investment_account,
       Not_Used,
       Savings_investments_etc,
       Government_Gilt_Edged_Stock,
       Unit_or_Investment_Trusts,
       Stocks_Shares_Bonds_etc,
       PEP,
       National_Savings_capital_bonds,
       Index_Linked_National_Savings_Certificates,
       Fixed_Interest_National_Savings_Certificates,
       Pensioners_Guaranteed_Bonds,
       SAYE,
       Premium_bonds,
       National_Savings_income_bonds,
       National_Savings_deposit_bonds,
       First_Option_bonds,
       Yearly_Plan,
       ISA,
       Profit_sharing,
       Company_Share_Option_Plans,
       Member_of_Share_Club,
       Fixed_Rate_Savings_or_Guaranteed_Income_or_Guaranteed_Growth_Bonds,
       Guaranteed_Equity_Bond,
       Basic_Account,
       Credit_Unions,
       Endowment_Policy_Not_Linked,
       Post_Office_Card_Account,
       Friendly_Society_Investment,
       Informal_Assets
export Missing_Account_Type

@enum Account_Type begin  # mapped from account
   Missing_Account_Type = -1
   Current_account = 1
   NSB_Direct_Saver = 2
   NSB_Investment_account = 3
   Not_Used = 4
   Savings_investments_etc = 5
   Government_Gilt_Edged_Stock = 6
   Unit_or_Investment_Trusts = 7
   Stocks_Shares_Bonds_etc = 8
   PEP = 9
   National_Savings_capital_bonds = 10
   Index_Linked_National_Savings_Certificates = 11
   Fixed_Interest_National_Savings_Certificates = 12
   Pensioners_Guaranteed_Bonds = 13
   SAYE = 14
   Premium_bonds = 15
   National_Savings_income_bonds = 16
   National_Savings_deposit_bonds = 17
   First_Option_bonds = 18
   Yearly_Plan = 19
   ISA = 21
   Profit_sharing = 22
   Company_Share_Option_Plans = 23
   Member_of_Share_Club = 24
   Fixed_Rate_Savings_or_Guaranteed_Income_or_Guaranteed_Growth_Bonds = 25
   Guaranteed_Equity_Bond = 26# Guaranteed/Fixed rate E bond
   Basic_Account = 27
   Credit_Unions = 28
   Endowment_Policy_Not_Linked = 29
   Post_Office_Card_Account = 30
   Friendly_Society_Investment = 31
   Informal_Assets = 32
end


export Account_Tax_Status  # mapped from invtax
export After_tax, Before_tax
export Missing_Account_Tax_Status

@enum Account_Tax_Status begin  # mapped from invtax
   Missing_Account_Tax_Status = -1
   After_tax = 1
   Before_tax = 2
end

export Benefit_Type  # mapped from benefit
export DLAself_care,
       DLAmobility,
       Child_Benefit,
       Pension_credit,
       State_Pension,
       Bereavement_Allowance_or_Widowed_Parents_Allowance_or_Bereavement,
       Armed_Forces_Compensation_Scheme,
       War_Widows_or_Widowers_Pension,
       Severe_Disability_Allowance,
       Attendance_Allowance,
       Carers_Allowance,
       Jobseekers_Allowance,
       Industrial_Injury_Disablement_Benefit,
       Employment_and_Support_Allowance,
       Incapacity_Benefit,
       Income_Support,
       Maternity_Allowance,
       Maternity_Grant_from_Social_Fund,
       Funeral_Grant_from_Social_Fund,
       Any_other_NI_or_State_benefit,
       Trade_Union_sick_or_strike_pay,
       Friendly_Society_Benefits,
       Private_sickness_scheme_benefits,
       Accident_insurance_scheme_benefits,
       Hospital_savings_scheme_benefits,
       Government_training_allowances,
       Guardians_Allowance,
       Widows_Payment,
       Unemployment_or_Redundancy_Insurance,
       Winter_Fuel_Payments,
       Child_Winter_Heating_Assistance_Payment,
       DWP_third_party_payments_IS_or_PC,
       DWP_third_party_payments_JSA_or_ESA,
       Social_Fund_Loan_Repayment_from_IS_or_PC,
       Social_Fund_Loan_Repayment_from_JSA_or_ESA,
       Extended_HB,
       Permanent_health_insurance,
       Any_other_sickness_insurance,
       Critical_Illness_Cover,
       Working_Tax_Credit,
       Child_Tax_Credit,
       Working_Tax_Credit_Lump_Sum,
       Child_Tax_Credit_Lump_Sum,
       Housing_Benefit,
       Universal_Credit,
       Personal_Independence_Payment_Daily_Living,
       Personal_Independence_Payment_Mobility,
       A_loan_from_the_DWP_and_DfC,
       A_loan_or_grant_from_local_authority,
       Future_Pension_Credit,
       Future_Universal_Credit,
       Future_Housing_Benefit,
       Future_Working_Tax_Credit,
       Future_Child_Tax_Credit,
       Future_Income_Support,
       Future_Jobseekers_Allowance,
       Future_Employment_and_Support_Allowance,
       DWP_third_party_payments_UC,
       Social_Fund_Loan_UC,
       DWP_Third_Party_Payments_V2, # 2019 -
       Repayment_UC_Advance, # 2019- 
       Advance_of_UC, # 2019 -
       Job_Start_Payment,
       Troubles_Permanent_Disablement,
       Child_Disability_Payment_Care,
       Child_Disability_Payment_Mobility,
       Pupil_Development_Grant
        
export Missing_Benefit_Type

@enum Benefit_Type begin  # mapped from benefit
   Missing_Benefit_Type = -1
   DLAself_care = 1
   DLAmobility = 2
   Child_Benefit = 3
   Pension_credit = 4
   State_Pension = 5
   Bereavement_Allowance_or_Widowed_Parents_Allowance_or_Bereavement = 6
   Armed_Forces_Compensation_Scheme = 8
   War_Widows_or_Widowers_Pension = 9
   Severe_Disability_Allowance = 10
   Attendance_Allowance = 12
   Carers_Allowance = 13
   Jobseekers_Allowance = 14
   Industrial_Injury_Disablement_Benefit = 15
   Employment_and_Support_Allowance = 16
   Incapacity_Benefit = 17
   Income_Support = 19
   Maternity_Allowance = 21
   Maternity_Grant_from_Social_Fund = 22
   Funeral_Grant_from_Social_Fund = 24
   Any_other_NI_or_State_benefit = 30
   Trade_Union_sick_or_strike_pay = 31
   Friendly_Society_Benefits = 32
   Private_sickness_scheme_benefits = 33
   Accident_insurance_scheme_benefits = 34
   Hospital_savings_scheme_benefits = 35
   Government_training_allowances = 36
   Guardians_Allowance = 37
   Widows_Payment = 60
   Unemployment_or_Redundancy_Insurance = 61
   Winter_Fuel_Payments = 62
   Child_Winter_Heating_Assistance_Payment = 63
   DWP_third_party_payments_IS_or_PC = 65
   DWP_third_party_payments_JSA_or_ESA = 66
   Social_Fund_Loan_Repayment_from_IS_or_PC = 69
   Social_Fund_Loan_Repayment_from_JSA_or_ESA = 70
   Extended_HB = 78
   Permanent_health_insurance = 81
   Any_other_sickness_insurance = 82
   Critical_Illness_Cover = 83
   Working_Tax_Credit = 90
   Child_Tax_Credit = 91
   Working_Tax_Credit_Lump_Sum = 92
   Child_Tax_Credit_Lump_Sum = 93
   Housing_Benefit = 94
   Universal_Credit = 95
   Personal_Independence_Payment_Daily_Living = 96
   Personal_Independence_Payment_Mobility = 97
   A_loan_from_the_DWP_and_DfC = 98
   A_loan_or_grant_from_local_authority = 99
   Future_Pension_Credit = 102
   Future_Universal_Credit = 103
   Future_Housing_Benefit = 104
   Future_Working_Tax_Credit = 105
   Future_Child_Tax_Credit = 106
   Future_Income_Support = 107
   Future_Jobseekers_Allowance = 108
   Future_Employment_and_Support_Allowance = 109
   DWP_third_party_payments_UC = 110
   Social_Fund_Loan_UC = 111
   DWP_Third_Party_Payments_V2 = 1112 # 2019- no idea what this is
   Repayment_UC_Advance = 113 # 2019- 
   Advance_of_UC = 114 # 2019 -
   Scottish_Child_Payment = 112
   Job_Start_Payment = 115
   Troubles_Permanent_Disablement = 116
   Child_Disability_Payment_Care = 121
   Child_Disability_Payment_Mobility = 122
   Pupil_Development_Grant = 123


end


export Child_Care_Type  # mapped from chlook
export Playgroup_or_pre_school,
       Day_nursery_or_crèche,
       Nursery_school,
       Nursery_class_attached_to_Primary_or_Infants_School,
       Reception_class_at_Primary_or_Infants_School,
       Breakfast_club,
       After_school_club_or_activities,
       Holiday_scheme_or_club,
       Special_day_school_or_nursery_unit_for_children_with_special_ed,
       Other_formal,
       Grand_parents,
       Non_resident_parent_or_ex_spouse_or_ex_partner,
       Childd_brother_or_sister,
       Other_relatives,
       Childminder,
       Nanny_or_Au_Pair,
       Friends_or_neighbours,
       Other_non_relatives_includes_babysitters
export Missing_Child_Care_Type

@enum Child_Care_Type begin  # mapped from chlook
   Missing_Child_Care_Type = -1
   Playgroup_or_pre_school = 1
   Day_nursery_or_crèche = 2
   Nursery_school = 3
   Nursery_class_attached_to_Primary_or_Infants_School = 4
   Reception_class_at_Primary_or_Infants_School = 5
   Breakfast_club = 6
   After_school_club_or_activities = 7
   Holiday_scheme_or_club = 8
   Special_day_school_or_nursery_unit_for_children_with_special_ed = 9
   Other_formal = 10
   Grand_parents = 11
   Non_resident_parent_or_ex_spouse_or_ex_partner = 12
   Childs_brother_or_sister = 13
   Other_relatives = 14
   Childminder = 15
   Nanny_or_Au_Pair = 16
   Friends_or_neighbours = 17
   Other_non_relatives_includes_babysitters = 18
end

export Fuel_Type  # mapped from fueltyp
export Petrol, Diesel, Biofuel_eg_E85_fuel, Hybrid_use_a_combination_of_petrol_and_electricity, Electric, LPG, Other, Dont_know
export No_Fuel, Missing_Fuel_Type, Fuel_Type_Dict

@enum Fuel_Type begin  # mapped from fueltyp
   Missing_Fuel_Type = -1
   No_Fuel = 0
   Petrol = 1
   Diesel = 2
   Biofuel_eg_E85_fuel = 3
   Hybrid_use_a_combination_of_petrol_and_electricity = 4
   Electric = 5
   LPG = 6
   Other = 7
   Dont_know = 8
end

const Fuel_Type_Dict = Dict{Fuel_Type,T} where T <: Number

export
   Uprate_Item_Type,
   upr_no_uprate,
   upr_earnings,
   upr_housing_rents,
   upr_housing_oo,
   upr_unearned,
   upr_costs,
   upr_cpi,
   upr_gdp_deflator,
   upr_nominal_gdp,
   upr_shares

@enum Uprate_Item_Type begin
    upr_no_uprate
    upr_earnings
    upr_housing_rents
    upr_housing_oo
    upr_unearned
    upr_costs
    upr_cpi
    upr_gdp_deflator
    upr_nominal_gdp
    upr_shares
end

@enum JSAType begin
    no_jsa = -1
    contributory_jsa = 1 
    income_related_jsa =2 
    both_jsa = 3
end
# FIXME we also use this for ESA, which makes the names confusing
export JSAType, contributory_jsa, income_related_jsa, both_jsa, no_jsa

@enum LMTBenefitType esa hb ctr is jsa pc wtc ctc sc 
const LMTBenefitSet = Set{LMTBenefitType}
export LMTBenefitType, esa, hb, ctr, is, jsa, pc, wtc, ctc, sc, LMTBenefitSet

@enum LMTPremia  begin
   family_premium = 1
   disabled_child = 2
   severe_disability_single = 3
   severe_disability_couple = 4
   carer_single = 5
   carer_couple = 6
   enhanced_disability_child = 7
   enhanced_disability_single = 8
   enhanced_disability_couple = 9
   disability_single = 10
   disability_couple = 11
   pensioner_is = 12
end  

const LMTPremiaDict = Dict{LMTPremia,T} where T <:Real
const LMTPremiaSet = Set{LMTPremia}

export LMTPremia,LMTPremiaDict, LMTPremiaSet, disabled_child,
    severe_disability_single,severe_disability_couple,
    carer_single,carer_couple,enhanced_disability_child,
    enhanced_disability_single,enhanced_disability_couple,disability_single,disability_couple,pensioner_is

export BIG_NOTHING
const BIG_NOTHING = BigInt(0)

export DataSource, FRS, OtherSource, ExampleSource

@enum DataSource begin  # mapped from relhrp
   FRS = 1
   OtherSource = 2
   ExampleSource = 3
end

export get_pid, safe_assign, safe_inc, from_pid
"""
  get a unique ID for a person from (say) a certain year of the FRS, given hhld number and number inside the household
"""
function get_pid(source::DataSource, year::Integer, hid::Integer, pno::Integer)::BigInt
   (Int(source) * 10^11) + (year * 10^7) + (hid * 10^2) + pno
end

function from_pid( pid :: Integer ) :: NamedTuple
   ids = extract_digits( pid, 1:1 ) 
   source = DataSource(ids)
   year = extract_digits(pid, 2:5)
   hid = extract_digits( pid, 6:10)
   pno = extract_digits( pid, 11:12)
   return (datasource=source, year=year, hid=hid, pno=pno )
end

export DEFAULT_MISSING_VALUES, safe_inc

const DEFAULT_MISSING_VALUES = [-9.0, -8.0, -7.0, -6.0, -5.0, -4.0, -3.0, -2.0, -1.0]

"""
a = a+b if b is not missing or (-9 to -1), else a
"""
function safe_inc(a::Real, b::Union{Real,Missing})::Real
   if ismissing(b) || (b in DEFAULT_MISSING_VALUES)
      return a
   end
   a + b
end

"""
map missing values or (-9 to -2) to -1, else a
used for mapping values to enums, where we add a missing enum with value -1
"""
function safe_assign(a::Union{Number,Missing,AbstractString},deflt=-1)   
   if ismissing(a)
      return deflt
   elseif typeof(a) <: AbstractString
      a = tryparse( typeof( deflt ), a )
      if a === nothing
         return deflt
      end
   end
   if a < -1
      return deflt
   end
   return a
end

export make_sym_for_frame, make_sym_for_asset, make_sym_from_frame
"""
"income", :fred => :income_fred
"""
function make_sym_for_frame(prefix::AbstractString, enum::Enum)::Symbol
    sym = Symbol(enum)
    Symbol(lowercase(prefix * "_" * String(Symbol(sym))))
end

"""
"income", :a_fred => :income_fred
"""
function make_sym_for_asset(enum::Enum)::Symbol
    s = String(Symbol(enum))[3:end]
   # println( "s=$s")
    Symbol(lowercase("asset_" * s))
end

"""
"income", :income_fred => :fred
"""
function make_sym_from_frame(prefix::AbstractString, sym::Symbol)::Symbol
   # FIXME got to be a simpler way
    matchstr = "$(prefix)(.*)"
    re = Regex(matchstr)
    rm = match(re, String(sym))
    Symbol(rm[1])
end

export safe_to_bool, m2z

function safe_to_bool( thing ) :: Bool
   ty = typeof( thing )
   if ty == Bool
      return thing
   end
   if ismissing( thing )
      return false
   end
   if ty <: Number
      return thing == 1
   end
   return false
end

function m2z( s )
   if ismissing( s )
      return 0
   end
   s
end

export 
   age_range,
   age_ends,
   age_str

#
# FIXME this is a dup of the thing in `weights`
#
const age_ends = [4,9,14,19,24,29,34,39,44,49,54,59,64,69,74,79,99999]

function age_str( band )
   a2 = "$(age_ends[band])"
   a1 = ""
   if band==1
      a1 = "0"
   elseif band==lastindex(age_ends)
      return "$(age_ends[band-1]+1) and above"
   else
      a1 = "$(age_ends[band-1]+1)"
   end
   return "$(a1)-$(a2)"
end

function age_range( age :: Integer ) :: Integer
   for a in eachindex(age_ends)
      if age <= age_ends[a]
         return a
      end
   end
end


#
# This is for quick lookups of hhld/people by hid/pid
# you need the `isequal`/`hash` to make sure `Dict`s can use these
# as keys.

export OneIndex, in_indexes
struct OneIndex 
   id :: BigInt
   data_year :: Int  
end

function in_indexes( s :: Set{OneIndex}, id :: BigInt, data_year:: Int)
   return OneIndex( id, data_year ) in s
end

function in_indexes( s :: Set{OneIndex}, id :: BigInt )
   # this is silly ...
   bits = from_pid( id )
   return in_indexes( s, id, bits.year )
end

Base.isequal( a :: OneIndex, b :: OneIndex ) = (a.id==b.id)&&(a.data_year == b.data_year )

Base.hash( a :: OneIndex ) = UInt64(a.id*1000)+UInt64(a.data_year)

function Base.isless( a :: OneIndex, b :: OneIndex )
   if b.data_year > a.data_year
       return true
   elseif b.data_year < a.data_year
       return false
   else
       return b.id > a.id
   end
end

export UBIMTBenTreatment,
   ub_as_is, 
   ub_abolish, 
   ub_keep_housing

@enum UBIMTBenTreatment ub_as_is ub_abolish ub_keep_housing

# Dan's entitlement stuff
export UBEntitlement,
   ub_ent_all,
   ub_ent_all_but_non_jobseekers,
   ub_ent_only_in_work,
   ub_ent_only_not_in_work

@enum UBEntitlement ub_ent_all ub_ent_all_but_non_jobseekers ub_ent_only_in_work ub_ent_only_not_in_work
 #=
    People in and out of work are entitled
Everyone is entitled but people of working age who are not disabled are required to look for work
Only people in work are entitled
Only people out of work are entitled 
   =#

# Dan's citizenship
export UBCitizenship,
   ub_cit_all, # ish ..
   ub_cit_plus_perm_res,
   ub_cit_only

@enum UBCitizenship ub_cit_all ub_cit_plus_perm_res ub_cit_only

#=
Citizens, permanent residents and anyone residing in the UK for more than six months are entitled
Only citizens and permanent residents are entitled
Only citizens are entitled 
=#

#
# wealth tax
#

export WealthTypes,net_physical_wealth,net_financial_wealth,
   net_housing_wealth,net_pension_wealth,WealthSet

@enum WealthTypes net_physical_wealth net_financial_wealth net_housing_wealth net_pension_wealth
WealthSet = Set{WealthTypes}

export AggregationLevel, individual, benefit_unit, household 

@enum AggregationLevel begin
   individual
   benefit_unit
   household 
end

end # module
