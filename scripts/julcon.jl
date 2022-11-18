### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 82cff020-f7c5-11ec-058b-adcf730aecd1

begin
	#
	# Load scotben
	#
	using Pkg
	# Pkg.develop( url="https://github.com/grahamstark/ScottishTaxBenefitModel.jl")
	Pkg.develop( path="/home/graham_s/julia/vw/ScottishTaxBenefitModel")
	Pkg.add( "Plots")
	Pkg.add( "Observers" )
	Pkg.add( "Observables" )
	Pkg.add( "PrettyTables")
	Pkg.add( "DataFrames" )
	Pkg.add( "PlutoUI" )
	Pkg.add( "Colors" )
	Pkg.add( "ColorVectorSpace" )
	Pkg.add( "ImageShow" )
	Pkg.add( "FileIO" )
	Pkg.add( "ImageIO" )
	Pkg.add( "BudgetConstraints" )
	Pkg.add( "SurveyDataWeighting" )
	Pkg.add( "PovertyAndInequalityMeasures" )
	Pkg.add( "CSV" )
	# Pkg.update()
end

# ╔═╡ 38953460-94b3-4a57-aee9-40dbc67b6b68
begin
    #
	# The Model 
	#	
	using ScottishTaxBenefitModel
	import .ExampleHouseholdGetter
	using .STBParameters
	using .BCCalcs
	using .ModelHousehold
	using ScottishTaxBenefitModel.Runner: do_one_run
	import .FRSHouseholdGetter
	using .Utils
	using .Definitions
	using .Monitor
	using .SingleHouseholdCalculations
	using .RunSettings

	using Observers
	using Observables
	using Plots
	using PlutoUI
	using CSV
	using DataFrames
	using PrettyTables
	#
	# Image stuff
	#
	using Colors, ColorVectorSpace, ImageShow, FileIO, ImageIO
	#
	# My stuff
	#
	using BudgetConstraints
	using SurveyDataWeighting
	using PovertyAndInequalityMeasures 
end

# ╔═╡ 47e47829-f21a-4473-b9f8-0f3f76fecaa8
begin
	PlutoUI.TableOfContents(aside=true)
end

# ╔═╡ ecc7a9ef-1d4a-47b6-b3aa-bf09755465bf
p = STBParameters.TaxBenefitSystem{Float64}()

# ╔═╡ c75e6664-dd0b-49e3-b085-7064314696c3
md"""

# ScotBen 
### A Microsimulation Tax Benefit Model for Scotland

Graham Stark [gks56@open.ac.uk](gks56@open.ac.uk)/[graham.stark@virtual-worlds.biz](graham.stark@virtual-worlds.biz)

[https://github.com/grahamstark/ScottishTaxBenefitModel.jl](https://github.com/grahamstark/ScottishTaxBenefitModel.jl)"
"""

# ╔═╡ 51a1df57-1d49-4267-af4a-b8569273bd3d
md"## What's a tax benefit model for? 
### Some examples"

# ╔═╡ 6d54f8cc-025a-4693-8069-ee2e35048e77
begin
	cpay = load( "/home/graham_s/julia/vw/Visualisations/web/images/juliacon/bbc_scottish_child_payment.png" )
end

# ╔═╡ 4ddafeec-da63-43ad-95c7-25e0440d6b71
begin
	ni_inc = load( "/home/graham_s/julia/vw/Visualisations/web/images/juliacon/herald-national-insurance.png" )
end

# ╔═╡ f7910a29-dab8-45c4-9736-64121cb9e669
begin
	rsa_basic = load( "/home/graham_s/julia/vw/Visualisations/web/images/juliacon/bbc-basic-income-rsa.png" )
end

# ╔═╡ 64dd95db-ca5a-4940-8823-6ed0d58c87e9
md"""## What We'd Want to know about these changes
* how much does it cost or how much would it raise?
* who does it affect most? Are the most affected expecially vulnerable, or politically sensitive?
* what would the change do to the efficiency of the economy? Would people be more or less likely to work or take risks?
* does the change make society more or less equal? Does it worsen poverty? (a slightly different concept).
"""


# ╔═╡ 3fc65fbd-16e2-4091-a78c-f2d1389f1716
md"## What's needed?
### Encode the fiscal system - it's *huge*
"

# ╔═╡ b8ebf72d-3b12-485b-9f28-847cfa6f61b3


# ╔═╡ 1f956c4f-f2a6-4766-b40c-66c1f51720c7
begin
	load( "/home/graham_s/julia/vw/Visualisations/web/images/tolleys_guides.jpeg")
end

# ╔═╡ 552c9aa8-30b9-4b3b-aa56-bb0ebf218711
begin
	cpag = load( "/home/graham_s/julia/vw/Visualisations/web/images/cpag_guide.jpg" )
end

