module Intermediate

#
#   This module provides some intial calculations for things like numbers and
#   ages of children, number of carers and so on, for benefit units and households. 
#   It is intended to simplify subsequent modelling of benefits, etc.. 
#   and to reduce the number of repeated calculations. It also holds code for some age and
#   child count calculations that are also used stand-alone elsewhere.
# 
#   FIXME some of the names should be globally changed.
#

using Base: Bool, String
using Dates: TimeType, Date, now, Year

using ScottishTaxBenefitModel
using .Definitions

using .ModelHousehold: 
    BenefitUnit,
    Household, 
    Person,    
    between_ages, 
    count, 
    default_bu_allocation, 
    empl_status_in, 
    ge_age, 
    get_benefit_units,
    get_head,
    has_carer_member, 
    has_children, 
    has_disabled_member, 
    has_income,
    is_lone_parent, 
    is_severe_disability,
    is_single, 
    le_age, 
    num_adults, 
    num_carers, 
    num_people,
    pers_is_carer, 
    pers_is_disabled, 
    search
    
using .STBParameters: 
    AgeLimits, 
    HoursLimits, 
    ChildLimits,
    reached_state_pension_age 
  
using .Utils: 
    has_non_z,
    haskeys, 
    mult,
    to_md_table

using .STBIncomes

using .RunSettings: Settings

export 
    MTIntermediate,     
    apply_2_child_policy,
    born_before, 
    has_limited_capactity_for_work_activity,
    has_limited_capactity_for_work, 
    is_working_hours, 
    make_intermediate, 
    make_recipient,
    num_born_before, 
    to_string,
    working_disabled,
    HHIntermed

"""
examples: 

2 children born before start_date, 1 after
 => allowable = 2
3  children born before start_date, 1 after
 => allowable = 3
1  children born before start_date, 2 after
 => allowable = 2
0  children born before start_date, 2 after
 => allowable = 2
 @return number of children allowed
"""
function apply_2_child_policy(
    bu      :: BenefitUnit,
    limits  :: ChildLimits
    ; 
    model_run_date :: TimeType = now() ) :: Integer
    before_children = 0
    after_children = 0
    for pid in bu.children
        ch = bu.people[pid]
        if born_before( ch.age, limits.policy_start, model_run_date )
            before_children += 1
        else
            after_children += 1
        end          
    end
    allowable = before_children + min( max(limits.max_children-before_children,0), after_children )
end

function born_before( age :: Integer,
    start_date     :: TimeType = Date( 2017, 4, 6 ), # 6th April 2017
    model_run_date :: TimeType = now() )
    bdate = model_run_date - Year(age)
    return bdate < start_date   
end

"""
Very loose implementation of CPAG 2020/1 ch 45 
"""
function has_limited_capactity_for_work( pers :: Person ) :: Bool
    # based on cpag 2020/1 ch45 pp 1100-
    l =  pers.employment_status in
        [   Retired,
            Permanently_sick_or_disabled,
            Temporarily_sick_or_injured,
            Other_Inactive] &&  # FIXME - retired/temp sick/looking after family ??        
        pers_is_disabled( pers )
    l = l || (pers.esa_type != no_jsa)
    return l
end

"""
Very loose implementation of CPAG 2020/1 ch 45. Until we have
something better, maybe regression-based.
`Work Activity` here means attending interviews, assessments and the like.
"""
function has_limited_capactity_for_work_activity( pers :: Person ) :: Bool
    l = false
    if has_limited_capactity_for_work( pers )
        has_high_esa = false
        if has_non_z( pers.income, employment_and_support_allowance )
            esa = pers.income[employment_and_support_allowance]
            if( pers.age < 25 ) 
                if esa > 80 # crudely including support component
                    has_high_esa = true
                end
            else
                if esa > 100 # crudely including support component
                    has_high_esa = true
                end
            end
        end # crude ESA check
        if is_severe_disability( pers ) || has_high_esa
            l = true
        end            
    end
    return l
end

