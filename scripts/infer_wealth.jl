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
using .HouseholdFromFrame

using CSV
using DataFrames
using Distributions 
using DataStructures
using Format
using GLM
using Random
using RegressionTables
using StatsBase

include( "../regressions/load_was.jl")
include( "../regressions/wealth_regressions.jl")

const RENAMES =  Dict( [
    "log(weekly_gross_income)"=>"log_weekly_gross_income",
    "(Intercept)"=>"cons" ])

#=
function load_reg( filename :: String ) :: DataFrameRow
    reg = CSV.File( "data/2023-4/uk_wealth_regressions/$(filename).tab")|>DataFrame
    tr_reg = unstack(reg[!,[1,2]],1,2)
    rename!( tr_reg, RENAMES )
    tr_reg[1,:]
end
=#

"""
As above but with a pre-computed set of names in common and a pre-computed coefficient vector
"""
function rowmul( 
    names :: Vector{String}, 
    d1 :: DataFrameRow, 
    v2 ::Vector{Float64} )::Float64
    v1 = Vector(d1[names])
    # println( [names v1 v2])
    v1'*v2
end

function extract( 
    name :: Symbol, 
    r :: RegressionModel, 
    dfnames :: Vector{String},
    translations :: Dict  ) :: NamedTuple
    ns = collect( coefnames( r ))
    n = length(ns)
    for i in 1:n
        ns[i] = get( translations, ns[i], ns[i] )
    end
    # @assert issubset( coefnames, dfnames ) "this is missing: $(setdiff( coefnames, dfnames ))"
    (; name=name, coefnames = ns, coefs=coef( r ), sdev=dispersion(r.model), model=r )
end 

nrand(sd) = rand(Normal( 0.0, sd ))

function t2x( 
    actual::StatsBase.SummaryStats, 
    was_reg::StatsBase.SummaryStats, 
    imputed ::StatsBase.SummaryStats )::DataFrame

    f( v ) = format( v, precision=0, commas=true )

    function ovec( t :: StatsBase.SummaryStats ) :: Vector
        return [
            f(t.mean),
            f(t.min),
            f(t.q25),
            f(t.median), 
            f(t.q75), 
            f(t.max), 
            f(t.nobs), 
            f(t.nmiss)]
    end

    return DataFrame( 
        measure=[:Mean, :Min, :"25th percentile", :Median, :"75th Percentile", "Max", :"Observations", :"Missing Values"], 
        Actual=ovec( actual ), 
        Was_Regession= ovec( was_reg ), 
        FRS_Imputed=ovec( imputed ))
end

function add_wealth_to_dataframes!( 
    hhr:: DataFrame, 
    hh :: DataFrame, 
    final_regs :: OrderedDict )
    
    hhp = hhr[ hhr.is_hrp .== 1, : ] # 1 per hhld
    hpnames = names( hhp )
    println( "hhp loaded $(size(hhp))")
    
    ex = OrderedDict()
    for (k,r) in final_regs
        ex[k] = extract( k, r, hpnames, RENAMES )
    end

    for hrow in eachrow( hhp )
        p = (hh.hid .== hrow.hid).&(hh.data_year .== hrow.data_year) 
         
        pw = rowmul( ex[:has_pension].coefnames, hrow, ex[:has_pension].coefs)+nrand(1)
        if pw >= 0 # so, probit > 0.5 - infer pension wealth
            w = rowmul( ex[:net_pension_wealth].coefnames, hrow, ex[:net_pension_wealth].coefs )
            hh[p,:net_pension_wealth] .= exp(w+nrand(ex[:net_pension_wealth].sdev ))
        end

        if hrow.owner == 1 || hrow.mortgaged == 1
            w = rowmul( ex[:net_housing_wealth].coefnames, hrow, ex[:net_housing_wealth].coefs)
            hh[p,:net_housing_wealth] .= exp(w+nrand(ex[:net_housing_wealth].sdev))
        end

        # debt and +ive financial wealth treated seperately
        is_in_debt = rowmul( ex[:is_in_debt].coefnames, hrow, ex[:is_in_debt].coefs)+nrand(1)
        target =  :net_financial_wealth
        m  = 1.0
        if is_in_debt >= 0 
            m = -1
            target = :net_debt
        end
        w = rowmul( ex[target].coefnames, hrow, ex[target].coefs )
        hh[p,:net_financial_wealth] .= m*(exp(w+nrand( ex[target].sdev )))
        
        w = rowmul( ex[:net_physical_wealth].coefnames, hrow, ex[:net_physical_wealth].coefs)
        hh[p,:net_physical_wealth] .= exp(w+nrand( ex[:net_physical_wealth].sdev ))

    end # each row    
    hh.total_wealth = 
        hh.net_housing_wealth + 
        hh.net_financial_wealth + 
        hh.net_physical_wealth + 
        hh.net_pension_wealth
    ex
 end # function add_wealth_to_dataframes!

function comptable(
    wasv :: Vector,
    reg  :: NamedTuple,
    frsv :: Vector  )
    wpred = predict( reg.model )
    err = rand(Normal(0, reg.sdev ),Int(nobs(reg.model )))
    wpred = exp.(wpred+err)
    t2x( 
        summarystats( wasv ),
        summarystats(wpred),
        summarystats(frsv) )
    
end

model_hhlds_path = joinpath( MODEL_DATA_DIR, "model_households-2015-2021.tab")
hh = CSV.File( model_hhlds_path ) |> DataFrame
pers = CSV.File( joinpath( MODEL_DATA_DIR, "model_people-2015-2021.tab")) |> DataFrame
hhr = create_regression_dataframe( hh, pers )
ex = add_wealth_to_dataframes!( hhr, hh, final_regs )

io = IOBuffer()
println( io, "Net Physical")
    println(io, comptable(
        was.net_physical,
        ex[:net_physical_wealth],
        hh.net_physical_wealth))

println( io, "Net Housing")
println( io, 
    comptable(
        was.net_housing,
        ex[:net_housing_wealth],
        hh.net_housing_wealth
    ))

println( io, "Net Pensions")
println( io, 
    comptable(
        was.total_pensions,
        ex[:net_pension_wealth],
        hh.net_pension_wealth
    ))

println( io, "Net Financial")
println( io, comptable(
    was.net_financial,
    ex[:net_financial_wealth],
    hh.net_financial_wealth))

write( "docs/wealth_summary.txt", String(take!(io)) )

CSV.write( model_hhlds_path, hh, delim='\t' )
 
