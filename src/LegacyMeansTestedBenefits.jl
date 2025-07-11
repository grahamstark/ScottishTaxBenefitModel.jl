module LegacyMeansTestedBenefits
#
# This module implements the pre-universal credit means-tested benefit system.
#
using ArgCheck
using Base: Bool
using Dates
using ScottishTaxBenefitModel
using .Definitions

using .STBIncomes

using .Utils: to_md_table

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
    AgeLimits, 
    ChildTaxCredit,
    HoursLimits, 
    HousingBenefits, 
    HousingRestrictions,
    IncomeRules, 
    IncomeRules,  
    LegacyMeansTestedBenefitSystem, 
    MinimumWage, 
    NonMeansTestedSys,
    PersonalAllowances, 
    Premia, 
    SavingsCredit, 
    WorkingTaxCredit, 
    reached_state_pension_age, 
    state_pension_age
    
using .GeneralTaxComponents: 
    RateBands,
    TaxResult, 
    calctaxdue

using .Results: 
    BenefitUnitResult, 
    HouseholdResult, 
    IndividualResult, 
    LMTIncomes,
    LMTResults, 
    LMTCanApplyFor, 
    aggregate_tax, 
    gross_pension_contributions,
    has_any,
    to_string,
    total

using .Intermediate: 
    MTIntermediate, 
    HHIntermed,
    apply_2_child_policy,
    born_before, 
    is_working_hours,
    make_recipient,
    num_born_before, 
    working_disabled

using .LocalLevelCalculations: 
    apply_rent_restrictions

export 
    calc_legacy_means_tested_benefits, 
    calc_allowances, 
    calc_incomes,
    calc_NDDs, 
    calc_premia,
    calculateHB_CTR!,
    calcWTC_CTC!, 
    make_lmt_benefit_applicability, 
    num_qualifying_for_severe_disability,
    tariff_income



"""
Incomes for old style mt benefits
The CPAG guide ch 21/21 has over 100 pages on this stuff
this can no more than catch the gist.
"""
function calc_incomes( 
    which_ben :: LMTBenefitType, # esa hb is jsa pc wtc ctr pc sc
    bu        :: BenefitUnit, 
    bur       :: BenefitUnitResult, 
    intermed  :: MTIntermediate,
    incrules  :: IncomeRules,
    hours     :: HoursLimits ) :: LMTIncomes 
    T = typeof( incrules.permitted_work )
    mntr = bur.legacy_mtbens # shortcut
    inc = LMTIncomes{T}()
    gross_earn = zero(T)
    net_earn = zero(T)
    other = zero(T)
    
    if which_ben in [hb,ctr]
        inclist = incrules.hb_incomes
    elseif which_ben == pc
        inclist = incrules.pc_incomes
    elseif which_ben == sc
        inclist = incrules.sc_incomes
    else
        inclist = incrules.incomes
    end
    # children's income doesn't count see cpag p421, so:
    for pid in bu.adults
        pers = bu.people[pid]
        pres = bur.pers[pid]
        gpc = gross_pension_contributions(pres)
        gross = 
            pres.income[WAGES] +
            pres.income[SELF_EMPLOYMENT_INCOME] # this includes losses
        if which_ben in [pc,is,jsa,esa,hb,ctr]
            net = 
                gross - ## FIXME parameterise this so we can use gross/net
                pres.it.non_savings_tax - ## FIXME?? income[INCOME_TAX] ??
                pres.income[NATIONAL_INSURANCE] - 
                0.5*gpc # .income[PENSION_CONTRIBUTIONS_EMPLOYEE]
            # println( "net=$net; gross=$gross pres.it.non_savings_tax = $(pres.it.non_savings_tax) gpc=$gpc ni=$(pres.income[NATIONAL_INSURANCE])")
        else
            # wtc,ctr all pension contributions but not IT/NI
            gross = max( 0.0, gross - gross_pension_contributions(pres)) # .income[PENSION_CONTRIBUTIONS_EMPLOYEE])
            net = gross
        end
        gross_earn += gross
        net_earn += max( 0.0, net )
        other += isum( pres.income, inclist )
        #    data=pers.income, 
        #    calculated=pres.incomes, 
        #    included=inclist )
    end
    # disregards
    # if which_ben in [hb,jsa,is,]
    # FIXME this is not quite right for ESA
    disreg = intermed.is_sing ?  incrules.low_single : incrules.low_couple
    
    if( which_ben == esa ) 
        if ! search( bu, is_working_hours, hours.lower )
            disreg = incrules.high
            # and some others ... see CPAG 
        end
    elseif which_ben in [hb,ctr,jsa,is,pc]
        if intermed.is_sparent            
            disreg = which_ben == hb ? incrules.lone_parent_hb : incrules.high 
        elseif ! isdisjoint( mntr.premia, [
                carer_single, 
                carer_couple, 
                disability_couple, 
                disability_single, 
                severe_disability_couple, 
                severe_disability_single, 
                enhanced_disability_couple, 
                enhanced_disability_single] )
            disreg = incrules.high
        end       
    end

    if( which_ben in [hb,ctr] ) 
        # fixme do this above
        if has_any( bur, CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE, NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE )     
            disreg = incrules.high
        end
        # HB disregard CPAG p432 this, too, is very approximate
        # work 30+ hours - should really check premia if haskeys( mtr.premia )
        extra = 0.0
        # println( "hours.higher $(hours.higher)")
        if search( bu, is_working_hours, hours.higher )
            extra = incrules.hb_additional 
            # println( "extra=$extra")
        elseif search(  bu, is_working_hours, hours.lower )
            if intermed.is_sparent || (intermed.num_children > 0) || intermed.is_disabled
                extra = incrules.hb_additional
            end
        end
        disreg += extra
        # childcare in HB - costs are assigned in frs to the children
        if ( intermed.num_children > 0 ) 
            maxcc = intermed.num_children == 1 ? incrules.childcare_max_1 : incrules.childcare_max_2
            cost_of_childcare = 0.0
            for pid in bu.children 
                cost_of_childcare += bu.people[pid].cost_of_childcare 
            end
            inc.childcare = min(cost_of_childcare, maxcc )
        end
    end

    """
    not even remotely right ... cpag 21
    """
    #=
    cap = 0.0
    for pid in bu.adults
        if bu.people[pid].over_20_k_saving
            cap = 100_000 # some huge number bigger than any reasonable capmax
        else
            for (at,val) in bu.people[pid].assets
                cap += val
            end
        end
    end
    =#
    inc.other_income = other
    inc.capital = intermed.net_financial_wealth
    inc.gross_earnings = gross_earn
    inc.net_earnings = max(0.0, net_earn - disreg ) - inc.childcare
 
    capmin = incrules.capital_min
    capmax = incrules.capital_max
    tariff = incrules.capital_tariff
    if intermed.someone_pension_age
        tariff = incrules.pensioner_tariff
        if which_ben == pc 
            capmin = incrules.pc_capital_min
            capmax = incrules.pc_capital_max
        else
            capmin = incrules.pensioner_capital_min
            capmax = incrules.pensioner_capital_max
        end
    end
    
    inc.tariff_income = tariff_income(inc.capital, capmin, tariff )
    inc.disqualified_on_capital = inc.capital > capmax
    inc.total_income = inc.net_earnings + inc.other_income + inc.tariff_income    
    inc.disregard = disreg
    return inc
