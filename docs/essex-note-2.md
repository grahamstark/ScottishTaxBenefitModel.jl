
Hi Graham,

> Many thanks for this clarification.  I sympathise with your experience attempting to model council tax and related benefits, as this has been an on-going area of tinkering for us as well.  As it turns out, your suspicions were broadly correct - implementing your value for council tax obtains very similar projections, subject to some deviations among means-tested benefit recipients (see file 12-private-single-200.0-1-0-0.xlsx, sheet UC disaggregation).

I'm planning on re-working CT Benefit completely before starting on this project properly.

I'm puzzled about why the income tax and NI numbers should be different at all, and how far up your UC entitlement goes. Possibly the UC one is because your modelled rents are too high, if you're not applying the BRMA restrictions.

> Can you please tell me what values you assumed for council tax for the other categories reported?  Specifically, did you assume £83.39 per month for all single bedroom units, and another figure for all four-bedroom units?  If so, can you please tell me the four-bedroom figure?  If not, can you let me know what alternative you used?  I can then revise projections for the budget constraints of other units considered.

The CT is Band C throughout. 

For periods, I assume:

WEEKS_PER_YEAR = 365.25/7 = 52.1785
WEEKS_PER_MONTH = 4.354 (since you use this)

so the CT is:

£1_499.00/WEEKS_PER_YEAR*(320/360) = 25.5362pw

x 0.75 = 19.15pw for a single person

monthly: 111.18/83.39

where 1_499.00 is Glasgow 2024/5 Band D.

You'll also need the BRMA Greater Glasgow rent values (0..4 bedrooms, pw):

[103.56, 159.95, 195.62, 223.23, 414.25]

the 103.56 (450.90pm) is what you want for this case (single under 35 year old).




