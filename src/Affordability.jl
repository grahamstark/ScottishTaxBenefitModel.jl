module Affordability

struct AffordabilityMeasures{T<:Real} 
    share :: T
    above_poverty :: Bool 
end

function make_pc_measures( 
    povline  :: T,
    income :: T,
    amount :: T ) :: AffordabilityMeasures{T} where T
    v = income - amount
    pv = v > povline 
    share = v/(income-povline)
    return AffordabilityMeasures( share, pv )
end

end