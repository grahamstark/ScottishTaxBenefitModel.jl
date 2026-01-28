=  IMA 2026 Congress Proposals

#link( "mailto:graham.stark@notrthumbria.ac.uk.")[Graham Stark]
#link( "mailto:")[Howard Reed]
#link( "mailto:")[Juan-Pedro Castro]
#link( "mailto:")[Daniel Mermenstien]

Here are four proposals ...

== 1: A Static Microsimulation Model of Farming in England And Wales

Graham Stark

=== Summary

This talk describes a new static microsimulation model of Farming in England and Wales.
The model is in the spirit of O'Donahue (XX,chXX). It uses pooled data from the
Farm Business Survey. 

=== Objectives

1. To capture the likely effects of the rapidly changing tax and subsidy
   regime on the farming sector in England and Wales;
2. To explore the effects on rural poverty of direct  

More generally, an independent microsimulation of farms seems a timely thing given the unpredictability
of world trade in agriculture, taxes on carbon, etc.,

=== Research Questions 

1. Can we capture the effects of a subsidy regime which was changing radically during the period our micro data was collected?
2. Can we use an enterprise-level model to say something useful about the distribution of income of households and individuals?   

=== Theoretical Framework

This is a static microsimulation model in the spirit of O'Donahue. That is, it doesn't attempt to understand the extent to which
the new regime is likely to achieve its objectives of improving conservation. However, as with any microsimulation model, good static 
modelling is the foundation of good behavioural work. 

=== Methods

This is a work in progress. The model is implemented in the #link("x")[Julia] programming language and 
borrows the structure and some code from the #link("x")[Scotben] household microsimulation model, previously discussed at the IMA conference.
Linear regressions are used to capture the largely discretionary operation of the new regime (the previous) EU scheme can me modelled using more conventional rules-based modelling.

For assessing policies at the household and individual level, we augment the FBS data with matched FRS records.  

In practice much of the work so far has consisted of ploughing through and reorganising a poorly documented, weirdly arranged dataset but we shall spare
attendees much of that. Simply getting hold of the FBS data is a saga in itself.

=== Results

At present we have no useable results. The intended initial output is an assessment of the static effects of shifting some or all of
the subsidy regime towards direct payments to farmers and farm workers. This should be ready in good time for the Congress. 

== 2: Modelling Fiscal Options for Scotland

Juan-Pedro Castro
Howard Reed
Graham stark

=== Summary


The Future Economy Scotland think tank is [...]. They have been funded by #link("xx")[Aberdeen ..] to produce a comprehensive 
.. "XXX", due to be published in ?? March 2026. This talk describes our experience of producing microsimulation modelling for the whole range 
of devolved taxes, which a view to finding the fairest and most equitable way of raising significant revenue for funding a 
just Green Transition. As a sub-nation of the United Kingdom, Scotland 


=== Objectives

The report is ... We were tasked with modelling the entire set of taxes and benefits currently devolved to the Scottish Parliament, as well
as hypothetical new taxes such as taxes on Wealth and local-authority level Proportional Property Taxes. 

=== Research Questions 

Can a build a comprehensive, internally-consistent, suite of simulation models that capture the effects on Scottish households of all 
the measures available

=== Theoretical Framework

=== Methods

Modeling used Scotben and a variety of smaller custom-built models. Scotben was significantly overhauled for this exercise. 

As a preliminary, a comparison exercise was carried out between the Scottish variant of UKMod and Scotben. This exercise 
might be worth discussing in itself; much was learned and ScotBen came out quite well. 

A lot of work was put in to improve interaction between the modellers and the report authors. Instead of simoly providing results, 
customised Pluto Notebooks were built that could be manipulated by the report writers.  

=== Results

The report is ... 

== 3: An API for Microsimulation Models 



=== Summary

=== Objectives

=== Research Questions 

=== Theoretical Framework

=== Methods

=== Results



