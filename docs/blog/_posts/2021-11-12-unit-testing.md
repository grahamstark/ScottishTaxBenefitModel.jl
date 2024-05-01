---
layout: post
date:   2021-11-13
category: Blog
tag: Tax Benefit Model
tag: Scotland
tag: Programming
tag: Unit Testing
title: Testing, Testing 
author: graham_s
nav_exclude: true
---

The model now has a [huge test suite](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/tree/master/test), all of which passes, but I worry about test coverage still. 

<!--more-->

The lack of worked examples of benefit calculations in either the [CPAG Guides](https://cpag.org.uk/shop/cpag-titles/welfare-benefits-tax-credits-handbook-202122) or the online guides from [the Government](https://www.gov.uk/browse/benefits), [Shelter](https://scotland.shelter.org.uk/), [Age UK](https://www.ageuk.org.uk/information-advice/money-legal/benefits-entitlements/) and the rest is a real problem. I'n guessing the incentive here is to upsell training courses on this stuff.

Instead, I've been testing against an [online calculator](https://policyinpractice.co.uk/benefit-budgeting-calculator/) from [Policy in Practice](https://policyinpractice.co.uk). As someone who [used to write this sort of thing](https://www.virtual-worlds.scot/demonstrations/), I have to say the PiP calculator is really very well designed and easy to use. 

It's a slightly frustrating task as comparing against another calculator means you need pretty much the whole model completed before you can start, rather than test-as-you-write against each component, which I'd prefer (there's a lot of test-as-you go, but it's not very thorough). Testing against the calculator, there are some minor niggles that needed sorting out, like how many weeks are there in a year (not as obvious as you might think)? But testing against PiP was a really productive experience, at first turning up some really embarrassing errors I'd made, and then eventually getting to the point where I felt I was slightly ahead of them (my income tax calculations are a bit more complete in obscure corner cases, for instance).

I still don't think there are enough tests though. For instance, my [inequality routines](https://github.com/grahamstark/PovertyAndInequalityMeasures.jl) broke badly when confronted by real data with negative incomes in it, despite passing a pretty large test suite based on worked examples from [the World Bank](http://documents.worldbank.org/curated/en/488081468157174849/Handbook-on-poverty-and-inequality) (a few of the the world bank ones were wrong, incidentally).

One very good testing technique for a model like this is to drive a [budget constraint generator](https://github.com/grahamstark/BudgetConstraints.jl) through it and see if the results can be rationalised - the generator homes right in on all the wierd stuff - net incomes that drop off a cliff with small increments to wages, marginal tax rates over 100 or less than zero. [Scotben is now doing very well there](https://stb.virtual-worlds.scot/bcd/), at least to the extent that I understand how all the interactions are supposed to work. I'll write about that next.

On the process of testing, I've been reading the [Google Testing on the Toilet Door Series](https://testing.googleblog.com/2007/01/introducing-testing-on-toilet.html) - recommended. My test suite would not do well against Google's principles but it's the best I can do on my own to this timescale.
