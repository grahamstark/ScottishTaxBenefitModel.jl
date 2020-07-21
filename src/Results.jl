module Results

    using Parameters: @with_kw
    using DataFrames

    import ScottishTaxBenefitModel:
        ModelHousehold,
        Definitions,
        NationalInsuranceCalculations,
        IncomeTaxCalculations
    using .Definitions
    using .ModelHousehold: BenefitUnits


    export IndividualResult,
        BenefitUnitResult,
        HouseholdResult,
        init_household_result

    @with_kw mutable struct IndividualResult{RT<:Real}
       ni = NIResult{RT}()
       it = ITResult{RT}()
       # ...
    end

    @with_kw mutable struct BenefitUnitResult{RT<:Real}
        net_income    :: RT = zero(RT)
        eq_net_income :: RT = zero(RT)
        pers          = Dict{BigInt,IndividualResult{RT}}()
    end

    @with_kw mutable struct HouseholdResult{RT<:Real}
        bhc_net_income :: RT = zero(RT)
        eq_bhc_net_income :: RT = zero(RT)
        ahc_net_income :: RT = zero(RT)
        eq_ahc_net_income :: RT = zero(RT)
        bus = Vector{BenefitUnitResult{RT}}(undef,0)
    end

    # create results that mirror some
    # allocation of people to benefit units
    function init_household_result( bus :: BenefitUnits )
        hr = HouseholdResult()
        for bu in bus
            bur = BenefitUnitResult()
            for pid in keys( bu.people )
                bur[pid] = IndividualResult()
            end
            push!( hr.bus, bur )
        end
        return hr
    end


end
