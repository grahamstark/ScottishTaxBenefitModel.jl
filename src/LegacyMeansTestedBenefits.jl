module LegacyMeansTestedBenefits

using ScottishTaxBenefitModel
using .Definitions
using .ModelHousehold: Person,BenefitUnit,Household, is_lone_parent,
    is_single, pers_is_disabled, pers_is_carer, search, count,
    has_disabled_member, has_carer_member, le_age, between_ages, ge_age,
    empl_status_in, has_children, num_adults
using .STBParameters: LegacyMeansTestedBenefitSystem, IncomeRules, 
    Premia, PersonalAllowances, HoursLimits, AgeLimits
using .GeneralTaxComponents: TaxResult, calctaxdue, RateBands
using .Results: BenefitUnitResult, HouseholdResult, IndividualResult, LMTIncomes,
    LMTResults, has_income, LMTCanApplyFor
using .Utils: mult, haskeys

export calc_legacy_means_tested_benefits, tariff_income,
    LMTResults, is_working, make_lmt_benefit_applicability,
    working_disabled

function is_working( pers :: Person, hours... ) :: Bool
    # println( "hours=$hours employment=$(pers.employment_status)")
    (pers.usual_hours_worked > hours[1]) || 
    (pers.employment_status in [Full_time_Employee,Full_time_Self_Employed])
end

"""
Incomes for olds style mt benefits
The CPAG guide ch 21/21 has over 100 pages on this stuff
this can no more than catch the gist.
"""
function calc_incomes( 
    which_ben :: LMTBenefitType, # esa hb is jsa pc wtc ctc
    bu :: BenefitUnit, 
    bur :: BenefitUnitResult, 
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
    is_sparent = is_lone_parent( bu )
    is_sing = is_single( bu )
    is_disabled = has_disabled_member( bu )
    is_carer = has_carer_member( bu )
    nu16s = count( bu, le_age, 16 )
    if which_ben == hb
        inclist = incrules.hb_incomes
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
        net = 
            gross - ## FIXME parameterise this so we can use gross/net
            pres.it.non_savings -
            pres.ni.total_ni - 
            0.5 * get(pers.income, pension_contributions_employee, 0.0 )
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
    disreg = is_sing ?  incrules.low_single : incrules.low_couple
    
    if( which_ben == esa ) 
        if ! search( bu, is_working, hours.lower )
            disreg = incrules.high
            # and some others ... see CPAG 
        end
    elseif which_ben in [hb,jsa,is,pc]
        if is_sparent            
            disreg = which_ben == hb ? incrules.lone_parent_hb : incrules.high 
        elseif haskeys(mntr.premia, carer_single, carer_couple, disability_couple, disability_single, severe_disability_couple, severe_disability_single )
            disreg = incrules.high
        end       
    end

    if( which_ben == hb ) 
        # fixme do this above
        if( Results.has_income( bu, bur, employment_and_support_allowance ))     
            disreg = incrules.high
        end
        # HB disregard CPAG p432 this, too, is very approximate
        # work 30+ hours - should really check premia if haskeys( mtr.premia )
        extra = 0.0
        if search( bu, is_working, hours.higher )
            extra = incrules.hb_additional 
        elseif search(  bu, is_working, hours.lower )
            if is_sparent || (nu16s > 0) || is_disabled
                extra = incrules.hb_additional
            end
        end
        disreg += extra
        # childcare in HB - costs are assigned in frs to the children
        if ( nu16s > 0 ) 
            maxcc = nu16s == 1 ? incrules.childcare_max_1 : incrules.childcare_max_2
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
    inc.tariff_income = tariff_income(cap,incrules.capital_min,incrules.capital_tariff)
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

"""
The strategy here is to include *all* benefits the BU is entitled to
and then decide later on which ones to route to. Source: CPAG chs 9-15
'Who can get XX' sections.
"""
function make_lmt_benefit_applicability( 
    bu :: BenefitUnit, 
    hrs :: HoursLimits,
    ages :: AgeLimits ) :: LMTCanApplyFor
    whichb = LMTCanApplyFor()
    pens_age = search( bu, ge_age, ages.state_pension_age)
    working_ft = search( bu, is_working, hrs.higher )
    working_pt :: Int = count( bu, is_working, hrs.lower )
    working_24 :: Int = count( bu, is_working, hrs.med )
    total_hours_worked = 0
    is_carer = has_carer_member( bu )
    is_sparent = is_lone_parent( bu )
    is_sing = is_single( bu )
    
    ge_16_u_pension_age = search( bu, between_ages, 16, ages.state_pension_age-1)
    limited_capacity_for_work = has_disabled_member( bu ) # FIXTHIS
    has_kids = has_children( bu )
    economically_active = search( bu, empl_status_in, 
        [Full_time_Employee,
        Part_time_Employee,
        Full_time_Self_Employed,
        Part_time_Self_Employed,
        Unemployed, Temporarily_sick_or_injured])
    # can't think of a simple way of doing the rest with searches..
    num_employed = 0
    num_unemployed = 0
    num_semi_employed = 0
    
    num_adlts = num_adults( bu )
    for pid in bu.adults
        pers = bu.people[pid]
        if ! is_working( pers, hrs.lower )
            num_unemployed += 1
        elseif pers.usual_hours_worked <= hrs.med
            num_semi_employed += 1
        end
        total_hours_worked += pers.usual_hours_worked
    end
    if pens_age
        whichb.pc = true
    end
 
    # ESA, JSA, IS, crudely
    if ((num_adlts == 1 && num_unemployed == 1) || 
       (num_adlts == 2 && (num_unemployed>=1 && num_semi_employed<=1))) &&
       ge_16_u_pension_age

        if limited_capacity_for_work
            whichb.esa = true 
        elseif economically_active 
            whichb.jsa = true  
        else
            whichb.is = true
        end
    end
    #
    # tax credits
    # CTC - easy
    if has_kids
        whichb.ctc = true
    end
    #
    # WTC - not quite so easy
    #
    if working_ft
        whichb.wtc = true
    elseif (total_hours_worked >= hrs.med) && working_pt && has_kids 
        # ie. 24 hrs worked total and one person  >= 16 hrs and has kids
        whichb.wtc = true
    elseif working_pt && pens_age
        whichb.wtc = true
    elseif working_pt && is_sparent
        whichb.wtc = true
    else
        for pid in bu.adults
            pers = bu.people[pid]
            if working_disabled( pers, hrs )
                whichb.wtc = true
                break
            end
        end # wtc loop
    end
    return whichb
end

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

function calc_premia( bu :: BenefitUnit ) LMTPremiaDic{Bool}

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

function calc_LHA()

end

function calc_WTC()

end

function calc_legacy_means_tested_benefits(
    pers   :: Person,
    sys    :: LegacyMeansTestedBenefitSystem ) :: LMTResults

end

end # module LegacyMeansTestedBenefits
