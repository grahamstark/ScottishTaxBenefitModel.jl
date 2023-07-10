using ScottishTaxBenefitModel
using .FRSHouseholdGetter: initialise, get_household, get_num_households
using .STBParameters:
    TaxBenefitSystem,
    NationalInsuranceSys,
    IncomeTaxSys,
    weeklyise!,
    make_ubi_pre_adjustments!,
    load_file,
    load_file!

import .Results: init_benefit_unit_result, BenefitUnitResult
using .ModelHousehold: 
   BenefitUnit, 
   Household, 
   Person,    
   child_pids,
   get_head,
   is_child,
   num_adults, 
   num_children,
   make_eq_scales!

using .Definitions
import .ExampleHouseholdGetter

using .RunSettings: Settings

using .ExampleHelpers

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

function init_data(; reset :: Bool = false, settings = Settings() )
   nhh = get_num_households()
   num_people = -1
   if( nhh == 0 ) || reset 
      @time nhh, num_people,nhh2 = initialise( settings )
   end
   (nhh,num_people)
end


function getSystem(; scotland::Bool ) :: TaxBenefitSystem
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
   if ! sys.ubi.abolished
      make_ubi_pre_adjustments!( sys )
   end
   return sys
end

function get_uk_system(; year = 2023 ) :: TaxBenefitSystem
   sys = nothing
   if year == 2023
      # FIXME 
      load_file!( sys, "$(MODEL_PARAMS_DIR)/sys_2023_24_ruk.jl")
      weeklyise!(sys)
      return sys
   end
end

function get_system( ; year, scotland = true )  :: TaxBenefitSystem
   sys = nothing
   if year == 2022
      sys = load_file("$(MODEL_PARAMS_DIR)/sys_2022-23.jl" )
      if ! scotland
         sys.scottish_child_payment.amount = 0.0
         sys.scottish_child_payment.maximum_age = 0
         sys.scottish_child_payment.qualifying_benefits = []
         sys.nmt_bens.carers.scottish_supplement = 0.0
      end
   elseif year == 2023
      sys = load_file( "$(MODEL_PARAMS_DIR)/sys_2023_24_ruk.jl")
      if scotland
         load_file!( sys, "$(MODEL_PARAMS_DIR)/sys_2023_24_scotland.jl")
      end
   else
      return getSystem( scotland=scotland )
   end 
   weeklyise!(sys)
   return sys
end

    
function init_benefit_unit_result( bu :: BenefitUnit ) :: BenefitUnitResult
   return init_benefit_unit_result( DEFAULT_NUM_TYPE, bu )
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

"""
if the test was written at TEST_BASE_DATE, what age would we have to make somebody
to be sure the test will still work in some later year?
"""
function age_now( age :: Int ) :: Int
  yd = (Date(now()) - TEST_BASE_DATE).value ÷ 365 # leap years; no function for this
  return age + Int(yd)
end
