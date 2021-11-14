---
layout: post
date:   2021-09-07
category: Blog
tag: Tax Benefit Model
tag: Scotland
tag: Programming
tag: Benefits
tag: Disability
title: Scottish Disability Benefits
author: graham_s
nav_exclude: true
---

A series of new [Scottish disability benefits](https://www.gov.scot/policies/social-security/benefits-disabled-people-ill-health/) are [moving towards implementation](). 

Kind of the point of this model is to capture changes like this. 

<!--more-->

These are tricky to model. The [Social Security Scotland documents](https://www.gov.scot/publications/consultation-adult-disability-payment/) stay that the initial intention is that the new benefits mirror exactly the entitlements to DLA, PIP and Attendance Allowance that they replace, but with less intrusive examinations. So in principle, from our high level, we can just relabel existing DLA/Pip receipts and we're done. But the [Scottish Fiscal Commission think the new benefits will end up being more generous](https://www.fiscalcommission.scot/publications/how-we-forecast-social-security-disability-and-carers-payments-may-2021/). We'll just have to see, but clearly we need some modelling of the generosity of the disability tests. This is hard-ish because, although the FRS has a series of disability questions, they don't follow the [ones used in current tests](https://www.gov.uk/government/publications/personal-independence-payment-fact-sheets/pip-handbook#assessment-criteria), and likely not the evential SBA tests. In the event, I've just [run some Probits](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/tree/master/regressions) on FRS recorded DLA/PIP/AA receipt against the FRS disability indicators and a few other demographics. 

The module [BenefitGenerosity.jl](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/BenefitGenerosity.jl) uses these probits to adjust disability benefit receipt up and down depending on some user supplied estimate of total extra numbers entitled. This seems to be [the same in spirit to how the SFC models this](https://www.fiscalcommission.scot/publications/how-we-forecast-social-security-disability-and-carers-payments-may-2021/). To minimise disruption to the data, instead of basing all entitlements on the highest modelled receipt probabilities from the probits, we instead construct a list of most current non-recipients with highest probabilities, and add those when making the benefits more generous, and likewise a list of the current recipients with the lowest probabilities, and remove those if the tests are modelled as more severe. I'm sure a proper statistician would find lots to fault here, but it seems the procedure that captures what we want whilst distrupting the data least.
