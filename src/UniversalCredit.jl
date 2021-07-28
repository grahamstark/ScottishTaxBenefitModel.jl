module UniversalCredit
#
# UC 
# 
#
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
    if intermed.num_adults == 1 
        if intermed.age_oldest_adult < 18

        elseif intermed.age_oldest_adult < 25

        else

        end
    else

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