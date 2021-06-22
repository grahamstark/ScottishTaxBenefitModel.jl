### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ 125fdd06-d330-11eb-0cf4-17cfac8cc4f7
begin
	using Plots,DataFrames,CSV,Dates,GLM
	# gr() 
	plotly() 
	# pyplot()
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

# ╔═╡ 923d961b-0912-4d1e-976e-20b89150b563
begin
	cd("/home/graham_s/julia/vw/ScottishTaxBenefitModel/")
	dla=CSV.File("docs/dla_time_series.csv";header=11,datarow=14,limit=67)|>DataFrame
	dla.Date = Date.( dla.Date, dateformat"U yyyy" )
	dla
end

# ╔═╡ fd0658ac-4fef-471a-af49-db01751ef2a9
begin
	p = plot(dla.Date,[dla.Scotland dla.Wales dla.England], ylims = (0, 3_000_000),title="DLA Cases Scotland 2002-2018", labels=["Sco" "Wal" "Eng"], formatter=:plain )
	annotate!(p, dla.Date[50],dla.Scotland[50], "PIP introduced")
	
end

# ╔═╡ Cell order:
# ╠═125fdd06-d330-11eb-0cf4-17cfac8cc4f7
# ╠═923d961b-0912-4d1e-976e-20b89150b563
# ╠═fd0658ac-4fef-471a-af49-db01751ef2a9
