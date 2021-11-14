---
layout: post
date:   2021-11-14
category: Blog
tag: Tax Benefit Model
tag: Scotland
tag: Programming
tag: Benefits
tag: Budget Constraints 
tag: Incentives
title: Scotland's Kinkiest Families
author: graham_s
nav_exclude: true
---

I've finally put [some of this model out into the world](https://stb.virtual-worlds.scot/bcd/) - to almost zero response so far, but that's OK.

<!--more-->

This was originally just a testing exercise. The [Budget Constraint generator](https://github.com/grahamstark/BudgetConstraints.jl) has always been a great way of ferreting out all the weirdness in a model: it finds all the discontinuities, marginal effective tax rates (METRs) that go the 'wrong' way.

Like this one:

![Weird Budget Constraint](/assets/weird_bc.png)

This shows the gross/net income relationship for a family with 7 children and £270pw in housing costs, living in a council house. So a pretty unusual family, but still.. Both the legacy system (red) and UC (greeen) are shown.

There's a lot going on here. Key things are:

* [Benefit Cap](https://www.gov.uk/benefit-cap). This limits the amount of  benefits received, but not for Working Tax Credit recipients (Legacy) and only for those earning below £617pm (UC). Hence the big jumps upward at the points where the family qualifies for WTC or earns £617, and back down in the Legacy case when WTC entitlement is exausted. 
* The downward sections on the right are a combination of child benefit withdrawal over £50,000 per year (50%), higher rate income tax, and UC/WTC withdrawal (these can go surprisingly high up for large families). 
* There are other weird ones, too, like the interaction between the Discresionary Housing Payments the Scottish government use to [ameliorate the Bedroom Tax](https://www.gov.scot/policies/social-security/support-with-housing-costs/) and the benefit cap - these combined can produce *negative* marginal tax rates.