end

"""
The strategy here is to include *all* benefits the BU is entitled to
and then decide later on which ones to route to. Source: CPAG chs 9-15
'Who can get XX' sections.
"""
function make_lmt_benefit_applicability( 
    mt_ben_sys   :: LegacyMeansTestedBenefitSystem,
    intermed :: MTIntermediate,
    hrs      :: HoursLimits ) :: LMTCanApplyFor
    whichb = LMTCanApplyFor()
    if intermed.someone_pension_age #!! fixme both pension age for new claims 2019=>
        whichb.pc = true
    end
    if intermed.someone_pension_age_2016
        whichb.sc = true
    end
    # println( "intermed: intermed.num_working_16_or_less=$(intermed.num_working_16_or_less) intermed.economically_active=$(intermed.economically_active) intermed.num_working_16_or_less=$(intermed.num_working_16_or_less)")
    # FIXME: the all-student one should actually let through ESA, I think
    if (! intermed.all_student_bu ) && (! intermed.all_pension_age ) && (intermed.num_working_16_or_less >= 1)
        if ((intermed.num_adults == 1) ||
           ((intermed.num_adults == 2) && (intermed.num_working_24_plus == 0)))
            if intermed.limited_capacity_for_work
                whichb.esa = true 
            # CPAG 21/2 p236/7
            elseif( intermed.num_adults == 1) && (intermed.num_allowed_children>0) && 
                ((intermed.age_youngest_child <= 5) || (intermed.age_oldest_adult < 18))
                    whichb.is = true
            elseif intermed.economically_active
                whichb.jsa = true  
            else
                whichb.is = true
            end
        end
    end # all pens age
    
    #
    # Tax credits
    # CTC - easy - but route pensioners to pension credit even 
    # if they have children - this is how Age Concern do it, anyway.
    #
    if intermed.has_children && ( ! whichb.pc )
        whichb.ctc = true
    end
    #
    # WTC - not quite so easy
    #
    if intermed.all_student_bu
        whichb.wtc = false
    elseif intermed.someone_working_ft_and_25_plus
        whichb.wtc = true
    elseif (intermed.total_hours_worked >= hrs.med) && (intermed.num_working_pt>0) && intermed.has_children 
        # ie. 24 hrs worked total and one person  >= 16 hrs and has children
        whichb.wtc = true
    elseif (intermed.num_working_pt>0) && intermed.someone_pension_age
        whichb.wtc = true
    elseif (intermed.num_working_pt>0) && intermed.is_sparent
        whichb.wtc = true
    elseif intermed.working_disabled
        whichb.wtc = true
    end
   # FIXME not really true
    if( intermed.benefit_unit_number == 1 )
        whichb.hb = ! intermed.all_student_bu
        whichb.ctr = true
    end
    # check!!! is this correct? is, etc. or wtc over pc/sc
    if( whichb.esa || whichb.jsa || whichb.is ) ## || whichb.wtc)
        whichb.pc = false
        whichb.sc = false
    end
    # FIXME we have abolished code twice!
    # override these if something abolished
    if mt_ben_sys.isa_jsa_esa_abolished 
        whichb.jsa = false
        whichb.is = false
        whichb.esa = false
        # FIXME problem with pension credit here
        whichb.pc = false
    end
    whichb.ctc &= (! mt_ben_sys.child_tax_credit.abolished)
    whichb.wtc &= (! mt_ben_sys.working_tax_credit.abolished)
    whichb.hb &= (! mt_ben_sys.hb.abolished)
    whichb.ctr &= (! mt_ben_sys.ctr.abolished)
    whichb.sc &= (! mt_ben_sys.savings_credit.abolished)
    # @show whichb
    return whichb
