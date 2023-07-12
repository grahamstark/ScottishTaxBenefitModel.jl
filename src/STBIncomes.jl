module STBIncomes
#
# This module implements a list of incomes, roughly based on FRS incomes,
# implemented with constants and
# fixed length arrays. It's used by the calculation and results modules for
# fast computation. In the household module, incomes are modelled as a Dictionary.
# [Results.jl] has a routine to map between the two.
#
# TODO Investigate Named Arrays
#

# using Base: String
using ArgCheck
using StaticArrays
using DataFrames
using ScottishTaxBenefitModel
using .RunSettings: Settings
using .Utils
     
    # declarations  ----------------
@exported_enum Incomes begin
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
 
    SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_DAILY_LIVING
    SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_MOBILITY
    SCOTTISH_DISABILITY_ASSISTANCE_OLDER_PEOPLE
    SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_DAILY_LIVING
    SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_MOBILITY

    BASIC_INCOME

    OTHER_TAX
end

const IncomesSet = Set{Incomes}

const FIRST_INCOME = instances(Incomes)[1]
const LAST_INCOME = instances(Incomes)[end-1] # skip OTHER_TAX
const NUM_INCOMES = length(instances(Incomes))[1]

export IncomesSet
# FIXME the export_enum macro should take care of these ..
export WAGES 
export SELF_EMPLOYMENT_INCOME 
export ODD_JOBS 
export PRIVATE_PENSIONS 
export NATIONAL_SAVINGS 
export BANK_INTEREST 
export STOCKS_SHARES 
export INDIVIDUAL_SAVINGS_ACCOUNT 
export PROPERTY 
export ROYALTIES 
export BONDS_AND_GILTS 
export OTHER_INVESTMENT_INCOME 
export OTHER_INCOME 
export ALIMONY_AND_CHILD_SUPPORT_RECEIVED 
export PRIVATE_SICKNESS_SCHEME_BENEFITS 
export ACCIDENT_INSURANCE_SCHEME_BENEFITS 
export HOSPITAL_SAVINGS_SCHEME_BENEFITS 
export UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE 
export PERMANENT_HEALTH_INSURANCE 
export ANY_OTHER_SICKNESS_INSURANCE 
export CRITICAL_ILLNESS_COVER 
export TRADE_UNION_SICK_OR_STRIKE_PAY 
export HEALTH_INSURANCE 
export ALIMONY_AND_CHILD_SUPPORT_PAID 
export TRADE_UNIONS_ETC 
export FRIENDLY_SOCIETIES 
export WORK_EXPENSES 
export AVCS 
export OTHER_DEDUCTIONS 
export LOAN_REPAYMENTS 
export PENSION_CONTRIBUTIONS_EMPLOYEE 
export PENSION_CONTRIBUTIONS_EMPLOYER 
export INCOME_TAX 
export NATIONAL_INSURANCE 
export LOCAL_TAXES 
export SOCIAL_FUND_LOAN_REPAYMENT 
export STUDENT_LOAN_REPAYMENTS 
export CARE_INSURANCE 
export CHILD_BENEFIT 
export STATE_PENSION 
export BEREAVEMENT_ALLOWANCE 
export ARMED_FORCES_COMPENSATION_SCHEME 
export WAR_WIDOWS_PENSION 
export SEVERE_DISABILITY_ALLOWANCE 
export ATTENDANCE_ALLOWANCE 
export CARERS_ALLOWANCE 
export INDUSTRIAL_INJURY_BENEFIT 
export INCAPACITY_BENEFIT 
export PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING 
export PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY 
export DLA_SELF_CARE 
export DLA_MOBILITY 
export EDUCATION_ALLOWANCES 
export FOSTER_CARE_PAYMENTS 
export MATERNITY_ALLOWANCE 
export MATERNITY_GRANT 
export FUNERAL_GRANT 
export ANY_OTHER_NI_OR_STATE_BENEFIT 
export FRIENDLY_SOCIETY_BENEFITS 
export GOVERNMENT_TRAINING_ALLOWANCES 
export CONTRIB_JOBSEEKERS_ALLOWANCE 
export GUARDIANS_ALLOWANCE 
export WIDOWS_PAYMENT 
export WINTER_FUEL_PAYMENTS 
# legacy mt benefits
export WORKING_TAX_CREDIT 
export CHILD_TAX_CREDIT 
export NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE 
export INCOME_SUPPORT 
export PENSION_CREDIT 
export SAVINGS_CREDIT 
export NON_CONTRIB_JOBSEEKERS_ALLOWANCE 
export HOUSING_BENEFIT 

