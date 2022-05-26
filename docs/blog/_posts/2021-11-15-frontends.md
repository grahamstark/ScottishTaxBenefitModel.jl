---
layout: post
date:   2021-11-13
category: Blog
tag: Tax Benefit Model
tag: Scotland
tag: Programming
title: Frontends
author: graham_s
nav_exclude: true
---

This thing isn't going to be of much general use if people can't interact with it.

<!--more-->

One big advantage is that SB has a nice modular structure. Running accross a single houseold is one simple function call

```julia

function do_one_calc( 
    hh :: Household{T}, 
    sys :: TaxBenefitSystem{T},
    settings :: Settings = Settings() ) :: HouseholdResult{T} where T
```
(From [SingleHouseholdCalculations.jl](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/SingleHouseholdCalculations.jl))

likewise running the whole model across an entire dataset

```julia
function do_one_run(
        settings :: Settings,
        params   :: Vector{TaxBenefitSystem{T}} ) :: NamedTuple where T # fixme simpler way of declaring this?
```

(From [Runner.jl](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/Runner.jl))

It's easy to embed these calls in something ambitious. This could be a web application (as here), but could also be some fancier simulation, for example of [incentives to work](https://stb.virtual-worlds.scot/bcd/) or forward projections of [health and social care](https://www.virtual-worlds.scot/demonstrations/wsc/) or [child poverty](https://www.virtual-worlds.scot/). Sounds obvious until you see how the rest of the world gets the structure of these models [horribly](https://euromod-web.jrc.ec.europa.eu/) [wrong](https://awesomeopensource.com/project/openfisca/openfisca-core).

So, for frontends: one thing I'm *not* going to do is build a frontend with every possible parameter. I've [done a fair few](https://www.virtual-worlds.scot/demonstrations/) and I've come to think they're a waste of time: if you really want to mess with the 3rd housing benefit non-dependent deduction or whatever, you want something more precise and reproducable than a thrown-together web interface.

So, small, easy to use things for learning and experimentation, and some riff on old-school command-line running for more complex cases.

The ones I'm working with are:

### Dash

[Dash](https://dash-julia.plotly.com/introduction) is a rapid web development framework. The [first model output](https://stb.virtual-worlds.scot/bcd/) is built with dash and I'm really quite chuffed with it. Nice things:

* it's multi-platform (R, Python, Julia) so anything I learn can be used elsewhere (I'm teaching R in the new-year, God help me and the students) 
* the basic thing it does - produce a single web page with some controls and a nice graph as output is exactly what's needed here and what interactions with complex systems should generally look like - more than that overwhelms users, I think;
* it's pretty easy to make something that looks professional, especially with [Bootstrap components](http://dash-bootstrap-components.opensource.faculty.ai/) add-on.

Not so nice:

* being multi-platform it's not very 'Julian'; for example Julia has a [standard set of Statistics components](https://juliastats.org/StatsBase.jl/stable/) that dedicated Julia graphics packages like [Plots](https://docs.juliaplots.org/latest/) and [Makie](https://makie.juliaplots.org/stable/) work with seamlessly, but Dash's [PlotlyJS](https://plotly.com/javascript/) subsystem just doesn't recognise. I've given up trying to draw a pretty straighforward histogram of marginal tax rates, for instance;
* like all frameworks I've ever worked with, it's only useful for the things it's expressley designed for - maybe there are exceptions but not for me. Deviate much from the "a few controls, one output" thing and it's rapidly going to be more trouble than just hand-writing the code. So the second thing I've been writing, which just makes a 'dashboard' of summary results for a full run (costs, marginal rates, poverty levels, inequality and so on) has been much harder work than the first;
* Julia, being a [bit more of a minority language than R or Python](https://www.tiobe.com/tiobe-index/) seems a fairly low priority. To get the Bootstrap package working I've had to abandon the packaged version and work with a locally hacked version(which I can't contribute back since I don't understand how the multi-language build process works).

### Pluto

[Pluto](https://github.com/fonsp/Pluto.jl) is an interactive web-based tool. I've been blown away with the use of this in the [Introduction to Computational Thinking](https://computationalthinking.mit.edu/Spring21/) online course. Initial experiments with this (an inevitable SIR epidemic simulation) have been very encouraging.

Pros and cons:

1. it looks absolutely lovely;
2. its 'reactive' nature, where any change in a cell is automatically propogated to other cells, is both a strength and a weakness. I worry what will happen with a relatively slow running simulation. There have been times on the MIT course when the Pluto pages seem to have locked up; 
3. In the most recent pluto updates the authors have introduced a packaging feature that downloads all required packages at each startup. I can see this being a problem when demoing, and it's certainly annoying when developing. Perhaps there's a way of turning it off?

### Dr Watson

[Dr Watson](https://juliadynamics.github.io/DrWatson.jl/dev/) is:

| a Julia package created to help people increase the consistency of their scientific projects, navigate them and share them faster and easier, manage scripts, existing simulations as well as project source code

For full blown modelling projects, this is what I intend to develop in, in conjunction with either Pluto or [Julia Weave](https://www.juliapackages.com/p/weave) for visualisation. Plus, I've [contributed one tiny bugfix to this](https://github.com/JuliaDynamics/DrWatson.jl/graphs/contributors), so I feel proprietal. I haven't yet used it in anger though, but it feels right.
