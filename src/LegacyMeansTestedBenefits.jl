module LegacyMeansTestedBenefits

using ScottishTaxBenefitModel
using .Definitions

using .ModelHousehold: Person,BenefitUnit,Household, is_lone_parent,
    is_single, pers_is_disabled, pers_is_carer, search, count, num_carers,
    has_disabled_member, has_carer_member, le_age, between_ages, ge_age,
    empl_status_in, has_children, num_adults, pers_is_disabled, is_severe_disability
    
using .STBParameters: LegacyMeansTestedBenefitSystem, IncomeRules,  
    Premia, PersonalAllowances, HoursLimits, AgeLimits, reached_state_pension_age, state_pension_age,
    WorkingTaxCredit, SavingsCredit, IncomeRules, MinimumWage, ChildTaxCredit
    
using .GeneralTaxComponents: TaxResult, calctaxdue, RateBands

using .Results: BenefitUnitResult, HouseholdResult, IndividualResult, LMTIncomes,
    LMTResults, has_income, LMTCanApplyFor, aggregate!, aggregate_tax
    
using .Utils: mult, haskeys

using Dates: TimeType, Date, now, Year

export calc_legacy_means_tested_benefits, tariff_income,
    LMTResults, is_working_hours, make_lmt_benefit_applicability,
    working_disabled, MTIntermediate, make_intermediate, calc_allowances,
    born_before, num_born_before, apply_2_child_policy, calc_incomes,
    calcWTC_CTC!

function is_working_hours( pers :: Person, hours... ) :: Bool
    # println( "hours=$hours employment=$(pers.employment_status)")
    if length(hours) == 1 
        return (pers.usual_hours_worked >= hours[1])
    elseif length(hours) == 2
        return (pers.usual_hours_worked >= hours[1]) &&
               (pers.usual_hours_worked <= hours[2])
    end
    #(pers.employment_status in [Full_time_Employee,Full_time_Self_Employed])
end


"""
examples: 

2 children born before start_date, 1 after
 => allowable = 2
3  children born before start_date, 1 after
 => allowable = 3
1  children born before start_date, 2 after
 => allowable = 2
0  children born before start_date, 2 after
 => allowable = 2
 @return number of children allowed
"""
function apply_2_child_policy(
    bu             :: BenefitUnit
    ;
    child_limit    :: Integer = 2,
    start_date     :: TimeType = Date( 2017, 4, 6 ), # 6th April 2017
    model_run_date :: TimeType = now() ) :: Integer
    before_children = 0
    after_children = 0
    for pid in bu.children
        ch = bu.people[pid]
        if born_before( ch.age, start_date, model_run_date )
            before_children += 1
        else
            after_children += 1
        end          
    end
    println( "before children $before_children after children $after_children " )
    allowable = before_children + min( max(child_limit-before_children,0), after_children )
end

function born_before( age :: Integer,
    start_date     :: TimeType = Date( 2017, 4, 6 ), # 6th April 2017
    model_run_date :: TimeType = now() )
    bdate = model_run_date - Year(age)
    println( "age = $(age) => birthdate $bdate" )
    return bdate < start_date   
end

function num_born_before(
    bu             :: BenefitUnit,
    start_date     :: TimeType = Date( 2017, 4, 6 ), # 6th April 2017
    model_run_date :: TimeType = now()) :: Integer
    nb = 0
    for pid in bu.children
        ch = bu.people[pid]
        if born_before( ch.age, start_date, model_run_date )
            nb += 1
        end
    end
    return nb
end

struct MTIntermediate
    benefit_unit_number :: Int
    age_youngest_adult :: Int
    age_oldest_adult :: Int
    age_youngest_child :: Int
    age_oldest_child :: Int
    num_adults :: Int
    someone_pension_age  :: Bool
    someone_pension_age_2016 :: Bool
    all_pension_age :: Bool
    working_ft  :: Bool 
    num_working_pt :: Int 
    num_working_24_plus :: Int 
    total_hours_worked :: Int
    is_carer :: Bool 
    num_carers :: Int
    
    is_sparent  :: Bool 
    is_sing  :: Bool 
    is_disabled :: Bool
    
    num_disabled_adults :: Int
    num_disabled_children :: Int
    num_severely_disabled_adults :: Int
    num_severely_disabled_children :: Int
    
    num_u_16s :: Int
    num_allowed_children :: Int
    num_children_born_before :: Int
    ge_16_u_pension_age  :: Bool 
    limited_capacity_for_work  :: Bool 
    has_children  :: Bool 
    economically_active :: Bool
    num_working_full_time :: Int 
    num_not_working :: Int 
    num_working_part_time :: Int
    working_disabled :: Bool
