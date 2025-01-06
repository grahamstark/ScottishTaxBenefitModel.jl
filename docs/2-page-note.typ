#import "@preview/charged-ieee:0.1.3": ieee

#show: ieee.with(
  title: [ScotBen: A New Microsimulation Tax-Benefit Model],
  abstract: [
    ScotBen is a new microsimulation tax-benefit model written
    by Graham Stark of the University of Northumbria and Virtual Worlds Research. The primary scope of ScotBen is
    the Scottish fiscal system, though it is also capable of modelling the other three Home nations, and the UK as a whole. 
    This brief note describes the models design, implementation, unique features, and limitations. 
    ],
  authors: (
    (
      name: "Graham Stark",
      department: [Social Work and Social Policy],
      organization: [University of Northumbria],
      location: [Newcastle, UK],
      email: "graham.stark@northumbria.ac.uk"
    ),
  ),
  paper-size: "a4",
  index-terms: ("Microsimulation", "Scotland", "Taxation", "Poverty", "Inequality"),
  bibliography: bibliography("PHd.bib"),
  figure-supplement: [Fig.],
)

#set text(font:"ETBembo")
#show link: underline
  
#show table.cell.where(x: 2): set text(style: "italic", size:7pt)
#show table.cell.where(x: 1): set text(size: 4pt, font:"JuliaMono")
#show table.cell.where(x: 0): set text(size: 7pt)

#set table (
    columns: (8em, auto, auto),
    align: (left, left, left),
    inset: (x: 8pt, y: 4pt),
    stroke: (x, y) => {if y <= 1 { (top: 0.5pt) }},
    fill: (x, y) => if y > 0 and calc.rem(y, 2) == 0  { rgb("#dfdfef") },
  )
#show table.footer: set text(style: "italic")


= Introduction

Scotben @stark_scottish_2024 is a conventionally structured static microsimulation tax-benefit model, 
in the family of models branching out from the Institute for Fiscal Studies' TAXBEN, of which Graham Stark was one of
the principal authors @johnson_taxben2_1990. Scotben has been used in several projects at the University of Northumbria and elsewhere.
With the exception of some survey data, Scotben is fully Open Source@open_source_initiative_open_1999, 
and released under a #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/LICENSE")[permissive licence].

This note is intended as a 'warts and all' summary of some key aspects the models development, structure, novel features, uses to date,
and strengths and weaknesses. 

As with all models of this sort, ScotBen is continually being updated and developed, and so this note may not
always be in sync with the latest version. 

= Scope <sec:scope>

As the name suggests, the ScotBen's primary scope is the the Scottish fiscal system.
The model covers taxes and benefits that individuals are directly liable for,
such as income and spending taxes and cash benefits, though it also has some limited
ability to capture the effects on individuals of e.g. Corporate Taxes and Green Levies. 
Both devolved taxes and benefits and those reserved to the UK government are included.
Many hypothetical structural reforms can be modelled without requiring modifications to the code,
including basic incomes, wealth taxes and various local taxation schemes. See the @model-coverage appendix for 
a full list of the taxes and benefits included. 

= Design and Implementation <sec:implementation>

At it's heart, Scotben is a single period, static microsimulation model. It loosely follows the 
design of IFS's TAXBEN2, though ScotBen is programmed in a different language (Julia@sec:julia vs TAXBEN's Pascal/Delphi)
and no TAXBEN code was referred to. 

The model attempts to follow modern program development practices, with short, independently testable,
functions, a comprehensive test suite @sec:testing, and readable code. In places, however, the
scale of the project means that these ideals are honoured in the breach.

Despite its fundamentally static nature, Scotben's modular design and clean interfaces make it easy to 
build simulations incorporating 
behavioural responses or long-term projections on top of the base model. 

== Julia<sec:julia>

The model is written in Julia @bezanson_julia_2017. As discussed in that paper, Julia is intended to solve the 
"Two Language Problem": to be equally useful for conventional large-scale programming and for exploratory data science. Julia produces highly efficient code, 
comparable in speed with Fortran or C. 
Although not without its problems, this dual nature means that Julia has proven a good choice for microsimulation. 

The model is organised as a Julia package - a bundle of code and
data that can be automatically downloaded and run using standard Julia tools. All code and most data is stored and developed on the GitHub code sharing site @stark_scottish_2024.

Internally, the model is organised as a series of #link("https://docs.julialang.org/en/v1/manual/modules/")[modules], arranged to minimise cross-dependencies. For example, there are modules that:

