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

The analysis uses a heavily adapted version of Scotben [@SB-GITHUB], a microsimulation model of Scotland written in the Julia programming language. The model is fully open source [^FN-GIT-SB]. This section briefly discusses this model; for more, the primary source is of course the Github repository; there is also a model development blog [^FN-SB-BLOG], and two online presentations, one from the 2022 Online IMA conference [^FN-SB-PRES]. 

Scotben is a conventionally structured static tax-benefit model, in the family of models branching out from the Institute for Fiscal Studies TAXBEN2 [@TAXBEN2] (two fof the present authors, Reed and Stark, were developers of TAXBEN2). Emphasis is put on modularity and careful encapsulation of the key data structures: households, tax systems and so on [^FN-SB-MODULES]. Scotben is developed "Test First" [^FN-TEST-FIRST]: tests of the functionality in a module ("unit tests") are written before development of the module itself, and we write only the code needed to pass the tests [^FN-SB-IT-TESTS]. Modularity and test-driven development are excellent investments. The modular organisation makes it easy to bolt together variants of the model for different purposes [^FN-TB-EXAMPLES] and continually running test suite during development minimises the chances of introducing new errors. The development phase of the PPPC model took just 6 weeks in total. 

By 'static' here, we of course mean:

1. the model is single-period; and
2. that there are no behavioural adjustments: benefits are fully taken up, taxes not avoided, and there are no labour supply responses.

However, the clean design makes it much easier to add these things as needed; for example, we can map complete budget constraints more accurately than rival models, in just a few lines of code [^FN-TB-BC]

As is conventional in UK modelling, Scotben uses the Family Resources Survey as its principle dataset. The original scope of the model is Scotland, but the present project is UK-wide [^FN-GB-NI]. In many respects a UK scope actually simplifies things because much of the difficulty in a Scotland-specific model is in pooling multiple years of data and constructing suitable sample weights, whereas here we can use a single 2021/22 FRS dataset and the pre-calculated weights. On the other hand, we have to model taxes and benefits that differ between the Nations of the UK - in the event, Northern Ireland was dropped from the analysis because we were unable to model the NI property-based local tax in the time we had available. To capture the effects of the various Conjoint options, FRS data has to be augmented with several other sources: we discuss these below.

The Model is written in the Julia [@Julia] language. Julia is well worth a look for anyone looking to start a new microsimulation project. It aims to bridge the gap between statistics packages such as Stata and high-level programming languages like Fortran or Python. While not without its problems, it largely succeeds in this: many of the regressions reported below are written Julia [^FN-JU-GLM], while the main modelling code has the expressiveness and type-safety of the Pascal-like languages used in the TAXBEN2 family.

The modular design and the abundance of high-quality 3rd party Julia libraries made adding a Web based model user interface extremely easy; we return to this briefly below.

### Integrating The Conjoint Analysis

As mentioned, the questions in the conjoint survey largely determine the direction of the microsimulation modelling.

There is ambiguity in some of the questions: a wealth tax or carbon levy could be implemented in many different ways, for instance. We make what we hope are reasonable assumptions for these cases, but for the microsimulation to be fully consistent with the conjoint survey we'd have to know what was in the mind of the respondents. 

The outcome questions - poverty, inequality, health and so on - are phrased as changes -  "50% fewer cases" for mental health, "Increased by 50%" for poverty and so on. A particularly tricky question arising from this is establishing a baseline for comparison. As discussed below the conjoint survey had no 'keep things as they are' option for the tax and benefit instruments, so we have two options:

1. using a tax-benefit system some way from the current one as baseline and assuming that the outcome changes represent changes in poverty, health, etc. from that point, rather than changes from the actual current situation; or
2. using the current system as the baseline - but if we do that the default output will have significant deviations for the outcome variables.

We opted for 1) on the grounds that it makes the conjoint popularity output much easier to understand. So the model starts from some distance from where we currently are.

### The model flow TODO 

1. User selects instruments - tax rates etc. 
2. Model calculates consequences - net fiscal position, gainers/losers. 
3. Health calculations based on net income changes (one way - income -> health) 
4. Conjoint popularity based in all three.

### Components

We turn now to how we .. 

One slightly testing aspect of developing PPPC is that simple seeming options from the questionnaire can represent pretty major pieces of modelling. For example, one of the of the options in the Conjoint questionnaire for paying for changes is 'Tax on wealth'; that sounds simple enough (and it's one button in the user-interface), but it requires a lot of modelling work and strong assumptions. 

#### Income Tax Taxes[^FN-UK-IT]

The conjoint analysis has a number of tax options of the form:

    * Basic rate - 20%; Higher rate - 40%; Additional rate - 45%
    * Basic rate - 30%; Higher rate - 50%; Additional rate - 60%

and so on. The first of these are the current non Scottish UK income tax rates; all other options in the survey represent rate increases. We assume the corresponding thresholds are as present. Scotland, has its own 5 rate system - 19,20,21,41,46: for the reasons above we impose the "Rest of UK" 3 rate system as the baseline in Scotland too, so we start there from a position where Scottish low earners pay slightly more than in reality and high earners less. 

#### Benefits[^FN-UK-BEN]

The benefit questions in the conjoint survey are about a hypothetical UBI. The questions of the form: 

    * Child - £0; Adult - £63; Pensioner - £190
    * Child - £95; Adult - £230; Pensioner - £230

There also questions about eligibility e.g:

    * People in and out of work are entitled
    * Everyone is entitled but people of working age who are not disabled are required to look for work

Means-testing e.g:
   
    * People with any or no amount of income are entitled to the full benefit
    * Only those with incomes less than £20k are entitled to the full benefit

And citizenship:
    
    * Citizens, permanent residents and anyone residing in the UK for more than six months are entitled
    * Only citizens and permanent residents are entitled

It's unclear how this proposed UBI system should interact with the existing tax and benefit system, especially bearing in mind that the question is not how an expert believes they should interact, but what was most likely in the mind of the respondents. 

The ultimate ambition of many UBI advocates is that the UBI system sweeps away the all the current means-tested and conditional benefits but replacing all benefits with the above produces huge changes in incomes, especially for those on lower incomes due to the abolition of means-tested benefits. Instead, we follow our recent analysis [@Johnson-Read] and assume:

1. means-tested benefits are retained [^FN-UC-TRANSITION];
2. most other benefits, including the state pension and Child Benefit, are abolished and replaced by the UBI payments above. (Disability benefits are retained).

The least generous options: Child - £0; Adult - £63; Pensioner - £190 are taken as the base values. Compared to the actual current system, this means that we're starting from a social security system that's considerably more expensive (because of the adult payments), but where pensioners are usually slightly worse off (£190 vs £203.85 [@statepen]) and where families with large numbers of children not on means-tested benefits are worse off, since the UBI payments to children is zero in the default case and the payments to adults are not always enough to compensate. We don't adjust taxes to meet these extra base costs. TODO NUMBERS FOR THIS.

For the eligibility, means-testing and citizenship options, it seemed plausible that at least some of the respondents might be aware of the means and eligibility tests from existing benefits. Consequently, we model the eligibility rules that apply to the 'legacy' UK benefits - Working Tax Credit and Income Support/Employment Support that are in the process of being phased out and the means-tests are taken from the new Universal Credit. Note that these tests apply to 'benefit units' - essentially a nuclear family [^FN-CPAG-BUs], rather than to individuals. 

#### A Wealth Tax



#### Health Modelling

#### Corporation Taxes

#### Value Added Tax

#### Carbon Taxes 

### The Equaliser

### Model User Interface













