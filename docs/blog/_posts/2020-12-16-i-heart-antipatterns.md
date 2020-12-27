---
layout: post
date:   2020-12-16
category: Programming
tags: Anti-patterns Julia
title: I 💓 Antipatterns
author: graham_s
---

I was reading [JuliaLang Antipatterns](https://www.oxinabox.net/2020/04/19/Julia-Antipatterns.html) by [Lyndon
White](https://www.oxinabox.net/).

I'm a guilty man. STB violates (at least) two of these antipatterns pretty consistently.

<!--more-->

Dr. White knows more about Julia than I do, and likely ever will. But on these 

### Over-constraining argument types

Dr. White writes:

> I will begin with a bold claim: Type constraints in Julia are only for dispatch. If you don’t have multiple methods
> for a function, you don’t need any type-constraints. If you must add type-constraints (for dispatch) do so as loosely as
> possible. I will justify this claim in the following sections.

Applications vs libraries

Ideal organisation - non programming specialists on a spectrum

why not programming specialists plus subject specialists

Defensive programming - spreadsheet error examples 

IFS Taxben example - programmer proof. 

So - case for strong(ish) possible typing. Can't rely on comments. Building data structures.

Difference from library/compiler code.

trade-offs 
    
* between generality and clarity - more clarity for an application
* speed and accuracy no trade off and likely fewer eyes on the code 


clarity - 




