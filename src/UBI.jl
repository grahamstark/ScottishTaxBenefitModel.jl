module UBI
#=
Might as well do this while we're at it.
A very basic basic income; based roughly on 

Painter, Anthony, Jamie Cooke, and Ahmed Aima. 2019. ‘A Basic Income for Scotland’. Royal Society for the encouragement of Arts, Manufactures and Commerce. https://www.thersa.org/globalassets/pdfs/rsa-a-basic-income-for-scotland.pdf.
=#

using ScottishTaxBenefitModel
using .ModelHousehold: 
    BenefitUnit,
    Household, 
    Person,
    get_benefit_units

using .Intermediate: 
    MTIntermediate, 
    HHIntermed

using .STBParameters: 
    HoursLimits,
    LegacyMeansTestedBenefitSystem,
    MinimumWage,
    TaxBenefitSystem,
    UBISys,
    UniversalCreditSys

using .STBIncomes
using .Definitions
using .LegacyMeansTestedBenefits: make_lmt_benefit_applicability
using .UniversalCredit: calc_uc_income, calc_tariff_income

using .Results: 
    BenefitUnitResult, 
    LMTCanApplyFor,
    HouseholdResult

export 
    calc_UBI!, 
    make_ubi_post_adjustments!

function make_ubi_post_adjustments!( 
    hres   :: HouseholdResult,
    ubisys :: UBISys )
    for bn in eachindex( hres.bus )
        bres = hres.bus[bn]
        if ubisys.mt_bens_treatment == ub_keep_housing
            # TODO add assertions that things are correctly turned off
            if bres.uc.recipient > 0
                uc = bres.pers[bres.uc.recipient].income[UNIVERSAL_CREDIT]
                uc = min( uc, bres.uc.housing_element )
                bres.pers[bres.uc.recipient].income[UNIVERSAL_CREDIT] = uc
            end
            #
            # I think these have to be left on so we can do hb passporting
            # so we set them to zero ex post
            for (pid,pers) in bres.pers
                pers.income[INCOME_SUPPORT] = 0.0
                pers.income[NON_CONTRIB_JOBSEEKERS_ALLOWANCE] = 0.0
                pers.income[NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE] = 0.0
            end
        end
    end
end

"""
Strategy: use eligibility calcs for wtc, is .. 
Dan's conjoint criteria
People in and out of work are entitled
Everyone is entitled but people of working age who are not disabled are required to look for work
Only people in work are entitled
Only people out of work are entitled 
"""
function is_elig(     
    benefit_unit        :: BenefitUnit,
    intermed            :: MTIntermediate,    
    ubisys              :: UBISys,
    mt_ben_sys          :: LegacyMeansTestedBenefitSystem,
    hrs                 :: HoursLimits) ::Bool
    if ubisys.entitlement == ub_ent_all 
        return true
    end
    # in case we've switched these off ..    
    elig = false
    ctc_ab = mt_ben_sys.child_tax_credit.abolished
    wtc_ab = mt_ben_sys.working_tax_credit.abolished
    hb_ab = mt_ben_sys.hb.abolished
    ctr_ab = mt_ben_sys.ctr.abolished
    sc_ab = mt_ben_sys.savings_credit.abolished
    isa_ab = mt_ben_sys.isa_jsa_esa_abolished 

    mt_ben_sys.child_tax_credit.abolished = false
    mt_ben_sys.working_tax_credit.abolished = false
    mt_ben_sys.hb.abolished = false
    mt_ben_sys.ctr.abolished = false
    mt_ben_sys.savings_credit.abolished = false
    mt_ben_sys.isa_jsa_esa_abolished = false
    whichb = make_lmt_benefit_applicability( mt_ben_sys, intermed, hrs )
    if( whichb.sc || whichb.pc ) # always qualify anyone qualifying for pensioner benefit
        elig = true
    else ## FIXME could some bu fall between these cracks? Add an assert?
        elig = 
            if ubisys.entitlement == ub_ent_all_but_non_jobseekers 
                ! whichb.is
            elseif ubisys.entitlement == ub_ent_only_in_work 
                whichb.wtc 
            elseif ubisys.entitlement == ub_ent_only_not_in_work
                whichb.is || whichb.esa || whichb.jsa
            end
    end
    mt_ben_sys.child_tax_credit.abolished = ctc_ab
    mt_ben_sys.working_tax_credit.abolished = wtc_ab
    mt_ben_sys.hb.abolished = hb_ab
    mt_ben_sys.ctr.abolished = ctr_ab 
    mt_ben_sys.savings_credit.abolished = sc_ab
    mt_ben_sys.isa_jsa_esa_abolished = isa_ab
    return elig
end 

function calc_UBI!( 
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit        :: BenefitUnit,
    ubisys              :: UBISys,
    mt_ben_sys          :: LegacyMeansTestedBenefitSystem,
    uc_sys              :: UniversalCreditSys,
    intermed            :: MTIntermediate,
    hrs                 :: HoursLimits )
    scp = 0.0
    bu = benefit_unit
    bur = benefit_unit_result # shortcuts 
    if is_elig( bu, intermed, ubisys, mt_ben_sys, hrs )
        for (pid,pers) in bu.people
            if pers.age < ubisys.adult_age 
                bi = ubisys.child_amount
            elseif pers.age < ubisys.retirement_age
                bi = ubisys.adult_amount
            else
                bi = ubisys.universal_pension
            end
            bur.pers[pid].income[BASIC_INCOME] = bi
        end
    end
end

function calc_UBI!( 
    household_result :: HouseholdResult,
    hh               :: Household,
    ubisys           :: UBISys,
    mt_ben_sys       :: LegacyMeansTestedBenefitSystem,
    uc_sys           :: UniversalCreditSys,
    intermed         :: HHIntermed,
    hrs              :: HoursLimits  )
    if ubisys.abolished
        return
    end
    bus = get_benefit_units( hh )
    for bn in eachindex( bus )
        calc_UBI!(
            household_result.bus[bn],
            bus[bn],
            ubisys,
            mt_ben_sys,
            uc_sys,
            intermed.buint[bn],
            hrs
        )
    end
end

end # module