export FREE_SCHOOL_MEALS 
export UNIVERSAL_CREDIT 
export OTHER_BENEFITS 
export STUDENT_GRANTS 
export STUDENT_LOANS 
export COUNCIL_TAX_BENEFIT 
export CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE 
export SCOTTISH_CHILD_PAYMENT
export SCOTTISH_CARERS_SUPPLEMENT
export BASIC_INCOME
export DISCRESIONARY_HOUSING_PAYMENT
export SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_DAILY_LIVING
export SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_MOBILITY
export SCOTTISH_DISABILITY_ASSISTANCE_OLDER_PEOPLE
export SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_DAILY_LIVING
export SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_MOBILITY
export OTHER_TAX


function sz(thing)::Int
    t = 0
    for i in instances(thing)
      t += 1
     end
     t
end


const INC_ARRAY_SIZE = sz(Incomes)
const IncomesArray = MVector{INC_ARRAY_SIZE,T} where T

Base.getindex( X::IncomesArray, s::Incomes ) = getindex(X,Int(s)+1) # enums without explicit numbers start at 0...
Base.setindex!( X::IncomesArray, x, s::Incomes) = setindex!(X,x,Int(s)+1)

function fill( starti::Incomes, stopi :: Incomes) :: IncomesSet
    is = IncomesSet()
    for i in Int(starti):Int(stopi)
        push!(is, Incomes(i))
    end
    return is
end

function make_income_taxes() :: IncomesSet
    is = IncomesSet()
    for i in Int(INCOME_TAX):Int(NATIONAL_INSURANCE)
        if i != Int(LOCAL_TAXES)
            push!( is, Incomes(i))
        end
    end
    push!( is, OTHER_TAX )
    return is
    # IncomesSet(setdiff(fill(INCOME_TAX,NATIONAL_INSURANCE),[LOCAL_TAXES]) ) # CT treated seperately
end

const NON_CALCULATED_INCOMES = fill( WAGES, TRADE_UNION_SICK_OR_STRIKE_PAY )
const NON_CALCULATED_ITEMS = fill( WAGES, PENSION_CONTRIBUTIONS_EMPLOYER )
const BENEFITS = fill(CHILD_BENEFIT, LAST_INCOME ) # careful!
const LEGACY_MTBS =fill(WORKING_TAX_CREDIT,HOUSING_BENEFIT)

const MEANS_TESTED_BENS = union(fill(WORKING_TAX_CREDIT,UNIVERSAL_CREDIT), [SCOTTISH_CHILD_PAYMENT,COUNCIL_TAX_BENEFIT] )
const NON_MEANS_TESTED_BENS = IncomesSet(setdiff( BENEFITS, MEANS_TESTED_BENS ))
const INCOME_TAXES = make_income_taxes()

const CALCULATED = fill(INCOME_TAX,SCOTTISH_CARERS_SUPPLEMENT)
const SCOTTISH_SICKNESS_BENEFITS = IncomesSet([
        SCOTTISH_CARERS_SUPPLEMENT,
        SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_DAILY_LIVING, 
        SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_MOBILITY ])
const UK_SICKNESS_ILLNESS = fill(SEVERE_DISABILITY_ALLOWANCE,DLA_MOBILITY)
const SICKNESS_ILLNESS = union(UK_SICKNESS_ILLNESS, SCOTTISH_SICKNESS_BENEFITS )
const DEDUCTIONS = fill(HEALTH_INSURANCE,PENSION_CONTRIBUTIONS_EMPLOYEE) # not employer since wages are net of this
const SCOTTISH_BENEFITS = union( 
    SCOTTISH_SICKNESS_BENEFITS,
    [SCOTTISH_CHILD_PAYMENT] ) # FIXME plus ...


