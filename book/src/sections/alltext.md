##Introduction

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
##Some Concepts

## Some Concepts

Economics is about people - about how people behave, and whether we can make people better or worse off in some sense. But there are a lot of people - 60m in the UK, and every one is different. In principle we could just list the effects of some tax change on all 60m, but without some organising principles it would be impossible to make sense of the results. If we are going to get anywhere here we need some abstractions.

So, in this section, I'll start by briefly revisiting the summary statistics you met in block 1 - means, medians, totals, and some simple charts. In subsequent sections we'll then briefly discuss poverty, inequality - these everyday words have distinct technical meanings here[^FN_POVOLD]. Mostly we'll be talking about people's incomes, but before we get on to the model, I'll briefly double back and discuss what the thing that we're trying to summarise should be: should it be people's income, or consumption, or should we go directly for some measure of happiness? Do we need to account for different living arrangements?

### Summary Statistics

Here's a picture of one measure of the UK income distribution, as a bar chart.

![2018/9 HBAI Income distribution](./images/uk_income_hbai_2018-8.png)

This comes from thee [Department for Work and Pensions]() (DWP) [Households Below Average Income]() (HBAI) data series [^FN_HBAI]

This shows distribution an official UK measure of income for the financial year 2017/8[^FN_FINANCIAL_YEAR], the latest available at the time of writing:

The income measure is "Equivalised Net Household Income, Before Housing Costs". In the sections that follow we'll discuss in some detail what you should take each of those words to mean, and consider some other possible measures. But for now, just think of it as "UK income".

The chart uses data from the Family Resources Survey (FRS) [^FN_FRS], a large annual survey that provides detailed information about the incomes and living circumstances of households and families in the UK. The microsimulation model used later in this section also uses the FRS. The FRS is one of several large UK surveys. I'll further discuss large sample surveys below, and let you explore the FRS using our tax-benefit model.

There's a lot of useful material in this graph. Income in £per week is on X-axis, in £10 bands, and an estimate of the numbers of people in each band on the y-axis.

The chart is a little misleading in that it stops at £1,000pw. In reality, there are people with incomes higher than that - literally off-the-scale - so the full graph stretches far to the right. It's likely that the chart is truncated at £1,000 because very high incomes are hard to measure; I'll return to this point later,

It's useful to be able to summarise this data in various ways. The mean and median that you encountered in block 1 are useful:

* The Mean income is £613;
* the Median £517: half the population is richer than the median, and half poorer;

Note how the mean income is nearly £100 higher than the median. This is because there are a large number of relatively small incomes (around where the graph peaks), but a few very large ones out to the right (incomes are 'skewed right'). The large incomes pull the mean up away from the median. Right-skewed data like this is very common in economics - not only income but the size of companies or national incomes of countries, or the distribution of wealth or consumption.

#### Activity

Open [this spreadsheet](/activities/activity_1.xlsx). It contains some income distribution data for an imaginary country of 1,000 people. Incomes are heavily right-skewed.

1) Find the minimum, maximum, mean and the median. Ans:

     min	43.69
     max	22,640.63
     mean	1,696.22
     median	1,043.17

2) Draw a bar chart similar the HBAI chart above (don't worry about creating the shading). Ans: should look a bit like:
![Bar Chart of 1,000 log-normal incomes](/activities/activity_1.svg)

2) Now double the income of the 10 richest people. What happens to the mean and median. Ans:

     min	43.69
     max	45,281.25
     mean	1,857.70
     median	1,043.17


#### Other things to note

The insensitivity to changes at the very top that you see in the activity is why the median is often preferred to the mean in economic discussions. Very high incomes are hard to measure in sample surveys, because it's hard to persuade very rich people to participate, because those rich people who do participate may understate their income, and because the circumstances of the rich can be too complex to fit easily into a standard survey, and so recorded top incomes are uncertain and tend to jump around from year-to-year[^FN_SPI].

When you hear a discussion about how some change affects an "average person", you should remember that an average person could well be comparatively rich.

A couple of other things of note in that graph.

1. The Line marked "60% of median (£304pw)" is the official UK poverty line - 60% of median income for that year (note the use of median over mean, for the reasons we've just discussed). We return to poverty below.
2. The chart is shaded into `deciles`. The dark area on the left labelled "1" contains the poorest tenth of the population, the lighter area labelled "2" to the left of that is the next poorest tenth and so on. Chopping the population up like into progressively richer chunks is a simple but very useful trick. For example, you can see that the mean is 1/2 way up the 7th decile, so about 65% of people have an income less than the mean[^FN_INCOME_HHLD], and that the poverty line is just below the start of the 3rd decile, so about 18% of people are in poverty, on this measure. We'll be using deciles a lot in what follows

Often, when we are trying to understand complex data like this one, the best place to start is by drawing pictures of it. The HBAI chart above is a particularly rich one, with, as we've seen, lots of different facets, and I'll come to a few other standard charts as we go on.
##Large Sample Datasets

## Large Sample Datasets

### Introduction

As we've mentioned, the modelling and analysis we'll be doing here mostly uses data from the UK Family Resources Survey (FRS). The FRS is one of several large household survey datasets for the UK - you've already encountered one example when examining the Gender Pay Gap in Block 1.

Each dataset has its own speciality, for example:

* the Wealth And Assets Survey (WAS) [^FN_WAS] - this contains very detailed information on household wealth - the value of houses, pension funds, savings and the like;
* Living Costs and Food Survey (LCF) [^FN_LCF] - this concentrates on recording household expenditure. One if the LCF's main uses is providing the weights used in compiling the various measures of inflation, including the Consumer Price index and Retail Price Index.
* Understanding Society [^FN_US] - this tracks a sample of people each year, recording their health, incomes, and social attitudes.
* English Longitudinal Survey of Ageing (ELSA) [^FN_ELSA] - like US, this is tracks a sample elderly people over time, with specialised questions on health, social care and the like.

There is a good deal of overlap between all of them - all need the same basic demographic information - people's ages, gender, employment status and so on, and all ask at least some basic information on income and wealth, though the FRS  goes into much more detail on incomes and WAS on wealth. All of them have been used in various specialised microsimulation models [^FNWALES].

By the standards of modern 'Big Data', our datasets are relatively small - a few thousand households[^FN_SAMPLE_SIZE] rather than the millions of observations available to the likes of Google or Facebook, but they more than compensate for this in the richness, accuracy and detail of what's recorded.

All these major surveys are collected face-to-face using trained interviewers[^FN_INTERVIEW]. This is expensive, but necessary given the very complex material collected. All except ELSA are surveys of households - they skip, for example, rough sleepers, people in care homes, barracks, prisons and the like. (ELSA follows people to care homes). They all aim to to be representative samples of UK households[^FN_ELSA_REP], usually by picking addresses randomly from complete lists of all UK addresses[^FN_RANDOM]. The list of all the things that could be sampled is known as the *sample frame*, and the proportion of addresses picked is known as the *sample frequency*: if we pick one household in every 5,000, the sample frequency is 1/5000 = 0.0002.

The FRS, WAS, and LCF are *cross-section* surveys - each year a new set of households is surveyed. Understanding Society and ELSA, are *Longitudinal*[^FN_PANEL] surveys, where the same people are re-interviewed each year. Longitudinal surveys have advantages. For example, in the econometric modelling you came across earlier, there is always the worry that the variation in the thing you're trying to explain (the 'dependent variable') is because of things you can't observe in your dataset, such as tastes, attitudes and the like ('unobserved heterogeneity' in the jargon); it's often possible to exploit the structure of a panel dataset to eliminate this heterogeneity, and so focus in on just systematic influences. But this power comes at a cost. It's much more expensive to gather a Longitudinal dataset than a cross-section of the same size. With a Longitudinal dataset, if one your subjects decides to go to live in the other end of the country, you have to send your interviewer after them. With cross sections, it's usually good enough to pick streets or blocks of flats at random, and then interview a bunch of people in that street - "stratified sampling" rather than "random sampling". Also, since it's very important to keep people in the Longitudinal survey for as long as possible, there's a tendency not to ask the kinds of burdensome questions about incomes, spending or wealth that the cross-sectional surveys might get away with once.

Mostly, our surveys ask questions about the household in a given month or week, with a few questions about how the household has been faring in the longer term. With Longitudinal data, of course, we can look back at previous years to get a picture of how things have evolved over time.

### Grossing Up and Non-Response

If a sample survey is truly representative of the population we can multiply up the data by the inverse of the sample frequency to get population estimates. If we see, say, 200 people in the survey with a certain disability, and the sample frequency is 1/2000, our best estimate is that there are 400,000 (2,000×200) such people in the country. In microsimulation, this step is know as *grossing up*, and the number we're multiplying our sample by (2,000 in this example) is known as the *grossing factor*.

However, these surveys are voluntary; unlike the Census, no-one can be compelled to participate in the FRS or LCF, and indeed only about 50% of those approached agree to. (Participation in the Family Expenditure Survey, the predecessor to these surveys, was over 80% in the early 1960s, but participation has declined steadily ever since)[^FN_PARTIC]. If non-participation was random, this wouldn't pose much of a problem, but in reality some types of household are much less likely to participate - those with high incomes, or sick or disabled members, for instance. In microsimulation jargon, this is *response bias*. A way around this is *differential weighting*. If, because of response bias, a dataset sampled 1 in every 100 working aged adults, but 1 in 200 pensioners, we could simply gross up each working aged person by 100, but each pensioner by 200, and that would give us the correct total for each group. For this to work, of course, we need some external source of information on what the actual number of pensioners and working age adults should be; information like this typically comes from the Census (which should include everybody) or other official sources such as tax-returns or the electoral roll. In practice things are more complicated than this, because there is response bias in multiple dimensions - not just by age, but also income, health, location, and other characteristics. Methods exist that can calculate weights that will allow a dataset to be grossed up so as to give correct totals for multiple sets of targets [^FN_CREEDY]. The model you will be exploring presently uses such a set of weights[^FN_ATTRITION].

#### Activity

Open [this spreadsheet](/activities/activity_2.xlsx). It contains a random sample from an imaginary country of 1,000,000 households. Pensioner households are coded `2` and non-pensioners `1`.

1) assuming this is a true random sample, what should the grossing factor be? Ans: there 100 observations from a population of 1,000,000. Therefore the sample frequency is `1,000,000/100 = 1/10,000`, and so the grossing factor = `10,000`
2) suppose instead that we know from a Census that there are 500,000 pensioner households and 500,000 non-pensioner households in the population. Is there evidence of response bias in the data? If, so, what should the grossing factors be to correct for this? (Hint: an easy way of counting the numbers of each type of household in the sample in Excel is to sort the data by household type and run the `count()` function across each group). Ans: there are 33 pensioners and 67 non pensioners in the dataset, so pensioners are under-represented and non-pensioners over-represented. To correct this, the grossing up factors for pensioners should be `33/500,000 ≈ 151,520` and for non-pensioners `67/500,000 ≈ 74,620`.

### Dealing with Uncertainty