end



"""
Incomes for old style mt benefits
The CPAG guide ch 21/21 has over 100 pages on this stuff
this can no more than catch the gist.
"""
function calc_incomes( 
    which_ben :: LMTBenefitType, # esa hb is jsa pc wtc ctr
    bu :: BenefitUnit, 
    bur :: BenefitUnitResult, 
    intermed :: MTIntermediate,
    incrules :: IncomeRules,
    hours :: HoursLimits ) :: LMTIncomes 
    T = typeof( incrules.permitted_work )
    mntr = bur.legacy_mtbens # shortcut
    inc = LMTIncomes{T}()
    extra_incomes = zero(T)
    gross_earn = zero(T)
    net_earn = zero(T)
    other = zero(T)
    total = zero(T)
    
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
        other += mult( 
            data=pers.income, 
            calculated=pres.incomes, 
            included=inclist )
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
        elseif ! isdisjoint( mntr.premiums, [carer_single, carer_couple, disability_couple, disability_single, severe_disability_couple, severe_disability_single] )
            disreg = incrules.high
        end       
    end

    if( which_ben in [hb,ctr] ) 
        # fixme do this above
        if( Results.has_income( bu, bur, employment_and_support_allowance ))     
            disreg = incrules.high
        end
        # HB disregard CPAG p432 this, too, is very approximate
        # work 30+ hours - should really check premia if haskeys( mtr.premia )
        extra = 0.0
        if search( bu, is_working_hours, hours.higher )
            extra = incrules.hb_additional 
        elseif search(  bu, is_working_hours, hours.lower )
            if intermed.is_sparent || (intermed.num_u_16s > 0) || intermed.is_disabled
                extra = incrules.hb_additional
            end
        end
        disreg += extra
        # childcare in HB - costs are assigned in frs to the children
        if ( intermed.num_u_16s > 0 ) 
            maxcc = intermed.num_u_16s == 1 ? incrules.childcare_max_1 : incrules.childcare_max_2
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
    
    inc.tariff_income = tariff_income(cap, capmin, incrules.capital_tariff )
    inc.disqualified_on_capital = cap > capmax 
    inc.total_income = inc.net_earnings + inc.other_income + inc.tariff_income    
    inc.disregard = disreg
    return inc
end

"""
See CPAG ch 61 p 1426 and appendix 5
"""
function working_disabled( pers::Person, hrs :: HoursLimits ) :: Bool
    if pers.usual_hours_worked >= hrs.lower || pers.employment_status in [Full_time_Employee, Full_time_Self_Employed]
        if pers.registered_blind || pers.registered_partially_sighted || pers.registered_deaf
            return true
        end
        for (dis, t ) in pers.disabilities
            return true
        end
        if haskeys( pers.income, 
            [
                Incapacity_Benefit, 
                Severe_Disability_Allowance, 
                Employment_and_Support_Allowance ])
            return true
        end
    end
    return false
end

