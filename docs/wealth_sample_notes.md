# Comparison of ScotBen's Wealth Sample with WAS Wave 7 Raw Data

I'm going through the to-do list. First up was Wealth Taxes: trying to understand why my revenue estimates are lower than Howards'. Since mine are household based and H's are individual, my wealth tax should raise much more for the same rate/band structure. I've noticed a few things but don't really have an explanation:

1) I'm using WAS wave 7 (2018-2020) rather than the latest Wave 8 (2020-2022). I *think* that was because I wanted to skip Covid years.

2) Scotben matches in WAS data from the whole of the UK but gives much higher probability to matching Scottish records and a very low probability of coming from London and SE. (This is contrary to what I remembered and what I told you last week - it's a big program..)

Below I give some sample statistics comparing my Scotben matched wealth records with the actual WAS Scottish subset. The gist of it is that my matched WAS records don't look all that different from the actual Scottish subsample. So I don't think my matching process is why my numbers are lower than Howards'. 

Possible actions:

* try wave 8, Covid or not;
* fix the matching to Scotland only, or just exclude London/SE completely.

Variable compared here is `totwlthr7` - total net household wealth.

## Scotben matched data, 

*uprated, Scotben Weights, Full Sample*

    Median 356,643
    Mean 619,225
    Min -81,318
    Max 99,954,514

(Note: these numbers are from the Essex comparison exercise and will be a bit different now)

## WAS Scottish Subset 

*Wave 7 (unuprated), sample weights*

    Median 302,558
    Mean 576,248
    Min -184,730
    Max 78,521,164

## Region of Origin of Matched Scotben sample

    Scotland             => 6567
    ---------------------------
    North_East           => 256
    North_West           => 525
    Yorks_and_the_Humber => 465
    East_Midlands        => 65
    West_Midlands        => 70
    East_of_England      => 62
    London               => 25
    South_East           => 55
    South_West           => 38
    Wales                => 221
    ---------------------------
    Total                => 8349
