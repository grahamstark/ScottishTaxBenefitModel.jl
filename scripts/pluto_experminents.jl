### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# ╔═╡ 6e40cb6c-b416-11ed-0c75-a589c6e8a2d4
begin
	using Pkg
	Pkg.activate(Base.current_project())
	Pkg.instantiate()
	using ScottishTaxBenefitModel
	using CSV,DataFrames
end

# ╔═╡ 21764c30-ff2c-40d0-a708-9a5f908ea1c9
begin
	rates = [19,20,21,40,41]
	bands = [3000,19000,]
end

# ╔═╡ 2f85bbe6-2f5b-4b10-abf5-7af0388c8059
begin
	
end

# ╔═╡ Cell order:
# ╠═6e40cb6c-b416-11ed-0c75-a589c6e8a2d4
# ╠═21764c30-ff2c-40d0-a708-9a5f908ea1c9
# ╠═2f85bbe6-2f5b-4b10-abf5-7af0388c8059
