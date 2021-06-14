module HistoricBenefits

using CSV, DataFrames
using ScottishTaxBenefitModel.Definitions 

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

function make_benefit_ratios( fy :: Integer, incd :: Incomes_Dict{T} ) ::Incomes_Dict{T} where T
    d = Incomes_Dict{T}()
    for target in RATIO_BENS
        if haskey(incd, target )
            d[target] = benefit_ratio( fy, incd[target], target )
        end
    end
    return d
end 

function add_pips!( rats :: Incomes_Dict{T}, fy :: Integer, incd :: Incomes_Dict )
    if haskey( incd, :income_personal_independence_payment_daily_living)  
        v = incd[:income_personal_independence_payment_daily_living]
        if v ≈ HISTORIC_BENEFITS[fy][:pip_daily_daily_living_enhanced]
            rats[personal_independence_payment_daily_living] = 1
        elseif v ≈ HISTORIC_BENEFITS[fy][:pip_daily_daily_living_standard]
            rats[personal_independence_payment_daily_living] = 2
        else

        end
    end
    if haskey( incd, :income_personal_independence_payment_mobility )    
        v = incd[:income_personal_independence_payment_mobility]
        if v ≈ HISTORIC_BENEFITS[fy][:pip_mobility_enhanced]
            rats[personal_independence_payment_mobility] = 1
        elseif v ≈ HISTORIC_BENEFITS[fy][:pip_mobility_standard]
            rats[personal_independence_payment_mobility] = 2
        else
            println( "")
        end
    end
end

end # module