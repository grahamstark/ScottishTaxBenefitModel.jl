#
# 
#
using ScottishTaxBenefitModel
using .RunSettings
using .FRSHouseholdGetter
using .Weighting
using .Definitions
using .ModelHousehold
using DataFrames

include( joinpath(SRC_DIR,"targets","wales-2023.jl"))

settings = Settings()
settings.benefit_generosity_estimates_available = false
settings.household_name = "model_households_wales"
settings.people_name    = "model_people_wales"
settings.lower_multiple = 0.275
settings.upper_multiple = 4.0
settings.target_nation = N_Wales

@time nhhx, num_peoplex, nhh2x = initialise( settings; reset=true )

@time weight = generate_weights( 
                nhhx;
                weight_type = settings.weight_type,
                lower_multiple = settings.lower_multiple,
                upper_multiple = settings.upper_multiple,
                hoiusehold_total=NUM_HOUSEHOLDS_WALES_2023,
                targets=DEFAULT_TARGETS_WALES_2023,
                initialise_target_dataframe=initialise_target_dataframe_wales_2023,
                make_target_row!=make_target_row_wales_2023! )

f = open( "tmp/wales_weights.csv","w")



println( f, "hid,data_year,weight")
for hno in 1:nhhx
    mhh = get_household( hno )
    println( f, "$(mhh.hid),$(mhh.data_year),$(mhh.weight)")
end
close(f)



