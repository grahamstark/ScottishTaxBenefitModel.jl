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

@time nhhx, num_peoplex, nhh2x = initialise( settings; reset=true )

f = open( "tmp/wales_weights.csv","w")
println( f, "hid,data_year,weight")
for hno in 1:nhhx
    mhh = get_household( hno )
    println( f, "$(mhh.hid),$(mhh.data_year),$(mhh.weight)")
end
close(f)



