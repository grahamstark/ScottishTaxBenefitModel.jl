module LegacyMeansTestedBenefits

using ScottishTaxBenefitModel
using .Definitions
using .ModelHousehold: Person,BenefitUnit,Household, is_lone_parent,
    is_single, pers_is_disabled, pers_is_carer, search, count, under_age,
    has_disabled_member, has_carer_member
using .STBParameters: LegacyMeansTestedBenefitSystem, IncomeRules, 
    Premia, PersonalAllowances, HoursLimits
using .GeneralTaxComponents: TaxResult, calctaxdue, RateBands
using .Results: BenefitUnitResult, HouseholdResult, IndividualResult, LMTIncomes,
    LMTResults
using .Utils: mult, haskeys

export calc_legacy_means_tested_benefits, 
    LMTResults, working_for_esa_purposes

function working_for_esa_purposes( pers :: Person, hours... ) :: Bool
    println( "hours=$hours employment=$(pers.employment_status)")
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
    nu16s = count( bu, under_age, 16 )
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
    
    if which_ben == esa
        if ! search( bu, working_for_esa_purposes, hours.lower )
            disreg = incrules.high
            # and some others ... see CPAG 
        end
    elseif which_ben in [hb,jsa,is,pc]
        # childcare
        if is_sparent            
            disreg = which_ben == hb ? incrules.lone_parent_hb : incrules.high 
        elseif haskeys(mntr.premia, carer_single, carer_couple, disability_couple, disability_single, severe_disability_couple, severe_disability_single )
            disreg = incrules.high
        end       
    end
    # childcare in HB
    if( which_ben == hb ) && ( nu16s > 0 ) 
        maxcc = nu16s == 1 ? incrules.childcare_max_1 : incrules.childcare_max_2
        cost_of_childcare = 0.0
        for (pid,pers) in bu.people 
            cost_of_childcare += pers.cost_of_childcare
        end
        inc.childcare = min(cost_of_childcare, maxcc )
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
    inc.tariff_income = trunc( max(0.0, cap-incrules.capital_min)/incrules.capital_tariff)
    inc.total_income = inc.net_earnings + inc.other_income + inc.tariff_income    
    inc.disregard = disreg
    return inc
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
