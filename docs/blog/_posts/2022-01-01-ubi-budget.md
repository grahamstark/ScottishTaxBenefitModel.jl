---
layout: post
date:   2022-01-01
category: Blog
tag: Tax Benefit Model
tag: Scotland
tag: Programming
title: Two New Interfaces
author: graham_s
nav_exclude: true
---

I've built two new interfaces for the model. One is a [simple budget sim](https://stb.virtual-worlds.scot/scotbudg/) and the other a [specialised Basic Income model](https://ubi.virtual-worlds.scot/).

<!--more-->

I'm quite pleased with them. I think they look good. They use [Bootstrap](https://getbootstrap.com/) for the visuals which I really like since it makes all the hard decisions for you - you just add some tags (and *lots* of <divs>s).

The budget one is written, like the [BC one](https://stb.virtual-worlds.scot/scotbudg/), in [Dash](https://dash.plotly.com/julia). But I got a bit worried about how Dash seems unable to handle multiple requests. The rule of thumb I've aways used is a classroom-full of model submissions - 25-30 in a few seconds, when a teachers says 'run your simulation now, please'. Handling this with serialised requests is fine with the BC sim because runs are near instantaneous, but the full dataset runs take 5-10 seconds, mainly because marginal rates are calculated by incrementing wages. So submitted runs may start to pile up. 

The UBI one is instead a hand-written mini server with each job started on a new thread. There are problems with that, too, of course, that would need addressed - cross-site scripting, multiple inadvertent submissions, parameters not resetting, generally the messy code, and I'm sure others. But it does handle multiple requests correctly, so I'll likely go with that in future and work out the wrinkles. All the code for this is in the [Visualisations repository](https://github.com/grahamstark/Visualisations.jl).

The UBI one is to help with a pretty big project application - not much I can say just at the moment but we'll see.
