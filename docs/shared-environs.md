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

function make_shared_package( name :: String, packages :: Vector{String})
    Pkg.activate( name, shared=true)
    for p in packages
        Pkg.add(p)
    end
end




make_shared_package( "GMaths", ["DifferentialEquations", "LinearSolve", "Roots"])
make_shared_package( "GStats", [ # just loading StatsKit doesn't appear to work here..
    "StatsBase", 
    "Bootstrap",
    "CategoricalArrays",
    "Clustering",
    "CSV",
    "DataFrames",
    "Distances",
    "Distributions",
    "GLM",
    "HypothesisTests",
    "KernelDensity",
    "Loess",
    "MultivariateStats",
    "MixedModels",
    "StatsBase",
    "ShiftedArrays",
    "TimeSeries",
    "RegressionTables",
    "FixedEffectModels"])
make_shared_package( "GEecon", ["Agents" ])
make_shared_package( "GMakie", ["Makie", "CairoMakie", "GLMakie", "Observables", "WGLMakie", "Bonito"])  
make_shared_package( "GData", ["Format", "DataFrames", "DataFramesMeta", "CSV", "IterableTables", "PrettyTables", "MarkdownTables", "Format", "FileIO"])
make_shared_package( "GWebIO", ["Genie", "Pluto", "PlutoUI", "IJulia", "Mux", "HTTP", "PlutoExtras", "Observables", "PlutoSliderServer"])
make_shared_package( "GTest", ["BenchmarkTools", "Chairmarks", "PrettyChairmarks"])

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
for env in ["GMakie","GMaths","GData","GWebIO", "GTests", "GEcon"]
    Pkg.activate(env, shared=true)
    Pkg.update()
end
Pkg.activate(".")

## Adding 

Example - add `FileIO` to `GData`.

```julia

using Pkg
Pkg.activate("GData", shared=true)
Pkg.add("FileIO")
Pkg.add("DrWatson")
Pkg.activate("GStats", shared=true)
Pkg.add("StatsBase")
Pkg.activate(".")

```

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
