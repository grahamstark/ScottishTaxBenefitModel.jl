#=

Very crude wealth tax experiments

=#

using CSV,DataFrames,StatsBase
using Format
using PrettyTables 

using PovertyAndInequalityMeasures

using ScottishTaxBenefitModel
using .MatchingLibs
using .RunSettings
using .ModelHousehold
using .STBOutput
using .Definitions
using .FRSHouseholdGetter

fmt(v,row,col) = Format.format(v,commas=true,precision=0)

settings = Settings()
settings.num_households, settings.num_people,nhh= FRSHouseholdGetter.initialise(settings)

# my dataset 
wass = MatchingLibs.WAS.create_subset()
wass_sco = wass[wass.region .== 299999999,:]

w7 = CSV.File( "/mnt/data/was/UKDA-7215-tab/tab/was_round_7_hhold_eul_march_2022.tab")|>DataFrame
rename!(lowercase, w7 )

# scottish subset of w7 WAS
w7_sco = w7[w7.gorr7 .== 12,:]

"""
Wealth Tax for a single unit (hh,person..)
"""
function wealthtax( totalwealth; allow=1_000_000,rate=0.01 )
    max(0,totalwealth-allow)*rate
end

function wealthtax2( totalwealth; allow=1_000_000,rate=0.01 )
    return if totalwealth < allow 
        0.0
    else 
        totalwealth*rate
    end
end
# nom gdp 2020q1->2025q4
infl=698.4/580.9

# crude wealth tax 1% over 1m hhld level scotland
sum(wealthtax.(w7_sco.totwlthr7 .*infl ) .* w7_sco.r7xshhwgt)  /1_000_000
# = £4,060.69
# model using matched data gets 3.8bn.

# hhld weight looks about right:
sum(w7_sco.r7xshhwgt)
# = 2.452622772997429e6


odf = DataFrame(
    pid = fill( BigInt(0), settings.num_households ),
    regions = fill( Scotland, settings.num_households ), 
    wealth = zeros(settings.num_households),
    wealth2 = zeros(settings.num_households), 
    wealth3 = zeros(settings.num_households),
    weight=zeros(settings.num_households),
    wealth_tax = zeros(settings.num_households))
for i in 1:settings.num_households
    hh = FRSHouseholdGetter.get_household(i)
    head = get_head( hh )
    odf.pid[i] = head.pid
    odf.regions[i] = Standard_Region(hh.raw_wealth.region)
    odf.wealth[i] = hh.total_wealth
    odf.wealth2[i] = hh.raw_wealth.total_household_wealth # idiot check
    odf.wealth3[i] = hh.net_physical_wealth + hh.net_financial_wealth + hh.net_housing_wealth + hh.net_pension_wealth # anotheridiot check
    odf.weight[i] = hh.weight
end
countmap(odf.regions)
sum(wealthtax.(odf.wealth ) .* odf.weight)  /1_000_000
# £4,392
sum(wealthtax.(odf.wealth2 ) .* odf.weight)  /1_000_000
# £4,392
sum(wealthtax.(odf.wealth3 ) .* odf.weight)  /1_000_000
# no allowance case
sum(wealthtax2.(odf.wealth ) .* odf.weight)  /1_000_000 
# £8,929

odf.wealth_tax = wealthtax.(odf.wealth ) ./ WEEKS_PER_YEAR

# model output with 1m 1% wealth tax
wealth1000 = CSV.File( "/home/graham_s/tmp/wealth-1000.tab") |> DataFrame |> [!,[:pid,:other_tax]]

w_combined = innerjoin( wealth1000, odf; on=:pid, makeunique=true)
w_combined.wealth_tax ≈ w_combined.other_tax
sum(w_combined.weight) ≈ sum(w_combined.weight_1)

# model incomes per decile and mean are quite close to howards
modeldec = STBOutput.decs_to_df(PovertyAndInequalityMeasures.binify( 
                odf, 
                10, 
                :weight, 
                :wealth ))
modeldec.decile = 1:10

iq=PovertyAndInequalityMeasures.make_inequality(odf, :weight,:wealth)
# mean idiot check
iq.average_income
# 589,610
#=

 Row │ Cumulative Population  Cumulative Income  Income Break   Average Income 
     │ Float64                Float64            Float64        Float64        
─────┼─────────────────────────────────────────────────────────────────────────
   1 │              0.100268         0.00123657  20413.3          7282.49
   2 │              0.199833         0.00703898  51672.4         34449.8
   3 │              0.299879         0.0204137       1.14598e5   79005.9
   4 │              0.400097         0.0480856       2.0943e5        1.6291e5
   5 │              0.500053         0.0928152       3.28459e5       2.63883e5
   6 │              0.599988         0.157779        4.36988e5       3.83348e5
   7 │              0.700116         0.247554        6.15403e5       5.28766e5
   8 │              0.800026         0.373582        8.96178e5       7.43815e5
   9 │              0.900054         0.565165        1.4051e6        1.12947e6
  10 │              1.0              1.0             1.00919e8       2.5658e6

  Row │ Cumulative Population  Cumulative Income  Income Break   Average Income 
     │ Float64                Float64            Float64        Float64        
─────┼─────────────────────────────────────────────────────────────────────────
   1 │             20413.3          7282.49
   2 │             51672.4         34449.8
   3 │              0.299879         0.0204137       1.14598e5   79005.9
   4 │              0.400097         0.0480856       2.0943e5        1.6291e5
   5 │              0.500053         0.0928152       3.28459e5       2.63883e5
   6 │              0.599988         0.157779        4.36988e5       3.83348e5
   7 │              0.700116         0.247554        6.15403e5       5.28766e5
   8 │              0.800026         0.373582        8.96178e5       7.43815e5
   9 │              0.900054         0.565165        1.4051e6        1.12947e6
  10 │              1.0              1.0             1.00919e8       2.5658e6

=#

# unuprated raw w7
wasdec = STBOutput.decs_to_df(PovertyAndInequalityMeasures.binify( 
                w7_sco, 
                10, 
                :r7xshhwgt,
                :totwlthr7 ))

mean( odf.wealth, Weights( odf.weight ))
# 589,610

modeldec.decile = 1:10
pretty_table( modeldec[!,[5,4]]; formatters=[fmt], backend=:markdown)
