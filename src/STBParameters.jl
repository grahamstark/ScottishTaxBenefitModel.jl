module STBParameters

    using Dates
    using Dates: Date, now, TimeType, Year
    using TimeSeries

    using Parameters
    using BudgetConstraints: BudgetConstraint

    using ScottishTaxBenefitModel
    using .GeneralTaxComponents: RateBands, WEEKS_PER_YEAR
    using .Definitions
    using .Utils
    using .TimeSeriesUtils: fy, fy_array
    
    using JSON3

    export IncomeTaxSys, NationalInsuranceSys, TaxBenefitSystem, SavingsCredit
    export WorkingTaxCredit, SavingsCredit, IncomeRules, MinimumWage, PersonalAllowances
    export weeklyise!, annualise!, AgeLimits, HoursLimits, LegacyMeansTestedBenefitSystem
    export HousingBenefits, LocalHousingAllowance, Premia, ChildTaxCredit
    export state_pension_age, reached_state_pension_age, load, load!

    const MCA_DATE = Date(1935,4,6) # fixme make this a parameter

    function SAVINGS_INCOME( t :: Type ) :: Incomes_Dict
        Incomes_Dict{t}(
            bank_interest => one(t),
            bonds_and_gilts => one(t),
            other_investment_income => one(t) )
    end
  
    """
    TODO check this carefully against WTC,PC and IS chapters
    note this doesn't include wages and TaxBenefitSystem
    which are handled in the `calc_incomes` function.   
    poss. have 2nd complete version for WTC/CTC
    """
    function LEGACY_MT_INCOME( t :: Type ):: Incomes_Dict
        # wages and SE treated seperately
        Incomes_Dict{t}(
            other_income=> one( t ),
            carers_allowance=>one( t ),
            alimony_and_child_support_received=> one( t ), # FIXME there is a 15 disregard see pp 438
            alimony_and_child_support_paid=> 0.0,
            student_loan_repayments=> -one( t ),
            education_allowances=> one( t ),
            foster_care_payments=> one( t ),
            # it and NI dealt with in wage seperately
            state_pension=> one( t ),
            private_pensions => one( t ),
            bereavement_allowance_or_widowed_parents_allowance_or_bereavement=> 0.0,
            war_widows_or_widowers_pension=> one( t ),
            jobseekers_allowance=> one( t ), ## contribution based
            industrial_injury_disablement_benefit=> one( t ),
            incapacity_benefit=> one( t ),
            maternity_allowance=> one( t ),
            maternity_grant_from_social_fund=> one( t ),
            funeral_grant_from_social_fund=> one( t ),
            any_other_ni_or_state_benefit=> one( t ),
            trade_union_sick_or_strike_pay=> one( t ),
            friendly_society_benefits=> one( t ),
            working_tax_credit => one( t ),
            private_sickness_scheme_benefits=> one( t ),
            accident_insurance_scheme_benefits=> one( t ),
            hospital_savings_scheme_benefits=> one( t ),
            government_training_allowances=> one( t ),
            guardians_allowance=> one( t ),
            widows_payment=> one( t ),
            unemployment_or_redundancy_insurance=> one( t ),
            winter_fuel_payments=> one( t ),
            dwp_third_party_payments_is_or_pc=> one( t ),
            dwp_third_party_payments_jsa_or_esa=> one( t ),
            extended_hb=> one( t ) # what is this?
        )
    end

    #
    # add the other old MT bens to HB incomes
    #
    function LEGACY_HB_INCOME(t::Type)::Incomes_Dict
        inc = LEGACY_MT_INCOME(t)
        # since these are passported this should only
        # ever matter if we have a 'passporting' switch
        # and it's turned off, but anyway ....
        inc[income_support] = one( t )
        inc[jobseekers_allowance] = one( t )
        inc[employment_and_support_allowance] = one( t )
        inc[child_tax_credit] = one( t )
        return inc
    end

    ### NOT USED
    function LEGACY_PC_INCOME(t::Type)::Incomes_Dict
        inc = LEGACY_MT_INCOME(t)
        inc[income_support] = one( t )
        inc[jobseekers_allowance] = one( t )
        inc[employment_and_support_allowance] = one( t )
        delete!(inc, working_tax_credit )
        return inc
    end
    
    function LEGACY_SAVINGS_CREDIT_INCOME( t::Type )::Incomes_Dict
        inc = LEGACY_PC_INCOME(t)
        for todel in [
            working_tax_credit, 
            incapacity_benefit,
            employment_and_support_allowance, # contributory only
            jobseekers_allowance, # cont only
            # severe_disablement_allowance,
            maternity_allowance,
            alimony_and_child_support_received ]
            delete!( inc, todel )
        end
        return inc
    end

    function DIVIDEND_INCOME( t :: Type ) :: Incomes_Dict
        Incomes_Dict{t}(
             stocks_shares => one(t))
    end

    function Exempt_Income( t :: Type ) :: Incomes_Dict
        Incomes_Dict{t}(
            carers_allowance=>one( t ),
            jobseekers_allowance =>one( t ),
            free_school_meals => one( t ),
            dlaself_care => one( t ),
            dlamobility => one( t ),
            child_benefit => one( t ),
            pension_credit => one( t ),
            bereavement_allowance_or_widowed_parents_allowance_or_bereavement=> one( t ),
            armed_forces_compensation_scheme => one( t ), # FIXME not in my list check this
            war_widows_or_widowers_pension => one( t ),
            severe_disability_allowance => one( t ),
            attendence_allowance => one( t ),
            industrial_injury_disablement_benefit => one( t ),
            employment_and_support_allowance => one( t ),
            incapacity_benefit => one( t ),## taxable after 29 weeks,
            income_support => one( t ),
            maternity_allowance => one( t ),
            maternity_grant_from_social_fund => one( t ),
            funeral_grant_from_social_fund => one( t ),
            guardians_allowance => one( t ),
            winter_fuel_payments => one( t ),
            dwp_third_party_payments_is_or_pc => one( t ),
            dwp_third_party_payments_jsa_or_esa => one( t ),
            extended_hb => one( t ),
            working_tax_credit => one( t ),
            child_tax_credit => one( t ),
            working_tax_credit_lump_sum => one( t ),
            child_tax_credit_lump_sum => one( t ),
            housing_benefit => one( t ),
            universal_credit => one( t ),
            personal_independence_payment_daily_living => one( t ),
            personal_independence_payment_mobility => 1.0 )
    end

    function make_all_taxable(t::Type)::Incomes_Dict
        eis = union(Set( keys( Exempt_Income(t) )), Definitions.Expenses )
        all_t = Incomes_Dict{t}()
        for i in instances(Incomes_Type)
            if ! (i ∈ eis )
                all_t[i]=one(t)
            end
        end
        all_t
    end

    function make_non_savings( t :: Type )::Incomes_Dict where T
        excl = union(Set(keys(DIVIDEND_INCOME(t))), Set( keys(SAVINGS_INCOME(t))))
        nsi = make_all_taxable(t)
        for i in excl
            delete!( nsi, i )
        end
        nsi
    end

    ## TODO Use Unitful to have currency weekly monthly annual counts as annotations
    # using Unitful

    function Default_Fuel_Dict_2020_21(t::Type):: Fuel_Type_Dict
        Fuel_Type_Dict{t}(
            Missing_Fuel_Type=>0.1,
            No_Fuel=>0.1,
            Other=>0.1,
            Dont_know=>0.1,
            Petrol=>0.25, # dunno
            Diesel=>0.37,
            Hybrid_use_a_combination_of_petrol_and_electricity=>0.16,
            Electric=>0.02,
            LPG=>0.02,
            Biofuel_eg_E85_fuel=>0.02 )
    end

    @with_kw mutable struct IncomeTaxSys{RT<:Real}
        non_savings_rates :: RateBands{RT} =  [19.0,20.0,21.0,41.0,46.0]
        non_savings_thresholds :: RateBands{RT} =  [2_049.0, 12_444.0, 30_930.0, 150_000.0]
        non_savings_basic_rate :: Int = 2 # above this counts as higher rate
        
        savings_rates  :: RateBands{RT} =  [0.0, 20.0, 40.0, 45.0]
        savings_thresholds  :: RateBands{RT} =  [5_000.0, 37_500.0, 150_000.0]
        savings_basic_rate :: Int = 2 # above this counts as higher rate
        
        dividend_rates :: RateBands{RT} =  [0.0, 7.5,32.5,38.1]
        dividend_thresholds :: RateBands{RT} =  [2_000.0, 37_500.0, 150_000.0]
        dividend_basic_rate :: Int = 2 # above this counts as higher rate
        
        personal_allowance :: RT          = 12_500.00
        personal_allowance_income_limit :: RT = 100_000.00
        personal_allowance_withdrawal_rate  :: RT= 50.0
        blind_persons_allowance    :: RT  = 2_450.00
        
        married_couples_allowance   :: RT = 8_915.00
        mca_minimum                 :: RT = 3_450.00
        mca_income_maximum          :: RT = 29_600.00
        mca_credit_rate             :: RT = 10.0
        mca_withdrawal_rate         :: RT= 50.0
        
        marriage_allowance          :: RT = 1_250.00
        personal_savings_allowance  :: RT = 1_000.00
        
        # FIXME better to have it straight from
        # the book with charges per CO2 range
        # and the data being an estimate of CO2 per type
        company_car_charge_by_CO2_emissions :: Fuel_Type_Dict{RT} = Default_Fuel_Dict_2020_21(RT)
        fuel_imputation  :: RT = 24_100.00
        
        #
        # pensions
        #
        pension_contrib_basic_amount :: RT = 3_600.00
        pension_contrib_annual_allowance :: RT = 40_000.00
        pension_contrib_annual_minimum :: RT = 10_000.00
        pension_contrib_threshold_income :: RT = 150_000.00
        pension_contrib_withdrawal_rate :: RT = 50.0
        
        non_savings_income :: Incomes_Dict{RT} = make_non_savings(RT)
        all_taxable :: Incomes_Dict{RT} = make_all_taxable(RT)
        savings_income :: Incomes_Dict{RT} = SAVINGS_INCOME(RT)
        dividend_income :: Incomes_Dict{RT} = DIVIDEND_INCOME(RT)
        mca_date = MCA_DATE
    
    end

    function annualise!( it :: IncomeTaxSys )
        it.non_savings_rates .*= 100.0
        it.savings_rates .*= 100.0
        it.dividend_rates .*= 100.0
        it.personal_allowance_withdrawal_rate *= 100.0
        it.non_savings_thresholds .*= WEEKS_PER_YEAR
        it.savings_thresholds .*= WEEKS_PER_YEAR
        it.dividend_thresholds .*= WEEKS_PER_YEAR
        it.personal_allowance *= WEEKS_PER_YEAR
        it.blind_persons_allowance *= WEEKS_PER_YEAR
        it.married_couples_allowance *= WEEKS_PER_YEAR
        it.mca_minimum *= WEEKS_PER_YEAR
        it.marriage_allowance *= WEEKS_PER_YEAR
        it.personal_savings_allowance *= WEEKS_PER_YEAR
        it.pension_contrib_basic_amount *= WEEKS_PER_YEAR
        
        
        it.mca_income_maximum       *= WEEKS_PER_YEAR
        it.mca_credit_rate             *= 100.0
        it.mca_withdrawal_rate         *= 100.0
        for k in it.company_car_charge_by_CO2_emissions
            it.company_car_charge_by_CO2_emissions[k.first] *= WEEKS_PER_YEAR
        end
        it.pension_contrib_basic_amount *= WEEKS_PER_YEAR
        it.pension_contrib_annual_allowance *= WEEKS_PER_YEAR
        it.pension_contrib_annual_minimum *= WEEKS_PER_YEAR
        it.pension_contrib_threshold_income *= WEEKS_PER_YEAR
        it.pension_contrib_withdrawal_rate *= 100.0
    end

    function weeklyise!( it :: IncomeTaxSys )
    
        it.non_savings_rates ./= 100.0
        it.savings_rates ./= 100.0
        it.dividend_rates ./= 100.0
        it.personal_allowance_withdrawal_rate /= 100.0
        it.non_savings_thresholds ./= WEEKS_PER_YEAR
        it.savings_thresholds ./= WEEKS_PER_YEAR
        it.dividend_thresholds ./= WEEKS_PER_YEAR
        it.personal_allowance /= WEEKS_PER_YEAR
        it.blind_persons_allowance /= WEEKS_PER_YEAR
        it.married_couples_allowance /= WEEKS_PER_YEAR
        it.mca_minimum /= WEEKS_PER_YEAR
        it.marriage_allowance /= WEEKS_PER_YEAR
        it.personal_savings_allowance /= WEEKS_PER_YEAR
        it.mca_income_maximum       /= WEEKS_PER_YEAR
        it.mca_credit_rate             /= 100.0
        it.mca_withdrawal_rate         /= 100.0
        for k in it.company_car_charge_by_CO2_emissions
            it.company_car_charge_by_CO2_emissions[k.first] /= WEEKS_PER_YEAR
        end
        it.pension_contrib_basic_amount /= WEEKS_PER_YEAR
        it.pension_contrib_annual_allowance /= WEEKS_PER_YEAR
        it.pension_contrib_annual_minimum /= WEEKS_PER_YEAR
        it.pension_contrib_threshold_income /= WEEKS_PER_YEAR
        it.pension_contrib_withdrawal_rate /= 100.0
    end

    """
    Note this is *very* approximate as the pension 
    age actually increases monthly; see https://en.wikipedia.org/wiki/State_Pension_(United_Kingdom)
    """
    function pension_ages()::TimeArray
        n = 2050-2010+1
        dates = Vector{Date}(undef,n)
        males=zeros(Int,n)
        females=zeros(Int,n)
        i = 0
        #
        # we could actually just use this if-else as the function lookup,
        # except we might want to parameterise this. Note if we do and have different m/f ages we have
        # to change the ModelHousehold count-by-age functions.
        #
        for y in 2010:1:2050
            i += 1
            dates[i] = Date( y, 04, 06 )
            if y < 2012
                males[i] = 65
                females[i] = 60
            elseif y < 2014
                males[i] = 65
                females[i] = 61
            elseif y < 2016
                males[i] = 65
                females[i] = 62
            elseif y < 2018
                males[i] = 65
                females[i] = 63
            elseif y < 2020
                males[i] = 65
                females[i] = 64
            elseif y < 2022
                males[i] = 65
                females[i] = 65
            elseif y < 2024
                males[i] = 66
                females[i] = 66
            elseif y < 2046
                males[i] = 67
                females[i] = 67
            else
                males[i] = 68
                females[i] = 68
            end
        end # loop
        data=(dates=dates,females=females,males=males)
        ts = TimeArray(data,timestamp=:dates)
        ts
    end
    
    @with_kw mutable struct AgeLimits
        state_pension_ages = pension_ages(); # fixme can't serialise using json3
        savings_credit_to_new_state_pension :: Date = Date( 2016, 04, 06 )
    end
    
    function state_pension_age( limits :: AgeLimits, sex :: Sex, when :: Integer )::Integer
        y = fy( when )
        # temp temp fixme
        limits.state_pension_ages = pension_ages()
        n = size( limits.state_pension_ages )[1]
        if y < timestamp( limits.state_pension_ages[1] )
            py = sex == Male ? limits.state_pension_ages[1].males : limits.state_pension_ages[1].females
        elseif y > timestamp( limits.state_pension_ages[n] )
            py = sex == Male ? limits.state_pension_ages[n].males : limits.state_pension_ages[n].females
        else
            py = sex == Male ? limits.state_pension_ages[y].males : limits.state_pension_ages[y].females
        end
        return values(py)[1]
    end
    
    function state_pension_age( limits :: AgeLimits, sex :: Sex, when :: DateTime = now() )::Integer
        return state_pension_age( limits, sex, Dates.year( when ))
    end
    
    function reached_state_pension_age(
        limits :: AgeLimits,
        age  :: Int,
        sex  :: Sex,
        when :: Integer ) :: Bool
    
        return Utils.age_then( age, when ) >= state_pension_age( limits, sex, when )
    end
    
    function reached_state_pension_age(
        limits :: AgeLimits,
        age  :: Int,
        sex  :: Sex,
        when :: DateTime = now()) :: Bool
        return reached_state_pension_age( limits, age, sex, Dates.year( when ))
    end
    
    function reached_state_pension_age(
        limits :: AgeLimits,
        age  :: Int,
        sex  :: Sex,
        when :: Date ) :: Bool
        return reached_state_pension_age( limits, age, sex, Dates.year( when ))
    end
    
    @with_kw mutable struct NationalInsuranceSys{RT<:Real}
        primary_class_1_rates :: RateBands{RT} = [0.0, 0.0, 12.0, 2.0 ]
        primary_class_1_bands :: RateBands{RT} = [118.0, 166.0, 962.0, 9999999999999.9] # the '-1' here is because json can't write inf
        secondary_class_1_rates :: RateBands{RT} = [0.0, 13.8, 13.8 ] # keep 2 so
        secondary_class_1_bands :: RateBands{RT} = [166.0, 962.0, 99999999999999.9 ]
        state_pension_age :: Int = 66; # fixme move
        class_2_threshold ::RT = 6_365.0;
        class_2_rate ::RT = 3.00;
        class_4_rates :: RateBands{RT} = [0.0, 9.0, 2.0 ]
        class_4_bands :: RateBands{RT} = [8_632.0, 50_000.0, 99999999999999.9 ]
        class_1_income = Incomes_Dict{RT}(
         wages => 1.0,
         pension_contributions_employer => -1.0 )
        class_4_income = Incomes_Dict{RT}( 
         self_employment_income => 1.0 )      
        ## some modelling of u21s and u25s in apprentiships here..
        # gross_to_net_lookup = BudgetConstraint(undef,0)
    end

    function weeklyise!( ni :: NationalInsuranceSys )
        ni.primary_class_1_rates ./= 100.0
        ni.secondary_class_1_rates ./= 100.0
        ni.class_2_threshold /= WEEKS_PER_YEAR
        ni.class_4_rates ./= 100.0
        ni.class_4_bands ./= WEEKS_PER_YEAR
    end

    @with_kw mutable struct PersonalAllowances{ RT<:Real }
        age_18_24 :: RT = 57.90
        age_25_and_over :: RT = 73.10
        age_18_and_in_work_activity :: RT = 73.10
        over_pension_age :: RT = 181.00
        lone_parent :: RT = 73.10
        lone_parent_over_pension_age :: RT = 181.00
        couple_both_under_18 :: RT = 87.50 # this isn't quite right; see cpag p336
        couple_both_over_18 :: RT = 114.85
        couple_over_pension_age :: RT = 270.60
        couple_one_over_18_high :: RT = 114.85
        couple_one_over_18_med :: RT = 173.10
        pa_couple_one_over_18_low :: RT = 57.90
        child :: RT = 66.90
        pc_mig_single :: RT = 167.25
        pc_mig_couple :: RT = 255.25
    end

    @with_kw mutable struct Premia{ RT<:Real }
        family :: RT = 17.45
        disabled_child :: RT = 64.19
        severe_disability_single :: RT = 65.85
        severe_disability_couple :: RT = 131.70
        carer_single :: RT = 36.85
        carer_couple :: RT = 73.70
        enhanced_disability_child :: RT = 26.04
        enhanced_disability_single :: RT = 16.80
        enhanced_disability_couple :: RT = 24.10
        disability_single :: RT = 34.35
        disability_couple :: RT = 48.95
        pensioner_is :: RT = 140.40
    end
    
    @with_kw mutable struct WorkingTaxCredit{ RT<:Real }
        ## PA
        basic :: RT = 1_920.00
        lone_parent :: RT = 1_950.00
        couple  :: RT = 1_950.00
        hours_ge_30 :: RT = 790.00
        disability :: RT = 2_650.00
        severe_disability :: RT = 1_130.00
        age_50_plus  :: RT = 1_365.00 # discontinued 2012 - not modelled
        age_50_plus_30_hrs :: RT = 2_030.00 # discontinued - not modelled
        childcare_max_2_plus_children :: RT  = 300.0 # pw
        childcare_max_1_child :: RT  = 175.0
        childcare_proportion :: RT = 70.0 # pct
        taper :: RT = 41.0
        threshold :: RT = 6_420.0
        non_earnings_minima :: RT = 300.0
        # incomes :: Incomes_Dict = make_all_taxable( RT )  
    end
    
    function weeklyise!( wtc :: WorkingTaxCredit )
        wtc.basic /= WEEKS_PER_YEAR
        wtc.lone_parent /= WEEKS_PER_YEAR
        wtc.couple /= WEEKS_PER_YEAR
        wtc.hours_ge_30 /= WEEKS_PER_YEAR
        wtc.disability /= WEEKS_PER_YEAR
        wtc.severe_disability /= WEEKS_PER_YEAR
        wtc.age_50_plus /= WEEKS_PER_YEAR
        wtc.age_50_plus_30_hrs /= WEEKS_PER_YEAR
        wtc.childcare_proportion /= 100.0
        wtc.non_earnings_minima /= WEEKS_PER_YEAR
        wtc.threshold /= WEEKS_PER_YEAR
        wtc.taper /= 100.0
    end
     
    @with_kw mutable struct ChildTaxCredit{ RT<:Real }
        family :: RT = 545.00
        child  :: RT = 2_555.00
        disability :: RT = 2_800.00
        severe_disability :: RT = 1_130.00    
        disregard :: RT = 16_105.00
    end

    function weeklyise!( ctc :: ChildTaxCredit )
        ctc.family /= WEEKS_PER_YEAR
        ctc.child /= WEEKS_PER_YEAR
        ctc.disability /= WEEKS_PER_YEAR
        ctc.severe_disability /= WEEKS_PER_YEAR
        ctc.disregard/= WEEKS_PER_YEAR
    end
    
    
    @with_kw mutable struct HoursLimits
        lower :: Int = 16
        med   :: Int = 24
        higher :: Int = 30
    end
   
    @with_kw mutable struct IncomeRules{RT<:Real}
        permitted_work :: RT= 131.50
        lone_parent_hb :: RT = 25.00
        high :: RT = 20.0
        low_couple :: RT = 10.0
        low_single :: RT = 5.0       
        hb_additional :: RT = 17.10
        childcare_max_1 :: RT = 175.00
        childcare_max_2 :: RT = 300.00
        incomes :: Incomes_Dict = LEGACY_MT_INCOME(RT)
        hb_incomes :: Incomes_Dict = LEGACY_HB_INCOME(RT)  
        pc_incomes :: Incomes_Dict = LEGACY_PC_INCOME(RT)  
        sc_incomes :: Incomes_Dict = LEGACY_SAVINGS_CREDIT_INCOME(RT)
        capital_min :: RT = 6_000.0    
        capital_max :: RT = 16_000.0
        pc_capital_min :: RT = 10_000.0
        pc_capital_max :: RT = 99999999999999.9
        pensioner_capital_min :: RT = 10_000.0
        pensioner_capital_max :: RT = 16_000.0
        
        capital_tariff :: RT = 250 # £1pw per 250 
    end
    
    @with_kw mutable struct MinimumWage{RT<:Real}
        ages = [16,18,21,25]
        wage_per_hour :: Vector{RT} = [4.55, 6.45, 8.20, 8.72]
        apprentice_rate :: RT = 4.15;
    end
    
    function get_minimum_wage( mwsys :: MinimumWage, age :: Int ):: Real
        p = 0
        if age < mwsys.ages[1]
            return zero(eltype( mwsys.wage_per_hour))
        end
        for r in mwsys.ages
            p += 1
            if age <= r
                break
            end
        end
        return mwsys.wage_per_hour[p]
    end
    
    @with_kw mutable struct SavingsCredit{RT<:Real}
        withdrawal_rate :: RT = 60.0
        threshold_single :: RT = 144.38 
        threshold_couple :: RT =229.67 
        max_single :: RT = 13.73 
        max_couple :: RT = 15.35 
        available_till = Date( 2016, 04, 06 )
    end
    
    function weeklyise!( sc :: SavingsCredit )
        sc.withdrawal_rate /= 100.0
    end
    
    const DEFAULT_PASSPORTED_BENS = Incomes_Set(
            [ income_support, 
              employment_and_support_allowance, 
              jobseekers_allowance,
              pension_credit] ) # fixme contrib jsa, only guaranteed pension credit

     
    @with_kw mutable struct HousingBenefits{RT<:Real}
        taper :: RT = 65.0
        passported_bens = DEFAULT_PASSPORTED_BENS
        ndd_deductions :: RateBands{RT} =  [15.60,35.85,49.20,80.55,91.70,100.65]
        ndd_incomes :: RateBands{RT} =  [143.0,209.0,271.0,363.0,451.0,99999999999999.9]
     end

     function weeklyise!( hb :: HousingBenefits )
        hb.taper /= 100.0
     end
 
    @with_kw mutable struct LegacyMeansTestedBenefitSystem{RT<:Real}
        # CPAG 2019/bur.pers[pid].20 p335
        premia :: Premia = Premia{RT}()
        allowances :: PersonalAllowances = PersonalAllowances{RT}()
        income_rules :: IncomeRules = IncomeRules{RT}()
        hours_limits :: HoursLimits = HoursLimits()
        savings_credit :: SavingsCredit = SavingsCredit{RT}()
        working_tax_credit = WorkingTaxCredit{RT}()
        child_tax_credit = ChildTaxCredit{RT}()
        hb = HousingBenefits{RT}()
        ctb = HousingBenefits{RT}( 20.0, DEFAULT_PASSPORTED_BENS, RateBands{RT}[], RateBands{RT}[])
    end
    
    
    @with_kw mutable struct LocalHousingAllowance{RT<:Real}
        # Temp till we figure this stuff out
        tmp_lha_prop :: RT = 1.0
    end
   
    @with_kw mutable struct TaxBenefitSystem{RT<:Real}
        name :: String = "Scotland 2919/20"
        it   = IncomeTaxSys{RT}()
        ni   = NationalInsuranceSys{RT}()
        lmt  = LegacyMeansTestedBenefitSystem{RT}()
        age_limits = AgeLimits()
        minwage = MinimumWage{RT}()
        lha = LocalHousingAllowance{RT}()
    end
   
    function weeklyise!( lmt :: LegacyMeansTestedBenefitSystem )
        weeklyise!( lmt.working_tax_credit )
        weeklyise!( lmt.child_tax_credit )
        weeklyise!( lmt.savings_credit )
        weeklyise!( lmt.hb )
        weeklyise!( lmt.ctb )
    end
   
    function weeklyise!( tb :: TaxBenefitSystem )
        weeklyise!( tb.it )
        weeklyise!( tb.ni )
        weeklyise!( tb.lmt )
    end
    
   """
   load a file from `params/` directory. The file should contain
   entries like `sys.it.personal_allowance=999` but can also contain
   arbitrary code
   """
   function load( sysname :: AbstractString = "") :: TaxBenefitSystem
        sys = TaxBenefitSystem{Float64}()
        if sysname != ""
            begin
                global sys
                include( "params/$(sysname).jl" )
            end
        end
        return sys
    end

    function load!( sys :: TaxBenefitSystem, sysname :: AbstractString = "" )
        if sysname != ""
            begin
                global sys
                include( "params/$(sysname).jl" )
            end
        end
    end

end # module