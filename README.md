# A  Microsimulation Model of the Scottish Fiscal System

## This is in development and not ready for use

A Tax Benefit Model is a computer program that calculates the effects of possible changes to the fiscal system, for example tax increases or cash benefit reforms. 

We take a dataset with information on incomes, demographics, spending, etc. for a representative
sample of households. The model loops over the households in the dataset, calculating for each one how much tax the household members are liable for, and how much they are due in benefits. If the sample dataset is representative of the population, and the modelling sufficiently accurate, the model can then tell you what the effects of some tax change or benefit reform would be: the total cost, the how many people would be made better or worse off, the effective tax rates faced by
different individuals, how many households are taken in and out of poverty, whether inequality is increased or lessened, and much else.

This is a Tax Benefit Model for Scotland. To my knowledge, this is the first model specifically built for Scotland, and
the first fully Open Source one anywhere. It is designed to use data from the [Family Resources Survey](https://www.ons.gov.uk/surveys/informationforhouseholdsandindividuals/householdandindividualsurveys/familyresourcessurvey), possibly
augmented by other datasets later on.

For more information, try the following:

* I've started a [blog about the model](https://stb-blog.virtual-worlds.scot/). Pretty much stream of consciousness stuff as I write the model;
* A [short course on the ideas behind the model](https://stb.virtual-worlds.scot/intro.html), originally written for the UK's Open University;
* .. the course includes an [interactive section](https://stb.virtual-worlds.scot/tax-benefit-tour.html), using a very preliminary demo version of the model - **DONT USE FOR ANYTHING OTHER THAN PLAYING WITH**;
* .. also a section on [Budget Constraints](https://stb.virtual-worlds.scot/bc-intro.html);
* some Julia registered packages I've written containing model components:
  - A generator for [budget constraints](https://github.com/grahamstark/BudgetConstraints.jl);
  - Routines for [survey data weighting](https://github.com/grahamstark/SurveyDataWeighting.jl);
  - Various standard [measures of poverty & inequality](https://github.com/grahamstark/PovertyAndInequalityMeasures.jl).

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://grahamstark.github.io/ScottishTaxBenefitModel.jl/dev)
[![Build Status](https://travis-ci.com/grahamstark/ScottishTaxBenefitModel.jl.svg?branch=master)](https://travis-ci.com/grahamstark/ScottishTaxBenefitModel.jl)
[![Coverage](https://codecov.io/gh/grahamstark/ScottishTaxBenefitModel.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/grahamstark/ScottishTaxBenefitModel.jl)