end # make_lmt_benefit_applicability

# CTC disabled child definition:
#
# Getting Disability Living Allowance (DLA), Personal Independence Payment (PIP) or Armed Forces Independence Payment (AFIP)
# In hospital but otherwise would get DLA, PIP or AFIP
# Certified blind (or were until less than 28 weeks before you made the claim)

#
#

# Disabled adult for wtc
# Answer yes if you work at least 16 hours a week and any of the following apply to you:
#
#    you get a disability benefit, eg Disability Living Allowance, Attendance Allowance or Personal Independence Payment
#    you have recently been getting disability benefit, eg Incapacity Benefit or Employment and Support Allowance
#    you have a disability that makes it hard for you to get a job, eg you’re deaf or blind
#


"""
tariff income from capital. 
See CPAG p488 £1 pw for every £250, or part of £250 above 6,000
"""
function tariff_income( cap :: Real, capital_min::Real, tariff :: Real )::Real
    return ceil( max(0.0, cap-capital_min)/tariff)
end

"""
WRONG AND NOT USED!
CPAG 2019/20 p347. I *thik* this is what it means ...
Moved to own function since it's convoluted.
FIXME move this as it's being used in the UC module
"""
function num_qualifying_for_severe_disability( 
    bu    :: BenefitUnit,
    bures :: BenefitUnitResult,
    num_bus :: Int ) :: Int
    if num_bus > 1
        return 0;
    end
    n = 0
    for pid in bu.adults
        pers = bu.people[pid]
        if (pers.dla_self_care_type in [high,mid] ||
              pers.attendance_allowance_type != missing_lmh ||
              pers.registered_blind || 
              pers.pip_daily_living_type == enhanced_pip )
              n += 1
        end
        if bures.pers[pid].income[CARERS_ALLOWANCE] > 0
            n -= 1
        end
    end    
    return max( 0, n )
end

"""
See: https://www.gov.uk/disability-premiums/eligibility
"""
function qualifies_for_disability_premium( 
    pers :: Person, 
    pres :: IndividualResult,
    prem_sys :: Premia ) :: Bool
    if pers.registered_blind
        return true
    end
    if any_positive( pres.income, prem_sys.disability_premium_qualifying_benefits)
        return true
    end
    return false
end

function qualifies_for_enhanced_disability(
    pers     :: Person, 
    pres     :: IndividualResult,
    prem_sys :: Premia,
    nmt      :: NonMeansTestedSys,
    age_limits :: AgeLimits ) :: Bool
    if reached_state_pension_age(
        age_limits,
        pers.age,
        pers.sex )
        return false
    end
    if any_positive( pres.income, [NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE])
        return true
    end
    for p1 in [
        PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
        ADP_DAILY_LIVING]
        if p1 in prem_sys.enhanced_disability_premium_qualifying_benefits
            if pres.income[p1] >= nmt.pip.dl_enhanced
                return true
            end
        end
    end
    for p1 in [DLA_SELF_CARE, CHILD_DISABILITY_PAYMENT_CARE]
        if p1 in prem_sys.enhanced_disability_premium_qualifying_benefits
            if pres.income[p1] >= nmt.dla.care_high
                return true
            end
        end
    end
    ## FIXME support group for ESA
    return false
end

"""
FIXME this should be over the HOUSEHOLD not the benefit unit,
I think
"""
function num_adults_qualifiying_for_disability_premium(
    bu    :: BenefitUnit,
    bures :: BenefitUnitResult,
    prem_sys :: Premia ) :: Integer
    n = 0
    for pid in bu.adults
        if qualifies_for_disability_premium( bu.people[pid], bures.pers[pid], prem_sys )
            n += 1
        end            
    end
    return n
end

