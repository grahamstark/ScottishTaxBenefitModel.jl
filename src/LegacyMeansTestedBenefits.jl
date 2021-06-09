module LegacyMeansTestedBenefits

using ScottishTaxBenefitModel
using .Definitions

using .Incomes

using .ModelHousehold: Person,BenefitUnit,Household, is_lone_parent, get_benefit_units,
    is_single, count, num_carers, le_age, between_ages, ge_age, search,
    empl_status_in, has_children, num_adults, pers_is_disabled, is_severe_disability
    
using .STBParameters: LegacyMeansTestedBenefitSystem, IncomeRules,  
    Premia, PersonalAllowances, HoursLimits, AgeLimits, reached_state_pension_age, state_pension_age,
    WorkingTaxCredit, SavingsCredit, IncomeRules, MinimumWage, ChildTaxCredit,
    HousingBenefits, HousingRestrictions
    
using .GeneralTaxComponents: TaxResult, calctaxdue, RateBands

using .Results: BenefitUnitResult, HouseholdResult, IndividualResult, LMTIncomes,
    LMTResults, LMTCanApplyFor, aggregate!, aggregate_tax

using .Intermediate: MTIntermediate, working_disabled, is_working_hours,
    born_before, num_born_before, apply_2_child_policy

using .LocalLevelCalculations: apply_rent_restrictions

export calc_legacy_means_tested_benefits, tariff_income,
    LMTResults,  make_lmt_benefit_applicability, calc_premia,
    calc_allowances, calc_incomes,
    calcWTC_CTC!, calc_NDDs, calculateHB_CTR!



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
        gross = 
            get( pers.income, wages, 0.0 ) +
            get( pers.income, self_employment_income, 0.0 ) # this includes losses
        if which_ben in [pc,is,jsa,esa,hb]
            net = 
                gross - ## FIXME parameterise this so we can use gross/net
                pres.it.non_savings_tax -
                pres.ni.total_ni - 
                0.5 * get(pers.income, pension_contributions_employee, 0.0 )
        else
            # wtc,ctr all pension contributions but not IT/NI
            net = gross - get(pers.income, pension_contributions_employee, 0.0 )
        end
        gross_earn += gross
        net_earn += max( 0.0, net )
        other += isum( pres.incomes, inclist )
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
    elseif which_ben in [hb,jsa,is,pc]
        if intermed.is_sparent            
            disreg = which_ben == hb ? incrules.lone_parent_hb : incrules.high 
        elseif ! isdisjoint( mntr.premia, [carer_single, carer_couple, disability_couple, disability_single, severe_disability_couple, severe_disability_single] )
            disreg = incrules.high
        end       
    end

    if( which_ben in [hb,ctr] ) 
        # fixme do this above
        if has_income( bur, EMPLOYMENT_AND_SUPPORT_ALLOWANCE )     
            disreg = incrules.high
        end
        # HB disregard CPAG p432 this, too, is very approximate
        # work 30+ hours - should really check premia if haskeys( mtr.premia )
        extra = 0.0
        if search( bu, is_working_hours, hours.higher )
            extra = incrules.hb_additional 
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
    cap = 0.0
    for pid in bu.adults
        for (at,val) in bu.people[pid].assets
           cap += val
        end
    end
    inc.other_income = other
    inc.capital = cap
    inc.gross_earnings = gross_earn
    inc.net_earnings = max(0.0, gross_earn - disreg - inc.childcare )
    capmin = incrules.capital_min
    capmax = incrules.capital_max
    if intermed.someone_pension_age
        if which_ben == pc 
            capmin = incrules.pc_capital_min
            capmax = incrules.pc_capital_min
        else
            capmin = incrules.pensioner_capital_min
            capmax = incrules.pensioner_capital_min
        end
    end
    
    inc.tariff_income = tariff # ex_income(cap, capmin, incrules.capital_tariff )
    inc.disqualified_on_capital = cap > capmax 
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
    intermed :: MTIntermediate,
    hrs      :: HoursLimits ) :: LMTCanApplyFor
    whichb = LMTCanApplyFor()
    if intermed.someone_pension_age #!! fixme both pension age for new claims 2019=>
        whichb.pc = true
    end
    if intermed.someone_pension_age_2016
        whichb.sc = true
    end
    # ESA, JSA, IS, crudely
    if ! intermed.all_pension_age 
        if ((intermed.num_adults == 1 && intermed.num_not_working == 1) || 
        (intermed.num_adults == 2 && (intermed.num_not_working>=1 && intermed.num_working_part_time<=1))) &&
        intermed.ge_16_u_pension_age
            if intermed.limited_capacity_for_work
                whichb.esa = true 
            elseif intermed.economically_active 
                whichb.jsa = true  
            else
                whichb.is = true
            end
        end
    end # all pens age
    
    #
    # tax credits
    # CTC - easy
    if intermed.has_children
        whichb.ctc = true
    end
    #
    # WTC - not quite so easy
    #
    # println( "someone_working_ft $(intermed.someone_working_ft) num_working_pt $(intermed.num_working_pt)  has_children $(intermed.has_children) someone_pension_age $(intermed.someone_pension_age) ")
    if intermed.someone_working_ft
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
    if intermed.benefit_unit_number == 1
        whichb.hb = true
        whichb.ctr = true
    end
    # check!!! is this correct? is, etc. or wtc over pc/sc
    if( whichb.esa || whichb.jsa || whichb.is ) ## || whichb.wtc)
        whichb.pc = false
        whichb.sc = false
    end
    # hb,ctr are assumed true, worked out on benefit unit number
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


