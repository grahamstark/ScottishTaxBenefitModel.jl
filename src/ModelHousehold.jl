module ModelHousehold

#
# This module provides a slightly abstracted view of a single Scottish household. The fields
# are predominantly based on the FRS, but could in principle come from other sources
# such as SHS, LCF and so on, or perhaps from a web form.
#
using ArgCheck
using Base: String
using Dates
using DataFrames
import Base.show

using ScottishTaxBenefitModel
using .Definitions
using .Utils: 
    has_non_z, 
    todays_date, 
    to_md_table

using .RunSettings: Settings

using .EquivalenceScales:
    EQ_P_Type,
    EQ_Person,
    EQScales,
    get_equivalence_scales,
    eq_dependent_child,
    eq_head,
    eq_other_adult,
    eq_spouse_of_head

import .EquivalenceScales.get_age 
import .EquivalenceScales.eq_rel_to_hoh

import Base.isequal
import Base.hash

using .Uprating: uprate, UPRATE_MAPPINGS

export 
    Household, 
    BenefitUnit,
    BenefitUnits,
    BUAllocation,
    Person, 
    People_Dict,

    adult_pids,
    age_then,
    between_ages, 
    child_pids, 
    count,
    default_bu_allocation,
    empl_status_in, 
    ge_age, 
    get_benefit_units, 
    get_head,
    get_spouse, 
    has_carer_member, 
    has_children, 
    has_disabled_member,
    has_income,
    household_composition_1,
    interview_date, 
    infer_house_price!,
    is_child,
    is_head,
    is_lone_parent, 
    is_severe_disability, 
    is_single, 
    is_spouse,
    isless,
    le_age, 
    make_benefit_unit, 
    make_eq_scales!,    
    num_adults, 
    num_adults, 
    num_carers,
    num_children, 
    num_people, 
    num_std_bus,
    oldest_person, 
    on_mt_benefits,
    pers_is_carer, 
    pers_is_disabled, 
    printpids,
    search,
    set_wage!,
    to_string, 
    total_assets,
    uprate!

mutable struct Person{RT<:Real}
    hid::BigInt # == sernum
    pid::BigInt # == unique id (year * 100000)+
    uhid::BigInt # non compound index to hhld
    pno:: Int # person number in household
    is_hrp :: Bool
    default_benefit_unit:: Int
    is_benefit_unit_head :: Bool 
    is_standard_child :: Bool
    age:: Int

    sex::Sex
    ethnic_group::Ethnic_Group
    marital_status::Marital_Status
    highest_qualification::Qualification_Type

    sic::SIC_2007
    occupational_classification::Standard_Occupational_Classification
    public_or_private :: Employment_Sector
    principal_employment_type :: Employment_Type

    socio_economic_grouping::Socio_Economic_Group
    age_completed_full_time_education:: Int
    years_in_full_time_work:: Int
    employment_status::ILO_Employment
    actual_hours_worked::RT
    usual_hours_worked::RT

    age_started_first_job :: Int

    income::Incomes_Dict{RT}
    benefit_ratios :: Incomes_Dict{RT}
    
    jsa_type :: JSAType # FIXME change this name
    esa_type :: JSAType
    dla_self_care_type :: LowMiddleHigh
    dla_mobility_type :: LowMiddleHigh
    attendance_allowance_type :: LowMiddleHigh
    pip_daily_living_type :: PIPType
    pip_mobility_type ::  PIPType

    bereavement_type :: BereavementType
    had_children_when_bereaved :: Bool 

    assets::Asset_Dict{RT}
    over_20_k_saving :: Bool
    pay_includes ::Included_In_Pay_Dict{Bool}
    
    # contracted_out_of_serps::Bool

    registered_blind::Bool
    registered_partially_sighted::Bool
    registered_deaf::Bool

    disabilities::Disability_Dict{Bool} # FIXME this should be a set
    
    health_status::Health_Status

    has_long_standing_illness :: Bool
    adls_are_reduced :: ADLS_Inhibited
    how_long_adls_reduced :: Illness_Length

    relationships::Relationship_Dict
    relationship_to_hoh :: Relationship
    is_informal_carer::Bool
    receives_informal_care_from_non_householder::Bool
    hours_of_care_received::RT
    hours_of_care_given::RT
    #
    # Childcare fields; assigned to children
    #
    hours_of_childcare :: RT
    cost_of_childcare :: RT
    childcare_type :: Child_Care_Type
    employer_provides_child_care :: Bool

    company_car_fuel_type :: Fuel_Type
    company_car_value :: RT
    company_car_contribution :: RT
    fuel_supplied :: RT

    work_expenses  :: RT 
    travel_to_work :: RT 
    debt_repayments :: RT 
    wealth_and_assets :: RT
    totsav :: Int # FRS savings as bands
    onerand :: String

    legal_aid_problem_probs :: Union{Nothing,DataFrameRow}

