#set heading(
  numbering: "1.")
#set text(font:"Palatino Linotype")

#show link: set text(blue)
#show heading: set text(font: "Gill Sans")
#show raw: set text(font:"JuliaMono",size:8pt,navy)

#include "standard-typst.typ"

IMA 2026 Congress Proposals

- #link( "mailto:graham.stark@notrthumbria.ac.uk.")[Graham Stark] University of Northumbria
- #link( "mailto:howard.reed@northumbria.ac.uk")[Howard Reed] University of Northumbria and Landman Economics
- #link( "mailto:juan-pedro@futureeconomy.scot")[Juan-Pedro Castro] Future Economy Scotland
- #link( "mailto:")[Daniel Mermenstien] University of Northumbria

Here are three proposals for the 2026 IMA conference from our small group at the University of Northumbria, UK. All three are concern current projects that are in development, but
project 2) below is substantially complete and are confident we will have interesting and substantiative results for the other two in good time for the conference.

= A Static Microsimulation Model of Farming in England And Wales

Presenter: Graham Stark

== Summary

This talk describes a new farm-level microsimulation model of agriculture in England and Wales.
The model is in the spirit of @odonoghue_farm-level_2017. It uses pooled data from the
Farm Business Survey@department_for_environment_food__rural_affairs_farm_2025.

== Objectives

1. To capture the likely effects of the rapidly changing tax and subsidy
   regime on the farming sector in England and Wales@coe_new_2024;
2. To explore the effects on rural poverty of direct payments to farmers and their employees.

More generally, a new farm-level microsimulation model is a timely thing given the unpredictability
of world trade in agriculture, taxes on carbon, etc.,

== Research Questions 

1. Can we capture the effects of a subsidy regime which was changing radically during the period our micro data was collected?
2. Can we use an enterprise-level model to say something useful about the distribution of income of households and individuals?   

== Theoretical Framework

This is a static microsimulation model in the spirit of O'Donahue. It doesn't attempt to understand the extent to which the new regime is likely to change behaviour. However, as with any microsimulation model, good static  modelling is the foundation of good behavioural work. 

== Methods

This is a work in progress. 

The model is implemented in the Julia programming language@bezanson_julia_2017 and 
borrows the structure and some code from the #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/")[Scotben] household microsimulation model (Scotben has previously presented IMA conferences).

Linear regressions are used to capture the largely discretionary operation of the new regime (the previous). A version of the previous EU scheme is also modelled using more conventional rules-based modelling.

For assessing policies at the household and individual level, we augment the FBS data with matched FRS records.  

In practice much of the work so far has consisted of ploughing through and reorganising a poorly documented, weirdly arranged dataset but we shall spare attendees much of that. (Simply getting hold of the FBS data was a saga in itself).

== Results

At present we are just at the point of having a model with useable results. The intended initial output is an assessment of the static effects of shifting some or all of the subsidy regime towards direct payments to farmers and farm workers. This should be ready in good time for the Congress. 

#pagebreak()

= Modelling Fiscal Options for Scotland

Presenters: Juan-Pedro Castro, Howard Reed, Graham Stark.

== Summary

#link("https://www.futureeconomy.scot/")[Future Economy Scotland] (FES) is a non-partisan think tank that aims to create a new economy that is democratic, sustainable and just. 
FES have been funded by #link("https://www.aberdeenplc.com/en-gb/corporate-sustainability/aberdeen-group-charitable-trust")[Aberdeen Group Charitable Trust] to produce a comprehensive 
report on fiscal options for the devolved Scottish government. This is due to be published in March 2026. 

This talk describes our experience of working with FES to produce microsimulation modelling for the whole range of devolved taxes, which a view to finding the fairest and most equitable way of raising significant revenue for funding a just Green Transition. 

The exercise was an excellent stress-test for the #link("ScotBen")[https://github.com/grahamstark/ScottishTaxBenefitModel.jl/] microsimulation model of Scotland, prompting many improvements, especially in its outputs and documentation. 

Much of the output from the exercise is in the form of interactive notebooks. Manipulating these can work very well as live demonstrations (and sometimes be a disaster, of course). 

== Objectives

We were tasked with modelling the entire set of taxes and benefits currently devolved to the Scottish Parliament, as well as hypothetical new taxes such as taxes on Wealth and local-authority level Proportional Property Taxes. 

== Research Questions 

Can we build a comprehensive, internally-consistent, suite of simulation models that capture the effects on Scottish households of all available fiscal measure, and present the results in an intelligibe way? 