function calc_premia(     
    which_ben :: LMTBenefitType,
    bu :: BenefitUnit,
    intermed :: MTIntermediate, 
    prem_sys :: Premia,
    ages :: AgeLimits  ) :: Tuple
    premium = 0.0
    premset = LMTPremiaSet()
    if which_ben in [hb,ctr]
        # disabled child premium
        if intermed.num_disabled_children > 0
            premium += intermed.num_disabled_children*prem_sys.disabled_child   
            union!( premset, [disabled_child])
        end
    end
    if which_ben != esa
        if intermed.num_disabled_adults == 1
            premium += prem_sys.disability_single
            union!( premset,[disability_single])
        elseif intermed.num_disabled_adults == 2
            premium += prem_sys.disability_couple
            union!( premset,[disability_couple])
        end        
    end
    if which_ben in [hb,ctr,esa,is,jsa] # FIXME check ESA here
        premium += intermed.num_severely_disabled_children*prem_sys.enhanced_disability_child
        if intermed.num_severely_disabled_children > 0
            union!( premset,[enhanced_disability_child] )
        end
        if intermed.num_severely_disabled_adults == 1
            premium += prem_sys.enhanced_disability_single
            union!( premset, [enhanced_disability_single] )
        elseif intermed.num_severely_disabled_adults == 2
            premium += prem_sys.enhanced_disability_couple
            union!( premset,[enhanced_disability_couple]) 
        end                
    end
    if which_ben in [ is, jsa, esa ] # this should almost never happen given our routing; cpag p345
        if intermed.someone_pension_age
            premium += prem_sys.pensioner_is  
            union!( premset, [pensioner_is] )
        end
    end
    # all benefits, I think, incl. 
    # if which_ben != ctr
    if intermed.num_carers == 1
        premium += prem_sys.carer_single
        union!( premset,[carer_single] )
    elseif intermed.num_carers == 2
        # FIXME what if 1 is a child?
        premium += prem_sys.carer_couple
        union!( premset, [carer_couple] )
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
    ages :: AgeLimits ) :: Real
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
        # pers_allow += intermed.num_children_born_before*
    else
        if intermed.age_oldest_adult < 18
            # argh .. not there's a conditional on ESA that we don't cover here
            # seems to be it - no change for sps, marriage..
            # but some change
            if intermed.num_adults == 2
                pers_allow = pas.couple_both_under_18
            else
                pers_allow = pas.age_18_24
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
        if which_ben in [hb,ctr]
            pers_allow += pas.child * intermed.num_allowed_children
        end
    end
    @assert pers_allow > 0
    return pers_allow
end