const PASSED_THROUGH_BENEFITS = IncomesSet([
        ARMED_FORCES_COMPENSATION_SCHEME,
        WAR_WIDOWS_PENSION,
        SEVERE_DISABILITY_ALLOWANCE,
        INDUSTRIAL_INJURY_BENEFIT,
        INCAPACITY_BENEFIT,
        EDUCATION_ALLOWANCES,
        FOSTER_CARE_PAYMENTS,
        MATERNITY_GRANT,
        FUNERAL_GRANT,
        ANY_OTHER_NI_OR_STATE_BENEFIT,
        GUARDIANS_ALLOWANCE,
        FREE_SCHOOL_MEALS,
        OTHER_BENEFITS,
        STUDENT_GRANTS,
        STUDENT_LOANS ])
const ALL_INCOMES = union( NON_CALCULATED_INCOMES, BENEFITS )
const ALL_INCOMES_EXCEPT_HOUSING_BENEFITS = IncomesSet(setdiff(ALL_INCOMES,[COUNCIL_TAX_BENEFIT,HOUSING_BENEFIT]))

const DIRECT_TAXES_AND_DEDUCTIONS = union(INCOME_TAXES,DEDUCTIONS)


# exports ----------------
export GROSS_INCOME
export BENEFITS
export LEGACY_MTBS
export MEANS_TESTED_BENS
export NON_MEANS_TESTED_BENS
export INCOME_TAXES
export CALCULATED
export DEDUCTIONS 
export DIRECT_TAXES_AND_DEDUCTIONS
export SICKNESS_ILLNESS
export INC_ARRAY_SIZE
export ALL_INCOMES
export ALL_INCOMES_EXCEPT_HOUSING_BENEFITS
export PASSED_THROUGH_BENEFITS
export SCOTTISH_BENEFITS
export SCOTTISH_SICKNESS_BENEFITS
export NET_COST

export iname
export make_static_incs
export make_mutable_incs
export IncludedItems
export isum
export any_positive
export set2syms

struct IncludedItems
    included :: IncomesSet
    deducted :: Union{Nothing,IncomesSet}  
end

function IncludedItems( included :: Vector, deducted :: Vector )
    # println( "matched here")
    IncludedItems( IncomesSet( included), IncomesSet( deducted ))
end

function IncludedItems( included :: Set, deducted :: Vector )
    # println( "matched here 2")
    IncludedItems( IncomesSet( included), IncomesSet( deducted ))
end

const NET_COST = IncludedItems(    
    BENEFITS, [INCOME_TAX,NATIONAL_INSURANCE,LOCAL_TAXES,OTHER_TAX] )

function make_a( T :: Type ) :: IncomesArray
    return IncomesArray{T}( zeros(T, INC_ARRAY_SIZE))
end

function isum( a :: IncomesArray{T}, 
    included :: IncomesSet; 
    deducted :: Union{IncomesSet,Nothing} = nothing ) :: T where T
    s = zero(T)
    for i in included
        s += a[i]
    end
    if ! isnothing(deducted)
        for i in deducted
            s -= a[i]
        end
    end
    return s
end

function i2sym( i :: Incomes ) :: Symbol
    return Symbol(lowercase( string(i)))
end

function set2syms(s :: IncomesSet ) :: Set{Symbol}
    ss = Set{Symbol}()
    for i in s 
        push!(ss,i2sym(i))
    end
    return ss
end

function isum( a :: AbstractArray, 
    which :: IncludedItems )
    return isum( a, which.included, deducted=which.deducted)
end

function any_positive( a :: AbstractArray, 
    which ) :: Bool
    for i in which
        if a[i] > 0
            return true
        end
    end
    return false
end

function make_static_incs( 
    T         :: Type; 
    ones, 
    minusones ) :: IncomesArray
    v = IncomesArray{T}(zeros(T,INC_ARRAY_SIZE))
    for i in ones
        v[i] = one(T)
    end
    for i in minusones
        v[i] = -one(T)
    end
    return IncomesArray(v)
end

function iname(i::Incomes)::String
    return pretty(i)
end

