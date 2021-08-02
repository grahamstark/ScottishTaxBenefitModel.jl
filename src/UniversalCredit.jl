module UniversalCredit
#
# UC 
# 
#
using Base: Bool
using ScottishTaxBenefitModel

using .ModelHousehold: 
    BenefitUnit,
    Household, 
    Person,    
    between_ages, 
    count, 
    empl_status_in, 
    ge_age, 
    get_benefit_units,
    has_children, 
    is_head,
    is_lone_parent, 
    is_severe_disability,
    is_spouse,
    is_single, 
    le_age, 
    num_adults, 
    num_carers, 
    pers_is_disabled, 
    search

using .STBParameters: 
    UniversalCreditSys,
    AgeLimits,
    ChildLimits,
    HoursLimits,
    HousingRestrictions,
    MinimumWage

using .Intermediate: 
    MTIntermediate, 
    HHIntermed,
    apply_2_child_policy,
    born_before, 
    has_limited_capactity_for_work_activity,
    is_working_hours,
    num_born_before, 
    working_disabled
 
using .Results: 
    BenefitUnitResult, 
    HouseholdResult, 
    IndividualResult, 
    LMTIncomes,
    LMTResults, 
    LMTCanApplyFor, 
    aggregate_tax, 
    has_any,
    to_string,
    total
    
using .LocalLevelCalculations: 
    apply_rent_restrictions

using .LegacyMeansTestedBenefits:
    num_qualifying_for_severe_disability,
    tariff_income

export 
    calc_universal_credit!, 
    qualifiying_16_17_yo,
    basic_conditions_satisfied,
    calc_standard_allowance,
    disqualified_on_capital

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
    uc           :: UniversalCreditSys,
    age_limits   :: AgeLimits ) :: Bool
    if intermed.all_pension_age 
        return false
    elseif intermed.age_age_oldest_adult < 18
        q1617 = false
        for pid in benefit_unit.adults
            if qualifiying_16_17_yo( bu, bu.people[pid], intermed, uc )
                q1617 = true
                break
            end
        end
        if ! q1617            
            return false
        end
    else
        all_in_educ = true
        for pid in benefit_unit.adults
            # FIXME need a better test than this
            in_educ :: Bool = 
                (benefit_unit.people[pid].employment_status == Student) &&
                (intermed.num_children == 0) && 
                (! pers_is_disabled( benefit_unit.people[pid]))
            if ! in_educ
                all_in_educ = false
                break
            end
        end
        return ! all_in_educ 
    end
end

## FIXME we need the quickie capital question here
function disqualified_on_capital( 
    benefit_unit :: BenefitUnit, 
    uc           :: UniversalCreditSys ) :: Bool
    cap = 0.0
    # FIXME we're doing this twice
    for pid in bu.adults
        for (at,val) in bu.people[pid].assets
           cap += val
        end
    end
    return cap > uc.capital_max
end

function qualifiying_16_17_yo( 
    bu   :: BenefitUnit,
    pers :: Person, 
    intermed :: MTIntermediate, 
    uc :: UniversalCreditSys ) :: Bool
    if pers_is_carer( pers )
        return true
    elseif has_limited_capactity_for_work_activity( pers )
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
    if intermed.num_adults == 1 
        if intermed.age_oldest_adult < 18
            # under 18 single FIXME we should only every need 1 call to this, at the beginning
            if qualifiying_16_17_yo( bu, bu.people[py], intermed, uc )
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
                sa = couple_both_under_25
            end
        elseif intermed.age_oldest_adult < 25
            # under 25 couple(probably - might be u25 single if 2nd adult under 18)
            if  intermed.age_youngest_adult >= 18
                sa = couple_both_under_25
            else
                if qualifiying_16_17_yo( bu, bu.people[yp], intermed, uc )
                    sa = couple_both_under_25
                else
                    sa = uc.age_18_24 # single person, ...
                end
            end
        else 
            # 25+ couple (probably - might be 25+ single if 2nd adult under 18)
            if intermed.age_youngest_adult >= 18
                sa = couple_oldest_25_plus
            else
                ## kinda TODO
                if qualifiying_16_17_yo( bu, bu.people[yp], intermed, uc )
                    sa = couple_oldest_25_plus
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
    uc           :: UniversalCreditSys 
    hours_limits :: HoursLimits, 
    child_limits :: ChildLimits )

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
        ucr.child_element += (1-intermed.num_allowed_children)*uc.subsequent_child
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
        ucr.limited_capcacity_for_work_activity_element = uc.limited_capcacity_for_work_activity
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
    inc = 0.0  
    earn = 0.0
    bur = benefit_unit_result # alias
    for pid in bu.adults
        inc += isum( bur.pers[pid].income, uc.other_income )
        earn += isum( bur.pers[pid].income, uc.earned_income )
        seinc = bur.pers[pid].income[SELF_EMPLOYMENT_INCOME] 
        # FIXME any self employed? what about losses?          
        if bu.people[pid].employment_status == Full_time_Self_Employed 
            min_se = make_min_se( seinc, bu.people[pid].age, uc, minwage )            
        end
        earn += seinc
    end


    if( intermed.num_children > 0 ) || intermed.limited_capacity_for_work
        bur.uc.work_allowance = bur.uc.housing_element > 0 ? 
            work_allowance_w_housing : work_allowance_no_housing
        earn = max( 0.0, earn-bur.uc.work_allowance)
    end
    bur.uc.other_income = inc
    bur.uc.earnings = earn*uc.taper