function calcWTC_CTC!(
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit :: BenefitUnit, 
    intermed :: MTIntermediate,
    wtc :: WorkingTaxCredit,
    ctc :: ChildTaxCredit,
    can_apply_for :: LMTCanApplyFor )
    
    bu = benefit_unit # aliases
    bu_lmt = benefit_unit_result.legacy_mtbens
    it, ni = aggregate_tax( benefit_unit_result )
    other_income = it.savings_income + it.dividends_income
    # FIXME does this tread pensions correctly - they're disgregarded
    if other_income < wtc.non_earnings_minima
        other_income = 0.0
    end
    income = other_income + it.non_savings_income
    wtc_elements = 0.0
    ctc_elements = 0.0
    threshold = wtc.threshold
    if can_apply_for.wtc 
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
    if can_apply_for.ctc 
        ctc_elements = ctc.family
        ctc_elements += (intermed.num_allowed_children*ctc.child)
        ctc_elements += intermed.num_disabled_children*ctc.disability
        ctc_elements += intermed.num_severely_disabled_children*ctc.severe_disability
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
    

    bu_lmt.wtc_income = income
    bu_lmt.ctc_elements = ctc_elements
    bu_lmt.wtc_elements = wtc_elements
    bu_lmt.wtc_ctc_threshold = threshold
    # to spouse if has one

    recipient :: BigInt = length(bur.adults)[1] == 2 ? bur.adults[2] : bur.adults[1]
    benefit_unit_result.pers[recipient].income[WORKING_TAX_CREDIT] = wtc_amt
    benefit_unit_result.pers[recipient].income[CHILD_TAX_CREDIT] = ctc_amt
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
            [ATTENDENCE_ALLOWANCE,
             DLA_SELF_CARE,
             PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
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
                    EMPLOYMENT_AND_SUPPORT_ALLOWANCE] )
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
    intermed         :: NamedTuple,
    lmt_ben_sys      :: LegacyMeansTestedBenefitSystem,
    age_limits       :: AgeLimits )
    
    eligible_amount = which_ben == ctr ? 
        household_result.local_tax.council_tax :
        household_result.housing.allowed_rent
       
    @assert which_ben in [ctr, hb]
    bus = get_benefit_units( hh )
    nbus = size(bus)[1]
    ndds = 0.0
    for bn in nbus:-1:1 # fixme bn=>buno for consistency
        bures = household_result.bus[bn]
        println( "loop start; bures.legacy_mtbens.premia $(bures.legacy_mtbens.premia)")    
        bu = bus[bn]
        ## FIXME pass this in
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
            if has_income( bures, lmt_ben_sys.hb.passported_bens )
                # no need to do anything
                passported = true
            else
                println( "else; bures.legacy_mtbens.premia $(bures.legacy_mtbens.premia)")    
                premium, premset = calc_premia(
                    hb,
                    bu,
                    intermed.buint[bn],        
                    lmt_ben_sys.premia,
                    age_limits )            
                println( "bures.legacy_mtbens.premia $(bures.legacy_mtbens.premia)")
                println( "premset $(premset))")
                union!(bures.legacy_mtbens.premia, premset)
                allowances = calc_allowances(
                    hb,
                    intermed.buint[bn],
                    lmt_ben_sys.allowances,
                    age_limits )
                excess = max( 0.0, incomes.total_income - (premium+allowances))
                if excess > 0
                    taper = which_ben == ctc ?  lmt_ben_sys.ctc.taper : lmt_ben_sys.hb.taper
                    println( "taper=$taper excess=$excess" )
                    benefit = max( 0.0, benefit - taper*excess )    
                end
                
            end
            # FIXME this needs to be a function
            recipient :: BigInt = bur.adults[1]
            if which_ben == hb
                bures.pers[recipient].income[HOUSING_BENEFIT] = benefit
                bures.legacy_mtbens.hb_passported = passported
                bures.legacy_mtbens.hb_premia = premium
                bures.legacy_mtbens.hb_allowances = allowances
                bures.legacy_mtbens.hb_incomes = incomes                           
            elseif which_ben == ctr
                bures.pers[recipient].income[COUNCIL_TAX_BENEFIT] = benefit
                bures.legacy_mtbens.ctr = benefit
                bures.legacy_mtbens.ctr_passported = passported
                bures.legacy_mtbens.ctr_premia = premium
                bures.legacy_mtbens.ctr_allowances = allowances
                bures.legacy_mtbens.ctr_incomes = incomes               
            end
        else # ndds for hb, not ctr
            if which_ben == hb
                ndds += calc_NDDs(
                    bu,
                    bures,
                    intermed.buint[buno],
                    lmt_ben_sys.income_rules,
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
    hours        :: HoursLimits )
    # aliases
    bures = benefit_unit_result
    bu = benefit_unit
    premium = 0.0
    can_apply_for :: LMTCanApplyFor = make_lmt_benefit_applicability(
        intermed,
        mt_ben_sys.hours_limits
    )
    # FIXME MIG not really the right name for is,jsa,esa
    which_mig = nothing
    mig = 0.0
    if can_apply_for.esa 
        which_mig = esa
    elseif can_apply_for.jsa
        which_mig = jsa
    elseif can_apply_for.is
        which_mig = is
    end
    if which_mig != nothing 
        premium,premset = calc_premia(
            which_mig,
            bu,
            intermed,        
            mt_ben_sys.premia,
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
            age_limits )        
        mig = max( 0.0, premium+allowances - incomes.total_income );
        bures.legacy_mtbens.mig_incomes = incomes
        bures.legacy_mtbens.mig_allowances = allowances
        bures.legacy_mtbens.mig_premia = premium
        if ! incomes.disqualified_on_capital
            # FIXME we just allocate payment to the head of
            # the BU - make this a function or make can_apply_for
            # specify the payee as well as whether the BU qualifies
            recipient :: BigInt = bur.adults[1]
            if can_apply_for.esa 
                bures.pers[recipient].income[EMPLOYMENT_AND_SUPPORT_ALLOWANCE] = mig
                # bures.legacy_mtbens.esa = mig
            elseif can_apply_for.jsa
                bures.pers[recipient].income[NON_CONTRIB_JOB_SEEKERS_ALLOWANCE] = mig
                # bures.legacy_mtbens.jsa = mig
            elseif can_apply_for.is
                bures.pers[recipient].income[INCOME_SUPPORT] = mig                
                # bures.legacy_mtbens.is = mig
            end
        end
    end
    
    if can_apply_for.pc
        premium, premset = calc_premia(
            pc,
            bu,
            intermed,        
            mt_ben_sys.premia,
            age_limits )            
        union!(bures.legacy_mtbens.premia, premset )
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
            age_limits 
        )        
        # NOTE - there can be 'qualifying housing costs' in the MIG;
        # see: CPAG 2122
        if ! incomes.disqualified_on_capital    
            bures.legacy_mtbens.mig = max( 0.0, miglevel - incomes.total_income );
        end
        bures.legacy_mtbens.ctc_incomes = incomes
        bures.legacy_mtbens.ctc_allowances = allowances
        bures.legacy_mtbens.ctc_premia = premium

        miglevel = premium+allowances

        # fixme make this a function
        recipient = bures.adults[1]
        
        if can_apply_for.sc && ( ! incomes.disqualified_on_capital )  
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
            maxpay = scsys.threshold_single
            if num_adults > 1
                thresh = scsys.threshold_couple
                maxpay = scsys.max_couple
            end
            # see: CPAG 2011/12 edition ch 19
            sc_income = scsys.withdrawal_rate * 
                max(0.0, sc_incomes.total_income-thresh)
            
            income_over_mig = (1-scsys.withdrawal_rate)*max(0.0, incomes.total_income-miglevel)
            bures.pers[recipient].income[SAVINGS_CREDIT] = max( 0.0, sc_income - income_over_mig )
            bures.legacy_mtbens.sc_incomes = sc_incomes   
        end
        bures.pers[recipient].income[PENSION_CREDIT] = bures.legacy_mtbens.mig
        #  + bures.legacy_mtbens.sc
    end
    
    if can_apply_for.wtc || can_apply_for.ctc
        bures.legacy_mtbens.wtc = calcWTC_CTC!( 
                bures,
                bu,
                intermed,
                mt_ben_sys.working_tax_credit,
                mt_ben_sys.child_tax_credit,
                can_apply_for )
    
    end
    
    if has_income( bures, 
        [
            PENSION_CREDIT, 
            NON_CONTRIB_JOBSEEKERS_ALLOWANCE,
            EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
            INCOME_SUPPORT ])        
        bures.legacy_mtbens.hb_passported = true
        bures.legacy_mtbens.ctr_passported = true
    end
end

function calc_legacy_means_tested_benefits!(
            household_result :: HouseholdResult,
            household        :: Household,
            intermed         :: NamedTuple,
            age_limits       :: AgeLimits, 
            lmt_ben_sys      :: LegacyMeansTestedBenefitSystem,
            hours            :: HoursLimits,
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
            hours )
    end
    # hb using the whole hhls but assigned to 1st bu
    calculateHB_CTR!( 
        household_result,
        hb,
        household,
        intermed,
        lmt_ben_sys,
        age_limits )
    calculateHB_CTR!( 
        household_result,            
        ctr,
        household,
        intermed,
        lmt_ben_sys,
        age_limits )      
    #   
end

end # module LegacyMeansTestedBenefits