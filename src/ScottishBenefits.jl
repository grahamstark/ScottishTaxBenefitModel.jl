module ScottishBenefits
#=
# This module is a holder for all the Scotland-specific 
# benefits - currently SCP and bedroom tax 
# mitigation,
=#
using ScottishTaxBenefitModel
using .ModelHousehold: 
    BenefitUnit,
    Household, 
    Person,
    count,
    get_head,
    get_spouse,
    le_age
    
using .STBParameters: 
    ScottishChildPayment

using .STBIncomes
using .Definitions

using .Intermediate 
using .Results: BenefitUnitResult, HouseholdResult, has_any

export calc_scottish_child_payment!, 
    calc_bedroom_tax_mitigation!

function calc_scottish_child_payment!( 
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit        :: BenefitUnit,
    intermed            :: MTIntermediate,
    scpsys              :: ScottishChildPayment )
    scp = 0.0
    bu = benefit_unit
    bur = benefit_unit_result # shortcuts 
    nkids = count( bu, le_age, scpsys.maximum_age )   
    if( nkids > 0 ) && has_any( bur, scpsys.qualifying_benefits... )
        scp = nkids * scpsys.amount
        spouse = get_spouse( bu )
        target_pid = BigInt(-1)
        if spouse === nothing
            target_pid = get_head( bu ).pid
        else 
            target_pid = spouse.pid
        end
        bur.pers[target_pid].income[SCOTTISH_CHILD_PAYMENT] = scp
    end
end

"""

This is the Scottish Government's bedroom tax
removal for social renters. 
DISCRESIONARY_HOUSING_PAYMENT can be used for other things, too, but not so far
in this model.

Assigns a DISCRESIONARY_HOUSING_PAYMENT of the 
minimum of hb/uc hosts and the amount of
rooms reduction to whoever recieves uc/hb in the 1st benefit unit. 
'But for weekly or monthly payments, the amount of a discretionary housing payment cannot be more than the amount of universal credit or housing benefit that you get to help with your rent.'

See: https://cpag.org.uk/scotland/welfare-rights/scottish-benefits/discretionary-housing-payments-scotland
TODO parameterise this somehow - mitigate fully or whatever.
"""
function calc_bedroom_tax_mitigation!( 
    hr    :: HouseholdResult, 
    hh    :: Household )
    # DISCRESIONARY_HOUSING_PAYMENT
    if ! is_social_renter( hh.tenure )
        return
    end
    hrep = hr.bus[1].legacy_mtbens.hb_recipient
    urep = hr.bus[1].uc.recipient
    if hr.housing.rooms_rent_reduction > 0 
        # the > housing tests here are kinda redundant, but still ..
        if urep > 0 && hr.bus[1].uc.housing_element > 0
            # can't exceed uc housing element
            hr.bus[1].pers[urep].income[DISCRESIONARY_HOUSING_PAYMENT] = 
                min( hr.bus[1].uc.housing_element, hr.rooms_rent_reduction )
        elseif hrep > 0 && hr.bus[1].pers[hrep].income[HOUSING_BENEFIT] > 0 
            # can't exceed housing benefit
                hr.bus[1].pers[hrep].income[DISCRESIONARY_HOUSING_PAYMENT] = 
                    min( hr.bus[1].pers[hrep].income[HOUSING_BENEFIT], 
                    hr.rooms_rent_reduction )    
        end
    end
end # calc_ ..
 
end # module 