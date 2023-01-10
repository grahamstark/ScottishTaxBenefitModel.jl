module Affordability
#
# start of an Affordability module. See, for example:
# Stark, G. (2009) Assessing the Ability to Pay for the Fees Charged by Charities (Stage 2 Report). Office of the Scottish Charities Regulator (OSCR). Available at: http://www.oscr.org.uk/publications-and-guidance/affordability-report-phase-2/.
# Stark, G. (no date) ‘ASSESSING THE ABILITY TO PAY FOR THE FEES CHARGED BY CHARITIES PHASE 1 REPORT’, p. 36.
#
#

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
