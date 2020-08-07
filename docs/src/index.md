```@meta
CurrentModule = ScottishTaxBenefitModel
```

# ScottishTaxBenefitModel

## A  Microsimulation Model of the Scottish Fiscal System

This is **in development**, has just been moved from an earlier version, and so will likely break in all sorts of unpleasant ways.

Please bear with me, or better still, help.

One quick note: my packages:

* [Budget Constraints](https://github.com/grahamstark/BudgetConstraints.jl);
* [Reweighting](https://github.com/grahamstark/SurveyDataWeighting.jl); and
* [Poverty & Inequality](https://github.com/grahamstark/PovertyAndInequalityMeasures.jl)

will have to be added manually using the URLs above until their registrations are accepted. This also breaks Travis since it can't parse the Project.toml file if it includes non-registered packages.

# Modules

```@index
```

```@autodocs
Modules = [
    ScottishTaxBenefitModel,
    Definitions.jl,
    ExampleHouseholdGetter.jl,
    FRSHouseholdGetter.jl,
    GeneralTaxComponents.jl,
    HouseholdFromFrame.jl,
    HouseholdMappingsFRS_HBAI.jl,
    IncomeTaxCalculations,jl,
    LegacyMeansTestedBenefits.jl,
    MiniTB.jl,
    ModelHousehold.jl,
    NationalInsuranceCalculations.jl,
    Results.jl,
    Runner.jl,
    SingleHouseholdCalculations.jl,
    Uprating.jl,
    STBParameters.jl,
    Weights.jl
    ]

## Test Suite 

## Data Notes

## Weighting

## Validation in Aggregate

## An Annotated Bibiography

## Coding Notes

## TODO



