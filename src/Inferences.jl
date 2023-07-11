#
# this module is a container for all the wild guesses
# we have to make on e.g. Wealth, Benefit Generosity and Health
# currently some things are in their own packages [HealthRegressions]
# TODO: move all the regressions in here.
# TODO: there must be a more general way.
#
module Inferences

using ScottishTaxBenefitModel
using .Definitions
using .ModelHousehold

"""
Insert a wealth value in the vacant hhld slot. 
See the wealth_regressions.jl in `regressions` folder.
FIXME: note this *doesn't* depend on income for now.
FIXME: indexing/uprating needs thought.
"""
function infer_wealth!( hh :: Household )
    c =  [
        "(Intercept)"          9.60123
        "north_west"           0.0625833
        "yorkshire"            0.0644574
        "east_midlands"        0.1236
        "west_midlands"        0.116029
        "east_of_england"      0.364842
        "london"               0.538478
        "south_east"           0.481941
        "south_west"           0.341577
        "wales"                0.0879198
        "scotland"             0.185351
        "owner"                2.01444
        "mortgaged"            1.68485
        "detatched"            0.355151
        "semi"                 0.0504565
        "terraced"            -0.0868402
        "purpose_build_flat"  -0.0861793
        "HBedrmr7"             0.263676
        "hrp_u_25"            -1.11464
        "hrp_u_35"            -0.800181
        "hrp_u_45"            -0.341497
        "hrp_u_55"             0.0183485
        "hrp_u_65"             0.322276
        "hrp_u_75"             0.259357
        "managerial"           0.676127
        "intermediate"         0.329747
        "num_adults"           0.103515
        "num_children"        -0.0568348 ]
    

    hrp = get_head( hh )

       v = ["(Intercept)"           1
    "north_west"        hh.region == North_West ? 1 : 0
    "yorkshire"         hh.region == Yorks_and_the_Humber ? 1 : 0
    "east_midlands"        hh.region == East_Midlands ? 1 : 0
    "west_midlands"        hh.region == West_Midlands ? 1 : 0
    "east_of_england"      hh.region == East_of_England ? 1 : 0
    "london"               hh.region == London ? 1 : 0
    "south_east"           hh.region == South_East ? 1 : 0
    "south_west"           hh.region == South_West ? 1 : 0
    "wales"                hh.region == Wales ? 1 : 0
    "scotland"             hh.region == Scotland ? 1 : 0   
    "owner"                hh.tenure == Owned_outright ? 1 : 0
    "mortgaged"            hh.tenure == Mortgaged_Or_Shared ? 1 : 0
    "detatched"                 hh.dwelling == detatched ? 1 : 0
    "semi"                      hh.dwelling == semi_detached ? 1 : 0
    "terraced"                  hh.dwelling == terraced ? 1 : 0
    "purpose_build_flat"        hh.dwelling == flat_or_maisonette ? 1 : 0
    "HBedrmr7"                  hh.bedrooms
    "hrp_u_25"                  hrp.age < 25 ? 1 : 0
    "hrp_u_35"                  hrp.age in 25:34 ? 1 : 0
    "hrp_u_45"                  hrp.age in 35:44 ? 1 : 0
    "hrp_u_55"                  hrp.age in 45:54 ? 1 : 0
    "hrp_u_65"                  hrp.age in 55:64 ? 1 : 0
    "hrp_u_75"                  hrp.age in 65:74 ? 1 : 0
    "managerial"                hrp.socio_economic_grouping in [
        Employers_in_large_organisations,
        Higher_managerial_occupations,
        Higher_professional_occupations_New_self_employed,
        Higher_supervisory_occupations,
        Employers_in_small_organisations_non_professional,
        Lower_managerial_occupations,Intermediate_clerical_and_administrative,
        Lower_supervisory_occupations
         ] ? 1 : 0
    "intermediate"              hrp.socio_economic_grouping in [
        Lower_technical_craft,
        Semi_routine_sales,
        Routine_sales_and_service  
        ] ? 1 : 0
    "num_adults"           num_adults(hh)
    "num_children"         num_children(hh)
        ]
    wealth = max(0.0, exp( c[:,2]'v[:,2]))
    hh.total_wealth = wealth
    return v
end


end # module