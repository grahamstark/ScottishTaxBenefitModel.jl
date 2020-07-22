using ScottishTaxBenefitModel.FRSHouseholdGetter: initialise, get_household, get_num_households
using ScottishTaxBenefitModel.STBParameters:
    TaxBenefitSystem,
    NationalInsuranceSys,
    IncomeTaxSys,
    get_default_it_system
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
   nhh = get_num_households()
   num_people = -1
   if nhh == 0
      @time nhh, num_people,nhh2 = initialise(
            household_name = "model_households_scotland",
            people_name    = "model_people_scotland" )
   end
   (nhh,num_people)
end


function get_system( scotland = false ) :: TaxBenefitSystem
    tb = TaxBenefitSystem{Int,Float64}()
    println( tb.it )
    # overwrite IT to get RuK system as needed
    itn :: IncomeTaxSys{Int,Float64} = get_default_it_system( year=2019, scotland=scotland, weekly=true )
    # println( itn )
    tb.it = itn
    tb
end
