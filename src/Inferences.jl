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

using CSV
using DataFrames

export add_wealth_to_dataframes!

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

const RENAMES =  Dict( # "log(weekly_gross_income)"=>"log_weekly_gross_income",
        "(Intercept)"=>"cons" )


function load_reg( filename :: String ) :: DataFrameRow
    reg = CSV.File( "data/2023-4/uk_wealth_regressions/$(filename).tab")|>DataFrame
    tr_reg = unstack(reg[!,[1,2]],1,2)
    rename!( tr_reg, RENAMES )
    tr_reg[1,:]
end

const WEALTH_REG_NAMES = ["is_in_debt", "net_financial", "net_debt", "net_physical", "has_pension", "total_pensions", "net_housing"]

function load_all_regs()::Dict
    tt = Dict()
    for r in WEALTH_REG_NAMES
        tt[r] = load_reg( r )
    end
    tt
end


"""
As above but with a pre-computed set of names in common and a pre-computed coefficient vector
"""
function rowmul( 
    names :: Vector{Symbol}, 
    d1 :: DataFrameRow, 
    v2 ::Vector{Float64} )::Float64
    v1 = Vector(d1[names])
    println( [names v1 v2])
    v1'*v2
end



function add_wealth_to_dataframes!( hhr:: DataFrame, hh :: DataFrame )
    WEALTH_REGS = load_all_regs()
    
    hhp = hhr[ hhr.is_hrp .== 1, : ] # 1 per hhld
    println( "hhp loaded $(size(hhp))")
    
    ncs = Dict()
    coefs = Dict()
    for r in WEALTH_REG_NAMES
       ncs[r] = Symbol.(intersect( names(hhp), names(WEALTH_REGS[r])))
       println( "$r : made coefs names as $(ncs[r])")
       coefs[r] = Vector{Float64}( WEALTH_REGS[r] )
       println( "$r : made coef vals as $(coefs[r])")
    end
    k = 0
    for hrow in eachrow( hhp )
        k += 1
        if k == 10
           break
        end
        p = (hh.hid .== hrow.hid).&(hh.data_year .== hrow.data_year)
        # println( "got outrow = ", hh[p,[:hid,:region]] )
        pw = rowmul( ncs["has_pension"], hrow,  coefs["has_pension"])
        # if pw >= 0 # so, probit > 0.5 - infer pension wealth
            w = rowmul( ncs[ "total_pensions"], hrow, coefs["total_pensions"])
            hh[p,:net_pension_wealth] .= w # exp(w)
        # end
        if hrow.owner == 1 || hrow.mortgaged == 1
            w = rowmul( ncs[ "net_housing"], hrow, coefs["net_housing"])
            hh[p,:net_housing_wealth] .= w # exp(w)
        end
        is_in_debt = rowmul( ncs["is_in_debt"], hrow,  coefs["is_in_debt"])
        target =  "net_financial"
        m  = 1.0
        if is_in_debt >= 0
            m = -1
            target = "net_debt"
        end
        w = rowmul( ncs[target], hrow, coefs[target])
        hh[p,:net_financial_wealth] .= m*(exp(w ))
        w = rowmul( ncs["net_physical"], hrow, coefs["net_physical"])
        # println( "log physical wealth $w")
        hh[p,:net_physical_wealth] .= w # exp(w)
        #
        # also back into hrp 
        # 
        hrow.net_pension_wealth = hh[p,:net_pension_wealth][1]
        hrow.net_financial_wealth = hh[p,:net_financial_wealth][1]
        hrow.net_physical_wealth = hh[p,:net_physical_wealth][1]
        hrow.net_housing_wealth = hh[p,:net_housing_wealth][1]
        # println( "row ",hh[p,[:net_pension_wealth,:net_physical_wealth,:net_financial_wealth,:net_housing_wealth]])
    end # each row    
end # function add_wealth_to_dataframes!

end # module