function make_intermediate(
    buno :: Int,
    bu   :: BenefitUnit, 
    hrs  :: HoursLimits,
    age_limits :: AgeLimits ) :: MTIntermediate
    # {RT} where RT
    age_youngest_adult :: Int = 9999
    age_oldest_adult :: Int = -9999
    age_youngest_child :: Int = 9999
    age_oldest_child :: Int = -9999
    
    is_working_disabled :: Bool = false
    num_adlts :: Int = num_adults( bu )
    # check both & die as we need to think about counts again
    # if we're going back in time to when these were unequal
    # 
    num_pens_age :: Int = 0
    ge_16_u_pension_age  :: Bool = false
    someone_pension_age_2016 :: Bool = false
    for pid in bu.adults
        pers = bu.people[pid]
        if reached_state_pension_age( 
            age_limits, 
            pers.age, 
            pers.sex )
            num_pens_age += 1
        else
            ge_16_u_pension_age = true
        end
        if reached_state_pension_age(
            age_limits, 
            pers.age, 
            pers.sex,
            age_limits.savings_credit_to_new_state_pension )
            someone_pension_age_2016 = true
        end
        
    end
    println( "num_adults=$num_adults; num_pens_age=$num_pens_age")
    someone_pension_age  :: Bool = num_pens_age > 0
    all_pension_age :: Bool = num_adlts == num_pens_age
    working_ft  :: Bool = search( bu, is_working_hours, hrs.higher )
    num_working_pt :: Int = count( bu, is_working_hours, hrs.lower, hrs.higher-1 )
    num_working_24_plus :: Int = count( bu, is_working_hours, hrs.med )
    total_hours_worked :: Int = 0
    num_carrs :: Int = num_carers( bu )
    is_carer :: Bool = has_carer_member( bu )
    is_sparent  :: Bool = is_lone_parent( bu )
    is_sing  :: Bool = is_single( bu )   
    limited_capacity_for_work  :: Bool = has_disabled_member( bu ) # FIXTHIS
    has_children  :: Bool = ModelHousehold.has_children( bu )
    economically_active = search( bu, empl_status_in, 
        Full_time_Employee,
        Part_time_Employee,
        Full_time_Self_Employed,
        Part_time_Self_Employed,
        Unemployed, 
        Temporarily_sick_or_injured )
    # can't think of a simple way of doing the rest with searches..
    num_working_full_time = 0
    num_not_working = 0
    num_working_part_time = 0
    is_disabled = has_disabled_member( bu )
    num_disabled_adults = 0
    num_severely_disabled_adults = 0
    for pid in bu.adults
        pers = bu.people[pid]
        if pers.age > age_oldest_adult
            age_oldest_adult = pers.age
        end
        if pers.age < age_youngest_adult
            age_youngest_adult = pers.age
        end
        if ! is_working_hours( pers, hrs.lower )
            num_not_working += 1
        elseif pers.usual_hours_worked <= hrs.med
            num_working_part_time += 1
        else 
            num_working_full_time += 1
        end          
        total_hours_worked += round(pers.usual_hours_worked)
        if working_disabled( pers, hrs )
            is_working_disabled = true
            break
        end 
        if pers_is_disabled( pers )
            num_disabled_adults += 1
            if is_severe_disability( pers )
                num_severely_disabled_adults += 1
            end
        end
    end
    @assert 120 >= age_oldest_adult >= age_youngest_adult >= 16
    num_u_16s = count( bu, le_age, 16 )
    num_children_born_before = num_born_before( bu ) # fixme parameterise
    num_disabled_children = 0
    num_severely_disabled_children :: Int = 0
    for pid in bu.children
        pers = bu.people[pid]
        if pers.age > age_oldest_child
            age_oldest_child = pers.age
        end
        if pers.age < age_youngest_child
            age_youngest_child = pers.age
        end
        if pers_is_disabled( pers )
            num_disabled_children += 1
            if is_severe_disability( pers )
                num_severely_disabled_children += 1
            end
        end
    end
    ## fixme parameterise this
    num_allowed_children :: Int = apply_2_child_policy( bu )
    println( "has_children $has_children age_oldest_child $age_oldest_child age_youngest_child $age_youngest_child" )
    @assert (!has_children)||(19 >= age_oldest_child >= age_youngest_child >= 0)
    
    println( typeof( total_hours_worked ))
                                   
    return MTIntermediate(
        buno,
        age_youngest_adult,
        age_oldest_adult,
        age_youngest_child,
        age_oldest_child,
        num_adlts,
        someone_pension_age,
        someone_pension_age_2016,
        all_pension_age,
        working_ft,
        num_working_pt,
        num_working_24_plus,
        total_hours_worked,
        is_carer,
        num_carrs,
        is_sparent,
        is_sing,    
        is_disabled,
        num_disabled_adults,
        num_disabled_children,
        num_severely_disabled_adults,
        num_severely_disabled_children,
        num_u_16s,
        num_allowed_children,
        num_children_born_before,
        ge_16_u_pension_age,
        limited_capacity_for_work,
        has_children,
        economically_active,
        num_working_full_time,
        num_not_working,
        num_working_part_time,
        is_working_disabled
    )
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
    if intermed.someone_pension_age
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
    println( "working_ft $(intermed.working_ft) num_working_pt $(intermed.num_working_pt)  has_children $(intermed.has_children) someone_pension_age $(intermed.someone_pension_age) ")
    if intermed.working_ft
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
    premia = 0.0
    premset = LMTPremiaSet()
    if which_ben in [hb,ctr]
        # disabled child premia
        premia += intermed.num_disabled_children*prem_sys.disabled_child   
        union(premset,disabled_child)
    end
    if which_ben != esa
        if num_disabled_adults == 1
            premia += prem_sys.disability_single
            union!( premset,disability_single)
        elseif num_disabled_adults == 2
            premia += prem_sys.disability_couple
            union!( premset,disability_couple)
        end        
    end
    if which_ben in [hb,ctr,esa,is,jsa]
        premia += intermed.num_severely_disabled_children*prem_sys.enhanced_disabled_child
        if intermed.num_severely_disabled_children > 0
            union!( premset,enhanced_disability_child)
        end
        if num_severely_disabled_adults == 1
            premia += prem_sys.enhanced_disability_single
            union!( premset,enhanced_disability_single)
        elseif num_severely_disabled_adults == 2
            premia += prem_sys.enhanced_disability_couple
            union!( premset,enhanced_disability_couple)
        end                
    end
    if which_ben != pc 
        if intermed.num_pens_age > 0
            premia += prem_sys.pensioner_is  
            union!( premset,pensioner_is)
        end
    end
    # all benefits, I think, incl. 
    # if which_ben != ctr
    if intermed.num_carers == 1
        premia += prem_sys.carer_single
        union!( premset,carer_single)
    elseif intermed.num_carers == 2
        # FIXME what if 1 is a child?
        premia += prem_sys.carer_couple
        union!( premset,carer_couple)
    end
    # end
    #
    # we're ignoring support components (p355-) for now.
    #
    return (premia, premset)
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
        pers_allow += intermed.num_children_born_before
    else
        if intermed.age_oldest_adult < 18
            # argh .. not there's a conditional on ESA that we don't cover here
            # seems to be it - no change for sps, marriage..
            # but some change
            pers_allow = pas.age_18_24
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
                if intermed.num_u_16s > 0 # single parent
                    if intermed.someone_pension_age
                        pers_allow = pas.lone_parent                 
                    else
                        pers_allow = pas.lone_parent_over_pension_age     
                    end            
                else
                    if intermed.age_oldest_adult < 25
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


