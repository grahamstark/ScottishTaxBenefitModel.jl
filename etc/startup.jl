# see: https://www.juliabloggers.com/activating-project-environment-in-julia-repl-automatically/?utm_source=ReviveOldPost&utm_medium=social&utm_campaign=ReviveOldPost
using Pkg
if isfile("Project.toml") && isfile("Manifest.toml")
    Pkg.activate(".")
end
push!( LOAD_PATH, "src/")