function qualifies_for_severe_disability_premium(
    pers     :: Person, 
    pres     :: IndividualResult,
    prem_sys :: Premia ) :: Bool
    return qualifies_for_disability_premium( pers, pres, prem_sys ) &&
        any_positive( pres.income, 
            [PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
            ADP_DAILY_LIVING,
            DLA_SELF_CARE, 
            CHILD_DISABILITY_PAYMENT_CARE,
            ATTENDANCE_ALLOWANCE, 
            PENSION_AGE_DISABILITY] )
end 

function calc_premia(     
    which_ben :: LMTBenefitType,
    bu        :: BenefitUnit,
    bures     :: BenefitUnitResult,
    intermed  :: MTIntermediate, 
    prem_sys  :: Premia,
    nmt       :: NonMeansTestedSys,
    age_limits:: AgeLimits ) :: Tuple
    premium = 0.0
    premset = LMTPremiaSet()
    # disabled child premium
    num_ads = num_adults( bu )
    # !!!!! CAREFUL lone_parent_premia DOESN'T EXIST ANYMORE and I'm unsure exactly what the 
    # rules for lone parents were. prem_sys.family_lone_parent should always be
    # zero in actual param files !!!
    if intermed.is_sparent && (prem_sys.family_lone_parent > 0)
        premium += prem_sys.family_lone_parent
        union!( premset, [lone_parent_premium])
    end
    # !!! Likewise family premium isn't actually used 
    if intermed.has_children && (prem_sys.family > 0)
        premium += prem_sys.family
        # @show premset
        # @show family_premium
        union!( premset, [family_premium])
    end
    if which_ben in [hb,ctr]
        if intermed.num_disabled_children > 0
            premium += intermed.num_disabled_children*prem_sys.disabled_child   
            union!( premset, [disabled_child])
        end
    end
    # carer's premium - all benefits, I think.
    if intermed.num_carers == 1
        premium += prem_sys.carer_single
        union!( premset,[carer_single] )
    elseif intermed.num_carers == 2
        # FIXME what if 1 is a child?
        premium += prem_sys.carer_couple
        union!( premset, [carer_couple] )
    end
    # disability premiums 
    ndis = num_adults_qualifiying_for_disability_premium(
        bu, bures, prem_sys )
    if which_ben in [is, jsa, hb, ctr] # FIXME not quite right but perhaps near enough - should be reached pension age? CPAG19 p344
        if ndis == 1
            premium += prem_sys.disability_single
            union!( premset,[disability_single])         
        elseif ndis == 2
            premium += prem_sys.disability_couple
            union!( premset,[disability_couple])
        end
    end
    # enhanced disability - also for ESA
    if which_ben in [is, jsa, hb, ctr, esa]
        nenh = 0
        for pid in bu.adults
            nenh += qualifies_for_enhanced_disability(
                    bu.people[pid],
                    bures.pers[pid],
                    prem_sys,
                    nmt,
                    age_limits )
        end
        if nenh == 1
            premium += prem_sys.enhanced_disability_single
            union!( premset, [enhanced_disability_single] )
        elseif nenh == 2
            premium += prem_sys.enhanced_disability_couple
            union!( premset,[enhanced_disability_couple]) 
        end
    end
    # severe disability premium
    if ndis == num_ads # all adults disabled - check for severe dis
        nsev = 0
        for pid in bu.adults
            nsev += qualifies_for_severe_disability_premium(
                bu.people[pid],
                bures.pers[pid],
                prem_sys )
        end
        if nsev == 1
            premium += prem_sys.severe_disability_single
            union!( premset, [severe_disability_single])
        elseif nsev == 2
            premium += prem_sys.severe_disability_couple
            union!( premset, [severe_disability_couple])
        end
    end
    # FIXME this is not the right test for sev disabled child
    if which_ben in [hb,ctr,is,jsa,esa,pc] 
        premium += intermed.num_severely_disabled_children*prem_sys.enhanced_disability_child
        if intermed.num_severely_disabled_children > 0
            union!( premset,[enhanced_disability_child] )
        end
    end
    #=
    if which_ben in [ hb, ctr, is, jsa, esa, pc, sc ] 
        # CPAG 19/20 - I *think* this is what it means..
        nsd = num_qualifying_for_severe_disability( bu, bures, intermed.num_benefit_units ) > 0
        if nsd == 1
            premium += prem_sys.severe_disability_single
            union!( premset, [severe_disability_single])
        elseif nsd == 2
            premium += prem_sys.severe_disability_couple
            union!( premset, [severe_disability_couple])
        end
    end
    =#
    if which_ben in [ is, jsa, esa ] # this should almost never happen given our routing; cpag p345
        if intermed.someone_pension_age
            premium += prem_sys.pensioner_is  
            union!( premset, [pensioner_is] )
        end
    end
    # end
    #
    # we're ignoring support components (p355-) for now.
    #
    return (premium, premset)
end

