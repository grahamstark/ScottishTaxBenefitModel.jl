module ExampleHelpers
##
# This module just collects together random stuff that's helpul
# in creating unit tests and visualisations, such as things to create an example household,
# make someone disabled, unemployed and so on. None of it is very rigorous and likely
# shouldn't be used in a proper model simulation run.
##


using ScottishTaxBenefitModel
using .ModelHousehold
using .ExampleHouseholdGetter
using .EquivalenceScales
using .Definitions
using .Utils

export

    EXAMPLES,

    add_child!,
    add_non_dependent!,
    age_now,
    blind!,
    carer!,
    deafen!,
    delete_child!,
    delete_person!,
    disable_seriously!,
    disable_slightly!,
    employ!,
    enable!,
    make_hh,
    makePID,
    retire!,
    set_childrens_ages!,
    unblind!,
    uncarer!,
    undefen!,
    unemploy!


export SS_Examples, cpl_w_2_children_hh, single_parent_hh, single_hh, childless_couple_hh, mbu

@enum SS_Examples cpl_w_2_children_hh single_parent_hh single_hh childless_couple_hh mbu

function get_ss_examples()::Dict{SS_Examples, Household}
    d = Dict{SS_Examples, Household}()
    @time names = ExampleHouseholdGetter.initialise()
    d[cpl_w_2_children_hh] = ExampleHouseholdGetter.get_household( "example_hh1" )
    d[single_parent_hh] = ExampleHouseholdGetter.get_household( "single_parent_1" )
    d[single_hh] = ExampleHouseholdGetter.get_household( "example_hh2" )
    d[childless_couple_hh] = ExampleHouseholdGetter.get_household("mel_c2_scot")
    d[mbu] =  ExampleHouseholdGetter.get_household("mbu_example")
    return d
end

const EXAMPLES = get_ss_examples()
const SPARE_CHILD = EXAMPLES[cpl_w_2_children_hh].people[320190000104]
const SPARE_ADULT = get_head( EXAMPLES[single_hh])
    
