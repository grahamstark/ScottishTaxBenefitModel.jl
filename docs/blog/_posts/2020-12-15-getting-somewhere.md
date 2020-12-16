---
layout: post
date:   2020-12-15
category: Blog
tags: Tax Benefit
title: Getting Somewhere, and a Mild Rant
author: graham_s
---

.. 3 months later.

The Covid test I mentioned last time was negative. But 4 weeks ago I had another test, just on a vague feeling, and that
one was positive. So it's been a tricky few weeks. I'll maybe write an entire entry on this. 

On the model: I've been fitting it in amongst paid work, so progress is slower than I'd like. 

<!--more-->

I've been doing 'Legacy Means-Tested Benefits' - Pension Credit, Working Tax Credit and the like. It's been a chore. I
haven't worked on this stuff in many years and I was shocked at how complicated it all was. One problem is that the main
reference, the [Child Poverty Action Group's Welfare Right's
Handbook](https://cpag.org.uk/shop/cpag-titles/welfare-benefits-tax-credits-handbook-202021) is - sorry to say this - an
incoherent mess. It's *enormous*. Here's a comparison between an old 86/87 CPAG guide I have from my IFS days, and the
2019/20 version I've been using for reference:

![CPAG Guides 2019/20 vs 1985/6](/assets/img/cpag_2019-1986.jpg)

1,847 pages vs 252. The welfare system has clearly got more much complicated since the 80s, and currently there are two
means-tested systems running in parallel - Universal Credit and the old benefits.

But a lot of the increase is down to the sheer amount of repitition in the current Guide. And information is scattered
around. I've always been a huge admirer of the CPAG, back from when I first started working on this stuff in the '80s,
so it pains me to say this.

The [code I've written](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/LegacyMeansTestedBenefits.jl) follows the CPAG stucture 
probably too closely - so a section trying to route people to the correct benefit, then a section on incomes, then allowances. Probably neater just to 
have a complete model of each benefit. 

The CPAG book has very few worked examples, so creating unit tests is tricky. I guess they want to keep worked examples
for the courses they sell. The [tests I have so
far](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/test/legacy_mt_tests.jl) are not at all where
I'd want them to be. I've spent a good deal of time on
[various](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/docs/uc_test_cases.ods) [benefit
calculators](https://betteroffcalculator.co.uk/calculator/new/step1) generating [a spreadsheet of test
cases](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/docs/uc_test_cases.ods). Next step is to
convert these to unit tests. These calculators are such black-boxes that this will be tedious since I don't know the
exact assumptions they are using.

I only really nailed the income tax/ni parts of this model when I discovered the [Melville
Book](https://www.pearson.com/uk/educators/higher-education-educators/program/Melville-Melville-s-Taxation-Finance-Act-2019-25th-Edition/PGM2646808.html)
and there must be a market for something roughly similar for the benefit system.