- #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/STBParameters.jl")[capture the fiscal system parameters];
- #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/IncomeTaxCalculations.jl")[calculate income tax]

Many other such modules are referred to below. 

== Data 

ScotBen uses Family Resources Survey (FRS) @dwp_family_2012 as its primary data. 
For Scottish runs, pooled Scottish FRS subsets from 2016-2022 are used (just over 17,000 households); UK-wide
simulations presently use a single full FRS year. The #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/HouseholdMappingFRS_Only.jl")[HouseholdMappingFRS.jl] 
package creates the main model dataset, and #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/ModelHousehold.jl")[ModelHousehold.jl] encapsulates the model's view of a household.

The model has a built in #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/Weighting.jl")[weighting system] @creedy_survey_2003 using a native Julia implementation of standard
survey data weighting algorithms@stark_grahamstarksurveydataweightingjl_2022. As well as standard
demographics, this allows us to weight to #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/targets/scotland-2022.jl")[Scottish employment totals, disability benefit receipts, 
local authority-level populations and occupations]. We can also use the inbuilt weighting system
to use ScotBen to model individual Local Authorities.

Data is then #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/Uprating.jl")[uprated] using a combination of ONS price and earnings data, supplemented by some OBR 
and SFC forecast data. Uprating is normally to 1 quarter behind the current quarter. 

The FRS has very limited information on wealth and assets, and no information on consumption. It also has
no Local Authority identifiers. To allow modelling of (e.g.) a Wealth tax or indirect taxes such as Fuel Duty or VAT,
the FRS data is supplemented by the Wealth and Assets Survey (WAS)@statistics_wealth_2019,
Living Costs and Food Survey (LCF)@statistics_living_2019 and Scottish Household Survey (SHS) @scottish_government_scottish_2008.
These datasets can either be matched in@leulescu_statistical_2013 - #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/MatchingLibs.jl")[picking WAS/LCF/SHS records with similar characteristics to each FRS record], or #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/regressions/wealth_regressions.jl")[imputed using linear regression] (SHS is always data-matched).

== Testing <sec:testing>

ScotBen is developed Test First @version_one_test-driven_2016. A large suite of Individual, Benefit Unit, and Household level 
level example calculations for each tax and benefit was collected and expressed as unit-tests. Code was then written so all the tests pass. 
Sources used included official and semi-official online calculators@policy_in_practice_better_2024, taxation textbooks@melville_taxation_nodate, 
benefit manuals@cpag_welfare_nodate-1, and our own calculations. The test suite also contains numerous aggregate tests
which check that complete model runs produce plausible aggregate values for revenues, expenditures and caseloads.  

The #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/test/")[testsuite] currently contains over 1,000 individual tests
and 10,000 lines of code. In addition there are over 150 runtime consistency assertions in the main body of code - these
will halt a simulation if any abnormal condition is encountered.

The suite is used as a 'continuous integration' tool @google_inc_introducing_2007: part or all of the tests
are run before every change to the model is committed. This helps prevent errors being introduced during development.

= Applications And Novel features <sec:novel-features>

Scotben's clean, modular, design makes it easy to incorporate the code into specialised applications. 
Examples to date are:

== Budget Constraints

This uses the a simple algorithm@duncan_recursive_2000 @stark_grahamstarkbudgetconstraintsjl_2020 to
draw exact budget constraints - the relationship between net income and 
earnings for individuals with differing earnings capacity and family circumstances.
Often this relationship is startlingly non-linear. These budget constraints
are the best foundation for dynamic labour supply models.

An online Budget Constraint Generator is available at:

https://stb.virtual-worlds.scot/bcd/

== Local Taxation 

The weighting system discussed above can be used to weight the FRS dataset
so that the sample grosses up to the population of a local authority.
Data is weighted to 2022 Census data on occupation, tenure, accommodation type, employment status, age, sex and household size. 
See the module #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/LocalWeightGeneration.jl")[LocalWeightGeneration.jl]

== The Public Preference Calculator (TriplePC) 

The Public Policy Preference Calculator (TriplePC)@stark_public_2024 is an adaption of the model that extends the microsimulation art in two ways:

First, as well as modelling the outcomes of a policy in the conventional way, our model uses
Conjoint Analysis of public acceptability data to give an indication of the policy’s popularity. This is
novel and important. There are measures that might actually be popular with the electorate, but which
policymakers have been unwilling to touch because of uncertainty about their electoral
consequences@nettle_sp21_2023.

