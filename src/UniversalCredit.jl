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
    is_lone_parent, 
    is_severe_disability,
    is_single, 
    le_age, 
    num_adults, 
    num_carers, 
    pers_is_disabled, 
    search

using .STBParameters: 
    UniversalCreditSys,
    AgeLimits,
    HoursLimits,
    HousingRestrictions,
    MinimumWage

using .Intermediate: 
    MTIntermediate, 
    HHIntermed,
    apply_2_child_policy,
    born_before, 
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

export calc_universal_credit!

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

function basic_conditions_satisfied( 
    benefit_unit :: BenefitUnit, 
    age_limits   :: AgeLimits ) :: Bool
    # TODO
    return true
end

function disqualified_on_capital( 
    benefit_unit :: BenefitUnit, 
    uc           :: UniversalCreditSys ) :: Bool
    # TODO
    return false
end

function qualifiying_16_17_yo( pers :: Person, uc :: UniversalCreditSys ) :: Bool
    # TODO
    return false
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

    if ! basic_conditions_satisfied( benefit_unit, age_limits )
        ucr.basic_conditions_satisfied = false
        return
    end
    if disqualified_on_capital( benefit_unit, uc )
        ucr.disqualified_on_capital = true
        return
    end
    if intermed.num_adults == 1 
        if intermed.age_oldest_adult < 18
            # under 18 single
            if qualifiying_16_17_yo( bu.people[py], uc )
                ucr.standard_allowance = uc.age_18_24    
            end
        elseif intermed.age_oldest_adult < 25
            # u 26 single
            ucr.standard_allowance = uc.age_18_24
        else
            # 25+ single
            ucr.standard_allowance = uc.age_25_and_over
        end
    else
        if  intermed.age_oldest_adult < 18
            # under 18 couple
            np = 0
            for pid in bu.adults
                if qualifiying_16_17_yo( bu.people[pid], uc )
                    np += 1
                end
            end
            if np == 1
                ucr.standard_allowance = uc.age_18_24
            elseif np == 2
                ucr.standard_allowance = couple_both_under_25
            end
        elseif intermed.age_oldest_adult < 25
            # under 25 couple(probably - might be u25 single if 2nd adult under 18)
            if  intermed.age_youngest_adult >= 18
                ucr.standard_allowance = couple_both_under_25
            else
                if qualifiying_16_17_yo( bu.people[yp], uc )
                    ucr.standard_allowance = couple_both_under_25
                else
                    ucr.standard_allowance = uc.age_18_24 # single person, ...
                end
            end
        else 
            # 25+ couple (probably - might be 25+ single if 2nd adult under 18)
            if intermed.age_youngest_adult >= 18
                ucr.standard_allowance = couple_oldest_25_plus
            else
                ## kinda TODO
                if qualifiying_16_17_yo( bu.people[yp], uc )
                    ucr.standard_allowance = couple_oldest_25_plus
                else
                    ucr.standard_allowance = uc.age_25_and_over # single person, ...
                end
            end
        end # over 25 couple
    end

    

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