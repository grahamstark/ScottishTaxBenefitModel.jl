module ScottishTaxBenefitModel

#
# A microsimulation tax benefit model of Scotland.
# Work in progress.
#

# __precompile__(true)

include("Utils.jl" )
export Utils

include( "TimeSeriesUtils.jl" )
export TimeSeriesUtils

include("Definitions.jl" )
export Definitions

include("Incomes.jl")
export Incomes

include( "EquivalenceScales.jl")
export EquivalenceScales

include("GeneralTaxComponents.jl" )
export GeneralTaxComponents

include("Uprating.jl" )
export Uprating

include("ModelHousehold.jl" )
export ModelHousehold

include( "HistoricBenefits.jl")
export HistoricBenefits

include("HouseholdFromFrame.jl" )
export HouseholdFromFrame

include("ExampleHouseholdGetter.jl" )
export ExampleHouseholdGetter

include("FRSHouseholdGetter.jl" )
export FRSHouseholdGetter

include("STBParameters.jl" )
export STBParameters

include( "Intermediate.jl")
export Intermediate

include( "Results.jl")
export Results

include( "NonMeansTestedBenefits.jl")
export NonMeansTestedBenefits

include("IncomeTaxCalculations.jl" )
export IncomeTaxCalculations

include("NationalInsuranceCalculations.jl" )
export NationalInsuranceCalculations

include("LocalLevelCalculations.jl" )
export LocalLevelCalculations

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

end
