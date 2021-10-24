module UniversalCredit
#
# This module implements the Universal Credit system,
# largely as its defined in CPAG 19/20 and 20/21.
#
using Base: Bool
using Dates: TimeType, now

using ScottishTaxBenefitModel

# FIXME prune these imports to things actually used.

using .ModelHousehold: 
    BenefitUnit,
    Household, 
    Person,    
    empl_status_in, 
    get_benefit_units,
    get_head,
    get_spouse,
    is_head,
    is_spouse,
    pers_is_disabled, 
    pers_is_carer

using .STBParameters: 
    UniversalCreditSys,
    AgeLimits,
    ChildLimits,
    HoursLimits,
    HousingRestrictions,
    MinimumWage,
    get_minimum_wage

using .Intermediate: 
    MTIntermediate, 
    HHIntermed,
    born_before, 
    has_limited_capactity_for_work_activity,
    has_limited_capactity_for_work,
    make_recipient,
    reached_state_pension_age
 
using .Results: 
    BenefitUnitResult, 
    HouseholdResult, 
    IndividualResult, 
    UCResults,
    has_any,
    to_string,
    total
    
using .LocalLevelCalculations: 
    apply_rent_restrictions

using .LegacyMeansTestedBenefits:
    num_qualifying_for_severe_disability,
    tariff_income

using .STBIncomes
using .Definitions

export 
    basic_conditions_satisfied,
    calc_elements!,
    calc_standard_allowance,
    calc_tariff_income!,
    calc_uc_child_costs!,
    calc_uc_income!,
    calc_universal_credit!, 
    disqualified_on_capital,
    make_min_se,
    qualifiying_16_17_yo

function pid_of_youngest_adult( bu :: BenefitUnit ) :: BigInt
    y = 99999
    yp :: BigInt = -1
    for pid in bu.adults
        if bu.people[pid].age < y
            y = bu.people[pid].age
            yp = pid
        end
    end
    return yp
end

"""
The test of basic eligibility from p37- 2020/1 CPAG
"""
function basic_conditions_satisfied( 
    benefit_unit :: BenefitUnit, 
    intermed     :: MTIntermediate,
    uc           :: UniversalCreditSys, # FIXME uc->ucsys everywhere
    age_limits   :: AgeLimits ) :: Bool
    bu = benefit_unit # shortcut
    if intermed.all_pension_age 
        return false
    elseif intermed.age_oldest_adult < 18 # FIXME parameterise this
        q1617 = false
        for pid in benefit_unit.adults
            if qualifiying_16_17_yo( bu, bu.people[pid], intermed, uc )
                q1617 = true
                break
            end
        end
        return q1617            
    else
        all_in_educ = true
        for pid in bu.adults
            # FIXME need a better test than this
            in_educ :: Bool = 
                (bu.people[pid].employment_status == Student) &&
                (intermed.num_children == 0) && 
                (! pers_is_disabled( bu.people[pid]))
            if ! in_educ
                all_in_educ = false
                break
            end
        end
        return ! all_in_educ 
    end
    @assert false "should never get to end of basic_conditions_satisfied"
end

function disqualified_on_capital( 
    benefit_unit :: BenefitUnit, 
    uc           :: UniversalCreditSys ) :: Bool
    cap = 0.0
    bu = benefit_unit # shortcut
    # FIXME we're doing this twice
    for pid in bu.adults
        if bu.people[pid].over_20_k_saving
            return true
        else
            for (at,val) in bu.people[pid].assets
                cap += val
            end
        end
    end
    return cap > uc.capital_max
end

function qualifiying_16_17_yo( 
    benefit_unit   :: BenefitUnit,
    pers :: Person, 
    intermed :: MTIntermediate, 
    uc :: UniversalCreditSys ) :: Bool
    bu = benefit_unit # shortcut
    if pers_is_carer( pers )
        return true
    elseif has_limited_capactity_for_work( pers )
        return true
    elseif (is_head( bu, pers ) || is_spouse( bu, pers )) && ( intermed.num_children > 0)
        return true
        ## And some others; see CPAG 2020/1 p 37
    end
    return false
end

