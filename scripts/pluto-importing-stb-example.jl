### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ bb28a1be-25cb-11ec-3a42-a3577c700396
begin
	import Pkg;Pkg.add( url="https://github.com/grahamstark/ScottishTaxBenefitModel.jl")
	using ScottishTaxBenefitModel
	
	using Plots
end

# ╔═╡ b9c7ccae-afbd-4e15-b508-44bc0803bdab
begin
	using Test
    using .ModelHousehold
	using .STBParameters
	using .STBIncomes
	using .Definitions
	using .GeneralTaxComponents
	using .SingleHouseholdCalculations
	using .RunSettings
	using .Utils	
end

# ╔═╡ 9b44570c-bd0f-427a-bdbb-497737ede8cc
begin
	# sys21_22 = load_file( "../params/sys_2021_22.jl" )
	using DataFrames,CSV, Dates
	#
# full dataset is available .. 
# 
const IS_LOCAL = isdir("/mnt/data/frs/")

# pids for example people
# see make_pid 
const RUK_PERSON = 320190010101

const SCOT_HEAD = 320190010201
const SCOT_SPOUSE = 320190010202

const DEFAULT_NUM_TYPE = Float64

const TEST_BASE_DATE = Date( 2021, 06, 14 ) # All the tests ran on this date; `TEST_BASE_DATE` is used
   # to adjust some ages e.g. social_security_ages_tests.jl so tests also pass next year.
 
function get_default_it_system(
   ;
  year     :: Integer=2019,
  scotland :: Bool = true,
  weekly   :: Bool = true )::Union{Nothing,IncomeTaxSys}
  it = nothing
  if year == 2019
     it = IncomeTaxSys{DEFAULT_NUM_TYPE}()
     if ! scotland
        it.non_savings_rates = [20.0,40.0,45.0]
        it.non_savings_thresholds = [37_500, 150_000.0]
        it.non_savings_basic_rate = 1
     end
     if weekly
        weeklyise!( it )
     end
  end
  it
end

function get_default_uc( ;
   year :: Integer = 2019,
   weekly :: Bool = true )
   uc = UniversalCreditSys{DEFAULT_NUM_TYPE}()
   if weekly
      weeklyise!( uc )
   else
      uc.taper /= 100 
   end
   return uc
end

function to_nearest_p( x, y :: Real, ps :: Real = 1 ) :: Bool
   diff = abs(x-y)
   return diff <= 0.01*ps
   # round(x, digits=2) == round(y, digits=2)
end

function init_data(; reset :: Bool = false )
   nhh = get_num_households()
   num_people = -1
   if( nhh == 0 ) || reset 
      @time nhh, num_people,nhh2 = initialise( Settings() )
   end
   (nhh,num_people)
end


function get_system(; scotland::Bool ) :: TaxBenefitSystem
   sys = TaxBenefitSystem{DEFAULT_NUM_TYPE}()
   weeklyise!(sys)
   # overwrite IT to get RuK system as needed
   # println( itn )
   sys.it = get_default_it_system( year=2019, scotland=scotland, weekly=true )
   #
   # So, assuming that the default has these things set ... 
   #
   @assert sys.scottish_child_payment.amount > 0
   if ! scotland
      sys.scottish_child_payment.amount = 0.0
      sys.scottish_child_payment.maximum_age = 0
      sys.scottish_child_payment.qualifying_benefits = []
      sys.nmt_bens.carers.scottish_supplement = 0.0
   end
   return sys
end

@enum SS_Examples cpl_w_2_children_hh single_parent_hh single_hh childless_couple_hh mbu

function get_ss_examples()::Dict{SS_Examples, ModelHousehold.Household}
    d = Dict{SS_Examples, Household}()
    @time names = ExampleHouseholdGetter.initialise(settings=settings)
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
function add_child!( hh :: ModelHousehold.Household, age :: Integer, sex :: Sex )::BigInt
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
    
function init_benefit_unit_result( bu :: BenefitUnit ) :: BenefitUnitResult
   return init_benefit_unit_result( DEFAULT_NUM_TYPE, bu )
end

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

#
# Messing around with periods to fit the Policy In Practice 
# calculator.
#
const POLICY_IN_PRACTICE_WEEKS_PER_MONTH = 52/12 
const PWPM = POLICY_IN_PRACTICE_WEEKS_PER_MONTH

"""
Compare PIP monthly calculations with our weekly, using their 52/12 weeks per month.
Throw an AssertionException if different, so we can use this directly
in a @test macro.
"""
function compare_w_2_m( uspw::Real, thempm::Real, ps :: Real = 1 ) :: Bool
   uspm = uspw*PWPM
   thempw = thempm/PWPM
   @assert to_nearest_p(uspw,thempw,ps) "us $(uspw)pw ($(uspm)pm) != $(thempm)pm"
   return true
end

sys21_22 = load_file( "../params/sys_2021_22.jl" )
	
	weeklyise!( sys21_22; wpy=52, wpm=PWPM  )
end

# ╔═╡ Cell order:
# ╠═bb28a1be-25cb-11ec-3a42-a3577c700396
# ╠═b9c7ccae-afbd-4e15-b508-44bc0803bdab
# ╠═9b44570c-bd0f-427a-bdbb-497737ede8cc
