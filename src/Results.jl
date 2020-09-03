module Results

    using Parameters: @with_kw
    using DataFrames

    using ScottishTaxBenefitModel
    using .Definitions
    using .GeneralTaxComponents: RateBands
    using .ModelHousehold: Household, BenefitUnits, BenefitUnit, 
        get_benefit_units
    
    export
        ITResult,
        NIResult, 
        IndividualResult,
        BenefitUnitResult,
        HouseholdResult,
        init_household_result,
        init_benefit_unit_result,
        LMTIncomes,
        LMTResults,
        search, 
        has_income

    
    @with_kw mutable struct LMTIncomes{RT<:Real}
        gross_earnings :: RT = zero(RT)
        net_earnings   :: RT = zero(RT)
        other_income   :: RT = zero(RT)
        total_income   :: RT = zero(RT)
        disregard :: RT = zero(RT)
        childcare :: RT = zero(RT)
        capital :: RT = zero(RT)
        tariff_income :: RT = zero(RT)
    end
        
    @with_kw mutable struct LMTResults{RT<:Real}
        esa :: RT = zero(RT)
        hb  :: RT = zero(RT)
        is :: RT = zero(RT)
        jsa :: RT = zero(RT)
        pc  :: RT = zero(RT)
        ndds :: RT = zero(RT)
        wtc  :: RT = zero(RT)
        ctc  :: RT = zero(RT)
        premia :: LMTPremiaDict{Bool} = LMTPremiaDict{Bool}()
        intermediate :: Dict = Dict()
    end

    @with_kw mutable struct NIResult{RT<:Real}
        above_lower_earnings_limit :: Bool = false
        total_ni :: RT = 0.0
        class_1_primary    :: RT = 0.0
        class_1_secondary  :: RT = 0.0
        class_2   :: RT = 0.0
        class_3   :: RT = 0.0
        class_4   :: RT = 0.0
        assumed_gross_wage :: RT = 0.0
    end

    @with_kw mutable struct ITResult{RT<:Real}
        total_tax :: RT = 0.0
        taxable_income :: RT = 0.0
        adjusted_net_income :: RT = 0.0
        total_income :: RT = 0.0
        non_savings :: RT = 0.0
        allowance   :: RT = 0.0
        non_savings_band :: Integer = 0
        savings :: RT = 0.0
        savings_band :: Integer = 0
        dividends :: RT = 0.0
        dividend_band :: Integer = 0
        unused_allowance :: RT = 0.0
        mca :: RT = 0.0
        transferred_allowance :: RT = 0.0
        pension_eligible_for_relief :: RT = 0.0
        pension_relief_at_source :: RT = 0.0
        non_savings_thresholds :: RateBands = zeros(RT,0)
        savings_thresholds  :: RateBands = zeros(RT,0)
        dividend_thresholds :: RateBands = zeros(RT,0)
        intermediate :: Dict = Dict()
    end
    
    @with_kw mutable struct IndividualResult{RT<:Real}
       eq_scale  :: RT = zero(RT)
       net_income :: RT =zero(RT)
       ni = NIResult{RT}()
       it = ITResult{RT}()
       income_taxes :: RT = zero(RT)
       means_tested_benefits :: RT = zero(RT)
       other_benefits  :: RT = zero(RT)
       incomes = Dict{Incomes_Type,RT}()
       # ...
    end

    @with_kw mutable struct BenefitUnitResult{RT<:Real}
        eq_scale  :: RT = zero(RT)
        net_income    :: RT = zero(RT)
        eq_net_income :: RT = zero(RT)
        income_taxes :: RT = zero(RT)
        means_tested_benefits :: RT = zero(RT)
        legacy_mtbens = LMTResults{RT}()
        other_benefits  :: RT = zero(RT)
        pers = Dict{BigInt,IndividualResult{RT}}()
    end

    @with_kw mutable struct HouseholdResult{RT<:Real}
        eq_scale  :: RT = zero(RT)
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

    function has_income( pers::IndividualResult, which :: Incomes_Type )::Bool
        haskey( pers.incomes, which )
    end
    
    function has_income( pers::Person, ir :: IndividualResult, which ... ) :: Bool
        for inc in which
            @assert typeof( inc ) <: Incomes_Type
            if( haskey( ir.incomes, inc ))
                return true
            end
            if( haskey( pers.income, inc ))
                return true
            end
        end
        return false
    end

    function has_income( bu :: BenefitUnit, br :: BenefitUnitResult, which... )::Bool
        for pid in keys(bu.people)
            if has_income( bu.people[pid], br.pers[pid], which... )
                return true
            end
        end
        return false
    end

    """
    FIXME: this assumes the default allocator for BUs
    """
    function has_income( bus :: BenefitUnits, hr :: HouseholdResult, which ... ) :: Bool
        bus = get_benefit_units(hh)
        nbus = size(bus)[1]
        for bn in nbus
            if has_income( bus[bn], br.bus[bn], which... )
                return true
            end
        end
        return false
    end

    function search( bur :: BenefitUnitResult, func :: Function, params ...) :: Bool
        for (pid,pers ) in bur.pers
            if func( pers, params ... )
                return true
            end
            return false
        end
    end

    function search( hr :: HouseholdResult, func :: Function, params ... ) :: Bool
        for bu in hr.bus
            if search( bu, params ... )
                return true
            end
        end
        return false
    end


    function init_benefit_unit_result( RT::Type, bu :: BenefitUnit ) :: BenefitUnitResult
        bur = BenefitUnitResult{RT}()
        for pid in keys( bu.people )
            bur.pers[pid] = IndividualResult{RT}()
        end
        return bur
    end

    # create results that mirror some
    # allocation of people to benefit units
    function init_household_result( hh :: Household{RT} ) :: HouseholdResult{RT} where RT <: Real
        bus = get_benefit_units(hh)
        hr = HouseholdResult{RT}()
        for bu in bus
            push!( hr.bus, init_benefit_unit_result( RT, bu ))
        end
        return hr
    end

    function aggregate( hhr :: HouseholdResult )

    end


end
