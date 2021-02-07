---
layout: post
date:   2021-02-07
category: Blog
tag: Tax Benefit Model
tag: Scotland
tag: Programming
tag: Data Merging
title: Merging SHS and FRS Data
author: graham_s
nav_exclude: true
---

Some notes as I try to add some [Scottish Household Survey Data]() to my [FRS]() based dataset. 

<!--more-->

## Why?

Because a lot of my public access FRS is blank. In particular I've decided I can't really proceed 
with housing-related benefits modelling without [Local Housing Allowance](https://www.gov.scot/publications/local-housing-allowance-rates-2020-2021/) identifiers and council taxes. 
And these aren't in the public FRS datasets I use.

Plus, there's loads of good stuff about housing, heating and transport in the SHS which might be useful later on.

## HOW

There's some theory about this, and some software; see [King et.
al](https://gking.harvard.edu/publications/cem-software-coarsened-exact-matching), [EuroStat](https://ec.europa.eu/eurostat/documents/3888793/5855821/KS-RA-13-020-EN.PDF/477dd541-92ee-4259-95d4-1c42fcf2ef34?version=1.0)
 and the [StatMatch](https://cran.r-project.org/web/packages/StatMatch/]) software.

I'd really like to replicate StatMatch in Julia.

For now, I'm using a rather hacked, ad-hoc implementation based on King's [Coarsened Exact Matching](https://academic.oup.com/aje/article/189/6/613/5679490) idea.

There's a large literature on matching more generally, used as a technique in evaluation studies, but I don't think much of it is useful for what I'm after here.
[Propensity Score Matching](https://www.ncrm.ac.uk/resources/video/RMF2012/whatis.php?id=c776e30) is fun - and I'd also like to implement a Julia version, but the kind of matching produced isn't really useful here, since it matches on scores and not characteristics (a white young male could get matched with a black old female
if they have the same score - we need to aviod that, I think).

So I'm just using an hand-coded matching thing - select records from SHS and FRS based on a bunch of characteristics,
but just use a hand-written program. 'Coarsened' here means progressively widening and then dropping characteristics if
there are no perfect matches; for example, we might match by tenure type, but if there's no private renter in the SHS
amonst those that match on ouseful characteristics, we might find one that rents in any way (e.g. from a council) or, in
extremis, drop tenure type as a matching criterial for that observation.



