# SCOTBEN Install Instructions
author:
  - name: Graham Stark
    id: jc
    orcid: 0000-0002-4740-8711
    email: graham.stark@northumbria.ac.uk
    affiliation: 
      - name: Northumbria University
        city: Newcastle
        url: northumbria.ac.uk
date: 8 April 2025


## Julia

The model is written in [Julia](https://julialang.org/). To install Julia, use [JuliaUp](https://julialang.org/downloads/). ScotBen is developed against the latest public julia release, currently `v1.11.4` - please don't use an earlier version. 

## The Model

The model is a [Julia package](https://docs.julialang.org/en/v1/stdlib/Pkg/). It's not an official registered package however, though three of its main components are. (Until I have a plausible synthetic dataset I don't feel I can register it). This makes it slightly more awkward to install and work with using Julia's standard package management features.

The model is open source and lives on [GitHub](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/`). Data is *not* in the repository and is managed separately.

There are 2 ways to use ScotBen: 1) grab the Scotben package directly from GitHub and interact with it 'old school' using Julia's very nice command line 'REPL', or 2) download one of the packages that uses ScotBen as a component and interact with that.

### 1. Install the model directly

You'll need a [GIT Client](https://git-scm.com/downloads). (You can also download git repositories as `.zip` files but updating is easier using GIT).

To clone the repository, using the command line GIT version , type:

    git clone git@github.com:grahamstark/ScottishTaxBenefitModel.jl.git
    
And something similar for GUI GIT clients - I've never used one.

Should create `ScottishTaxBenefitModel.jl` directory with all the code and support files.

change to that directory. Run:

    julia --project=. -t auto

This starts the [REPL](https://docs.julialang.org/en/v1/stdlib/REPL/). 

Do an initial build. This downloads all the needed libraries and compiles them. Also grabs data:

```julia

using Pkg
Pkg.activate(".")
Pkg.instantiate()
Pkg.update()

```

This may take a while 1st time.

#### Run the Test suite

This is huge and may take up to 1/2 hour to complete. Please get back straight away if any errors are reported.


```julia

Pkg.test()

```
This runs everything; tests can also be run individually.

#### Directory Structure

* `README.md` : the file you see in the GitHub front page
* `Project.toml`: the main project file; specifies required libraries, version information, etc.;
* `Artifacts.toml` : controls downloading of datasets
* `CITATION.cff` : reference file for citations;
* `LICENSE`: MIT licence;
* `params/` : default parameter files and some supporting docs
* `docs/` : vast incoherent collection of documentation including the source for the model bog, IMA articles, working notes, etc. Mostly in markdown;
* `src/` : main source code files
* `data/` : working files for data creation - NOT actual FRS/WAS, etc.
* `etc/` : configuration files e.g. for web enabled version
* `regressions/` : various regressions (engel curves, pip entitlement, etc.);
* `scripts/` : one-off pieces of code. Many are obselete;
* `test/` : model test suite
* `book/` : tutorial material for Northumbria and OU microsim courses
* `matching/` : **NOT USED** replaced with code in `src` 
* `simPop/` : one of several attempts at creating a synthetic dataset;
* `web/`: not used and should be deleted;
* `tmp/` : working directory - should be empty.


#### Simple Model Run

Here's an example of a simple model run from the REPL. 

The steps are:

* import all the libraries you need;
* create a settings structure - tells the model which data to use, how to uprate. and so on.
* set up a monitor - this just displays progress;
* construct at least 1 tax-benefit parameter structure
* run the model using the settings and parameters
* run a routine to summarise the results.

```julia

using CSV
using DataFrames
using StatsBase
using PrettyTables
using Observables

using ScottishTaxBenefitModel
using .STBParameters
using .Runner
using .RunSettings
using .Utils
using .Monitor
using .STBOutput

# default run settings
settings = Settings()
settings.to_y = 2025
settings.to_q = 2 # targetting 2025 q2 should turn off WTC and CTC
settings.means_tested_routing = modelled_phase_in # attempt model the Legacy->UC transition; alternative is uc_full
settings.requested_threads = 4 # multiprocesses if avaliable
# initialise the model data
@time settings.num_households, settings.num_people, nhh2 = 
    FRSHouseholdGetter.initialise( settings; reset=false )

# set up an observer - prints run progress 
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
tot = 0
of = on(obs) do p
    global tot
    tot += p.step
    println(" run $tot households")
end

# base and reform tax-benefit mparameters
# these systems are weeklyised
base_sys = get_default_system_for_fin_year(2024; scotland=true) 
reform_sys = get_default_system_for_fin_year( 2024; scotland=true )
# changes to reform sys go here.., for example - flat 19% income tax
reform_sys.it.non_savings_basic_rate = 1
reform_sys.it.non_savings_rates = [0.19]
reform_sys.it.non_savings_thresholds = [9999999999999999999999.999] # top threshold - all income at 19%

# run the model. `results` is a case-by-case dump of everything.
results = do_one_run( settings, [base_sys, reform_sys], obs )
# Dump hhls-by hhl;d results to temp directory.
dump_frames( settings, results )
# Produce gain-lose tables, costs, poverty and inequality.
summary = summarise_frames!( results, settings )
# outf can be explored in the Repl, for example:
# this prints some fields from the main costs table
pretty_table(summary.income_summary[1][:,
    [:label,
     :working_tax_credit,
     :child_tax_credit,
     :universal_credit,
     :income_support,
     :non_contrib_employment_and_support_allowance,
     :non_contrib_jobseekers_allowance,
     :income_tax]])
```

#### Structure of main results

the `summary` struct holds arrays of results, one per system. Fields are:

* `gain_lose` : DataFrames with gain lose tables
* `income_summary` : DataFrames with costs and caseloads for each income component
* `inequality` : struct with output from the[PovertyAndInequality](https://github.com/grahamstark/PovertyAndInequalityMeasures.jl/) package;
* `poverty`: likewise;
* `metrs` : Marginal Effective Tax Rates - only present if selected in `settings`;
* `child_poverty` : quick summary of child poverty
* `deciles` : matrix with 10 quantiles with popn share, income share, average income and income cut
* `quantiles` : as above with 50 quantiles

plus a couple of fields not needed here. 

So, for example:

* `summary.deciles[1]` gives you the deciles for the 1st (base) system

There are 3 types of data structure here:

1. [DataFrames](https://dataframes.juliadata.org/stable/) - spreadsheet-like structures similar to Python's[Pandas](https://pandas.pydata.org/) (but better);
2. Fortran-like matrices; and
3. [structs](https://docs.julialang.org/en/v1/manual/types/#Composite-Types) - c-like structs with fixed fields.


You can use `pretty_table` command in the REPL to display any of these, (except poverty and inequality structs). But just typing the name prints everything reasonable clearly.

#### Parameters

The example above creates two sets of tax-benefit parameters and modifies the second of them. The call:

```julia
get_default_system_for_fin_year( 2024; scotland=true )
```

loads the 2024 system. Refer to `src/STBParameters.jl` for the exact structure. 

By default, everything is weeklyised, but you can load parameters with annualised taxes, monthly UC, etc. and weeklyise them:

```julia
sys = get_default_system_for_fin_year( 2024; scotland=true; autoweekly=false )
# your annual/mnthly changes here ..
weeklyise!(sys)
```

Main fields are:

```julia
  it: IncomeTaxSys
  ni: NationalInsuranceSys
  lmt: LegacyMeansTestedBenefitSystem
  uc: ScottishTaxBenefitModel.STBParameters.UniversalCreditSys
  scottish_child_payment: ScottishTaxBenefitModel.STBParameters.ScottishChildPayment
  age_limits: AgeLimits
  hours_limits: HoursLimits
  child_limits: ChildLimits
  minwage: MinimumWage
  hr: HousingRestrictions
  loctax: LocalTaxes
  nmt_bens: NonMeansTestedSys
  bencap: BenefitCapSys
  ubi: ScottishTaxBenefitModel.STBParameters.UBISys
  wealth: WealthTaxSys
  othertaxes: OtherTaxesSys
  indirect: IndirectTaxSystem
  adjustments: DataAdjustments
  legalaid: ScottishLegalAidSys
```


### 2. ScotBen As a component of another package.

The model is designed to be used as a component in other systems, such as web services or larger models.

I've been working on a teaching microsimulation course for Northumbria, based on a IMA 2024 conference workshop. That uses [Pluto Notebooks](https://plutojl.org/) and embeds ScotBen.

Download the course from [GitHub](https://github.com/grahamstark/MicrosimTraining). 

At the top level there are Windows and Unix install scripts `run-training.bat`/`run-training.sh` which build everything and start the Pluto service. If all goes well you'll be presented with a list of workbooks -  are some introductory ones based on the IMA workshop and presently two workbooks that use the full model. 

This is work in progress but Pluto is a nice system and it may be more comfortable to work this way.

The model also has various live Web based interface versions:

* [Be The Finance Secretary](https://scotben.virtual-worlds.scot/)
* [Budget Constraints](https://stb.virtual-worlds.scot/bcd/)
* [TriplePC](https://triplepc.northumbria.ac.uk/)

None of these are updated.

## 3) Known Missing/Worrysome Feature

**As of 8/April 2025**

ScotBen has been worked on heavily over the last few weeks, as part of this project, work at Northumbria and also a general update. All tests pass, but WAS/SHS/LCF data matching and data weighting are completely revamped. And various updates added. Missing and worrying things I'm aware of are:

1. I haven't yet produced an updated UK wide dataset, as used in the [TriplePC](https://triplepc.northumbria.ac.uk/) project. Many tests of the triplepc components are currently switched to using Scottish Data;
2. There's no 2025/6 parameter set as yet;
3. The code to switch between UC and legacy benefits has been rewritten to reflect the abolition of WTC and CTC, but is a bit of a hack currently and not fully tested;
4. Council Tax Rebates for Universal Credit cases are flat wrong at the moment - it was hard to get good information on this and I misunderstood what I had;
5. Code to route between PIP/DLA/AA and the Scottish equivalents is also rewritten and not fully tested;
6. None of the online versions of the model have been updated.

I'm busy with all of these at the moment.

