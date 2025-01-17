# Model Maintenance master document - Adding Data, Uprating, Weighting, New Benefits, New Parameters

This tries to bring together everything in the convoluted steps needed to add a year's worth of data to the model (FRS/SHS), uprate the variables and create a new weighting target dataset. 

This is *convoluted*. I don't remember Taxben being this hard. Ideally I'd automate much of this - I had a brief go using some of the APIs for grabbing ONS data, but didn't get far. 

Also, paths and filenames are often hard-wired in: add a paths config file.

Always keep running the test suite while you're doing any of this. 

The struct `UpdatingInfo` in `Definitions.jl` holds static info on when each component below was last updated and should be kept up-to-date.

File paths are held as constants in `Definitions.jl`.

Raw survey data from [UK Data Service](https://ukds.ac.uk) (login in keypass). Unpack these into the `$RAW_DATA/[dataset]/[year]` directories and add simlinks to `tab` and `mrdoc` directories.

* bad thing: the `.rtf` format we needed for loading the documentation into the `dictionaries` Postgres database isn't there anymore. TODO document this db and the Ruby code somewhere and add parsing from `.html` files in mrdoc.

## General usage.

In what follows I assume using the [repl](https://docs.julialang.org/en/v1/stdlib/REPL/) plus [Revise](https://timholy.github.io/Revise.jl/stable/). Starting julia in the `ScottishTaxBenefitModel` home directory.

1) load a script file:

```julia
] activate .
using Revise
includet( "src/[yourfiles])
```

2) load tests:

```julia
] activate .
] test
```

3) load specific test:

```julia
] activate .
using Revise, ScottishTaxBenefitModel
includet( "test/testutils.jl")
includet( "test/[your specific test"])
```


## 1. ADDING a new FRS/HBAI

Code is `HouseholdMappingFRS_HBAI.jl` (note: not a package). Check the `.tab` files and `.docs` carefully:

* benefit, income codes may change. Check against enums in `Definitions.jl`;
* 2020 FRS `.tab` version had a missing tab which caused wrongly labelled data (See emails to UKDS June-Aug 2022).
* date ranges are hard-wired into `HouseholdMappingFRS_HBAI.jl` and need manually changed.

Note that we use HBAI for optional  `SPI`' wage and self-employment data so we can only add a year when the HBAI is released.

Note paths wired in to `Definitions.jl`.

Then, run `create_data()`. This creates a full UK-wide dataset. Run `scripts/create_scottish_subset` with `ADD_IN_MATCHING` set to `false` (initially) to create just scottish bit. `ADD_IN_MATCHING` needs to be `false` until step (2) below.



## 2. Matching in a new SHS

Unpack new SHS as above. The matching code is an unholy mess. 

In `matching/`:

* `matching_funcs.jl` - library
* `matching.jl` - driver code. Note this also has year ranges hardwired in at the top which need manually changed. You may need to execute the code in `matching.jl` in stages as it makes successively coarsened matches. Also some crude hhld totals close to the bottom used as consistency checks - these need to be updated each year (or just deleted). TODO output of this should be lists of candidate SHS donor households.

## 3. Creating a target weighting dataset

Directory (for 2022) `data/targets/aug-2022-updates/`; create something similar for each year. Main workfile is `target_generation.ods` which attempts to get counts of people, households, employment, etc. consistent.

Output is (for 2022) at 90 piece target set. Sources:

