using ScottishTaxBenefitModel
using Documenter

makedocs(;
    modules=[ScottishTaxBenefitModel],
    authors="Graham Stark",
    repo="https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/{commit}{path}#L{line}",
    sitename="ScottishTaxBenefitModel.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://grahamstark.github.io/ScottishTaxBenefitModel.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/grahamstark/ScottishTaxBenefitModel.jl",
)
