#=

Very crude wealth tax experiments

=#

using CSV,DataFrames,StatsBase

using ScottishTaxBenefitModel
using .MatchingLibs
using .RunSettings

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
