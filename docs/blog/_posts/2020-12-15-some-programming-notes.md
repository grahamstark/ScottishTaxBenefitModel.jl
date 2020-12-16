---
layout: post
date:   2020-12-15
category: Programming
tag: Tax Benefit Model
tag: Julia 
tag: Type Systems
title: Some Programming Notes
author: graham_s

---

I really like [Julia](https://julialang.org/). It's a really nice combination of a 'proper' structured programming
language and a data exploration tool. But it has its quirks. 

One I'm struggling with is finding a good way to build a [package](https://julialang.org/packages/) with multiple
[modules](https://docs.julialang.org/en/v1/manual/modules/). I want a seperate package for each main component, but to
have one Scottish Tax Benefit Model package. You can kinda-sorta manage it with [child packages](), which is what I'm
using, but it's akward. I might write up something about this: [Ada](https://www.adacore.com/about-ada) does this right.

<!--more-->

Julia can be really fast and efficient, but also a good dynamic prototying language. But that can be a problem because
the dynamic stuff is naturally quite slow - a sort of 'PHP mode'. The key to getting it fast is to be sure that [the
code you're running is unambigiously typed](https://docs.julialang.org/en/v1/manual/performance-tips/). 

This is tricky. It can be non-obvious whether something is unambigiously typed, and it can be very good practice to use
abstract, non-concrete types (though I draw the line at not providing any type, which is usually legal and surprisingly
common). 

It's taken me a long time to get my head round this and I'm probably not there yet. I always prefer using strong typing
for clarity so this weak-ish typing for efficiency is a new thing.

One particular problem this model faces is that, in the current design, we need a big global variable to hold our
dataset. Julia does not like this: the first adminition in the [performance
section](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-global-variables) is "Avoid global variables".
Globals can't be typed (I don't understand why not), so unless you're very careful, using a global can inadverantly trip
the program into dynamic, typeless, PHP mode. 

I spent a while today writing [some tests to help me understand all
this](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/tree/master/scripts/performance). I found quite a nice
hack here: wrap the array of households in a `struct`:

```julia
struct  HHWrapper 
    hhlds :: Vector{Household{Float64}}
end 
```

Here: 

* `struct` is an [immutable structure](https://docs.julialang.org/en/v1/base/base/#struct) - in principle can't be changed once instansiated;
* `Vector` is shorthand for a 1-dimensional array; and 
* `Household{Float64}` declares a [Household](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/ModelHousehold.jl) record, with 64-bit floats used for all the real numbers.

You then declare a global constant of type `HHWrapper`, with an unitialised array of `hhlds`:

```julia
const MODEL_HOUSEHOLDS = HHWrapper(Vector{Household{Float64}}(undef, 0 ))
```

The `const` guarantees that the `MODEL_HOUSEHOLDS` global can't change type, and the `HHWrapper` is non-mutable, so all
the type stability stuff is ensured. But since the `hhlds` field is a `vector`, in Julia, it's mutable, in the sense
that you can add and alter elements (of exactly the element type), even if in a immutable struct with a `const` instance.
So the [data handling
module](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/FRSHouseholdGetter.jl) can fill in the
array with a single global (but hidden) instance with loads of households, but we get the speed advantages of static
typing.

This can be much faster. Here's some output from my speed test comparing conventional array access to a global variable
to access to my constant wrapped version, from [my speed test script](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/scripts/performance/hhld_example.jl) on my laptop.

```
:getter_struct_var => Trial(600.001 μs)
:getter_struct_const => Trial(13.380 μs)
```
In other non-news, I've gone back to my old, trusty [JEdit](http://www.jedit.org/). I just like its unfussyness, the way
it doesn't try to do everything for me. Should probably use its spell-checker a bit more, though.