function calc_allowances(
    which_ben :: LMTBenefitType,
    intermed :: MTIntermediate, 
    pas :: PersonalAllowances,
    ages :: AgeLimits,
    oo_housing_costs :: Real  ) :: Real
    pers_allow = 0.0
    @assert intermed.num_adults in [1,2]
    if which_ben == pc
        if intermed.num_adults == 1 
            pers_allow = pas.pc_mig_single        
        elseif intermed.num_adults == 2
            pers_allow = pas.pc_mig_couple         
        end
        # children - cpag p 272 says there's an allowance for children
        # if not claiming CTC, but so far as I can see there's no
        # upper limit on CTC
        # .. anyway, the AC calculator suggests this:
        pers_allow += pas.pc_child * intermed.num_allowed_children
        ## FIXME also an allowance for 1st child born before 6th april 2018
    else
        if intermed.age_oldest_adult < 18
            # argh .. not there's a conditional on ESA that we don't cover here
            # seems to be it - no change for sps, marriage..
            # but some change
            if intermed.num_adults == 2
                pers_allow = pas.couple_both_under_18
            else
                if which_ben != esa
                    pers_allow = pas.age_18_24
                else # FIXME rename this allowance !!
                    pers_allow = pas.age_25_and_over
                end
            end
            # should be somethinh like ...
            #if which_ben in [is,jsa,esa]
            #    
            #elseif which_ben == hb 
            #    pers_allow = pas.age_18_24
            #end
        elseif intermed.age_youngest_adult < 18 && intermed.num_adults == 2
            pers_allow = pas.couple_one_over_18_high
            ## FIXME some cases lower than this see p 335 CPAG
        else # all over 17
            if intermed.num_adults == 1 
                if intermed.num_children > 0 # single parent
                    if intermed.someone_pension_age
                        pers_allow = pas.lone_parent_over_pension_age     
                    else
                        pers_allow = pas.lone_parent                 
                    end            
                else
                    if intermed.someone_pension_age
                        pers_allow = pas.over_pension_age
                    elseif intermed.age_oldest_adult < 25
                        pers_allow = pas.age_18_24        
                    else
                        pers_allow = pas.age_25_and_over
                    end
                end
            else # 2 adults, both at least 18
                if intermed.someone_pension_age
                    pers_allow = pas.couple_over_pension_age
                else
                    pers_allow = pas.couple_both_over_18
                end
            end # 2 adults
        end # no 16-17 yos 
        if which_ben in [hb,ctr] #
            pers_allow += pas.child * intermed.num_allowed_children
        end
    end
    pers_allow += oo_housing_costs
    @assert pers_allow > 0
    return pers_allow
end

function calc_full_ctc( 
    bu :: BenefitUnit,
    intermed :: MTIntermediate, 
    ctc :: ChildTaxCredit )
    ctc_elements = 0.0
    # p282
    if num_born_before( bu, Date( 2017, 4, 6 )) > 0
        ctc_elements += ctc.family
    end
    ctc_elements += (intermed.num_allowed_children*ctc.child)
    ctc_elements += intermed.num_disabled_children*ctc.disability
    ctc_elements += intermed.num_severely_disabled_children*ctc.severe_disability 
    return ctc_elements
end

function calcWTC_CTC!(
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit :: BenefitUnit, 
    intermed :: MTIntermediate,
    wtc :: WorkingTaxCredit,
    ctc :: ChildTaxCredit )
    
    bu = benefit_unit # aliases
    bures = benefit_unit_result
    bu_lmt = bures.legacy_mtbens
    can_apply_for = bu_lmt.can_apply_for
    it, ni = aggregate_tax( bures )

    other_income = it.savings_income + it.dividends_income
    # FIXME does this tread pensions correctly - they're disgregarded
    if other_income < wtc.non_earnings_minima
        other_income = 0.0
    end
    nsi = it.non_savings_income - (total( bures, PENSION_CONTRIBUTIONS_EMPLOYEE )+it.pension_relief_at_source )
    income = other_income + nsi
    wtc_elements = 0.0
    ctc_elements = 0.0
    threshold = wtc.threshold
    cost_of_childcare = 0.0
    if can_apply_for.wtc && ( ! wtc.abolished )
        wtc_elements = wtc.basic
        if intermed.is_sparent
            wtc_elements += wtc.lone_parent
        elseif intermed.num_adults > 1
            wtc_elements += wtc.couple
        end
        if intermed.someone_working_ft > 0
            wtc_elements += wtc.hours_ge_30      
        end
        if intermed.working_disabled
            wtc_elements += wtc.disability        
        end
        # FIXME do servere_working disabled
        cost_of_childcare = 0.0
        for pid in bu.children 
            cost_of_childcare += bu.people[pid].cost_of_childcare 
        end
        
        cost_of_childcare *= wtc.childcare_proportion
        
        if intermed.num_children > 1 
            cost_of_childcare = min( wtc.childcare_max_2_plus_children, cost_of_childcare )
        else
            cost_of_childcare = min( wtc.childcare_max_1_child, cost_of_childcare )
        end    
        wtc_elements += cost_of_childcare
    end
    if can_apply_for.ctc && ( ! ctc.abolished )
        ctc_elements = calc_full_ctc( bu, intermed, ctc)
        if ! can_apply_for.wtc
            threshold = ctc.threshold
        end
    end
    
    elements = ctc_elements + wtc_elements
    excess = wtc.taper * max( 0.0, income - threshold )
    wtc_ctc = max( 0.0, elements - excess )
    # allocate
    ctc_amt = min( wtc_ctc, ctc_elements )
    wtc_amt = wtc_ctc - ctc_amt
    ## assign to an individual
    
    bu_lmt.wtc_ctc_tapered_excess = excess
    bu_lmt.wtc_income = income
    bu_lmt.ctc_elements = ctc_elements
    bu_lmt.wtc_elements = wtc_elements
    bu_lmt.cost_of_childcare = cost_of_childcare
    bu_lmt.wtc_ctc_threshold = threshold

    # to spouse if has one
    recipient = make_recipient( bu, WORKING_TAX_CREDIT )
    bures.legacy_mtbens.wtc_recipient = recipient
    bures.pers[recipient].income[WORKING_TAX_CREDIT] = wtc_amt
    # println( "wtc repipient=$recipient amount=$wtc_amt")

    recipient = make_recipient( bu, CHILD_TAX_CREDIT )
    bures.pers[recipient].income[CHILD_TAX_CREDIT] = ctc_amt
