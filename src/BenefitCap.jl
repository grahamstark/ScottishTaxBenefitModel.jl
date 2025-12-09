module BenefitCap
#
# Apply the benefit cap as described in CPAG 19/20
# ch 52. Somewhat impressionistic and could do 
# with another go.
# 
using ScottishTaxBenefitModel

using .ModelHousehold: 
    BenefitUnit,
    Household, 
    Person

using .STBParameters: 
    BenefitCapSys

using .Results: 
    BenefitUnitResult,
    has_any

using .Definitions

using .Intermediate:
    MTIntermediate

using .STBIncomes

export apply_benefit_cap!

"""
Apply a benefit cap to a benefit unit.

09/07 !!! FIXME: may well never be needed, but we need to make sure pensioners are 
treated as legacy benefits route her
"""
function apply_benefit_cap!( 
    benefit_unit_result :: BenefitUnitResult,
    region           :: Standard_Region,
    benefit_unit     :: BenefitUnit,
    intermed         :: MTIntermediate,
    caps             :: BenefitCapSys,
    route            :: LegacyOrUC )
    # println( "apply_benefit_cap entered; route = $route")
    bu = benefit_unit # shortcut
    bur = benefit_unit_result # shortcut
    if caps.abolished
        bur.bencap.not_applied = true
        return
    end
    if route == legacy_bens 
        for pid in bu.adults
            if bur.pers[pid].income[WORKING_TAX_CREDIT] > 0
                # cpag 21/2 p 1182
                # println("wtc bailing out")
                bur.bencap.not_applied = true
                return
            end
        end
    else
        gross_earnings = 0.0
        for pid in bu.adults
            gross_earnings += isum( bur.pers[pid].income, IncomesSet([WAGES,SELF_EMPLOYMENT_INCOME]))
        end
        if gross_earnings >= caps.uc_incomes_limit
            # println("gross earn; bailing out ")
            bur.bencap.not_applied = true
            return
        end
    end

    if intermed.someone_pension_age || 
        intermed.someone_is_carer ||
        (intermed.num_severely_disabled_adults > 0) ||
        has_any( bur, BEN_CAP_EXEMPTION_BENEFITS ) 
        # println("pension age bailing out")
        bur.bencap.not_applied = true
        return
    end
    
    cap = intermed.num_people == 1 ? 
        caps.outside_london_single :
        caps.outside_london_couple
    if region == London
        cap = intermed.num_people == 1 ? 
            caps.inside_london_single :
            caps.inside_london_couple
    end
    # println("got cap as $cap")
    totbens = 0.0
    included = UC_CAP_BENEFITS
    target_ben = UNIVERSAL_CREDIT
    min_amount = bur.uc.childcare_costs
    if route == legacy_bens 
        included = LEGACY_CAP_BENEFITS 
        target_ben = HOUSING_BENEFIT
        min_amount = 0.5
    end    
    # @show "Benefit Cap entered " route target_ben
       
    recip_pers :: BigInt = -1
    recip_ben = 0.0
    
    for pid in bu.adults
        totbens += isum( bur.pers[pid].income, included )
        if bur.pers[pid].income[target_ben] > 0
            recip_pers = pid
            recip_ben = bur.pers[pid].income[target_ben]
        end
    end
    if recip_ben == 0.0
        println("uc/hb0; returning ")
        return
    end
    excess = totbens - cap
    # println("totbens=$totbens cap=$cap excess=$excess")
    if excess > min_amount
        rd = max( min_amount, recip_ben - excess )
        bur.bencap.reduction = recip_ben - rd        
        bur.pers[recip_pers].income[target_ben] = rd
    end
    # @show recip_pers recip_ben cap 
    bur.bencap.cap_benefits = totbens
    bur.bencap.cap = cap
    # @show bur
end # cap_benefits

end # module
