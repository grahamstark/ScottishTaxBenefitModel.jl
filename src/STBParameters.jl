module STBParameters
    
    #
    # This module models all the parameters (tax rates, benefit levels, ages, etc.) needed to model
    # the Scottish/UK Tax and Benefit System. Also functions to convert everything to weekly amounts.
    # The default values that everything is initialised to are 2019/20 values, which shows how long I've been at this.
    # At the bottom are functions that can read other sets of parameters from files. The 20/21 and later 
    # parameters should be loaded that way rather than by changing the defaults, as the 19/20 system is used
    # heavily in the unit tests.
    #
    using Dates
    using Dates: Date, now, TimeType, Year
    using TimeSeries
    using StaticArrays
    using Parameters
    using DataFrames,CSV

    using ScottishTaxBenefitModel
    using .GeneralTaxComponents: RateBands, WEEKS_PER_YEAR, WEEKS_PER_MONTH
    using .Definitions
    using .Utils
    using .TimeSeriesUtils: fy, fy_array
    using .STBIncomes
    
    # FIXME make this ordered list
    export IncomeTaxSys, NationalInsuranceSys, TaxBenefitSystem, SavingsCredit
    export WorkingTaxCredit, SavingsCredit, IncomeRules, MinimumWage, PersonalAllowances
    export weeklyise!, annualise!, AgeLimits, HoursLimits, LegacyMeansTestedBenefitSystem
    export HousingBenefits, HousingRestrictions, Premia, ChildTaxCredit, LocalTaxes, CouncilTax
    export state_pension_age, reached_state_pension_age, load_file, load_file!
    export BRMA, loadBRMAs, DEFAULT_BRMA_2021
    export AttendanceAllowance, ChildBenefit, DisabilityLivingAllowance
    export CarersAllowance, PersonalIndependencePayment, ContributoryESA
    export WidowsPensions, BereavementSupport, RetirementPension, JobSeekersAllowance
    export NonMeansTestedSys, MaternityAllowance, ChildLimits
    export BenefitCapSys

    const MCA_DATE = Date(1935,4,6) # fixme make this a parameter

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

    @with_kw mutable struct AttendanceAllowance{RT<:Real}
        abolished :: Bool = false
        higher :: RT = 87.65
        lower :: RT = 58.70
        extra_people :: RT = 0
        candidates = Set{OneIndex}()
        slot :: Incomes = ATTENDANCE_ALLOWANCE
    end
    
    @with_kw mutable struct ChildBenefit{RT<:Real}
        abolished :: Bool = false
        first_child :: RT = 20.70
        other_children :: RT = 13.70
        high_income_thresh :: RT = 50_000.0
        withdrawal = 1/100
        guardians_allowance :: RT = 17.20
    end

    @with_kw mutable struct DisabilityLivingAllowance{RT<:Real}
        abolished :: Bool = false
        care_high :: RT = 87.65
        care_middle  :: RT = 58.70
        care_low  :: RT = 23.20
        mob_high  :: RT = 61.20
        mob_low  :: RT = 23.20
        extra_people :: RT = 0
        candidates = Set{OneIndex}()
        care_slot :: Incomes = DLA_SELF_CARE
        mob_slot :: Incomes = DLA_MOBILITY
    end

    @with_kw mutable struct CarersAllowance{RT<:Real}
        abolished :: Bool = false
        allowance :: RT = 66.15
        scottish_supplement :: RT = 231.40 # per 6 months
        hours :: Int = 35
        gainful_employment_min :: RT = 123.0
        earnings = [SELF_EMPLOYMENT_INCOME,WAGES]
        deductions = [INCOME_TAX,NATIONAL_INSURANCE]
        extra_people :: RT = 0
        candidates = Set{OneIndex}()
        slot :: Incomes = CARERS_ALLOWANCE
    end

    @with_kw mutable struct PersonalIndependencePayment{RT<:Real}
        abolished :: Bool = false
        dl_standard :: RT = 58.70
        dl_enhanced :: RT = 87.85
        mobility_standard :: RT = 23.20
        mobility_enhanced :: RT = 61.20
        extra_people :: RT = 0 # FIXME this is the same for mob/daily living
        mobility_candidates = Set{OneIndex}()        
        dl_candidates = Set{OneIndex}()        
        care_slot :: Incomes = PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING
        mob_slot :: Incomes = PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY
    end

    @with_kw mutable struct ContributoryESA{RT<:Real}
        abolished :: Bool = false
        assessment_u25 :: RT = 57.90
        assessment_25p :: RT = 73.10
        main           :: RT = 73.10
        work           :: RT = 29.05
        support        :: RT = 38.55
    end

    @with_kw mutable struct JobSeekersAllowance{RT}
        abolished :: Bool = false
        u25 :: RT = 57.90
        o24 :: RT = 73.10
    end

    #=
    @with_kw IncapacityBenefit{RT<:Real}
        upens_lower :: RT = 84.65
        upens_higher :: RT = 100.20
        upens_adult_dep :: RT = 50.80
        opens_lower :: RT = 107.65
        opens_higher :: RT = 112.25
        opens_adult_dep :: RT = 62.75

    end
    =#

    @with_kw mutable struct RetirementPension{RT}
        abolished :: Bool = false
        new_state_pension :: RT = 168.60
        # pension_start_date = Date( 2016, 04, 06 )
        cat_a     :: RT = 129.20
        cat_b     :: RT = 129.20
        cat_b_survivor :: RT = 77.45
        cat_d     :: RT = 77.45
    end

    @with_kw mutable struct BereavementSupport{RT}
        abolished :: Bool = false
        # higher effectively just means 'with children'; 
        lump_sum_higher :: RT = 3_500 # convert to weekly
        lump_sum_lower  :: RT = 2_500
        higher :: RT = 350 # monthly
        lower  :: RT = 100 # monthly 
        deaths_after = Date( 2017, 04, 06 ) # noway of using this, but, key
    end

    @with_kw mutable struct WidowsPensions{RT}
        abolished :: Bool = false
        industrial_higher :: RT = 129.20
        industrial_lower :: RT = 38.76
        standard_rate :: RT = 119.90
        parent :: RT = 119.90
        ages = collect(54:-1:45)
        age_amounts = Vector{RT}([111.51,103.11,94.72,86.33,77.94,69.54,61.15,52.76,44.36,35.97])
    end

    @with_kw mutable struct MaternityAllowance{RT}
        abolished :: Bool = false
        rate :: RT = 148.68

    end

    @with_kw mutable struct BenefitCapSys{RT<:Real}
        abolished :: Bool = false
        outside_london_single :: RT = 257.69
        outside_london_couple :: RT = 384.62
        # not really needed, but anyway ..
        inside_london_single :: RT = 296.35
        inside_london_couple  :: RT = 442.31
        uc_incomes_limit :: RT = 542.88
    end

    function weeklyise!( bc :: BenefitCapSys; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR )
        bc.uc_incomes_limit /= wpm
    end
    #
    # initial version - will be progressively replaced
    # with actual calculations based on disability, hours caring etc.
    @with_kw mutable struct NonMeansTestedSys{RT<:Real}
        attendance_allowance = AttendanceAllowance{RT}()
        child_benefit = ChildBenefit{RT}()
        dla = DisabilityLivingAllowance{RT}()
        carers = CarersAllowance{RT}()
        pip = PersonalIndependencePayment{RT}()
        esa = ContributoryESA{RT}()
        # ?? TODO, maybe incapacity = IncapacityBenefit{RT}()        
        jsa = JobSeekersAllowance{RT}()
        pensions = RetirementPension{RT}()
        bereavement = BereavementSupport{RT}()
        widows_pension = WidowsPensions{RT}()
        # young carer grant
        maternity = MaternityAllowance{RT}()
        smp :: RT = 148.68
        # not modelled SDA,Incapacity which we just wrap into
        # ESA
    end

    function weeklyise!( nmt :: NonMeansTestedSys; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR )
        nmt.bereavement.lump_sum_higher /= wpy
        nmt.bereavement.lump_sum_lower /= wpy
        nmt.bereavement.lower /= wpm
        nmt.bereavement.higher /= wpm
        nmt.carers.scottish_supplement /= (wpy/2) # kinda sorta
        nmt.child_benefit.high_income_thresh /= wpy
        # this is unintuitive, but the weekly amount of CB
        # is withdrawn by 1% of the annual excess of income,
        # and the whole model is weekly, so ...
        nmt.child_benefit.withdrawal *= wpy
    end

    @with_kw mutable struct IncomeTaxSys{RT<:Real}
        abolished :: Bool = false
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
        
        non_savings_income = NON_SAVINGS_INCOME
        all_taxable = ALL_TAXABLE_INCOME
        savings_income = SAVINGS_INCOME
        dividend_income = DIVIDEND_INCOME

        mca_date = MCA_DATE
    
    end

    function annualise!( it :: IncomeTaxSys; wpy = WEEKS_PER_YEAR, wpm=WEEKS_PER_MONTH )
        it.non_savings_rates .*= 100.0
        it.savings_rates .*= 100.0
        it.dividend_rates .*= 100.0
        it.personal_allowance_withdrawal_rate *= 100.0
        it.non_savings_thresholds .*= wpy
        it.savings_thresholds .*= wpy
        it.dividend_thresholds .*= wpy
        it.personal_allowance *= wpy
        it.blind_persons_allowance *= wpy
        it.married_couples_allowance *= wpy
        it.mca_minimum *= wpy
        it.marriage_allowance *= wpy
        it.personal_savings_allowance *= wpy
        it.pension_contrib_basic_amount *= wpy
        
        
        it.mca_income_maximum       *= wpy
        it.mca_credit_rate             *= 100.0
        it.mca_withdrawal_rate         *= 100.0
        for k in it.company_car_charge_by_CO2_emissions
            it.company_car_charge_by_CO2_emissions[k.first] *= wpy
        end
        it.pension_contrib_basic_amount *= wpy
        it.pension_contrib_annual_allowance *= wpy
        it.pension_contrib_annual_minimum *= wpy
        it.pension_contrib_threshold_income *= wpy
        it.pension_contrib_withdrawal_rate *= 100.0
    end

    function weeklyise!( it :: IncomeTaxSys; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR )
    
        it.non_savings_rates ./= 100.0
        it.savings_rates ./= 100.0
        it.dividend_rates ./= 100.0
        it.personal_allowance_withdrawal_rate /= 100.0
        it.non_savings_thresholds ./= wpy
        it.savings_thresholds ./= wpy
        it.dividend_thresholds ./= wpy
        it.personal_allowance /= wpy
        it.blind_persons_allowance /= wpy
        it.married_couples_allowance /= wpy
        it.mca_minimum /= wpy
        it.marriage_allowance /= wpy
        it.personal_savings_allowance /= wpy
        it.mca_income_maximum       /= wpy
        it.mca_credit_rate             /= 100.0
        it.mca_withdrawal_rate         /= 100.0
        for (k,v) in it.company_car_charge_by_CO2_emissions
            it.company_car_charge_by_CO2_emissions[k] /= wpy
        end
        it.pension_contrib_basic_amount /= wpy
        it.pension_contrib_annual_allowance /= wpy
        it.pension_contrib_annual_minimum /= wpy
        it.pension_contrib_threshold_income /= wpy
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
        abolished :: Bool = false
        primary_class_1_rates :: RateBands{RT} = [0.0, 0.0, 12.0, 2.0 ]
        primary_class_1_bands :: RateBands{RT} = [118.0, 166.0, 962.0, 9999999999999.9] # the '-1' here is because json can't write inf
        secondary_class_1_rates :: RateBands{RT} = [0.0, 13.8, 13.8 ] # keep 2 so
        secondary_class_1_bands :: RateBands{RT} = [166.0, 962.0, 99999999999999.9 ]
        state_pension_age :: Int = 66; # fixme move
        class_2_threshold ::RT = 6_365.0;
        class_2_rate ::RT = 3.00;
        class_4_rates :: RateBands{RT} = [0.0, 9.0, 2.0 ]
        class_4_bands :: RateBands{RT} = [8_632.0, 50_000.0, 99999999999999.9 ]
        class_1_income = IncludedItems([WAGES],[PENSION_CONTRIBUTIONS_EMPLOYER])
        class_4_income = [SELF_EMPLOYMENT_INCOME]
            ## some modelling of u21s and u25s in apprentiships here..
        # gross_to_net_lookup = BudgetConstraint(undef,0)
    end

    function weeklyise!( ni :: NationalInsuranceSys; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR )
        ni.primary_class_1_rates ./= 100.0
        ni.secondary_class_1_rates ./= 100.0
        ni.class_2_threshold /= wpy
        ni.class_4_rates ./= 100.0
        ni.class_4_bands ./= wpy
    end

    @with_kw mutable struct PersonalAllowances{ RT<:Real }
        age_18_24 :: RT = 57.90
        age_25_and_over :: RT = 73.10 # FIXME rename this allowance !! Applies to u25 ESA people too (CPAG21/22 p165)
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
        pc_child :: RT = 53.34
    end

    @with_kw mutable struct Premia{ RT<:Real }
        family :: RT = 17.45
        family_lone_parent = 22.00 # FIXME this is not used??
        disabled_child :: RT = 64.19
        carer_single :: RT = 36.85
        carer_couple :: RT = 73.70 # FIXME is this used?
        disability_single :: RT = 34.35
        disability_couple :: RT = 48.95
        enhanced_disability_child :: RT = 26.04
        enhanced_disability_single :: RT = 16.80
        enhanced_disability_couple :: RT = 24.10
        severe_disability_single :: RT = 65.85
        severe_disability_couple :: RT = 131.70
        pensioner_is :: RT = 140.40
        disability_premium_qualifying_benefits = [
            DLA_SELF_CARE,
            DLA_MOBILITY,
            PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
            PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY,
            ATTENDANCE_ALLOWANCE,
            SEVERE_DISABILITY_ALLOWANCE,
            INCAPACITY_BENEFIT,
            SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_DAILY_LIVING,
            SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_MOBILITY,
            SCOTTISH_DISABILITY_ASSISTANCE_OLDER_PEOPLE,
            SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_DAILY_LIVING,
            SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_MOBILITY ]
        enhanced_disability_premium_qualifying_benefits = [
            PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
            DLA_SELF_CARE,
            ATTENDANCE_ALLOWANCE,
            SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_DAILY_LIVING,
            SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_DAILY_LIVING,
            SCOTTISH_DISABILITY_ASSISTANCE_OLDER_PEOPLE
        ]
    end
    
    @with_kw mutable struct WorkingTaxCredit{ RT<:Real }
        ## PA
        abolished :: Bool = false
        basic :: RT = 1_960.00
        lone_parent :: RT = 2_010.00
        couple  :: RT = 2_010.00
        hours_ge_30 :: RT = 810.00
        disability :: RT = 3_165.00
        severe_disability :: RT = 1_365.00
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
    
    function weeklyise!( wtc :: WorkingTaxCredit; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR )
        wtc.basic /= wpy
        wtc.lone_parent /= wpy
        wtc.couple /= wpy
        wtc.hours_ge_30 /= wpy
        wtc.disability /= wpy
        wtc.severe_disability /= wpy
        wtc.age_50_plus /= wpy
        wtc.age_50_plus_30_hrs /= wpy
        wtc.childcare_proportion /= 100.0
        wtc.non_earnings_minima /= wpy
        wtc.threshold /= wpy
        wtc.taper /= 100.0
    end

    @with_kw mutable struct ScottishChildPayment{ RT<:Real }
        # the guidance is really ambigious about weeks/months
        # just jam on weeks
        amount :: RT = 10.0
        maximum_age :: Int = 5
        qualifying_benefits = [
            CHILD_TAX_CREDIT,
            UNIVERSAL_CREDIT,
            INCOME_SUPPORT,
            WORKING_TAX_CREDIT,
            PENSION_CREDIT,
            NON_CONTRIB_JOBSEEKERS_ALLOWANCE,
            NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE
        ]
    end
     
    @with_kw mutable struct ChildTaxCredit{ RT<:Real }
        abolished :: Bool = false
        family :: RT = 545.00
        child  :: RT = 2_780.00
        disability :: RT = 3_355.00
        severe_disability :: RT = 1_360.00    
        threshold :: RT = 16_105.00       
    end

    function weeklyise!( ctc :: ChildTaxCredit; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR )
        ctc.family /= wpy
        ctc.child /= wpy
        ctc.disability /= wpy
        ctc.severe_disability /= wpy
        ctc.threshold/= wpy
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
        incomes     = LEGACY_MT_INCOME
        hb_incomes  = LEGACY_HB_INCOME
        pc_incomes  = LEGACY_PC_INCOME
        sc_incomes  = LEGACY_SAVINGS_CREDIT_INCOME
        capital_min :: RT = 6_000.0    
        capital_max :: RT = 16_000.0
        pc_capital_min :: RT = 10_000.0
        pc_capital_max :: RT = 99999999999999.9
        pensioner_capital_min :: RT = 10_000.0
        pensioner_capital_max :: RT = 16_000.0
        
        capital_tariff :: RT = 250 # £1pw per 250 
        pensioner_tariff :: RT = 500
    end
    
    @with_kw mutable struct MinimumWage{RT<:Real}
        abolished :: Bool = false
        ages = [16,18,21,25]
        # 19/20
        wage_per_hour :: Vector{RT} = [4.35, 6.15, 7.70, 8.21]
        # 20/1 
        # wage_per_hour :: Vector{RT} = [4.55, 6.45, 8.20, 8.72]
        # apprentice_rate :: RT = 4.15;
        apprentice_rate :: RT = 3.90;
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
        abolished :: Bool = false
        band_d :: Dict{Symbol,RT} = default_band_ds(RT)
        relativities :: Dict{CT_Band,RT} = default_ct_ratios(RT)
        single_person_discount :: RT = 25.0
        # TODO see CT note on disabled discounts
    end

    @with_kw mutable struct LocalTaxes{RT<:Real}
        ct = CouncilTax{RT}()
        # other possible local taxes go here
    end
    
    function weeklyise!( lt :: LocalTaxes; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR )
        for (c,v) in lt.ct.band_d
            lt.ct.band_d[c] /= wpy
        end
        lt.ct.single_person_discount /= 100.0
    end

    @with_kw mutable struct SavingsCredit{RT<:Real}
        abolished :: Bool = false
        withdrawal_rate :: RT = 60.0
        threshold_single :: RT = 144.38 
        threshold_couple :: RT =229.67 
        max_single :: RT = 13.73 
        max_couple :: RT = 15.35 
        available_till = Date( 2016, 04, 06 )
    end
    
    function weeklyise!( sc :: SavingsCredit; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR )
        sc.withdrawal_rate /= 100.0
    end
    
     @with_kw mutable struct HousingBenefits{RT<:Real}
        abolished :: Bool = false
        taper :: RT = 65.0
        passported_bens = DEFAULT_PASSPORTED_BENS
        ndd_deductions :: RateBands{RT} =  [15.60,35.85,49.20,80.55,91.70,100.65]
        ndd_incomes :: RateBands{RT} =  [143.0,209.0,271.0,363.0,451.0,99999999999999.9]
     end

     function weeklyise!( hb :: HousingBenefits; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEARs )
        hb.taper /= 100.0
     end
 
    @with_kw mutable struct LegacyMeansTestedBenefitSystem{RT<:Real}
        # CPAG 2019/bur.pers[pid].20 p335
        abolished :: Bool = false
        ## FIXME we can't turn off pension credit individually here..
        premia :: Premia = Premia{RT}()
        allowances :: PersonalAllowances = PersonalAllowances{RT}()
        income_rules :: IncomeRules = IncomeRules{RT}()
        # FIXME why do we need a seperate copy of HoursLimits here?
        hours_limits :: HoursLimits = HoursLimits()
        savings_credit :: SavingsCredit = SavingsCredit{RT}()
        working_tax_credit = WorkingTaxCredit{RT}()
        child_tax_credit = ChildTaxCredit{RT}()
        hb = HousingBenefits{RT}()
        ctr = HousingBenefits{RT}( false, 20.0, DEFAULT_PASSPORTED_BENS, RateBands{RT}[], RateBands{RT}[])
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
            obd = BRMA( r.bname, Symbol( r.bcode ), SVector{N,T}([r.bed_1,r.bed_2,r.bed_3,r.bed_4]), T(r.room) )
            dict[ Symbol( r.bcode ) ] = obd
        end
        dict
    end

    const DEFAULT_BRMA_2021 = "$(MODEL_DATA_DIR)/local/lha_rates_scotland_2020_21.csv"
    
    @with_kw mutable struct HousingRestrictions{RT<:Real}
        abolished :: Bool = false
        # Temp till we figure this stuff out
        maximum_rooms :: Int = 4
        rooms_rent_reduction = SVector{2,RT}(14, 25)
        # FIXME!!! load this somewhere
        brmas = loadBRMAs( 4, RT, DEFAULT_BRMA_2021 )  
        single_room_age = 35 # FIXME expand
    end

    function weeklyise!( hr :: HousingRestrictions; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR )
        hr.rooms_rent_reduction /= 100.0
    end

    @with_kw mutable struct ChildLimits
        policy_start  ::  TimeType = Date( 2017, 4, 6 )
        max_children  :: Int = 2
    end

    @with_kw mutable struct UniversalCreditSys{RT<:Real}
        abolished :: Bool = false
        threshold :: RT = 2_500.0 ## NOT USED
        age_18_24 :: RT = 251.77
        age_25_and_over :: RT = 317.82

        couple_both_under_25 :: RT = 395.20
        couple_oldest_25_plus :: RT = 498.89

        first_child  :: RT = 277.08
        subsequent_child :: RT = 231.67
        disabled_child_lower :: RT = 126.11
        disabled_child_higher :: RT = 392.08
        limited_capcacity_for_work_activity:: RT = 336.20
        carer ::  RT = 160.20

        ndd :: RT = 73.89

        childcare_max_2_plus_children :: RT  = 1_108.04 # pm
        childcare_max_1_child :: RT  = 646.35
        childcare_proportion :: RT = 85.0 # pct
    
        minimum_income_floor_hours :: RT = 35*WEEKS_PER_MONTH # FIXME this jams on the DWP 4.35 weeks per month which we may not want in tests

        work_allowance_w_housing :: RT = 287.0
        work_allowance_no_housing :: RT = 503.0
        other_income = UC_OTHER_INCOME
        earned_income :: IncludedItems = UC_EARNED_INCOME
        capital_min :: RT = 6_000.0
        capital_max :: RT = 16_000.0
        # £1 *per week* ≆ 4.35 pm FIXME make 4.35 wpm? 
        capital_tariff :: RT = 250.0/4.35
        taper  :: RT= 63.0
        ctr_taper  :: RT = 20.0 # not really part of UC, I suppose, but still...
    end    

    function weeklyise!( uc :: UniversalCreditSys; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR )
        uc.threshold /= wpm
        uc.age_18_24  /= wpm
        uc.age_25_and_over  /= wpm
        uc.capital_tariff *= 4.35 # !!! wpm
        uc.couple_both_under_25  /= wpm
        uc.couple_oldest_25_plus  /= wpm
        uc.minimum_income_floor_hours /= wpm
        uc.first_child   /= wpm
        uc.subsequent_child  /= wpm
        uc.disabled_child_lower  /= wpm
        uc.disabled_child_higher  /= wpm
        uc.limited_capcacity_for_work_activity /= wpm
        uc.carer  /= wpm
        uc.ndd /= wpm
        uc.childcare_max_2_plus_children  /= wpm
        uc.childcare_max_1_child  /= wpm
        uc.childcare_proportion  /= 100.0
        uc.taper /= 100.0
        uc.ctr_taper /= 100.0
        uc.work_allowance_w_housing /= wpm
        uc.work_allowance_no_housing /= wpm
    
    end
    @with_kw mutable struct UBISys{RT}
        # numbers from "horizon 3; 2019 values"
        abolished :: Bool = true
        adult_amount :: RT = 4_800.0
        child_amount :: RT = 3_000.0
        universal_pension :: RT = 8_780.0
        adult_age :: Int = 17
        retirement_age :: Int = 66
    end

    function weeklyise!( ubi :: UBISys; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR )
        ubi.adult_amount /= wpy
        ubi.child_amount /= wpy
        ubi.universal_pension /= wpy
    end

    @with_kw mutable struct TaxBenefitSystem{RT<:Real}
        name :: String = "Scotland 2919/20"
        it   = IncomeTaxSys{RT}()
        ni   = NationalInsuranceSys{RT}()
        lmt  = LegacyMeansTestedBenefitSystem{RT}()
        uc   = UniversalCreditSys{RT}()
        scottish_child_payment = ScottishChildPayment{RT}()
        age_limits = AgeLimits()
        # just a copy of standard ft/pt hours; mt benefits may have their own copy
        hours_limits :: HoursLimits = HoursLimits() 
        child_limits :: ChildLimits = ChildLimits()
        minwage = MinimumWage{RT}()
        hr = HousingRestrictions{RT}() # fixme better name
        loctax = LocalTaxes{RT}() # fixme better name
        nmt_bens = NonMeansTestedSys{RT}()
        bencap = BenefitCapSys{RT}()
        ubi = UBISys{RT}()
    end

    
    function weeklyise!( lmt :: LegacyMeansTestedBenefitSystem; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR )
        println( "weeklyise lmt wpm = $wpm wpy=$wpy")
        weeklyise!( lmt.working_tax_credit; wpm=wpm, wpy=wpy )
        weeklyise!( lmt.child_tax_credit; wpm=wpm, wpy=wpy )
        weeklyise!( lmt.savings_credit; wpm=wpm, wpy=wpy)
        weeklyise!( lmt.hb; wpm=wpm, wpy=wpy )
        weeklyise!( lmt.ctr; wpm=wpm, wpy=wpy )
    end
   
    function weeklyise!( tb :: TaxBenefitSystem; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR )
        println( "weeklyise tb wpm = $wpm wpy=$wpy")
        
        weeklyise!( tb.it; wpm=wpm, wpy=wpy )
        weeklyise!( tb.ni; wpm=wpm, wpy=wpy )
        weeklyise!( tb.lmt; wpm=wpm, wpy=wpy )
        weeklyise!( tb.hr; wpm=wpm, wpy=wpy )
        weeklyise!( tb.loctax; wpm=wpm, wpy=wpy )
        weeklyise!( tb.nmt_bens; wpm=wpm, wpy=wpy )
        weeklyise!( tb.uc; wpm=wpm, wpy=wpy )
        weeklyise!( tb.bencap; wpm=wpm, wpy=wpy )
        weeklyise!( tb.ubi; wpm=wpm, wpy=wpy )
    end
    
   """
   Load a file `filename` and use it to create a modified version
   of the default parameter system. The file should contain
   entries like `sys.it.personal_allowance=999` but can also contain
   arbitrary code.Note: probably not thread safe: poss global variable?
   The file is executed as julia code but doesn't actually need
   a `.jl` extension.
   """
   function load_file( sysname :: AbstractString, RT :: Type = Float64 ) :: TaxBenefitSystem        
        begin
            T = RT
            sys = TaxBenefitSystem{T}()
            global sys
            global T
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
   function load_file!( psys :: TaxBenefitSystem{RT}, sysname :: AbstractString ) where RT
            begin
                # I have no idea why scoping
                # like this works ..
                T = RT
                sys = psys
                global sys
                global T
                include( sysname )
            end
   end

end # module