end



function calc_NDDs( 
    bu       :: BenefitUnit, 
    bur      :: BenefitUnitResult,
    intermed :: MTIntermediate,
    incomes  :: LMTIncomes,
    hb       :: HousingBenefits )::Real
    ndd = 0.0
    # income based on the couples income if it is a couple
    any_pay_ndds = false
    for pid in bu.adults 
        pays_ndd = true
        pers = bu.people[pid]
        persr = bur.pers[pid]
        # fixme check this list & reference
        if any_positive( persr.income, 
            [ATTENDANCE_ALLOWANCE,
             DLA_SELF_CARE,
             PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
             ADP_DAILY_LIVING,
             PENSION_CREDIT] )
            pays_ndd = false
        elseif pers.registered_blind || pers.registered_partially_sighted
            pays_ndd = false
        elseif pers.age < 18
            pays_ndd = false
        elseif pers.age < 25 
            if any_positive( 
                    persr.income,
                    [INCOME_SUPPORT,
                    NON_CONTRIB_JOBSEEKERS_ALLOWANCE, 
                    NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE] )
                pays_ndd = false
            end
        end
        any_pay_ndds = any_pay_ndds || pays_ndd
    end # pids loop
    if any_pay_ndds
        if intermed.someone_working_ft
            n = size(hb.ndd_incomes)[1]
            w = n
            for i in 1:n
                if hb.ndd_incomes[i] > incomes.gross_earnings
                    w = i
                    break
                end
            end
            ndd = hb.ndd_deductions[w]
        else
            ndd = hb.ndd_deductions[1]
        end
    end # any ndd payable
    return ndd
end

function calculateHB_CTR!( 
    household_result :: HouseholdResult,
    which_ben        :: LMTBenefitType,
    hh               :: Household,
    intermed         :: HHIntermed,
    lmt_ben_sys      :: LegacyMeansTestedBenefitSystem,    
    age_limits       :: AgeLimits,
    nmt_bens         :: NonMeansTestedSys )
    @argcheck which_ben in [ctr, hb]

    eligible_amount = which_ben == ctr ? 
        total(household_result, LOCAL_TAXES ) :
        household_result.housing.allowed_rent
       
    bus = get_benefit_units( hh )
    nbus = size(bus)[1]
    ndds = 0.0
    for bn in nbus:-1:1 # fixme bn=>buno for consistency
        bu = bus[bn]
        bures = household_result.bus[bn]
        incomes = calc_incomes( 
            hb,
            bu,
            bures,
            intermed.buint[bn],
            lmt_ben_sys.income_rules,
            lmt_ben_sys.hours_limits )
        if bn == 1
            benefit = max(0.0, eligible_amount - ndds ) # ndds deducted from eligible rent
            premium = 0.0
            allowances = 0.0
            passported = false
            # FIXME we're doing passpored twice            
            if has_any( bures, lmt_ben_sys.hb.passported_bens... )
                # no need to do anything
                passported = true
            else
                ## FIXME pass this in
                premium, premset = calc_premia(
                    hb,
                    bu,
                    bures,
                    intermed.buint[bn],        
                    lmt_ben_sys.premia,
                    nmt_bens,
                    age_limits )            
                union!(bures.legacy_mtbens.premia, premset)
                allowances = calc_allowances(
                    hb,
                    intermed.buint[bn],
                    lmt_ben_sys.allowances,
                    age_limits,
                    0.0  )
                excess = max( 0.0, incomes.total_income - (premium+allowances))
                if excess > 0
                    taper = which_ben == ctr ? lmt_ben_sys.ctr.taper : lmt_ben_sys.hb.taper
                    benefit = max( 0.0, benefit - taper*excess )
                end
                
            end
            
            recipient = make_recipient( bu, HOUSING_BENEFIT )
            bures.legacy_mtbens.hb_recipient = recipient
            bures.legacy_mtbens.ctr_recipient = recipient

            if which_ben == hb
                bures.pers[recipient].income[HOUSING_BENEFIT] = benefit
                bures.legacy_mtbens.hb_passported = passported
                bures.legacy_mtbens.hb_eligible_rent = eligible_amount
                if ! passported
                    bures.legacy_mtbens.hb_premia = premium
                    bures.legacy_mtbens.hb_allowances = allowances
                    bures.legacy_mtbens.hb_incomes = incomes                           
                end
            elseif which_ben == ctr
                bures.pers[recipient].income[COUNCIL_TAX_BENEFIT] = benefit
                bures.legacy_mtbens.ctr = benefit
                bures.legacy_mtbens.ctr_passported = passported
                bures.legacy_mtbens.ctr_eligible_amount = eligible_amount
                if ! passported
                    bures.legacy_mtbens.ctr_premia = premium
                    bures.legacy_mtbens.ctr_allowances = allowances               
                    bures.legacy_mtbens.ctr_incomes = incomes                               
                end
            end
        else # ndds for hb, not ctr
            if which_ben == hb
                ndds += calc_NDDs(
                    bu,
                    bures,
                    intermed.buint[bn],
                    incomes,
                    lmt_ben_sys.hb )
            end
        end
    end