function calc_standard_allowance( 
    benefit_unit     :: BenefitUnit,
    intermed         :: MTIntermediate,
    uc               :: UniversalCreditSys )
    sa = 0.0
    bu = benefit_unit # shortcut
    yp :: BigInt = pid_of_youngest_adult( bu )
    if intermed.num_adults == 1 
        if intermed.age_oldest_adult < 18
            # under 18 single FIXME we should only every need 1 call to this, at the beginning
            if qualifiying_16_17_yo( bu, bu.people[yp], intermed, uc )
                sa = uc.age_18_24    
            end
        elseif intermed.age_oldest_adult < 25
            # u 26 single
            sa = uc.age_18_24
        else
            # 25+ single
            sa = uc.age_25_and_over
        end
    else
        if  intermed.age_oldest_adult < 18 # FIXME parameterise these numbers, at least
            # under 18 couple
            np = 0
            for pid in bu.adults
                if qualifiying_16_17_yo( bu, bu.people[pid], intermed, uc )
                    np += 1
                end
            end
            if np == 1
                sa = uc.age_18_24
            elseif np == 2
                sa = uc.couple_both_under_25
            end
        elseif intermed.age_oldest_adult < 25
            # under 25 couple(probably - might be u25 single if 2nd adult under 18)
            if  intermed.age_youngest_adult >= 18
                sa = uc.couple_both_under_25
            else
                if qualifiying_16_17_yo( bu, bu.people[yp], intermed, uc )
                    sa = uc.couple_both_under_25
                else
                    sa = uc.age_18_24 # single person, ...
                end
            end
        else 
            # 25+ couple (probably - might be 25+ single if 2nd adult under 18)
            if intermed.age_youngest_adult >= 18
                sa = uc.couple_oldest_25_plus
            else
                ## kinda TODO
                if qualifiying_16_17_yo( bu, bu.people[yp], intermed, uc )
                    sa = uc.couple_oldest_25_plus
                else
                    sa = uc.age_25_and_over # single person, ...
                end
            end
        end # over 25 couple
    end # 2 adult bu
    return sa
end # standard allowance

function calc_elements!( 
    ucr          :: UCResults,
    benefit_unit :: BenefitUnit, 
    intermed     :: MTIntermediate,
    uc           :: UniversalCreditSys,
    hours_limits :: HoursLimits, 
    child_limits :: ChildLimits )
    bu = benefit_unit # shortcut

    # child elements
    
    if intermed.num_allowed_children > 0
        if born_before( 
            intermed.age_oldest_child, 
            child_limits.policy_start, 
            now()) # FIXME we need to parameterise model_run_date somehow
            # this is the abolished 1st child thing see 20/21 p66
            ucr.child_element = uc.first_child
        else
            ucr.child_element = uc.subsequent_child
        end
        ucr.child_element += (intermed.num_allowed_children-1)*uc.subsequent_child
    end
    # limited capacity for work-related Activity
    # 1 per BU; see cpag 20/1 p 71-73
    lcwa = false
    lcwa_pid :: BigInt = -1
    for pid in bu.adults 
        if has_limited_capactity_for_work_activity( bu.people[pid])
            lcwa = true
            lcwa_pid = pid
            break
        end            
    end
    if lcwa 
        ucr.limited_capacity_for_work_activity_element = uc.limited_capcacity_for_work_activity
    end
    carer = false
    for pid in bu.adults 
        if pid != lcwa_pid # can't also give carers to same person, but could give to spouse
            if pers_is_carer( bu.people[pid] )
                carer = true
                break
            end # is carer
        end # pid
    end
    if carer
        ucr.carer_element = uc.carer
    end
end

"""

FIXME: Near dup of WTC calculation 
"""
function calc_uc_child_costs!( 
    ucr                 :: UCResults,
    benefit_unit        :: BenefitUnit,
    intermed            :: MTIntermediate,
    uc                  :: UniversalCreditSys )  
    bu = benefit_unit # shortcut
    cost_of_childcare = 0.0
    for pid in bu.children 
        cost_of_childcare += bu.people[pid].cost_of_childcare 
    end    
    cost_of_childcare *= uc.childcare_proportion    
    if intermed.num_children > 1 
        cost_of_childcare = min( uc.childcare_max_2_plus_children, cost_of_childcare )
    else
        cost_of_childcare = min( uc.childcare_max_1_child, cost_of_childcare )
    end    
    ucr.childcare_costs = cost_of_childcare 
end

function make_min_se( 
    seinc    :: T, 
    age      :: Integer,
    uc       :: UniversalCreditSys, 
    minwage  :: MinimumWage ) :: T where T
    mw :: T = get_minimum_wage( minwage, age )
    min_se :: T = mw*uc.minimum_income_floor_hours
    return max( min_se, seinc )
