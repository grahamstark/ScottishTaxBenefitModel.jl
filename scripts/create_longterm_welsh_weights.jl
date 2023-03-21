#
# HORRIBLE HACK ALL NEEDS REFACTORED
#
using ScottishTaxBenefitModel
using .RunSettings
using .FRSHouseholdGetter
using .Weighting
using .Definitions
using .ModelHousehold
using DataFrames

using SurveyDataWeighting: 
    DistanceFunctionType, 
    chi_square,
    constrained_chi_square,
    d_and_s_constrained,
    d_and_s_type_a,
    d_and_s_type_b,
    do_reweighting

include( joinpath(SRC_DIR,"targets","wales-2023.jl"))

settings = Settings()
settings.benefit_generosity_estimates_available = false
settings.household_name = "model_households_wales"
settings.people_name    = "model_people_wales"
settings.lower_multiple = 0.2
settings.upper_multiple = 5.0

@time nhhx, num_peoplex, nhh2x = initialise( settings; reset=true )

include( joinpath(SRC_DIR,"targets","wales-longterm.jl"))

nrs = nhhx*21
d = DataFrame( 
        hid=fill(0, nrs ), 
        data_year = fill(0, nrs ),
        year = fill( 0, nrs ),
        weight = zeros( nrs )
    )

popn = loaddf()
p = 0
for year in 2020:2040
    ytargets = onerow( popn, year )
    println( ytargets )
    w = generate_weights_xx( 
        nhhx;
        weight_type = constrained_chi_square,
        lower_multiple = settings.lower_multiple,
        upper_multiple = settings.upper_multiple,
        targets = ytargets
    )
    for n in 1:nhhx 
        global p
        mhh = get_household( n )
        p += 1
        r = d[p,:]
        r.hid = mhh.hid
        r.data_year = mhh.data_year
        r.weight = w[n]
        r.year = year
    end
    println( "Weights for year $year = $w" )
end

d



