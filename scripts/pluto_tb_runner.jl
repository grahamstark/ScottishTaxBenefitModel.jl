### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 86c233b6-0ac2-4869-a423-0336c837b73b
begin
	using Pkg
	Pkg.activate( "~/julia/vw/ScottishTaxBenefitModel" )
	Pkg.add( "BenchmarkTools" )
end

# ╔═╡ 4f30d000-ea1e-11eb-1a93-9be9c3779dc5
begin
	using Test
	using CSV
	using DataFrames
	using StatsBase
	using BenchmarkTools

	using ScottishTaxBenefitModel
	using ScottishTaxBenefitModel.GeneralTaxComponents
	using ScottishTaxBenefitModel.STBParameters
	using ScottishTaxBenefitModel.Runner: 
		do_one_run!
	using .RunSettings: Settings

	using .Utils
	include("../test/testutils.jl")
end

# ╔═╡ 1d044997-c2bb-4c7a-b372-474160b27fd5
begin
		
	settings = Settings()

	BenchmarkTools.DEFAULT_PARAMETERS.seconds = 120
	BenchmarkTools.DEFAULT_PARAMETERS.samples = 2


	function basic_run()::NamedTuple

		sys = [get_system(scotland=false), get_system( scotland=true )]
		results = do_one_run!( settings, sys )
		return results
	end 

end

# ╔═╡ 629ef4aa-0c3f-46bd-a7ea-4a06af43937c


# ╔═╡ 8eeec2d4-0b33-4883-aab1-79fb4051a196
begin
	res = basic_run()
	res.hh[1]
end

# ╔═╡ a06a02e6-3c01-4dd4-966f-0564cede93ff


# ╔═╡ Cell order:
# ╠═86c233b6-0ac2-4869-a423-0336c837b73b
# ╠═4f30d000-ea1e-11eb-1a93-9be9c3779dc5
# ╠═1d044997-c2bb-4c7a-b372-474160b27fd5
# ╠═629ef4aa-0c3f-46bd-a7ea-4a06af43937c
# ╠═8eeec2d4-0b33-4883-aab1-79fb4051a196
# ╠═a06a02e6-3c01-4dd4-966f-0564cede93ff