end

"""
Implements CPAG 19/20 ch 7
"""
function calc_uc_income!( 
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit        :: BenefitUnit,
    intermed            :: MTIntermediate,
    uc                  :: UniversalCreditSys,
    minwage             :: MinimumWage ) 
    bu = benefit_unit # shortcut
    bur = benefit_unit_result # shortcut
    inc = 0.0  
    earn = 0.0
    for pid in bu.adults
        inc += isum( bur.pers[pid].income, uc.other_income )
        earn += isum( bur.pers[pid].income, uc.earned_income )
        seinc = bur.pers[pid].income[SELF_EMPLOYMENT_INCOME] 
        # FIXME any self employed? what about losses?          
        if bu.people[pid].employment_status == Full_time_Self_Employed 
            seinc = make_min_se( seinc, bu.people[pid].age, uc, minwage )            
        end
        earn += seinc
    end
    bur.uc.earnings_before_allowances = earn # the PiP calculator uses this for CTR for UC recipients
    if( intermed.num_children > 0 ) || intermed.limited_capacity_for_work
        bur.uc.work_allowance = bur.uc.housing_element > 0 ? 
            uc.work_allowance_w_housing : uc.work_allowance_no_housing
        earn = max( 0.0, earn-bur.uc.work_allowance)
    end
    bur.uc.other_income = inc
    bur.uc.earned_income = earn*uc.taper
end

## FIXME we need the extra capital var here benunit.Totsav
function calc_tariff_income!( 
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit :: BenefitUnit, 
    uc           :: UniversalCreditSys )
    bu = benefit_unit # shortcut
    ucr = benefit_unit_result.uc # shortcut
    cap = 0.0
    # FIXME we're doing this twice!
    for pid in bu.adults
        for (at,val) in bu.people[pid].assets
            cap += val
        end
    end
    ucr.assets = cap    
    ucr.tariff_income = tariff_income( cap, uc.capital_min, uc.capital_tariff )
 end

#
# FIXME CPAG 19/20 p 122 shows a earned/unearned 
# split calculation with earnings 
#
function calc_universal_credit!(
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit     :: BenefitUnit,
    intermed         :: MTIntermediate,
    uc               :: UniversalCreditSys,
    age_limits       :: AgeLimits, 
    hours_limits     :: HoursLimits,
    child_limits     :: ChildLimits,
    hr               :: HousingRestrictions,
    minwage          :: MinimumWage )
    bu = benefit_unit # shortcut
    bur = benefit_unit_result # shortcut
    

    if ! basic_conditions_satisfied( 
        bu, 
        intermed, 
        uc, 
        age_limits )
        bur.uc.basic_conditions_satisfied = false
        return
    end
    bur.uc.basic_conditions_satisfied = true
    if disqualified_on_capital( bu, uc )
        bur.uc.disqualified_on_capital = true
        return
    end
    bur.uc.disqualified_on_capital = false
    bur.uc.standard_allowance = calc_standard_allowance( benefit_unit, intermed, uc )
    calc_elements!( bur.uc, bu, intermed, uc, hours_limits, child_limits )
    if( intermed.num_working_ft > 0 ) || ( intermed.num_working_pt > 0 )
        calc_uc_child_costs!( bur.uc, bu, intermed, uc )
    end
    calc_uc_income!( bur, bu, intermed, uc, minwage )
    calc_tariff_income!( bur, bu, uc )
    bur.uc.maximum = 
        bur.uc.standard_allowance + 
        bur.uc.limited_capacity_for_work_activity_element +
        bur.uc.child_element +
        bur.uc.housing_element + 
        bur.uc.carer_element + 
        bur.uc.childcare_costs
    bur.total_income = 
        bur.uc.earned_income - 
        bur.uc.other_income - 
        bur.uc.tariff_income
    uce = max( 0.0, bur.uc.maximum - bur.total_income )
    
    # Make the recipient the bu head if the head isn't 
    # retired. 
    head = get_head( bu )
    target_pid = head.pid
    if reached_state_pension_age( age_limits, head.age, head.sex )
        target_pid = get_spouse( bu ).pid # fail if spouse is nothing - but this must be the case
    end
    bur.uc.recipient= target_pid # save a record of who gets for e.g. CT calculation
    bur.pers[target_pid].income[UNIVERSAL_CREDIT] = uce
end