function unemploy!( pers::Person )
    pers.usual_hours_worked = 0
    pers.actual_hours_worked = 0
    pers.employment_status = Unemployed 
    delete!( pers.income, wages )  
    delete!( pers.income, self_employment_income ) 
 end
 
 function employ!( pers::Person, wage=600.00 )
    pers.usual_hours_worked = 40
    pers.actual_hours_worked = 40
    pers.employment_status = Full_time_Employee 
    pers.income[wages] = wage   
 end
 
 function disable_slightly!( pers::Person )
    pers.employment_status = Permanently_sick_or_disabled
    pers.health_status = Bad
    pers.has_long_standing_illness = true
    pers.adls_are_reduced = reduced_a_little
    pers.how_long_adls_reduced = v_12_months_or_more
    pers.disabilities[mobility] = true
    pers.disabilities[stamina] = true
 end
 
 function disable_seriously!( pers::Person )
    pers.employment_status = Permanently_sick_or_disabled
    pers.health_status = Very_Bad
    pers.has_long_standing_illness = true
    pers.adls_are_reduced = reduced_a_lot
    pers.how_long_adls_reduced = v_12_months_or_more
    pers.disabilities[mobility] = true
    pers.disabilities[stamina] = true
 end
 
 
 function enable!( pers::Person )
    pers.dla_mobility_type = missing_lmh
    pers.dla_self_care_type = missing_lmh
    pers.pip_mobility_type = no_pip
    pers.pip_daily_living_type = no_pip
    pers.health_status = Good
    pers.has_long_standing_illness = false
    pers.adls_are_reduced = not_reduced
    pers.how_long_adls_reduced = Missing_Illness_Length
    pers.disabilities = Disability_Dict{Bool}()
 end
 
 function blind!( pers :: Person )
    pers.disabilities[vision ] = true
    pers.registered_blind = true
 end
 
 function unblind!( pers :: Person )
    delete!(pers.disabilities, vision )
    pers.registered_blind = false
 end
 
 function deafen!( pers :: Person )
    pers.disabilities[ hearing ] = true
    pers.registered_deaf = true
 end
 
 function undeafen!( pers :: Person )
    delete!(pers.disabilities, hearing )
    pers.registered_deaf = false
 end
 
 function carer!( pers :: Person )
    pers.income[carers_allowance] = 100.0
    pers.is_informal_carer = true
    pers.hours_of_care_given = 10
    pers.employment_status = Looking_after_family_or_home
 end
 
 function uncarer!( pers :: Person )
    delete!(pers.income,carers_allowance)
    pers.is_informal_carer = false
    pers.hours_of_care_given = 0
 end
 
 function retire!( pers :: Person )
    pers.usual_hours_worked = 0
    pers.employment_status = Retired
 end
 
 # FIXME relationships fixup
 """
 Add a child to the 1st benefit unit
 """
 function add_child!( hh :: Household, age :: Integer, sex :: Sex )::BigInt
    head = get_head(hh)   
    np = deepcopy( SPARE_CHILD )
    empty!( np.income )
    np.relationships[head.pid] = Son_or_daughter_incl_adopted
    # TODO fill in other relationships
    np.default_benefit_unit = head.default_benefit_unit
    np.pid = maximum( keys( hh.people ))+1
    np.age = age
    np.sex = sex
    hh.people[ np.pid ] = np
    head.relationships[np.pid] = Parent
    spouse = get_spouse( hh )
    if spouse !== nothing
       spouse.relationships[np.pid] = Parent
    end
    # FIXME other adults in othe BUS
    make_eq_scales!( hh )
    return np.pid
 end
 
 function add_non_dependent!( 
    hh  :: Household, 
    age :: Integer, 
    sex :: Sex ) :: BigInt
 
    head = get_head(hh)
    np = deepcopy( SPARE_ADULT )
    bus = get_benefit_units( hh )
    nbus = size(bus)[1]
    np.pid = maximum( keys( hh.people ))+1
    np.relationships[head.pid] = Son_or_daughter_incl_adopted
    # TODO fill in other relationships
    np.age = age
    np.sex = sex
    np.default_benefit_unit = nbus + 1
    hh.people[ np.pid ] = np
    bus = get_benefit_units( hh )
    nnbus = size(bus)[1]
    @assert nnbus == nbus + 1
    @assert get_head( bus[nnbus] ) == np
    make_eq_scales!( hh )   
    return np.pid
 end
 
 function delete_person!( hh :: Household, pid :: BigInt )
    delete!( hh.people, pid )
    make_eq_scales!( hh )
 end
 
 function delete_child!( hh :: Household )
    chpids = child_pids( hh )
    if size(chpids)[1] > 0
       delete_person!( hh, chpids[1])
    end
    make_eq_scales!( hh )
 end
 
 """
  if the test was written at TEST_BASE_DATE, what age would we have to make somebody
  to be sure the test will still work in some later year?
 """
 function age_now( age :: Int ) :: Int
    yd = (Date(now()) - TEST_BASE_DATE).value ÷ 365 # leap years; no function for this
    return age + Int(yd)
 end
 
 function set_childrens_ages!( hh :: Household, ages ... )
    nc = length(ages)[1]
    nset = 0
    for (pid, pers) in hh.people
       if is_child(pers)
          nset = min( nc, nset+1)
          pers.age = ages[nset]
       end
    end
 end

"""

"""
function make_hh( 
    ;
    adults   :: Int = 1,
    children :: Int = 0,
    earnings :: Real = -1,
    rent     :: Real = -1,
    rooms    :: Int  = 4,
    age      :: Int = -1,
    spouse_age :: Int = -1,
    tenure   :: Tenure_Type = Private_Rented_Furnished ) :: Household
    hh = nothing
    if adults == 2
       if children > 0
          hh = deepcopy( EXAMPLES[cpl_w_2_children_hh])
       else
          hh = deepcopy( EXAMPLES[childless_couple_hh])
       end   
    elseif adults == 1
       if children > 0 
          hh = deepcopy( EXAMPLES[single_parent_hh])
       else
          hh = deepcopy( EXAMPLES[single_hh])
       end
    else
       error("can't do $adults adults yet")
    end
    hh.tenure = tenure
    hh.ct_band = Band_B
    num_kids = num_children( hh )
    if num_kids < children
       for i in (num_kids+1):children
          sex = (i % 2) == 0 ? Male : Female
          add_child!( hh, i, sex ) # use the counter as age
       end
    elseif num_kids > children
       delete_child!( hh )
    end
    nc = num_children( hh )
    na = num_adults( hh )
    @assert nc == children "num_childen=$nc but requested=$children"
    @assert na == adults "num_adults=$na but requested=$adults"
    head = get_head( hh )
    if age != -1
       head.age = age
    end
    if spouse_age != -1
       @assert na == 2 "need 2 adults for spouse age to be meaningful"
       sp = get_spouse( hh )
       sp.age = spouse_age
    end
    if earnings != -1
       head.income[wages] = earnings
    end
    if rent != -1
       hh.gross_rent = rent
    end
    make_eq_scales!( hh )
    return hh
 end
 
 #
 # quickie for making a default-ish pid
 #
 function makePID( hid::Int, year = 2018, pno=1 )::BigInt
    get_pid( FRS, year, hid, pno )
 end
 


end