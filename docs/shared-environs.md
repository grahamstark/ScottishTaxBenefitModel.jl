# SHARED ENVIRONMENTS

* [Inspired By](https://discourse.julialang.org/t/whats-in-your/129530/4)
* [Std Docs](https://pkgdocs.julialang.org/v1/environments/#Shared-environments)
* [ShareAdd.jl](https://github.com/Eben60/ShareAdd.jl) - in startup.jl

My shared environments:

* @Stats
* @MakieGraphs
* @Maths
* @Data

```julia

pkg> activate --shared Maths
(@Maths) pkg> add DifferentialEquations, LinearSolve, Roots

activate --shared Stats
# see: 
(@Stats) pkg> add StatsKit
#=
    Bootstrap
    CategoricalArrays
    Clustering
    CSV
    DataFrames
    Distances
    Distributions
    GLM
    HypothesisTests
    KernelDensity
    Loess
    MultivariateStats
    MixedModels
    StatsBase
    ShiftedArrays
    TimeSeries
=#

activate --shared MakieGraphs
add Makie, CairoMakie, GLMakie, Observables, WGLMakie, Bonito

activate --shared Data
add DataFrames, DataFramesMeta, CSV, IterableTables, PrettyTables, MarkdownTables

```

## Useage

These shared libs go automatically into the loadpath. Then:

```julia 

using ShareAdd
@usingany CairoMakie, GLM, StatsBase 

```


