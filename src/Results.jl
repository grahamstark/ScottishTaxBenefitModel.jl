module Results

    using Parameters: @with_kw
    using DataFrames

    using ScottishTaxBenefitModel
    using .Definitions
    using .GeneralTaxComponents: RateBands
    using .ModelHousehold: Household, Person, BenefitUnits, BenefitUnit, 
        get_benefit_units, Pid_Array
    
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
        LMTCanApplyFor,
        search, 
        has_income,
        aggregate!

    
    @with_kw mutable struct LMTIncomes{RT<:Real}
        gross_earnings :: RT = zero(RT)
        net_earnings   :: RT = zero(RT)
        other_income   :: RT = zero(RT)
        total_income   :: RT = zero(RT)
        disregard :: RT = zero(RT)
        childcare :: RT = zero(RT)
        capital :: RT = zero(RT)
        tariff_income :: RT = zero(RT)
        disqualified_on_capital :: Bool = false
    end

    # 
    @with_kw mutable struct LMTCanApplyFor
        esa :: Bool = false
        is :: Bool = false
        jsa :: Bool = false
        sc  :: Bool = false
        pc  :: Bool = false
        ndds :: Bool = false
        wtc  :: Bool = false
        ctc  :: Bool = false
        hb  :: Bool = false
        ctr :: Bool = false
    end
        
    @with_kw mutable struct LMTResults{RT<:Real}
        esa :: RT = zero(RT)
        hb  :: RT = zero(RT)
        is :: RT = zero(RT)
        jsa :: RT = zero(RT)
        pc  :: RT = zero(RT)
        mig  :: RT = zero(RT)
        sc   :: RT = zero(RT)
        ndds :: RT = zero(RT)
        wtc  :: RT = zero(RT)
        ctr  :: RT = zero(RT)
        # FIXME better name than MIG here
        mig_premia :: RT = zero(RT)
        mig_allowances :: RT = zero(RT)
        mig_incomes = LMTIncomes{RT}()
        
        ctc_premia :: RT = zero(RT)
        ctc_allowances :: RT = zero(RT)
        ctc_incomes = LMTIncomes{RT}()
        
        sc_incomes = LMTIncomes{RT}()
        
        wtc_income  :: RT = zero(RT)
        wtc_elements :: RT = zero(RT)
        wtc_ctc_threshold :: RT = zero(RT)
        ctc_elements :: RT = zero(RT)
        ctc_childcare :: RT = zero(RT)

        hb_premia :: RT = zero(RT)
        hb_allowances :: RT = zero(RT)
        hb_incomes = LMTIncomes{RT}()

        ctb_premia :: RT = zero(RT)
        ctb_allowances :: RT = zero(RT)
        ctb_incomes = LMTIncomes{RT}()
        
        premiums = LMTPremiaSet()
        can_apply_for = LMTCanApplyFor()
        # intermediate :: Dict = Dict()
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
    
    function add_to!( ni :: NIResult, ni2 :: NIResult )
        ni.above_lower_earnings_limit += ni2.above_lower_earnings_limit
        ni.total_ni += ni2.total_ni
        ni.class_1_primary    += ni2.class_1_primary   
        ni.class_1_secondary  += ni2.class_1_secondary 
        ni.class_2   += ni2.class_2  
        ni.class_3   += ni2.class_3  
        ni.class_4   += ni2.class_4  
        ni.assumed_gross_wage += ni2.assumed_gross_wage    
    end

    @with_kw mutable struct ITResult{RT<:Real}
        total_tax :: RT = 0.0
        taxable_income :: RT = 0.0
        adjusted_net_income :: RT = 0.0
        total_income :: RT = 0.0
        allowance   :: RT = 0.0
        
        non_savings_tax :: RT = 0.0
        non_savings_band :: Integer = 0
        non_savings_income :: RT = 0.0
        non_savings_taxable :: RT = 0.0
        
        savings_tax :: RT = 0.0
        savings_band :: Integer = 0
        savings_income :: RT = 0.0
        savings_taxable :: RT = 0.0
        
        dividends_tax :: RT = 0.0
        dividend_band :: Integer = 0
        dividends_income :: RT = 0.0
        dividends_taxable :: RT = 0.0
        
        unused_allowance :: RT = 0.0
        mca :: RT = 0.0
        transferred_allowance :: RT = 0.0
        pension_eligible_for_relief :: RT = 0.0
        pension_relief_at_source :: RT = 0.0
        
        non_savings_thresholds :: RateBands = zeros(RT,0)
        savings_thresholds  :: RateBands = zeros(RT,0)
        dividend_thresholds :: RateBands = zeros(RT,0)
        
        savings_rates  :: RateBands = zeros(RT,0)
        dividend_rates :: RateBands = zeros(RT,0)
        
        personal_savings_allowance :: RT = 0.0
    end
    
    function add_to!( it :: ITResult; it2 :: ITResult )
        it.total_tax += it2.total_tax
        it.taxable_income += it2.taxable_income
        it.adjusted_net_income += it2.adjusted_net_income
        it.total_income += it2.total_income
        it.allowance   += it2.allowance  
                
        it.non_savings_tax += it2.non_savings_tax
        it.non_savings_band += it2.non_savings_band
        it.non_savings_income += it2.non_savings_income
        it.non_savings_taxable += it2.non_savings_taxable
                
        it.savings_tax += it2.savings_tax
        it.savings_band += it2.savings_band
        it.savings_income += it2.savings_income
        it.savings_taxable += it2.savings_taxable
                
        it.dividends_tax += it2.dividends_tax
        it.dividend_band += it2.dividend_band
        it.dividends_income += it2.dividends_income
        it.dividends_taxable += it2.dividends_taxable
                
        it.unused_allowance += it2.unused_allowance
        it.mca += it2.mca
        it.transferred_allowance += it2.transferred_allowance
        it.pension_eligible_for_relief += it2.pension_eligible_for_relief
        it.pension_relief_at_source += it2.pension_relief_at_source
                
        it.personal_savings_allowance += it2.personal_savings_allowance
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

        it_summed = false # so we can aggregated these bits before everything
                          # is complete without double counting
        ni_summed = false
        ni = NIResult{RT}()
        it = ITResult{RT}()
        it_adults = ITResult{RT}()
        
        legacy_mtbens = LMTResults{RT}()
        other_benefits  :: RT = zero(RT)
        pers = Dict{BigInt,IndividualResult{RT}}()
        adults = Pid_Array()
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
        bur.adults = bu.adults
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
    
    #
    # used for the WTC calculation
    # 
    function aggregate_tax( bu :: BenefitUnitResult; include_children :: Bool = true ) :: Tuple
        pids = include_children ? keys( bu.pers ) : bu.adults
        T = typeof( bu.eq_scale )
        it = ITResult{T}()
        ni = NIResult{T}()
        for pid in pids
            add_to!( it, bu.pers[pid].it )
            add_to!( ni, bu.pers[pid].ni )
        end
        return (it,ni)
    end
    
    function aggregate!( bu :: BenefitUnitResult )
        # TODO FINISH  THIS
        pids = include_children ? keys( bu.pers ) : bu.adults
        bu.it, bu.ni = aggregate_tax( bu, include_children=true )
        bu.income_taxes =bu.it.total_tax + bu.ni.total_ni
        for pid in pids
            
        end
    end

    function aggregate!( hhr :: HouseholdResult )
        # TODO ..
        
        for bu in hhr.bus
            aggregate!( bu )
            hhr.income_taxes += bu.income_taxes
            hhr.bhc_net_income + bu.net_income
            ## etc.
        end
        hhr.ahc_net_income = hhr.bhc_net_income
        hhr.net_housing_costs = 0.0 # SOMETHING
        hhr.eq_scale = 1.0
        ## do something with hb,ctr
    end

end
