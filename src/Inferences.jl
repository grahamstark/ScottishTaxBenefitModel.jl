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
    c =  ["(Intercept)"         11.5217
    "north_west"           0.0672303
    "yorkshire"            0.0497986
    "east_midlands"        0.0770983
    "west_midlands"        0.122249
    "east_of_england"      0.337285
    "london"               0.791592
    "south_east"           0.484205
    "south_west"           0.290802
    "wales"                0.0551278
    "scotland"             0.124095
    "owner"                0.357653
    "detatched"            0.179522
    "semi"                -0.136554
    "terraced"            -0.265704
    "purpose_build_flat"  -0.175543
    "HBedrmr7"             0.276718
    "hrp_u_25"            -1.04961
    "hrp_u_35"            -0.836553
    "hrp_u_45"            -0.269733
    "hrp_u_55"             0.131253
    "hrp_u_65"             0.394099
    "hrp_u_75"             0.29878
    "managerial"           0.535079
    "intermediate"         0.223264
    "num_adults"           0.0657891
    "num_children"        -0.044644]

    hrp = get_head( hh )

       v = ["(Intercept)"           1
    "north_west"        hh.region == North_West ? 1 : 0
    "yorkshire"         hh.region == Yorks_and_the_Humber ? 1 : 0
    "east_midlands"        hh.region == East_Midlands ? 1 : 0
    "west_midlands"        hh.region == West_Midlands ? 1 : 0
    "east_of_england"      hh.region == East_of_England ? 1 : 0
    "london"               hh.region == East_of_London ? 1 : 0
    "south_east"           hh.region == South_East ? 1 : 0
    "south_west"           hh.region == South_West ? 1 : 0
    "wales"                hh.region == Wales ? 1 : 0
    "scotland"             hh.region == Scotland ? 1 : 0   
    "owner"                     hh.tenure == Owned_outright ? 1 : 0
    "detatched"                 hh.dwelling == detatched ? 1 : 0
    "semi"                      hh.dwelling == semi_detached ? 1 : 0
    "terraced"                  hh.dwelling == terraced ? 1 : 0
    "purpose_build_flat"        hh.dwelling == flat_or_maisonette ? 1 : 0
    "HBedrmr7"                  hh.bedrooms
    "hrp_u_25"                  hrp.age < 25 ? 1 : 0
    "hrp_u_35"                  hrp.age in [25:44] ? 1 : 0
    "hrp_u_45"                  hrp.age in [45:54] ? 1 : 0
    "hrp_u_55"                  hrp.age in [55:64] ? 1 : 0
    "hrp_u_65"                  hrp.age in [65:74] ? 1 : 0
    "hrp_u_75"                  hrp.age in [75:999] ? 1 : 0
    "managerial"                hrp.socio_economic_grouping in [Managers_Directors_and_Senior_Officials,Professional_Occupations] ? 1 : 0
    "intermediate"              hrp.socio_economic_grouping in [Associate_Prof_and_Technical_Occupations,Admin_and_Secretarial_Occupations] ? 1 : 0
    "num_adults"           num_adults(hh)
    "num_children"         num_children(hh)
        ]
    wealth = max(0.0, exp( c[:,2]'v[:,2]))
    hh.total_wealth = wealth
end


end # module