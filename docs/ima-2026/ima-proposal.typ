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

Graham Stark

== Summary

This talk describes a new farm-level microsimulation model of agriculture in England and Wales.
The model is in the spirit of @odonoghue_farm-level_2017. It uses pooled data from the
Farm Business Survey@department_for_environment_food__rural_affairs_farm_2025.

== Objectives

1. To capture the likely effects of the rapidly changing tax and subsidy
   regime on the farming sector in England and Wales@coe_new_2024;
2. To explore the effects on rural poverty of direct  

More generally, an independent microsimulation of farms seems a timely thing given the unpredictability
of world trade in agriculture, taxes on carbon, etc.,

== Research Questions 

1. Can we capture the effects of a subsidy regime which was changing radically during the period our micro data was collected?
2. Can we use an enterprise-level model to say something useful about the distribution of income of households and individuals?   

== Theoretical Framework

This is a static microsimulation model in the spirit of O'Donahue. That is, it doesn't attempt to understand the extent to which
the new regime is likely to achieve its objectives of improving conservation. However, as with any microsimulation model, good static 
modelling is the foundation of good behavioural work. 

== Methods

This is a work in progress. The model is implemented in the #link("x")[Julia] programming language and 
borrows the structure and some code from the #link("x")[Scotben] household microsimulation model, previously discussed at the IMA conference.
Linear regressions are used to capture the largely discretionary operation of the new regime (the previous) EU scheme can me modelled using more conventional rules-based modelling.

For assessing policies at the household and individual level, we augment the FBS data with matched FRS records.  

In practice much of the work so far has consisted of ploughing through and reorganising a poorly documented, weirdly arranged dataset but we shall spare
attendees much of that. Simply getting hold of the FBS data is a saga in itself.

== Results

At present we have no useable results. The intended initial output is an assessment of the static effects of shifting some or all of
the subsidy regime towards direct payments to farmers and farm workers. This should be ready in good time for the Congress. 

#pagebreak()

=  Modelling Fiscal Options for Scotland

Juan-Pedro Castro
Howard Reed
Graham stark

== Summary

#link("https://www.futureeconomy.scot/")[Future Economy Scotland] (FES) is a non-partisan think tank that aims to create a new economy that is democratic, sustainable and just. 
FES have been funded by #link("https://www.aberdeenplc.com/en-gb/corporate-sustainability/aberdeen-group-charitable-trust")[Aberdeen Group Charitable Trust] to produce a comprehensive 
report on fiscal options for the devolved Scottish government, due to be published in March 2026. This talk describes our experience of working with FES to produce microsimulation modelling for the whole range 
of devolved taxes, which a view to finding the fairest and most equitable way of raising significant revenue for funding a 
just Green Transition. 

The exercise was an excellent stress-test for the ScotBen microsimulation model of Scotland, 
prompting many improvements, especially in its outputs and documentation. 

Much of the output from the exercise is in the form of interactive notebooks. Manipulating these can work very well 
as live demonstrations (and sometimes be a disaster, of course). 

== Objectives

We were tasked with modelling the entire set of taxes and benefits currently devolved to the Scottish Parliament, as well
as hypothetical new taxes such as taxes on Wealth and local-authority level Proportional Property Taxes. 

== Research Questions 

Can a build a comprehensive, internally-consistent, suite of simulation models that capture the effects on Scottish households of all 
the measures available. 

== Theoretical Framework

The models used are predominantly classic static microsimulation models. However, a new module was added to ScotBen to capture behavioural 
adjustments to income tax changes.

== Methods

Modelling used Scotben and a variety of smaller custom-built models. Scotben was significantly overhauled for this exercise. 

Datasets used include, the Family Resources Survey (FRS), Wealth and Assets Survey (WAS) and the Scottish Household Survey (SHS). 

As a preliminary, a comparison exercise was carried out between the Scottish variant of UKMod and Scotben. This exercise 
might be worth discussing in itself; much was learned and ScotBen came out quite well. 

A lot of work was put in to improve interaction between the modellers and the report authors. Instead of simply providing results, 
customised #link("pluto")[Pluto Notebooks] were built that could be manipulated by the report writers. The proposed talk will be 
built around these notebooks 

== Results

The report will be published in good time for the Congress. 

#pagebreak()

= An API for Microsimulation Models