end

People_Dict = Dict{BigInt,Person{T}} where T<:Real
Pid_Array = Vector{BigInt}

mutable struct Household{RT<:Real}
    sequence:: Int # position in current generated dataset
    hid::BigInt
    uhid::BigInt # single 
    data_year :: Int
    interview_year:: Int
    interview_month:: Int
    quarter:: Int
    tenure::Tenure_Type
    region::Standard_Region
    ct_band::CT_Band
    dwelling :: DwellingType
    council_tax::RT
    water_and_sewerage ::RT
    mortgage_payment::RT
    mortgage_interest::RT
    years_outstanding_on_mortgage:: Int
    mortgage_outstanding::RT
    year_house_bought:: Int
    gross_rent::RT # rentg Gross rent including Housing Benefit  or rent Net amount of last rent payment
    rent_includes_water_and_sewerage::Bool
    other_housing_charges::RT 
    gross_housing_costs::RT
    # total_income::RT
    total_wealth::RT
    house_value::RT
    weight::RT
    council :: Symbol
    nhs_board :: Symbol
    bedrooms :: Int
    head_of_household :: BigInt
    
    # fixme make these a set based on WealthTypes
    net_physical_wealth :: RT
    net_financial_wealth :: RT
    net_housing_wealth :: RT
    net_pension_wealth :: RT
    original_gross_income :: RT
    original_income_decile :: Int
    equiv_original_income_decile :: Int
    # FIXME make a proper consumption structure here rather than just an lcf dump.
    # lcf_default_matched_case :: Int 
    # lcf_default_data_year :: Int  
    expenditure :: Union{Nothing,DataFrameRow}
    factor_costs :: Union{Nothing,DataFrameRow}
    raw_wealth :: Union{Nothing,DataFrameRow}
    shsdata :: Union{Nothing,DataFrameRow}
    people::People_Dict{RT}
    onerand :: String
    equivalence_scales :: EQScales{RT}
end

function to_string( hh :: Household ) :: String
    s = to_md_table( hh, exclude=[:people,:onerand])
    for pid in sort(collect(keys(hh.people)))
        s *= to_string( hh.people[pid] )
    end
    return s
end

function to_string( pers :: Person ) :: String
    s = """
    ### Person $(pers.pno)
    """
    s *= to_md_table( pers, depth=1,exclude=[:onerand])
    return s
end


"""
for equivalence scale implicit interface
"""
function get_age( p::Person ) :: Int
    return p.age;
end

"""
for the eq scale implicit interface
"""
function eq_rel_to_hoh( p :: Person ) :: EQ_P_Type
    # if (! p.is_standard_child) && (p.default_benefit_unit > 1)
    #    return eq_head
    if p.relationship_to_hoh == This_Person
        return eq_head
    elseif p.is_standard_child
        return eq_dependent_child
    elseif p.relationship_to_hoh in [Spouse,Cohabitee]
        return eq_spouse_of_head
    # hack for 2nd bu adults always being heads
    # elseif (p.default_benefit_unit > 1)
        # return eq_head
    else 
        return eq_other_adult
    end