If the re-ran our sampling procedure, randomly picking different households, we would likely get a slightly different number for our estimate of disabled people. So we can't be certain that 400,000 is the true number. We can use statistical theory to quantify the uncertainty around our estimate. We're not able to discuss the mechanics of this in detail here, but, broadly, the larger the sample and the smaller the amount of variation in our dataset, the more confidence we can have in our estimate[^FN_UNCERTAINTY]. The uncertainty is often expressed using "confidence intervals" (sometimes called the "margin of error" in popular discussions). Confidence intervals have a slightly unintuitive interpretation: roughly, if we re-ran our sampling many times, and calculated our confidence interval each time, the true value would be inside the interval in 95% of the samples. For simple cases like this, where we want the uncertainty surrounding an estimate there are usually nice formulas we can apply. But a microsimulation model might need information from dozens of variables (for wages, hours of work, and so on), and there might be other sources of uncertainty such as how people's behaviour responds to tax changes. In these cases, there may be no simple formula that we can use to calculate our confidence intervals. Instead, we often estimate uncertainty using *bootstrapping*. Bootstrapping involves running our calculations many times, each with as slightly different sample dataset, and perhaps also with different assumptions about behavioural responses. You can simulate a different sample by deleting a few observations randomly on each run[^FN_BOOTSTRAP]. The little simulation below shows a simple simulation of bootstrapping a sample dataset.

