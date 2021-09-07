---
layout: post
date:   2021-05-20
category: Blog
tag: Tax Benefit Model
tag: Scotland
tag: Programming
tag: Arrays,Julia 
title: Incomes Again
author: graham_s
nav_exclude: true
---

Here's a nice thing I discovered today - kind of rediscovered, as I'd [asked about this a while back](https://discourse.julialang.org/t/array-indexed-by-enum/56510) but it's only just clicked.

You can make a Pascal-style enumerated-type indexed array in Julia in 2 lines of code. All you have to do is overload the array indexing in the Base library:

If I have an enum `Incomes`, then:

````julia

Base.getindex( X::IncomesArray, s::Incomes ) = getindex(X,Int(s)+1) # enums without explicit numbers start at 0...
Base.setindex!( X::IncomesArray, x, s::Incomes) = setindex!(X,x,Int(s)+1)

````

allows `Incomes` to be used as an index: `inc[Wages] = 99` and so on.  It's not quite the same as Pascal since the array being indexed can be any array type and of any length, and you can always index by `Int`s as well - there's no obvious way of turning these things off. 

The [STBIncomes module](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/STBIncomes.jl) now uses this trick.