end

function make_eq_scales!( hh :: Household{T} ) where T
    pl = collect(values(hh.people))
    # sz = size( pl )[1]
    # print( "num people $sz" )
    hh.equivalence_scales = get_equivalence_scales( T, pl )
end

function interview_date( hh :: Household ) :: Date
    return Date( hh.interview_year, hh.interview_month, 15 )
end

function uprate!( pid :: BigInt, year::Integer, quarter::Integer, person :: Person )
    for (t,inc) in person.income
            person.income[t] = uprate( inc, year, quarter, UPRATE_MAPPINGS[t])
    end
    for (a,ass) in person.assets
            person.assets[a] = uprate( ass, year, quarter, UPRATE_MAPPINGS[a])
    end
    person.cost_of_childcare = uprate( person.cost_of_childcare, year, quarter, upr_earnings )
end

function uprate!( hh :: Household, settings::Settings )

    hh.water_and_sewerage  = uprate( hh.water_and_sewerage , hh.interview_year, hh.quarter, upr_housing_rents )
    hh.mortgage_payment = uprate( hh.mortgage_payment, hh.interview_year, hh.quarter, upr_housing_oo )
    hh.mortgage_interest = uprate( hh.mortgage_interest, hh.interview_year, hh.quarter, upr_housing_oo )
    hh.mortgage_outstanding = uprate( hh.mortgage_outstanding, hh.interview_year, hh.quarter, upr_housing_oo )
    hh.gross_rent = uprate( hh.gross_rent, hh.interview_year, hh.quarter, upr_housing_rents )
    hh.other_housing_charges = uprate( hh.other_housing_charges, hh.interview_year, hh.quarter, upr_nominal_gdp )
    hh.gross_housing_costs = uprate( hh.gross_housing_costs, hh.interview_year, hh.quarter, upr_nominal_gdp )
    # hh.total_income = uprate( hh.total_income, hh.interview_year, hh.quarter, upr_nominal_gdp )
    if settings.wealth_method != matching # since matched wealth data is pre-uprated
        hh.total_wealth = uprate( hh.total_wealth, hh.interview_year, hh.quarter, upr_nominal_gdp )
        hh.net_physical_wealth = uprate( hh.net_physical_wealth, hh.interview_year, hh.quarter, upr_nominal_gdp )
        hh.net_financial_wealth = uprate( hh.net_financial_wealth, hh.interview_year, hh.quarter, upr_nominal_gdp )
        hh.net_housing_wealth = uprate( hh.net_housing_wealth, hh.interview_year, hh.quarter, upr_nominal_gdp )
        hh.net_pension_wealth = uprate( hh.net_pension_wealth, hh.interview_year, hh.quarter, upr_nominal_gdp )
    end
    hh.house_value = uprate( hh.house_value, hh.interview_year, hh.quarter, upr_housing_oo )
    for (pid,person) in hh.people
        uprate!( pid, hh.interview_year, hh.quarter, person )
    end
end

function oldest_person( people :: People_Dict ) :: NamedTuple
    oldest = ( age=-999, pid=BigInt(0))
    for person in people
        if person.age > oldest.age
            oldest.age = person.age
            oldest.pid = person.pid
        end
    end
    oldest
end

PeopleArray = Vector{Person}

struct BenefitUnit{T<:Real}
    people :: People_Dict{T}
    head :: BigInt
    spouse :: BigInt
    adults :: Pid_Array
    children :: Pid_Array
end


BenefitUnits = Vector{BenefitUnit}
BUAllocation = Vector{PeopleArray}

function num_children( bu :: BenefitUnit ) :: Integer
    size( bu.children )[1]
end

function num_children( hh :: Household ) :: Integer
    count( hh, is_child )
end