function num_born_before(
    bu             :: BenefitUnit,
    start_date     :: TimeType = Date( 2017, 4, 6 ), # 6th April 2017
    model_run_date :: TimeType = now()) :: Integer
    nb = 0
    for pid in bu.children
        ch = bu.people[pid]
        if born_before( ch.age, start_date, model_run_date )
            nb += 1
        end
    end
    return nb
end



function is_working_hours( pers :: Person, hours... ) :: Bool
    if length(hours) == 1 
        return (pers.usual_hours_worked >= hours[1])
    elseif length(hours) == 2
        return (pers.usual_hours_worked >= hours[1]) &&
               (pers.usual_hours_worked <= hours[2])
    end
end

function is_working_lt_hours( pers :: Person, hours :: Real ) :: Bool
    return pers.usual_hours_worked < hours
end

"""
See CPAG ch 61 p 1426 and appendix 5
"""
function working_disabled( pers::Person, hrs :: HoursLimits ) :: Bool
    if pers.usual_hours_worked >= hrs.lower || pers.employment_status in [Full_time_Employee, Full_time_Self_Employed]
        if pers.registered_blind || pers.registered_partially_sighted || pers.registered_deaf
            return true
        end
        for (dis, t ) in pers.disabilities
            return true
        end
        if haskeys( pers.income, 
            [
                Incapacity_Benefit, 
                Severe_Disability_Allowance, 
                Employment_and_Support_Allowance ])
            return true
        end
    end
    return false
end


#
# FIXME some names here need clarified
#
mutable struct MTIntermediate{RT<:Real}

    benefit_unit_number :: Int
    num_people :: Int
    age_youngest_adult :: Int
    age_oldest_adult :: Int
    age_youngest_child :: Int
    age_oldest_child :: Int
    num_adults :: Int
    someone_pension_age  :: Bool
    someone_pension_age_2016 :: Bool
    all_pension_age :: Bool
    someone_working_ft  :: Bool 
    #
    someone_working_ft_and_25_plus :: Bool
    
    num_not_working :: Int
    num_working_ft :: Int
    num_working_pt :: Int 
    num_working_24_plus :: Int 
    num_working_16_or_less :: Int
    total_hours_worked :: Int
    someone_is_carer :: Bool 
    num_carers :: Int
    
    is_sparent  :: Bool 
    is_sing  :: Bool # FIXME RENAME: is_single
    is_disabled :: Bool
    
    num_disabled_adults :: Int
    num_disabled_children :: Int
    num_severely_disabled_adults :: Int
    num_severely_disabled_children :: Int

    num_job_seekers :: Int
    
    num_children :: Int
    num_allowed_children :: Int
    num_children_born_before :: Int
    ge_16_u_pension_age  :: Bool 
    limited_capacity_for_work  :: Bool 
    has_children  :: Bool 
    economically_active :: Bool
    working_disabled :: Bool
    num_benefit_units :: Int
    nation :: Nation 
    all_student_bu :: Bool

    net_physical_wealth :: RT
    net_financial_wealth :: RT
    net_housing_wealth :: RT
    net_pension_wealth :: RT

end


struct HHIntermed # FIXME make this name consistent with MTIntermediate
    hhint :: MTIntermediate
    buint ::  Vector{MTIntermediate}
end

function to_string( it :: MTIntermediate )::String
    s = to_md_table( it, depth=2 )
    return s
end

function to_string( hh :: HHIntermed ) :: String                          
    s = "## Household\n"
    s *= to_string( hh.hhint )
    for i in eachindex( hh.buint )
        s *= "### Bu $i"
        s *= to_string( hh.buint[i])
    end
    return s
end

"""
Assign CB, etc. to 1st adult female in a benefit unit, everything else to head of bu
"""
function make_recipient( bu :: BenefitUnit, which :: Incomes ) :: BigInt
    ## FIXME assert check here for non bu level benefits e.g. PIPs
    #
    # FIXME maybe also check relationships to children?
    if which in [CHILD_TAX_CREDIT, CHILD_BENEFIT, SCOTTISH_CHILD_PAYMENT ]
        # first_adult_female
        for pid in bu.adults
            if bu.people[pid].sex == Female
                return pid
            end
        end
    end
    ## FIXME expand this to check for if head is retired for WTC/UC 
    # see the thing in .UniversalCredit.jl
    return get_head( bu ).pid
