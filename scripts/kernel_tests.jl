### A Pluto.jl notebook ###
# v0.14.8

using Markdown
using InteractiveUtils

# ╔═╡ e8433caa-1882-4153-bb6b-881b64eda8c5
using StatsPlots,DataFrames,CSV,KernelDensity

# ╔═╡ a524bb50-d918-11eb-18ba-ff416e617daf
md"# Kernel Tests"

# ╔═╡ 2be06875-e8dc-4ac6-bb21-4b094c453fbb
lcf=CSV.File( "/home/graham_s/OU/DD309/2020J/econometrics/data/lcf/lcf_017_18.tab",delim='\t')|>DataFrame


# ╔═╡ 8f3b8c66-9089-467b-a879-f1a8717036aa
atk = KernelDensity.kde((lcf.total_expend, lcf.alcohol_tobacco)) # note this has to be a tuple, for some reason

# ╔═╡ e37800e2-0db4-4e09-8f91-8680e62407fc
StatsPlots.plot(atk)

# ╔═╡ 69ec345f-b97a-40af-97b5-a37600b1d7b2
p1 = @df lcf marginalscatter(:total_expend,:food_and_drink,xlabel="expenditure", ylabel="food and drink")

# ╔═╡ 732de09c-a4e3-47f2-aa81-1152e05b8bec
marginalkde(lcf.total_expend,lcf.food_and_drink,xlabel="expenditure", ylabel="food and drink")

# ╔═╡ Cell order:
# ╠═a524bb50-d918-11eb-18ba-ff416e617daf
# ╠═e8433caa-1882-4153-bb6b-881b64eda8c5
# ╠═2be06875-e8dc-4ac6-bb21-4b094c453fbb
# ╠═8f3b8c66-9089-467b-a879-f1a8717036aa
# ╠═e37800e2-0db4-4e09-8f91-8680e62407fc
# ╠═69ec345f-b97a-40af-97b5-a37600b1d7b2
# ╠═732de09c-a4e3-47f2-aa81-1152e05b8bec
