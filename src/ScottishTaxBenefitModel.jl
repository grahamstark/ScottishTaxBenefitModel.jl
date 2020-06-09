module ScottishTaxBenefitModel

##  for Travis - must be a better way ...
if ! ( "src/" in LOAD_PATH )
    push!( LOAD_PATH, "src/")
end

import Definitions
import ExampleHouseholdGetter
import FRSHouseholdGetter
import GeneralTaxComponents
import HouseholdFromFrame
import IncomeTaxCalculations
import MiniTB
import ModelHousehold
import STBParameters
import SingleHouseholdCalculations
import Uprating
import WebModelLibs
import household_mapping_frs



end