# FIXME what if we din't export these ones, deleted '_INCOME' and instead forced Incomes.SAVINGS ...
export LEGACY_MT_INCOME
export GROSS_INCOME
export LEGACY_HB_INCOME
export LEGACY_PC_INCOME
export LEGACY_SAVINGS_CREDIT_INCOME
export DIVIDEND_INCOME
export EXEMPT_INCOME
export ALL_TAXABLE_INCOME
export NON_SAVINGS_INCOME
export SAVINGS_INCOME
export DEFAULT_PASSPORTED_BENS
export UC_OTHER_INCOME
export UC_EARNED_INCOME 

const SAVINGS_INCOME = IncomesSet([BANK_INTEREST, BONDS_AND_GILTS,OTHER_INVESTMENT_INCOME])

""" 
TODO check this carefully against WTC,PC and IS chapters
note this doesn't include wages and TaxBenefitSystem
which are handled in the `calc_incomes` function.   
poss. have 2nd complete version for WTC/CTC
"""
const UC_EARNED_INCOME = IncludedItems(
    [   
        WAGES
        # se treated seperately
    ],
    [
        INCOME_TAX,
        NATIONAL_INSURANCE,
        PENSION_CONTRIBUTIONS_EMPLOYEE # !! NOTE THIS IS NOT GROSSED UP, see: CPAG 118
        ## ? student loan repayments?
    ]
)

export 
    LEGACY_CAP_BENEFITS,
    UC_CAP_BENEFITS 

const COMMON_CAP_BENEFITS = IncomesSet([
    CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
    CONTRIB_JOBSEEKERS_ALLOWANCE,
    WIDOWS_PAYMENT,
    MATERNITY_ALLOWANCE,
    INCAPACITY_BENEFIT,
    CHILD_BENEFIT,
    SEVERE_DISABILITY_ALLOWANCE
])

const UC_CAP_BENEFITS = IncomesSet(union([UNIVERSAL_CREDIT], COMMON_CAP_BENEFITS ))

const LEGACY_CAP_BENEFITS = IncomesSet(union(
    [HOUSING_BENEFIT,
        CHILD_TAX_CREDIT,
        NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
        NON_CONTRIB_JOBSEEKERS_ALLOWANCE,
        INCOME_SUPPORT], 
        COMMON_CAP_BENEFITS
))

# FIXME check these lists again very carefully indeed.
# FIXME the CPAG guide describes a very convoluted way
# of calculating, which requires 2 lists of earned and unearned income
# I think that's important just for 
const UC_OTHER_INCOME = IncomesSet([   
        # WAGES,
        # SELF_EMPLOYMENT_INCOME, # counts, but see minimum level of earnings regs 19/20 p119
        OTHER_INCOME,
        CARERS_ALLOWANCE,
        ALIMONY_AND_CHILD_SUPPORT_RECEIVED, # FIXME THERE IS A 15 DISREGARD SEE PP 438
        EDUCATION_ALLOWANCES,
        FOSTER_CARE_PAYMENTS,
        STATE_PENSION,
        PRIVATE_PENSIONS,
        BEREAVEMENT_ALLOWANCE,
        WAR_WIDOWS_PENSION,
        CONTRIB_JOBSEEKERS_ALLOWANCE, ## CONTRIBUTION BASED Only
        CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
        INDUSTRIAL_INJURY_BENEFIT,
        INCAPACITY_BENEFIT,
        MATERNITY_ALLOWANCE,
        MATERNITY_GRANT,
        FUNERAL_GRANT,
        ANY_OTHER_NI_OR_STATE_BENEFIT,
        TRADE_UNION_SICK_OR_STRIKE_PAY,
        FRIENDLY_SOCIETY_BENEFITS,
        # WORKING_TAX_CREDIT,
        PRIVATE_SICKNESS_SCHEME_BENEFITS,
        ACCIDENT_INSURANCE_SCHEME_BENEFITS,
        HOSPITAL_SAVINGS_SCHEME_BENEFITS,
        GOVERNMENT_TRAINING_ALLOWANCES,
        GUARDIANS_ALLOWANCE,
        WIDOWS_PAYMENT,
        UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE ])
