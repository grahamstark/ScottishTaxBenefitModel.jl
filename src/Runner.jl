module Runner

import BudgetConstraints: BudgetConstraint

    import ScottishTaxBenefitModel:
        GeneralTaxComponents,
        Definitions,
        Utils,
        STBParameters,
        Results,
        FRSHousholdGetter,
        ModelHousehold,
        SingleHouseholdCalculations
        
    import .GeneralTaxComponents: RateBands, WEEKS_PER_YEAR
    using .Definitions
    import .Utils
    using .STBParameters

    export do_one_run

    function do_one_run()

    end

end