function calc_credits()

end

function calc_ESA()

end

function calc_HB()

end

function calc_JSA()

end

function calc_PC()

end

function calc_CTC()

end

function calc_NDDS()

end

function calcWTC_CTC!(
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit :: BenefitUnit, 
    intermed :: MTIntermediate,
    wtc :: WorkingTaxCredit,
    ctc :: ChildTaxCredit,
    can_apply_for :: LMTCanApplyFor )
    bu = benefit_unit # aliases
    bur = benefit_unit_result.legacy_mtbens
    earn = 0.0
    non_earn = 0.0
    it, ni = aggregate_tax( bu )
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
        if intermed.working_ft > 0
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
        
        if intermed.num_u_16s > 1 
            cost_of_childcare = min( wtc.childcare_max_2_plus_children. cost_of_childcare )
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
    bur.ctc = min( wtc_ctc, ctc_elements )
    bur.wtc = wtc_ctc - bur.ctc
    bur.wtc_income = income
    bur.ctc_elements = ctc_elements
    bur.wtc_elements = wtc_elements
    bur.wtc_ctc_threshold = threshold
end



"""
 Temp hack till I work this stuff out at least semi-sensibly
"""
function calc_LHA(
    hh :: ModelHousehold,
    lha :: LocalHousingAllowance ) :: Real
    return lha.tmp_lha_prop*hh.gross_rent
end

function calculateNDD( bu :: BenefitUnit )::Real
    ndd = 0.0
    
    return ndd
end

