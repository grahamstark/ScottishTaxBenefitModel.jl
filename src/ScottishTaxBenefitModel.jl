module ScottishTaxBenefitModel

#
# A microsimulation tax benefit model of Scotland.
# Work in progress.
#

__precompile__(true)

include("Utils.jl" )
export Utils

include( "TimeSeriesUtils.jl" )
export TimeSeriesUtils

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

include( "Results.jl")
export Results

include("IncomeTaxCalculations.jl" )
export IncomeTaxCalculations

include("NationalInsuranceCalculations.jl" )
export NationalInsuranceCalculations

include("LegacyMeansTestedBenefits.jl" )
export LegacyMeansTestedBenefits

include("SingleHouseholdCalculations.jl" )
export SingleHouseholdCalculations

# pro. tem include("WebModelLibs.jl" )
# export WebModelLibs

include( "Weighting.jl")
export Weighting

include( "Runner.jl" )
export Runner

# include( "ParamsIO.jl" )
# export ParamsIO

end