end

## FIXME we need the extra capital var here benunit.Totsav
function calc_tariff_income!( 
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit :: BenefitUnit, 
    uc           :: UniversalCreditSys )
    cap = 0.0
    bur = benefit_unit_result
    # FIXME we're doing this twice!
    for pid in bu.adults
        for (at,val) in bu.people[pid].assets
            cap += val
        end
    end
    bur.uc.assets = cap    
    bur.uc.tariff_income = tariff_income( cap, uc.capital_min, uc.)
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
    ucr = benefit_unit_result.uc # shortcut
    py :: BigInt = pid_of_youngest_adult( bu )

    if ! basic_conditions_satisfied( 
        benefit_unit, 
        intermed, 
        uc, 
        age_limits )
        ucr.basic_conditions_satisfied = false
        return
    end
    ucr.basic_conditions_satisfied = true
    if disqualified_on_capital( benefit_unit, uc )
        ucr.disqualified_on_capital = true
        return
    end
    ucr.disqualified_on_capital = false
    ucr.standard_allowance = calc_standard_allowance( benefit_unit, intermed, uc )
    calc_elements!( ucr, benefit_unit, intermed, uc, hours_limits, child_limits )
    calc_uc_child_costs!( ucr, benefit_unit, intermed, uc )
    calc_uc_income!( ucr, benefit_unit, intermed, uc, minwage )
    calc_tariff_income!( ucr, bu, uc )
    ucr.maximum = 
        ucr.standard_allowance + 
        ucr.limited_capcacity_for_work_activity_element +
        ucr.child_element +
        ucr.housing_element + 
        ucr.carer_element + 
        ucr.childcare_costs
    head = get_head( bu )
    uce = ucr.maximum - 
        ucr.earned_income - 
        ucr.other_income - 
        ucr.tariff_income
    benefit_unit_result.people[head.pid].income[UNIVERSAL_CREDIT] = max( 0.0, uce )
end



function calc_uc_housing_element!(
    household_result :: HouseholdResult,
    household        :: Household,
    intermed         :: HHIntermed,
    uc               :: UniversalCreditSys,
    hr               :: HousingRestrictions
)
    eligible_amount = household_result.housing.allowed_rent
    bus = get_benefit_units(household)
    nbus = size(bus)[1]
    ndds = 0.0
    if nbus > 1
        if num_qualifying_for_severe_disability( bus[1], hh,bures[1], 1 ) == 0
            for buno in 2:nbus
                # children under 5
                if (intermed.buint.num_children == 0) || (intermed.buint.age_youngest_child >= 5)
                    for adno in bus[buno].adults 
                        pers = bus[buno].people[adno]
                        pr = household_result.bur[buno].pres[adno]
                        exempt =  # FIXME parameterise these
                            pers.age < 21 || 
                            any_positive( pers.inc,
                                [ATTENDANCE_ALLOWANCE,
                                PENSION_CREDIT,
                                PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
                                DLA_SELF_CARE,
                                CARERS_ALLOWANCE]
                        if ! exempt
                            ndds += uc.ndd
                        end
                    end # adult loop
                end # not responsible for u5 child
            end # bu loop 
        end # bu 1 isn't severe disabled
    end # > 1 bu
    household_result.bus[1].uc.housing_element = 
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
        household_result,
        household,
        intermed,
        uc,
        hr 
    )
    for buno in eachindex(bus)
        calc_universal_credit!(
            household_result.bur[buno],
            bus[buno],
            intermed.buint[buno],
            uc,
            age_limits,
            hours,
            hr,
            minwage
        )
    end

end


end