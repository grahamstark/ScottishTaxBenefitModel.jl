module NonMeansTestedBenefits

    using ScottishTaxBenefitModel
    using .Utils: nearest

    function nearz( x :: Real, comps ... ) :: Real
        if x ≈ 0
            return 0.0
        end
        return nearest( x, comps ... )
    end


    function widows( 
        pers :: Person{T}, 
        persr :: PersonalResult{T}
        has_kids :: Boolean, 
        wp :: WindowsPension{T})
        nearz( pers.income[])
        if pers.income[]
    end

end # package non-means-tested