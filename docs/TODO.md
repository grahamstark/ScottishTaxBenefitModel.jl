# TODO List  

## As of 28/July 2021

### Council Tax Reductions

* use [Glasgow's calculator](https://glasgow.teamnetsol.com/)
* You must pay your water and waste water charge of: £6.60 a week;
* Maximum CTB?
* check what I have against [CAB Online](http://www.citizensadvice.org.uk/benefits/help-if-on-a-low-income/help-with-your-council-tax-council-tax-reduction/how-your-council-tax-reduction-is-worked-out/council-tax-reduction-how-is-it-worked-out/)

### FRS

* Add fields for:
  -  SSP/SMP receipt from `Job` records;
  -  usual wages/current wages from job records;-  usual hourly wage.
* more comparisons of HBAI and FRS wage fields; maybe use FRS more;
* duration of benefit receipts? For LMT->UB transition?
* `PenCont` check the very big ones for on-off flag;
* `Accounts` only for < 16k - check the routine here in the questionairre and get something for over 16ks.
* `BenUnit` add a `total_savings` field somewhere - assign to hoh/ho ben unit? split?

### Incomes module

* Usual wage field;
* utility thing to regenerate constants each time a field is added/removed.

### Testing

* LMT Benefits full calculations:
  - disability
  - > 1 adult
  - MBUs

### LMT->UC Transition

* find out what's on [Stat-XPLORE](https://stat-xplore.dwp.gov.uk/webapi/jsf/login.xhtml)
* HOC thing? By LA?
* .. or by length on benefits?

### Model Running

* Loadable config/run settings file;
* finish `Runner.jl` dataframes;

### Code Style

* batch job to cleanup crazy FRS based variable names;
* using/import : clean up: check if things are actually used, reformat as needed;
* check stuff against [BlueStyle](https://github.com/invenia/BlueStyle).