end


function aggregate!( sum :: MTIntermediate, add :: MTIntermediate )
    # benefit_unit_number :: Int
    sum.num_people += add.num_people
    sum.age_youngest_adult = min( sum.age_youngest_adult, add.age_youngest_adult ) 
    sum.age_oldest_adult = max( sum.age_oldest_adult, add.age_oldest_adult )  
    sum.age_youngest_child = min( sum.age_youngest_child, add.age_youngest_child ) 
    sum.age_oldest_child = max( sum.age_oldest_child, add.age_oldest_child ) 
    sum.num_adults += add.num_adults
    sum.someone_pension_age = add.someone_pension_age || add.someone_pension_age 
    sum.someone_pension_age_2016 = sum.someone_pension_age_2016 || add.someone_pension_age_2016
    sum.all_pension_age = sum.all_pension_age && add.all_pension_age 
    sum.someone_working_ft  =  sum.someone_working_ft  || add.someone_working_ft # someone FIXME
    sum.someone_working_ft_and_25_plus =  sum.someone_working_ft_and_25_plus  || add.someone_working_ft_and_25_plus # someone FIXME

    sum.num_working_pt += add.num_working_pt 
    sum.num_working_ft += add.num_working_ft 
    sum.num_not_working += add.num_not_working
    
    sum.num_working_24_plus += add.num_working_24_plus 
    sum.num_working_16_or_less += add.num_working_16_or_less
    sum.total_hours_worked += add.total_hours_worked 
    sum.someone_is_carer = sum.someone_is_carer || add.someone_is_carer # rename someone FIXME
    sum.num_carers += add.num_carers
    
    sum.is_sparent = sum.is_sparent || add.is_sparent
    sum.is_sing = false # since we're adding a 2nd bu 
    sum.is_disabled = sum.is_disabled || add.is_disabled
    
    sum.num_disabled_adults += add.num_disabled_adults
    sum.num_disabled_children += add.num_disabled_children
    sum.num_severely_disabled_adults += add.num_severely_disabled_adults
    sum.num_severely_disabled_children += add.num_severely_disabled_children
    
    sum.num_job_seekers += add.num_job_seekers

    sum.num_children += add.num_children
    sum.num_allowed_children += add.num_allowed_children 
    sum.num_children_born_before += add.num_children_born_before
    sum.ge_16_u_pension_age = sum.ge_16_u_pension_age || add.ge_16_u_pension_age # SOMEONE: FIXME RENAME
    sum.limited_capacity_for_work = sum.limited_capacity_for_work || add.limited_capacity_for_work
    sum.has_children = sum.has_children || add.has_children
    sum.economically_active = sum.economically_active || add.economically_active
    sum.working_disabled = sum.working_disabled || add.working_disabled

    sum.net_physical_wealth += add.net_physical_wealth
    sum.net_financial_wealth += add.net_financial_wealth
    sum.net_housing_wealth += add.net_housing_wealth
    sum.net_pension_wealth += add.net_pension_wealth

end


#=
frs     | 2018 | benunit | TOTSAV        | 10    | Does not wish to say        | Does_not_wish_to_say
 frs     | 2018 | benunit | TOTSAV        | 2     | From 1,500 up to 3,000      | From_1_500_up_to_3_000
 frs     | 2018 | benunit | TOTSAV        | 3     | From 3,000 up to 8,000      | From_3_000_up_to_8_000
 frs     | 2018 | benunit | TOTSAV        | 4     | From 8,000 up to 20,000     | From_8_000_up_to_20_000
 frs     | 2018 | benunit | TOTSAV        | 5     | From 20,000 up to 25,000    | From_20_000_up_to_25_000
 frs     | 2018 | benunit | TOTSAV        | 6     | From 25,000 up to 30,000    | From_25_000_up_to_30_000
 frs     | 2018 | benunit | TOTSAV        | 7     | From 30,000 up to 35,000    | From_30_000_up_to_35_000
 frs     | 2018 | benunit | TOTSAV        | 8     | From 35,000 up to 40,000    | From_35_000_up_to_40_000
 frs     | 2018 | benunit | TOTSAV        | 9     | Over 40,000                 | Over_40_000
