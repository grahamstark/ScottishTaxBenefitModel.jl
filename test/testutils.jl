
import ScottishTaxBenefitModel.STBParameters:
   IncomeTaxSys, weeklyise!

import ScottishTaxBenefitModel.FRSHouseholdGetter: initialise, get_household, get_num_households



function get_default_it_system(
   ;
  year     :: Integer=2019,
  scotland :: Bool = true,
  weekly   :: Bool = true )::Union{Nothing,IncomeTaxSys}
  it = nothing
  if year == 2019
     it = IncomeTaxSys{Int,Float64}()
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

function init_data()
   if get_num_households() == 0
      @time nhh,total_num_people,nhh2 = initialise(
            household_name = "model_households_scotland",
            people_name    = "model_people_scotland",
            start_year = start_year )
   end
   (nhh,num_people)
end
