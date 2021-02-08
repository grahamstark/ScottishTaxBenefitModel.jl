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

So I'm just using an hand-coded matching thing - select records from SHS (the Donor) and FRS (the Recipient) based on a
bunch of characteristics, but just use a hand-written program. 'Coarsened' here means progressively widening and then
dropping characteristics if there are no perfect matches; for example, we might match by tenure type, but if there's no
private renter in the SHS amonst those that match on ouseful characteristics, we might find one that rents in any way
(e.g. from a council) or, in extremis, drop tenure type as a matching criterial for that observation.

[This video]() is a good intro. 

Our strategy has to be slightly different:

* Matching in evaluation is usually done only over observations that actually match (have 'common support' in the jargon - if some bins have just one side (treated/donor, etc.) or some propensity scores don't match, those observations are dropped, but
we have to match for every FRS observation since we never want to lose observations). So for some, we might just use a bad match; 
* some matches may be catastrophic - assigning a male health record to a female, for example; 
* Coarsened matching coarsens across all observations the same (all renting for everyone, even if using private renting works for some), but we might want tight matches where
available

## Li-Chung-ing 

This is idea suggested to us on a previous project by [Li-Chun
Zhang](https://www.southampton.ac.uk/demography/about/staff/lz1n11.page) of the University of Southampton.

We can get an idea of the errors produced by this procedure by recording not just the best match but progressively
more coarsened matches, and then using all the matches in your simulation - bootstrapping of a sort. 

## SHS (Donor) Side

SHS has a seriously weird stucture. Not everyone in a household is sampled - instead there's a randomly chosen person
and there's also a bunch of stuff for the ['highest income person'](). 

### Household Characteristics

The object initially is to match in *household* records. In future I might match in individual level stuff (health, transport)
in which case we'll need to match a bit differently (include gender, for example, de-emphasise household characterists ike accomodation type)

* Sheltered Home
* Tenure Type
* Accomodation type

* Num Adults
* Num Children (u 16)
* Num Working in HH
* Num Pensioners (over 65s, 80s)
* Single Parent flag

* CTB Receipt - hhld
* ... not easy to use HB/IS/ receipt because of transition to UC
* Disabilility Benefits Receipt - any person
* Any MT Ben Receipt

### Highest earner

* Employment status 
* Age
* .. not gender, for these purposes
* Health
* marital status

For coarsening, the order these are introduced matters.

I don't think there's any high theory for how to choose matching variables.

Here's some quick and dirty code for this:

```julia

"""
finds the matches in a single recipient tuple `recip` in a data set `donor`.

each of the recip and donor should be structured as follows

firstvar_1, firstvar_2, firstvar_2 <- progressively coarsened first variable with the `_1` needed exactly as is;
then secondvar_1 .. thirdvar_1 .. _2 and so on. Variables can actually be in any order in the frame.

`vars` list of `firstvar`, `secondvar` and so on, in the order you want them coarsened
`max_matches` - stop after making these matches
`max_coarsens` stop after _2, _3 coarsened variables.

returns a tuple:
     matches->indexes of rows that match
     qualities->index for each match of how coarse the match is (+1 for each coarsening step needed for this match)
"""
function coarse_match( 
    recip :: DataFrameRow, 
    donor :: DataFrame, 
    vars  :: Vector{Symbol},
    max_matches :: Int,
    max_coarsens :: Int ) :: NamedTuple
    nobs = size( donor )[1]
    nvars = size( vars )[1]
    c_level = ones(Int,nvars)
    qualities = zeros(Int,nobs)
    quality = 1
    prevmatches = fill( false, nobs )
    matches = fill( true, nobs )
    for nc in 1:max_coarsens
        for nv in 1:nvars
            matches = fill( true, nobs )
            for n in 1:nvars
                # so, if sym[1] = :a and c_level[1] = 1 then :a_1 and so on
                sym = Symbol("$(String(vars[n]))_$(c_level[n])") # everything
                matches .&= (donor[sym] .== recip[sym])            
            end
            newmatches = matches .⊻ prevmatches # mark new matches with current quality   ⊻
            # println( "quality $quality\nmatches $matches\n prevmatches $prevmatches\n newmatches $newmatches\n" )
            qualities[newmatches] .= quality
            quality += 1
            c_level[nv] = min(nc+1, max_coarsens)
            prevmatches = copy(matches)
            if sum(matches) >= max_matches
                return (matches=matches,qualities=qualities)
            end
        end # vars
    end # coarse
    return (matches=matches,qualities=qualities)
end

```

