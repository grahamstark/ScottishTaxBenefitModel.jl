module NonMeansTestedBenefits
    using Dates
    using Dates: Date, now, TimeType, Year
    using ScottishTaxBenefitModel
    using .Utils: nearest
    using .ModelHousehold: Person
    using .STBParameters: WidowsPensions, BereavementSupport, AgeLimits, 
        RetirementPension, PersonalIndependencePayment, reached_state_pension_age
    using .Results: BenefitUnitResult, HouseholdResult, IndividualResult, LMTIncomes
    using .Definitions
    export calc_widows_benefits, calc_state_pension

    function nearz( x :: Real, comps ... ) :: Real
        if x ≈ 0
            return 0.0
        end
        return nearest( x, comps ... )
    end


    function calc_widows_benefits(
        pers :: Person{T}, 
        has_kids :: Bool, 
        bp :: BereavementSupport{T},
        wp :: WidowsPensions{T}) :: T where T
        # We don't know when someone was widowed
        # so we rely on this.
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

    function calc_pip( 
        pers :: Person{T},
        pip  :: PersonalIndependencePayment{T}
    ) :: T where T
        
        0.0
    end

    function calc_state_pension( 
        pers :: Person{T}, 
        rp :: RetirementPension{T},
        age_limits :: AgeLimits ) :: T where T
        pen = 0.0
        if reached_state_pension_age( 
            age_limits, 
            pers.age, 
            pers.sex )
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

end # package non-means-tested