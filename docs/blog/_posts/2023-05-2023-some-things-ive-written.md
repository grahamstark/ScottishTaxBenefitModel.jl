---
layout: post
date:   2022-08-08
category: Blog
tag: Microsimulation
tag: Publications
tag: Legal Aid
tag: Affordability
title: Some things I've written (part 1)
author: graham_s
nav_exclude: true
---

At the age of 64 I'm in the process of finally getting a Phd. I started one during my first job in Lancaster one back in 1983 (Macroecononic aspects of price stabilisation in the Sugar Industry, since you didn't ask) but never finished it after I joined IFS.

This one is 'by publication' so I've been gathering stuff I've written over the years. I've never been great at CV management; proper people have all this to hand and on [Orchid](https://orcid.org/0000-0002-4740-8711), but I've never bothered till now.

So here's a bunch of stuff from when I was IFS. I'll add a something on post-IFS work presently.

### Microsimulation Modelling 

The canonical microsimulation is the Tax Benefit Model, which, as the name suggests, models the effects of the fiscal system on individuals and households. The IFS had a such a model before I joined, but after I blew it up on live TV during a BBC Budget broadcast (1987 I think) I persuaded our then boss Bill Robinson to let me build a new one. Taxben was mainly written in my spare room in Milton Keynes on an [Amstrad PC](https://en.wikipedia.org/wiki/Amstrad_PCW) in the months after my son was born. It was written in [Turbo Pascal](https://en.wikipedia.org/wiki/Turbo_Pascal), which I loved; such a step up from the Fortran-66 we'd been using. [Johnson, Stark and Webb (1990)](https://virtual-worlds.scot/publications/docs/stark-webb-taxben.pdf) is the working paper. An updated version of that that model remains in use today; 25 years on it still has many technical advantages over competitor models such as Euromod. It's certainly proved to be programmer-proof.

Subsequently, we build similar models for former Soviet Block countries using similar methods; [Coulter Heady and Stark (1995)](https://virtual-worlds.scot/publications/docs/coulter-stark-cz.pdf) is a paper describing one such model for the former Czechoslovakia. Living and working in Prague so soon after the Velvet Revolution was a really exciting.

I also found a technical paper and a Fiscal Studies article on one of my first ever microsimulations, of the UK Capital Gains Tax [King and Stark 1985](https://virtual-worlds.scot/publications/docs/stark-king-cgt.pdf) - that one was a bit of a nightmare - crashed deadlines, crashed programs; the thing I remember most about it was my boss [John Kay](https://johnkay.com) being really kind about it - 'learn from this'. I hope I did. 

[Duncan and Stark 2000](https://virtual-worlds.scot/publications/docs/A_Recursive_Algorithm_to_Generate_Piecewise_Linear.pdf) describes an algorithm for accurately calculating the often highly non-linear relationships between what people earn and what they get to keep. It's the agorithm used [here](https://stb.virtual-worlds.scot/bcd) to describe budget constraints for Scottish families. I loved working with Alan on that; it's one of the few things I've ever done that felt truly original; doubtless it isn't - I'm sure some mathematician or computer scientist had the same thought years ago, but it was new to us. 

### Applications of Microsimulation 

Here are some examples of papers using these microsimulation models to analyse important possible policy changes. It's possible that some of this analysis seems commonplace now, but the ability to describe the impact of such changes on the incomes of different types of family, incentives to work, and tax revenues was very new and a big deal at the time.

[Stark 1988](https://virtual-worlds.scot/publications/docs/stark-tax-family.pdf) analyses the move from taxing husbands and wives jointly to the individual taxation we have today; one consequence of that change was that families with two earners could now receive more tax allowances than families with a single earner, and this paper is one of several I wrote exploring proposed *transferrable allowances* that would address this. 

Dilnot and Stark (1986 [a](https://virtual-worlds.scot/publications/docs/dilnot-stark-oup.pdf), [b](https://doi.org/10.1111/j.1475-5890.1986.tb00410.x)) are analyses of the poverty trap - as a family's income rose from a low level, the withdrawal of means-tested benefits along with increases in taxes could leave them no better off, or even worse off. These papers were the first to show that the numbers of families affected by very high withdrawal rates were at the time likely quite small. 

[Johnson and Stark (1990)](https://virtual-worlds.scot/publications/docs/johnson-stark-mw.pdf) was the first study of the distributional effects of a UK minimum wage. What I remember most about this is that the whole thing - both the MW simulation code and the paper that used it - were written in an afternoon, after Andrew had been on TV saying minimum wages were insane (I think that was the word he used), and we needed something to, if not back him up, at least show we we had something concrete to add. Anyway, we showed that the likely gains were mostly amongst second earners, and so the gains were predominantly to the middle of the income distribution - this result was not appreciated at the time, though it has largely been overtaken by social and economic changes such as the rise in low-paid gig working. 

[Johnson and Stark (1993)](https://virtual-worlds.scot/publications/docs/Assessing_the_impact_of_tax_ch.pdf) was my attempt at a "How to Lie with statistics" paper specifically about tax policy, and written as a reaction to media coverage of the tax policies proposed in the 1992 general election. 

[Stark and Johnson (1989)](https://onlinelibrary-wiley-com.libezproxy.open.ac.uk/doi/10.1111/j.1475-5890.1986.tb00421.x) was an attempt to summarise the entirety of the tax and benefit policy of the Thatcher Government in a concise but consistent way, showing how the changes to taxation and benefits taken in their entirety were highly regressive.

### Benefit Takeup 

The UK's benefit system is largely means-tested - entitlement to Universal Credit, Working Tax Credit and the like depend on family income, with benefits being withdrawn as incomes rise. Along with the Poverty Trap, the key problem with means testing is that these benefits may not be claimed, perhaps because of stigma, or because of the complexity of claiming them. I worked on applying microsimulation techniques to non-takeup with Vanessa Fry; Vanessa was great to work with - you can easily tell the bits of these papers Vanessa wrote since the prose suddenly comes alive. Fry and Stark ([1987](https://virtual-worlds.scot/publications/docs/fry_stark_fs_1990_72044232X_ocr.pdf)), ([1992](https://virtual-worlds.scot/publications/docs/stark-fry-oup.pdf)
), ([1993](https://ifs.org.uk/sites/default/files/output_url_files/r41.pdf)). A key result is that takeup is higher for large entitlements, which provides support for the -disutility- model of takeup. Studies using our microsimulation methods have since become a mini-industry, though it's gone in a very strange direction.  

### Benefit Simplification

The Takeup work showed how complexity and stigma were likely important factors in limiting the effectiveness of means-tested benefits. [This work with the brilliant Alexy Buck](https://virtual-worlds.scot/publications/docs/buck-stark-legal-aid.pdf) on Legal Aid Means-Testing was an attempt to address this. We used microsimulation to answer the question: 'what is the simplest set of rules that could achieve some set of objectives'? - the numbers and types of families eligible, overall expenditure and administrative costs and so on.  The work fed directly into reforms to the legal aid means tests, though the positive impact was largely drowned out by subsequent large cuts to Legal Aid budgets. Subsequently, there was interest in the simplification question in Government, including briefly an [Office for Tax Simplification](https://www.gov.uk/government/organisations/office-of-tax-simplification), but work there often combined simplification with sweeping distributional changes - flat taxes or poll taxes are clearly simpler, but that doesn't make them a good idea. Our question was better and clearer.

### Budget Analysis

One of the founding missions of IFS was to provide timely, detailed analysis of actual and proposed budget changes. These papers are examples of using microsimulation for this. These, too, may seem commonplace now (although the analysis of budgets is mostly focussed elsewhere nowadays, on the public finances in the aggregate). But at the time, quick, detailed analysis of the distributional and incentive effects of budgets was new and had a huge impact in the wider discourse. 

* [Budget 1987](https://virtual-worlds.scot/publications/docs/stark-dilnot-budget-87.pdf);
* [1990](https://virtual-worlds.scot/publications/docs/stark-dilnot-webb-budget-90.pdf);
* [1991](https://virtual-worlds.scot/publications/docs/stark-dilnot-budget-91.pdf).