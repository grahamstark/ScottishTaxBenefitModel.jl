#
# various performance experiments with typing and constants
#
    
using BenchmarkTools
using InteractiveUtils
using Revise

#
# A). Speed tests of global variables
# conclusion:
#  1. anything other than a global untyped variable is roughly equivalent
#  2. ... but we'll neeed to be v careful with specifying types exactly though parameters (see: B)
include( "performance/globals.jl" )

#
# B) types of structures
# conclusion: 
#  1. we need explicit vectors, not abstract containers
#  2. .. and explicit element types
#  3. specialised functions make no difference
include( "performance/structs.jl" )

#
# C) type stability
#
# this is from https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-changing-the-type-of-a-variable
#
# conclusion: 
#  1. add concrete types to local variables
#  2. or initialise to something explicit
#  3. abstract types can work as well in some cases (abstract float)
#  4. adding return type doesn't seem to matter for performance purposes
#
include( "performance/stability.jl" )



