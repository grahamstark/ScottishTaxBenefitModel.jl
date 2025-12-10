module UCTransition
#
# This module models the transition from Legacy Means Tested benefits
# to Universal Credit.
# 
# Currently it's based crudely on Scotland-wide transition figures from HoC Research
# https://commonslibrary.parliament.uk/constituency-data-universal-credit-roll-out/#caseload
#

using ScottishTaxBenefitModel
using .RunSettings  # : Settings, MT_Routing
using .Intermediate: MTIntermediate, HHIntermed
using .ModelHousehold
using .Definitions
using .Randoms: testp
using .Results: tozero!, HouseholdResult, BenefitUnitResult, LMTResults, UCResults, has_any
using .STBIncomes

export 
    route_to_uc_or_legacy

@enum ClaimantType trans_all trans_housing trans_w_kids trans_incapacity trans_jobseekers

# Thse are very rough - see spreadsheet 
const PROPS_ON_UC_V2 = (; _2024=(;UNEMPLOYED_BENS=0.2, TAX_CREDITS=0.8),
                          _2025=(;UNEMPLOYED_BENS=0.2, TAX_CREDITS=1.0))

const PROPS_ON_UC = # NOT USED
    Dict(N_England=>
            Dict(
                trans_all => 0.70, 
                trans_housing => 0.69,
                trans_w_kids => 0.71,
                trans_incapacity => 0.53,
                trans_jobseekers => 0.97 ),
        N_Scotland=>
            Dict(
                trans_all => 0.71, 
                trans_housing => 0.70,
                trans_w_kids => 0.80,
                trans_incapacity => 0.57,
                trans_jobseekers => 0.97 ),
        N_Wales=>
            Dict(
                trans_all => 0.70, 
                trans_housing => 0.69,
                trans_w_kids => 0.71,
                trans_incapacity => 0.53,
                trans_jobseekers => 0.97 ),
        N_Northern_Ireland=>
            Dict(
                trans_all => 0.70, 
                trans_housing => 0.69,
                trans_w_kids => 0.71,
                trans_incapacity => 0.53,
                trans_jobseekers => 0.97 ) # FIXME this is just Wales!!
            )

function route_to_uc_or_legacy( 
    settings :: Settings,
    bu       :: BenefitUnit,
    intermed :: MTIntermediate,
    bures    :: BenefitUnitResult ) :: LegacyOrUC
    if intermed.all_pension_age
        return legacy_bens
    end 
    if settings.means_tested_routing != modelled_phase_in
        return settings.means_tested_routing == uc_full ? uc_bens : legacy_bens
    end
    # FIXME make historic
    targets = if settings.to_y >= 2025 && settings.to_q > 1
        PROPS_ON_UC_V2._2025
    else
        PROPS_ON_UC_V2._2024
    end
    prob = if has_any( bures, WORKING_TAX_CREDIT, CHILD_TAX_CREDIT )
        targets.TAX_CREDITS
    elseif has_any( bures, INCOME_SUPPORT, NON_CONTRIB_JOBSEEKERS_ALLOWANCE, NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE )
        targets.UNEMPLOYED_BENS
    else 
        1.0
    end
    head = get_head( bu )
    switch = testp( head.onerand, prob, Randoms.UC_TRANSITION )
    route = switch ? uc_bens : legacy_bens
    return route
end

"""
A vector, 1 per bu of whether to go to legacy or UC. Always go to legacy for
all-pensioner bus. The modelled transition bit is a messy wild guess.
"""
function get_routes_for_hh(
    settings :: Settings,
    hh       :: Household, 
    intermed :: HHIntermed )::Vector{LegacyOrUC}
    bus = get_benefit_units( hh )
    routes = []
    for bno in eachindex( bus )
        inter = intermed.buint[bno]
        head = get_head( bus[bno] )
        route =if inter.all_pension_age # always to pc/hb for all pensioner bus
            legacy_bens
        elseif settings.means_tested_routing == uc_full
            uc_bens 
        elseif settings.means_tested_routing == lmt_full
            legacy_bens 
        else # modelled_phase_in
            targets = if settings.to_y >= 2025 && settings.to_q > 1
                PROPS_ON_UC_V2._2025
            else
                PROPS_ON_UC_V2._2024
            end
            prob = if inter.num_not_working > 0 
                targets.UNEMPLOYED_BENS
            else
                targets.TAX_CREDITS
            end
            switch = testp( head.onerand, prob, Randoms.UC_TRANSITION )
            switch ? uc_bens : legacy_bens
        end
        push!( routes, route)
    end # bus 
    return routes
end

end # Module UCTransition
