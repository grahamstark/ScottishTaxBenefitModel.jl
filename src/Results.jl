module Results

    using Parameters: @with_kw
    using DataFrames
    using StaticArrays

    using ScottishTaxBenefitModel
    
    using .Definitions
    
    using .GeneralTaxComponents: RateBands

    using .ModelHousehold: 
        BenefitUnit, 
        BenefitUnits, 
        Household, 
        Person, 
        Pid_Array,
        get_benefit_units

    using .Incomes
    
    using .Utils:
        to_md_table

    export
        BenefitUnitResult,
        HouseholdResult,
        HousingResult,
        IndividualResult,
        ITResult,
        LMTCanApplyFor,
        LMTIncomes,
        LMTResults,
        LocalTaxes,
        NIResult, 

        aggregate_tax,
        aggregate!,
        has_any,
        init_benefit_unit_result,
        init_household_result,
        map_incomes,
        to_string,
        total

    
    @with_kw mutable struct UCResults{RT<:Real}
        basic_conditions_satisfied :: Bool = false
        disqualified_on_capital :: Bool = false
        income :: RT = zero(RT)
        standard_allowance  :: RT = zero(RT)
        elements ::  RT = zero(RT)
        childcare_costs :: RT = zero(RT)
        housing_element :: RT = zero(RT)
    end

                
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
        ctc  :: Bool = false
        esa :: Bool = false
        hb  :: Bool = false
        is :: Bool = false
        jsa :: Bool = false
        pc  :: Bool = false
        sc  :: Bool = false
        wtc  :: Bool = false
        ctr :: Bool = false
    end
        
    @with_kw mutable struct LMTResults{RT<:Real}
        #ctc :: RT = zero(RT) XX 
        #esa :: RT = zero(RT) x
        #hb  :: RT = zero(RT) x
        #is :: RT = zero(RT) x
        #jsa :: RT = zero(RT) x
        #pc  :: RT = zero(RT) x
        #sc   :: RT = zero(RT) x
        #wtc  :: RT = zero(RT)
        #ctr  :: RT = zero(RT) x
        
        ndds :: RT = zero(RT)
        mig  :: RT = zero(RT)
        
        # total_benefits :: RT = zero(RT) #  hb and ctr
        
        # FIXME better name than MIG here
        # FIXME rename premia => premium everywhere here
        mig_premia :: RT = zero(RT)
        mig_allowances :: RT = zero(RT)
        mig_incomes = LMTIncomes{RT}()
        sc_incomes = LMTIncomes{RT}()
        
         
        ctc_elements :: RT = zero(RT)   
        wtc_income  :: RT = zero(RT)
        wtc_elements :: RT = zero(RT)
        wtc_ctc_threshold :: RT = zero(RT)
        wtc_ctc_tapered_excess :: RT = zero(RT)
        cost_of_childcare :: RT = zero(RT)

        hb_passported :: Bool = false
        hb_premia :: RT = zero(RT)
        hb_allowances :: RT = zero(RT)
        hb_incomes = LMTIncomes{RT}()
        hb_eligible_rent :: RT = zero(RT)
        
        ctr_passported :: Bool = false
        ctr_premia :: RT = zero(RT)
        ctr_allowances :: RT = zero(RT)
        ctr_incomes = LMTIncomes{RT}()
        ctr_eligible_amount :: RT = zero(RT)

        pc_premia :: RT = zero(RT)
        pc_allowances :: RT = zero(RT)
        pc_incomes = LMTIncomes{RT}()
        
        premia = LMTPremiaSet()
        can_apply_for = LMTCanApplyFor()
    end

    @with_kw mutable struct NIResult{RT<:Real}
        above_lower_earnings_limit :: Bool = false
        # total_ni :: RT = 0.0
        class_1_primary    :: RT = 0.0
        class_1_secondary  :: RT = 0.0
        class_2   :: RT = 0.0
        class_3   :: RT = 0.0
        class_4   :: RT = 0.0
        assumed_gross_wage :: RT = 0.0
    end

    @with_kw mutable struct ITResult{RT<:Real}
        # total_tax :: RT = 0.0
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
    
    @with_kw mutable struct IndividualResult{RT<:Real}
       
       net_income :: RT = zero(RT)
       ni = NIResult{RT}()
       it = ITResult{RT}()
       income = Incomes.make_a( RT );
    end

    function to_string( ir :: IndividualResult, depth=2 )::String
        s = to_md_table( ir, exclude=[:income], depth=depth )
        s *= #*repeat("#",depth)*"Incomes";
        s *= inctostr( ir.income )
        return s
    end
    
    @with_kw mutable struct BenefitUnitResult{RT<:Real}
        income = Incomes.make_a( RT )
        eq_scale  :: RT = zero(RT)
        net_income    :: RT = zero(RT)
        eq_net_income :: RT = zero(RT)
        legacy_mtbens = LMTResults{RT}()
        uc = UCResults{RT}()
        other_benefits  :: RT = zero(RT)
        pers = Dict{BigInt,IndividualResult{RT}}()
        adults = Pid_Array()
    end

    function to_string( br :: BenefitUnitResult, depth=1 )::String
        s = to_md_table( br, exclude=[:pers,:adults,:income], depth=depth )
        s *= "#### Benefit Unit Incomes "
        s *= inctostr(br.income)
        for pid in sort(collect(keys(br.pers)))
            s *= "### Individual Result; Person $(pid)"
            s *= to_string( br.pers[pid] )
        end
        return s
    end

    function has_any( bur :: BenefitUnitResult, things :: AbstractArray ) :: Bool
        for (pid,pers) in bur.pers
            if any_positive( pers.income, things )
                return true
            end
        end
        return false
    end

    function has_any( bur :: BenefitUnitResult, things ... ) :: Bool
        return has_any( bur, collect( things ))
    end

    @with_kw mutable struct LocalTaxes{RT<:Real}
        # council_tax :: RT = zero(RT) 
        # this isn't really used at present since LOCAL_TAXES
        # are in the incomes list, but we'll keep it around for modelling other types of local 
        # tax in future.
        thing_just_to_make_with_kw_work :: RT = -99
    end


    function calc_net_income(incs::AbstractArray{T})::T where T
        return isum(incs, 
            ALL_INCOMES, 
            deducted=DIRECT_TAXES_AND_DEDUCTIONS )
    end


    @with_kw mutable struct HousingResult{RT<:Real}
        allowed_rooms :: Int = 0
        excess_rooms :: Int = 0
        allowed_rent :: RT = zero(RT) # FIXME this name
        gross_rent :: RT = zero(RT)
     end

    @with_kw mutable struct HouseholdResult{RT<:Real}
        income = Incomes.make_a( RT )
         
        bhc_net_income :: RT = zero(RT)
        eq_bhc_net_income :: RT = zero(RT)
        ahc_net_income :: RT = zero(RT)        
        eq_ahc_net_income :: RT = zero(RT)
        
        net_housing_costs :: RT = zero(RT)
        housing = HousingResult{RT}()
        # FIXME note this is at the household level, which makes local income taxes, etc. akward. OK for now.
        local_tax = LocalTaxes{RT}()
        # 
        # FIXME make this `people` to match the ModelHousehold
        # and adapt the get_benefit_units function 
        #
        bus = Vector{BenefitUnitResult{RT}}(undef,0)
    end

    function to_string( hr :: HouseholdResult, depth=0 )::String
        s = "# Results for Household"
        s *= to_md_table( hr, exclude=[:bus,:income], depth=depth )
        s *= "## HH Income"
        s *= inctostr( hr.income )
        s *= "\n\n"
        for bn in eachindex(hr.bus)
            s *= repeat("#",depth+1)*" Benefit Unit Result $(bn)"
            s *= to_string( hr.bus[bn], depth+1)
        end
        return s
    end

    """
    Test the individual incomes in hhr for some values
    """
    function has_any( hhr :: HouseholdResult, things ... ) :: Bool
        for bu in hhr.bus
            if has_any( bu, things ... )
                return true
            end
        end
        return false
    end

    function total( bur :: BenefitUnitResult{T}, which :: Int ) ::T where T
        t = zero(T)
        for (pid,pers) in bur.pers
            t += pers.income[which]
        end
        return t
    end

    function total( hhr :: HouseholdResult{T}, which :: Int ) :: T where T
        t = zero(T)
        for bu in hhr.bus
            t += total( bu, which )
        end
        return t
    end
    
    function add_to!( ni :: NIResult, ni2 :: NIResult )
        # ni.above_lower_earnings_limit += ni2.above_lower_earnings_limit
        # ni.total_ni += ni2.total_ni
        ni.class_1_primary    += ni2.class_1_primary   
        ni.class_1_secondary  += ni2.class_1_secondary 
        ni.class_2   += ni2.class_2  
        ni.class_3   += ni2.class_3  
        ni.class_4   += ni2.class_4  
        ni.assumed_gross_wage += ni2.assumed_gross_wage    
    end

    function add_to!( it :: ITResult, it2 :: ITResult )
        # it.total_tax += it2.total_tax
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

    """
    This is used to get aggregate taxable income for means-tested benefits;
    we don't really need bu/hh aggregated data in the results record other than total tax
    """
    function aggregate_tax( bu :: BenefitUnitResult{T}; include_children :: Bool = true ) :: Tuple where T
        pids = include_children ? keys( bu.pers ) : bu.adults
        it = ITResult{T}()
        ni = NIResult{T}()
        for pid in pids
            add_to!( it, bu.pers[pid].it )
            add_to!( ni, bu.pers[pid].ni )
        end
        return (it,ni)
    end
    

    function aggregate!( bures :: BenefitUnitResult{T} ) where T
        bures.income .= zero(T)
        for (pid,pers) in bures.pers
            bures.income .+= pers.income            
        end
        bures.net_income = calc_net_income( bures.income )
    end

    function aggregate!( hh :: Household{T}, hres :: HouseholdResult{T} ) where T
        hres.income .= zero(T)
        for bu in hres.bus
            aggregate!( bu )
            hres.income .+= bu.income
        end
        hres.bhc_net_income = calc_net_income( hres.income ) -
            hres.income[HOUSING_BENEFIT] - 
            hres.income[COUNCIL_TAX_BENEFIT]
        if hres.bhc_net_income <= 0 
            println("zero bhc_net_income for seq=$(hh.sequence); hid=$(hh.hid) year=$(hh.interview_year) ")
            println("income")
            println( inctostr( hres.income ))
            println( "bhc_net_income $(hres.bhc_net_income) HOUSING_BENEFIT=$(hres.income[HOUSING_BENEFIT]) COUNCIL_TAX_BENEFIT=$(hres.income[COUNCIL_TAX_BENEFIT]) hres.income[COUNCIL_TAX_BENEFIT]=$(hres.income[COUNCIL_TAX_BENEFIT])")
        end
        hres.net_housing_costs = hh.gross_rent + 
            hres.income[LOCAL_TAXES] +
            hh.mortgage_payment + 
            hh.other_housing_charges + 
            hh.water_and_sewerage -
            hres.income[HOUSING_BENEFIT] - 
            hres.income[COUNCIL_TAX_BENEFIT]
        hres.ahc_net_income = hres.bhc_net_income - hres.net_housing_costs        
        hres.eq_bhc_net_income = hres.bhc_net_income/hh.equivalence_scales.oecd_bhc
        hres.eq_ahc_net_income = hres.ahc_net_income/hh.equivalence_scales.oecd_ahc        
    end


   function init_benefit_unit_result( T::Type, bu :: BenefitUnit ) :: BenefitUnitResult{T}
        # FIXME add an explicit head/spouse pid here
        bur = BenefitUnitResult{T}()
        bur.adults = bu.adults
        for pid in keys( bu.people )
            bur.pers[pid] = IndividualResult{T}()
            bur.pers[pid].income = map_incomes( bu.people[pid])

        end
        return bur
    end

    # create results that mirror some
    # allocation of people to benefit units
    # FIXME remove the type and use where RT
    function init_household_result( hh :: Household{T} ) :: HouseholdResult{T} where T
        bus = get_benefit_units(hh)
        hr = HouseholdResult{T}()
        for bu in bus
            push!( hr.bus, init_benefit_unit_result( T, bu ))
        end
        return hr
    end
    

    function map_incomes( pers :: Person{T}; include_calculated :: Bool=false ) :: MVector{INC_ARRAY_SIZE,T} where T
        out = MVector{INC_ARRAY_SIZE,T}( zeros(T,INC_ARRAY_SIZE ))
        incd = pers.income
        if haskey(incd, Definitions.wages )
            out[WAGES] = incd[Definitions.wages]
        end
        if haskey(incd, Definitions.self_employment_income )
            out[SELF_EMPLOYMENT_INCOME] = incd[Definitions.self_employment_income]
        end
        if haskey(incd, Definitions.odd_jobs )
            out[ODD_JOBS] = incd[Definitions.odd_jobs]
        end
        if haskey(incd, Definitions.private_pensions )
            out[PRIVATE_PENSIONS] = incd[Definitions.private_pensions]
        end
        if haskey(incd, Definitions.national_savings )
            out[NATIONAL_SAVINGS] = incd[Definitions.national_savings]
        end
        if haskey(incd, Definitions.bank_interest )
            out[BANK_INTEREST] = incd[Definitions.bank_interest]
        end
        if haskey(incd, Definitions.stocks_shares )
            out[STOCKS_SHARES] = incd[Definitions.stocks_shares]
        end
        if haskey(incd, Definitions.individual_savings_account )
            out[INDIVIDUAL_SAVINGS_ACCOUNT] = incd[Definitions.individual_savings_account]
        end
        if haskey(incd, Definitions.property )
            out[PROPERTY] = incd[Definitions.property]
        end
        if haskey(incd, Definitions.royalties )
            out[ROYALTIES] = incd[Definitions.royalties]
        end
        if haskey(incd, Definitions.bonds_and_gilts )
            out[BONDS_AND_GILTS] = incd[Definitions.bonds_and_gilts]
        end
        if haskey(incd, Definitions.other_investment_income )
            out[OTHER_INVESTMENT_INCOME] = incd[Definitions.other_investment_income]
        end
        if haskey(incd, Definitions.other_income )
            out[OTHER_INCOME] = incd[Definitions.other_income]
        end
        if haskey(incd, Definitions.alimony_and_child_support_received )
            out[ALIMONY_AND_CHILD_SUPPORT_RECEIVED] = incd[Definitions.alimony_and_child_support_received]
        end
        if haskey(incd, Definitions.private_sickness_scheme_benefits )
            out[PRIVATE_SICKNESS_SCHEME_BENEFITS] = incd[Definitions.private_sickness_scheme_benefits]
        end
        if haskey(incd, Definitions.accident_insurance_scheme_benefits )
            out[ACCIDENT_INSURANCE_SCHEME_BENEFITS] = incd[Definitions.accident_insurance_scheme_benefits]
        end
        if haskey(incd, Definitions.hospital_savings_scheme_benefits )
            out[HOSPITAL_SAVINGS_SCHEME_BENEFITS] = incd[Definitions.hospital_savings_scheme_benefits]
        end
        if haskey(incd, Definitions.unemployment_or_redundancy_insurance )
            out[UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE] = incd[Definitions.unemployment_or_redundancy_insurance]
        end
        if haskey(incd, Definitions.permanent_health_insurance )
            out[PERMANENT_HEALTH_INSURANCE] = incd[Definitions.permanent_health_insurance]
        end
        if haskey(incd, Definitions.any_other_sickness_insurance )
            out[ANY_OTHER_SICKNESS_INSURANCE] = incd[Definitions.any_other_sickness_insurance]
        end
        if haskey(incd, Definitions.critical_illness_cover )
            out[CRITICAL_ILLNESS_COVER] = incd[Definitions.critical_illness_cover]
        end
        if haskey(incd, Definitions.trade_union_sick_or_strike_pay )
            out[TRADE_UNION_SICK_OR_STRIKE_PAY] = incd[Definitions.trade_union_sick_or_strike_pay]
        end
        if haskey(incd, Definitions.health_insurance )
            out[HEALTH_INSURANCE] = incd[Definitions.health_insurance]
        end
        if haskey(incd, Definitions.alimony_and_child_support_paid )
            out[ALIMONY_AND_CHILD_SUPPORT_PAID] = incd[Definitions.alimony_and_child_support_paid]
        end
        if haskey(incd, Definitions.trade_unions_etc )
            out[TRADE_UNIONS_ETC] = incd[Definitions.trade_unions_etc]
        end
        if haskey(incd, Definitions.friendly_societies )
            out[FRIENDLY_SOCIETIES] = incd[Definitions.friendly_societies]
        end
        if haskey(incd, Definitions.work_expenses )
            out[WORK_EXPENSES] = incd[Definitions.work_expenses]
        end
        if haskey(incd, Definitions.avcs )
            out[AVCS] = incd[Definitions.avcs]
        end
        if haskey(incd, Definitions.other_deductions )
            out[OTHER_DEDUCTIONS] = incd[Definitions.other_deductions]
        end
        if haskey(incd, Definitions.loan_repayments )
            out[LOAN_REPAYMENTS] = incd[Definitions.loan_repayments]
        end
        if haskey(incd, Definitions.pension_contributions_employee )
            out[PENSION_CONTRIBUTIONS_EMPLOYEE] = incd[Definitions.pension_contributions_employee]
        end
        if haskey(incd, Definitions.pension_contributions_employer )
            out[PENSION_CONTRIBUTIONS_EMPLOYER] = incd[Definitions.pension_contributions_employer]
        end

        ### passed through benefits
        if haskey(incd, Definitions.other_benefits )
            out[OTHER_BENEFITS] = incd[Definitions.other_benefits]
        end
        if haskey(incd, Definitions.student_grants )
            out[STUDENT_GRANTS] = incd[Definitions.student_grants]
        end
        if haskey(incd, Definitions.student_loans )
            out[STUDENT_LOANS] = incd[Definitions.student_loans]
        end
        if haskey(incd, Definitions.free_school_meals )
            out[FREE_SCHOOL_MEALS] = incd[Definitions.free_school_meals]
        end
        if haskey(incd, Definitions.social_fund_loan_repayment_from_is_or_pc) 
            out[SOCIAL_FUND_LOAN_REPAYMENT] = incd[Definitions.social_fund_loan_repayment_from_is_or_pc]
        end
        if haskey(incd, Definitions.social_fund_loan_repayment_from_jsa_or_esa) 
            out[SOCIAL_FUND_LOAN_REPAYMENT] += incd[Definitions.social_fund_loan_repayment_from_jsa_or_esa]
        end
        if haskey(incd, Definitions.student_loan_repayments )
            out[STUDENT_LOAN_REPAYMENTS] = incd[Definitions.student_loan_repayments]
        end
        if haskey(incd, Definitions.armed_forces_compensation_scheme )
            out[ARMED_FORCES_COMPENSATION_SCHEME] = incd[Definitions.armed_forces_compensation_scheme]
        end
        if haskey(incd, Definitions.war_widows_or_widowers_pension )
            out[WAR_WIDOWS_PENSION] = incd[Definitions.war_widows_or_widowers_pension]
        end
        if haskey(incd, Definitions.severe_disability_allowance )
            out[SEVERE_DISABILITY_ALLOWANCE] = incd[Definitions.severe_disability_allowance]
        end
        if haskey(incd, Definitions.attendance_allowance )
            out[ATTENDANCE_ALLOWANCE] = incd[Definitions.attendance_allowance]
        end
        if haskey(incd, Definitions.foster_care_payments )
            out[FOSTER_CARE_PAYMENTS] = incd[Definitions.foster_care_payments]
        end
        if haskey(incd, Definitions.maternity_grant_from_social_fund )
            out[MATERNITY_GRANT] = incd[Definitions.maternity_grant_from_social_fund]
        end
        if haskey(incd, Definitions.funeral_grant_from_social_fund )
            out[FUNERAL_GRANT] = incd[Definitions.funeral_grant_from_social_fund]
        end
        if haskey(incd, Definitions.any_other_ni_or_state_benefit )
            out[ANY_OTHER_NI_OR_STATE_BENEFIT] = incd[Definitions.any_other_ni_or_state_benefit]
        end
        if haskey(incd, Definitions.friendly_society_benefits )
            out[FRIENDLY_SOCIETY_BENEFITS] = incd[Definitions.friendly_society_benefits]
        end
        if haskey(incd, Definitions.government_training_allowances )
            out[GOVERNMENT_TRAINING_ALLOWANCES] = incd[Definitions.government_training_allowances]
        end

        #
        # 
        #

        if include_calculated 
            if haskey(incd, Definitions.income_tax )
                out[INCOME_TAX] = incd[Definitions.income_tax]
            end
            if haskey(incd, Definitions.national_insurance )
                out[NATIONAL_INSURANCE] = incd[Definitions.national_insurance]
            end
            if haskey(incd, Definitions.local_taxes )
                out[LOCAL_TAXES] = incd[Definitions.local_taxes]
            end

            if haskey(incd, Definitions.care_insurance )
                out[CARE_INSURANCE] = incd[Definitions.care_insurance]
            end
            if haskey(incd, Definitions.child_benefit )
                out[CHILD_BENEFIT] = incd[Definitions.child_benefit]
            end
            if haskey(incd, Definitions.state_pension )
                out[STATE_PENSION] = incd[Definitions.state_pension]
            end
            if haskey(incd, Definitions.bereavement_allowance_or_widowed_parents_allowance_or_bereavement )
                out[BEREAVEMENT_ALLOWANCE] = incd[Definitions.bereavement_allowance_or_widowed_parents_allowance_or_bereavement]
            end
            if haskey(incd, Definitions.carers_allowance )
                out[CARERS_ALLOWANCE] = incd[Definitions.carers_allowance]
            end
            if haskey(incd, Definitions.industrial_injury_disablement_benefit )
                out[INDUSTRIAL_INJURY_BENEFIT] = incd[Definitions.industrial_injury_disablement_benefit]
            end
            if haskey(incd, Definitions.incapacity_benefit )
                out[INCAPACITY_BENEFIT] = incd[Definitions.incapacity_benefit]
            end
            if haskey(incd, Definitions.personal_independence_payment_daily_living )
                out[PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING] = incd[Definitions.personal_independence_payment_daily_living]
            end
            if haskey(incd, Definitions.personal_independence_payment_mobility )
                out[PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY] = incd[Definitions.personal_independence_payment_mobility]
            end
            if haskey(incd, Definitions.dlaself_care )
                out[DLA_SELF_CARE] = incd[Definitions.dlaself_care]
            end
            if haskey(incd, Definitions.dlamobility )
                out[DLA_MOBILITY] = incd[Definitions.dlamobility]
            end
            if haskey(incd, Definitions.education_allowances )
                out[EDUCATION_ALLOWANCES] = incd[Definitions.education_allowances]
            end
            if haskey(incd, Definitions.maternity_allowance )
                out[MATERNITY_ALLOWANCE] = incd[Definitions.maternity_allowance]
            end
            if haskey(incd, Definitions.jobseekers_allowance )
                if pers.jsa_type == contributory_jsa
                    out[CONTRIB_JOBSEEKERS_ALLOWANCE] = incd[Definitions.jobseekers_allowance]
                elseif pers.jsa_type == income_related_jsa
                    out[NON_CONTRIB_JOBSEEKERS_ALLOWANCE] = incd[Definitions.jobseekers_allowance]
                elseif pers.jsa_type == both_jsa
                    out[NON_CONTRIB_JOBSEEKERS_ALLOWANCE] = incd[Definitions.jobseekers_allowance]/2
                    out[CONTRIB_JOBSEEKERS_ALLOWANCE] = incd[Definitions.jobseekers_allowance]/2
                else
                    @assert false "jsa is positive but jsa_type unset"
                end
            end
            if haskey(incd, Definitions.widows_payment )
                out[WIDOWS_PAYMENT] = incd[Definitions.widows_payment]
            end
            if haskey(incd, Definitions.winter_fuel_payments )
                out[WINTER_FUEL_PAYMENTS] = incd[Definitions.winter_fuel_payments]
            end
            if haskey(incd, Definitions.working_tax_credit )
                out[WORKING_TAX_CREDIT] = incd[Definitions.working_tax_credit]
            end
            if haskey(incd, Definitions.child_tax_credit )
                out[CHILD_TAX_CREDIT] = incd[Definitions.child_tax_credit]
            end
            if haskey(incd, Definitions.employment_and_support_allowance )
                if pers.esa_type == contributory_jsa
                    out[CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE] = incd[Definitions.employment_and_support_allowance]
                elseif pers.esa_type == income_related_jsa
                    out[NON_EMPLOYMENT_AND_SUPPORT_ALLOWANCE] = incd[Definitions.employment_and_support_allowance]
                elseif pers.esa_type == both_jsa
                    out[NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE] = incd[Definitions.employment_and_support_allowance]/2
                    out[CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE] = incd[Definitions.employment_and_support_allowance]/2
                else
                    @assert false "jsa is positive but jsa_type unset"
                end
            end
            if haskey(incd, Definitions.income_support )
                out[INCOME_SUPPORT] = incd[Definitions.income_support]
            end
            if haskey(incd, Definitions.pension_credit )
                out[PENSION_CREDIT] = incd[Definitions.pension_credit]
            end
            # merged with pension credit in the frs, I think
            # if haskey(incd, Definitions.savings_credit )
            #    out[SAVINGS_CREDIT] = incd[Definitions.savings_credit]
            # end
            if haskey(incd, Definitions.housing_benefit )
                out[HOUSING_BENEFIT] = incd[Definitions.housing_benefit]
            end

            if haskey(incd, Definitions.extended_hb )
                out[HOUSING_BENEFIT] += incd[Definitions.extended_hb]
            end
   
            if haskey(incd, Definitions.working_tax_credit_lump_sum )
                out[WORKING_TAX_CREDIT] += incd[Definitions.working_tax_credit_lump_sum]
            end
            if haskey(incd, Definitions.child_tax_credit_lump_sum )
                out[CHILD_TAX_CREDIT] += incd[Definitions.child_tax_credit_lump_sum]
            end

            if haskey(incd, Definitions.universal_credit )
                out[UNIVERSAL_CREDIT] = incd[Definitions.universal_credit]
            end
            if haskey(incd, Definitions.guardians_allowance )
                out[GUARDIANS_ALLOWANCE] = incd[Definitions.guardians_allowance]
            end
            # not in the income list
            # if haskey(incd, Definitions.council_tax_rebate )
            #     out[COUNCIL_TAX_REBATE] = incd[Definitions.council_tax_rebate]
            # end
        end # include calculated
        return out
    end 
end