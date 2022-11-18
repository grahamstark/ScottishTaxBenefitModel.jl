module ScottishTaxBenefitModel

#
# A microsimulation tax benefit model of Scotland.
#
# This is the `parent module` that just imports (and re-exports) all its child modules.
#

include("Utils.jl" )
export Utils

include( "Randoms.jl")
export Randoms

include( "Monitor.jl")
export Monitor

include( "TimeSeriesUtils.jl" )
export TimeSeriesUtils

include("Definitions.jl" )
export Definitions

include( "RunSettings.jl" )
export RunSettings

include("STBIncomes.jl")
export STBIncomes

include( "EquivalenceScales.jl")
export EquivalenceScales

include("GeneralTaxComponents.jl" )
export GeneralTaxComponents

include("Uprating.jl" )
export Uprating

include("ModelHousehold.jl" )
export ModelHousehold

include("Weighting.jl" )
export Weighting

include( "HistoricBenefits.jl")
export HistoricBenefits

include( "Pensions.jl")
export Pensions

include("HouseholdFromFrame.jl" )
export HouseholdFromFrame

include("ExampleHouseholdGetter.jl" )
export ExampleHouseholdGetter

include("FRSHouseholdGetter.jl" )
export FRSHouseholdGetter

include("STBParameters.jl" )
export STBParameters

include( "BenefitGenerosity.jl")
export BenefitGenerosity

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

include( "UniversalCredit.jl")
export UniversalCredit

include( "ScottishBenefits.jl")
export ScottishBenefits

include( "BenefitCap.jl" )
export BenefitCap

include( "UCTransition.jl")
export UCTransition

include( "UBI.jl")
export UBI

include("SingleHouseholdCalculations.jl" )
export SingleHouseholdCalculations

include( "ExampleHelpers.jl")
export ExampleHelpers

include( "BCCalcs.jl")
export BCCalcs

include( "SimplePovertyCounts.jl")
export SimplePovertyCounts

# pro. tem include("WebModelLibs.jl" )
# export WebModelLibs

include( "STBOutput.jl")
export STBOutput

include( "Runner.jl" )
export Runner

include( "TheEqualiser.jl" )
export TheEqualiser

include( "Expenditure.jl")
export Expenditure

include( "Affordability.jl")
export Affordability

end
