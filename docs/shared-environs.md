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

using Pkg
Pkg.activate("GMaths", shared=true)
for p in ["DifferentialEquations", "LinearSolve", "Roots"]
    Pkg.add(p)
end

Pkg.activate("GStats", shared=true)
for p in ["StatsKit", "RegressionTables"]
    Pkg.add(p)
end

# see: 
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
Pkg.activate("GMakie", shared=true)
for p in ["Makie", "CairoMakie", "GLMakie", "Observables", "WGLMakie", "Bonito", "AlgebraOfGraphics"]
    Pkg.add(p)
end

Pkg.activate("GData", shared=true )
for p in ["DataFrames", "DataFramesMeta", "CSV", "IterableTables", "PrettyTables", "MarkdownTables"]
    Pkg.add(p)
end

Pkg.activate("GWebIO", shared=true )
for p in ["Genie", "Pluto", "PlutoUI", "IJulia", "Mux", "HTTP", "PlutoExtras", "Observables"]
    Pkg.add(p)
end

Pkg.activate("GTest", shared=true)
for p in ["BenchmarkTools", "Chairmarks", "PrettyChairmarks"]
    Pkg.add(p)
end

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
for env in ["GMakie","GMaths","GData","GWebIO", "GTests"]
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