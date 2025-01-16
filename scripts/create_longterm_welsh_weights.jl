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

settings = Settings()
settings.benefit_generosity_estimates_available = false
settings.household_name = "model_households_wales"
settings.people_name    = "model_people_wales"
settings.lower_multiple = 0.2
settings.upper_multiple = 5.0
settings.aweightinhg_strategy = use_runtime_computed_weights

@time nhhx, num_peoplex, nhh2x = initialise( settings; reset=true )

nrs = nhhx*21
d = DataFrame( 
        hid=fill(0, nrs ), 
        data_year = fill(0, nrs ),
        year = fill( 0, nrs ),
        weight = zeros( nrs )
    )

p = 0
for year in 2020:2040
    targets, household_total = one_years_targets_wales( year )
    println( targets )
    w = generate_weights( 
        nhhx;
        weight_type = constrained_chi_square,
        lower_multiple = settings.lower_multiple,
        upper_multiple = settings.upper_multiple,
        household_total = household_total,
        targets = targets,
        initialise_target_dataframe = initialise_target_dataframe_wales_longterm,
        make_target_row! = make_target_row_wales_longerm!
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
    # println( "Weights for year $year = $w" )
end

du = unstack(d, :year, :weight )
CSV.write( "/home/graham_s/tmp/wales_weights_by_year.csv", du )