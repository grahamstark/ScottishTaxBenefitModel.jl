module Intermediate

"""
    Some intial calculations for things like numbers and
    ages of children, number of carers and so on. Intended
    to simplify subsequent modelling of benefits, etc.. 
    FIXME some of the names should be globally changed.
"""
using ScottishTaxBenefitModel
using .Definitions

using .ModelHousehold: Person,BenefitUnit,Household, is_lone_parent, get_benefit_units,
    is_single, pers_is_disabled, pers_is_carer, search, count, num_carers, get_head,
    has_disabled_member, has_carer_member, le_age, between_ages, ge_age, num_people,
    empl_status_in, has_children, num_adults, pers_is_disabled, is_severe_disability
    
using .STBParameters: HoursLimits, AgeLimits

export MTIntermediate, make_intermediate

#
# FIXME some names here need clarified
#
mutable struct MTIntermediate
    benefit_unit_number :: Int
    age_youngest_adult :: Int
    age_oldest_adult :: Int
    age_youngest_child :: Int
    age_oldest_child :: Int
    num_adults :: Int
    someone_pension_age  :: Bool
    someone_pension_age_2016 :: Bool
    all_pension_age :: Bool
    working_ft  :: Bool 
    num_working_pt :: Int 
    num_working_24_plus :: Int 
    total_hours_worked :: Int
    is_carer :: Bool 
    num_carers :: Int
    
    is_sparent  :: Bool 
    is_sing  :: Bool 
    is_disabled :: Bool
    
    num_disabled_adults :: Int
    num_disabled_children :: Int
    num_severely_disabled_adults :: Int
    num_severely_disabled_children :: Int
    
    num_children :: Int
    num_allowed_children :: Int
    num_children_born_before :: Int
    ge_16_u_pension_age  :: Bool 
    limited_capacity_for_work  :: Bool 
    has_children  :: Bool 
    economically_active :: Bool
    num_working_full_time :: Int 
    num_not_working :: Int 
    num_working_part_time :: Int
    working_disabled :: Bool
end

function aggregate!( sum :: MTIntermediate, add :: MTIntermediate )
    # benefit_unit_number :: Int
    sum.age_youngest_adult = min( sum.age_youngest_adult, add.age_youngest_adult ) 
    sum.age_oldest_adult = max( sum.age_oldest_adult, add.age_oldest_adult )  
    sum.age_youngest_child = min( sum.age_youngest_child, add.age_youngest_child ) 
    sum.age_oldest_child = max( sum.age_oldest_child, add.age_oldest_child ) 
    sum.num_adults += add.num_adults
    sum.someone_pension_age = add.someone_pension_age || add.someone_pension_age 
    sum.someone_pension_age_2016 = sum.someone_pension_age_2016 || add.someone_pension_age_2016
    sum.all_pension_age = sum.all_pension_age && add.all_pension_age 
    sum.working_ft  += add.working_ft 
    sum.num_working_pt += add.num_working_pt 
    sum.num_working_24_plus += sum.num_working_24_plus 
    sum.total_hours_worked += add.total_hours_worked 
    sum.is_carer = sum.is_carer || add.is_carer
    sum.num_carers += add.num_carers
    
    sum.is_sparent = sum.is_sparent || ad.is_sparent
    sum.is_sing = false # since we're adding a 2nd bu 
    sum.is_disabled = sum.is_disabled || add.is_disabled
    
    sum.num_disabled_adults += add.num_disabled_adults
    sum.num_disabled_children += add.num_disabled_children
    sum.num_severely_disabled_adults += add.num_severely_disabled_adults
    sum.num_severely_disabled_children += add.num_severely_disabled_children
    
    sum.num_children += add.num_children
    sum.num_allowed_children += add.num_allowed_children 
    sum.num_children_born_before += add.num_children_born_before
    sum.ge_16_u_pension_age  += add.ge_16_u_pension_age
    sum.limited_capacity_for_work = sum.limited_capacity_for_work || add.limited_capacity_for_work
    sum.has_children = sum.has_children || add.has_children
    sum.economically_active = sum.economically_active || add.economically_active
    sum.num_working_full_time += add.num_working_full_time
    sum.num_not_working += add.num_not_working
    sum.num_working_part_time += add.num_working_part_time
    sum.working_disabled = sum.working_disabled || add.working_disabled
end


