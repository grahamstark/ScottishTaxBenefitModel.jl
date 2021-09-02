module UCTransition
#
# This module models the transition from Legacy Means Tested benefits
# to Universal Credit.
# 
# Currently it's based crudely on Scotland-wide transition figures from HoC Research
# https://commonslibrary.parliament.uk/constituency-data-universal-credit-roll-out/#caseload
#

using ScottishTaxBenefitModel
using .RunSettings: MT_Routing
using .Intermediate
using .ModelHousehold

@enum ClaimantType trans_all trans_housing trans_w_kids trans_incapacity trans_jobseekers

const PROPS = Dict(
    trans_all => 0.59,
    trans_housing => 0.61,
    trans_w_kids => 0.55,
    trans_incapacity => 0.32,
    trans_jobseekers => 0.95
)


    function which_benefit( 
        bu :: BenefitUnit, 
        intermed :: MTIntermediate,
        routing :: MT_Routing ) :: MT_Routing
        if routing != modelled_phase_in
            return routing
        end
        prob = 0.0
        if intermed.num_job_seekers > 0
            prob = PROBS[trans_jobseekers]
        elseif intermed.num_disabled_adults > 0
            prob = PROBS[trans_incapacity]
        elseif intermed.num_children > 0
            prob = PROBS[trans_w_kids]
        elseif intermed.benefit_unit_number == 1
            prob = PROBS[trans_housing]
        else
            prob = PROBS[trans_all]
        end


    end

end