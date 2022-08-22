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
using .Results: tozero!, HouseholdResult, BenefitUnitResult, LMTResults, UCResults
using .STBIncomes

export 
    route_to_uc_or_legacy, 
    route_to_uc_or_legacy!

@enum ClaimantType trans_all trans_housing trans_w_kids trans_incapacity trans_jobseekers

const PROPS_ON_UC = Dict(
    trans_all => 0.62, 
    trans_housing => 0.64,
    trans_w_kids => 0.63,
    trans_incapacity => 0.41,
    trans_jobseekers => 0.95 )

"""
Allocate a benefit unit to ether UC or Legacy Benefits. Very crudely.
"""
function route_to_uc_or_legacy( 
    settings :: Settings,
    bu       :: BenefitUnit, 
    intermed :: MTIntermediate ) :: LegacyOrUC
    if settings.means_tested_routing != modelled_phase_in
        return settings.means_tested_routing == uc_full ? uc_bens : legacy_bens
    end
    prob = 0.0
    if intermed.num_job_seekers > 0
        prob = PROPS_ON_UC[trans_jobseekers]
    elseif intermed.limited_capacity_for_work
        prob = PROPS_ON_UC[trans_incapacity]
    elseif intermed.num_children > 0
        prob = PROPS_ON_UC[trans_w_kids]
    elseif intermed.benefit_unit_number == 1
        prob = PROPS_ON_UC[trans_housing]
    else
        prob = PROPS_ON_UC[trans_all]
    end
    head = get_head( bu )
    switch = testp( head.onerand, prob, Randoms.UC_TRANSITION )
    return switch ? uc_bens : legacy_bens
end

function route_to_uc_or_legacy!( 
    results  :: HouseholdResult,
    settings :: Settings,
    hh       :: Household, 
    intermed :: HHIntermed )
    bus = get_benefit_units( hh )
    RT = eltype( results.income ) # FIXME whole where RT thing

    for bno in eachindex( bus )
        im = intermed.buint[bno]
        bres = results.bus[bno]
        if bres.uc.basic_conditions_satisfied # FIXME This condition needs some thought.
            bres.route = route_to_uc_or_legacy( settings, bus[bno], im )
            if bres.route == legacy_bens 
                tozero!( bres, UNIVERSAL_CREDIT )
                bres.uc = UCResults{RT}()
                if( bno == 1 ) && ( bres.legacy_mtbens.ctr_recipient > 0 )# ctr assignment hack
                    bres.pers[bres.legacy_mtbens.ctr_recipient].income[COUNCIL_TAX_BENEFIT] = bres.legacy_mtbens.ctr
                else
                    tozero!( bres, COUNCIL_TAX_BENEFIT )
                end
            elseif bres.route == uc_bens
                # nuke every old thing for everyone who's in scope for UC
                tozero!( bres, LEGACY_MTBS...)
                bres.legacy_mtbens = LMTResults{RT}()
                if( bno == 1 ) && ( bres.uc.recipient > 0 )# ctr assignment hack
                    bres.pers[bres.uc.recipient].income[COUNCIL_TAX_BENEFIT] = bres.uc.ctr
                else
                    tozero!( bres, COUNCIL_TAX_BENEFIT )
                end
                ## FIXME TRANSITIONAL PAYMENTS
            end
        end
        # .. so some futher nuking ..
        if settings.means_tested_routing == uc_full
            # these cease to exist, even for pensioners and students
            tozero!( bres, 
                NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE, 
                NON_CONTRIB_JOBSEEKERS_ALLOWANCE, 
                INCOME_SUPPORT, 
                WORKING_TAX_CREDIT, 
                CHILD_TAX_CREDIT )
            bres.legacy_mtbens = LMTResults{RT}()
            # this last is entirely arbitrary, but
            # takes out essentially all ft students, etc.
            if im.age_oldest_adult < 50
                tozero!( bres, LEGACY_MTBS...)
            end
        end
    end
end

end # Module UCTransition