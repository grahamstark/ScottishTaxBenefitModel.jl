Good news — for question 1 I found solid, recent, official figures, including a Scotland-specific breakdown that's actually calculated on exactly this basis. Question 2 is genuinely more obscure — HMRC doesn't publish a single headline "% co`:llected in year of accrual" figure — but I can give you the mechanism and a reasonable bound.

## 1) PAYE vs Self Assessment share of Income Tax collected

**UK-wide:** HMRC's Income Tax Receipts Statistics put this at roughly **85% PAYE / 15% Self Assessment**, and this ratio has been fairly stable for years. For example, in 2018-19, total net Income Tax receipts were estimated at £191.0 billion, with PAYE receipts estimated at £161.9 billion and Self-Assessment receipts estimated at £31.5 billion — that's about 85% PAYE, 16% SA (the extra couple of points reflects separate repayments/other adjustments in the accounting). The following year, total net Income Tax receipts for 2019-20 were £193.2 billion, with PAYE at £164.8 billion and Self Assessment at £32.2 billion — essentially the same split.

**Scotland specifically:** there's a proper official comparator here, from HMRC's Scottish Income Tax Outturn Statistics, which explicitly report the PAYE/SA collection split for both Scottish and rest-of-UK taxpayers on a like-for-like basis (non-savings, non-dividend income — the devolved portion). For 2024-25: 87.5% of rest-of-UK liabilities are collected through the PAYE system, while for Scotland the equivalent figure is 90.1%, up 0.3 percentage points on 2023-24. The report attributes this to a significantly higher proportion of rest-of-UK taxpayers being required to submit Self Assessment returns compared to Scottish taxpayers. The equivalent Scottish PAYE share has hovered in the high-80s for years — it was 88.4% in 2016-17 and has drifted up to 90.1% by 2024-25, according to the same publication's historical table.

One caveat: the Scotland/rUK figures are on an NSND (non-savings, non-dividend) basis, since savings and dividend tax rates aren't devolved — so it's not exactly the same basis as the whole-UK figure above, but it's the closest apples-to-apples split available and the UK-wide figure is dominated by NSND income anyway, so the comparison is meaningful.

## 2) Proportion of liabilities collected in the year they accrue

This one doesn't have a clean published percentage — HMRC and OBR both flag the receipts-vs-liabilities gap as a known issue but describe it qualitatively rather than quantifying "% collected in-year" as a headline statistic. What is documented:

- **PAYE** (the ~85-90% majority) is deducted and passed to HMRC before wages or pensions are paid — essentially collected in the same tax year the liability arises, with only a small lag for year-end reconciliation.
- **Self Assessment** (~10-15%) is the part that misses the accrual year almost entirely: there are lags between when Income Tax liabilities arise and when the corresponding taxes collected through Self Assessment are received, because the majority of Income Tax collected through Self Assessment is not usually paid until the year after the liability arises. SA returns and the balancing payment are due the following January, roughly 9-10 months after the tax year ends — so even the Payments on Account made during the year are estimates based on the *prior* year's liability, not the year in question.

So the rough shape is: if PAYE (~85-90% of the total) is collected almost entirely within the accrual year, and SA (~10-15%) is collected mostly in the following year, then the proportion of the *total liability* collected within its own accrual year is somewhere in the high-80s to low-90s percent — but that's my own arithmetic sketch from the two facts above, not a number HMRC publishes directly, so treat it as an estimate rather than an official statistic. If you need a defensible figure for something formal, the SA vs PAYE established-liability tables in the Scottish Income Tax Outturn publication (Table 3, linked above) combined with HMRC's monthly receipts timing data would let you build a more rigorous estimate — happy to help with that if it's worth digging further.

Good context — that's a much more interesting question than SA timing alone. A ~£2bn gap on ~£18.6bn of Scottish income tax (roughly 10%) is too big to be explained by receipts-vs-liabilities timing, since that only affects *when* cash arrives, not the *total* liability a model should be estimating. Since SFC and ScotBen are both presumably modelling the same tax-year liability (not cash receipts), the SA lag you originally suspected shouldn't matter much here at all — that's a receipts/liabilities distinction, and a well-built microsimulation model estimates liabilities directly.

Some other candidates worth checking, roughly in order of how much I'd expect them to matter for a gap this size:

