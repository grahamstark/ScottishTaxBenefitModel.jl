# Tax Benefit Models and Microsimulation

## Introduction

Let's start with some recent headlines:

* In Scotland, the Government responds to concern about rising child poverty by introducing a new cash benefit[^FN_SCOTTISH_CHILD];
* Meantime, the Scottish Government is warned that increasing higher rate income tax rates to pay for this might backfire[^FN_SCOT_INCOME_TAX_1];
* At the Conservative party conference, large increase in Minimum Wages are proposed[^FN_JAVED];
* Also at the conference, the Government proposes that Fuel Taxes - already frozen for eight years, be further cut[^FN_FUEL].

How can we analyse what's going on with these things? How can we understand the reasoning behind the decisions that were
made in each case?

This week we want to do two things:

1. firstly, we will discuss some ideas that can help you to think systematically about questions like these; and
2. give you a chance to experiment with a simple example of the most important tool used in this field - a Microsimulation Tax Benefit model.

What all our headlines have in common is that they are concerned with the impact on our diverse society of broad Government policies - on Social Security, wage setting, or the taxation of income and spending. We need to always keep this diversity in mind: Microsimulation is a way of confronting what may seem on paper a good, simple idea with the
reality of a society with rich and poor, able and disabled, young and old, conventional nuclear families and those living in very different arrangements. But the very complexity of a modern society makes it all the more important that we have a few organising principles to guide us - it's no use just holding our hands up and saying "it's all very
complicated" - even if it is.

Broadly, we can group the questions we might want to ask about our policies changes into two:

1. policy changes inevitably produce gainers and losers: some people might be better off, and some worse off, and we want to summarise those changes in an intelligible way. This leads us to the study of measures such as poverty and inequality; when we come to do some modelling we'll also consider some more prosaic measures such as counts of gainers
and losers disaggregated in various ways, aggregate costings and the like;

2. our policy changes may alter the way the economy works in some way - for example an income tax cut might make people work more (or, as we'll see, less), or a tax on plastic bags might lead people to use less of them. Some of these effects may be beneficial and part of the intention of the change, others may be harmful and unintentional. A useful is organising idea here is *fiscal neutrality* - if we start from the broad premise that a market economy is a reasonably efficient thing, then we should design our fiscal system should so as to alter the behaviour of the economy as little as possible, unless there is some clear argument why we should do otherwise.

Much of the art of policy analysis and policy design lies in balancing these two aspects; for example, redistributing
income whilst maintaining incentives to work, or raising taxes on some harmful good without hurting the poorest and most
vulnerable.

The distributional and incentive analysis of policy changes, and the art of balancing these things, are huge and technical subjects that go well beyond this course, but we aim to equip you with many of the key ideas and give you a flavour of where more advanced treatments might take you. As you'll see, you can get remarkably far with a few simple measures.

A note on our language. This section is quite jargon-heavy, and covers a lot of technical issues. None of it is especially difficult, but it does mean that we will be approaching questions about very personal things like poverty, whether it's worth working, or whether people are being treated fairly, in a relatively detached, technocratic way. Many people find this detachment distasteful[^FN_MOND]. The detachment of many researchers in this field from the problems they are modelling can be a problem, but I hope to show that there are things that a technocratic, data-driven approach can be of use to those with strong personal commitments, whatever those commitments might be.

### Outline Of the Week

The week is split in two:

1. in the first part, we'll take you through many of the concepts needed to interpret the outputs of a tax-benefit microsimulation model. Some of this material has already been covered earlier in the course, and some is also covered in other OU courses that you may have studied, in particular DD209 book 2, chapter 19 and DB125, chapter 3, but here the emphasis is on how things can be measured in practice;
2. We then get you hands-on with our tax-benefit model. Initially we'll use the model to study how the tax and benefit system affects just one example person: this lets you explore how the tax and benefit system affects incentives. We'll then move on to using the model on a full, representative dataset - after a few exercises to give you a feel for how the model behaves, we'll invite you to take charge of the economy and design some packages of measures that Governments of different persuasions might adopt.


### Learning Outcomes

After completing this week, you should:

1. be able to read reports produced using microsimulation techniques, and understand the concepts and something of the mechanics of how they were produced, as well of having a feel for their limitations[^FN_MS_EXAMPLES];
2. understand how to present rich and detailed results produced by a microsimulation model from differing angles - for example, as a technical report, a submission from lobbyist,  or as journalism;
3. understand how to construct packages of measures that meet some policy objectives, and understand how objectives may need to be traded off;
4. understand, at least in outline, some important microsimulation concepts and techniques:
   - the pros and cons of different types of large-sample datasets;
   - how these large dataset are used in microsimulation, including data weighting and uprating;
   - techniques for the measurement of poverty and inequality;
   - measures of the incentive effects of taxation, including marginal and average tax rates, replacement rates.

We are not trying to equip you to actually *write* a microsimulation model; the program code for the tax-benefit model is available and might well be of interest to those of you with a technical background, but nothing in this week depends on you doing this.