[![Stolen Bootstrap Animation Example](https://www.stat.auckland.ac.nz/~wild/BootAnim/animgif/bootstrap2.gif)](https://www.stat.auckland.ac.nz/~wild/BootAnim/movies/bootstrap2.mp4)

### Other Problems with large datasets

There are other difficulties we should briefly mention:

Firstly, some people might be reluctant to answer some embarrassing questions. When grossed up, the LCF records spending on smoking and drinking that are of about half the level suggested from official tax statistics[^FN_SMOKING]. This is *under-reporting*. (There may be other reasons for the survey estimates being too low, for example, a lot of smoking and drinking may be by non-households, such as tourists, and so outside the sample frame). Particularly important for out purposes is possible under-reporting of high incomes. In most official estimates of poverty and inequality, such as the HBAI estimates we discussed earlier, the incomes reported by the very richest people in the FRS are considered so unreliable that they are replaced entirely by imputed incomes derived from income tax records[^FN_JENKINS].

Secondly, even if we have the right sample, and even if the questions are answered accurately, the questions might be the wrong ones for the purposes of a microsimulation model. For example, in the FRS, the questions asked about wages and salaries are pretty close to those asked on a tax-return or benefit application form, but the questions on self-employment incomes are far from what's needed for an accurate tax calculation.
##Individuals, Families and Households

### Individuals, Families and Households

The HBAI graph we discussed earlier shows the distribution of incomes of individual people, and almost all of what follows is about the welfare of individuals. But people are social beings. Most people live in households (those living alone can be thought of one-person household). Others live in other arrangements: prisons, communes, barracks, care homes and the like, but, as we've seen, these are typically out of scope of our datasets.

The ONS define a household as follows:

> A household comprises of 1 person living alone or a group of people (not necessarily related) living at the same address who: share cooking facilities and share a living room or sitting room or dining area[^FN_HH_DEF]

Note the need for shared facilities and shared rooms. The circumstances of the household as a whole affects the wellbeing of each individual member. There are two main issues here:

1. Larger households might be more efficient than small ones. A two person household might not need twice the income of a one- person household to have the same standard of living. It's cheaper to buy food in bulk,  household might need only one fridge or cooker regardless of how large it is, and so on. Also member of larger households might be able to specialise, for example in paid or unpaid work;
2. household members might not get an equal share of what's available.

We'll consider these in turn.

#### Equivalence Scales

A scale that reflects the different needs and capabilities of households of different sizes is known as an *equivalence scale*. If households didn't get more efficient with size, and everyone had the same needs, then the equivalence scale would simply be 1 for a single person household, 2 for a two-person household and so on. If there are economies of scale, the numbers might be 1 for a single 1.5 for two-person, 1.8 for three. The scale might be lower for multi-person households with children, but higher for households with disabled or very elderly members.

You divide observed household income by the relevant scale to get *equivalised income* of the household, which is a measure of average wellbeing of the individual members. Recall that the HBAI figures we saw earlier use equivalised income[^FN_HBAI_METHODS].

Where might we get such a scale? There is an equivalence scale implicit in some state benefits; for example, here are the scale rates for Job Seeker's Allowance, a benefit paid to low-income families:

type                    |  £ per week |  proportion of single person
------------------------|-------------|-------
Single Person (age 25+) |  73.10      |  1.0  
Couple                  |  114.85     |  1.57
Child                   |  66.90      |  0.91

From this, you can see that if the scale for a single adult was 1.0, a 2 adult household would be 1.57, and a a two adult, one child household 2.48 (`1.57+0.91`).

However, these benefit amounts must themselves have come from somewhere. Can we derive and equivalence scale from first principles? One approach uses the regression techniques you learned in the previous week and the Living Costs and Food Survey I mentioned last time. The approach here dates back over 150 years, to the first ever systematic budget surveys, carried out in Germany by Ernst Engel. Engel was studying how shares of expenditure on different goods varied with income, and with family size [^FN_ENGEL]. He noticed two things:

1. although on average rich families spent more on food than poor ones, rich families spent a smaller share of their income on food than poor families;
2. larger families had a larger share of spending on food than smaller families with the same income.

Taken together, these give us to a simple strategy to estimates equivalence scales: households of different sizes have the same well being on average when their share of spending on food is the same.

Figure XX illustrates one way of doing this, using the 2017/8 edition of the Living Costs and Food Survey (LCF) we discussed last time.

I've plotted total spending by each household on the x- axis against the share of food in total spending on the y- axis. Each dot represents spending by one household. I've grouped the LCF households into those with children (marked in <span style='color:#ff762e'>orange</span>), and those without children (in <span style='color:#007aaf'>blue</span>). The two solid lines show the average food consumption at each level of total consumption for our two classes of household - these are known as *Engel Curves*[^FN_ENGEL]. The curves are computed using the regression techniques you studied in the macroeconomics week[^FN_BANKS].

You can see that, although there is a good deal of variation, the patterns Engel observed 150 years ago are there in this dataset.

![Source: author's calculations using 2017/8 Living Costs and Food Survey](./images/food_and_drink_engel_curve.png)

Now we can calculate an empirical equivalence scale. Pick some share of food spending - a good one might be the median food share (11.6%). That's the dashed horizontal line.  Then we look up on the Engel curves the level of total spending the two groups would on average need for this share. These are the points A and B on the diagram -  for households with children, this is £747.90 (point B) and for those without, it's £525.38 (A). The ratio between these is 1.423, which is our simple equivalence scale: our estimate is that families with children need 42% more spending than families without to enjoy the same standard of living.

A full analysis would do almost every aspect of this differently. You would want to allow for different household sizes and compositions, not just the presence or otherwise of children, and perhaps also other factors such as age, disability and the like. Nonetheless, I hope this shows you how a little bit of theory and a good dataset can be used to produce useful things in a straightforward manner. Much of the work of empirical economists, especially in the public sector, consists of doing simple exercises like this.

The HBAI data we looked at earlier is equivalised using the *Modified OECD Scale*[^FN_OECD_1], which is as follows:

type                   | proportion of single person
-----------------------|-------------
One Adult              |  1.0  
Two Adults             |  1.5
Two Adults, 1 child    |  1.8
Two Adults  2 children |  2.1
Two Adults  3 children |  2.4

and so on, with an extra 0.5 for each extra adult, and an extra 0.3 for each extra child (the OECD defines a child is someone aged 13 or under). The OECD scale is a standard scale used in many countries [^FN_OECD_2].

##### Activity

For this activity, we invite you to explore the LCF dataset we've just been using.

Download [our subset of the 2017/8 Living Costs and Food Survey data](/activities/activity_3.xlsx) and its [associated documentation](/activities/activity_3_coding_frame.docx). The dataset contains a small subset of the information on 5,376 households, including spending broken down into 13 groups and some demographic information (a few households with very extreme values have been deleted). Full details of the dataset are in the coding frame.

Mostly, these are not activities with a single right answer; instead, we invite you to explore the data using either Excel or any other tool you are familiar with. Questions 2,3 and 5 are especially difficult and you should feel under no pressure to attempt them.

1. generate shares of each expenditure group in total spending (note there are two different definitions of total spending in the dataset);
2. explore the relationship between the share (or level) of spending on each good and total spending or household income. You could do this by drawing scatter plots or, if you are ambitious, estimating your own Engel curves **FIXME HOW DO YOU DO RUN A REGRESSION IN EXCEL?**. For this you'd need to generate a column with the logarithm of total spending ;
ANSWER: The complete set of Engel Curves for this dataset is as follows:
<table>
    <tr><td><img src='/images/share_food_and_drink_single.png' alt='Engel curve'/></td><td><img src='/images/share_alcohol_tobacco_single.png' alt='Engel curve'/></td></tr>
    <tr><td><img src='/images/share_housing_single.png' alt='Engel curve'/></td><td><img src='/images/share_communication_single.png' alt='Engel curve'/></td></tr>
    <tr><td><img src='/images/share_non_consumption_single.png' alt='Engel curve'/></td><td><img src='/images/share_education_single.png' alt='Engel curve'/></td></tr>
    <tr><td><img src='/images/share_recreation_single.png' alt='Engel curve'/></td><td><img src='/images/share_clothing_single.png' alt='Engel curve'/></td></tr>
    <tr><td><img src='/images/share_miscellaneous_single.png' alt='Engel curve'/></td><td><img src='/images/share_transport_single.png' alt='Engel curve'/></td></tr>
    <tr><td><img src='/images/share_restaurants_etc_single.png' alt='Engel curve'/></td><td><img src='/images/share_health_single.png' alt='Engel curve'/></td></tr>
    <tr><td><img src='/images/share_household_goods_single.png' alt='Engel curve'/></td><td></td></tr>
</table>
3. explore how spending on some good appears to vary for different groups. You could do this by sorting the data on economic position of the head, tenure type, or region, and then computing means and medians for subgroups;
4. an alternative to Engel's method for computing equivalence scales is Barten's Method[^FN_BANKS_2], which proposes that families with and without children have the same standard of living when they have the same *level* of spending on *adult goods*.  
What problems do you see in applying Barten's method to this dataset?
ANSWER: a) it's hard to define "adult goods" and it would be impossible to identify them in this dataset. The only obvious candidate is the "alcohol and tobacco" group, but there are problems with that group: we know from last time that spending on these things is under-reported, and in our data many people report not spending anything at all on these things, which makes fitting a linear relationship problematic;
5. A very ambitious activity might be to actually calculate rough equivalence scales using Barten's method. You could assume the alcohol and tobacco group is representative of "adult goods". Alternatively, try sketching out what you thing the equivalent of the Engel analysis above might look like.
 ANSWER: should look something like:
 ![Barten Example](/images/barten_example.png)
Note that here we've dealt with the large number of zeros simply by deleting them, estimating instead over only those households who consume these goods. Since we're interested in the *level* of spending we've estimated a linear Engel curve. The implied equivalence scale is approximately 1.64.

##### End activity


#### Unequal distribution within households

Once we've equivalised our household incomes, we need to assign it to household member. Typically we just assign give everyone the average household income. But this ignores the possibility of discrimination by gender, or other characteristics such as age or disability.

Making a different assumption requires somehow looking inside households to infer how sharing of goods and the allocation of tasks actually works in practice[^FN_DEATON_CASE]. In principle can use our budget surveys to examine this question, using variants of the approach above. If we can identify specifically male, female-, or children's goods in our survey (clothing might be an example), then we can measure how spending on these vary between, for example, households where women have significant income of their own (through work or perhaps benefit payments), and households where all the income accrues to men. Alternatively, we could look at health or education outcomes - is shifting income between men and women associated with improvements in female health or school enrolment?  There have been many studies, and the evidence seems mixed[^FN_MIXED]. Consumption based studies tend to find no effect, whilst studies of health and education outcomes often show better outcomes in cases where incomes shifted from men to women.

#### Benefit Units

There's a further subdivision of households we should briefly consider. Some state benefits such as Universal Credit or Job Seeker's Allowance are assessed over 'benefit units' - roughly speaking, adults living together as a couple and any children dependent on them. A household with the a married couple and two children, and also an elderly parent, would be one household, but two benefit units, since the elderly parent would be assessed separately for means-tested benefits. In our model, and most modern analysis, benefit units are solely an indirect part of the modelling process, but in the past results were often presented at the benefit unit, rather than individual level [^FN_SOCIAL_METRICS_2].
##Poverty

### Poverty

#### Poverty Standards

For our purposes, those in poverty are those whose command over resources falls below some minimum acceptable standard. To make this operational - something we can measure, and design programmes to alleviate - we need to establish what this minimum is - our poverty line. In reality there is no single objective point above which people have an acceptable standard of life, and below which they do not; rather there is a continuum. Stress levels, for example, worsen steadily the poorer people get[^FN_STRESS], rather than jumping sharply at some point. There are a variety of ways we could define such a standard; discussing these at length would take us off-topic, but an interesting recent approach is to use focus groups to gauge public opinion on what an acceptable minimum standard might be[@hirsch_cost_2019]. And, as we've briefly noted, there are also multi-dimensional standards - recently the Social Metrics Commission has proposed one such for the UK [@social_metrics_commission_social_2019]. But, for now, it's enough that an official poverty line exists - for the UK, since 1991 (check!) it's been defined 2/3rds of median equivalised household income ]. This is the Households Below Average Income (HBAI) measure[^FN_HBAI_2]; looking back at figure 1, this is the line marked "£304pw" to the left of the chart; you can see straight away that, since the line falls towards the top of the second decile, about 18% of the population is in poverty on that measure.


#### Absolute and Relative Poverty

Because the HBAI line is defined using the income of the year in question,  it drifts up or down each year as median incomes rise and fall: it's a "relative poverty line". Indeed, poverty alleviation programmes will themselves change median incomes, and hence change the poverty line. For some purposes, therefore, we might also want to measure poverty against some unchanging standard: "absolute poverty". This can be done by picking an HBAI line for some reference year and, after adjusting it for price changes, applying it to subsequent years.

#### Aggregate  Measures of Poverty

Once we have a poverty line, we can use our survey data to estimate the level of poverty in our society, and when we come to our microsimulation model in the next section we can estimate how policy changes would change that level. The obvious way to do this simply to count the number of people below the poverty line - a 'Headcount' measure - and that is indeed what the official HBAI statistics do.

There is a problem with Headcounts, however, especially when we come to designing anti-poverty programmes. Consider someone with income just below the poverty line -Alice, on (say) £303pw - and someone far below the line - Bob on £203pw. Cut Bob's benefits by £2 and use the money to pay for a £2 increase for Alice. Alice is now above the poverty line, so is removed from the poverty headcount. Bob is further below the poverty line but still counts for one on the headcount measure. So we have reduced the poverty headcount by transferring money from a very poor person to a richer (though still quite poor) person.  This is not just an academic point - some significant reforms to the benefit system have had exactly this effect [^FN_FOWLER], cutting support benefits for those on very low incomes and increasing support for the 'near-poor'. And targets for poverty reduction, such as those in the Scottish Government's recent Child Poverty Bill [^FN_SCOTTISH_CHILD] are always more easily attained by targetting the near-poor than the very poor.

It would therefore be good to have a poverty measure that never improves when we transfer money from a poorer person to a richer one - the idea that measures of poverty or inequality should never improve from an upward transfer is known as *Dalton's Principle*[^FN_DALTON].

One obvious thing to do is to consider how far below the poverty line Alice and Bob are - Alice starts £1 below, and Bob £100. This leads to the poverty gap measure - summing up all the gaps for everyone gives the minimum amount that would have to be spent to eliminate poverty, if spending was perfectly targetted on the poor. (Poverty gaps are usually expressed as a fraction of the poverty line, so Alice's gap is 1/304 ≈ 0.003 and Bob's 100/304 ≈ 0.328). The poverty gap is useful, but still violates Dalton's principle - to see this, suppose now Bob was in the same position as before, but Alice started £50 below the poverty line.  The poverty gap is therefore £150 in total. Our transfer upwards of £2 from Bob to Alice makes no difference at all to this poverty gap - it's still £150, just distributed differently - £152 for Bob and £48 for Alice. So transfers upwards don't always worsen the poverty gap, again violating Dalton.

More sophisticated measures exist that do not violate Dalton's principle. The most commonly used is the Foster-Greer-Thorndyke measure[^FN_FGT] - sometimes known as the 'Poverty Severity Index'. This takes the proportional gaps, squares them, and then sums them - squaring the gaps means that the large gaps of very poor people like Bob become much more important in the final sum than small gaps of near-poor people like Alice. So our FTG measure for Alice and Bob would be 0.003^2 + 0.0328^2 ≈ 0.001. It can be shown mathematically that this measure can never be improved by an upwards transfer.

##### Activity
Open [this spreadsheet](/activities/activity_4.xlsx)

It contains data on the incomes of eight people from two small countries.  Country A has a poverty line of 200, and country B 150.

I've calculated the poverty headcount, poverty gap and poverty severity index for country A.

Your tasks are:

1	Fill in the poverty calculations for country B, in the same way as for country A
  Answer:
  <table>
  	<tr>
  		<td></td>
  		<td>1</td>
  		<td>2</td>
  		<td>3</td>
  		<td>4</td>
  		<td>5</td>
  		<td>6</td>
  		<td>7</td>
  		<td>8</td>
  		<td>Poverty Measure</td>
  		<td><b><br></b></td>
  	</tr>
  	<tr>
  		<td>Income </td>
  		<td>100</td>
  		<td>120</td>
  		<td>149</td>
  		<td>151</td>
  		<td>201</td>
  		<td>220</td>
  		<td>230</td>
  		<td>250</td>
  		<td><br></td>
  		<td><b><br></b></td>
  	</tr>
  	<tr>
  		<td>In Poverty (1=yes,0=no)</td>
  		<td>1</td>
  		<td>1</td>
  		<td>1</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0.375</td>
  		<td><b>Poverty Headcount</b></td>
  	</tr>
  	<tr>
  		<td>Poverty Gap</td>
  		<td>50</td>
  		<td>30</td>
  		<td>1</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0</td>
  		<td></td>
  		<td><b><br></b></td>
  	</tr>
  	<tr>
  		<td>Gap/Poverty Line</td>
  		<td>0.3333333333</td>
  		<td>0.2</td>
  		<td>0.0066666667</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0.0675</td>
  		<td><b>Poverty Gap</b></td>
  	</tr>
  	<tr>
  		<td>Poverty Severity</td>
  		<td>0.1111111111</td>
  		<td>0.04</td>
  		<td>0.00004444</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0</td>
  		<td>0.0188944444</td>
  		<td><b>Poverty Severity</b></td>
  	</tr>
  </table>
  (note that the numbers here may differ from yours slightly because of rounding)  
2.	experiment with the effects of transfers: can you find an example of an upwards transfer that violates Dalton’s principle for some of the poverty measures? Answer: for country A, an example would be:
  - take 1 away from person 3 and give it to person 4. Person 4 now has 200, and so is no longer in poverty, but person 1 has 149.
    the poverty *level* falls to 0.375 and the poverty *gap* remains unchanged at 0.144375, but poverty *severity* **increases** to 0.059378125

#### More sophisticated Measures

Even more sophisticated measures of poverty exist; for example, a measure proposed by Amartya Sen [^FN_SEN_POV] combines a measure of poverty with a measure of inequality amongst the poor (we come to inequality next).

The problem with ever more sophisticated measures is that they become progressively harder to explain to policy makers and the public more generally. And, of course, keeping civic society informed and on-side is a vital part of any successful anti-poverty strategy. Our microsimulation model can report all of these measures, and it can be a good exercise to consider which of them, if any, you'd want to report to different audiences.
##Inequality

### Inequality

Inequality is a broader concept than poverty, defined across the whole population rather than just the poor[^FN_REL_POV].

As with poverty, our job here is to take the intuitive notions we all have about whether some state is more or less equal than another and make them operational, so we can make broad but reasonably precise statement about the inequality of society and how possible reforms might change it.

I'll start with a simple table and a diagram. In table 1 column we show all the incomes of the people a little economy. They've been sorted from the poorest at the top to the richest at the bottom. You can change the numbers in the income column (but please wait till we've explained them!). Next to that is the *cumulative population* - the sum of all the population up to that point; so the first cell is 1, the next 2 `(1+1)` and so on. Then we have the sum of incomes up to that point (so the first is 10, the next `10+11=21` and so on). Finally we have two columns which just re-express the cumulative populations and incomes as a share of the totals (the totals are recorded at the bottom) - as with poverty, a lot of the work on inequality is done using proportions and shares rather than absolute levels.  Since the total income is 145, and the poorest two people have 21, the share of the bottom two is 14.48% `(100*21/145)`, and so on.

The graph to the left charts the cumulative population share on the x- axis against cumulative income share on the y-axis. This is the *lorenz curve* and this simple thing is probably the best tool we have for thinking systematically about inequality.

If you try changing the numbers in the income column, you'll see that the other columns get recalculated and the chart redisplayed. We invite you to get a feel for this by experimenting. In particular, please try:

* what happens to the Lorenz curve when all the incomes are equal - so, all the incomes cell have the same numbers in them? (Can you predict the Lorenz curve before you try changing the numbers?)
* what happens when the distribution is completely *unequal* - so the first 9 incomes are zero and the top one has everything? Again, can you draw what you think the Lorenz should look like before you try?

You'll have seen (and may have realised anyway) that with perfect equality, the Lorenz curve is a straight diagonal line. With perfect equality, the first 10% of the population have a 10% share of income, the first 20% of population have 20% of total income, and so on.

With perfect inequality, the share of everyone but the top person is zero, and the top person has 100%.

So, the more equal a country is, the closer the lorenz curve will be to the diagonal, and, conversely, the more unequal it is, the more the curve will be bowed away from the diagonal. Again, we invite you to play with the incomes to confirm this for yourself.

#### The Gini Coefficient - The Standard Measure of Poverty

The *Gini Coefficient* is a a nice way of summarising this, and is the most widely quoted inequality measure. In the  diagram below we've shaded the area between the perfect equality diagonal and the actual Lorenz curve in yellow.

![Gini Example](./images/gini-shaded-yellow.png)

The bigger the yellow area the greater the inequality. The Gini Coefficient just expresses this area as a percentage[^FNPCT] of the triangle ABC in the diagram. Complete inequality gives a Gini of 1, and complete equality gives 0.

Chart 2, below, from the World Bank shows some international comparisons of Gini Coefficients [^FN_WORLD_BANK_GINI]


|   country   |  Gini (%) |
|-------------|---------|
|  Australia  | 35.8 |
| Czech Republic|  29.9 |
| Denmark | 28.2 |
| UK | 33.2 |
| USA | 41.5 |
| South Africa | 63.0 |


You can see that the UK has a high inequality by European standards, but a low one compared to the USA or South Africa.

And here is a chart showing the UK Gini Coefficient over time, using many years of our HBAI data we encountered earlier.

![UK Gini Time Series](./images/gini-by-year.png)
Source: [@department_for_work_and_pensions_households_2019]

UK Inequality rose sharply during the Thatcher administration but has been roughly steady since then. The 2008 recession actually *reduced* inequality on the Gini measure, mainly by wiping out some very high incomes in the financial sector.

#### Advanced Measures of Inequality

There is a huge technical literature on inequality. Many other summary indexes have been proposed, each with different desirable properties[^FN_INDEXES]. For example:

* the *Theil index* has the feature that it can be neatly disaggregated to show the contribution of different groups to inequality; for example, the rise in UK inequality in the 80s and early 90s was accompanied by large changes in Regional inequality. With the Theil index one can split changes in overall inequality into changes in inequality *between* regions (London vs the South East, for example) and changes *within* regions (greater inequality in London between financial workers and the rest);
* The *Atkinson index* allows inequality to depend not just on the distribution of income, but also on the analyst's (or society's) views on inequality ("Inequality Aversion");
* The Palma Index [^FN_PALMA] has recently become popular - it's simply the ratio between the share of the richest 10% of the population and the poorest 40%.

As with poverty measures, there's a tension between how sophisticated these measures are and how easy they are to explain to non-specialists. The Palma index, in particular, is very easy to explain, and so has become very popular, but arguably lacks a strong basis - it clearly violates Dalton's principle, for example, since upward redistributions within the bottom 40%, the middle 50, or the top 10%, do not change the value of the Palma.

##### Activity

What happens to poverty, inequality, and mean and median incomes if:

1. Britain welcomes a group of Russian oligarchs? Answer: inequality ↑ , poverty (both absolute and relative) ≈, mean income ↑, median ≈)
2. Britain welcomes a group of penniless refugees? Answer: inequality ↑ , poverty↑, mean ↓, median ≈)
3. All incomes in Britain increase by 5%? Answer: inequality ≈, absolute poverty ↓ relative poverty ≈, inequality ≈, mean ↑, median ↑)
4. all incomes increase by £10pw? Answer: absolute poverty ↓ relative poverty ↓, inequality ↓, mean ↑, median ↑ )
##Inequality of What?