"""
For Budget constraints: set the wage and make all the needed
corrections to employment status, hours worked, pensions(? pensions not done yet)
"""
function set_wage!( pers :: Person, gross :: Real, wage :: Real; switch_status=true )
    pers.income[wages] = gross
    h = gross/wage
    pers.usual_hours_worked = h
    if switch_status     
        pers.employment_status = if h <= 0 
            Unemployed
        elseif h < 30 
            Part_time_Employee
        else
            Full_time_Employee
        end
    end
    # println( "made usual_hours_worked = $h gross=$gross wage=$wage pers.employment_status=$(pers.employment_status)")
end

#
# Sort by age but with bu heads always first.
#
function sort_people_in_bus!( bua :: BUAllocation )
    function comp2people( l::Person, r::Person )::Bool
        r1 = r.age + (10000*(r.is_benefit_unit_head))
        l1 = l.age + (10000*(l.is_benefit_unit_head))
        return isless( r1, l1 )
    end

    for bu in bua
        sort!( bu; lt=comp2people ) # (left,right)->isless(right.age,left.age))  
        #=      
        for p in bu
            println( "hh.hid=$(hh.hid) buno $buno is_benefit_unit_head=$(p.is_benefit_unit_head) age=$(p.age)" )
        end
        =#
    end
end

#
# This creates a array of references to each person in the houshold, broken into
# benefit units using the default FRS/EFS benefit unit number. 
#
function default_bu_allocation( hh :: Household ) :: BUAllocation
    bua = BUAllocation()
    nbus = 0
    # how many bus
    for (pid,person) in hh.people
        nbus = max( nbus, person.default_benefit_unit )
    end
    ## create benefit units
    for buno in 1:nbus
        push!( bua, PeopleArray())
    end
    sz = size( bua )[1]
    ## allocate peobuallocationple to them
    for (pid,person) in hh.people
        pp = bua[person.default_benefit_unit]
        push!( pp, person )
    end
    # sort heads always first, then by age
    return bua
end

"""

Create a benefit unit from an array of people
really only needed for some unit tests.

FIXME: don't use outside of tests! likely mess up children and spouses.

"""
function make_benefit_unit( 
    people :: PeopleArray, 
    head :: BigInt, 
    spouse:: BigInt = -1 ) :: BenefitUnit
    npeople = size( people )[1]
    T = typeof( people[1].hours_of_care_received )
    pd = People_Dict{T}()
    children = Pid_Array()
    adults = Pid_Array()
    push!( adults, head )
    if spouse > 0 
        push!( adults, spouse )
    end
    palloc = spouse <= 0 ? 2 : 3
    for n in palloc:npeople
        push!(children, people[n].pid)
        @assert people[n].age <= 19 # vague idiot check
    end
    for pers in people
        pd[pers.pid] = pers
    end
    return BenefitUnit( pd, head, spouse, adults, children )
end

function child_pids( hh :: Household ) :: Pid_Array
    chlds = Pid_Array()
    for (pid,pers) in hh.people
        if is_child( pers )
            push!( chlds, pid )
        end
    end
    return chlds 
end

