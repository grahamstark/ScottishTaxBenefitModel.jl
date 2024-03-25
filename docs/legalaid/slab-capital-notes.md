# Capital Notes 


`totsav`

`totsavbu` Same as TOTSAV but fewer categories

`totacapb4` 

`assets`

`accounts` - has interest only (in public version)

`totcapb3`
`totcapb4` - benefit unit level - two attempts at total assets "Similar to version 2 but derives interest rate assumptions from the dataset using account median interest rates
Similar to version 3 but derives values for current and basic accounts using CBAAMT2." 
`b4` 2019- `b3` 2009- `b2` 2006-10

so, `b3`.

`totsav`: Estimated value of accounts/investments

`totsavbu` Recoded TOTSAV for benunit

- but seems to be asked directly (Q Instructions 2021 p356):

This question is asked of adults. Note that if the respondent has a current account which
fluctuates over pay periods, the amount required is the figure left in the account at the end
of the pay period, just before the respondent is paid again. If the respondent is overdrawn
on any accounts do not take this amount away from the total amount, simply count it as a
zero asset.

````

summarystats(bu.totcapb3)
Summary Stats:
Length:         18541
Missing Count:  0
Mean:           81888.236582
Minimum:        0.000000
1st Quartile:   0.000000
Median:         2438.360000
3rd Quartile:   17500.000000
Maximum:        54026481.179881


summarystats(bu.totcapb4)
Summary Stats:
Length:         18541
Missing Count:  0
Mean:           82743.437607
Minimum:        0.000000
1st Quartile:   100.000000
Median:         3000.000000
3rd Quartile:   20075.000000
Maximum:        54069381.179881

````

SO: 

* using `totcapb3`
* assign as an individual field to bu head
* longer term, use person information in `account` & `assets` to assign to inviduals
* check against `totsav` and `totsavbu` ranges 

## Repayments/Debt

All this stuff:

```
If DLOANNum > 0
? Last loan repayment amount
 DLOANIn1
[FIRST/SECOND/THIRD.FOURTH/FIFTH/ALL OTHER LOANS]
How much was the last repayment on [{for each loop 1-5 if DLOANNUM is less than
or equal to 5 then} this loan / {if 5th loop and DLOANNUM>5 then} all other loans]?
INTERVIEWER: Respondents may find it useful to check bank statements and work
out last repayment amount
:0..9997
ENTER AMOUNT IN £s
If DLOANIn1 > £2500
Soft Check
INTERVIEWER: “Are you sure? This seems high.”
```

Is this in the restricted version? Social Deprivation section.

So: experimental data in 2021-2 FRS only, and not actually included in the public dataset.

WAS debt data