module HistoricBenefits

using CSV, DataFrames
using ScottishTaxBenefitModel
using .Definitions 
using .Utils: nearesti

export benefit_ratio, RATIO_BENS, make_benefit_ratios

const RATIO_BENS = [state_pension,bereavement_allowance_or_widowed_parents_allowance_or_bereavement]

function load_historic( file ) :: Dict
    df = CSV.File( file ) |> DataFrame
    nc = size( df )[2]
    nms = strip.(names( df ))
    db = Dict{Int,Dict}()
    for dr in eachrow(df)
        d = Dict{Symbol,Union{Missing,Float64}}()
        for i in 3:nc
            rn = Symbol(nms[i])
            # println( rn )
            # println( typeof( rn ))                
            d[rn] = dr[i]
        end
        db[dr.year] = d
    end
    return db
end

const HISTORIC_BENEFITS = load_historic( "$(MODEL_PARAMS_DIR)/historic_benefits.csv" ) 

function benefit_ratio( 
    fy :: Integer, 
    amt :: Real, 
    btype :: Incomes_Type ) :: Real
    brat = HISTORIC_BENEFITS[fy][Symbol(btype)]
    return amt/brat
end

#
# Year 1st, then 1 before and 1 after, then 2.. 
#
function get_historic( fy :: Integer, which :: Symbol, width::Int = 1 )::Vector{Real}
    out = []
    push!(out, HISTORIC_BENEFITS[fy][which])
    for i in 1:width
        year = fy-i 
        push!(out, HISTORIC_BENEFITS[year][which])
        year = fy+1
        push!(out, HISTORIC_BENEFITS[year][which]) 
    end
    return out
end

"""
  Find an exact match for some benefit level, given actual levels, -1..+1 years around fy, or find 
  the nearest amongst the current values, since sometimes the imputation
  seems to be for the wrong year (calendar vs financial). If that fails, pick the
  index of the current values that's closest.
"""
function get_matches( v :: Real, fy :: Int, which ... ) :: Tuple
    n = length(which)
    all_current = []
    for i in 1:n
        hvals = get_historic( fy, which[i])
        m = size(hvals)[1]
        push!(all_current,hvals[1]) 
        for j in 1:m
            if v ≈ hvals[j]
                # println( "on $(which[i]) matched $v at pos $i j=$j vals are $hvals ")
                return (i,j)
            end
        end
    end
    # if we get here, try searching nearest
    println( "didn't match; trying against $(all_current)")
    n = nearesti( v, all_current... )
    return (n,99)
end

# 
# FIXME make all these names the same. Use the integer constants in `.Incomes.jl`.
# FIXME historic bit should be the whole parameter system eventually.
#
"""
 Return a dict of either ratios of recorded receipt to actual values or an indicator of which
 level of benefit is closest.
"""
function make_benefit_ratios( fy :: Integer, incd :: Incomes_Dict{T} ) ::Incomes_Dict{T} where T
    d = Incomes_Dict{T}()
    # for pensions, etc. we just accept what's there & assign the ratio 
    for target in RATIO_BENS
        if haskey(incd, target )
            d[target] = benefit_ratio( fy, incd[target], target )
        end
    end

    # these seem to be usually imputed in the data. Find which one matches best.
    if haskey( incd, personal_independence_payment_daily_living)  
        v = incd[personal_independence_payment_daily_living]
        matches = get_matches( v, fy, :pip_daily_living_standard,  :pip_daily_living_enhanced )
        d[personal_independence_payment_daily_living] = matches[1]
        if matches[2] > 1
            # println( "!! pip daily living matched at $(matches[2])")
        end
    end
    if haskey( incd, personal_independence_payment_mobility)  
        v = incd[personal_independence_payment_mobility]
        matches = get_matches( v, fy, :pip_mobility_standard, :pip_mobility_enhanced )
        d[personal_independence_payment_mobility] = matches[1]
        if matches[2] > 1
            # println( "!! pip mobility matched at $(matches[2])")
        end
    end
    return d
end
    
end # module