* [NOMIS Standard Scottish Report](https://www.nomisweb.co.uk/reports/lmp/gor/2013265931/report.aspx) - employment, social class. These numbers are adjusted manually to match entire popn totals (shouldn't be different but are);
* [Stat XPLORE](https://stat-xplore.dwp.gov.uk/webapi/jsf/login.xhtml) - benefits (in payment);
* [National Records Scotland (NRS) Household Projections](https://www.nrscotland.gov.uk/statistics-and-data/statistics/statistics-by-theme/households/household-projections/2018-based-household-projections). 2018 based data. 2022 projections. Note we use the non-household pcts from `2018-house-proj-source-data-alltabs.xlsx` for scaling down population just to household based popn (excluding students in halls, those in care homes, etc.);
* [NRS - Housing Stock by Tenure](https://www.gov.scot/publications/housing-statistics-stock-by-tenure/) - scaled up to 2022 hhld projections
* [NRS Population forecasts](https://www.nrscotland.gov.uk/statistics-and-data/statistics/statistics-by-theme/population/population-projections/population-projections-scotland/2020-based). NOte we scale by NRS estimates of Scotland-level proportion of populations in households. TODO: Glasgow,Edinburgh have huge student 16-21 population in halls but we only have hhld counts by LA so are ignoring this.

All this has to be merged together manually on any update, I'm afraid. Note how we change the standard age ranges 10-14 and 15-19 to 10-15 16-19 to better mesh with employment data. Note how everything needs to be scaled to match 2022 hhld/population numbers (popn is all or hhld depending on the question - see the spreadsheet).

## 4. Uprating

Main uprating file is `data/prices/indexes/indexes.tab`. Uprating code is `Uprating.jl`; filenames and uprating targets in `Settings.jl`. Sources are as in `indexes.tab` header rows. Indexes are quarterly. Sources:

* [OBR Economic and fiscal outlook – March 2022: Supplementary Data]https://obr.uk/data/);
* [Scottish Fiscal Commission Forecast](https://www.fiscalcommission.scot/publications/scotlands-economic-and-fiscal-forecasts-december-2021/)

FIXME this needs updating urgently.

## 5. Benefits

There are 3 things here: numbers for the transition to UC, estimates of how many on legacy disability benefits we should move to new benefits and some probits we use to model generosity of disability tests.

### 5.1 The Legacy/UC transition

This is done very, very crudely using [House of Commons Data](https://commonslibrary.parliament.uk/constituency-data-universal-credit-roll-out/#caseload). We use Scotland-wide approximations, which are then hard-wired into `UCTransition.jl`. We could use LA level if someone still produced this (HoC is constituency). Can't be bothered trying myself.

### 5.2 Model Transitions to new disable/carer benefits

Code is `HistoricBenefits.jl`. It re-assigns DLA recipients to PIP according to proportions on each in the interview month for Scotland as a whole. 

Data files are: 

* `data/receipts/[pip|dla]_2002-2020_from_stat_explore.csv`

To update these, randomly press buttons on STat Explore until something comes out - DLA/PIP in receipt, including devolved to Scotland, current tables. Note I have a saved table format for PIP. Export as `.xlsx`. Transpose in open office to same format as `data/receipts/pip_2002-2020_from_stat_explore.csv`. Change filename in `HistoricBenefits.jl`.

You also need to update `params/historic_benefits.csv`; see section on updating parameters below.

### 5.3 Benefit Generosity

Main script is `regressions/disability_regressions.jl`

Creates `candidates` files in `data/disability/`

If the data has been created correctly, just running the script should create these files automatically. A data year dummy for the new year's data should be automatically added.

## 6. Adding new default parameters

Most of the individual level tests are based on the system when I started, using the 2020/21 values hard-wired into the parameter definitions using the [@with_kw Macro](https://github.com/mauro3/Parameters.jl). So, don't alter the defaults there. Instead, copy 

`sys_2022-23.jl` and update that. This can be loaded using `load_file` in STBParameters. If thing are changing rapidly you can add or remove some parameters in a separate file and and layer that on top of the main parameters using the mutating `load_file!` function.

### 6.1 Direct Taxes

Note that it's best to get an updated version of [Melville's Taxation](https://www.amazon.co.uk/Taxation-Finance-2022-Alan-Melville/dp/129243953X/ref=sr_1_1?crid=RFHJT70PAC2L&keywords=melville+taxation&qid=1661165205&sprefix=melville+%2Caps%2C89&sr=8-1) for a consolidated set of parameters and test examples.


* [(r) UK Income Tax](https://www.gov.uk/government/publications/autumn-budget-2021-overview-of-tax-legislation-and-rates-ootlar/annex-a-rates-and-allowances)
* [Scottish Income Tax](http://www.gov.scot/publications/scottish-income-tax-2022-2023/)

But use Mellvile.

### 6.2 UK Benefits

Only place I know with everything in one place is the [CPAG Guide](https://cpag.org.uk/shop/cpag-titles/welfare-benefits-tax-credits-handbook-202223).

But:

* [UK Wide Benefits (NOT legacy tax-credits)](https://www.gov.uk/government/publications/benefit-and-pension-rates-2022-to-2023);
* [Scottish Benefits]()


### 6.3 Scottish Benefits

See [here](https://www.gov.scot/publications/social-security-assistance-effects-inflation-report-2021-2022/pages/12/). Notes:

* some implementations are incomplete (TODO);
* link may not be permanent.

### 6.4 Local Housing Allowances

2022/3 values are [here](https://www.data.gov.uk/dataset/81a61cf3-ccad-4ba2-8945-74a2e6cbe4f9/broad-rental-market-areas-brma). 

Note the BRMA definitions are treated as constants.

> " for this year (2022-23) all rates have been frozen at the rate last determined on 31st March 2020. This was the 30th percentile at that time."

So I'll skip changing this for now.

### 6.5 Council Tax

This needs parameterised better.

Default alues are hard-wired into `default_band_ds` function in STBParameters.

Example loading new values in `sys_2022-23.jl`, at the bottom. Values from [ScotGov CT Datasets](http://www.gov.scot/publications/council-tax-datasets/). We just need the band Ds here so long as the relativities don't change.

## 7. Updating Tests

### 7.1 Individual Level Unit Tests

* there are places (e.g. `uprating_tests.jl`, `historic_tests.jl`) where I've hard wired in test values that will change on each updating. I'm trying to mark all of these with "CHANGEME".

### 7.2 Tests in Aggregate - sources

## 8 Notes on data sources

## References