Second, we integrate health outcomes into the model@reed_examining_2024. We built a model relating SF-12 scores to income and
demographic characteristics; SF-12 is a widely used measure of an individual’s health-related quality
of life, with two summary scores: the Physical Component Summary (PCS-12) and the Mental
Component Summary (MCS-12). The health model is estimated over 12 waves (2009/11-2020/22) of
Understanding Society @institute_for_social_and_economic_research_understanding_2018 panel data 
and implemented in the #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/HealthRegressions.jl")[HealthRegressions.jl] module, which maps the regression coefficients to 
the ScotBen dataset.

This version uses the UK-wide FRS sample. An online version is available at: #link("https://triplepc.northumbria.ac.uk")[https://triplepc.northumbria.ac.uk].

== Legal Aid

Scotben has recently been used to build a model of Legal Aid
entitlement and costs for the Scottish Legal Aid Board (SLAB).

The module #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/LegalAidCalculations.jl")[LegalAidCalculations.jl]
encapsulates the means-test rules. Entitlements are estimated by mapping 
SLAB provided administrative data - the #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/LegalAidData.jl")[LegalAidData.jl]
module is used for this. The model is actively being used to design reforms to the 
Legal Aid means-tests.

= Interfaces <sec:interfaces>

By design, the ScotBen model package has no user interface code. 
This actually makes it *easier* to build user interfaces, since there are no clashing dependencies.

Several model Web interfaces have been built (not all may be active).

- https://scotben.virtual-worlds.scot/ - A simple budget simulator, implemented using the #link("https://genieframework.com/")[Genie] web package;
- https://ubi.virtual-worlds.scot/ - A basic income sim, implemented with #link("https://go.plotly.com/dash-julia")[Dash]
- https://stb.virtual-worlds.scot/bcd/ - The Budget Constraint generator discussed above, also implemented with Dash;
- https://triplepc.northumbria.ac.uk - TriplePC, also implemented with Gini.1

The Legal Aid model also has a web interface, though this is not currently public.

In addition, the model can be integrated into #link("https://plutojl.org/")[Pluto] and 
#link("https://jupyter.org/")[Jupyter] notebooks - work on this is ongoing
with a view to using ScotBen in teaching. 

ScotBen can also be run from conventional command-line scripts with a few 
lines of code - there are multiple examples of this in the test suite discussed above, 

= TO-dos 

ScotBen is under active development. As of January 2025, tasks include: 

