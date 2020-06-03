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
