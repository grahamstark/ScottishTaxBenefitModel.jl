#=

Very crude wealth tax experiments

=#

using CSV,DataFrames,StatsBase

using ScottishTaxBenefitModel
using .MatchingLibs
using .RunSettings
using .Definitions
using .FRSHouseholdGetter

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
    regions = fill( Scotland, settings.num_households ), 
    wealth = zeros(settings.num_households),
    wealth2 = zeros(settings.num_households),
    wealth3 = zeros(settings.num_households),
    weight=zeros(settings.num_households))
for i in 1:settings.num_households
    hh = FRSHouseholdGetter.get_household(i)
    odf.regions[i] = Standard_Region(hh.raw_wealth.region)
    odf.wealth[i] = hh.total_wealth
    odf.wealth2[i] = hh.raw_wealth.total_household_wealth
    odf.wealth3[i] = hh.net_physical_wealth + hh.net_financial_wealth + hh.net_housing_wealth + hh.net_pension_wealth
    odf.weight[i] = hh.weight
end
countmap(odf.regions)
sum(wealthtax.(odf.wealth ) .* odf.weight)  /1_000_000
# £4,392
sum(wealthtax.(odf.wealth2 ) .* odf.weight)  /1_000_000

# weeklyised
52*sum(wealthtax.(odf.wealth2; rate=0.01*0.019164955509924708 ) .* odf.weight)  /1_000_000 
# 437729.76685000083

# £4,392
sum(wealthtax.(odf.wealth3 ) .* odf.weight)  /1_000_000