- _Synthetic Datasets_ since the main datasets cannot be included with the open-source distribution, work is underway om creating synthetic datasets with the same properties;
- _Local Modelling_ - the local re-weighting scheme described above is still being refined;
- _Code cleanups and reorganisation_ - code 'TODO's that are being worked on include clearer and more consistent names fpr variables and functions, removing duplicated and unused code, and and simplifications of some modules, notably the (#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/STBIncomes.jl"))[income handling module]. 
- _Automatic updating_ presently, updating model parameters, inflation rates and grossing up targets takes at least one working week, but much of the needed material is available via public APIs, so the intention is to use those APIs to largely automate the updating process;
- _verificaton against other microsimulation models_ - work is now underway to verify ScotBan's individual-level calculations against those of Policy Engine@woodruff_policyengine_2024;
- _benefit takeup and tax avoidance/evasion_ - work is beginning on creating takeup correction routines@fry_take-up_1993 and revenue responsiveness to taxes on income@scottish_fiscal_commission_how_2018-1.

= More Information
 
- #link("https://stb-blog.virtual-worlds.scot/")[A blog about the model] 
- #link("https://pretalx.com/juliacon-2022/talk/KPRZAM/")[Video presentation] from the #link("https://juliacon.org/2022/")[Juliacon 2022] conference;
- #link("https://virtual-worlds.scot/ou/ima-presentation.pdf")[Powerpoint Presentation] from the #link("https://www.microsimulation.org/events/2024_vienna_world_congress/")[2024 International Microsimulation (IMA) Conference];
- #link("https://stb-blog.virtual-worlds.scot/articles/2022/01/01/IMA.html")[Video] frpm the #link("https://www.microsimulation.org/events/2021_online_world_congrss/")[2022 IMA conference]

* Last updated: #datetime.today().display(). *

#pagebreak()

== Appendix: Modelled Taxes And Benefits <model-coverage>

#figure(
  caption: [Modelled Taxes],
  placement: none,
  table(
    // Table styling is not mandated by the IEEE. Feel free to adjust these
    // settings and potentially move them into a set rThis actually makes it *easier* to 
    table.header[Tax][Code Module][Notes],
    [Income Tax],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/IncomeTaxCalculations.jl")[IncomeTaxCalculations.jl]],[Scottish and reserved UK],
    [National Insurance],[#link("https://github.com/grahamstar.k/ScottishTaxBenefitModel.jl/blob/master/src/NationalInsuranceCalculations.jl")[NationalInsuranceCalculations.jl]],[Employees, Self Employed and Employers (though this needs more thought on incidence)],
    [Council Tax],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/LocalLevelCalculations.jl")[LocalLevelCalculations.jl]],[plus some simple modelling of local income taxes and domestic rates],
    [Wealth Taxes],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/OtherTaxes.jl")[OtherTaxes.jl]],[using WAS data],
    [VAT and excise duties],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/IndirectTaxes.jl")[IndirectTaxes.jl]],[using LCF data; incomplete module],
    [incidence of essentially any tax incident on wages],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/OtherTaxes.jl")[OtherTaxes.jl]],[],
  )
) <tab:taxes> 


=== Modelled benefits

#figure(
  caption: [Modelled Non Means-Tested Benefits],
  placement: none,
  table(
    table.header[Benefit][Code Module][rUK equivalent],
    [Pension Age Disability Payment],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/NonMeansTestedBenefits.jl")[NonMeansTestedBenefits.jl]],[Attendance Allowance],
    [Child Benefit],[""],[ ],
    [Adult Disability Payment],[""],[Disability Living Allowance (DLA)],
    [Carer Support Payment],[""],[Carer's Benefit],
    [Adult Disability Payment],[""],[Personal Independence Payment (PIP)],
    [Contributory Employment Support Allowance],[""],[reserved benefit],
    [Contributory Job Seeker's Allowance],[""],[""],
    [Old/New State Pensions],[""],[""],
    [Bereavement Support Payment (and predecessors) ],[""],[""],
    [Maternity Allowance],[""],[""],
    [Statutory Maternity Pay],[""],[""],
  )
)

_note:_ The Scottish disability benefits:
    - Carer’s Allowance Supplement
    - Carer Support Payment
    - Adult Disability Payment
    - Child Disability Payment
    - Pension Age Disability Payment
are modelled as being equivalent to the rUK benefits, though a mechanism exists to make the disability tests more or less generous.] <fn-disability>

#figure(
  caption: [Modelled Means-Tested Benefits],
  placement: none,
  table(
    table.header[Benefit][Code Module][Notes],
    [Scottish Child Payment],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/ScottishBenefits.jl")[ScottishBenefits.jl]],[Scottish-specific; passported],
    [Universal Credit],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/UniversalCredit.jl")[UniversalCredit.jl]],[UK reserved, though ScotGov aspire to remove the 2-child limit ],
    [Savings Credit/Pension Credit],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/LegacyMeansTestedBenefits.jl")[LegacyMeansTestedBenefits.jl]],[ ],
    [Council Tax Reductions],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/LegacyMeansTestedBenefits.jl")[LegacyMeansTestedBenefits.jl]],[ ],
    [Housing Benefit],[""],[Being phased out for working-age families; see #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/UCTransition.jl")[UCTransition.jl]],
    [Working Tax Credit],["" ],[ ""],
    [Child Tax Credit],[ ""],["" ],
    [Income Support ],[ ""],[""],
    [Non-Contributory Employment Support Allowance],[""],[""],
    [Non-Contributory Job Seeker's Allowance],[""],[""]
  )
)
      
#figure(
  caption: [Others],
  placement: none,
  table(
    table.header[Benefit][Code Module][Notes],

    [Minimum Wages],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/HouseholdAdjuster.jl")[HouseholdAdjuster.jl]],[ ],
    [Scottish Civil Legal Aid],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/LegalAidCalculations.jl")[LegalAidCalculations.jl]],[ ],
    [Basic Incomes],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/UBI.jl")[UBI.jl]],[],
    [Wealth Taxes],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/OtherTaxes.jl")[OtherTaxes.jl]],[ ],
    [Various Local Taxation schemes],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/LocalLevelCalculations.jl")[LocalLevelCalculations.jl]],[ ],
    [The Benefit Cap],[#link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/BenefitCap.jl")[BenefitCap.jl]],[ ],
  )
)

=== Not currently modelled
    - Any form of Student Support;
    - Student loans and repayments (working on repayments ATM)
    - Food banks or similar;
    - Foster Care payments
    - Scottish Best Start payments
    - Child Winter Heating Payment
    - Winter Heating Payment
    - Funeral Support Payment
    - Job Start Payment
    - any local authority-specific payments
    - Young Carer Grant

#pagebreak()

