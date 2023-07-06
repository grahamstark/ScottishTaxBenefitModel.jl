using ScottishTaxBenefitModel
using .Utils
using .Definitions

println( "MODEL_DATA_DIR=$(MODEL_DATA_DIR) HBAI_DIR=$(HBAI_DIR)" )
include( "../src/HouseholdMappingFRS_HBAI.jl")
create_data(start_year=2021, end_year=2021, hbai="i2122e_2122prices")