#
# This creates a array of references to each person in the houshold, broken into
# benefit units using the default FRS/EFS benefit unit number.
#
function allocate_to_bus( T::Type, hh_head_pid :: BigInt, bua :: BUAllocation ) :: BenefitUnits
    nbus = size(bua)[1]
    bus = BenefitUnits(undef, nbus)
    # We have to have bu heads first, so...
    sort_people_in_bus!( bua )
    for buno in 1:nbus
        people = People_Dict{T}()
        head_pid :: BigInt = -1
        spouse_pid :: BigInt = -1
        children = Pid_Array()
        adults = Pid_Array()
        npeople = size( bua[buno])[1]
        for p in 1:npeople
            person = bua[buno][p]
            people[person.pid] = person
            if person.pid == hh_head_pid
                # FIXME: Rewrite so there's no need for this.
                @assert buno == 1 "head needs to be 1st BU $hh_head_pid"
                head_pid = person.pid
                push!( adults, head_pid )
            elseif person.is_benefit_unit_head
                head_pid = person.pid
                push!( adults, head_pid )
            elseif (p == 1) && (buno > 1)
                head_pid = person.pid
                push!( adults, head_pid )
            else
                # println( "on bu $i person $p relationships $(person.relationships)")
                @assert head_pid > 0 "head pid must be allocated; buno=$buno person $(person.pid) relationships $(person.relationships)"
                hp = (buno == 1) ? hh_head_pid : head_pid
                reltohead = person.relationships[hp]
                if reltohead in [Spouse,Cohabitee,Civil_Partner]
                    spouse_pid = person.pid
                    push!( adults, spouse_pid )
                    # FIXME we need to remove these checks if
                    # we're using a non-default allocation to bus
                    # @assert person.age >= 16
                else
                    # @assert person.age <= 19
                    push!( children, person.pid )
                end
            end
        end
        new_bu = BenefitUnit( people, head_pid, spouse_pid, adults, children )
        bus[buno] = new_bu
    end
    # Idiot checks for allocations; counts of people checked where this is called.
    for buno in 1:nbus 
        head = get_head( bus[buno])
        if buno == 1
            @assert head.pid == hh_head_pid "mismatched 1st bu head should be $hh_head is: $(head.pid)"
        else
            @assert (! ismissing( head )) "unallocated head for bu $buno"
            @assert ! head.is_standard_child "head of bu seems to be child for bu $buno pid=$(head.pid) hid=$(head.hid) age=$(head.age)"
        end
    end
    return bus
end

function total_assets( pers :: Person{T} )::T where T
    sum( values( pers.assets ))
end

function total_assets( bu :: BenefitUnit )
    s = 0.0
    for( pid, pers ) in bu.people
        s += total_assets( pers.assets )
    end
    s
end

function total_assets( hh :: Household{T}) :: T where T
    s = zero(T)
    for( pid, pers ) in hh.people
        s += total_assets( pers )
    end
    s
end


function get_benefit_units(
    hh :: Household{T},
    allocator :: Function=default_bu_allocation ) :: BenefitUnits where T
    # println( "calling allocator on hh $(hh.hid)")
    allocs = allocator(hh)
    bus = allocate_to_bus( T, hh.head_of_household, allocs )
    @assert num_people( bus ) == num_people( hh ) "some people lost/found in bu allocation; bu count=$(num_people( bus )) hh count=$(num_people( hh ))"
    return bus
end

function num_people( bu :: BenefitUnit )::Integer
    length( bu.people )
end

function num_people( bus :: BenefitUnits ) :: Integer
    nbus = 0
    for bu in bus 
        nbus += num_people(bu)
    end
    return nbus
end

function num_std_bus( hh :: Household ) :: Int
    mbu = -1
    for (pid,pers) in hh.people
        if pers.default_benefit_unit > mbu
            mbu = pers.default_benefit_unit
        end
    end
    @assert mbu > 0
    return mbu
end

function num_adults( bu :: BenefitUnit )::Integer
    size( bu.adults )[1]
end

function adult_pids( hh :: Household )::Pid_Array
    pids = Pid_Array()
    for (pid,pers) in hh.people
        if ! is_child( pers )
            push!( pids, pid )
        end
    end
    return pids
end

function num_adults( hh )
    return size( adult_pids(hh))[1]
end

function num_people( hh :: Household ) :: Integer
    length( hh.people )
end

function get_head( bu :: BenefitUnit )::Person
    bu.people[bu.head]
end

function get_head( hh :: Household ) :: Person
    return hh.people[hh.head_of_household]
end

function is_head( bu :: BenefitUnit, pers :: Person  ) :: Bool
    return bu.head == pers.pid
end

function is_spouse( unit, pers :: Person  ) :: Bool
    head = get_head(unit)
    p = partner_of( head )
    if p === nothing
        return false
    end
    return p == pers.pid
end