frs     | 2021 | benunit | TOTSAV        | 10    | Over £500,000               | Over_£500_000
 frs     | 2021 | benunit | TOTSAV        | 11    | Does not wish to say        | Does_not_wish_to_say
 frs     | 2021 | benunit | TOTSAV        | 2     | From £100 up to £1,500      | From_£100_up_to_£1_500
 frs     | 2021 | benunit | TOTSAV        | 3     | From £1,500 up to £3,000    | From_£1_500_up_to_£3_000
 frs     | 2021 | benunit | TOTSAV        | 4     | From £3,000 up to £6,000    | From_£3_000_up_to_£6_000
 frs     | 2021 | benunit | TOTSAV        | 5     | From £6,000 up to £16,000   | From_£6_000_up_to_£16_000
 frs     | 2021 | benunit | TOTSAV        | 6     | From £16,000 up to £30,000  | From_£16_000_up_to_£30_000
 frs     | 2021 | benunit | TOTSAV        | 7     | From £30,000 up to £50,000  | From_£30_000_up_to_£50_000
 frs     | 2021 | benunit | TOTSAV        | 8     | From £50,000 up to £200,000 | From_£50_000_up_to_£200_000
 frs     | 2021 | benunit | TOTSAV        | 9     | From £200,000 to £500,000   | From_£200_000_to_£500_000


 =#

 function randi( onerand::String, range :: Integer; start=10, stop=15 ) 
    parse(Int,onerand[10:15]) % range # semi random number between 0 and 4999
end

function map_totsav( totsav::Int, data_year :: Int, default :: Real, onerand::String ) :: Real
    
    function oneinrange( totsav::Int, starts::Vector, onerand::String )::Real
        s = starts[totsav]
        range = starts[totsav+1]-starts[totsav]
        v = s + randi( onerand, range )
        @assert v in s:(s+range) "v = $v ; out of range of $(s):$(s+range)"
        return v
    end

    # if totsav == 0
    #    return 0 # should only be called for 1st bu
    # end
    # @show totsav data_year default 
    cap = -11.0
    if data_year in 2015:2019
        if totsav in [-1,1,10]
            cap = default
        elseif totsav == 9 # 40k and above
            if default > 40_000
                cap = default
            else
                cap = 50_000 # FIXME 
            end
        else
            starts = [0,1_500,3_000,8_000,20_000,25_000,30_000,35_000,40_000]
            cap = oneinrange( totsav, starts, onerand )
        end    
    elseif data_year >= 2020
        if totsav in [-1,1, 11]
            cap = default
        elseif totsav == 10
            if default > 500_000
                cap = default
            else
                cap = 600_000
            end
        else
            starts = [0,100,1_500,3_000,6_000,16_000,30_000,50_000,200_000,500_000]
            cap = oneinrange( totsav, starts, onerand )
        end
    else
        @assert false "can't map for totsav=$totsav; year $data_year"
    end
    @assert cap >= 0 "can't get to here totsav=$totsav; datayear=$data_year cap=$cap"
    return max(default,cap)
end

"""
return 3 element vector 1=financial, 2=physical 3=housing 4=pension
"""
function add_wealth!( 
    intermed  :: MTIntermediate{T},
    hh        :: Household{T},
    bu        :: BenefitUnit,
    buno      :: Int,
    method    :: ExtraDataMethod ) where T
    if method in [ imputation, matching ]
        if buno == 1 # use the regression hhld stuff from was & assign all to 1st bu 
            intermed.net_financial_wealth = hh.net_financial_wealth
            intermed.net_physical_wealth = hh.net_physical_wealth
            intermed.net_housing_wealth  = hh.net_housing_wealth 
            intermed.net_pension_wealth = hh.net_pension_wealth
        end
    elseif method == no_method
        head = get_head( bu )
        # println( "add_wealth! method=$method head.wealth_and_assets=$(head.wealth_and_assets)")
        intermed.net_financial_wealth = head.wealth_and_assets
        # nothing else set
    elseif method == other_method_1
        head = get_head( bu )
        cap = map_totsav(
            head.totsav,
            hh.data_year,
            head.wealth_and_assets,
            head.onerand )
        intermed.net_financial_wealth = cap
        intermed.net_physical_wealth = cap*0.6 # average diff between financial and physical in WAS
    end
