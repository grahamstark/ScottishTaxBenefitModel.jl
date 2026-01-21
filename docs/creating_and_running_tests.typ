#set heading(
  numbering: "1.")
#set text(font:"Palatino Linotype")

#show link: set text(blue)
#show heading: set text(font: "Gill Sans")
#show raw: set text(font:"JuliaMono",size:8pt,navy)

= Creating and Running Scotben tests
<creating-and-running-scotben-tests>
== Intro
<intro>

If you’re writing code, it’s good to add associated tests.

In principle the model is developed
#link("https://en.wikipedia.org/w/index.php?title=Test-driven_development")[test first],
so the tests are written in advance of the actual implementation code,
but in practice that doesn’t always happen. Even if the tests are very
basic, having tests makes it much easier to update the model, since it’s
harder to introduce inadvertent mistakes.

This note covers the specifics of writing tests for Scotben. It assumes that
`ScottishTaxBenefitModel` is the active package. 

See #link("https://docs.julialang.org/en/v1/stdlib/Test/")[The Julia Test package documentation]
for general information about Julia unit tests.

== The Test Suite
<the-test-suite>

The tests are in the `tests` directory. The file `runtests.jl` has
references to the complete set of tests. In principle the tests should
follow the structure of the `src/` directory, with one test file per
module and one individual test per function, but I never really managed
that.

== Running Tests
<running-tests>
=== All Tests
<all-tests>

To run all tests, do this:

```julia
using Pkg
Pkg.activate(".")
Pkg.test()
```

This takes a while. It’s useful because the version of ScotBen that’s
tested is exactly the one that would be used in e.g. the
`MicrosimTraining` package.

=== Individual tests
<individual-tests>

More often you’ll just want to run just the tests for the thing you’ve
changed.

Always include `testutils.jl`, then just the one you want, for instance:

```julia
include( "test/testutils.jl")
include( "test/local_level_calculations_tests.jl")
```

== Creating Tests
<creating-tests>

Most test file more-or-less correspond to a package in `src`. In each
file, tests are grouped into "testsets". For example:

```julia
@testset "Winter Fuel Payments" begin
# individual tests go here ...
end
```

So, if the thing being built is completely new, create a file in `test`
and add an `include` in `runtests.jl`. The file needs to import `Test`
package plus whatver subpackages you need.

=== Material For Tests
<material-for-tests>

Often the existing tests are worked examples of how particular
calculations should go. These come from a variety of sources,
principally:

+ #strong[Income Tax and NI] Mainly from
  #link("https://www.pearson.com/en-gb/subject-catalog/p/taxation-finance-act-2023/P200000011257/9781292729275")[Melville’s Taxation],
  several editions;
+ #strong[Benefits] worked examples from various CPAG guides, but mainly
  from a spreadsheet
  `docs\uc_test_cases.ods" collated from the [Policy In Practice](https://policyinpractice.co.uk/) calculator. See`test/vs\_policy\_in\_practice\_tests.jl\`.
  The spreadsheet is very cryptic and hasn’t been updated since 2021.

=== Household-Level Tests
<household-level-tests>

The `ExampleHelpers.jl` module provides a number of pre-built example
households you can use in tests, and methods to change the examples.

=== Get A Household
<get-a-household>

```julia
# using ExampleHelpers:
hh = get_example( cpl_w_2_children_hh )
# .. or, to get the 200th household in the main dataset
hh = FRSHouseholdGetter.get_household( 200 )
```

==== Available hhlds:
<available-hhlds>

see `src/ExampleHelpers.jl`

```julia

cpl_w_2_children_hh, 
single_parent_hh, 
single_hh, 
childless_couple_hh, 
mbu # multiple benefit unit
```

`ÈxampleHelpers` has multiple functions to change these households e.g.:
```julia
employ!(pers::Person)
``` 
changes the person’s employment status and
assigns default hours and earnings.

=== Example of one test
<example-of-one-test>

This is from code just written to model Winter Fuel Paymemts. Full code
is in `test/non_means_tested_bens_tests.jl`

```julia


@testset "Winter Fuel Payments" begin
    # 1. initialise a parameter system, household (2 ad, 2 ch couple) and default run settings:
    settings = Settings()
    sys = get_default_system_for_fin_year( 2026; scotland=true )
    hh = get_example( cpl_w_2_children_hh )
    # 1.1 allocate a record for the results, given the household
    hres = init_household_result( hh )
    # shortcuts for the head and spouse
    head = get_head(hh)
    bus = get_benefit_units(hh)
    #= 2. test 1: a non pensioner gets nothing
    # create an intermediate record (ages of oldest, num pensioners, etc - this just cuts down the amount of calculations actually needed in the calc routine.
    =#
    intermed = make_intermediate(
        Float64,
        settings,
        hh, 
        sys.hours_limits, 
        sys.age_limits, 
        sys.child_limits )
    # 3. do the sum for 1 household and 1 system
    calc_winter_fuel!( hres.bus[1], bus[1], intermed.buint[1], sys.nmt_bens.winter_fuel )
    # 4. check that there's no WINTER_FUEL being paid:
    @test  hres.bus[1].pers[head.pid].income[WINTER_FUEL_PAYMENTS] ≈ 0.0

    # 3. Test that an 81 yo gets full amount
    # age the head ..
    head.age = 81
    # re-do the intermediate record 
    intermed = make_intermediate(
        Float64,
        settings,
        hh, 
        sys.hours_limits, 
        sys.age_limits, 
        sys.child_limits )
    # reset the results record
    hres = init_household_result( hh )
    bus = get_benefit_units(hh)
    calc_winter_fuel!( hres.bus[1], bus[1], intermed.buint[1], sys.nmt_bens.winter_fuel )
    # Test of 2026 Winter Fuel level for over 80s
    @test  hres.bus[1].pers[head.pid].income[WINTER_FUEL_PAYMENTS] ≈ 305.10/WEEKS_PER_YEAR
    # and so on - see the code 
end
```