function calc_uc_housing_element!(
    household_result :: HouseholdResult,
    household        :: Household,
    intermed         :: HHIntermed,
    uc               :: UniversalCreditSys,
    hr               :: HousingRestrictions
)
    hhr = household_result # shortcut
    hh = household # shortcut
    eligible_amount = 0.0
    if renter( hh.tenure )
        eligible_amount = household_result.housing.allowed_rent
    elseif ! has_any( hhr.bus[1], WAGES,SELF_EMPLOYMENT_INCOME )
        eligible_amount = household.other_housing_charges  # FIXME go through the list
    end
    bus = get_benefit_units(household)
    nbus = size(bus)[1]
    ndds = 0.0
    if nbus > 1
        if num_qualifying_for_severe_disability( 
            bus[1], 
            hhr.bus[1], 
            1 ) == 0
            for buno in 2:nbus
                # children under 5
                buint = intermed.buint[buno] # shortcut
                if (buint.num_children == 0) || (buint.age_youngest_child >= 5)
                    for adno in bus[buno].adults 
                        pers = bus[buno].people[adno]
                        pr = hhr.bus[buno].pers[adno] # fixme make this `people` to match the bu
                        exempt =  # FIXME parameterise these
                            pers.age < 21 || 
                            any_positive( pr.income,
                                [ATTENDANCE_ALLOWANCE,
                                PENSION_CREDIT,
                                PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
                                DLA_SELF_CARE,
                                CARERS_ALLOWANCE,
                                SCOTTISH_CARERS_SUPPLEMENT,
                                SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_DAILY_LIVING,
                                SCOTTISH_DISABILITY_ASSISTANCE_OLDER_PEOPLE,
                                SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_DAILY_LIVING] )
                        if ! exempt
                            ndds += uc.ndd
                        end
                    end # adult loop
                end # not responsible for u5 child
            end # bu loop 
        end # bu 1 isn't severe disabled
    end # > 1 bu
    hhr.bus[1].uc.housing_element = 
        max(0.0, eligible_amount - ndds )
end

function calc_universal_credit!(
    household_result :: HouseholdResult,
    household        :: Household,
    intermed         :: HHIntermed,
    uc               :: UniversalCreditSys,
    age_limits       :: AgeLimits, 
    hours_limits     :: HoursLimits,
    child_limits     :: ChildLimits,
    hr               :: HousingRestrictions,
    minwage          :: MinimumWage )
    # fixme duped with LMTBens
    hhr = household_result
    hh = household # shortcuts
    if uc.abolished
        return
    end
    household_result.housing = apply_rent_restrictions( 
        household, intermed.hhint, hr )
    bus = get_benefit_units(household)
    nbus = size( bus )[1]
    #
    # Do housing 1st since it needs a seperate 
    # loop round the bus, but we can do everything else 
    # bu by bu. housing element is assigned always
    # to the first benefit unit; everyone else 
    # contributes NDDs.
    #
    calc_uc_housing_element!( 
        hhr,
        hh,
        intermed,
        uc,
        hr 
    )
    for buno in eachindex(bus)
        calc_universal_credit!(
            hhr.bus[buno],
            bus[buno],
            intermed.buint[buno],
            uc,
            age_limits,
            hours_limits,
            child_limits,
            hr,
            minwage
        )
    end

    # hack - council tax rebates for UC Retail_trade_except_of_motor_vehicles_and_motorcycles
    # 20% of any income above Maximum Universal Credit is deducted from maximum CT support 
    # income seems to *include* universal credit, and full wages
    # so grossed back up from the tapered calculated wages above, but
    # otherwise following the same rules. Something like that, anyway.
    #
    recipient = hhr.bus[1].uc.recipient
    if recipient > 0 # some *something* done with UC
        ucrec = hhr.bus[1].pers[recipient].income[UNIVERSAL_CREDIT]
        if ucrec > 0
            bur = household_result.bus[1] 
            ct = total(household_result, LOCAL_TAXES ) 
            # grossed_up_earn = (bur.uc.earned_income/uc.taper)
            ucincome =  
                bur.uc.earnings_before_allowances + # gross earned income back up
                bur.uc.other_income +
                bur.uc.tariff_income +
                ucrec
            excess = max(0.0, ucincome - bur.uc.maximum)
            if excess > 0
                ct = max( 0.0, ct - excess*uc.ctr_taper )  
            end
            bur.uc.ctr = ct
        end
    end
end

end # module