### A Pluto.jl notebook ###
# v0.19.13

using Markdown
using InteractiveUtils

# ╔═╡ fb3893ac-078e-4bd7-8620-abccea0e4e1f
begin
	using Pkg
	# Pkg.activate( "/home/graham_s/julia/vw/ScottishTaxBenefitModel")
	Pkg.add( url="https://github.com/grahamstark/ScottishTaxBenefitModel.jl" )
end

# ╔═╡ f74fdcb3-7048-4880-84f8-3a56adb7383a
begin
	Pkg.add( "LoggingExtras" )
end

# ╔═╡ bc8bbc02-a52a-4f2a-a664-9da3ce347449
begin
	cd( "/home/graham_s/julia/vw/ScottishTaxBenefitModel/" )
	include( "/home/graham_s/julia/vw/ScottishTaxBenefitModel/scripts/retriever.jl" )
end

# ╔═╡ 47056539-b2aa-44b2-ac98-9891eb91f859
begin
	#  = HTTP.request("GET", "http://localhost:8002/hhld/1")
	# s = String(r.body)
end

# ╔═╡ 69703abf-79fe-4536-a7d6-b7e409d1ece3
# md"XX$s"

# ╔═╡ 65a2c627-457c-4815-960d-1bf9a57ad6cf
begin
	
	# init_data()

	hno = 8
	bits = [:househol,:adult ]
	s = get_data( hno, bits )
	typeof(s)
	Markdown.parse( s )
end

# ╔═╡ Cell order:
# ╠═f74fdcb3-7048-4880-84f8-3a56adb7383a
# ╠═fb3893ac-078e-4bd7-8620-abccea0e4e1f
# ╠═47056539-b2aa-44b2-ac98-9891eb91f859
# ╠═69703abf-79fe-4536-a7d6-b7e409d1ece3
# ╠═bc8bbc02-a52a-4f2a-a664-9da3ce347449
# ╠═65a2c627-457c-4815-960d-1bf9a57ad6cf
