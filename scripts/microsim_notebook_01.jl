### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# ╔═╡ d02ecf8a-fdd0-11ea-0bec-b561da2f2a02
using DataFrames,CSV,Test,PovertyAndInequalityMeasures,Plots,Test,StatsBase

# ╔═╡ 97c87a0a-fde0-11ea-1419-2f9939bfa6e0
md"""

# Building A MicroSimulation Tax-Benefit Model of Scotland (in 25 minutes)

### Graham Stark 
[graham.stark@virtual-worlds-research.com](mailto:graham.stark@virtual-worlds-research.com)

Things we need:

* data - Family Resources Survey(FRS)/LFS/Living Costs and Food Survey(LCF)/Understanding Society... This example uses FRS
* A programming language:
   - Spreadsheets, R, Fortran, Python ..
   - We use [Julia](https://julialang.org)
* Structures: we need to model:
   - people, families and households;
   - the fiscal system (taxes, benefits);
   - outcomes: incomes net of taxes and benefits, revenues raised, inequalities, poverty and so on.

Let's build one from scratch, in real time (with some 'here's some I prepared earlier' where needs be).

"""

# ╔═╡ d1e09cc6-fde1-11ea-07c7-0fce2411a060
md"""
## A quick intro to julia.

This web page is created automatically by Julia.

"""

# ╔═╡ 00f12bde-fde2-11ea-1026-c11c72cea702
2+2

# ╔═╡ 0651656c-fde2-11ea-251f-5747f4746430
x = 24

# ╔═╡ 0a7f7e3a-fde2-11ea-3825-37b7be64f5e2
x

# ╔═╡ 0c3b3004-fde2-11ea-0567-4bd9576443af
function f(x)
	x*x-1
end

# ╔═╡ 2b19845e-fde2-11ea-2353-7ddeb1182fc9
f(10)

# ╔═╡ 53b4ca1c-fde2-11ea-2955-f3c19026972b
struct Dog
	age
	sex
	barks
end

# ╔═╡ 708ab7c8-fde2-11ea-32ac-b56e9df87ebe
hope = Dog(4,"Female",true)

# ╔═╡ 83d83a9c-fde2-11ea-3512-9f140251a4e9
hope.barks

# ╔═╡ 940fd034-fde2-11ea-1fe2-97533b9dc40f
hope.age == 4

# ╔═╡ d871fa52-fde2-11ea-1e58-a9ddbea34508
md"""
## Data

this is the 'here's one I prepared earlier' bit... This is a large extract from the Family Resources Survey (pooled 2015-2018 surveys, Scotland only households).

Julia provides a structure called a [DataFrame](https://juliadata.github.io/DataFrames.jl/stable/) to hold large datasets like this. 

"""

# ╔═╡ e8d7b7a4-fdd0-11ea-3e4e-d3cfcd789742
sp=CSV.File( "/home/graham_s/julia/vw/ScottishTaxBenefitModel/data/model_people_scotland.tab")|>DataFrame

# ╔═╡ 28ce666e-fdd1-11ea-2ae6-395356fc23e5
begin
    sp[((sp.age.>60).&(sp.sex.==1).&(sp.income_self_employment_income.>0)),[:age,:usual_hours_worked,:income_wages,:income_self_employment_income]]
	# sp = tsp[tsp.from_child_record.!=1,:]
end

# ╔═╡ d9eb5ebc-fdd2-11ea-28ab-2fa7c0cfaba9
names(sp)

# ╔═╡ 4f4ef062-fde3-11ea-1a36-1964d61271ca
md"""
## Structures

As I mentioned, we need structures for households, people,the tax and benefit system, and the results of our calculations. A good model is mostly structures and tests - get those right and the actual calculations are usually easy.

We'll skip most things for now; just:
* people (just age and income)
* simple Income Tax
* a results structure.

	
"""

# ╔═╡ 5ce6e028-fdd3-11ea-2924-897de20ca1c2
begin
	struct Person
		age  :: Int
		wage :: Real
	end
	
	struct TaxSystem
		rates :: Vector
		bands :: Vector
		allow :: Real
	end
	
	struct Result
		taxes :: Real
		net_income :: Real
	end
	
end


# ╔═╡ ba302158-fde3-11ea-2bae-939a6cab3511
md"""

### Initialise some tax systems

The current Scottish one and a flat-rate one.

"""

