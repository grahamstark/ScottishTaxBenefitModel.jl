---
layout: post
date:   2020-12-16
category: Programming
tags: Releases Julia
title: Notes on Releasing Julia Packages
author: graham_s
---

A lot has happened since I last posted. I'll write about it when I've got my head around it.

For now ...

Getting a release ready in Julia is painful and embarrasing for me. I keep getting things mixed up.

I've got 3 packages published presently:

* [Budget Constraints](https://github.com/grahamstark/BudgetConstraints.jl);
* [Survey Data Weighting](https://github.com/grahamstark/SurveyDataWeighting.jl);
* [Poverty & Inequality](https://github.com/grahamstark/PovertyAndInequalityMeasures.jl).

Getting each publised involved a fair amount of pain. 

Some notes:

### JuliaHub

The simplest way to publish or update a package is via [JuliaHub](https://juliahub.com/ui/Home). You need an account but
you can use your [GitHub Account](https://github.com/). I think registration will work with projects not hosted there
but haven't tried this. The registration process is *very* fussy so everything has to be right. It usually takes me
several goes to get everything right. 

### Deleting a git tag

I keep releasing things and then realising there's a mistake. Suppose the tag is `v1.0.3`:  

    git tag -d v1.0.3
    git push origin :v1.0.3

I don't know what it means either ...

### Project.toml checklist

I hate this file sometimes. Some random things that get me every time:

* always check the version number e.g. `version = "0.1.0"` matches the Git release tag;
* check there is a version number in the `[compat]` section for each package you add in the `[deps]` section.
  This is not done automatically;
* Note that packages needed just during development don't have to be added to `Project.toml` so long as they are available
  somewhere - in some general package cache - so `Revise` doesn't need to be added to the project file so long
  as it's installed as part of general Julia install.
  
Actually, seeing that it's there, it strikes me you could do more with it. 

* adding a `[modules]` section to list local modules;
* name an `[export]` module that would the packages public face.
  
### Compat Helper

Installed automatically in Git for a published julia package. Just obey it..


  











