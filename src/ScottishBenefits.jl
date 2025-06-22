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
    if scpsys.abolished
        return
    end
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
DISCRETIONARY_HOUSING_PAYMENT can be used for other things, too, but not so far
in this model.

I'm basically taking a wild guess at how this works for UC
since I can't find any documentation on what 'housing element'
means in this context - it can't mean all of it
regardless of total UC entitlement.

Assigns a DISCRETIONARY_HOUSING_PAYMENT of the 
minimum of hb/uc hosts and the amount of
rooms reduction to whoever recieves uc/hb in the 1st benefit unit. 
'But for weekly or monthly payments, the amount of a discretionary housing payment cannot be more than the amount of universal credit or housing benefit that you get to help with your rent.'

See: https://cpag.org.uk/scotland/welfare-rights/scottish-benefits/discretionary-housing-payments-scotland
TODO parameterise this somehow - mitigate fully or whatever.
"""
function calc_bedroom_tax_mitigation!( 
    hr    :: HouseholdResult, 
    hh    :: Household )
    # DISCRETIONARY_HOUSING_PAYMENT
    if ! is_social_renter( hh.tenure )
        return
    end
    hrep = hr.bus[1].legacy_mtbens.hb_recipient
    urep = hr.bus[1].uc.recipient
    uche = hr.bus[1].uc.housing_element
    benred = hr.bus[1].bencap.reduction
    hb = 0.0
    if hrep > 0
        hb = hr.bus[1].pers[hrep].income[HOUSING_BENEFIT]
    end
    uc = 0.0
    if urep > 0
        uc = hr.bus[1].pers[urep].income[UNIVERSAL_CREDIT]
    end
    # see:
    # https://www.gov.scot/publications/scottish-discretionary-housing-payment-guidance-manual/pages/3/
    # 
    rrd = hr.housing.rooms_rent_reduction + benred 
    if (rrd > 0) 
        # the > housing tests here are kinda redundant, but still ..
        if uc > 0 
            hr.bus[1].pers[urep].income[DISCRETIONARY_HOUSING_PAYMENT] = max(0.0,rrd)
            # !!! FIXME!! Assume uc housing element is the 1st part to be withdrawn
            # with income so eligibiliity for DHP ceases
            # when income > housing element.
            # FIXME I think that's how it must work but I don't know from
            # any documentation I have that this is right
            # uc itself is here in case this hhls is caught
            # by the benefit cap. 
            #=
            uchousing = max(
                0.0, 
                uche - hr.bus[1].uc.total_income - benred ) 
            hr.bus[1].pers[urep].income[DISCRETIONARY_HOUSING_PAYMENT] = 
                min( uchousing, rrd )
            =#
        elseif hrep > 0 && hb > 0 
            # can't exceed housing benefit
            hr.bus[1].pers[hrep].income[DISCRETIONARY_HOUSING_PAYMENT] = 
                min( hb , rrd )
        end
    end
    =#
end # calc_ ..
 
end # module 