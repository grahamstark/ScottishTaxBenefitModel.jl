---
layout: post
date:   2022-08-08
category: Blog
tag: Microsimulation
tag: Publications
tag: Legal Aid
tag: Affordability
title: Some things I've written
author: graham_s
nav_exclude: true
---
https://virtual-worlds.scot/publications/docs/dilnot-stark-oup.pdf




At the age of 64 I'm in the process of finally getting a Phd. I started one during my first job in Lancaster one back in 1983 (Macroecononic aspects of price stabilisation in the Sugar Industry, since you didn't ask) but never finished it after I joined IFS.

This one is 'by publication' so I've been gathering stuff I've written over the years. I've never been great at CV management; proper people have all this to hand and on [Orchid](https://orcid.org/0000-0002-4740-8711), but I've never bothered till now.

So here's a bunch of stuff.

### Microsimulation Modelling 

The canonical microsimulation is the Tax Benefit Model, which, as the name suggests, models the effects of the fiscal system on individuals and households. The IFS had a such a model before I joined, but after I blew it up on live TV during a BBC Budget broadcast (1987 I think) I persuaded our then boss Bill Robinson to let me build a new one. Taxben was mainly written in my spare room in Milton Keynes on an [Amstrad PC](https://en.wikipedia.org/wiki/Amstrad_PCW) in the months after my son was born. Written in [Turbo Pascal](https://en.wikipedia.org/wiki/Turbo_Pascal), which I loved; such a step up from the Fortran-66 we'd been using. [Johnson, Stark and Webb (1990)](https://virtual-worlds.scot/publications/docs/stark-webb-taxben.pdf) is the working paper. An updated version of that that model remains in use today; 25 years on it still has many technical advantages over competitor models such as Euromod. It's certainly proved to be programmer-proof.

Subsequently, we build similar models for former Soviet Block countries using similar methods; [Coulter Heady and Stark (1995)](https://virtual-worlds.scot/publications/docs/coulter-stark-cz.pdf) is a paper describing one such model for the former Czechoslovakia. Living and working in Prague so soon after the Velvet Revolution was a really exciting.

I also found a technical paper and a Fiscal Studies article on one of my first ever microsimulations, of the UK Capital Gains Tax [King and Stark 1985](https://virtual-worlds.scot/publications/docs/stark-king-cgt.pdf) - that one was a bit of a nightmare - crashd deadlines, crashed programs; the thing I remember most about it was my boss [John Kay](https://johnkay.com) being really kind about it - 'learn from this'. I hope I did. 

[Duncan and Stark 2000](https://virtual-worlds.scot/publications/docs/A_Recursive_Algorithm_to_Generate_Piecewise_Linear.pdf) describes an algorithm for accurately calculating the often highly non-linear relationships between what people earn and what they get to keep. It the agorithm used [here](https://stb.virtual-worlds.scot/bcd). I loved doing that; it's one of the few things I've ever done that felt truly original; doubtless it isn't - I'm sure some mathematician or computer scientist had the same thought years ago, but it was new to us. Alan was a good guy to work with.

### Applications of Microsimulation (Stark 1988, Dilnot and Stark 1986a, 1986b, Johnson and Stark 1989, 1991)

Here are some examples of papers using these microsimulation models to analyse important possible policy changes. It's possible that some of this analysis seems commonplace now, but the ability to describe the impact of such changes on the incomes of different types of family, incentives to work, and tax revenues was very new and a big deal at the time.

[Stark 1988](https://virtual-worlds.scot/publications/docs/stark-tax-family.pdf) analyses the move from taxing husbands and wives jointly to the individual taxation we have today; one consequence of that change was that families with two earners could now receive more tax allowances than families with a single earner, and this paper is one of several I wrote exploring proposed *transferrable allowances* that would address this. 

Dilnot and Stark (1986 [a](https://virtual-worlds.scot/publications/docs/dilnot-stark-oup.pdf), [b]()) are analyses of the poverty trap - as a family-s income rose from a low level, the withdrawal of means-tested benefits along with increases in taxes could leave them no better off, or even worse off. These papers were the first to show that the numbers of families affected by very high withdrawal rates were at the time likely quite small.

[Johnson and Stark (1990)](https://virtual-worlds.scot/publications/docs/johnson-stark-mw.pdf) was the first study of the distributional effects of a UK minimum wage. What I remember most about this is that the whole thing - both the MW simulation code and the paper that used it - were written in an afternoon, after Andrew had been on TV saying minimum wages were insane (I think that was the word he used), and we needed something quick. Anyway, we showed that the likely gains were mostly amongst second earners, and so the gains were predominantly to the middle of the income distribution - this result was not appreciated at the time, though it has largely been overtaken by social and economic changes such as the rise in low-paid -gig working-. 

https://virtual-worlds.scot/publications/docs/affordability-report-phase-1.pdf
https://virtual-worlds.scot/publications/docs/report_phase_2_aug_24.doc
https://virtual-worlds.scot/publications/docs/affordability-report-phase-2.pdf     
https://virtual-worlds.scot/publications/docs/stark-dilnot-budget-87.pdf
https://virtual-worlds.scot/publications/docs/A_Recursive_Algorithm_to_Generate_Piecewise_Linear.pdf
https://virtual-worlds.scot/publications/docs/stark-dilnot-budget-91.pdf
    
https://virtual-worlds.scot/publications/docs/stark-dilnot-webb-budget-90.pdf
https://virtual-worlds.scot/publications/docs/coulter-stark-cz.pdf


https://virtual-worlds.scot/publications/docs/stark-fry-pensions.pdf
https://virtual-worlds.scot/publications/docs/'Fiscal Studies - 2005 - Buck - Simplicity versus Fairness in Means Testing The Case of Civil Legal Aid.pdf'
https://virtual-worlds.scot/publications/docs/stark-king-cgt.pdf
https://virtual-worlds.scot/publications/docs/forecasting_child_povety_in_scotland_00533637.pdf
https://virtual-worlds.scot/publications/docs/'stark-part-transferrab;e-allowances.pdf'
https://virtual-worlds.scot/publications/docs/stark-tax-family.pdf
# https://virtual-worlds.scot/publications/docs/johnson-stark-mw.pdf
# https://virtual-worlds.scot/publications/docs/stark-webb-taxben.pdf

[Johnson and Stark (1993)](https://virtual-worlds.scot/publications/docs/Assessing_the_impact_of_tax_ch.pdf ) was my attempt at a "How to Lie with statistics" paper specifically about tax policy, and written as a reaction to media coverage of the tax policies proposed in the 1992 general election. 

[Stark and Johnson (1989)]()was an attempt to summarise the entirety of the tax and benefit policy of the Thatcher Government in a concise but consistent way, showing how the changes to taxation and benefits taken in their entirety were highly regressive.

### Benefit Takeup 

The UK's benefit system is largely means-tested - entitlement to Universal Credit, Working Tax Credit and the like depend on family income, with benefits being withdrawn as incomes rise. Along with the Poverty Trap, the key problem with means testing is that these benefits may not be claimed, perhaps because of stigma, or because of the complexity of claiming them. Fry and Stark ([1987](https://virtual-worlds.scot/publications/docs/fry_stark_fs_1990_72044232X_ocr.pdf)), ([1990](https://virtual-worlds.scot/publications/docs/stark-fry-oup.pdf)
), ([1993]()) were the first studies to use microsimulation techniques to study non-take up. A key result is that takeup is higher for large entitlements, which provides support for the -disutility- model of takeup. Studies using our microsimulation methods have since become a mini-industry, though it's gone in a very strange direction.  


The Takeup work showed how complexity and stigma were likely important factors in limiting the effectiveness of means-tested benefits. This work on Legal Aid Means-Testing was an attempt to address this. We used microsimulation to answer the question: -what is the simplest set of rules that could achieve some set of objectives - the numbers and types of families eligible, overall expenditure and administrative costs and so on.  The work fed directly into reforms to the legal aid means tests, though the positive impact was largely drowned out by subsequent large cuts to Legal Aid budgets. Subsequently, there was interest in the simplification question in Government, including an -Office for Tax Simplification-, but work there often combined simplification with sweeping distributional changes - flat taxes or poll taxes are clearly simpler. Our question was better and clearer. 

Budget Analysis (Johnson and Stark XX, Dilnot and Stark 1987, Stark and Webb 1990)[MJ1]
One of the key founding missions of IFS was to provide timely, detailed analysis of actual and proposed budget changes. These papers are examples of using microsimulation for this. These, too, may seem commonplace now (although the analysis of budgets is mostly focussed elsewhere nowadays, on the public finances in the aggregate). But at the time, quick, detailed analysis of the distributional and incentive effects of budgets was new and had a huge impact in the wider discourse. In addition, there are two papers (Stark 20xx, 20xx) written for the Office of the Scottish Charities Register (OSCR). OSCR were concerned out granting charitable status to (e.g.) private schools or golf clubs that few people could afford. The first of the two papers here discusses the literature on affordability as applied to, for example, affordable housing, fines levied by the courts and fuel poverty. The second describes a microsimulation model that shows the proportions of households who might be able to afford the proposed fees of some applicant for charitable status. Again, I believe this was the first model of its kind.

Means testing-
Dilnot Andrew, Graham Stark, and Steven Webb. 1987. -The Targeting of Benefits: Two Approaches-. Fiscal Studies 8 (1): 83-93. https://doi.org/10.1111/j.1475-5890.1987.tb00434.x.

Fry, Vanessa, and Graham Stark. 1987. -The Take-Up of Supplementary Benefit: Gaps in the -Safety Net Fiscal Studies 8 (4): 1-14. https://doi.org/10.1111/j.1475-5890.1987.tb00302.x.

Fry, Vanessa, and Graham Stark. 1992. The Takeup of Means-Tested Benefits in the UK: The Transition to Income Support and Family Credit. Institute for Fiscal Studies.
Fry, Vanessa, and Graham Stark. 1993. -The Take-up of Means-Tested Benefits, 1984-90-. 1 January 1993. https://doi.org/10.1920/re.ifs.1993.0041.
Buck, Alexy, and Graham Stark. 2001. Means Assessment: Options for Change. LSRC Research Paper No.8. Legal Services Commission.
Buck, Alexy, and Graham Stark. 2003. Simplicity versus Fairness in Means Testing: The Case of Civil Legal Aid. Fiscal Studies 24 (4): 427-49. https://doi.org/10.1111/j.1475-5890.2003.tb00090.x.

Impacts of tax-welfare reforms
Dilnot, Andrew, and Graham Stark. 1986a. The Poverty Trap, Tax Cuts, and the Reform of Social Security. Fiscal Studies 7 (1): 1-10. https://doi.org/10.1111/j.1475-5890.1986.tb00410.x.
Dilnot, Andrew, and Stark, Graham. 1986b. The Distributional Consequences of Mrs Thatcher. Fiscal Studies 7 (2): 48-53. https://doi.org/10.1111/j.1475-5890.1986.tb00421.x.
Dilnot, Andrew, Graham Stark, Ian Walker, and Steven Webb. 1987. -The 1987 Budget in Perspective-. Fiscal Studies 8 (2): 48-57. https://doi.org/10.1111/j.1475-5890.1987.tb00535.x.
Robinson, Bill, and Graham Stark. 1988. -The Tax Treatment of Marriage: What Has the Chancellor Really Achieved?- Fiscal Studies 9 (2): 48-56.
Stark, Graham. 1988. -Partially Transferable Allowances-. Fiscal Studies 9 (1): 29-40. https://doi.org/10.1111/j.1475-5890.1988.tb00310.x.
Johnson, Paul, and Graham Stark. 1989. -Ten Years of Mrs Thatcher: The Distributional Consequences-. Fiscal Studies 10 (2): 29-37.
Johnson, Paul, and Graham Stark. 1991. -The Effects of a Minimum Wage on Family Incomes-. Fiscal Studies 12 (3): 88-93. https://doi.org/10.1111/j.1475-5890.1991.tb00164.x.

Understanding of microsimulation methods
Johnson, Paul, Steven Webb, and Graham Stark. 1990. -TAXBEN2: The New IFS Tax and Benefit Model-. IFS Working Paper W90/5. https://doi.org/10.1111/j.1475-5890.1989.tb00107.x.
Coulter, Fiona, Graham Stark, and Stephen Smith. 1995. -Micro-Simulation Modelling of Personal Taxation and Social Security Benefits in the Czech Republic-. IFS Working Paper Series W95/58.
Duncan, Alan, and Graham Stark. 2000. -A Recursive Algorithm to Generate Piecewise Linear Budget Contraints-. 2 May 2000. https://doi.org/10.1920/wp.ifs.2000.0011.
Reed, Howard, and Graham Stark. 2011. Modelling the Costs for Individuals and Public Authorities in Wales of Alternative Funding Systems for the Long-Term Care of Adults: Stage 1 Report: Building a Forecasting Model for Long-Term Care in Wales. Welsh Assembly Government.

Austerity-era poverty interventions
Since beginning consultancy, I have received over -500,000 in funding from public and third sector bodies (Scottish Government, Welsh Assembly, United Nations, etc.), on top of regular grant acquisition while at the IFS (Nuffield, etc.). This has led to cutting edge research on the impact of austerity-era poverty interventions:
Reed, Howard, and Graham Stark. 2011. Modelling the Costs for Individuals and Public Authorities in Wales of Alternative Funding Systems for the Long-Term Care of Adults. Welsh Assembly Government.
Reed, Howard, and Graham Stark. 2013. Costing the -When I Am Ready- Scheme. Action for Children Wales/Gweithredu dros Blant.
Reed, Howard, and Graham Stark. 2018. Tackling Child Poverty Delivery Plan: Forecasting Child Poverty in Scotland. Scottish Government. http://www.gov.scot/Publications/2018/03/2911/0.
Reed, Howard, and Graham Stark. 2020. Giving Care Leavers the Chance to Stay: Staying Put Six Years on: Technical Report. Action for Children England. https://doi.org/10.1111/j.1475-5890.1988.tb00319.x.
Reed, Howard, and Graham Stark. 2009a. Assessing the Ability to Pay for the Fees Charged by Charities: Phase 1 & 2. February, 36. Office of the Scottish Charities Regulator (OSCR). http://www.oscr.org.uk/publications-and-guidance/affordability-reportphase-2/.
Stark, Graham. 2021. Staying Put Six Years on: 2021 Update. Action for Children England.




