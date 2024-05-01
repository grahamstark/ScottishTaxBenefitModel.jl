module ModelHousehold

#
# This module provides a slightly abstracted view of a single Scottish household. The fields
# are predominantly based on the FRS, but could in principle come from other sources
# such as SHS, LCF and so on, or perhaps from a web form.
#
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
    pno:: Int # person number in household
    is_hrp :: Bool
    default_benefit_unit:: Int
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

    disabilities::Disability_Dict{Bool}
    
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

    onerand :: String

    legal_aid_problem_probs :: Union{Nothing,DataFrameRow}

end

People_Dict = Dict{BigInt,Person{T}} where T<:Real
Pid_Array = Vector{BigInt}

mutable struct Household{RT<:Real}
    sequence:: Int # position in current generated dataset
    hid::BigInt
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
    expenditure :: Union{Nothing,DataFrameRow}
    factor_costs :: Union{Nothing,DataFrameRow}
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
    if p.relationship_to_hoh == This_Person
        return eq_head
    elseif p.is_standard_child
        return eq_dependent_child
    elseif p.relationship_to_hoh in [Spouse,Cohabitee]
        return eq_spouse_of_head
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

function uprate!( hh :: Household )

    hh.water_and_sewerage  = uprate( hh.water_and_sewerage , hh.interview_year, hh.quarter, upr_housing_rents )
    hh.mortgage_payment = uprate( hh.mortgage_payment, hh.interview_year, hh.quarter, upr_housing_oo )
    hh.mortgage_interest = uprate( hh.mortgage_interest, hh.interview_year, hh.quarter, upr_housing_oo )
    hh.mortgage_outstanding = uprate( hh.mortgage_outstanding, hh.interview_year, hh.quarter, upr_housing_oo )
    hh.gross_rent = uprate( hh.gross_rent, hh.interview_year, hh.quarter, upr_housing_rents )
    hh.other_housing_charges = uprate( hh.other_housing_charges, hh.interview_year, hh.quarter, upr_nominal_gdp )
    hh.gross_housing_costs = uprate( hh.gross_housing_costs, hh.interview_year, hh.quarter, upr_nominal_gdp )
    # hh.total_income = uprate( hh.total_income, hh.interview_year, hh.quarter, upr_nominal_gdp )
    hh.total_wealth = uprate( hh.total_wealth, hh.interview_year, hh.quarter, upr_nominal_gdp )
    hh.net_physical_wealth = uprate( hh.net_physical_wealth, hh.interview_year, hh.quarter, upr_nominal_gdp )
    hh.net_financial_wealth = uprate( hh.net_financial_wealth, hh.interview_year, hh.quarter, upr_nominal_gdp )
    hh.net_housing_wealth = uprate( hh.net_housing_wealth, hh.interview_year, hh.quarter, upr_nominal_gdp )
    hh.net_pension_wealth = uprate( hh.net_pension_wealth, hh.interview_year, hh.quarter, upr_nominal_gdp )

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
function set_wage!( pers :: Person, gross :: Real, wage :: Real )
    pers.income[wages] = gross
    h = gross/wage
    pers.usual_hours_worked = h     
    pers.employment_status = if h < 5 
        Unemployed
    elseif h < 30 
        Part_time_Employee
    else
        Full_time_Employee
    end
    # println( "made usual_hours_worked = $h gross=$gross wage=$wage pers.employment_status=$(pers.employment_status)")
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
    ## sort people in each by pid
    for buno in 1:nbus
        sort!( bua[buno], lt=(left,right)->isless(right.age,left.age))
    end
    bua
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
        @assert people[n].age <= 21 # vague idiot check
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
function allocate_to_bus( T::Type, bua :: BUAllocation ) :: BenefitUnits
    nbus = size(bua)[1]
    bus = BenefitUnits(undef, nbus)
    for i in 1:nbus
        people = People_Dict{T}()
        head_pid :: BigInt = -1
        spouse_pid :: BigInt = -1
        children = Pid_Array()
        adults = Pid_Array()
        npeople = size( bua[i])[1]
        for p in 1:npeople
            person = bua[i][p]
            people[person.pid] = person
            if p == 1
                head_pid = person.pid
                push!( adults, head_pid )
            else
                # println( "on bu $i person $p relationships $(person.relationships)")
                reltohead = person.relationships[head_pid]
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
        bus[i] = new_bu
    end
    bus
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
    allocate_to_bus( T, allocator(hh))
end

function num_people( bu :: BenefitUnit )::Integer
    length( bu.people )
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

end # module