function partner_of( pers :: Person ) :: Union{Nothing,BigInt}
    for (pid,rel) in pers.relationships
        if rel in [Spouse,Cohabitee]
            return pid
        end
    end
    return nothing
end

function get_spouse( hh :: Household ) ::Union{Nothing,Person}
    head = get_head( hh )
    p = partner_of( head )
    if p !== nothing
        return hh.people[p]
    end
    return nothing
end

function get_spouse( bu :: BenefitUnit )::Union{Nothing,Person}
    if bu.spouse <= 0
        return nothing
    end
    bu.people[bu.spouse]
end

function has_children( bu :: BenefitUnit ) :: Bool
    num_children( bu ) > 0
end

"""
relies on `is_child` being sensible
"""
function has_children( hh :: Household )::Bool
    for (pid, pers ) in hh.people
        if is_child( pers )
            return true
        end
    end
    return false
end

function is_lone_parent( bu :: BenefitUnit ) :: Bool
    return bu.spouse < 0 && has_children( bu )
end

function is_child( pers :: Person )
    # FIXME crude 
    pers.is_standard_child
    # below won't work for hh  since
    # wouldn't be child if in own BU & we can't check that with 1 person
    #if pers.age <= 15
    #    return true
    #end
    #(pers.age <= 19) && (pers.employment_status in [Student])
end

#
# fixme just count people???
#
function is_lone_parent( hh :: Household,
    allocator :: Function=default_bu_allocation ) :: Bool
    
    bus = get_benefit_units( hh, allocator )
    if size(bus)[1] > 1
        return false
    end
    return bus[1].spouse < 0 && size( bus[1].children )[1] > 0
end


function is_single( bu :: BenefitUnit ) :: Bool
    num_people( bu ) == 1
end

function is_single( hh :: Household ) :: Bool
    num_people( hh ) == 1
end

"""
FIXME we're going to do this solely on benefit receipt/is_informal_carer flag
for now until we get the regressions done
we use historic benefits here since this uses actual data
"""
function pers_is_carer( pers :: Person, params ... ) :: Bool
    if has_non_z( pers.income, carers_allowance )
        return true
    end
    # FIXME check/parameterise this
    if (pers.is_informal_carer) && (pers.hours_of_care_given > 0)
        return true
    end
    return false
end

const DISABLE_BENEFITS = [
    severe_disability_allowance,
    attendance_allowance,
    incapacity_benefit,
    dlaself_care,
    dlamobility,
    personal_independence_payment_daily_living,
    personal_independence_payment_mobility]
    

"""

"""
function is_severe_disability( pers :: Person )
    return pers_is_disabled( pers ) ||
           pers.dla_self_care_type in [mid, high] ||
           pers.dla_mobility_type == high ||
           pers.attendance_allowance_type == high ||
           pers.pip_daily_living_type == enhanced_pip ||
           pers.pip_mobility_type == enhanced_pip ||
           pers.adls_are_reduced == reduced_a_lot ||
           pers.health_status == Very_Bad 

end    

"""
FIXME we're going to do this solely on benefit receipt
for now until we get the regressions done
we use historic benefits here since this uses actual data
"""
function pers_is_disabled( pers :: Person, params ... ) :: Bool
    if pers.registered_blind
        return true
    end
    if pers.employment_status in [Permanently_sick_or_disabled]
        return true
    end
    if pers.adls_are_reduced == reduced_a_lot
        return true
    end
    for dis in [mobility,
        dexterity,
        learning,
        memory,
        mental_health]
        if haskey(pers.disabilities,dis) && pers.disabilities[dis]
            return true
        end
    end
       
    for k in DISABLE_BENEFITS
        if has_non_z( pers.income, k )
            return true
        end
    end # loop
    return false
end


function empl_status_in( pers :: Person, statuses ...)
    return pers.employment_status in statuses
end


function is_working( pers :: Person )
    return employment_status_in( pers, 
        Full_time_Employee,
        Part_time_Employee,
        Full_time_Self_Employed,
        Part_time_Self_Employed )
