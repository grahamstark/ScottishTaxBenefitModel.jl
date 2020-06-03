### Poverty

#### Poverty Standards

For our purposes, those in poverty are those whose command over resources falls below some minimum acceptable standard. To make this operational - something we can measure, and design programmes to alleviate - we need to establish what this minimum is - our poverty line. In reality there is no single objective point above which people have an acceptable standard of life, and below which they do not; rather there is a continuum. Stress levels, for example, worsen steadily the poorer people get[^FN_STRESS], rather than jumping sharply at some point. There are a variety of ways we could define such a standard; discussing these at length would take us off-topic, but an interesting recent approach is to use focus groups to gauge public opinion on what an acceptable minimum standard might be[@hirsch_cost_2019]. And, as we've briefly noted, there are also multi-dimensional standards - recently the Social Metrics Commission has proposed one such for the UK [@social_metrics_commission_social_2019]. But, for now, it's enough that an official poverty line exists - for the UK, since 1991 it's been defined 2/3rds of median equivalised household income ]. This is the Households Below Average Income (HBAI) measure[^FN_HBAI_2]; looking back at figure 1, this is the line marked "£304pw" to the left of the chart; you can see straight away that, since the line falls towards the top of the second decile, about 18% of the population is in poverty on that measure.


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