# ╔═╡ 4dbfb9a0-6539-4627-b286-a53e895bfeae
md"""
## Data

* uses pooled (2015-2018) Scottish Households from [Family Resources Survey](https://www.gov.uk/government/collections/family-resources-survey--2) from the [UK Data Service](https://ukdataservice.ac.uk/);
* Data from the [Scottish Household Survey](https://www.gov.scot/collections/scottish-household-survey/) is [matched in](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/tree/master/matching). This allows much more accurate modelling of local taxes and (in the future) health, housing conditions;
* Since we have a [Calmar-like weighting system built-in](https://github.com/grahamstark/SurveyDataWeighting.jl), we can [weight to Scottish Population, Employment Levels, and so on](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/Weighting.jl) very accurately and easily.
"""


# ╔═╡ de91355d-9b75-46e7-8906-1cfaa8c8a183
begin	
	settings = Settings()
	hhs = CSV.File( "$(settings.data_dir)/model_households_scotland.tab" )|>DataFrame
	people = CSV.File( "$(settings.data_dir)/model_people_scotland.tab" )|>DataFrame
end

# ╔═╡ 402c1e02-3278-4678-b52f-295dfca4d99b
md"""
## The Model Structure

[The Model is a package, though not yet in the general registry](https://github.com/grahamstark/ScottishTaxBenefitModel.jl). Internally, it's broken down into a collection of semi-independent modules, for example: 

* [a household](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/ModelHousehold.jl);
* [the fiscal system parameters](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/STBParameters.jl);
* [means-tested benefits](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/LegacyMeansTestedBenefits.jl);
* [income tax](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/IncomeTaxCalculations.jl)

.. [and so on](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/tree/master/src)

Some of the modules (e.g. [Equivalence Scales](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/EquivalenceScales.jl)) may eventually be moved out into generic packages.

"""

# ╔═╡ 328d1d02-0808-46d2-9304-ca8bdcad989a
md"""## Generic Support packages:


As well as the model itself, I've written some generic packages that help with this kind of modelling. All of these are in the general registry:

* [Budget Constraints](https://github.com/grahamstark/BudgetConstraints.jl);
* [Data Weighting](https://github.com/grahamstark/SurveyDataWeighting.jl) - like R's Survey Package;
* [Poverty & Inequality](https://github.com/grahamstark/PovertyAndInequalityMeasures.jl).
"""


# ╔═╡ 96c9f9f3-7ace-4ffa-8991-0319b6751923
md"## Examples

* [Let's answer the Child Payment Question](https://stb.virtual-worlds.scot/scotbudg/)
* [Is it worth working? Or, Scotland's Kinkiest Families](https://stb.virtual-worlds.scot/bcd/)
* [Basic Income](https://ubi.virtual-worlds.scot)

(First two use [Dash](https://dash.plotly.com/julia/introduction), UB uses [HTTP.jl](https://github.com/JuliaWeb/HTTP.jl) and [MUX](https://github.com/JuliaWeb/Mux.jl) )
"

# ╔═╡ 58a31622-6766-4e3f-aed4-1e81c2f51558
md"""
## Experiences with Julia

* compared to what I was used to, data handling is fantastic;
* it really does solve the two language problem (unless you need a very obscure estimator);
* it's really fast, even compared to my previous wholly compiled code.

"""

# ╔═╡ fa573faa-ca78-436c-b6d2-21d2c59f3316
md"""
## Things to do

The top 4 are probably:

* fresh eyes on the code - no-one can get something this intricate right by himself;
* needed code: an analog of R's [StatMatch](https://cran.r-project.org/web/packages/StatMatch/index.html) would be very nice;
* a synthetic dataset - create a dataset that had the same properties as the live one, but not real people, so it can be distributed as part of the package;
* an API do it's easier to construct interfaces.
"""

# ╔═╡ Cell order:
# ╟─82cff020-f7c5-11ec-058b-adcf730aecd1
# ╠═38953460-94b3-4a57-aee9-40dbc67b6b68
# ╠═47e47829-f21a-4473-b9f8-0f3f76fecaa8
# ╠═ecc7a9ef-1d4a-47b6-b3aa-bf09755465bf
# ╟─c75e6664-dd0b-49e3-b085-7064314696c3
# ╟─51a1df57-1d49-4267-af4a-b8569273bd3d
# ╟─6d54f8cc-025a-4693-8069-ee2e35048e77
# ╟─4ddafeec-da63-43ad-95c7-25e0440d6b71
# ╟─f7910a29-dab8-45c4-9736-64121cb9e669
# ╟─64dd95db-ca5a-4940-8823-6ed0d58c87e9
# ╟─3fc65fbd-16e2-4091-a78c-f2d1389f1716
# ╟─b8ebf72d-3b12-485b-9f28-847cfa6f61b3
# ╟─1f956c4f-f2a6-4766-b40c-66c1f51720c7
# ╟─552c9aa8-30b9-4b3b-aa56-bb0ebf218711
# ╟─4dbfb9a0-6539-4627-b286-a53e895bfeae
# ╟─de91355d-9b75-46e7-8906-1cfaa8c8a183
# ╟─402c1e02-3278-4678-b52f-295dfca4d99b
# ╟─328d1d02-0808-46d2-9304-ca8bdcad989a
# ╟─96c9f9f3-7ace-4ffa-8991-0319b6751923
# ╟─58a31622-6766-4e3f-aed4-1e81c2f51558
# ╟─fa573faa-ca78-436c-b6d2-21d2c59f3316
