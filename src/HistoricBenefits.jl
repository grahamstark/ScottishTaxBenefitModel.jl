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
        d = Dict{Symbol,Float64}()
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

end # module