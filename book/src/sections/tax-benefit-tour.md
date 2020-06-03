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
