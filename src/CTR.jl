module CTR
 
using ScottishTaxBenefitModel

using .Intermediate
using .LegacyMeansTestedBenefits
using .ModelHousehold
using .Results
using .STBIncomes
using .STBParameters
using .UniversalCredit

export calc_ctr!

function calc_ctr!( 
    household_result :: HouseholdResult,
    household        :: Household,
    intermed         :: HHIntermed,
    ucsys            :: UniversalCreditSys,
    ctrsys           :: CTRSys,
    age_limits       :: AgeLimits, 
    hours_limits     :: HoursLimits,
    child_limits     :: ChildLimits )
    hhr = household_result
    hh = household # shortcuts
    if ctrsys.abolished
        return 
    end
    bu = get_benefit_units(household)[1]
    head = get_head( bu )
    recipient = head.pid
    bur = household_result.bus[1] 
    passported =  has_any( bur, ctrsys.passported_bens... )
    ct = total( household_result, LOCAL_TAXES )
    ucrec = total( bur, UNIVERSAL_CREDIT )
    if ! passported         
        ucincome =  
            bur.uc.earnings_before_allowances + # gross earned income back up
            bur.uc.other_income +
            bur.uc.tariff_income +
            ucrec
        excess = max(0.0, ucincome - bur.ctr.maximum)
        if excess > 0
            ct = max( 0.0, ct - excess*ctrsys.taper )  
        end
        bur.uc.ctr = ct
    end
end

end # module