== Summary

This talk describes a simple API for interacting with microsimulation models. The initial intended use case for the API is embedding a tax benefit model into an online learning platform; possible other uses include  building 'mashups' of simulations from different providers, integrating realistic simulations into games, and running models from inside Content Management Systems (CMSs) such as WordPress. 

== Objectives

An API is a set of standardised rules that allow one piece of software to request and receive 
information or services from another piece of software. Much of the life - online shopping, banking, paying taxes - is built around simple standardised APIs. 

Standards have been developed for how such APIs should be designed@masse_rest_2011 and described@noauthor_swagger_2025, and the proposed API tries to adhere to these standards.

There have been online, publicly available versions of large Microsimulation models since the mid-1990s;
the Institute for Fiscal Studies' #link("https://web.archive.org/web/19970414074226/http://www.ifs.org.uk/DISCLAIM.HTM")[Be Your Own Chancellor]
(1995) and #link("https://virtual-worlds-research.com/demonstrations/virtual-economy/")[Virtual Economy]
(1999) were early examples. Contemporary examples include the #link("https://adrs-global.com/")[ADRS suite of South African simulations],
#link("x")[TriplePC] and the University of Essex's #link("x")[UK Mod].

These online 
models are implemented in different ways. TriplePC has the underlying simulation model and the web interface written in the same programming language (Julia@bezanson_julia:_2017), integrated into a single package. Older systems, and UKMod, have the public facing 'front end' written in a specialist languages like PHP@bakken_php_2000 or Java@arnold_java_2005, whilst the actual models are developed seperately and invoked as required by the front-end.

Microsimulation models have a number of common characteristics:

- they typically have a large number of inputs, outputs and other controls. It can take dozens of parameters to characterise, for example, an income tax system - tax rates, various allowances, switches for different options and so on;
- healthy models constantly evolve, as they are improved and as the world they try to capture changes. It's rarely a good sign when a model has the same inputs and outputs now as last year;
- they are typically (though not always) resource-intensive and long running - from a few seconds up to hours or even days. (Even a few seconds is a long time for a typical API service);
- models typically go through a number of distinct phases - sitting in a job queue, initialising, running calculations, generating output, and so on.

== Research Questions 



== Theoretical Framework

== Methods

This is how the test implementation works currently.

1. (Possibly, and not yet implemented) Client queries the server: available memory, jobs running, jobs queued, etc.

2. Client starts a session (this may be implied when e.g. the client sends some parameters, or explicit). Possibly an API token is provided. Server side, defautlt parameters and outputs are created and assigned to the session.

Note: parameters can be divided into policy parameters (e.g. tax rates) and run settings (e.g. numbers of households to run over).These are treated as seperate records;

3. Optionally, client queries the server for the required structure of inputs and outputs. The response might be in JSON, XML etc. and includes names of parameters, minima and maxima, preferred formats, etc. Possibly the client builds a UI automatically from this information (I have a rough version of this). Alternatively, the client might have a pre-built UI, as in the Scotben demo. Server site, these replies might simply be some static files;

4. Client gets inputs, probably from a web form, packages them in the format required by (3) and sends them to the server. This may happen serveral times. Server side, the parameters are validated and either an error message is sent back or the session parameters are updated.

5. The client runs the model. Server side:
 - a run data structure is created for monitoring and holding output in a server dictionary. This is keyed by a hash of the parameter values - if the key already exists, we send back stored results instantly. The run id is added to the session information for the user;
 - if no instant reply, the set of parameters is placed in a job queue. Jobs are pulled out of the queue by model run workers.

 Doing it this way allows the server to respond instantly to the run submission. In the test implementation the job queue is simply an Channel structure on the server, but bigger implementations might use proper queue software like Torque (I've used this before)

6. The server monitors the job. In the test implementation, we use an observer/observable pattern to write a short record to the run dictionary every time some event happens (additional 1,000 households processed, output creation phase reached etc.). Client side, a progress bar is drawn by repeatedly querying the server for run progress.

7. When the phase of the run is 'complete', the client begins making requests for output. In the test implementation, all the output is in json which is parsed into tables and graphs client-side. (The library for this is already huge).

8. Optionally, the session is destroyed.


== Results

We have 

#pagebreak()

#bibliography("IMA-2026.bib",style:"harvard-cite-them-right"),
