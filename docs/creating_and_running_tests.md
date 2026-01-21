# Creating and Running Scotben tests

[The Julia Test package](https://docs.julialang.org/en/v1/stdlib/Test/).

Adding a test. This is for the 

Running all tests:

```julia

using Pkg
Pkg.activate(".")
Pkg.test()

```

## individual tests

Always include `testutils.jl`, then just the one you want:

```julia
include( "test/testutils.jl")
include( "test/local_level_calculations_tests.jl")
```

## Get A Household 

```julia 

hh = get_example( cpl_w_2_children_hh )

# or ...

hh = FRSHouseholdGetter.get_household( 200 )
# to get the 200th household in the main dataset

```

## Available hhlds: 

see `src/ExampleHelpers.jl`

```julia

cpl_w_2_children_hh, 
single_parent_hh, 
single_hh, 
childless_couple_hh, 
mbu # multiple benefit unit

```

`ÈxampleHelpers` has multiple functions to change these households e.g. `employ!(pers::Person)`  