function calculateHB_CTB( 
    eligible_amount :: Real, 
    bu :: BenefitUnit,
    intermed :: MTIntermediate,
    lmt_ben_sys :: LegacyMeansTestedBenefitSystem,
    age_limits :: AgeLimits )
    
    premia,premset = calc_premia(
        hb,
        bu,
        intermed,        
        mt_ben_sys.premia,
        age_limits )            
    union!(bures.legacy_mtbens.premiums, premset)
    incomes = calc_incomes( 
        hb,
        bu,
        bures,
        intermed,
        mt_ben_sys.income_rules )
    allowances = calc_allowances(
        hb,
        intermed,
        mt_ben_sys.allowances,
        age_limits )
    
end

function calc_legacy_means_tested_benefits!(
    ;
    buno :: Int,
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit :: BenefitUnit,
    intermed :: MTIntermediate,
    age_limits :: AgeLimits, 
    mt_ben_sys  :: LegacyMeansTestedBenefitSystem,
    lha :: LocalHousingAllowance )
    # aliases
    bures = benefit_unit_result
    bu = benefit_unit
    
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
        premia,premset = calc_premia(
            which_mig,
            bu,
            intermed,        
            mt_ben_sys.premia,
            age_limits )            
        union!(bures.legacy_mtbens.premiums, premset)
        incomes = calc_incomes( 
            which_mig,
            bu,
            bures,
            intermed,
            mt_ben_sys.income_rules )
        allowances = calc_allowances(
            which_mig,
            intermed,
            mt_ben_sys.allowances,
            age_limits 
        )        
        mig = max( 0.0, premia+allowances - incomes.total_income );
        bures.legacy_mtbens.mig_incomes = incomes
        bures.legacy_mtbens.mig_allowances = allowances
        bures.legacy_mtbens.mig_premia = premia
        bures.legacy_mtbens.premia = premia
        if ! incomes.disqualified_on_capital
            if can_apply_for.esa 
                bures.legacy_mtbens.esa = mig
            elseif can_apply_for.jsa
                bures.legacy_mtbens.jsa = mig
            elseif can_apply_for.is
                bures.legacy_mtbens.is = mig
            end
        end
    end
    
    if can_apply_for.pc
        premia, premset = calc_premia(
            pc,
            bu,
            intermed,        
            mt_ben_sys.premia,
            age_limits )            
        union!(bures.legacy_mtbens.premiums, premset )
        incomes = calc_incomes( 
            pc,
            bu,
            bures,
            intermed.
            mt_ben_sys.income_rules )
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
        bures.legacy_mtbens.ctc_premia = premia

        miglevel = premia+allowances
        
        if can_apply_for.sc && ( ! incomes.disqualified_on_capital )  
            scsys = mt_ben_sys.savings_credit #  shortcut
            sc_incomes = calc_incomes( 
                pc,
                bu,
                bu_result,
                intermed.
                mt_ben_sys.income_rules )
            thresh = scsys.threshold_single
            maxpay = scsys.threshold_single
            if num_adults > 1
                thresh = scsys.threshold_couple
                maxpay = scsys.max_couple
            end
            # see: CPAG 2011/12 edition ch 19
            sc_income = scsys.withdrawal_rate * 
                max(0.0, sc_incomes.total_income-thresh)
            
            inc_over_mig = (1-scsys.withdrawal_rate)*max(0.0, incomes.total_income-miglevel)
            bures.legacy_mtbens.sc = max( 0.0, sc_income - income_over_mig )
            bures.legacy_mtbens.sc_incomes = sc_incomes   
        end
        bures.legacy_mtbens.pc = bures.legacy_mtbens.mig + bures.legacy_mtbens.sc
    end
    
    if can_apply_for.wtc || can_apply_for.ctc
        bures.legacy_mtbens.wtc = calcWTC_CTC!( 
                bu_result,
                bu,
                intermed,
                mt_ben_sys.working_tax_credit,
                mt_ben_sys.child_tax_credit,
                can_apply_for )
    
    end
    
    passported_hb = false
    passported_ctr = false
    #
    # Passporting
    #
    if bures.legacy_mtbens.pc > 0 || bures.legacy_mtbens.jsa > 0 || bures.legacy_mtbens.is > 0 || bures.legacy_mtbens.esa > 0
        passported_hb = true
        passported_ctr = true        
    end

    if can_apply_for.hb
    
    end
    if can_apply_for.ctr
    
    end
end

end # module LegacyMeansTestedBenefits