end

function is_employee( pers :: Person )
    return employment_status_in( pers, 
        Full_time_Employee,
        Part_time_Employee )
end

le_age( pers :: Person, age ... ) = pers.age <= age[1] 

ge_age( pers :: Person, age ... ) = pers.age >= age[1] 

between_ages( pers :: Person, age ... ) = age[1] <= pers.age <= age[2] 

has_income( pers::Person, which :: Incomes_Type ) = haskey( pers.income, which )

function has_income( pers::Person, which ... )::Bool
    for k in which
        if has_income( pers, k )
            return true
        end
    end
    return false
end

function search( people :: People_Dict, func :: Function, params... ) :: Bool
    for ( pid,pers ) in people
        if func( pers, params... )
            return true
        end
    end
    return false
end

function count( people :: People_Dict, func :: Function, params... ) :: Int
    n = 0
    for ( pid,pers ) in people
        if func( pers, params... )
            n += 1
        end
    end
    return n
end


function search( bu :: BenefitUnit, func :: Function, params... ) :: Bool
    return search( bu.people, func, params... )
end

function search( hh :: Household, func :: Function, params ... ) :: Bool
    return search( hh.people, func, params... )
end

function count( bu :: BenefitUnit, func :: Function, params... ) :: Integer
     return count( bu.people, func, params... )
end

function count( hh :: Household, func :: Function, params ... ) :: Integer
    return count( hh.people, func, params... )
end

function on_mt_benefits( pers :: Person ) :: Bool
    if has_income( pers, [income_support, working_tax_credit, child_tax_credit, housing_benefit, universal_credit]...)
        return true
    end
    if pers.jsa_type == income_related_jsa
        return true
    end
    if pers.esa_type == income_related_jsa
        return true
    end
    return false
end

## FIXME make these below return lists of PIDs

function on_mt_benefits( bu :: BenefitUnit ) :: Bool
    return search( bu, on_mt_benefits )
end

function on_mt_benefits( hh :: Household ) :: Bool
    return search( hh, on_mt_benefits )
end


function has_disabled_member( bu :: BenefitUnit ) :: Bool
    search( bu.people, pers_is_disabled )
end

function has_disabled_member( hh :: Household ) :: Bool
    search( hh.people, pers_is_disabled )
end

function has_carer_member( bu :: BenefitUnit ) :: Bool
    search( bu.people, pers_is_carer )
end

function has_carer_member( hh :: Household ) :: Bool
    search( hh.people, pers_is_carer )
end

function num_carers( bu :: BenefitUnit ) :: Int
    count( bu.people, pers_is_carer )
end

function carers( hh :: Household ) :: Int
    count( hh.people, pers_is_carer )
end


# simple diagnostic prints for testing allocation

function printpids( pers :: Person )
    println( "pid: $(pers.pid) age $(pers.age) sex $(pers.sex) default_benefit_unit $(pers.default_benefit_unit) ")
end

function printpids( bu::BenefitUnit)
      head = get_head( bu )
      print( "HEAD: ")
      printpids( head )
      spouse = get_spouse( bu )
      if spouse !== nothing
            print( "SPOUSE: ")
            printpids( spouse )

      end
      for chno in bu.children
            print( "CHILD_$(chno):")
            child = bu.people[chno]
            printpids( child )
      end
end

function printpids( people :: People_Dict )
    ks = sort(collect(keys(people)))
    for k in ks
        print( "PERSON_$k")
        printpids( people[k] )
    end
end

function printpids( buas::BUAllocation )
    nbus = size( buas )[1]
    for i in 1:nbus
        npeople = size( buas[i] )[1]
        for p in 1:npeople
            print( "PERS_$(p): ")
            printpids( buas[i][p])
        end
    end
end

function age_then( pers :: Person, when :: Int ) :: Int
    Utils.age_then( pers.age, when );
end

function age_then( pers :: Person, when :: Date = todays_date() ) :: Int
    Utils.age_then( pers.age, Dates.year( when ))
