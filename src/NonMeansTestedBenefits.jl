module NonMeansTestedBenefits
    using Dates
    using Dates: Date, now, TimeType, Year
    using ScottishTaxBenefitModel
    using .Utils: nearest
    using .ModelHousehold: Person
    using .STBParameters: WidowsPensions
    using .Results: BenefitUnitResult, HouseholdResult, IndividualResult, LMTIncomes

    export calc_widows_bens

    function nearz( x :: Real, comps ... ) :: Real
        if x ≈ 0
            return 0.0
        end
        return nearest( x, comps ... )
    end


    function calc_widows_bens(
        pers :: Person{T}, 
        has_kids :: Bool, 
        wp :: WindowsPensions{T}) :: T where T
        if pers.widows_type == bereavement_allowance

        else
            
        end
        #=
        nearz( pers.income[])
        if pers.income[]
        had_children_when_bereaved
        end
        =#
    end

end # package non-means-tested