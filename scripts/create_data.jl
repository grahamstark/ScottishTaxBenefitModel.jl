using ScottishTaxBenefitModel
using .Utils
using .Definitions

println( "MODEL_DATA_DIR=$(MODEL_DATA_DIR) HBAI_DIR=$(HBAI_DIR)" )
include( "../src/HouseholdMappingFRS_Only.jl")
create_data(start_year=2015, end_year=2021 ) # , hbai="i2122e_2122prices")
# include( "hack_regions_to_councils.jl")
