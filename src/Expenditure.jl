#
# imputations
#
module Expenditure

using ScottishTaxBenefitModel

using .Intermediate
using .ModelHousehold
using .Results

const COEFS = ones(21)

function impute_fuel(
    household_result :: HouseholdResult{T},
    household        :: Household{T},
    intermed         :: HHIntermed{T},
    fuel_price       :: T, # these should all be point differences from base forecast data
    cpi              :: T,
    rem_cpi          :: T ) :: NamedTuple where T
    v = zeros(T,21)
    v[1] = 1.0 # intercept
    v[2] = log( fuel_price / rem_cpi ) # rel pr fuel``
    v[3] = household_result.bhc_net_income / cpi ## FIXME make a price index with fuel
    v[4] = v[3]^2
    v[5] = v[3]^3
    v[6] = hh.region == Scotland ? 1 : 0
    v[7] = hh.tenure == Owned_outright ? 1 : 0
    v[8] = hh.tenure == Mortgaged_Or_Shared ? 1 : 0
    v[9] = hh.tenure in [Private_Rented_Unfurnished, Private_Rented_Furnished] ?  1 : 0
    v[10] = hh.tenure == Council_Rented ? 1 : 0
    v[11] = hh.dwelling == detatched ? 1 : 0 
    v[12] = hh.dwelling == terraced ? 1 : 0 
    v[13] = hh.dwelling == flat ? 1 : 0 
    v[14] = hh.dwelling in [caravan, other_dwelling] ? 1 : 0
    v[15] = count( hh, le_age, 17 ) 
    v[16] = count( hh, between_ages, 18, 69 ) 
    v[17] = count( hh, ge_age, 70 ) 
    @assert sum(v[15:17]) intermed.num_people
    v[18] = hh.interview_month in [12,1,2] ? 1 : 0
    v[19] = hh.interview_month in [3,4,5] ? 1 : 0
    v[20] = hh.interview_month in [6,7,8] ? 1 : 0
    v[21] = hh.interview_year - 2008
    pred_share : T = v'COEFS
    @assert pred_share > 0 && pred_share < 1
    pred_spend = pred_share*household_result.bhc_net_income
    return (pred_share=pred_share, pred_spend=pred_spend)
end

end # module