end # calculateHB_CTR

function calc_legacy_means_tested_benefits!(
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit :: BenefitUnit,
    intermed     :: MTIntermediate,
    mt_ben_sys   :: LegacyMeansTestedBenefitSystem,
    age_limits   :: AgeLimits, 
    hours        :: HoursLimits,
    nmt_bens     :: NonMeansTestedSys,
    hh :: Union{Nothing,Household} ) # passed on 1st BU only
    # aliases
    bures = benefit_unit_result
    bu = benefit_unit
    premium = 0.0
    bures.legacy_mtbens.can_apply_for = make_lmt_benefit_applicability(
        mt_ben_sys,
        intermed,
        mt_ben_sys.hours_limits
    )
    # FIXME we need to check the fuck out of this charge
    oo_housing_costs = 0.0
    if hh !== nothing
        if is_owner_occupier( hh.tenure ) 
            oo_housing_costs = hh.other_housing_charges
        end
    end
    # alias
    can_apply_for = bures.legacy_mtbens.can_apply_for
    # FIXME MIG not really the right name for is,jsa,esa
    which_mig = nothing
    if can_apply_for.esa 
        which_mig = esa
    elseif can_apply_for.jsa
        which_mig = jsa
    elseif can_apply_for.is
        which_mig = is
    end
    mig_entitlement = 0.0 # we need to record this for wtc/ctc routing below
    if which_mig !== nothing 
        premium,premset = calc_premia(
            which_mig,
            bu,
            bures,
            intermed,        
            mt_ben_sys.premia,
            nmt_bens,
            age_limits )            
        union!(bures.legacy_mtbens.premia, premset)
        incomes = calc_incomes( 
            which_mig,
            bu,
            bures,
            intermed,
            mt_ben_sys.income_rules,
            hours )
        allowances = calc_allowances(
            which_mig,
            intermed,
            mt_ben_sys.allowances,
            age_limits,
            oo_housing_costs )        
        bures.legacy_mtbens.mig = premium+allowances
        bures.legacy_mtbens.mig_incomes = incomes
        bures.legacy_mtbens.mig_allowances = allowances
        bures.legacy_mtbens.mig_premia = premium
        mig_entitlement = max( 0.0, bures.legacy_mtbens.mig - incomes.total_income );
        if (! incomes.disqualified_on_capital) && (mig_entitlement > 0)
            # FIXME we just allocate payment to the head of
            # the BU - make this a function or make can_apply_for
            # specify the payee as well as whether the BU qualifies
            if can_apply_for.ctc
                recipient = make_recipient( bu, CHILD_TAX_CREDIT )
                bures.pers[recipient].income[CHILD_TAX_CREDIT] = 
                    calc_full_ctc( bu, intermed, mt_ben_sys.child_tax_credit )
            end
            if can_apply_for.esa 
                recipient = make_recipient( bu, NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE )
                bures.pers[recipient].income[NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE] = mig_entitlement
                # bures.legacy_mtbens.esa = entitlement
            elseif can_apply_for.jsa
                recipient = make_recipient( bu, NON_CONTRIB_JOBSEEKERS_ALLOWANCE )
                bures.pers[recipient].income[NON_CONTRIB_JOBSEEKERS_ALLOWANCE] = mig_entitlement
                # bures.legacy_mtbens.jsa = entitlement
            elseif can_apply_for.is
                recipient = make_recipient( bu, INCOME_SUPPORT )
                bures.pers[recipient].income[INCOME_SUPPORT] = mig_entitlement
                # bures.legacy_mtbens.is = entitlement
            end
            bures.legacy_mtbens.mig_recipient = recipient
            can_apply_for.wtc = false # no overlapping
        end
    end
    
    if can_apply_for.pc && ( ! mt_ben_sys.pen_credit_abolished)
        premium, premset = calc_premia(
            pc,
            bu,
            bures,            
            intermed,        
            mt_ben_sys.premia,
            nmt_bens,            
            age_limits )            
        union!( bures.legacy_mtbens.premia, premset )
        incomes = calc_incomes( 
            pc,
            bu,
            bures,
            intermed,
            mt_ben_sys.income_rules,
            hours )
        allowances = calc_allowances(
            pc,
            intermed,
            mt_ben_sys.allowances,
            age_limits,
            oo_housing_costs
        )        
        # NOTE - there can be 'qualifying housing costs' in the MIG;
        # see: CPAG 2122
        bures.legacy_mtbens.mig = premium+allowances # = max( 0.0, entitlement - incomes.total_income );
        bures.legacy_mtbens.pc_incomes = incomes
        bures.legacy_mtbens.pc_allowances = allowances
        bures.legacy_mtbens.pc_premia = premium
        pc_entitlement = max( 0.0, 
            bures.legacy_mtbens.mig - 
            bures.legacy_mtbens.pc_incomes.total_income )
 
        
        recipient = make_recipient( bu, PENSION_CREDIT )
        
        if can_apply_for.sc && ( ! incomes.disqualified_on_capital ) && ( ! mt_ben_sys.savings_credit.abolished )
            scsys = mt_ben_sys.savings_credit #  shortcut
            sc_incomes = calc_incomes( 
                sc,
                bu,
                bures,
                intermed,
                mt_ben_sys.income_rules,
                hours
                 )
            thresh = scsys.threshold_single
            maxpay = scsys.max_single
            if intermed.num_adults > 1
                thresh = scsys.threshold_couple
                maxpay = scsys.max_couple
            end
            # see: CPAG 2011/12 edition ch 19
            scent = 0.0
            income_over_thresh = max(0.0, sc_incomes.total_income - thresh )
            if income_over_thresh > 0
                sc_maximum = min( maxpay, scsys.withdrawal_rate * income_over_thresh)
                income_over_mig = incomes.total_income - bures.legacy_mtbens.mig
                if income_over_mig <= 0.0
                    scent = sc_maximum
                else
                    scent = max( 0.0, sc_maximum - (1-scsys.withdrawal_rate)*income_over_mig)
                end
                bures.pers[recipient].income[SAVINGS_CREDIT] = scent
                bures.legacy_mtbens.sc_incomes = sc_incomes  
            end
        end
        
        bures.pers[recipient].income[PENSION_CREDIT] = pc_entitlement
    end
    
    #
    # Do WTC iff you can apply for it or if you qualify for CTC
    # but not the automatic full amount
    #
    if can_apply_for.wtc || (can_apply_for.ctc && ( mig_entitlement == 0.0 ))
        calcWTC_CTC!( 
                bures,
                bu,
                intermed,
                mt_ben_sys.working_tax_credit,
                mt_ben_sys.child_tax_credit )
    
    end
    
    if has_any( bures, 
            PENSION_CREDIT, 
            NON_CONTRIB_JOBSEEKERS_ALLOWANCE,
            NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
            INCOME_SUPPORT )        
        bures.legacy_mtbens.hb_passported = true
        bures.legacy_mtbens.ctr_passported = true
 
    end