**1. Behavioural response / avoidance adjustments**
SFC explicitly builds in a costed behavioural response to Scotland's higher marginal rates relative to rUK — cross-border migration, income-shifting (e.g. dividends instead of salary, timing of bonuses/pension contributions), and reduced labour supply at the top of the distribution. If ScotBen computes liabilities purely mechanically (rate × taxable income from survey data) without a behavioural adjustment, this is probably your single biggest suspect — SFC's published behavioural costings for the Higher/Advanced/Top rate divergence have historically run into the hundreds of millions and can be over £500m depending on the year, concentrated exactly where a model would otherwise be most confident (high earners, where per-taxpayer liabilities are large).

**2. Gross liability vs net Exchequer yield**
A microsimulation model naturally produces gross statutory liability. SFC's/HMRC's headline figure is net of several deductions that don't show up in a standard rate-and-bands calculation:
- Relief at Source pension relief (basic-rate relief passed to pension providers, not retained as tax)
- Gift Aid relief passed to charities
- An allowance for uncollectable/written-off amounts (non-payment, insolvency, etc.)
These aren't huge individually (a few hundred million combined at the Scotland level) but they're a real, systematic gap if ScotBen isn't netting them off, and they compound with everything else.

**3. Reliefs and allowances not (fully) modelled**
Worth an audit of which reliefs ScotBen actually applies: Marriage Allowance, Married Couple's Allowance, Blind Person's Allowance, Gift Aid, pension contributions (net pay / relief at source / salary sacrifice), Landlord Loan Interest relief, Foreign Tax Credit Relief, EIS/SEIS/VCT reliefs. HMRC's Personal Tax Model applies all of these; if your survey data or model logic only captures the "big" allowance (Personal Allowance) and skips the smaller ones, each taxpayer's liability is a bit too high, and across 3 million Scottish taxpayers that adds up.

**4. Personal Allowance taper and higher-rate/advanced-rate boundary mechanics**
Given how much fiscal drag matters right now (frozen thresholds since 2021-22), a small bug in how the taper above £100,000 or the band boundaries are implemented would misallocate a lot of income into the wrong marginal band. This is a place where a ~10% error is entirely plausible from a subtle off-by-one or wrong-threshold issue, especially with Scotland's six-band structure (starter/basic/intermediate/higher/advanced/top) being more fiddly to implement correctly than rUK's three-band system.

**5. Underlying income data quality, especially at the top**
If ScotBen's income base comes from a general household survey (e.g. something FRS-like) rather than HMRC administrative data, two known issues cut in *opposite* directions and are worth checking separately:
- Survey data typically *underrepresents* very high incomes (top-coding, low response rates among high earners) — that would make you *underpredict*, not overpredict, since the top few percent contribute a hugely disproportionate share of Scottish income tax (recall: ~22% of taxpayers pay ~68% of the tax).
- But if income is grossed up or reweighted to match population/income totals without matching the actual concentration at the top, you can inadvertently inflate liabilities in the upper bands where the marginal rates (42-48%) bite hardest — a small error in the shape of the income distribution has an outsized effect on total tax.

**6. Population and taxpayer-count assumptions**
If ScotBen's employment/earnings growth or population projections are more optimistic than SFC's (they use different determinants — SFC's are calibrated to their own economy forecast), that alone could produce a gap of this size independent of any tax-calculation logic at all. Worth comparing the taxpayer count and average income your model assumes against SFC's published determinants (their Chapter 3/4 supplementary figures) directly, since this is the easiest one to check and rule in or out first.

**7. Scope/definition mismatches**
Worth double-checking: is ScotBen only taxing NSND income at Scottish rates and leaving savings/dividends at UK rates (as it should, since those remain reserved)? Are you correctly excluding non-Scottish-resident taxpayers, and correctly applying Scottish taxpayer status rules rather than just "lives in a Scottish postcode"? A leakage here — e.g. accidentally taxing savings/dividend income at Scottish NSND rates — would inflate revenue in a way that's easy to miss.

If you want to narrow this down quickly, I'd suggest starting with #6 (compare your growth/population determinants against SFC's Chapter 3 figures — cheapest check, rules a lot in or out) and #4 (verify band boundaries and the £100k taper against actual 2024-25/2025-26 Scottish thresholds), before diving into the harder-to-quantify behavioural piece.
