#
# A container for all the wild guesses
# we have to make on e.g. Wealth, Benefit Generosity and Health
# currently some things are in their own packages [HealthRegressions]
# TODO: move all the regressions in here.
# TODO: there must be a more general way.
#

using ScottishTaxBenefitModel
using .Definitions
using .ModelHousehold

using CSV
using DataFrames
using Distributions 
export add_wealth_to_dataframes!


const RENAMES =  Dict( [
    "log(weekly_gross_income)"=>"log_weekly_gross_income",
    "(Intercept)"=>"cons" ])


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
    # println( [names v1 v2])
    v1'*v2
end

stderrs = Dict(
    "net_financial"=>0.754930602845524


)

nrand(sd) = rand(Normal( 0.0, sd ))

function add_wealth_to_dataframes!( hhr:: DataFrame, hh :: DataFrame )
    WEALTH_REGS = load_all_regs()
    
    hhp = hhr[ hhr.is_hrp .== 1, : ] # 1 per hhld
    println( "hhp loaded $(size(hhp))")
    
    ncs = Dict()
    coefs = Dict()
    for r in WEALTH_REG_NAMES
       ncs[r] = Symbol.(intersect( names(WEALTH_REGS[r]), names(hhp)))
       println( "$r : made coefs names as $(ncs[r])")
       coefs[r] = Vector{Float64}( WEALTH_REGS[r] )
       println( "$r : made coef vals as $(coefs[r])")
    end
    k = 0
    for hrow in eachrow( hhp )
        k += 1
        if k == 10
           # break
        end
        p = (hh.hid .== hrow.hid).&(hh.data_year .== hrow.data_year)
        # println( "got outrow = ", hh[p,[:hid,:region]] )
        pw = rowmul( ncs["has_pension"], hrow,  coefs["has_pension"])+nrand(1)
        if pw >= 0 # so, probit > 0.5 - infer pension wealth
            w = rowmul( ncs[ "total_pensions"], hrow, coefs["total_pensions"])
            hh[p,:net_pension_wealth] .= exp(w+nrand(1.3556770839942154))
        end
        if hrow.owner == 1 || hrow.mortgaged == 1
            w = rowmul( ncs[ "net_housing"], hrow, coefs["net_housing"])
            hh[p,:net_housing_wealth] .= exp(w+nrand(0.6285169266546937))
        end
        is_in_debt = rowmul( ncs["is_in_debt"], hrow,  coefs["is_in_debt"])+nrand(1)
        target =  "net_financial"
        m  = 1.0
        if is_in_debt >= 0 
            m = -1
            target = "net_debt"
        end
        w = rowmul( ncs[target], hrow, coefs[target])
        hh[p,:net_financial_wealth] .= m*(exp(w+nrand( 1.6934164956598172 )))
        w = rowmul( ncs["net_physical"], hrow, coefs["net_physical"])
        # println( "log physical wealth $w")
        hh[p,:net_physical_wealth] .= exp(w+nrand(0.754930602845524 ))
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
