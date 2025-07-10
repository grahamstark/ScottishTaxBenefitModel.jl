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

"""
    see: https://westlothian.gov.uk/article/32336/Non-dependant-deductions
    (only explanation of this I can find).
1. Person aged at least 25 years receiving IS/JSA(IB)/ESA(IR)	Nil
2. Person aged at least 25 years receiving UC - no earned income	Nil
3. Person aged 18 to 24 years receiving IS/JSA(IB)/ESA(IR)(assessment phase)	Nil
4. Person aged 18 to 24 years receiving ESA(IR)(main phase)	Nil
5. Person aged 18 to 24 years receiving universal credit - no earned income	Nil
6. Person receiving Pension Credit	Nil
7. Person aged less than 18 years whether in remunerative work or not	Nil
8. Aged 18 or over and not in remunerative work	£5.35
    - Gross Weekly income less than £273.00	£5.35
    - Gross Weekly income between £273.00 and £473.99	£10.35
    - Gross Weekly income between £474.00 and £585.99	£13.15
    - Gross Weekly income £586 and above	£15.95
"""
function calc_ctr_ndds( 
    bur      :: BenefitUnitResult,
    intermed :: MTIntermediate, 
    ctr      :: CTRSys ) :: Real
    gross_weekly_income = sum( bur, GROSS_INCOME )
    if has_any( bur, ctrsys.passported_bens... ) # 1..4, 6
        return 0.0
    elseif intermed.age_oldest_adult <= 18 # 7
        return 0.0 
    elseif has_any( bur, UNIVERSAL_CREDIT ) && 
         (bur.uc.earnings_before_allowances == 0) &&
         (intermed.age_oldest_adult <= 24) # 5
        return 0.0
    end
    n = size(hb.ndd_incomes)[1]
    w = n
    for i in 1:n
        if ctr.ndd_incomes[i] > gross_weekly_income
            w = i
            break
        end
    end
    ndd = ctr.ndd_deductions[w]
    return ndd
end

function calc_ctr!( 
    household_result :: HouseholdResult,
    household        :: Household,
    intermed         :: HHIntermed,
    ucsys            :: UniversalCreditSys,
    ctrsys           :: CTRSys,
    age_limits       :: AgeLimits, 
    hours_limits     :: HoursLimits,
    child_limits     :: ChildLimits,
    minwage          :: MinimumWage)
    if ctrsys.abolished
        return 
    end
    bus = get_benefit_units(household)
    nbus = length( bus )
    bu = bus[1]
    head = get_head( bu )
    recipient = head.pid
    bur = household_result.bus[1] 
    passported =  has_any( bur, ctrsys.passported_bens... )
    ctr = total( household_result, LOCAL_TAXES )
    if ! passported      
        if UniversalCredit.disqualified_on_capital( bu, intermed.buint[1], ucsys )
            bur.ctr.disqualified_on_capital = true
            return
        end
        # recalulate maximum, using all children, not child limit children, but otherwise
        # UC calculation
        bur.ctr.standard_allowance = calc_standard_allowance( bu, intermed.buint[1], ucsys )
        UniversalCredit.calc_elements!( 
            bur.ctr, 
            bu, 
            intermed.buint[1], 
            num_children(bu), 
            ucsys, 
            hours_limits, 
            child_limits )
        UniversalCredit.calc_uc_income!( bur.ctr, bur, bu, intermed.buint[1], ucsys, minwage )
        UniversalCredit.calc_tariff_income!( bur.ctr, intermed.buint[1], bu, ucsys )
        bur.ctr.maximum = 
            bur.ctr.standard_allowance + 
            bur.ctr.limited_capacity_for_work_activity_element +
            bur.ctr.child_element +
            bur.ctr.housing_element + 
            bur.ctr.carer_element + 
            bur.ctr.childcare_costs
        # income is precalulated UC income, plus UC itself
        ucrec = total( bur, UNIVERSAL_CREDIT )
        
        ucincome =  
            bur.uc.earnings_before_allowances + # gross earned income back up
            bur.uc.other_income +
            bur.uc.tariff_income +
            ucrec
        excess = max(0.0, ucincome - bur.ctr.maximum)
        @show total( bur, WAGES)
        @show ctr
        @show bur.ctr.maximum
        @show ucincome
        @show excess
        @show ctrsys.taper
        if excess > 0
            ctr = max( 0.0, ctr - excess*ctrsys.taper )  
        end
    end # not passported
    ndds = 0.0
    for bn in 2:nbus
        ndds += calc_ctr_ndds(  
            household_result.bus[bn], 
            intermed.buint[bn],
            ctrsys )
    end
    ctr = max( 0.0, ctr-ndds )
    @show ctr
            
    bur.pers[recipient].income[COUNCIL_TAX_BENEFIT] = ctr
end # calc_ctr!

end # module