# ╔═╡ e118d6a8-fdd3-11ea-2d61-ad17c31e0d1a
begin
	sys1=TaxSystem(
		[0.190,0.20,0.21,0.41,0.46], # rates
		[2_049.0, 12_444.0, 30_930.0, 150_000.0], # thresholds
		12_500.00) # allowance
	# flat - no allowance, 1 rate
	sys2=TaxSystem([0.1475],[],0)
end

# ╔═╡ eff4a08e-fde3-11ea-2e58-9b4e4969819e


# ╔═╡ 055e7cc4-fde4-11ea-145b-c5261a647e10
md"""

### A very simple tax system

"""

# ╔═╡ e89d49e0-fdd3-11ea-199c-2d4bf8a5563b
begin
	
	"""
Tax due on `taxable` income, given rates and thresholds
rates can be one more than thresholds, in which case the last band is assumed infinite.
Rates should be (e.g.) 0.12 for 12%.
"""
function calctaxdue(
   taxable    :: Number,
   rates      :: Vector,
   thresholds :: Vector ) :: Real
   nthresholds = length(thresholds)[1]
   nrates = length(rates)[1]

   @assert (nrates >= 1) && ((nrates - nthresholds) in 0:1 ) # allow thresholds to be 1 less & just fill in the top if we need it
   due = 0.0
   remaining = taxable
   i = 0
   if nthresholds > 0
      maxv = typemax( typeof( thresholds[1] ))
      gap = thresholds[1]
   else
      maxv = typemax( typeof( taxable ))
      gap = maxv
   end
   while remaining > 0.0
      i += 1
      if i > 1
         if i < nrates
            gap = thresholds[i]-thresholds[i-1]
         else
            gap = maxv
         end
      end
      t = min( remaining, gap )
      due += t*rates[i]
      remaining -= gap
   end
   due
end
	
	function dotax( pers::Person, sys :: TaxSystem )::Result
		taxable = max(0.0, pers.wage-sys.allow)
		tax = calctaxdue( taxable, sys.rates, sys.bands )
		net = pers.wage - tax
		return Result(tax,net)
	end
end

# ╔═╡ 44f853e2-fdd4-11ea-1a13-d5740807f2d0
begin	
	pers = Person(40,20_000.0)
	res = dotax(pers,sys1)
end

# ╔═╡ 6a698960-fdd5-11ea-3b8d-81aaf65a4d22
tt = (20_000-12500)*0.19

# ╔═╡ a5f30538-fde9-11ea-39c1-1f7f412d2c04
md"""
### Sample Weights

`target population/people (rows)` in the dataset.

"""

# ╔═╡ 7c9954a6-fdd5-11ea-32cc-819552e44bd2
begin
 	ss = size(sp)[1] # count of rows
	popn = 5_500_000 # approx popn of Scotland
	w = popn/ss
end

# ╔═╡ b265ebfa-fdd5-11ea-10fd-2f02021f86a0

function do_all(data::DataFrame, sys :: TaxSystem)::Matrix
	tot_tax = 0.0
	ss = size(data)[1]
	popn = 5_500_000
	w = popn/ss
	out = zeros(ss,3)
	inflation = 1.1
	i = 0
	for p in eachrow(data)
		i+=1
		pers = Person( p.age,p.income_wages*52*inflation)
		res = dotax(pers,sys)
		out[i,1]=w
		out[i,2]=res.net_income
		out[i,3]=res.taxes
	end
	out
end

# ╔═╡ a1f92cf4-fdd6-11ea-37ba-5b4efab11252
begin
	allr1=do_all(sp,sys1)
	allr2=do_all(sp,sys2)
end

# ╔═╡ d16e31fa-fdd6-11ea-3476-71dbfa596605
begin
	ineq1 = PovertyAndInequalityMeasures.make_inequality( allr1, 1, 2 )
	ineq2 = PovertyAndInequalityMeasures.make_inequality( allr2, 1, 2 )
end

# ╔═╡ 8fd8dc52-fdd8-11ea-0d46-db0fbd96cd90
begin
	dc1 = ineq1[:deciles]
	dc2 = ineq2[:deciles]
	m = hcat(dc1[:,1:2],dc2[:,2])
	plot(m,labels=["equality" "pre" "post"],title="Gini")
	#m
end

