module Results

    using Parameters: @with_kw
    using DataFrames

    import ScottishTaxBenefitModel:
        ModelHousehold,
        Definitions,
        NationalInsuranceCalculations,
        IncomeTaxCalculations
    using .Definitions
    using .ModelHousehold: Household, BenefitUnits, get_benefit_units
    using .IncomeTaxCalculations: ITResult
    using .NationalInsuranceCalculations: NIResult

    export IndividualResult,
        BenefitUnitResult,
        HouseholdResult,
        init_household_result

    @with_kw mutable struct IndividualResult{RT<:Real}
       ni = NIResult{RT}()
       it = ITResult{RT}()
       income_taxes :: RT = zero(RT)
       means_tested_benefits :: RT = zero(RT)
       other_benefits  :: RT = zero(RT)
       
       # ...
    end

    @with_kw mutable struct BenefitUnitResult{RT<:Real}
        net_income    :: RT = zero(RT)
        eq_net_income :: RT = zero(RT)
        income_taxes :: RT = zero(RT)
        means_tested_benefits :: RT = zero(RT)
        other_benefits  :: RT = zero(RT)
        pers          = Dict{BigInt,IndividualResult{RT}}()
    end

    @with_kw mutable struct HouseholdResult{RT<:Real}
        bhc_net_income :: RT = zero(RT)
        eq_bhc_net_income :: RT = zero(RT)
        ahc_net_income :: RT = zero(RT)
        eq_ahc_net_income :: RT = zero(RT)
        net_housing_costs :: RT = zero(RT)
        income_taxes :: RT = zero(RT)
        means_tested_benefits :: RT = zero(RT)
        other_benefits  :: RT = zero(RT)
        bus = Vector{BenefitUnitResult{RT}}(undef,0)
    end

    # create results that mirror some
    # allocation of people to benefit units
    function init_household_result( hh :: Household{IT,RT} ) :: HouseholdResult{RT} where IT <: Integer where RT <: Real
        bus = get_benefit_units(hh)
        hr = HouseholdResult{RT}()
        for bu in bus
            bur = BenefitUnitResult{RT}()
            for pid in keys( bu.people )
                # println( "pid=$pid")
                bur.pers[pid] = IndividualResult{RT}()
            end
            push!( hr.bus, bur )
        end
        return hr
    end

    function aggregate( hhr :: HouseholdResult )


    end


end