function make_intermediate(
    buno :: Int,
    bu   :: BenefitUnit, 
    hrs  :: HoursLimits,
    age_limits :: AgeLimits ) :: MTIntermediate
    # {RT} where RT
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
    for pid in bu.adults
        pers = bu.people[pid]
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
    # println( "num_adults=$num_adults; num_pens_age=$num_pens_age")
    someone_pension_age  :: Bool = num_pens_age > 0
    all_pension_age :: Bool = num_adlts == num_pens_age
    working_ft  :: Bool = search( bu, is_working_hours, hrs.higher )
    num_working_pt :: Int = count( bu, is_working_hours, hrs.lower, hrs.higher-1 )
    num_working_24_plus :: Int = count( bu, is_working_hours, hrs.med )
    total_hours_worked :: Int = 0
    num_carrs :: Int = num_carers( bu )
    is_carer :: Bool = has_carer_member( bu )
    is_sparent  :: Bool = is_lone_parent( bu )
    is_sing  :: Bool = is_single( bu )   
    limited_capacity_for_work  :: Bool = has_disabled_member( bu ) # FIXTHIS
    has_children  :: Bool = ModelHousehold.has_children( bu )
    economically_active = search( bu, empl_status_in, 
        Full_time_Employee,
        Part_time_Employee,
        Full_time_Self_Employed,
        Part_time_Self_Employed,
        Unemployed, 
        Temporarily_sick_or_injured )
    # can't think of a simple way of doing the rest with searches..
    num_working_full_time = 0
    num_not_working = 0
    num_working_part_time = 0
    is_disabled = has_disabled_member( bu )
    num_disabled_adults = 0
    num_severely_disabled_adults = 0
    for pid in bu.adults
        pers = bu.people[pid]
        if pers.age > age_oldest_adult
            age_oldest_adult = pers.age
        end
        if pers.age < age_youngest_adult
            age_youngest_adult = pers.age
        end
        if ! is_working_hours( pers, hrs.lower )
            num_not_working += 1
        elseif pers.usual_hours_worked <= hrs.med
            num_working_part_time += 1
        else 
            num_working_full_time += 1
        end          
        total_hours_worked += round(pers.usual_hours_worked)
        if working_disabled( pers, hrs )
            is_working_disabled = true
        end 
        if pers_is_disabled( pers )
            num_disabled_adults += 1
            println( "adding a disabled adult $num_disabled_adults ")
            if is_severe_disability( pers )
                num_severely_disabled_adults += 1
            end
        end
    end
    @assert 120 >= age_oldest_adult >= age_youngest_adult >= 16
    num_children = size( bu.children )[1] # count( bu, le_age, 16 )
    num_children_born_before = num_born_before( bu ) # fixme parameterise
    num_disabled_children = 0
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
    num_allowed_children :: Int = apply_2_child_policy( bu )
    # println( "has_children $has_children age_oldest_child $age_oldest_child age_youngest_child $age_youngest_child" )
    @assert (!has_children)||(19 >= age_oldest_child >= age_youngest_child >= 0)
                                    
    return MTIntermediate(
        buno,
        age_youngest_adult,
        age_oldest_adult,
        age_youngest_child,
        age_oldest_child,
        num_adlts,
        someone_pension_age,
        someone_pension_age_2016,
        all_pension_age,
        working_ft,
        num_working_pt,
        num_working_24_plus,
        total_hours_worked,
        is_carer,     
        num_carrs,
        is_sparent,
        is_sing,    
        is_disabled,
        num_disabled_adults,
        num_disabled_children,
        num_severely_disabled_adults,
        num_severely_disabled_children,
        num_children,
        num_allowed_children,
        num_children_born_before,
        ge_16_u_pension_age,
        limited_capacity_for_work,
        has_children,
        economically_active,
        num_working_full_time,
        num_not_working,
        num_working_part_time,
        is_working_disabled
    )
end

function make_intermediate( 
    hh   :: Household, 
    hrs  :: HoursLimits,
    age_limits :: AgeLimits,
    allocator :: Function=default_bu_allocation ) :: NamedTuple

    bus = get_benefit_units( hh, allocator )
    n = size( bus )[1]
    buint = Vector{MTIntermediate}(undef,n)
    for buno in 1:n
        buint[buno] = make_intermediate( buno, bus[buno], hrs, age_limits )        
    end
    hhint = deepcopy( buint[1] )
    for buno in 2:n
        aggregate!( hhint, buint[buno])
    end
    return ( hhint = hhint, buint=buint )
end

end # module Intermediate