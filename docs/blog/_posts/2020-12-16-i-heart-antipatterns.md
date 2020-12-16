---
layout: post
date:   2020-12-15
category: Programming
tag: Julia 
tag: Antipatterns
title: I 💓 Antipatterns
author: graham_s

---

I was reading [JuliaLang Antipatterns](https://www.oxinabox.net/2020/04/19/Julia-Antipatterns.html) by [Lyndon
White](https://www.oxinabox.net/).

I'm a guilty man. STB violates (at least) two of these antipatterns pretty consistently.

<!--more-->

Dr. White knows more about Julia than I do, and likely ever will. But on these 

## Over-constraining argument types

He writes:

> I will begin with a bold claim: Type constraints in Julia are only for dispatch. If you don’t have multiple methods
> for a function, you don’t need any type-constraints. If you must add type-constraints (for dispatch) do so as loosely as
> possible. I will justify this claim in the following sections.

I'm a strong typing guy. I want types everywhere.  