# ╔═╡ 8f1e6616-ffb2-11ea-0e84-f35d2f98221b
begin
	decs = (dc2[:,3] - dc1[:,3])./52
	bar(decs,labels="avg. gain",title="deciles")
end

# ╔═╡ 5667cce2-fdda-11ea-1eb2-130e04fd8cb3
begin
	r1=Int(trunc(sum(allr1[:,1].*allr1[:,3])/1_000_000))
	r2=Int(trunc(sum(allr2[:,1].*allr2[:,3])/1_000_000))
	cost = r2-r1
	(cost=cost,r1=r1,r2=r2)
end

# ╔═╡ 8f3045e0-fdda-11ea-2f94-0dec0b980c14
(ineq1[:gini],ineq2[:gini],ineq1[:gini]-ineq2[:gini])

# ╔═╡ f4a96ad2-fde9-11ea-28c3-f9376758d82f
@testset "X" begin
	@test 1 ≈ 1.0000000000000000000008
end

# ╔═╡ c985e5d6-0084-11eb-2569-c3d8af344837
combine(sp,:income_wages=>mean)[1,:income_wages_mean]*52|>trunc|>Integer

# ╔═╡ 20950768-0093-11eb-3e65-391d2057f808
last(select(sp, :income_wages => tiedrank,:income_wages => ordinalrank,:income_wages),9)

# ╔═╡ Cell order:
# ╠═d02ecf8a-fdd0-11ea-0bec-b561da2f2a02
# ╟─97c87a0a-fde0-11ea-1419-2f9939bfa6e0
# ╟─d1e09cc6-fde1-11ea-07c7-0fce2411a060
# ╠═00f12bde-fde2-11ea-1026-c11c72cea702
# ╠═0651656c-fde2-11ea-251f-5747f4746430
# ╠═0a7f7e3a-fde2-11ea-3825-37b7be64f5e2
# ╠═0c3b3004-fde2-11ea-0567-4bd9576443af
# ╠═2b19845e-fde2-11ea-2353-7ddeb1182fc9
# ╠═53b4ca1c-fde2-11ea-2955-f3c19026972b
# ╠═708ab7c8-fde2-11ea-32ac-b56e9df87ebe
# ╠═83d83a9c-fde2-11ea-3512-9f140251a4e9
# ╠═940fd034-fde2-11ea-1fe2-97533b9dc40f
# ╟─d871fa52-fde2-11ea-1e58-a9ddbea34508
# ╠═e8d7b7a4-fdd0-11ea-3e4e-d3cfcd789742
# ╠═28ce666e-fdd1-11ea-2ae6-395356fc23e5
# ╠═d9eb5ebc-fdd2-11ea-28ab-2fa7c0cfaba9
# ╟─4f4ef062-fde3-11ea-1a36-1964d61271ca
# ╠═5ce6e028-fdd3-11ea-2924-897de20ca1c2
# ╠═ba302158-fde3-11ea-2bae-939a6cab3511
# ╠═e118d6a8-fdd3-11ea-2d61-ad17c31e0d1a
# ╠═eff4a08e-fde3-11ea-2e58-9b4e4969819e
# ╟─055e7cc4-fde4-11ea-145b-c5261a647e10
# ╠═e89d49e0-fdd3-11ea-199c-2d4bf8a5563b
# ╠═44f853e2-fdd4-11ea-1a13-d5740807f2d0
# ╠═6a698960-fdd5-11ea-3b8d-81aaf65a4d22
# ╠═a5f30538-fde9-11ea-39c1-1f7f412d2c04
# ╠═7c9954a6-fdd5-11ea-32cc-819552e44bd2
# ╠═b265ebfa-fdd5-11ea-10fd-2f02021f86a0
# ╠═a1f92cf4-fdd6-11ea-37ba-5b4efab11252
# ╠═d16e31fa-fdd6-11ea-3476-71dbfa596605
# ╠═8fd8dc52-fdd8-11ea-0d46-db0fbd96cd90
# ╠═8f1e6616-ffb2-11ea-0e84-f35d2f98221b
# ╠═5667cce2-fdda-11ea-1eb2-130e04fd8cb3
# ╠═8f3045e0-fdda-11ea-2f94-0dec0b980c14
# ╠═f4a96ad2-fde9-11ea-28c3-f9376758d82f
# ╠═c985e5d6-0084-11eb-2569-c3d8af344837
# ╠═20950768-0093-11eb-3e65-391d2057f808
