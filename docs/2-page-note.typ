#import "@preview/charged-ieee:0.1.3": ieee

#show: ieee.with(
  title: [ScotBen: A New Microsimulation Tax-Benefit Model],
  abstract: [
    ScotBen is a new microsimulation tax-benefit model of written
    by Graham Stark of the University of Northumbria and Virtual Worlds Research. The primary scope of ScotBen is
    the Scottish fiscal system, though it is also capable of modelling any of the four nations and the UK as a whole. 
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

= Introduction

Scotben @stark_scottish_2024 is a conventionally structured static microsimulation tax-benefit model, 
in the family of models branching out from the Institute for Fiscal Studies' TAXBEN, of which Graham Stark was one of
the principal authors @johnson_taxben2_1990. Scotben has been used in several projects at the University of Northumbria and elsewhere.
This note brief is intended as a 'warts and all' summary of the models development, structure, novel features, uses to date,
and strengths and weaknesses.

= Scope <sec:scope>

As the name suggests, the model's primary scope is the the Scottish fiscal system.
The model covers taxes and benefits that individuals are directly liable for,
such as income and spending taxes and cash benefits, though it has some limited
ability to capture the effects on individuals of e.g. Corporate Taxes and Green Levies.

Both devolved taxes and benefits and those reserved to the UK government are included.
Many hypothetical structural reforms can be modelled without requiring modifications to the code,
including basic incomes, wealth taxes and various local taxation schemes.

= Design 

At it's heart, Scotben is a single period, static microsimulation model. 

However, Scotben's modular design and clean interfaces make it easy to build simulations incorporating behavioral responses or long-term projects on top of it - the explicitly dynamic microsimulation models I'm aware of are, in my view, 'run before you can walk' exercises which capture the key effects of the fiscal system poorly. 

= Implementation <sec:implementation>

== Julia

The model is written in Julia @bezanson_julia_2017. Julia is a relatively new language designed 
to be equally useful for conventional programming and for exploratory data science, and to produce highly efficient code, comparable in speed with Fortran or C. 
Although not without problems, this dual nature fits well: Julia has proven a good choice for microsimulation. The model is organised as a Julia package - a bundle of code and
data that can be automatically downloaded and run using standard Julia tools. All code and most data is stored and developed on the GitHub code sharing site @stark_scottish_2024.

The model is organised into a series of #link("https://docs.julialang.org/en/v1/manual/modules/")[modules], arranged to minimise cross-dependencies. For example, there are modules that:

- #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/ModelHousehold.jl")[Encapsulate a household];
- #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/STBParameters.jl")[capture the fiscal system parameters];
- #link("https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/IncomeTaxCalculations.jl")[calculate income tax]


== Data 

The model uses Family Resources Survey (FRS) @dwp_family_2012 data. For Scottish runs, pooled FRS 

= Testing <sec:testing>

#lorem(45)
 
= Novel features <sec:novel-features>

== Budget Constraints

== Poverty and Inequality Measures

== Local Taxation 

== Public Preferences/Conjoint Analysis 


== Legal Aid

= Interfaces <sec:interfaces>

By design the model package has no user inteface dependencies. 
This actually makes it *easier* to 

== Scripting

== Pluto

== Gini

== Dash 



#figure(
  placement: none,
  circle(radius: 15pt),
  caption: [A circle representing the Sun.]
) <fig:sun>

In @fig:sun you can see a common representation of the Sun, which is a star that is located at the center of the solar system.

#lorem(120)

#figure(
  caption: [The Planets of the Solar System and Their Average Distance from the Sun],
  placement: top,
  table(
    // Table styling is not mandated by the IEEE. Feel free to adjust these
    // settings and potentially move them into a set rule.
    columns: (6em, auto),
    align: (left, right),
    inset: (x: 8pt, y: 4pt),
    stroke: (x, y) => if y <= 1 { (top: 0.5pt) },
    fill: (x, y) => if y > 0 and calc.rem(y, 2) == 0  { rgb("#efefef") },

    table.header[Planet][Distance (million km)],
    [Mercury], [57.9],
    [Venus], [108.2],
    [Earth], [149.6],
    [Mars], [227.9],
    [Jupiter], [778.6],
    [Saturn], [1,433.5],
    [Uranus], [2,872.5],
    [Neptune], [4,495.1],
  )
) <tab:planets>

In @tab:planets, you see the planets of the solar system and their average distance from the Sun.
The distances were calculated with @sec:implementation that we presented in @sec:interfaces.

#lorem(240)

#lorem(240)