end

function household_composition_1( hh :: Household ) :: HouseholdComposition1
    # hc = single_person
    nads = num_adults( hh )
    @assert nads >= 1
    nkids = num_children( hh )
    nbus = num_std_bus( hh )
    @assert (nads + nkids) == num_people(hh)
    @assert nbus in 1:12
    return if nbus > 1
        if nkids > 0
            mbus_w_children
        else
            mbus_wo_children
        end
    else 
        @assert nads in 1:2
        if nads == 1
            if nkids == 0
                single_person
            else
                single_parent
            end
        else 
            if nkids == 0
                couple_wo_children
            else
                couple_w_children
            end
        end # 2 adults
    end 
end

function infer_house_price!( hh :: Household, settings :: Settings )
    ## wealth_regressions.jl , model 3
    hp = 0.0
    if is_owner_occupier(hh.tenure)
        if settings.wealth_method == matching 
            hp = hh.house_value
        else 
            hhincome = max(hh.original_gross_income, 1.0)
            c = ["(Intercept)"            10.576
            "scotland"               -0.279896
            "wales"                  -0.286636
            "london"                  0.843206
            "owner"                   0.0274378
            "detatched"               0.139247
            "semi"                   -0.169271
            "terraced"               -0.257117
            "purpose_build_flat"     -0.170908
            "HBedrmr7"                0.242845
            "hrp_u_25"               -0.334261
            "hrp_u_35"               -0.266385
            "hrp_u_45"               -0.206901
            "hrp_u_55"               -0.159525
            "hrp_u_65"               -0.10077
            "hrp_u_75"               -0.0509382
            "log_weekly_net_income"   0.17728
            "managerial"              0.227192
            "intermediate"            0.165209]
            
            hrp = get_head( hh )

            v = ["(Intercept)"          1
            "scotland"                  0
            "wales"                     1
            "london"                    0
            "owner"                     hh.tenure == Owned_outright ? 1 : 0
            "detatched"                 hh.dwelling == detatched ? 1 : 0
            "semi"                      hh.dwelling == semi_detached ? 1 : 0
            "terraced"                  hh.dwelling == terraced ? 1 : 0
            "purpose_build_flat"        hh.dwelling == flat_or_maisonette ? 1 : 0
            "HBedrmr7"                  hh.bedrooms
            "hrp_u_25"                  hrp.age < 25 ? 1 : 0
            "hrp_u_35"                  hrp.age in [25:44] ? 1 : 0
            "hrp_u_45"                  hrp.age in [45:54] ? 1 : 0
            "hrp_u_55"                  hrp.age in [55:64] ? 1 : 0
            "hrp_u_65"                  hrp.age in [65:74] ? 1 : 0
            "hrp_u_75"                  hrp.age in [75:999] ? 1 : 0
            "log_weekly_net_income"     log(hhincome)
            "managerial"                hrp.socio_economic_grouping in [Managers_Directors_and_Senior_Officials,Professional_Occupations] ? 1 : 0
            "intermediate"              hrp.socio_economic_grouping in [Associate_Prof_and_Technical_Occupations,Admin_and_Secretarial_Occupations] ? 1 : 0
            ]
            hp = exp( c[:,2]'v[:,2])
        end        
    elseif hh.tenure !== Rent_free
        # @assert hh.gross_rent > 0 "zero rent for hh $(hh.hid) $(hh.tenure) "
        # 1 │  2272       2015         0.0
        # 2 │ 10054       2015         0.0
        # 3 │  5019       2016         0.0
        # assign 50 pw to these 3
        rent = hh.gross_rent == 0 ? 100.0 : hh.gross_rent # ?? 3 cases of 0 rent
        hp = rent * WEEKS_PER_YEAR * settings.annual_rent_to_house_price_multiple
    else
        hp = 80_000 # FIXME just a made-up number for rent-free accomodation; make this based on ONS house data
    end
    hh.house_value = hp
end

end # module