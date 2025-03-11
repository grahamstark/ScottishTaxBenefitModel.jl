
module STBIncomes

    import Base.getindex 
    import Base.sum
    using ArgCheck
    using DataStructures
    
        # declarations  ----------------
    @enum Incomes begin
        WAGES 
        SELF_EMPLOYMENT_INCOME 
        ODD_JOBS 
        PRIVATE_PENSIONS 
        NATIONAL_SAVINGS 
        BANK_INTEREST 
        STOCKS_SHARES 
        INDIVIDUAL_SAVINGS_ACCOUNT 
        PROPERTY 
        ROYALTIES 
        BONDS_AND_GILTS 
        OTHER_INVESTMENT_INCOME 
        OTHER_INCOME 
        ALIMONY_AND_CHILD_SUPPORT_RECEIVED 
        PRIVATE_SICKNESS_SCHEME_BENEFITS 
        ACCIDENT_INSURANCE_SCHEME_BENEFITS 
        HOSPITAL_SAVINGS_SCHEME_BENEFITS 
        UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE 
        PERMANENT_HEALTH_INSURANCE 
        ANY_OTHER_SICKNESS_INSURANCE 
        CRITICAL_ILLNESS_COVER 
        TRADE_UNION_SICK_OR_STRIKE_PAY 

        HEALTH_INSURANCE 
        ALIMONY_AND_CHILD_SUPPORT_PAID 
        TRADE_UNIONS_ETC 
        FRIENDLY_SOCIETIES 
        WORK_EXPENSES 
        AVCS 
        OTHER_DEDUCTIONS 
        LOAN_REPAYMENTS 
        PENSION_CONTRIBUTIONS_EMPLOYEE 
        PENSION_CONTRIBUTIONS_EMPLOYER 

        INCOME_TAX 
        NATIONAL_INSURANCE 
        LOCAL_TAXES 
        SOCIAL_FUND_LOAN_REPAYMENT 
        STUDENT_LOAN_REPAYMENTS 
        CARE_INSURANCE 

        CHILD_BENEFIT 
        STATE_PENSION 
        BEREAVEMENT_ALLOWANCE 
        ARMED_FORCES_COMPENSATION_SCHEME 
        WAR_WIDOWS_PENSION 
        SEVERE_DISABILITY_ALLOWANCE 
        ATTENDANCE_ALLOWANCE 
        CARERS_ALLOWANCE 
        INDUSTRIAL_INJURY_BENEFIT 
        INCAPACITY_BENEFIT 
        PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING 
        PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY 
        DLA_SELF_CARE 
        DLA_MOBILITY 
        EDUCATION_ALLOWANCES 
        FOSTER_CARE_PAYMENTS 
        MATERNITY_ALLOWANCE 
        MATERNITY_GRANT 
        FUNERAL_GRANT 
        ANY_OTHER_NI_OR_STATE_BENEFIT 
        FRIENDLY_SOCIETY_BENEFITS 
        GOVERNMENT_TRAINING_ALLOWANCES 
        CONTRIB_JOBSEEKERS_ALLOWANCE 
        GUARDIANS_ALLOWANCE 
        WIDOWS_PAYMENT 
        WINTER_FUEL_PAYMENTS 
        # legacy mt benefits
        WORKING_TAX_CREDIT 
        CHILD_TAX_CREDIT 
        NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE 
        INCOME_SUPPORT 
        PENSION_CREDIT 
        SAVINGS_CREDIT 
        NON_CONTRIB_JOBSEEKERS_ALLOWANCE 
        HOUSING_BENEFIT 
        
        FREE_SCHOOL_MEALS 
        UNIVERSAL_CREDIT 
        OTHER_BENEFITS 
        STUDENT_GRANTS 
        STUDENT_LOANS 
        COUNCIL_TAX_BENEFIT 
        CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE 

        SCOTTISH_CHILD_PAYMENT
        SCOTTISH_CARERS_SUPPLEMENT

        DISCRESIONARY_HOUSING_PAYMENT # not just Scottish, but, hey..
        CHILD_DISABILITY_PAYMENT_CARE
        CHILD_DISABILITY_PAYMENT_MOBILITY
        PENSION_AGE_DISABILITY
        ADP_DAILY_LIVING
        ADP_MOBILITY

        BASIC_INCOME

        OTHER_TAX
    end

    FirstInc = WAGES
    LastInc = OTHER_TAX

    const IncomesDict = OrderedDict{Incomes}
    const IncomesSet = OrderedSet{Incomes}

    function Base.getindex( i :: IncomesDict{T}, k :: Incomes ) :: T where T <: Number
        return get(i,k,zero(T))
    end

    function times( i :: IncomesDict{T}, s :: IncomesDict{T} )::T where T <: Number
        v = zero(T)         
        t = intersect( keys(s), keys(i))
        for k in T
            v += i[k]*s[k]
        end
        v
    end

    function Base.sum( i :: IncomesDict{T}, which ) :: T where T <: Number
        @argcheck eltype(which) == Incomes
        v = zero(T)         
        t = intersect( which, keys(i))
        for k in t
            v += i[k]
        end
        v
    end
    

    function range( from :: Incomes, to :: Incomes ) :: IncomesSet
        s = IncomesSet()
        for k in instances(Incomes)
            if k >= from 
                push!(s,k)
                if k == to
                    break
                end
            end
        end
        s
    end

    function fill!( i :: IncomesDict{T}, v :: T, which :: IncomesSet  ) where T <: Number
        for k in which
            i[k] = v
        end        
    end

    function fill!( i :: IncomesDict{T}, v :: T ; from = FirstInc, to = LastInc ) where T <: Number
        @argcheck typeof(to) == Incomes
        @argcheck typeof(from) == Incomes
        range = range( from, to )
        fill!( i, range )
    end

    function filli( v :: T; from :: Incomes = FirstInc, to :: Incomes = LastInc)::IncomesDict{T} where T
        @argcheck typeof(to) == Incomes
        @argcheck typeof(from) == Incomes
        d = IncomesDict{T}()
        r = range( from, to )
        fill!( d, v, r )
        d
    end

    function onesi( T :: Type; from :: Incomes = FirstInc, to :: Incomes = LastInc ) :: IncomesDict
        d = IncomesDict{T}()
        o = one(T)
        return filli( o; from=from, to=to )
    end

    function zerosi( T :: Type; from :: Incomes = FirstInc, to :: Incomes = LastInc ) :: IncomesDict
        d = IncomesDict{T}()
        o = zero(T)
        return filli( o; from=from, to=to )
    end


end