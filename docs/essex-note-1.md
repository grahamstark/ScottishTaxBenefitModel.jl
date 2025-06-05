# NOTES 

## Weighting 

1. When I was doing this I found a mistake in the set of weight targets I was using - I'd used the female population targets where the males should have been. Correcting this lowers the weighted Scottish population a wee bit, and also allows us to use less dispersed weights. Note that this target set is new and hasn't been used in a live project, and previous target sets didn't have this error;
2. The weighting algorithm implementation is [here](https://github.com/grahamstark/SurveyDataWeighting.jl); read the Creedy Paper referenced there for the theory; the spreadsheet has the revised target set as sheet#3). We use constrained Chi-Square weighting with upper and lower bounds of 
3. Your data is in this denormalised form - the number of people living in particular tenures, etc. - so I've copied that. The weighting routine will guarantee that we hit targets for the household level variables housing tenure, households per LA and broad household composition. But since these are HH level targets and there's no explicit target for households of different sizes, the numbers of people in different tenures or council areas can vary a little between different samples;
4. I previously sent you a spreadsheet with the derivation of the grossing target set. Points to note:
   - population targets are taken from the latest NRS projections, not the 2022 census. This is to make it easier to produce forward looking projections. (Our local level simulations use the Census, however);
   - populations are household populations - so subtracting the institutional populations (students in halls, care home residents, etc.). Again, workings in the previous sheet;

## Matching

Some data comes from matched in alternative datasets:

1. Local Authority and NHS identifiers : Scottish Household Survey;
2. Wealth variables: WAS (at the household level only);
3. Work Expenses and TTW costs: LCF.

This is all experimental and was added for my ongoing Legal Aid project. 

The matching code is in [the `matching` directory](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/tree/master/src/matching).

Currently, the WAS matching produces median capital per household that's higher than the latest WAS outcomes for Scotland - £365,000 vs £239,500; see [this](https://www.ons.gov.uk/peoplepopulationandcommunity/personalandhouseholdfinances/incomeandwealth/datasets/totalwealthwealthingreatbritain) table 2.8. Previous iterations of ScotBen used regressions to impute wealth. 

All WAS numbers are much higher than FRS equivalents.

## STATS

For most variables I've followed what I think you're doing and provided statistics only over the non-zero values. For some variables (e.g. 1/0 values, ages) the stats include zeros - this is marked in the 2nd column of sheet 2.

Should you needed it, I have (technical term here) a shit ton of additional statistics and raw data I can put somewhere you can download.

As I mentioned last time I would very much like to see individual level data from Euromod, on (at least) wages, self-employment income and housing costs, or at least a note on how you derive and uprate these things. My average wages and se income are above yours, and there's no rent data I cans see in the sheet you sent. Much easier to sort out differences that way.






