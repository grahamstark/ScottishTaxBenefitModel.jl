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
    LMTResults, is_working_hours, make_lmt_benefit_applicability,
    working_disabled, MTIntermediate, make_intermediate

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


struct MTIntermediate
    age_youngest_adult :: Int
    age_oldest_adult :: Int
    age_youngest_child :: Int
    age_oldest_child :: Int
    num_adults :: Int
    pens_age  :: Bool 
    all_pens_age :: Bool
    working_ft  :: Bool 
    num_working_pt :: Int 
    num_working_24_plus :: Int 
    total_hours_worked :: Int
    is_carer :: Bool 
    is_sparent  :: Bool 
    is_sing  :: Bool 
    is_disabled :: Bool
    nu16s :: Int
    ge_16_u_pension_age  :: Bool 
    limited_capacity_for_work  :: Bool 
    has_kids  :: Bool 
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
    which_ben :: LMTBenefitType, # esa hb is jsa pc wtc ctc
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
    
    if which_ben == hb
        inclist = incrules.hb_incomes
    elseif which_ben in [pc,ctc,wtc]
        inclist = incrules.tc_incomes
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
                pres.it.non_savings -
                pres.ni.total_ni - 
                0.5 * get(pers.income, pension_contributions_employee, 0.0 )
        else
            # wtc,ctc all pension contributions but not IT/NI
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
        if search( bu, is_working_hours, hours.higher )
            extra = incrules.hb_additional 
        elseif search(  bu, is_working_hours, hours.lower )
            if intermed.is_sparent || (intermed.nu16s > 0) || intermed.is_disabled
                extra = incrules.hb_additional
            end
        end
        disreg += extra
        # childcare in HB - costs are assigned in frs to the children
        if ( intermed.nu16s > 0 ) 
            maxcc = intermed.nu16s == 1 ? incrules.childcare_max_1 : incrules.childcare_max_2
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

function make_intermediate(
    bu   :: BenefitUnit, 
    hrs  :: HoursLimits,
    ages :: AgeLimits ) :: MTIntermediate
    # {RT} where RT
    age_youngest_adult :: Int = 9999
    age_oldest_adult :: Int = -9999
    age_youngest_child :: Int = 9999
    age_oldest_child :: Int = -9999
    
    is_working_disabled :: Bool = false
    num_adlts :: Int = num_adults( bu )
    num_pens_age :: Int = count( bu, ge_age, ages.state_pension_age) 
    println( "num_adults=$num_adults; num_pens_age=$num_pens_age")
    pens_age  :: Bool = num_pens_age > 0
    all_pens_age :: Bool = num_adlts == num_pens_age
    working_ft  :: Bool = search( bu, is_working_hours, hrs.higher )
    num_working_pt :: Int = count( bu, is_working_hours, hrs.lower, hrs.higher-1 )
    num_working_24_plus :: Int = count( bu, is_working_hours, hrs.med )
    total_hours_worked :: Int = 0
    is_carer :: Bool = has_carer_member( bu )
    is_sparent  :: Bool = is_lone_parent( bu )
    is_sing  :: Bool = is_single( bu )   
    ge_16_u_pension_age  :: Bool = search( bu, between_ages, 16, ages.state_pension_age-1)
    limited_capacity_for_work  :: Bool = has_disabled_member( bu ) # FIXTHIS
    has_kids  :: Bool = has_children( bu )
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
    end
    @assert 120 >= age_oldest_adult >= age_youngest_adult >= 16
    nu16s = count( bu, le_age, 16 )

    for pid in bu.children
        pers = bu.people[pid]
        if pers.age > age_oldest_child
            age_oldest_child = pers.age
        end
        if pers.age < age_youngest_child
            age_youngest_child = pers.age
        end
    end
    println( "has_kids $has_kids age_oldest_child $age_oldest_child age_youngest_child $age_youngest_child" )
    @assert (!has_kids)||(19 >= age_oldest_child >= age_youngest_child >= 0)
    
    println( typeof( total_hours_worked ))
                                   
    return MTIntermediate(
        age_youngest_adult,
        age_oldest_adult,
        age_youngest_child,
        age_oldest_child,
        num_adlts,
        pens_age,
        all_pens_age,
        working_ft,
        num_working_pt,
        num_working_24_plus,
        total_hours_worked,
        is_carer,
        is_sparent,
        is_sing,    
        is_disabled,
        nu16s,
        ge_16_u_pension_age,
        limited_capacity_for_work,
        has_kids,
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
    if intermed.pens_age
        whichb.pc = true
    end
    # ESA, JSA, IS, crudely
    if ! intermed.all_pens_age 
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
    if intermed.has_kids
        whichb.ctc = true
    end
    #
    # WTC - not quite so easy
    #
    println( "working_ft $(intermed.working_ft) num_working_pt $(intermed.num_working_pt)  has_kids $(intermed.has_kids) pens_age $(intermed.pens_age) ")
    if intermed.working_ft
        whichb.wtc = true
    elseif (intermed.total_hours_worked >= hrs.med) && (intermed.num_working_pt>0) && intermed.has_kids 
        # ie. 24 hrs worked total and one person  >= 16 hrs and has kids
        whichb.wtc = true
    elseif (intermed.num_working_pt>0) && intermed.pens_age
        whichb.wtc = true
    elseif (intermed.num_working_pt>0) && intermed.is_sparent
        whichb.wtc = true
    elseif intermed.working_disabled
        whichb.wtc = true
    end
    
    # hb,ctb are assumed true 
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

function calc_allowances( 
    intermed :: MTIntermediate, 
    which_applic :: LMTCanApplyFor ) :: Real
    allows = 0.0
    if intermed.num_adults == 2 
        if intermed.pens_age
        
        end
    end
        
         age_18_24 :: RT = 57.90
         age_25_and_over :: RT = 73.10
         age_18_and_in_work_activity :: RT = 73.10
         over_pension_age :: RT = 181.10
         lone_parent :: RT = 73.10
         lone_parent_over_pension_age :: RT = 181.00
         couple_both_over_18 :: RT = 114.85
         couple_over_pension_age :: RT = 270.60
         couple_one_over_18_high :: RT = 114.85
         couple_one_over_18_med :: RT = 173.10
         pa_couple_one_over_18_low :: RT = 57.90
    return allows
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
