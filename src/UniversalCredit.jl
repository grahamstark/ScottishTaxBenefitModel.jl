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

function disqualified_on_capital( 
    benefit_unit :: BenefitUnit, 
    uc           :: UniversalCreditSys ) :: Bool
    cap = 0.0
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

function calc_elements( benefit_unit, intermed, uc, hours_limits )
    # child elements
    intermed.num_allowed_children
end

function calc_universal_credit!(
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit     :: BenefitUnit,
    intermed         :: MTIntermediate,
    uc               :: UniversalCreditSys,
    age_limits       :: AgeLimits, 
    hours            :: HoursLimits,
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
    if disqualified_on_capital( benefit_unit, uc )
        ucr.disqualified_on_capital = true
        return
    end
    ucr.standard_allowance = calc_standard_allowance( benefit_unit, intermed, uc )
    ucr.elements = calc_elements( benefit_unit, intermed, uc, hours_limits )

end

function calc_universal_credit!(
    household_result :: HouseholdResult,
    household        :: Household,
    intermed         :: HHIntermed,
    uc               :: UniversalCreditSys,
    age_limits       :: AgeLimits, 
    hours            :: HoursLimits,
    hr               :: HousingRestrictions,
    minwage          :: MinimumWage )
    # fixme duped with LMTBens
    household_result.housing = apply_rent_restrictions( 
        household, intermed.hhint, hr )
    bus = get_benefit_units(household)
    nbus = size( bus )[1]
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