## FIXME CHECK THIS list
## NOTE wages, se are treated seperately
const LEGACY_MT_INCOME = IncludedItems(
    [
        OTHER_INCOME,
        CARERS_ALLOWANCE,
        ALIMONY_AND_CHILD_SUPPORT_RECEIVED, # FIXME THERE IS A 15 DISREGARD SEE PP 438
        EDUCATION_ALLOWANCES,
        FOSTER_CARE_PAYMENTS,
        STATE_PENSION,
        PRIVATE_PENSIONS,
        BEREAVEMENT_ALLOWANCE,
        WAR_WIDOWS_PENSION,
        CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
        CONTRIB_JOBSEEKERS_ALLOWANCE, ## CONTRIBUTION BASED Only
        INDUSTRIAL_INJURY_BENEFIT,
        INCAPACITY_BENEFIT,
        MATERNITY_ALLOWANCE,
        MATERNITY_GRANT,
        FUNERAL_GRANT,
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
        UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE 
    ],
    [
        STUDENT_LOAN_REPAYMENTS,
        ALIMONY_AND_CHILD_SUPPORT_PAID
    ]
)

const GROSS_INCOME = IncludedItems(
    [
        WAGES,
        SELF_EMPLOYMENT_INCOME,
        ODD_JOBS,
        PRIVATE_PENSIONS,
        NATIONAL_SAVINGS,
        BANK_INTEREST,
        STOCKS_SHARES,
        INDIVIDUAL_SAVINGS_ACCOUNT,
        PROPERTY,
        ROYALTIES,
        BONDS_AND_GILTS,
        OTHER_INVESTMENT_INCOME,
        OTHER_INCOME,
        ALIMONY_AND_CHILD_SUPPORT_RECEIVED,
        PRIVATE_SICKNESS_SCHEME_BENEFITS,
        ACCIDENT_INSURANCE_SCHEME_BENEFITS,
        HOSPITAL_SAVINGS_SCHEME_BENEFITS,
        UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE,
        PERMANENT_HEALTH_INSURANCE,
        ANY_OTHER_SICKNESS_INSURANCE,
        CRITICAL_ILLNESS_COVER,
        TRADE_UNION_SICK_OR_STRIKE_PAY
    ],
    [
        HEALTH_INSURANCE,
        ALIMONY_AND_CHILD_SUPPORT_PAID,
        TRADE_UNIONS_ETC,
        FRIENDLY_SOCIETIES,
        WORK_EXPENSES,
        AVCS,
        OTHER_DEDUCTIONS,
        LOAN_REPAYMENTS,
        PENSION_CONTRIBUTIONS_EMPLOYEE,
        PENSION_CONTRIBUTIONS_EMPLOYER
    ]
)

const LEGACY_HB_INCOME = union( LEGACY_MT_INCOME.included, 
    # since these are passported this should only
    # ever matter if we have a 'passporting' switch
    # and it's turned off, but anyway ....       
    [
    INCOME_SUPPORT,
    CONTRIB_JOBSEEKERS_ALLOWANCE,
    NON_CONTRIB_JOBSEEKERS_ALLOWANCE,
    NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
    CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
    CHILD_TAX_CREDIT ] )

const LEGACY_PC_INCOME = IncomesSet(setdiff(LEGACY_MT_INCOME.included, [WORKING_TAX_CREDIT] ))

const LEGACY_SAVINGS_CREDIT_INCOME = IncomesSet(setdiff( LEGACY_MT_INCOME.included,
    [ WORKING_TAX_CREDIT,
    INCAPACITY_BENEFIT,
    CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
    # TODO CHECK BOTH?
    CONTRIB_JOBSEEKERS_ALLOWANCE,
    MATERNITY_ALLOWANCE,
    ALIMONY_AND_CHILD_SUPPORT_RECEIVED ]))

const DIVIDEND_INCOME = IncomesSet([ STOCKS_SHARES ])