end

"""
 TODO FIXME housing costs for oo if qualifies for PC,JSA etc.
    see CPAG ch 18
"""
function calc_legacy_means_tested_benefits!(
            household_result :: HouseholdResult,
            household        :: Household,
            intermed         :: HHIntermed,
            lmt_ben_sys      :: LegacyMeansTestedBenefitSystem,
            age_limits       :: AgeLimits, 
            hours            :: HoursLimits,
            nmt_bens         :: NonMeansTestedSys,
            hr               :: HousingRestrictions )
    # fixme not just for renters? fixme do this earlier
    household_result.housing = apply_rent_restrictions( 
        household, intermed.hhint, hr )
    bus = get_benefit_units(household)
    nbus = size( bus )[1]
    for buno in 1:nbus
        calc_legacy_means_tested_benefits!(
            household_result.bus[buno],
            bus[buno],
            intermed.buint[buno],
            lmt_ben_sys,
            age_limits,
            hours,
            nmt_bens,
            buno == 1 ? household : nothing )
    end
    # hb using the whole hhls but assigned to 1st bu
    if ! lmt_ben_sys.hb.abolished
        calculateHB_CTR!( 
            household_result,
            hb,
            household,
            intermed,
            lmt_ben_sys,
            age_limits,
            nmt_bens )
    end
    # 
end

end # module LegacyMeansTestedBenefits