== Theoretical Framework

The models used are predominantly classic static microsimulation models. However, a new module was added to ScotBen to capture behavioural adjustments to income tax changes patterned after@scottish_fiscal_commission_how_2018.

== Methods

Modelling used Scotben and a variety of smaller custom-built models. Scotben was significantly overhauled for this exercise. Datasets used include the Family Resources Survey (FRS), Wealth and Assets Survey (WAS) and the Scottish Household Survey (SHS). 

As a preliminary, a comparison exercise was carried out between the Scottish variant of UKMod and Scotben. This exercise  might be worth discussing in itself; much was learned and ScotBen came out quite well. 

A lot of work was put in to improve interaction between the modellers and the report authors. Instead of simply providing results, customised #link("https://plutojl.org/")[Pluto Notebooks] were built that could be manipulated by the report writers. The proposed talk will be 
built around these notebooks. 

Relevant links:

- #link("https://stb-blog.virtual-worlds.scot/assets/scottish-budget-2026-pluto.pdf")[A slightly imperfect PDF rendering of one of our notebooks];
- #link("https://github.com/grahamstark/MicrosimTraining")[Repository of all the notebooks and associated graphics and tabulating code].

== Results

The report will be published in good time for the Congress. 

#pagebreak()

= An API for Microsimulation Models

presenters: Daniel Mermenstien, Graham Stark

== Summary

_Note: this proposal doesn't easily fit into the IMA's Summary/Objectives/Methods framework._

An API is a set of standardised rules that allow one piece of software to request and receive 
information or services from another piece of software. Much of modern life - online shopping, banking, paying taxes - is built around simple standardised APIs. 

This talk describes a simple API for interacting with microsimulation models. The initial intended use case for the API is embedding a tax benefit model into an online learning platform, with the model itself hosted on a different computer; possible other uses include  building 'mashups' of simulations from different providers and running on different computers, integrating realistic simulations into games, and running models from inside Content Management Systems (CMSs) such as WordPress. 

Standards have been developed for how such APIs should be designed@masse_rest_2011 and described@noauthor_swagger_2025, and the proposed API tries to adhere to these standards.

There have been online, publicly available versions of large Microsimulation models since the mid-1990s; the Institute for Fiscal Studies' #link("https://web.archive.org/web/19970414074226/http://www.ifs.org.uk/DISCLAIM.HTM")[Be Your Own Chancellor] (1995) and #link("https://virtual-worlds-research.com/demonstrations/virtual-economy/")[Virtual Economy]
(1999) were early examples. Contemporary examples include the #link("https://adrs-global.com/")[ADRS suite of South African simulations],
#link("https://triplepc.northumbria.ac.uk/")[TriplePC] and the University of Essex's #link("https://www.microsimulation.ac.uk/ukmod/")[UK Mod].

These online models are implemented in different ways. TriplePC has the underlying simulation model and the web interface written in the same programming language@bezanson_julia_2017, integrated into a single package. Older systems, and UKMod, have the public facing 'front end' written in a specialist languages such as PHP@bakken_php_2000, whilst the actual models are developed seperately and invoked as required by the front-end.

Microsimulation models have a number of common characteristics:

- they typically have a large number of inputs, outputs and other controls. It can take dozens of parameters to characterise, for example, an income tax system - tax rates, various allowances, switches for different options and so on;
- healthy models constantly evolve, as they are improved and as the world they try to capture changes. It's rarely a good sign when a model has the same inputs and outputs now as last year;
- they are typically (though not always) resource-intensive and long running - from a few seconds up to hours or even days. (Even a few seconds is a long time for a typical API service);
- models typically go through a number of distinct phases - sitting in a job queue, initialising, running calculations, generating output, and so on.

This is work in progress and the specification is likely to change considerably before it could be considered generally useful. Currently we have #link("https://github.com/grahamstark/MicrosimAPIv1")[one implementation of the API backend, in Julia] and #link("https://scotben25.virtual-worlds.scot/")[one test front-end] that uses it. 

Our intention is that by the IMA Congress we will have further developed the API and its documentation, and built a second test implementation back-end in Python using Howard Reed's Landman microsimulation model.

The proposed talk will discuss the general ideas, demonstrate what we have, and, most importantly, seek help and suggestions from the community.

#pagebreak()

#bibliography("IMA-2026.bib",style:"harvard-cite-them-right"),