### Poverty and Inequality of What? Income, Consumption and Beyond

#### Income vs Consumption

Up to now we've used the term 'income', without worrying about what exactly we mean by it, or whether income is really the best thing focus on.

You may well have a reasonable idea of your family's income. But it's notoriously difficult to find a definition of income that fits every case, and which can be made operational[^FN_MEADE].  To see the problem, consider Alice and Bob. They have steady jobs on the same monthly salary, so on the face of it the same income, but Bob knows he will come into a large inheritance on retirement and Alice knows she won't.  Clearly, Bob can enjoy a better lifestyle now than Alice, since Alice may have to divert much of her salary into pensions and savings. Likewise, compare Bob, on his steady income, with Cynthia, an Youtube sensation who has made a million this year but who worries about being replaced by the next big thing in a matter of months. In the eyes of the FRS, or indeed the tax authorities, Cynthia is by far the richer. But, if this is her one chance at success, can Cynthia really afford a lavish lifestyle?

This naturally leads to the thought that *consumption* would a better thing to measure than income. The amount that Alice, Bob, and Cynthia are consuming could be a good indicator of their view of their sustainable, or *permanent* income. But in practice consumption has problems of its own. Consider durable goods: in any given month, you either buy a fridge or you don't, and in either case your spending on fridges is a poor indicator of your consumption of the service your fridge provides[^FN_KAY_KEEN]. So a comprehensive measure of consumption requires the imputation of some notional 'rental value' from all of a household's durable assets.

Housing is a particular problem in this regard, both for income and consumption measures. For those who own their houses, an 'imputed rent' would for many people be the largest element in their income, and, as can be seen from the frequent disputes over house valuations for local taxes, it can be very difficult to agree on what such a rental value should be. Many renters may have little or no choice about how much they pay. It's hard to tell whether rising rents reflect better quality housing, or simply a situation renters can't escape from. For these reasons, our official poverty and inequality measures are offered in before- and after- housing cost versions[^FN_RENT].

Most studies of the poverty Developing World measure consumption rather than income, for a related but distinct reason - small farmers, sharecroppers and  peasants may well consume much of what they produce, only selling some, so any measure of cash income may well understate their wellbeing.

##### Activity

Reopen the [LCF subset you used in the Equivalence Scale Activity](/activities/activity_3.xlsx). As well as the consumption data you explored then, it also contains a weekly income variable (`weekly_net_inc`). Try exploring the relationship between total spending and income. Are there any interesting patterns you can find?

Answer:

Here are some scatterplots of consumption against income, broken down by the economic position of the household head. There seem to be a number of cases where recorded consumption seems much higher than recorded income. The point above about durables might account for some of this, or perhaps there is under-reporting of some incomes - it's noticeable that there is a lot of variation for the self-employed, a group I highlighted earlier as having expecially unreliable income data.

![Scatterplots of income vs consumption](/images/activity_5.png)

#### Incomes over Time

The differing fates of Alice, Bob and Cynthia highlight the importance of considering the *intertemporal* nature of income and consumption. There are fewer steady jobs than there were in previous decades, but our surveys are mostly short-term; if they happened to pick Cynthia during her moment of fame she'll be recorded as very rich, and otherwise as very poor, whereas in reality if she's sensible she may have a modest but reasonable lifestyle for life. So our surveys be may mistake *instability* in income for inequality[^FN_BLUNDELL]. With the rise of the 'Gig Economy', it's possible that much of recorded poverty represents people flitting in and out of jobs rather than permanent poverty.

There is another important intertemporal aspect: people likely start out as a net recipient of benefits (such as Child Benefit) and public spending on education and health. As they age, there's a good chance they become a net contributor through taxation, perhaps with a period as a net recipient if they have a family of their own, before receiving state pensions and perhaps social care towards the end of their life. So, you can view much of the tax-benefit system as adjusting a person's lifetime income rather than redistributing between groups. To capture this aspect a long-run multi-year model is needed; that's not what we're presenting here, but we'll briefly discuss such a model at the end of this week[^FN_HILLS].

####  Broader Indicators of Wellbeing

Instead of single measures such as income or consumption, some advocate multi-dimensional measures. These attempt to condense measures of income, education, health and personal freedom into a single index. Examples of these are the 'capabilities framework' of  Amartya Sen[^FN_SEN], the United Nations Multidimensional Poverty Index[^FN_UN_MULTI] and, for the UK, the Social Metrics Commission Poverty Index[^FN_SOCIAL_METRICS]. These are appealing in some respects: reducing wellbeing to how much you earn, or how much you consume can seem distasteful, and, especially at the levels of countries or regions, it's certainly possible to have high incomes but poor outcomes for, say, health or education attainment. But there are problems with multidimensional indexes, too: if one aspect improves (health, say) but another worsens (education, perhaps), it's hard to say definitively that your index has gone up or down. And, although our main datasets have reasonably good data on many of the components of these indexes, in practice it can be very hard to operationalise these measures: as you'll see, we can predict quite accurately the effects of fiscal changes on incomes or consumption, but predicting the effect on health or education attainment is much harder.

As well as these broad measures, there is sometimes concern about individual aspects; for example fuel poverty[^FN_FUEL-POV], food poverty[^FN_FOOD], and recently period poverty[^FN_PERIODS]. As with the multidimensional measures, it may be difficult to operationalise these - you might need to augment the model we're about to look at with a *demand system* - a model which predicts how consumption of (e.g.) domestic fuel varies with income and prices[^FN_DEMAND].

For all this, in what follows we'll mostly be talking about changes in incomes, but you should keep these difficulties in mind. We can't do everything, but that doesn't mean we should do nothing.
##Formal and Effective Incidence

### Incidence: Who Really Pays Taxes?[^FN_KAY_INCIDENCE]

All the examples above and almost all of what follows are about things that directly affect people, by, for example, taking some of their income in tax, raising their wages, or paying them benefits. But we can use Microsimulation to study, for example, policy changes affecting companies, industries, schools, or Local Authorities. This raises an important point: ultimately the effects of a change to, say, the taxation of corporations or the funding of local councils falls on people, by changing, say, dividends, local taxes, or the quality of local parks, but the effect is at one remove from the policy. Resolving this indirection is know as finding the *effective incidence* of the change; the first-round effect is the *formal incidence*. For example, recent debates about the fairness of the United States tax code revolve round the question of whether corporation tax - which has been cut heavily in recent years, ultimately falls on wages or profits[^FN_US_CORP].

Considering the ultimate incidence of policy changes is very important, but can be very difficult. Even the direct changes we're concentrating on here can have an incidence beyond the those immediately affected - an income tax increase might cause higher prices in some industry, and so be 'passed on' to consumers who weren't the direct targets of the tax. For the most part we'll be considering first-round effects on the people directly affected by our policy changes - so, the formal incidence of the policy - but it's worth keeping in mind that the effective incidence may be different.
##Incentives

### Incentives and Fiscal Neutrality

As you saw in Chapter 1 of the textbook, mainstream economics starts from the premise that a properly functioning competitive market economy is the most efficient way of organising production and consumption for a modern society.

Economists often think of an economy as a "price system": where the market works well, prices reflect the relevant costs ("at the margin") of doing a thing, and people following these prices will be let "as if by an invisible hand"[^FN_SMITH] to do the best thing. "At the margin" is important here - it's the price of doing a little bit more of something that's the key thing - the price of the next litre of petrol you buy, or the wage for the next hour you work.

In designing a tax and benefit system, one common objective is therefore to distort market incentives as little as possible. There is a presumption in favour of low *marginal* tax rates on goods so the prices of things don't move away from their efficient level too much. In this context we'd consider labour to be a good that's bought and sold at a wage, so the presumption is for low marginal tax rates on earnings. (I'll discuss marginal versus average tax rates in more detail we have the simulation model in front of us)[^FN_MEADE_2].

