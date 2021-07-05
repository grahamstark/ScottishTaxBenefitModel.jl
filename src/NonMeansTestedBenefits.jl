module NonMeansTestedBenefits
#
# This module provides routines for benefits which are (mostly) not means-tested benefits,
# both current and historic. See [HistoricBenefits.jl] for the imputation routines used here.
#
    using Base: has_tight_type
    using Dates
    using Dates: Date, now, TimeType, Year
    using ScottishTaxBenefitModel
    using .Utils: nearest
    using .ModelHousehold: Person, get_benefit_units, Household, BenefitUnit
    using .STBParameters: NonMeansTestedSys, WidowsPensions, BereavementSupport, AgeLimits, 
        RetirementPension, PersonalIndependencePayment, 
        DisabilityLivingAllowance, reached_state_pension_age
    using .Results: BenefitUnitResult, HouseholdResult, IndividualResult, LMTIncomes
    using .Definitions

    export calc_widows_benefits, calc_state_pension, calc_dla, calc_pip, calc_non_means_tested!
    export calc_child_benefit!
 
    """
    Child Benefit - this has to be done *after* income tax, so we have
    income tax `total_income` for each adult in the `BenefitUnitResult` struct.
    """
    function calc_child_benefit!( 
        bures :: BenefitUnitResult,
        bu    :: BenefitUnit, 
        cb    :: ChildBenefit{T} )
        c = zero(T)
        #= FIXME something to check the exact type of children - 
        for now, assume the BU allocation has got this right.
        for pid in bu.children
            #
        end
        =#
        nc = num_children(bu)
        if nc == 0
            return
        end
        c += cb.first_child
        if nc > 1
            c += (nc-1)*cb.other_children
        end
        max_inc = zero(T)
        recipient :: BigInt = bu.spouse > 0 ? bu.spouse : bu.head
        # high income thing - highest of the BU's *individual* income; see cpag ch.27
        for pid in bu.adults
            max_inc = max( max_inc, bures.pers[pid].it.total_income )
            if bu.person[pid].sex == female
                recipient = pid
            end
        end
        # withdrawn 
        if max_inc > cb.high_income_thresh
            # this should really be done in steps £1 for every £100, but since
            # everything is weekly here we'll just multiply
            withdrawl = ch.withdrawal*(max_inc - cb.high_income_thresh)
            c = max(0.0, withdrawal)
        end
        # FIXME todo guardian's allowance
        bures.pers[recipient].income[CHILD_BENEFIT] = c
    end

    function calc_widows_benefits(
        pers :: Person{T}, 
        has_kids :: Bool, 
        bp :: BereavementSupport{T},
        wp :: WidowsPensions{T}) :: T where T
        #
        # We don't know when someone was widowed
        # so we rely on this. FIXME Obviously this gets progressively worse as time goes on and
        # we keep using the old years of FRS.
        #
        wid = 0.0
        # new-style: payable for 18 months at a flat rate
        # 
        if pers.bereavement_type == bereavement_allowance
            # payable for 18 months so we'll allocate
            # 2/3rds of the weekly value of the lump-sum
            if has_kids
                wid = bp.higher + bp.lump_sum_higher*2/3
            else
                wid = bp.lower + bp.lump_sum_lower*2/3
            end
        elseif pers.bereavement_type == widowed_parents # At least 3 years ago so no 
            # need to worry about lump-sums; just eq_scale
            # the standard rate by the ratio of
            # their receipt to the standard rate at the time
            # of interview.
            wid = pers.benefit_ratios[bereavement_allowance_or_widowed_parents_allowance_or_bereavement]*
                wp.standard_rate 
        else
            # check we're not missing anyone
            @assert ! has_key( pers.benefit_ratios, bereavement_allowance_or_widowed_parents_allowance_or_bereavement)
        end
        return wid
    end

    """
    PIP and DLA (below) rely on all the types being sorted out earlier
    either in some kind of probit or by being inferred from receipts (see [HistoricBenefits.jl] for
    what we have so far).
    """
    function calc_pip( 
        pers :: Person{T},
        pip  :: PersonalIndependencePayment{T}) :: Tuple{T,T} where T
        pl = zero(T)
        pm = zero(T)
        # fixme consistent names dl->daily living etc.
        if pers.pip_daily_living_type == standard_pip
            pl = pip.dl_standard    
        elseif pers.pip_daily_living_type == enhanced_pip
            pl = pip.dl_enhanced             
        end
        if pers.pip_mobility_type == standard_pip
            pm = pip.mobility_standard    
        elseif pers.pip_mobility_type == enhanced_pip
            pm = pip.mobility_enhanced             
        end
        return (pl, pm )
    end # pip calc

    function calc_dla(
        pers :: Person{T},
        dla  :: DisabilityLivingAllowance{T} ) :: Tuple{T,T} where T
        dc = zero(T)
        dm = zero(T)
        # FIXME make all these names constisent (mid/middle,care->self_care etc.)
        if pers.dla_self_care_type == high 
            dc = dla.care_high
        elseif pers.dla_self_care_type == mid
            dc = dla.care_middle
        elseif pers.dla_self_care_type == low 
            dc = dla.care_low
        end
        if pers.dla_mobility_type == high 
            dm = dla.mob_high
        elseif pers.dla_mobility_type in (low,mid)
            dm = dla.mob_low
        end
        return (dc,dm);
    end # dla calc

    function calc_state_pension( 
        pers :: Person{T}, 
        rp :: RetirementPension{T},
        age_limits :: AgeLimits ) :: T where T
        pen = zero(T)
        if reached_state_pension_age( 
            age_limits, 
            pers.age, 
            pers.sex )
            # so, was someone over pension age *before* the new state pension?
            # if so, use the proportion of the `class_a` they seemed to be on at 
            # the time, times the current `class_a`. 
            if reached_state_pension_age(
                age_limits, 
                pers.age, 
                pers.sex,
                age_limits.savings_credit_to_new_state_pension )
                pen = pers.benefit_ratios[state_pension]*rp.cat_a
                # old style 
            else
                # 
                # new style
                pen = rp.new_state_pension
            end
        end
        return pen
    end

    """
    Household level calculations for all nmt benefits.
    """
    function calc_non_means_tested!( 
        hhres :: HouseholdResult{T},
        hh    :: ModelHousehold{T},
        sys   :: NonMeansTestedSys,
        age_limits :: AgeLimits )
        ## maybe add a benefit unit allocator
        bus = get_benefit_units( hh )
        buno = 1 
        for bu in bus 
            has_children = size( bu.children )[1] > 0
            bures = hhres.bus[buno]
            for adno in bu.adults
                pers = bu.people[adno]
                pres = bures[adno]
                pres.income[STATE_PENSION] = calc_state_pension( 
                    pers,
                    sys.pensions, age_limits );
                pres.income[WIDOWS_PAYMENT] = calc_widows_benefits(
                    pers, has_children, sys.bereavement, sys.widows_pension )
                pres.income[DLA_SELF_CARE],pres.income[DLA_MOBILITY] = calc_dla( pers, sys.dla );
                pres.income[PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING],
                pres.income[PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY] = calc_pip( pers, sys.pip )
                # NON-overlapping rules p1178 go here 
            end # ad loop
            buno += 1
        end # bu loop
    end # calc_non_means_tested


end # package non-means-tested