# SHARED ENVIRONMENTS

* [Inspired By](https://discourse.julialang.org/t/whats-in-your/129530/4)
* [Std Docs](https://pkgdocs.julialang.org/v1/environments/#Shared-environments)
* [ShareAdd.jl](https://github.com/Eben60/ShareAdd.jl) - in startup.jl

My shared environments:

* @GStats
* @GMakieGraphs
* @GMaths
* @GData
* @GWebIO

```julia

activate --shared GMaths
add DifferentialEquations, LinearSolve, Roots

activate --shared GStats
# see: 
add StatsKit, RegressionTables
#= ... which adds:
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
activate --shared GMakie
add Makie, CairoMakie, GLMakie, Observables, WGLMakie, Bonito

activate --shared GData
add DataFrames, DataFramesMeta, CSV, IterableTables, PrettyTables, MarkdownTables

activate --shared GWebIO
add Genie, Pluto, PlutoUI, IJulia, Mux, HTTP, PlutoExtras

```

## Useage

These shared libs go automatically into the loadpath. Then:

```julia 

using ShareAdd
@usingany CairoMakie, GLM, StatsBase 

```

## updating

```julia

using Pkg
for env in ["GMakieGraphs","GMaths","GData","GWebIO"]
    Pkg.activate(env, shared=true)
    Pkg.update()
end

```

## sample startup.jl

```julia
if isinteractive()     
    using Revise
    using OhMyREPL
    using TruncatedStacktraces
# using BenchmarkTools
    TruncatedStacktraces.VERBOSE_MSG=""
    using ShareAdd
    using TerminalPager
end
``` 

~    