As well as low marginal rates, there is also a presumption in favour of broad based taxation. Suppose a particular brand of baked beans was taxed, but all other brands were not. Since brands of beans are likely close substitutes, even if the tax rate was low, the taxed brand of beans would likely be wiped out - a pretty severe distortion. A tax on all beans would be less distortionary, a tax on all food better still, and a tax on everything best of all from this point of view. In the UK, most food, children's clothes and books are not subject to our 20% Value Added Tax, whilst most other goods are. Economists at the Treasury have long had their eye on these exemptions, whilst politicians and their advisors have jealously guarded them, on both distributional and electoral grounds. (Both sides are right in their own way)[^FN_VAT].

Sometimes subtleties in the tax code matter more than the headline tax rates. Consider corporation taxes - taxes on profits of companies. If a company is operating efficiently, and making the most profit it can (maximising profits), then in principle it has no reason to change what it's doing if a proportion of those profits are taken away - its before-tax plan is still the best it can do. Neutrality in this case means careful attention to the detail of the tax code so the notion of profit for the tax corresponds to the notion of profit that the company seeks to maximise.

As we've seen earlier in the course, there are many important counter examples. Collective action will always be required to supply "public goods" (for example defence) and to correct the distribution of income. Markets may fail altogether in some circumstances - where important information is unobtainable, for example[^FN_STIGLITZ]. Frequently the price that a free market would produce would not reflect the true marginal cost of things; so petrol pollutes, alcohol causes crime and illness, and so on - these are "externalities" that are not priced in in private transactions. In these cases there is a good argument for for having taxes that deliberately move the prices away from its free market level to reflect the full 'social' cost.

There is another sense in which we might want changes to the fiscal system to be fiscally neutral: we might want any change to have a net zero cost, so any tax cut is paid for by a spending reduction somewhere, and any benefit increase paid for by a tax rise. Proposals that fail to to this are often criticised in the media and parliament, but there might be good reasons to design a package of measures that is not zero-cost, for example if we want to boost demand in a time of recession, or if we believe your measures might improve the efficiency of the economy in the long run. In any event, it's always important to know what the projected net cost of proposals are, and to have a good story to hand if the cost is not zero.
##A Tax Benefit Model

## Tax-Benefit Models

### Where we're going

We've covered a lot of ground quite fast: summary statistics, large sample datasets, data weighting, measuring poverty and inequality, measures of well-being, tax incidence and incentives. Now we'll to put all these things to use and build a microsimulation tax-benefit model.

### Building a tax-benefit model

In essence a tax benefit model is a simple thing.  It's a computer program that calculates the effects of
possible changes to the fiscal system on a sample of households. We take each of the households in our dataset, calculate how much tax the household members are liable for under some proposed tax and benefit regime, and how much benefits they are entitled to, and add add up the results. If the sample is representative of the population, and the modelling sufficiently accurate, the model can then tell you, for example, the net costs of the proposals, the numbers who are made better or worse off, the effective tax rates faced by individuals, the numbers taken in and out of poverty by some change, and much else.

The model we use here is written in the Julia programming language[^FN_JULIA]. All the program code stored on a public website [^FN_GIT] but there's no need to look at that unless you're interested. We've equipped the model with a simple Web interface so that you can interact with it.

### Structure

The main thing we haven't covered already is how we actually do the tax and benefit calculations. The first thing to confront is that there's a lot of stuff to model: the standard guide to the UK tax system is Tolley's Guides[^FN_TOLLEY]. Here are the current Tolley's guides:

![Tolleys Guides](./images/tolleys_guides.jpeg)
(Source: [@neidle_excitingly_2017])

The corresponding thing for the Benefit System is the Child Poverty Action Group Welfare Benefits guide[^FN_CPAG], which looks like this^FN_MELVILLE]:

