module NonMeansTestedBenefits

    using ScottishTaxBenefitModel
    using .Utils: nearest

    function nearz( x :: Real, comps ... ) :: Real
        if x ≈ 0
            return 0.0
        end
        return nearest( x, comps ... )
    end



end # package non-means-tested