const EXEMPT_INCOME = IncomesSet([
    CARERS_ALLOWANCE,
    FREE_SCHOOL_MEALS,
    DLA_SELF_CARE,
    DLA_MOBILITY,
    CHILD_BENEFIT,
    PENSION_CREDIT,
    BEREAVEMENT_ALLOWANCE,
    ARMED_FORCES_COMPENSATION_SCHEME,
    WAR_WIDOWS_PENSION,
    SEVERE_DISABILITY_ALLOWANCE,
    ATTENDANCE_ALLOWANCE,
    INDUSTRIAL_INJURY_BENEFIT,
    CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
    INCAPACITY_BENEFIT,
    INCOME_SUPPORT,
    MATERNITY_ALLOWANCE,
    MATERNITY_GRANT,
    FUNERAL_GRANT,
    GUARDIANS_ALLOWANCE,
    WINTER_FUEL_PAYMENTS,
    WORKING_TAX_CREDIT,
    CHILD_TAX_CREDIT,
    HOUSING_BENEFIT,
    PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
    PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY,
    # ...
    SCOTTISH_CARERS_SUPPLEMENT,
    SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_DAILY_LIVING,
    SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_MOBILITY,
    SCOTTISH_DISABILITY_ASSISTANCE_OLDER_PEOPLE,
    SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_DAILY_LIVING,
    SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_MOBILITY
])

const ALL_TAXABLE_INCOME = IncomesSet(setdiff( ALL_INCOMES, EXEMPT_INCOME ))
const NON_SAVINGS_INCOME = IncomesSet(setdiff( ALL_TAXABLE_INCOME, DIVIDEND_INCOME, SAVINGS_INCOME ))

const DEFAULT_PASSPORTED_BENS = IncomesSet([
        INCOME_SUPPORT,
        NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE,
        NON_CONTRIB_JOBSEEKERS_ALLOWANCE,
        PENSION_CREDIT ])

export inctostr, isettostr, non_zeros, two_incs_to_frame

"""
For printing: return a df with anything non-zero in either frame.
"""
function two_incs_to_frame(
    pre  :: AbstractVector,
    post :: AbstractVector ) :: DataFrame
    incs = []
    pres = []
    posts = []
    for i in instances(Incomes)
        if pre[i] != 0 || post[i] != 0
            push!(incs, i)
            push!(pres, pre[i])
            push!(posts, post[i])
        end
    end
    df = DataFrame( :Inc=>incs, :Before => pres, :After => posts)
    return df
end

"""
Make a markdown table with non-zero incomes.
"""
function inctostr( incs :: AbstractVector; round_inc :: Bool = true) :: String
    s = 
    """
    
    
    |            |              |
    |:-----------|-------------:|
    """        
    for i in instances(Incomes)
        if incs[i] != 0
            m = round_inc ? md_format(incs[i]) : "$(incs[i])"
            s *= "|**$(iname(i))**|$m|
            "
        end
    end
    s *= "
    
    "
    return s
end

function non_zeros( incs :: AbstractVector ) :: Vector{Tuple}
    v = []
    for i in instances(Incomes)
        if incs[i] != 0
            push!(v, (iname(i), incs[i]))
        end
    end
    return v
end

function isettostr( iset )
    s = ""
    for i in iset
        s *= "$(iname(i))\n"
    end
    return s
end

# FIXME move all exports close to the module top
export 
    create_incomes_dataframe,
    fill_inc_frame_row!


function create_incomes_dataframe( RT :: DataType, n :: Int ) :: DataFrame
    d = DataFrame(
    pid  = zeros( BigInt, n ),
    hid = zeros( BigInt, n ),
    weight = zeros( RT, n ) )
    # buno = zeros( Int, n ),
    for i in instances(Incomes)
        lab = i2sym(i)
        d[!,lab] = zeros(RT,n)
    end
    return d
end

function fill_inc_frame_row!( 
        incd :: DataFrameRow, 
        pid :: BigInt,
        hid :: BigInt,
        weight :: Real, 
        income :: IncomesArray )
    @argcheck size( income )[1] == INC_ARRAY_SIZE
    incd.pid = pid
    incd.hid = hid
    incd.weight = weight
    
    for i in instances(Incomes)
        lab = i2sym(i)
        incd[lab] = income[i]
    end

    

end # add_to_inc_frame

end # module