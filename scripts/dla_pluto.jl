### A Pluto.jl notebook ###
# v0.14.8

using Markdown
using InteractiveUtils

# ╔═╡ 125fdd06-d330-11eb-0cf4-17cfac8cc4f7
begin
	using Plots,DataFrames,CSV,Dates,GLM
	# gr() 
	# plotly() 
	pyplot()
	# pgfplotsx()
	default(fontfamily="Gill Sans", 
		titlefont = (12,:grey), 
		legendfont = (11), 
		guidefont = (10), 
		tickfont = (9), 
		annotationfontsize=(8),
		annotationcolor=:blue
		
	  )
end

# ╔═╡ a1341efb-8d58-4b9a-8071-6f3e665273ec
md"# PIP and DLA receipts
source: [Stat-Xplore](https://stat-xplore.dwp.gov.uk/); 
retrieved 02/July/2021
 "

# ╔═╡ 6ee3c8bd-5dca-4c7d-9e41-be59c2ba2b7e
md"## DLA "

# ╔═╡ 923d961b-0912-4d1e-976e-20b89150b563
begin
	cd("/home/graham_s/julia/vw/ScottishTaxBenefitModel/")
	dla=CSV.File("docs/dla_2002-2020_from_stat_explore.csv")|>DataFrame
	dla.Date = Date.( dla.Date, dateformat"u-yy" ) .+Year(2000)
	dla
end

# ╔═╡ fd0658ac-4fef-471a-af49-db01751ef2a9
begin
	p = plot(dla.Date,[dla.Scotland dla.Wales dla.England], ylims = (0, 3_000_000), labels=["DLA-Sco" "DLA-Wal" "DLA-Eng"], formatter=:plain )
	
	
end

# ╔═╡ 1686c58b-ebb0-4502-8021-7842e369eef8
md"## Personal Independence Payment"

# ╔═╡ a01723f5-e22a-4d36-9afa-6675d591bfeb
begin
	pip=CSV.File( "docs/pip-by-country-and-month-transposed.tab",missingstrings=[".."],types=Dict([:Date=>String]))|>DataFrame
	pip.Date = Date.( pip.Date, dateformat"yyyymm" )
	pip
end

# ╔═╡ 8dabffad-137c-4c91-8406-96127b960898
begin
	pipp = plot!(p,pip.Date,[pip.Scotland,pip.Wales,pip.England],title="DLA/PIP Cases UK 2002-2020",labels=["PIP-Sco" "PIP-Wal" "PIP-Eng"])
	# svg( pipp, "docs/pip-dla.svg" )
	savefig(pipp, "docs/pip-dla-uk.svg" )
	pipp
end

# ╔═╡ c9c0cb68-9bd6-4044-a92b-e83532dce766
begin
	psco = plot(dla.Date,dla.Scotland, labels="DLA", formatter=:plain )
	pscop = plot!( psco, pip.Date, pip.Scotland, title="PIP/DLA Scotland", labels="PIP" )
	savefig(pscop, "docs/pip-dla-scotland.svg" )
	pscop
end


# ╔═╡ Cell order:
# ╠═125fdd06-d330-11eb-0cf4-17cfac8cc4f7
# ╟─a1341efb-8d58-4b9a-8071-6f3e665273ec
# ╠═6ee3c8bd-5dca-4c7d-9e41-be59c2ba2b7e
# ╠═923d961b-0912-4d1e-976e-20b89150b563
# ╠═fd0658ac-4fef-471a-af49-db01751ef2a9
# ╠═1686c58b-ebb0-4502-8021-7842e369eef8
# ╠═a01723f5-e22a-4d36-9afa-6675d591bfeb
# ╠═8dabffad-137c-4c91-8406-96127b960898
# ╠═c9c0cb68-9bd6-4044-a92b-e83532dce766
