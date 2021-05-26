module STBParameters

    using Dates
    using Dates: Date, now, TimeType, Year
    using TimeSeries
    using StaticArrays
    using Parameters
    using BudgetConstraints: BudgetConstraint
    using DataFrames,CSV

    using ScottishTaxBenefitModel
    using .GeneralTaxComponents: RateBands, WEEKS_PER_YEAR
    using .Definitions
    using .Utils
    using .TimeSeriesUtils: fy, fy_array
    using .Incomes
    
    export IncomeTaxSys, NationalInsuranceSys, TaxBenefitSystem, SavingsCredit
    export WorkingTaxCredit, SavingsCredit, IncomeRules, MinimumWage, PersonalAllowances
    export weeklyise!, annualise!, AgeLimits, HoursLimits, LegacyMeansTestedBenefitSystem
    export HousingBenefits, HousingRestrictions, Premia, ChildTaxCredit, LocalTaxes, CouncilTax
    export state_pension_age, reached_state_pension_age, load_file, load_file!
    export BRMA, loadBRMAs, DEFAULT_BRMA_2021

    const MCA_DATE = Date(1935,4,6) # fixme make this a parameter

    function SAVINGS_INCOME( t :: Type ) :: Incomes_Dict
        Incomes_Dict{t}(
            bank_interest => one(t),
            bonds_and_gilts => one(t),
            other_investment_income => one(t) )
    end
  
    function SAVINGS_INCOME( t :: Type ) :: SVector
        return make_static_incs( T, ones=[BANK_INTEREST, BONDS_AND_GILTS, OTHER_INVESTMENT_INCOME])
    end

    function LEGACY_MT_INCOME( t :: Type )::SVector
        # wages and SE treated seperately
        return make_static_incs( T,
            ones = [ 
                OTHER_INCOME,
                CARERS_ALLOWANCE,
                ALIMONY_AND_CHILD_SUPPORT_RECEIVED, # FIXME THERE IS A 15 DISREGARD SEE PP 438
                EDUCATION_ALLOWANCES,
                FOSTER_CARE_PAYMENTS,
                STATE_PENSION,
                PRIVATE_PENSIONS,
                BEREAVEMENT_ALLOWANCE,
                WAR_WIDOWS_PENSION,
                CONTRIBURY_JOBSEEKERS_ALLOWANCE, ## CONTRIBUTION BASED
                INDUSTRIAL_INJURY_DISABLEMENT_BENEFIT,
                INCAPACITY_BENEFIT,
                MATERNITY_ALLOWANCE,
                MATERNITY_GRANT_FROM_SOCIAL_FUND,
                FUNERAL_GRANT_FROM_SOCIAL_FUND,
                ANY_OTHER_NI_OR_STATE_BENEFIT,
                TRADE_UNION_SICK_OR_STRIKE_PAY,
                FRIENDLY_SOCIETY_BENEFITS,
                WORKING_TAX_CREDIT ,
                PRIVATE_SICKNESS_SCHEME_BENEFITS,
                ACCIDENT_INSURANCE_SCHEME_BENEFITS,
                HOSPITAL_SAVINGS_SCHEME_BENEFITS,
                GOVERNMENT_TRAINING_ALLOWANCES,
                GUARDIANS_ALLOWANCE,
                WIDOWS_PAYMENT,
                UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE,
                WINTER_FUEL_PAYMENTS,
                DWP_THIRD_PARTY_PAYMENTS_IS_OR_PC,
                DWP_THIRD_PARTY_PAYMENTS_JSA_OR_ESA ],
            minusones = [
                STUDENT_LOAN_REPAYMENTS,
                ALIMONY_AND_CHILD_SUPPORT_PAID ]
            )

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

    function GROSS_INCOME( t :: Type ) :: Incomes_Dict
        Incomes_Dict{t}(
            wages => one( t ),
            self_employment_income => one( t ),
            self_employment_expenses => one( t ),
            self_employment_losses => one( t ),
            odd_jobs => one( t ),
            private_pensions => one( t ),
            national_savings => one( t ),
            bank_interest => one( t ),
            stocks_shares => one( t ),
            individual_savings_account => one( t ),
            property => one( t ),
            royalties => one( t ),
            bonds_and_gilts => one( t ),
            other_investment_income => one( t ),
            other_income => one( t ),
            alimony_and_child_support_received => one( t ),
            health_insurance => -one( t ),
            alimony_and_child_support_paid => -one( t ),
            care_insurance => -one( t ),
            trade_unions_etc => -one( t ),
            friendly_societies => one( t ),
            work_expenses => -one( t ),
            avcs => -one( t ),
            other_deductions => -one( t ),
            loan_repayments => -one( t ),
            student_loan_repayments => -one( t ),
            pension_contributions_employee => one( t ),
            pension_contributions_employer => one( t ),
            education_allowances => one( t ),
            foster_care_payments => one( t ),
            student_grants => one( t ),
            student_loans => one( t )
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
        for (k,v) in it.company_car_charge_by_CO2_emissions
            it.company_car_charge_by_CO2_emissions[k] /= WEEKS_PER_YEAR
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
    
    
    function default_band_ds( RT :: Type ) :: Dict
        return Dict{Symbol,RT}(
            :S12000033  =>  1_377.30,
            :S12000034  =>  1_300.81,
            :S12000041  =>  1_206.54,
            :S12000035  =>  1_367.73,
            :S12000036  =>  1_338.59,
            :S12000005  =>  1_304.63,
            :S12000006  =>  1_222.63,
            :S12000042  =>  1_379.00,
            :S12000008  =>  1_375.35,
            :S12000045  =>  1_308.98,
            :S12000010  =>  1_302.62,
            :S12000011  =>  1_289.96,
            :S12000014  =>  1_225.58,
            :S12000047  =>  1_280.80,
            :S12000049  =>  1_386.00,
            :S12000017  =>  1_332.33,
            :S12000018  =>  1_331.84,
            :S12000019  =>  1_409.00,
            :S12000020  =>  1_322.87,
            :S12000013  =>  1_193.49,
            :S12000021  =>  1_342.69,
            :S12000050  =>  1_221.25,
            :S12000023  =>  1_208.48,
            :S12000048  =>  1_318.00,
            :S12000038  =>  1_315.42,
            :S12000026  =>  1_253.91,
            :S12000027  =>  1_206.33,
            :S12000028  =>  1_344.96,
            :S12000029  =>  1_203.00,
            :S12000030  =>  1_344.28,
            :S12000039  =>  1_293.55,
            :S12000040  =>  1_276.42 )
    end
     
    function default_ct_ratios(RT)
        return Dict{CT_Band,RT}(
            Band_A=>240/360,
            Band_B=>280/360,
            Band_C=>320/360,
            Band_D=>360/360,
            Band_E=>473/360,
            Band_F=>585/360,                                                                      
            Band_G=>705/360,
            Band_H=>882/360,
            Band_I=>-1, # wales only
            Household_not_valued_separately => 0.0 ) # see CT note
    end
    
    @with_kw mutable struct CouncilTax{RT<:Real}
        band_d :: Dict{Symbol,RT} = default_band_ds(RT)
        relativities :: Dict{CT_Band,RT} = default_ct_ratios(RT)
        single_person_discount :: RT = 25.0
        # TODO see CT note on disabled discounts
    end

    @with_kw mutable struct LocalTaxes{RT<:Real}
        ct = CouncilTax{RT}()
        # other possible local taxes go here
    end
    
    function weeklyise!( lt :: LocalTaxes )
        for (c,v) in lt.ct.band_d
            lt.ct.band_d[c] /= WEEKS_PER_YEAR
        end
        lt.ct.single_person_discount /= 100.0
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
    
    struct BRMA{N,T}
        name :: String 
        code :: Symbol
        bedrooms :: SVector{N,T}
        room :: T
    end

    function loadBRMAs( N :: Int, T :: Type, file :: String  ) :: Dict{Symbol,BRMA{N,T}}
        bd = CSV.File( file ) |> DataFrame
        # FIXME infer N from bd
        dict = Dict{ Symbol, BRMA{ N, T }}() 
        for r in eachrow( bd )
            obd = BRMA( r.bname, Symbol( r.bcode ), SVector{N,T}([r.bed_1,r.bed_2,r.bed_3,r.bed_4]),r.room )
            dict[ Symbol( r.bcode ) ] = obd
        end
        dict
    end

    const DEFAULT_BRMA_2021 = "$(MODEL_DATA_DIR)/local/lha_rates_scotland_2020_21.csv"
    
    @with_kw mutable struct HousingRestrictions{RT<:Real}
        # Temp till we figure this stuff out
        maximum_rooms :: Int = 4
        rooms_rent_reduction = SVector{2,RT}(14, 25)
        # FIXME!!! load this somewhere
        brmas = loadBRMAs( 4, RT, DEFAULT_BRMA_2021 )  
        single_room_age = 35 # FIXME expand
    end

    function weeklyise!( hr :: HousingRestrictions )
        hr. rooms_rent_reduction /= 100.0
    end

    @with_kw mutable struct TaxBenefitSystem{RT<:Real}
        name :: String = "Scotland 2919/20"
        it   = IncomeTaxSys{RT}()
        ni   = NationalInsuranceSys{RT}()
        lmt  = LegacyMeansTestedBenefitSystem{RT}()
        age_limits = AgeLimits()
        # just a copy of standard ft/pt hours; mt benefits may have their own copy
        hours_limits :: HoursLimits = HoursLimits() 
        minwage = MinimumWage{RT}()
        hr = HousingRestrictions{RT}() # fixme better name
        loctax = LocalTaxes{RT}() # fixme better name
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
        weeklyise!( tb.hr )
        weeklyise!( tb.loctax )
    end
    
   """
   Load a file `filename` and use it to create a modified version
   of the default parameter system. The file should contain
   entries like `sys.it.personal_allowance=999` but can also contain
   arbitrary code.Note: probably not thread safe: poss global variable?
   The file is executed as julia code but doesn't actually need
   a `.jl` extension.
   """
   function load_file( sysname :: AbstractString, T :: Type = Float64 ) :: TaxBenefitSystem
        sys = TaxBenefitSystem{T}()
        begin
            global sys
            include( sysname )
        end
        return sys
   end
   

   """
   Load a file `filename` and use it to modify the given parameter system. The file should contain
   entries like `sys.it.personal_allowance=999` but can also contain
   arbitrary code.Note: probably not thread safe: poss global variable?
   The file is executed as julia code but doesn't actually need
   a `.jl` extension.
   """
   function load_file!( sys :: TaxBenefitSystem, sysname :: AbstractString )
            begin
                global sys
                include( sysname )
            end
   end

end # module