![CPAG Guide](./images/cpag_guide.jpg)
(Source: author's photograph.)

There is no royal road to creating the actual calculations; it's mostly a question of judgement - how much detail it's necessary to include, how best to use the available data, and so on.

Here's a simple flowchart of the steps the model goes through:

![Model Flowchart](./images/model_flowchart.svg)

Most of the steps here are hopefully familiar to you from earlier in the week; the one thing we haven't discussed is *uprating*: our datasets are typically 1-3 years old by the time they are released and wages, prices and interest rates will have changed since the time of the interviews, so we multiply incomes, rents and consumption by amounts to reflect these changes.

### How do we know the model is right?

A model of this sort inevitably gets quite big, and so there are lots of places it could go wrong. The model can be checked from the bottom-up: are the individual calculations are correct, is the survey data is handled correctly, and so on. Or it can be tested top down: are the models predictions for total amounts spent on benefits or raised in taxes close to what actually happens? In principle these two approaches are complimentary, but, as you'll see, a model that is accurate at the micro-level might actually be quite bad at predicting aggregates, and good performance at the aggregate level might hide significant errors in individual calculations.
##What Could Possibly Go Wrong?

## Tax Benefit Models: What Could Possibly Go Wrong?

Our model doesn't calculate what the people and households in our dataset will actually receive in benefits or pay in tax; rather, it calculates *entitlements* to benefits and *liabilities* to tax are. In terms of our earlier discussion, we are modelling *formal incidence*. People's entitlements and liabilities are important to know in themselves, but to go from liabilities and entitlements to what's actually received in tax and paid out in benefits requires a few extra steps that our simple model does not take. Further, by default we're assuming that no-one reacts to tax and changes, for instance by changing their spending or work patterns, or even by moving to a different jurisdiction. We'll consider these things in turn.

### Unclaimed Benefits

Our FRS dataset records actual receipts of state benefits as part of its record of peoples incomes. These recorded receipts are often different from the values a tax benefit model predicts. In particular, there are often cases where there a person is modelled to have an entitlement to some benefit but there is no recorded receipt. Typically the modelled entitlement for these case is relatively small. It's usual to interpret this as *non-take-up* - the modelled entitlements are correct but some people are choosing not to claim them, perhaps because of stigma or because the costs of claiming exceed the anticipated benefits. The fact that it's typically small amounts that seem to be unclaimed is consistent with this view[^FN_FRY_STARK], but it's also consistent with the view that we are making errors when we model entitlements and so the small entitlements that appear not to be taken up are actually just modelling mistakes[^FN_DUCLOS]. Either way, the way to correct for apparent non-take-up is the same: we construct a statistical model a bit like the ones we've seen, except it predicts whether a modelled entitlement is taken up or not - explanatory variables are the modelled entitlement and characteristics of the household like age of the head, presence of children and the like. Our little model does not have such a correction; since it's small entitlements that appear not to be claimed, we're not actually going to be all that far out modelling total costs and the levels of household incomes, but we may severely underestimating *caseloads* - the numbers of people receiving a benefit. Caseloads are very important for administrators, who need to know how many staff to hire and computers to buy, but arguably are less important for us than payments and incomes.

### Errors with Taxes

Similarly, it's often the case that the modelled amounts for direct tax liabilities (income tax and national insurance) are ifferent from the tax payments recorded in the data. There could be lots of reasons for this, such as timing issues (recorded payments might be for liabilities from months or years ago) or data problems (especially for the self-employed). Unlike benefits, however, there's rarely any very clear pattern, with as many over- as under- estimates, so that in aggregate tax-benefits usual predict total direct tax revenues quite well, at least once the high-income corrections discussed earlier have been applied.

This isn't the case for indirect taxes, however. We discussed earlier how spending in household surveys on 'bads' such as alcohol and tobacco is much too low given what is known from customs data. It could be that people are usually honest to the survey interviewer about whether they drink, but then understate how much they drink, perhaps out of embarrassment (or drunkenness). If this is the case then we can fix things simply by multiplying up the amounts people are recorded spending on alcohol - this is the standard correction used by most tax-benefit models. But suppose instead that the real reason for the understatement was that we weren't interviewing enough drinkers. If that was the case, multiplying up the alcohol spending we do have would still give us the correct aggregate amounts, but would make our distributional analysis *worse* - it would look like an extra tax on alcohol would punish a few people really severely, whereas in fact the pain would be spread between more households.

This is an example where improving the model's ability to forecast aggregates such as total tax revenues might *worsen* its accuracy at the level of individual or households. The non-takeup problem discussed above is another example: since not everyone actually takes up benefits, a microsimulation model that mistakenly understates individual entitlements, and so gets all the micro details wrong, might perform better in predicting aggregate costs than a model that gets entitlements right.

### Changing Behaviour

People may change their behaviour in response to changes to taxes and benefits, perhaps working more or less, or changing their spending on some good. Our model takes peoples hours and earnings as fixed, but, as you'll see, the model does produce some of the key building blocks for an analysis of labour supply - it can calculate the *marginal effective tax rates (METRs)* for every person in the survey, and indeed complete *budget constraints*. I'll discuss METRS and budget constraints next. The literature on the effects of taxes and benefits on the supply of labour is largely inconclusive[^FN_LABOUR]. Our understanding of the effect of taxes on demand for other goods is slightly firmer - see the discussion of sugar taxes in Block XX for an example.

Models that don't allow for behavioural changes, as with takeup or labour supply here, are often referred to as *static* models, as opposed to *dynamic* models which do allow behavioural changes[^FN_MALCHUP].

### Macroeconomic Feedbacks

You've seen examples of how macroeconomic models try to capture important feedbacks in the economy. For example, a tax increase, all else equal, will reduce the amount households have to spend, and this decreases total demand in the economy, which in turn causes wages, profits and employment to be lower. Since incomes and spending are lower, the amount raised by the tax might be less than you'd predict from a static model such as ours[^FN_WREN_LEWIS]. I'll briefly discuss a microsimulation model that attempts to capture these feedbacks right at the end of this chapter.

### Summing Up: What's a Good Model?

The last few sections may have seen like a long list of things we may not be measuring correctly, or are ignoring either to keep things manageable or because there is no know way of doing them correctly.

It's tempting to think that we should just wait for someone to build a model that: fully allows for behavioural responses, calculates the true incidence of taxes, captures the true distribution within households, corrects for non-takeup, and produces elaborate multi-dimensional measures of well-being. But no-one will produce such a model any time soon, and even if they did it would depend on so many strong assumptions that the output it produced would always be open to challenge, and the interactions in the model likely be so complex that you would in practice you would get little insight into what was really going on.

It's always important for researchers to be honest about the limitations of their work (not least to themselves), but  awareness of those limitations shouldn't paralyse them. In practical tax-benefit modelling, the questions we're answering aren't perfect - we've seen that at length. But they are important questions, which can be relatively easily explained, don't depend strongly on the analyst's prior beliefs, can be answered with a reasonable degree of precision, and are genuinely useful in the design of policy. This is rare in economics, and shouldn't be lightly given up.
##A Tax Benefit Model

## (Finally) Introducing Our Model

Now we can go on to experiment with our model. We'll do this in two steps. Firstly, we'll use it to draw some *budget constraints* for a example person. This allows us to study in a simple way how taxes and benefits interact, and to introduce a few more concepts that can help us think about policy.

Then we'll move on to running our model on a complete FRS dataset.
##Budget Constraints - Introduction

### Budget Constraints 1 - Income Taxes

We're going to start exploring our model by using it to generate a simple diagram: a *budget constraint*.

Above, to the left, we have some input fields you can use to sets up a simple income tax system. The first field is a *tax allowance*. This is the amount you can earn tax-free. Income above the tax allowance is *taxable income*. Underneath the allowance field, we have two fields for tax rates. We'll call the first the *basic rate* and the second the *higher rate*. Below those is the *higher rate threshold* field. You pay at the basic rate till your taxable income exceeds the higher rate threshold, and any taxable income more than the threshold is taxed at the higher rate.

As an example, suppose your income was £40,000 per year, the allowance as £5,000, the basic rate 20%, the higher rate was 40% and the higher rate threshold £20,000. Then:

    taxable income would be: * (40,000-5,000) = 35,000 *
    tax at the basic rate would be:  * 20%×20,000 = 4,000 *
    tax at the higher rate would be:  * (35,000-20,000)×40% = 6,000 *
    so total tax due would be: * (4,000+6,000) = £10,000 *

Many tax systems have more than two rates (the Scottish system has five): I show two just to keep things simple. A complete description of the UK tax system would need a lot more than these four parameters, but I want to keep things as clear as possible for now. You can get a good feel for how a real world tax system works just with these four numbers.

*A Note on periods* A slightly confusing thing here is that the allowances and bands on the left are in £s per annum, whilst the graph is in £ per week. Taxes are normally expressed in annual amount, whilst benefits (and our FRS data) are normally expressed weekly or monthly. And from the next page on we'll have taxes and benefits on the same page. I've tried to keep everything in its most natural units, but I appreciate this can be confusing at first.

On this page, the tax rates and allowances are initially set to zero - that may make it easier for you to see what the effects are of your choices of tax rates and allowances.

To the right of the inputs is our *budget constraint* graph. It shows for one person, or one family, the relationship between income *before* taxes (*gross income*) on the x- (horizontal) axis, and income *after* taxes have been taken off on the y- (vertical) axis. It's often useful to think of the gross income as being pre-tax earnings.

The button at the bottom of the input fields sends your tax choices to the model, and the models does the needed suums and sends back a graph showing all the possible gross vs net income combinations for earnings from £0 to £2,000 per week[^FN_BUDGET_CONSTRAINT].

If there are no taxes (and no benefits - I'll come to benefits in the next page), then if you earn £1, your net income will be £1, £100 gross gives you £100 net and so on. So the graph showing gross versus net income - the budget constraint - should simply be a 45% line up the middle of the chart. We invite you to check this by now by pressing the 'run' button with the default zero tax rates and allowance.

Now, I'd like you to experiment a little. Try setting the tax allowance and tax rates to some positive values just to get a feel for what happens.

####  Budget Constraints The orthodox analysis of labour supply

In mainstream economics, people are assumed to make rational choices, choosing the best possible thing given their preferences and the constraints they face. An elaborate theory has been constructed about the nature of peoples preferences. But it turns out we don't need much of this to get far in understanding choice - often all we need is to enumerate the constraints that they face, and the best choice is then often self-evident.

Economists draw budget constraints to help them understand all kinds of choices. In block XX week YY, you encountered one drawn between consumption now and consumption in the future, and you saw how that could help you understand savings decisions. Indeed, although not always drawn out, there are implicit budget constraints in practically everything in the course; for example between sugar and all other goods in the discussion of sugar taxes, or a 'Government Budget Constraint' in the cost-benefit-analysis week.

However, although it's standard in the microsimulation field to call the graph we're drawing here a budget constraint, it's actually slightly different from the examples you normally find in textbooks. Crucially, I'm drawing this graph flipped round horizontally from the normal one.

When we analyse how direct taxes and benefits affect the economy, it's natural to focus on the supply of labour - for a start, if a tax increase caused people to work less, it could backfire and cause revenues to fall. So he budget constraint that's normally used to illustrate the choice of how much to work is set up in a slightly unintuitive way, so as to make it easy to analyse this aspect. The goods are *consumption* (usually on the y- axis) and *leisure* on the x- axis. So instead of studying the supply of labour directly, the analysis flips things round and studies the demand for leisure.

Every available hour not consumed as leisure spent working; that is exchanged for  at consumption goods at some hourly wage.

In effect, the person's wage is playing two roles here:

* it's the source of the person's income - as wages go up, the income from every hour that you work increases, so workers can afford more time doing the things they really like doing;
* but it's also the price of leisure - as wages go up, taking an extra hour in bed or at the beach means you're giving up more consumption goods.

These two aspects of a wage - the 'income effect and the 'substitution effect' - work against each other, and are often thought to roughly cancel out, so increases or decreases in hourly wages might not make much difference to how much people want to work. Note that even if a tax increase has no effect on labour supply for this reason, it's still effecting choices and hence welfare - a tax increase with no change in labour supply must mean that consumption of goods, and hence the welfare of the worker, is lower, and the price system is distorted.

![Wage Increas Diagram](/images/wage_increase.png)

**INSERT EITHER A PICTURE or a small SIM like [https://virtual-worlds.biz/ou/demand/] here**.

Of course, this analysis needs to be modified in many ways - for example, many office workers might not get paid more if they stay late at work, or workers may be on fixed hours contracts and so unable to vary their hours, many people enjoy  their work (at least up to some limit) and so on. Plus, of course, wages are not be the only source of income. Nonetheless, this the mainstream approach offers a simple but powerful analysis.

If you think about it, the key thing here is that consumers own a thing (their time) that is both a source of income and something that they want to consume directly (as leisure). Many economic problems have this characteristic. The two-period consumption versus saving example from block XX is an example. The choices of subsistence farmers between consuming their own crops or selling them at market is another.

##### Activity:
1. Activity: look back at the 2 period saving/consumption diagram of Block XX. How would you analyse the effect of an interest rate rise on period 1 consumption using the ideas you've just encountered? Answer if the interest rate goes up, lifetime wealth (amount available to consume over both periods) goes up but the marginal cost of period 1 consumption also goes up since each extra £ spent in period 1 costs more in terms of foregone consumption in period 2. Hence the effect of an interest rate increase on period 1 consumption is ambiguous.  
2. (Note this is a rather difficult question). Using this framework, can you suggest why employers might offer overtime (higher wages for hours worked above the standard amount)? How does the analysis of overtime in this framework differ from the analysis of an across-the-board wage increase? Answer: overtime offers higher wages only for extra hours worked at not for all hours worked. This effectively removes the income effect that you would see from a general wage increase, leaving only the substitution effect.


#### Some important measures

We'll use the budget constraint graph to introduce some important ideas: *marginal tax rates*, *average tax rates*, and *replacement rates*. Replacement rates make more sense when we can consider state benefits and taxes together, which we do in the next screen, so we'll hold off on that one for now.

The *Marginal tax rate* (MTR) is the rate of tax on the next £1 that someone earns. We've seen in our discussion on fiscal neutrality that this is the key number for understanding how taxes distort the economy. In this case, it's pretty easy to work out - since there is only one tax, with two tax rates and an allowance - the MTRs are 0, up to the tax allowance, then 20% up to the higher rate threshold, then 40% from then on. In the diagram, the MTR measures the extent to which the tax system flattens out the budget constraint compared to the 45° line - with a marginal rate of 0, you keep all of the next £ that you earn, with a MTR of 100% (which as we'll see in a minute, is all too possible) you keep none of the next £1, so the budget constraint would be horizontal.  If you hover your mouse over the points on the budget constraint, the program will display the MTR at that point.

The  *Average tax Rate* is the proportion of total income you pay in tax.  Some important choices are all-or-nothing rather than marginal, and for those, the average tax rate is more important than the marginal one. For example, back at the very start we saw a brief discussion of the fear that higher taxes in Scotland might encourage people to move to England. For this decision, people are choosing which side of the border they would to earn *all* of their income on, not just the next £1[^FN_SFC_2].

If the average tax rate rises with income, so a bigger proportion of income is taken in tax from rich people than poorer ones, the tax system is said to be *progressive*. Note that a progressive tax system *doesn't* require marginal tax rates to be rising, so long as there is a tax allowance, since, with an allowance, the proportion of income that is taxable is higher for a rich person than a poorer one. We invite you to verify this by setting the basic and higher tax rates equal and examining the average tax rate at various points.

There's one further measure that's worth discussing here. Consider Edward, who earns £20,000 per anum. His tax allowance means that he has a taxable income of £10,000 (20,000-1000), and so pays tax of £2,000 (10,000×20%), with 20% also being his MTR. Ed would be in exactly the same position if he was taxed on *all* his income (so 20,000×20% or 4,000) and then given a tax-credit of £2,000, which is his tax allowance of £10,000 × his MTR of 20%. In other words his tax allowance has a cash value to him of £2,000. There's much more to the tax and benefit system than the income tax we're showing here, but no matter how convoluted the system gets, you can always summarise the entirety of someone's position using just his MRT and this notional tax credit; this is a very useful trick when thinking about even the most complicated system[^FN_ESRI].

Figure XX below tries to summarise all these points in a stylised version of our budget constraint diagram.

![Illustration of METR,ATR and Tax Credit](./images/bc-1.png)


##### Activity

Create a tax system a little like the UK one, with an allowance of £10,000, a basic rate of 20%, a higher rate of 40% and a higher rate threshold of £40,000 per annum.
##Budget Constraints - Adding Benefits

#### Budget Constraints: Introducing Cash Benefits

I'll now introduce cash benefits using the same diagram but a different set of inputs.

The low incomes on the left of the diagram might well be below the poverty line; indeed, they might be impossible to live on at all. So it may be necessary to introduce have cash benefits - transfers of money to people depending on their circumstances.

You can broadly classify cash benefits into three types:

* *universal benefits*: given to everyone, regardless of income or other circumstances
* *means-tested benefits*  - these are benefits that are given solely to people with low incomes, and so withdrawn as incomes rise;
* *contingent benefits* - these are given to people in certain circumstances, for example, the unemployed or disabled.

In practice benefits are often hybrids of these things, but it's still a useful classification[^FN_IFS_BENEFITS].

In this example, we'll model three different benefits, so we have some new fields on the left-hand-side. The modelling here is very basic; in reality the benefits would have multiple levels depending on age, disability status, number of children, and so on, and detailed rules on who qualifies. But there's more than enough here to produce some pretty complex results, and to give you a feel for the difficult choices involved in designing a social security system.

##### Minimum Income Benefits

The first field represents a *Minimum Income Benefit*[^FN_MIG]. Job Seeker's Allowance and Income Support are examples of this kind of benefit[^FN_JSA]. Minimum income benefits are designed to ensure that people don't fall below some acceptable standard. If they do, their income is topped up to that standard. Those above the minimum standard don't receive the benefit. Since benefits of this type are solely targeted on the poor, they can be very effective anti-poverty measures. Against this, since the benefit is the difference between some minimum acceptable level and actual income, if your income goes up by £1 the benefit must fall by £1.

We discussed earlier how means-tested benefits are normally assessed over 'benefit units' - roughly traditional nuclear families. A stay-at-home spouse of a high earner would not normally be assessed as poor. For now, we can rather gloss over this point, but family structure comes to be very important when we come presently to our full model with its representative dataset.

In the last section we discussed Marginal Tax Rates (MTRs) as being the wedge between an extra £1 you earn and the amount you get to keep. You can think of a means-tested benefit in just the same way. With a minimum income benefit of this type, in effect you don't get to keep any of the next £1 you earn, since £1 of extra earnings is matched by £1 of withdrawn benefit.

Q: What's the implied marginal tax rate here?

In some cases, people on low incomes might also be liable for taxes, and perhaps also eligible for other benefits which are also withdrawn as income rises. So the MTR for low-income people might be a complicated mix of benefit withdrawals and tax increases - it's possible for these withdrawals to *exceed* 100% in some cases, so earning an extra £1 leaves you net worse off [^FN_STARK_DILNOT].

Marginal Tax rates that mix together deductions from multiple sources are sometimes known as Marginal *Effective* Tax Rates (METRs), and we'll use that term from now on.

These very high marginal tax rates on the poor are sometimes referred to as the *Poverty Trap* - though that's a phrase with multiple meanings.

Exercise: we invite you to experiment with raising or lowering the minimum income benefit.

Our *Average Tax Rate* notion can also be applied here. The difference is that the average tax rate for a benefit recipient who is not also a tax payer is *negative* - net income is *above* gross income.

##### In Work Benefits

The next group of inputs model a simple in-work benefit. Examples from the UK are Working Tax Credit[^FN_WTC] (WTC) and, to an extent, the Universal Credit (UC) that is gradually replacing it[^FN_UC]. In work benefits boost the incomes of people who work at least a certain number of hours but who don't earn a great deal; they are normally withdrawn gradually as income increases, rather tha £1 for £1.

WTC and UC are normally paid in people's pay packets, effectively as a deduction from any taxes due, hence the names. In the past, however, they were paid directly to mothers in the same way as child benefit. We've just established that we can analyse taxes and benefits in the same way using our METR concepts, so one one level whether WTC and UC are classed as taxes or benefits doesn't matter to us, but you should also bear in mind here our earlier discussion on the intra-household distribution of income.

We need four parameters for a basic model of such a system:

* *Maximum Payment* - if a family qualifies, this is the most they'll be paid;
* *Minimum Hours Needed* - if this is to be an in-work benefit, we may want to specify some minimum amount of hours of work (or perhaps gross earnings) befire you qualify. Although our budget constraint has gross income on the x- axis, we can map that to hours worked if we make some assumption about hourly wages;
* *Upper Limit* - if we want to deny this benefit from high earners, we can set a point above which we start to withdraw it;
* *Taper above upper limit* - the benefit is withdrawn at this rate for every £1 earned above the upper limit. So, if this is 50%, if you earn above the upper limit, you lose 50p in benefits for the next £1 you earn, until eventually your entitlement is exhausted.

This is actually a pretty flexible system. For example, you can set parameters here to produce the same results as the minimum income benefit we discussed above.


##### Activity

1. Replicate the MIG using the 4 parameters of the in-work benefit. Answer:
(maximum payment should be positive 0, minimum hours=0, upper limit = maximum payment, taper=100)

2. We invite you to spend some time experimenting with the in-work benefit. Things you might want to consider are:
  - Marginal Tax Rates: how do METRs change as you change the withdrawal rate? Answer: very high withdrawal rates lead to very high METRs over a short section; lower withdrawal rates lead to smaller but possibly still high METRs over a bigger range of gross incomes
  - Universality - what happens as you change the qualifying condition?

#### Basic "Citizen's" Income

The final field represents a *basic income*[^FN_BASIC].  The the many benefits that make up UK social security all have qualifying conditions of some sort - the examples above have means-tests and hours of work conditions; other benefits are conditional on age, or whether the claimant is disabled in some way, widowed, and much else. All of these conditions need to be checked, and we've seen the possible disincentive effects of means tests. A Basic Income sweeps all this away - everyone is eligible regardless of income, health, or anything else.

A Basic Income appears to eliminate the problems we've identified with means tested benefits, but it comes at a (literal) cost: since it goes to everybody at all incomes, it's expensive. Whether a Basic Income reduces poverty or inequality, or improves work incentives, depends on how it's paid for and the extent to which it replaced or complemented the existing benefit system.

##### Activity

Try using the in-work benefit framework above emulate a Basic Income Answer: (amount positive 0, qualifying hours=0, upper limit = ∞ and/or taper=0).
##Budget Constraints - Putting things together

#### Budget Constraints: Putting things Together

Finally in this section, let's consider taxes and benefits together.

We have the usual diagram, but now all the fields for taxes and benefits together on the left. So it's possible to design a complete system.

We've seen seen that you can understand the effects of taxes and benefits using the same concepts. Now, when we put the two sides together, we can analyse the results in the same way, but the tax side and the benefit side can interact in ways that produce complicated and often unintended outcomes.  

For example, if tax allowances are low and the generosity of in-work benefits fairly high, it's possible to pay taxes and receive means-tested benefits at the same time. Depending on the exact calculations involved, this can produce METRs in excess of 100%  - earn more and net income falls[^FN_STARK_DILNOT-2].  

##### Activity

Exercise: we simply invite you to experiment here. Try to get  a feel for how taxes and benefits interact.

#### Integrating Taxes abd Benefits

The sometimes chaotic nature of the interaction of taxes and benefits have led to advocacy of the complete integration of taxes and benefits. Completely integrated systems are sometimes known as *Negative Income Taxes*; one such system was proposed for the UK in the early 1970s[^FN_SLOMAN]. Universal Credit, briefly discussed above, is an attempt to integrate several means-tested benefits, though not taxes. However, though it produces messy and inconsistent interactions, there are often good reasons for keeping parts of the tax and benefit system separate. With Minimum Income benefits, for example, it's often important to get help to people very quickly if they are destitute, whereas with an in-work benefit, it's often helpful to take a longer view, so support can be given consistently over say a, year.

#### Replacement Rates

Now we have taxes and benefits together, we can introduce our fourth summary measure: the *replacement rate*. This is intended to be a measure of whether it is worth working at all, and simply the ratio between the net income someone would have when working some standard amount of hours (usually 40 per week), and the income received when not working at all.

![Illustration of the replacement rate](./images/bc-2.png)

The replacement rate is worth knowing about because it is sometimes used in academic studies trying to explain, for example, the aggregate level of unemployment; it also sometimes appears in popular discourse[^FN_RP].

##### Activity
Assuming an hourly wage of £8, use the form above to calculate replacement rates for 2 different tax and benefit systems.
##Welcome to Unicoria

## Introducing The Full Model

### Welcome To Unicornia

We'll be modelling the fiscal system of Unicoria, an imaginary small economy on the Northern fringes of Europe, with a population of just under 6 million; Unicoria is a similar country to the one I live in but with a slightly simpler tax and benefit system. I've chosen a slightly fictionalised country so I can get most of the essential ideas across without confronting you all with the thousands of parameters needed to model the actual tax-benefit system of the United Kingdom.

Unicoria's economy is mid-way between the very high income Scandinavian countries and the newly independent Baltic Counties. A period of radical free market policies two decades ago has left a mixed legacy. On the positive side, Unicornia now has a flexible, service orientated labour market with very high employment levels, especially amongst the young and women. On the other, the mass redundancies that followed the decline of the old heavy industry base has left many long-term unemployed, many of whom receive sickness and disability benefits. Also, the new service-orientated has a large number of low paid and part-time jobs.

The population is ageing but this is partly mitigated by immigration.

#### Unicornia's Tax system

About 35% of Unicornia's national income is collected in tax. This, too, is mid-way between the Scandinavian counties and the newly independent Baltic states.

Unicornia has three main taxes:

* income tax - this has an old, creaking administrative system but is relatively progressive, with a relatively flat rate structure but high tax allowances. Tax competition from near neighbours makes significant increases in income tax risky.
* employment insurance of about 1/5th wages and self employment income - this is not enough to pay for particularly generous pensions
* indirect taxes - the main tax is VAT at 20% - but about 1/3rd of all spending is not fully covered by the tax - these exemptions are unpopular with the European Union but are jealously guarded. There are also a variety of 'Sin Taxes' on alcohol, tobacco and driving.

There are also taxes on corporations, wealth and natural resources, plus a local property tax which part funds local government spending.

#### The Social Security System

Just under 1/2 of Government spending goes in social security. The system has evolved over nearly a century into a complex mix of means-tested and contingent benefits with a creaking administrative system

The most expensive item is state pensions. The relatively low level of employment insurance means that pensions are relatively un-generous. Many retirees have private pensions, but others rely on top-ups from means-tested benefits.

There are also large expenditures on payments to families with children, and to the sick and disabled.

However, means tested benefits are the most important tool used to boost the incomes of those on low incomes. After an unpopular experiment with the Galactic Credit negative income tax, Unicornia has reverted to a minimum income guarantee plus an in-work tax credit and housing costs support.

Pressures on the benefit system include:

* rising Housing support driven by low wages and earlier household formation;
* the ageing population causing rising pension and social care costs;
* the rise in self-employment and 'gig economy' workers.

Concern about poverty traps and complexity have led to a debate about replacing much of the benefit system with a Citizen's Income.  Preparatory work has been done so it would be administratively straightforward to introduce one.

We'll turn now to getting hands-on with our model.
##The Main Model

### A Tour of Our Model

**PLEASE NOTE this model is incomplete and there are bugs in the interface (some arrows wrong way)**.

Now we have everything in place, we can start exploring the  main model.

I'll describe the mechanics of using the model first, and then in the next few sections explore different aspects of it.

#### Inputs

The input fields to the left should look familiar to you by now. There are a couple of things to note, though:

1. we've pre-set default values for everything. So, you don't have to build a default system from scratch this time;
2. although the fields are the same, what they actually now do once you press 'submit' is a bit different. In the budget constraint case, the few parameters you could see really were the entire system we were modelling - as you saw, those parameters produced results that were more than complicated enough to get the important ideas across. Here, since we have such rich FRS data, it's worth us modelling in much more detail: under the hood, there are actually more that 150 parameters, for multiple tax rates, other benefits including disability and housing benefits, and different levels of generosity for our main benefits. So, we use your choices to adjust several parameters at a time. Changing the basic rate of tax, for instance, actually changes three tax rates by the same amount. Doing it this way seems a good compromise between keeping things simple enough to learn from without too much distraction, but complex enough to capture much of the richness of our data.

When you press 'submit' your requests are sent to the server and the model is run - it's actually run *twice*, once for your changed system and once for the default values; most of what's shown in the output section is differences between the two, since its the changes you've brought about that are the of the most interest.

#### Ouputs

Instead of the budget constraint graph, we have the "Output Dashboard", a table of summary measures showing how the changes you enter affect Unicoria as a whole.

There's a lot tshere, but everything here has been introduced earlier.

From left to right, starting at the top row, the fields show:

* **The net cost of your changes**, to the nearest £10 million per year. This was discussed under 'fiscal neutrality'. You needn't always aim for a net zero cost, but you should be aware of the projected cost and have a story to hand if this cost is significant;
* **gainers and losers** - the numbers of individuals gaining or losing more than 1% of their net income;
* **marginal effective tax rates**. We've seen these in our budget constraint exercises. Since we've averaging over the whole population, we show the proportion of the population with METRs above 75% - this will include those in the poverty traps we discussed earlier, but, if you choose to increase higher rates of tax, could also include some higher rate payers.   
* **replacement rates**. Again, these were covered in our budget constraint discussion. Increases here might indicate reduced incentives to work amongst the low-paid;
* **Changes In Net Income By Decile** this is a slightly unfamiliar graph, although we've encountered all the ideas previously. We chop the population up into the poorest 10%, the next poorest 10%, and plot the average change in net income for each group. This is a nice way of seeing quickly whether your changes distribute income towards the poor or the rich;
* **Lorenz Curve** this is the same chart you experimented with earlier, except we show both a pre- and post- change curve;
* **Inequality** the measures shown here should all be familiar from our earlier discussion;
* **Poverty** Likewise, everything here is discussed in the poverty section;
* **Taxes on Income** - the total change (if any) in income taxes in £million
* **Taxes on Spending** - likewise for spending taxes
* **Spending on Benefits** - change in benefit spending in £m
* **Benefit Targetting** - This shows the proportion of any extra benefit spending that is targetted on the poor (defined as XX). We discussed the trade-offs between how well a benefit is targetted on the poor and high METRs.

##### Activity

1. try running the model with no changes to the parameters.
2. Can you suggest any other types of output that could be helpful?
##Modelling Direct Taxation

### Direct Taxation

**PLEASE NOTE this model is incomplete and there are bugs in the interface (some arrows wrong way)**.

We'll now briefly study direct taxes.

We've covered many of the key ideas with our budget constraint exercise. But we have a much richer environment to explore them in now.

#### Activity

1. try raising an extra £100 million by:
  - cutting the tax allowance; or
  - increasing both the basic and higher rates of income tax.
contrast the effects of these things on on each of our 9 measures. Which would you say is the more progressive? (Progressivity was discussed above in section XX).
2. experiment further with changes to income tax rates and allowances. Try graphing what you find. It's always useful to have an feel for how much tax you would raise from small changes to rates and allowances, especially when you're trying to 'balance the books' in some complicated package of measures.
##Modelling Benefits

### Benefits

**PLEASE NOTE this model is incomplete and there are bugs in the interface (some arrows wrong way). Also, these inputs shouldn't be zero.**

Now, we invite you to experiment with just the state benefit system, holding taxes constant.

The inputs should be familiar to you from before, but bear in mind the extra complexity of the underlying benefit system.

##### Activity

we've discussed the inherent trade-off between targeting expenditure on those most in need, and imposing high marginal tax rates (poverty traps), and perhaps high replacement rates, on the poor. Try to find empirically the relationship between these things by varying the generosity of each of our three types of benefit. Create a table of your results.
##Who is this for?

### Policy Analysis Using the Model

The users of microsimulation models include teachers, students, and interested members general public. We should definitely encourage this - the model you're using is intended as a small contribution to that. But for the most part users will be professions fulfilling some role in Government, Politics, Journalism or "Civil Society" more generally. It's worth considering these different roles a little, and in the sections that follow we'll invite you to assume some of these roles, and so look at our model's output from different angles.

This is the era of "Fake News", and in response Fact Checking services such as Full Fact[^FN_FULL-FACT] and The Ferret[^FN_FERRET] have sprung up to assign "True" or "False" to claims of all sorts, including the things we're studying here. But in fact in fiscal policy-making you very rarely see any outright lies, or even many serious mistakes. There's rarely any need: the world we're dealing with is so multi-faceted that there is a ways going to be *something* that tells the story that you want to tell, whatever your angle may be[^FN_LIE].

So, lets consider the roles we'd like you to play:

* *A Senior Civil Servant in the Finance Department* You must try to be impartial, but you are working for the Government of the day. You should offer 'pure' economics advice, subject to policy of the day; it's for the minster's political advisors to knock down politically dangerous but economically sound ideas. Misters are busy people, and may not have a technical background so don't drown them in detail[^FN_GOVT];
* *Special Advisor ('SPAD') to the Finance Secretary* - your job is to protect the minister, and to keep her on track with the Government's broad aims. You need to give advice on 'lines to take' - the best way to present the results of a policy, but also keep her aware of where the bodies are buried: are there any traps the ministers should be aware of, for example, vulnerable groups that will be made unavoidably worse off? And you need to shoot down politically dangerous ideas, wherever they originate from;
* *Special Advisor to the opposition party* - is mirror-image: you need to *find* where the bodies are buried. You also need to think of policies of your own, though it's often wise to keep them fairly vague;
* *A journalist for a right-of centre popular newspaper*. Your emphasis should on concrete examples: what does the change mean for *you*? (Where the 'you' in question is often some person or family that makes the point you want to make). A wider perspective can also be useful, but isn't the main priority;
* *A journalist for a sympathetic to the Government broadsheet* - you may have more time and space for context than your red-top colleague;
* *A researcher for an anti-poverty charity*. Your emphasis is obvious, but you need to balance lobbying for your charities cause with needlessly antagonising a government that you ultimately need to work with;
* A researcher for an Employer's Organisation.

None of these actors are in the business of "fake news". It is in none of their interests to report outright falsehoods, but they will report with a different emphasis and in different styles. SPADs and Civil servants usually write in traditional essay style, arguing from premise to conclusion, whereas journalism is usually 'top down' with the most important, or shocking, things first. But in all cases, brevity is welcome.

So, in the next sections, well ask you to design policies that meet the priorities of the Government of Unicoria, and to report on what you've done from the perspective of one or more of these players. You can choose which, but it can sometimes be very instructive to put yourself in the shoes of someone you are personally unsympathetic to.
##You are the Finance Secretary 1: Attacking Poverty

### You are the finance Secretary: Task 1: A War On Poverty

The Government of Unicoria has plegded to reduce the headcount measure of poverty by 10 percentage points. Your task is to design a policy package that delivers this in the most effective way possible. The economy is doing well, and net extra spending of up to £4 billion has been agreed.

Things to consider include:

* *cost* any costs above £4bn will have to be raised from somewhere;
* *targetting vs. incentives*: well targetted benefit increases may force poor people into poverty traps, whilst more widely spread increases may require tax increases to keep within budget;
* *alternative measures of poverty* have you cheated at all, and reduced poverty headcounts by concentrating on the near-poor, perhaps through increasing in-work benefits? (You may need to do this in order to meet the political objectives)

Once you've designed your scheme writing short briefings or newspaper articles on it from the perspectives of two of the roles you've just read about.
##You are the Finance Secretary 2: Incentivising the Economy

### You are the finance Secretary: Task II - Let's Get Unicoria Working!

The Government, worried about sluggish economic growth, changes tack and decides to go for economic liberalisation, encouraging people to work harder and keep more of what they earn.

Your task is to design a package which:

* has close to zero net cost;
* cuts marginal tax rates, especially very high ones;
* if possible, improves replacement rates so as to encourage people back to work; and
* implements an overall income tax cut of £50 million.

In doing all this, you should try to avoid hurting the poor as much as possible, though some losses may be inevitable.

Again, briefly report on your package from different perspectives.
##You are the Finance Secretary 3: A Woman- and Child- Friendly Budget

### You are the finance Secretary: Task III: A Budget for Women

Party policy is to produce the worlds first explicitly pro-woman budget. It is for you to interpret what this is to mean, and  to construct a package of measures to deliver it.

Points to consider:

* is the pattern of male and female working different - part-time versus full time, for instance, or low versus high wages? How could the tax and benefit system better support the kinds of work women do?
* what about families? If women are more frequently the main carers, should the benefit system reflect that?

It may be that the important changes needed in this case are not things allowed from our simple user-interface. But you may have enough of a feel by now of how things operate to be able to speculate on the likely effects of the changes you'd ideally make.
##Tax Benefit Models - Where Now?

## Where Next?

We've come a long way. We've studied most of the important concepts a professional in this field needs, got hands-on with a tax-benefit model, and carried out some ambitious policy design.

The model you've been using is static and very conventional, and we've discussed its problems at length. Nonetheless I hope the policy simulations you've been doing show that static microsimulation is a powerful and useful tool.

Earlier, I expressed scepticism about whether a model that addressed all the limitations of this present one was feasible, and whether, if such an all-singing, all-dancing model was somehow built, it would actually be very useful. But interesting extensions in various directions have been made, and in this final section I'll discuss a couple of them.  

### Long-Run Forecasting using Microsimulation: A simple example

Last year, I and my colleague Howard Reed of Landman Economics[^FN_LANDMAN] were commissioned to produce long run poverty projections for Scotland, as part of the anti-child poverty policy[^FN_REED_STARK] we mentioned right at the beginning. We've seen that poverty simulation is classic tax-benefit model territory. But how could we project forward over 15 or more years? It turns out that we've already encountered the tricks that you need: reweighting and uprating. We saw above how, because of differential non-response, we needed to re-weight our FRS dataset - give more emphasis to some households than others in the output - so that the final results matched know facts about the overall populations, such as the numbers of people of different ages and genders. We can extend this idea to produce weights such that our data matches not current levels of these things, but *projected* levels. Likewise, for incomes, we can uprate the recorded levels in the data to match projections of thee things from macroeconomic forecasters. Such projections exist: the ONS and Public Records Scotland produce long-run forecasts for populations and household composition[^FN_PRS] and the Scottish Fiscal Commission produces income forecasts[^FN_SFC]. Note that we're not forecasting populations and incomes *ourselves*; rather, we're making projections of poverty that are consistent with official forecasts.

### Micro- to Macro-

An example of a successful model that captures some of the interactions that our model leaves out is DIMMSIM[^FN_DIMMSIM], developed by the ADRS[^FN_ADRS] company for the South African Government. DIMMSIM is a *micro- to- macro- model* of the South African Economy. This merges MEMSA[^FN_MEMSA], a conventional macroeconomic forecasting model of South Africa, with SATTSIM, a conventional tax-benefit model of the sort we now know well. The model starts by doing the kind of conventional tax-benefit calculations we're now used to, but instead of just stopping there, the results for tax revenues, net incomes and the like are used as imputs to the macroeconomic side of the model, replacing the equations for these things that a conventional macro model would have. The macro model then uses the micro outputs to produce new estimates for employment and incomes, which are fed back into the micro part. This process continues until the model 'converges' - produces a set of micro outputs and macro outputs which are consistent with each other, and with the other constraints on the macro side (for trade deficits, for example). This procedure produces results that capture the feebacks between, for instance, tax increases and reduced economic activity, that our simple model ignores.
