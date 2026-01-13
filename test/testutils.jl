using ScottishTaxBenefitModel
using .FRSHouseholdGetter: initialise, get_household, get_num_households
using .STBParameters:
    TaxBenefitSystem,
    NationalInsuranceSys,
    IncomeTaxSys,
    weeklyise!,
    make_ubi_pre_adjustments!,
    get_default_system_for_date,
    get_default_system_for_cal_year,
    get_default_system_for_fin_year
using Observables
using .Monitor: Progress
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
using .Utils:date_string
using .Runner: do_one_run

using .Definitions
import .ExampleHouseholdGetter
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames!, make_gain_lose

using .RunSettings: Settings, get_all_uk_settings_2023

using .ExampleHelpers

using DataFrames,CSV, Dates

#
# full dataset is available .. 
# 
const IS_LOCAL = true # isdir("/mnt/data/frs/")

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
   pdiff = 0.01*ps
   if diff > pdiff
      throw( ErrorException( "x=$x y=$y aren't within $(pdiff)p diff is |$diff|")) 
   end
   # round(x, digits=2) == round(y, digits=2)
   return true
end

function init_data(; reset :: Bool = false, settings = Settings() )
   nhh = get_num_households()
   num_people = -1
   if( nhh == 0 ) || reset 
      @time nhh, num_people,nhh2 = initialise( settings; reset=reset )
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
   @assert sys.scottish_child_payment.amounts[1] > 0
   if ! scotland
      sys.scottish_child_payment.amounts = [0.0]
      sys.scottish_child_payment.maximum_ages = [0]
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
      sys = get_default_system_for_fin_year( 2023, scotland=false )
      return sys
   end
end

function get_system( ; year, scotland = true ) :: TaxBenefitSystem
   sys = get_default_system_for_fin_year( year; scotland=scotland )      
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
   try 
      diff = to_nearest_p( uspw, thempw, ps )
   catch e
      throw( ErrorException("us $(uspw)pw ($(uspm)pm) != $(thempm)pm $e"))
   end
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

# Observer as a global.
tot = 0
defsettings = get_all_uk_settings_2023()
    
# observer = Observer(Progress("",0,0,0))
obs = Observable( Progress(defsettings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
    println(tot)
end

function do_basic_run( settings :: Settings, sys :: Vector; reset :: Bool ) :: Tuple
   global tot
   tot = 0
   # force reset of data to use UK dataset
   settings.num_households, settings.num_people, nhh2 = 
       FRSHouseholdGetter.initialise( settings; reset=reset )
   results = do_one_run( settings, sys, obs )
   h1 = results.hh[1]
   settings.poverty_line = make_poverty_line( results.hh[1], settings )
   dump_frames( settings, results )
   println( "poverty line = $(settings.poverty_line)")
   summary = summarise_frames!( results, settings )
   return (summary, results, settings )
end

function do_basic_uk_run( ; reset = true )::Tuple
   settings = get_all_uk_settings_2023()
   settings.run_name="all-uk-run-$(date_string())"
   settings.requested_threads = 4
   sys = [get_system(year=2023, scotland=false), get_system(year=2023, scotland=false)]
   return do_basic_run( settings, sys, reset = reset )
end

#
# This needs to match the path in the default run settings.
#
tmpdir = joinpath( homedir(), "tmp", "test-output" )
if ! isdir( tmpdir )
   mkpath( tmpdir )
end