end

function make_intermediate(
    T :: Type,
    settings :: Settings,
    region :: Standard_Region,
    buno :: Int,
    bu   :: BenefitUnit, 
    hrs  :: HoursLimits,
    age_limits :: AgeLimits,
    child_limits :: ChildLimits,
    num_benefit_units :: Int ) :: MTIntermediate
    # {RT} where RT
    nation = nation_from_region( region )
    age_youngest_adult :: Int = 9999
    age_oldest_adult :: Int = -9999
    age_youngest_child :: Int = 9999
    age_oldest_child :: Int = -9999
    
    is_working_disabled :: Bool = false
    num_adlts :: Int = num_adults( bu )
    # check both & die as we need to think about counts again
    # if we're going back in time to when these were unequal
    # 
    num_pens_age :: Int = 0
    ge_16_u_pension_age  :: Bool = false
    someone_pension_age_2016 :: Bool = false
    limited_capacity_for_work = false
    num_working_16_or_less  = 0
    # :: Int = count( bu, is_working_lt_hours, hrs.lower )
    
    for pid in bu.adults
        pers = bu.people[pid]
        if has_limited_capactity_for_work( pers )
            limited_capacity_for_work = true
        end
        if pers.usual_hours_worked < hrs.lower
            num_working_16_or_less += 1
        end
        if reached_state_pension_age( 
            age_limits, 
            pers.age, 
            pers.sex )
            num_pens_age += 1
        else
            ge_16_u_pension_age = true
        end
        if reached_state_pension_age(
            age_limits, 
            pers.age, 
            pers.sex,
            age_limits.savings_credit_to_new_state_pension )
            someone_pension_age_2016 = true
        end
        
    end
    someone_pension_age  :: Bool = num_pens_age > 0
    all_pension_age :: Bool = num_adlts == num_pens_age
    num_working_ft :: Int = count( bu, is_working_hours, hrs.higher )
    num_working_pt :: Int = count( bu, is_working_hours, hrs.lower, hrs.higher-0.000001 ) # eps(FloatType)
    num_not_working :: Int = count( bu, empl_status_in, 
       Unemployed,
       Retired,
       Student,
       Looking_after_family_or_home,
       Permanently_sick_or_disabled,
       Temporarily_sick_or_injured,
       Other_Inactive
        )
    
    num_job_seekers = 0
    num_working_24_plus :: Int = count( bu, is_working_hours, hrs.med )
    someone_working_ft  :: Bool = num_working_ft > 0
    someone_working_ft_and_25_plus :: Bool = false

    total_hours_worked :: Int = 0
    num_carrs :: Int = num_carers( bu )
    someone_is_carer :: Bool = has_carer_member( bu )
    is_sparent  :: Bool = is_lone_parent( bu )
    is_sing  :: Bool = is_single( bu )   
    
    has_children  :: Bool = ModelHousehold.has_children( bu )
    economically_active = search( bu, empl_status_in, 
        Full_time_Employee,
        Part_time_Employee,
        Full_time_Self_Employed,
        Part_time_Self_Employed,
        Unemployed, 
        Temporarily_sick_or_injured )
    


    # can't think of a simple way of doing the rest with searches..

    is_disabled = has_disabled_member( bu )
    num_disabled_adults = 0
    num_severely_disabled_adults = 0
    num_students = 0
    for pid in bu.adults
        pers = bu.people[pid]
        # kinda sorta CPAG ch 41
        if(pers.employment_status == Student) && (!is_severe_disability( pers )) # fix
            num_students += 1
        end

        if( pers.age >= 25 ) && ( pers.usual_hours_worked >= hrs.higher )
            someone_working_ft_and_25_plus = true
        end

        if (pers.employment_status == Unemployed) || ( pers.jsa_type != no_jsa )
            num_job_seekers += 1
        end

        if pers.age > age_oldest_adult
            age_oldest_adult = pers.age
        end
        if pers.age < age_youngest_adult
            age_youngest_adult = pers.age
        end
        total_hours_worked += round(pers.usual_hours_worked)
        if working_disabled( pers, hrs )
            is_working_disabled = true
        end 
        if pers_is_disabled( pers )
            num_disabled_adults += 1
            if is_severe_disability( pers )
                num_severely_disabled_adults += 1
            end
        end
    end
    @assert 120 >= age_oldest_adult >= age_youngest_adult >= 16
    num_children = size( bu.children )[1] # count( bu, le_age, 16 )
    num_children_born_before = num_born_before( bu ) # fixme parameterise
    num_disabled_children = 0
    # CPAG 41 - there are actually multiple rules for different benefits but hopefully this is near enough
    all_student_bu = (num_students == num_adlts) && (num_children == 0) # CPAG 41 - crude but gets us most of the way here.
    num_severely_disabled_children :: Int = 0
    for pid in bu.children
        pers = bu.people[pid]
        if pers.age > age_oldest_child
            age_oldest_child = pers.age
        end
        if pers.age < age_youngest_child
            age_youngest_child = pers.age
        end
        if pers_is_disabled( pers )
            num_disabled_children += 1
            if is_severe_disability( pers )
                num_severely_disabled_children += 1
            end
        end
    end
    
    ## fixme parameterise this
    num_allowed_children :: Int = apply_2_child_policy( bu, child_limits )
    @assert (!has_children)||(19 >= age_oldest_child >= age_youngest_child >= 0)
          
    
    net_physical_wealth = zero(T)
    net_financial_wealth = zero(T)
    net_housing_wealth = zero(T)
    net_pension_wealth = zero(T)

    return MTIntermediate{T}(
        buno,
        num_people( bu ),
        age_youngest_adult,
        age_oldest_adult,
        age_youngest_child,
        age_oldest_child,
        num_adlts,
        someone_pension_age,
        someone_pension_age_2016,
        all_pension_age,
        someone_working_ft,

        someone_working_ft_and_25_plus,

        num_not_working,
        num_working_ft,
        num_working_pt,
        num_working_24_plus,
        num_working_16_or_less,
        total_hours_worked,
        someone_is_carer,     
        num_carrs,
        is_sparent,
        is_sing,    
        is_disabled,
        num_disabled_adults,
        num_disabled_children,
        num_severely_disabled_adults,
        num_severely_disabled_children,

        num_job_seekers,

        num_children,
        num_allowed_children,
        num_children_born_before,
        ge_16_u_pension_age,
        limited_capacity_for_work,
        has_children,
        economically_active,
        is_working_disabled,
        num_benefit_units,
        nation,
        all_student_bu,
        net_physical_wealth,
        net_financial_wealth,
        net_housing_wealth,
        net_pension_wealth )
end

function make_intermediate( 
    T :: Type,
    settings :: Settings,
    hh   :: Household, 
    hrs  :: HoursLimits,
    age_limits :: AgeLimits,
    child_limits :: ChildLimits,
    allocator :: Function=default_bu_allocation ) :: HHIntermed

    bus = get_benefit_units( hh, allocator )
    n = size( bus )[1]
    buint = Vector{MTIntermediate}(undef,n)
    for buno in 1:n
        buint[buno] = make_intermediate( 
            T,
            settings,
            hh.region,
            buno, 
            bus[buno], 
            hrs, 
            age_limits, 
            child_limits,
            n ) 
        add_wealth!( 
            buint[buno], 
            hh, 
            bus[buno], 
            buno, 
            settings.wealth_method )
    end
    hhint = deepcopy( buint[1] )
    for buno in 2:n
        aggregate!( hhint, buint[buno])
    end
    return HHIntermed( hhint, buint )
end


end # module Intermediate