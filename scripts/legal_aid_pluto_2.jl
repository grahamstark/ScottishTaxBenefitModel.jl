### A Pluto.jl notebook ###
# v0.19.40

using Markdown
using InteractiveUtils

# ╔═╡ 389df7e4-dcbc-11ee-121e-41c9d691391b
# ╠═╡ show_logs = false
begin
	using Pkg
	# Pkg.activate( Base.current_project())
	Pkg.add( url="https://github.com/grahamstark/ScottishTaxBenefitModel.jl/")
	Pkg.add( "Observables" )
	Pkg.add( "DataFrames")
	Pkg.add( "StatsBase" )
	Pkg.add( "CairoMakie" )
	Pkg.add( "Format")
	Pkg.add( "PlutoUI")
	using DataFrames
	using StatsBase
	using Observables
	using CairoMakie
	using Format
	using PlutoUI
	
	using ScottishTaxBenefitModel
	using .FRSHouseholdGetter
	using .GeneralTaxComponents: WEEKS_PER_YEAR
	using .Monitor: Progress
	using .RunSettings
	using .STBParameters: TaxBenefitSystem, get_default_system_for_fin_year
	using .Utils
	
	using .LegalAidCalculations: calc_legal_aid!
	using .LegalAidData
	using .LegalAidOutput
	using .LegalAidRunner
end

# ╔═╡ cf733630-889c-4fbb-b0ac-eacaeb9002d0
# ╠═╡ show_logs = false
begin
	#
	# Set things up
	#
	settings = Settings()
	settings.export_full_results = true
    settings.do_legal_aid = true
    settings.requested_threads = 6
	settings.num_households, settings.num_people = FRSHouseholdGetter.initialise( settings; reset=true )
	sys1 = STBParameters.get_default_system_for_fin_year( 2023, scotland=true )    
	sys2 = STBParameters.get_default_system_for_fin_year( 2023, scotland=true )
	systems = [sys1, sys2]
	# Observer as a global.
	tot = 0
	# observer = Observer(Progress("",0,0,0))
	obs = Observable( Monitor.Progress( settings.uuid,"",0,0,0,0))
	of = on(obs) do p
	    global tot
	    println(p)
	    tot += p.step
	    # println(tot)
	end

	
	function crosstab_to_df( ct :: Matrix ) :: DataFrame
	    Utils.matrix_to_frame( ct, 
			LegalAidOutput.ENTITLEMENT_STRS, 
			LegalAidOutput.ENTITLEMENT_STRS  )
	end

end

# ╔═╡ e490b3ab-3887-4e06-9e09-dc691534a886
# ╠═╡ show_logs = false
begin
	
		
    	
		
	

end

# ╔═╡ 9652fcf5-60fb-40d9-8f1c-d90f70dd015a


# ╔═╡ 5744c924-5eb4-4369-a85f-833fb2b9bb92
begin 
	pa = 2529
	# allout = run( pa )
	sys2.legalaid.civil.income_partners_allowance = pa/52
	allout = LegalAidRunner.do_one_run( settings, [sys1,sys2], obs )
	crosstab_to_df(allout.civil.crosstab_pers[1]["no_problem-prediction"])
	# allout.civil.crosstab_pers[1]["no_problem-prediction"]
end

# ╔═╡ 36bc4ecd-00ee-4f88-8bf0-5e15b87cb89c
begin

	table = """<table>
		<tr>
			<th></th><th>None</th><th>W/Contribution</th><th>Full</th><th>Passported</th>
		</tr>
		<tr>
			<th>None</th><td style='background:lightgrey'>NC</td>
			<td style='background:#cceebb'>100</td><td style='background:#cceebb;text-align:right'>0</td>
			<td style='background:#cceebb'>100</td><td style='background:#cceebb;text-align:right'>0</td>

		</tr>
		<tr>
			<th>W/Contribution</th>
			<td style='background:#eeccbb;text-align:right'>NC</td>
			<td style='background:lightgrey'>100</td><td style='background:#cceebb;text-align:right'>0</td>
				<td style='background:#cceebb'>100</td><td style='background:#cceebb;text-align:right'>0</td>

		</tr>
		</table>
	"""
	# <p style='background:#ccffcc'>I can be <b>rendered</b> as <em>HTML</em>!</p>"
	Show(MIME"text/html"(), table)

end

# ╔═╡ Cell order:
# ╟─389df7e4-dcbc-11ee-121e-41c9d691391b
# ╠═cf733630-889c-4fbb-b0ac-eacaeb9002d0
# ╠═e490b3ab-3887-4e06-9e09-dc691534a886
# ╠═9652fcf5-60fb-40d9-8f1c-d90f70dd015a
# ╠═5744c924-5eb4-4369-a85f-833fb2b9bb92
# ╠═36bc4ecd-00ee-4f88-8bf0-5e15b87cb89c
