module ScottishTaxBenefitModel

#
# A microsimulation tax benefit model of Scotland.
# Work in progress.
#

__precompile__(true)

include("Utils.jl" )
export Utils

include("Definitions.jl" )
export Definitions

include("DataUtils.jl" )
export DataUtils

include("GeneralTaxComponents.jl" )
export GeneralTaxComponents

include("MiniTB.jl" )
export MiniTB

include("Uprating.jl" )
export Uprating

include("ModelHousehold.jl" )
export ModelHousehold

include("HouseholdFromFrame.jl" )
export HouseholdFromFrame

include("ExampleHouseholdGetter.jl" )
export ExampleHouseholdGetter

include("FRSHouseholdGetter.jl" )
export FRSHouseholdGetter

include("STBParameters.jl" )
export STBParameters

include("IncomeTaxCalculations.jl" )
export IncomeTaxCalculations

include("NationalInsuranceCalculations.jl" )
export NationalInsuranceCalculations


include( "Results.jl")
export Results

include("SingleHouseholdCalculations.jl" )
export SingleHouseholdCalculations

include("WebModelLibs.jl" )
export WebModelLibs

end
