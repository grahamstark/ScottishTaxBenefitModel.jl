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
    route_to_uc_or_legacy, 
    route_to_uc_or_legacy!

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
    bures    :: BenefitUnitResult ) :: LegacyOrUC
    if settings.means_tested_routing != modelled_phase_in
        return settings.means_tested_routing == uc_full ? uc_bens : legacy_bens
    end
    # FIXME make historic
    targets = if settings.to_y >= 2025 && settings.to_q > 1
        PROPS_ON_UC_V2._2025
    else
        PROPS_ON_UC_V2._2024
    end
    #println( "targets as $targets")
    prob = if has_any( bures, WORKING_TAX_CREDIT, CHILD_TAX_CREDIT )
        # println( "IS route ")
        targets.TAX_CREDITS
    elseif has_any( bures, INCOME_SUPPORT, NON_CONTRIB_JOBSEEKERS_ALLOWANCE, NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE )
        # println( "Credits route $(Results.to_string(bures))")
        targets.UNEMPLOYED_BENS
    else 
        1.0
    end
    # println( "final prob $prob")
    head = get_head( bu )
    switch = testp( head.onerand, prob, Randoms.UC_TRANSITION )
    route = switch ? uc_bens : legacy_bens
    # println("route $route")
    return route
end

#=
function route_to_uc_or_legacy_old_version( 
    settings :: Settings,
    tenure   :: Tenure_Type,
    bu       :: BenefitUnit, 
    intermed :: MTIntermediate ) :: LegacyOrUC
    if settings.means_tested_routing != modelled_phase_in
        return settings.means_tested_routing == uc_full ? uc_bens : legacy_bens
    end
    prob = 0.0
    if intermed.limited_capacity_for_work
        prob = PROPS_ON_UC[intermed.nation][trans_incapacity]
    elseif (intermed.benefit_unit_number == 1) && renter( tenure )
        prob = PROPS_ON_UC[intermed.nation][trans_housing]
    elseif intermed.num_children > 0
        prob = PROPS_ON_UC[intermed.nation][trans_w_kids]
    elseif intermed.num_job_seekers > 0
        prob = PROPS_ON_UC[intermed.nation][trans_jobseekers]
    else
        prob = PROPS_ON_UC[intermed.nation][trans_all]
    end
    head = get_head( bu )
    switch = testp( head.onerand, prob, Randoms.UC_TRANSITION )
    return switch ? uc_bens : legacy_bens
end
=#
"""
Allocate a benefit unit to ether UC or Legacy Benefits. Very crudely.
"""
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
        # if bres.uc.basic_conditions_satisfied # FIXME This condition needs some thought.
            bres.route = route_to_uc_or_legacy( settings, bus[bno], bres )
            if bres.route == legacy_bens 
                tozero!( bres, UNIVERSAL_CREDIT )
                tozero!( bres, COUNCIL_TAX_BENEFIT )
                bres.uc = UCResults{RT}()
                if( bno == 1 ) && ( bres.legacy_mtbens.ctr_recipient > 0 ) # ctr assignment hack - it's possible
                    # that there's actually the value of CTB in that slot from the UC calculation
                    # so overwrite with the saved Legacy value
                    bres.pers[bres.legacy_mtbens.ctr_recipient].income[COUNCIL_TAX_BENEFIT] = bres.legacy_mtbens.ctr
                end
                
            elseif bres.route == uc_bens
                # nuke every old thing for everyone who's in scope for UC
                tozero!( bres, LEGACY_MTBS...)
                tozero!( bres, 
                    NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE, 
                    NON_CONTRIB_JOBSEEKERS_ALLOWANCE, 
                    INCOME_SUPPORT, 
                    WORKING_TAX_CREDIT, 
                    CHILD_TAX_CREDIT )
                tozero!( bres, COUNCIL_TAX_BENEFIT )
                bres.legacy_mtbens = LMTResults{RT}()
                
                if( bno == 1 ) && ( bres.uc.recipient > 0 )# ctr assignment hack
                    bres.pers[bres.uc.recipient].income[COUNCIL_TAX_BENEFIT] = bres.uc.ctr
                end
            end
        # end
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

#=
function route_to_uc_or_legacy_old_version!( 
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
            bres.route = route_to_uc_or_legacy( settings, hh.tenure, bus[bno], im )
            if bres.route == legacy_bens 
                tozero!( bres, UNIVERSAL_CREDIT )
                tozero!( bres, COUNCIL_TAX_BENEFIT )
                bres.uc = UCResults{RT}()
                if( bno == 1 ) && ( bres.legacy_mtbens.ctr_recipient > 0 ) # ctr assignment hack - it's possible
                    # that there's actually the value of CTB in that slot from the UC calculation
                    # so overwrite with the saved Legacy value
                    bres.pers[bres.legacy_mtbens.ctr_recipient].income[COUNCIL_TAX_BENEFIT] = bres.legacy_mtbens.ctr
                end
            elseif bres.route == uc_bens
                # nuke every old thing for everyone who's in scope for UC
                tozero!( bres, LEGACY_MTBS...)
                tozero!( bres, COUNCIL_TAX_BENEFIT )
                bres.legacy_mtbens = LMTResults{RT}()
                if( bno == 1 ) && ( bres.uc.recipient > 0 )# ctr assignment hack
                    bres.pers[bres.uc.recipient].income[COUNCIL_TAX_BENEFIT] = bres.uc.ctr
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
=#

end # Module UCTransition
