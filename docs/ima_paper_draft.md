---
date:   2023-10-08
title: The PPPC model - paper for IMA conference 2023/J Microsimulation
author: Elliot Johnson
author: Matthew Johnson
author: Daniel Nettle
author: Howard Reed
author: Graham Stark
---

# The PPPC Model: A New Yada 

## Paper Prepared for ...

## 1. Introduction

PPPC is part of the Health Case for UBI project, funded by NIHR. Scope: UK. Key novel features ...

## 2. Modelling Health

Elliot 

## 3. Conjoint Analysis

Popularity is derived from a discrete choice experiment with 697 age-representative UK adults conducted in 2023. Participants repeatedly chose between welfare policies differing in design, costs and consequences. From their choices we extracted the marginal values attribute to all the possible policy features and consequences, both for the whole population and each subgroup.

Popularity values will be between 0 and 100. This should not be interpreted as the proportion of people who would vote for a policy. It is an index of the propensity of a representative person to choose the policy given its features, costs and consequences (some of which they might like and some dislike). We also include the popularity of a baseline policy for comparison. 

(I think we need an argument of why people have preferences over tax rates at all, and not just over what their own outcomes would be)

...

## 4. Microsimulation - The Public Policy Preference Caculator (PPPC)

This section describes our experience of integrating the conjoint analysis and health modelling described above into a microsimulation tax-benefit model. Since the conjoint estimation, in particular, is a very new thing in the field, this section is very much "warts and all" - we'll try to be honest about what we've got wrong as well as what we got right, in the hope that this will be useful for subsequent work.

### Why Microsimulation?

Why microsimulate at all? As we saw in section 3 above, the respondents have preferences over instruments (tax rates, benefit levels, etc.) and outcomes (poverty levels, numbers of mental health cases, etc.). We use microsimulation to bridge between the instruments and outcomes. 

A key point is that the microsimulation work began *after* the conjoint analysis was completed. So the whole direction of our modelling was set by the contents of the conjoint analysis. As we'll see, some innocent sounding Conjoint questions almost become research projects in their own right. 

### The Base Model

The analysis uses a heavily adapted version of Scotben [@scotben_github], a microsimulation model of Scotland written in the Julia programming language. The model is fully open source [^FN-GIT-SB]. This section briefly discusses this model; for more, the primary source is of course the Github repository; there is also a model development blog [^FN-SB-BLOG], and two online presentations, one from the 2022 Online IMA conference [*FN-SB-PRES]. 

Scotben is a conventionally structured tax-benefit model, in the family of models branching out from the Institute for Fiscal Studies TAXBEN2 [@TAXBEN2] (two fof the present authors, Reed and Stark, were developers of TAXBEN2). Emphasis is put on modularity and careful encapuslation of the key data structures: households, tax systems and so on [^FN-SB-MODULES]. Scotben is developed "Test First" [^FN-TEST-FIRST]: tests of the functionality in a module ("unit tests") are written before development of the module itself, and we write only ythe code needed to pass the tests [^FN-SB-IT-TESTS]. Modularity and test-driven development are excellent investments. The modular organisation makes it easy to bolt together variants of the model for different purposes [^FN-TB-EXAMPLES] and continually running test suite during development minimises the chances of introducing new errors. The development phase of the PPPC model took just 6 weeks in total. 

As is conventional in UK modelling, Scotben uses the Family Resources Survey as its principle dataset. The original scope of the model is Scotland, but the present project is UK-wide [^FN-GB-NI]. In many respects a UK scope actually simplifies things because much of the difficulty in a Scotland-specific model is in pooling multiple years of data and constructing suitable sample weights, whereas here we can use a single 2021/22 FRS dataset and the pre-calculated weights. On the other hand, we have to model taxes and benefits that differ between the Nations of the UK - in the event, Northern Ireland was dropped from the analysis because we were unable to model the NI property-based local tax in the time we had available. To capture the effects of the various Conjoint options, FRS data has to be augmented with several other sources: we discuss these below.

The Model is written in the Julia [@Julia] language. Julia is well worth a look for anyone looking to start a new microsimulation project. It aims to bridge the gap between statistics packages such as Stata and high-level programming languages like Fortran or Python. While not without its problems, it largely succeeds in this: many of the regressions reported below are written Julia [^FN-JU-GLM], while the main modelling code has the expressiveness and type-safety of the Pascal-like languages used in the TAXBEN2 family.  

### Integrating The Conjoint Analysis

As mentioned, the questions in the conjoint survey largely determine the direction of the microsimulation modelling.

There is quite a lot of ambiguity in some of the questions: a wealth tax or carbon levy could be implemented in many different ways, for instance. We make what we hope are reasonable assumptions for these cases, but for the microsimulation to be fully consistent with the conjoint survey we'd have to know what was in the mind of the respondents. 

The outcome questions - poverty, inequality, health and so on - are phrased as changes -  "50% fewer cases" for mental health, "Increased by 50%" for poverty and so on. A particularly tricky question arising from this is establishing a baseline for comparison. In reporting the microsimulation results, it's 


#### Income Tax Taxes

The conjoint analysis has a number of tax options of the form:

    * Basic rate - 20%; Higher rate - 40%; Additional rate - 45%
    * Basic rate - 30%; Higher rate - 50%; Additional rate - 60%

and so on. The first of these is essentially the status-quo, except for in Scotland, where there are five rates; all other options in the survey represent rate increases. We assume the corresponding thresholds are as present. 
#### Benefits

For beneftits

A tricky question is what to take for the baseline system. For benefits, the conjoint survey doesn't ask how people would feel about keeping things as they presently are. 
All options 


#### The Baseline

#### A Wealth Tax

#### Health Modelling

#### Corporation Taxes

#### Value Added Tax

### Carbon Taxes 

### The Equaliser

### Model User Interface













