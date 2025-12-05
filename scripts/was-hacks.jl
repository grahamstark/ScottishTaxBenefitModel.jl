#=

Very crude wealth tax experiments

=#

using CSV,DataFrames,StatsBase
using Format
using PrettyTables 
using CategoricalArrays

using PovertyAndInequalityMeasures

using ScottishTaxBenefitModel
using .MatchingLibs
using .RunSettings
using .ModelHousehold
using .STBOutput
using .Definitions
using .FRSHouseholdGetter
using .Utils

fmt(v,row=0,col=0) = Format.format(v,commas=true,precision=0)
fmt2(v,row=0,col=0) = Format.format(v,commas=true,precision=2)

settings = Settings()
settings.num_households, settings.num_people,nhh= FRSHouseholdGetter.initialise(settings)

# my dataset 

wave = 7
raw_was = MatchingLibs.WAS.load_one_was( wave )
wass, edited_was = MatchingLibs.WAS.create_subset(raw_was, wave )
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

io = open( "/home/graham_s/tmp/was-hacks.md", "w")

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
    tenure = fill( Missing_Tenure_Type, settings.num_households ), 
    was_tenure = fill( Missing_Tenure_Type, settings.num_households ), 
    employment_status_head = fill( Missing_ILO_Employment, settings.num_households ), 
    age_head = fill( 0, settings.num_households ), 
    net_physical_wealth = zeros(settings.num_households),
    net_financial_wealth = zeros(settings.num_households),
    net_housing_wealth = zeros(settings.num_households),
    net_pension_wealth = zeros(settings.num_households),
    house_price = zeros(settings.num_households),
    wealth = zeros(settings.num_households),
    wealth2 = zeros(settings.num_households), 
    wealth3 = zeros(settings.num_households),
    weight=zeros(settings.num_households),
    wealth_tax = zeros(settings.num_households))
for i in 1:settings.num_households
    hh = FRSHouseholdGetter.get_household(i)
    head = get_head( hh )
    odf.weight[i] = hh.weight
    odf.pid[i] = head.pid
    odf.regions[i] = Standard_Region(hh.raw_wealth.region)
    odf.tenure[i] = hh.tenure
    odf.house_price[i] = hh.house_value
    odf.was_tenure[i] = Tenure_Type(hh.raw_wealth.tenure)
    odf.employment_status_head[i] = head.employment_status
    odf.age_head[i] = head.age
    odf.net_physical_wealth[i] = hh.net_physical_wealth 
    odf.net_financial_wealth[i] = hh.net_financial_wealth 
    odf.net_housing_wealth[i] = hh.net_housing_wealth 
    odf.net_pension_wealth[i] = hh.net_pension_wealth
    odf.wealth[i] = hh.total_wealth
    odf.wealth2[i] = hh.raw_wealth.total_household_wealth # idiot check
    odf.wealth3[i] = hh.net_physical_wealth + hh.net_financial_wealth + hh.net_housing_wealth + hh.net_pension_wealth # anotheridiot check
    
end

odf.weighted_total_wealth = odf.wealth.*odf.weight
odf.weighted_net_physical_wealth = odf.net_physical_wealth[i] .* odf.weight
odf.weighted_net_financial_wealth = odf.net_financial_wealth[i] .* odf.weight
odf.weighted_net_housing_wealth = odf.net_housing_wealth[i] .* odf.weight
odf.weighted_net_housing_wealth = odf.net_housing_wealth.*odf.weight
odf.weighted_house_price = odf.house_price.*odf.weight

countmap(odf.regions)
w1=sum(wealthtax.(odf.wealth ) .* odf.weight)  /1_000_000
# £4,392
w2=sum(wealthtax.(odf.wealth2 ) .* odf.weight)  /1_000_000
# £4,392
w3=sum(wealthtax.(odf.wealth3 ) .* odf.weight)  /1_000_000
# no allowance case
w4=sum(wealthtax2.(odf.wealth ) .* odf.weight)  /1_000_000 
# £8,929

println(io, "wealth taxes yields £m: £1m allowance: $(fmt(w1)); £1m threshold: $(fmt(w4))")

odf.wealth_tax = wealthtax.(odf.wealth ) ./ WEEKS_PER_YEAR

# model output with 1m 1% wealth tax
wealth1000 = DataFrame(CSV.File( "/home/graham_s/tmp/wealth-1000.tab"))[!,[:pid,:other_tax,:weight]]

w_combined = innerjoin( wealth1000, odf; on=:pid, makeunique=true)
@assert w_combined.wealth_tax ≈ w_combined.other_tax # same calcs
sum(w_combined.weight) ≈ sum(w_combined.weight_1)

# model incomes per decile and mean are quite close to howards
modeldec = STBOutput.decs_to_df(PovertyAndInequalityMeasures.binify( 
                odf, 
                10, 
                :weight, 
                :wealth ))
modeldec.decile = 1:10

println(io,modeldec)
modeldec1 = STBOutput.decs_to_df(PovertyAndInequalityMeasures.binify( 
                odf, 
                1, 
                :weight, 
                :wealth ))
modeldec1.decile = 1:1
println(io,"single modeldec from ODF $(modeldec1)")
mean1 = mean( odf.wealth, Weights(odf.weight ))
println(io,"mean wealth from OFS $(mean1)")




iq=PovertyAndInequalityMeasures.make_inequality(odf, :weight,:wealth)
# mean idiot check
println( io, "average wealth from Ineq version: $(fmt2(iq.average_income))")
w5=sum( w_combined.other_tax, Weights( w_combined.weight)) * WEEKS_PER_YEAR /1_000_000 
println( io, "wealth tax using model weight relative to ONS sample weights: $(fmt(w5))")

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
mean_wealth_odf_weights = mean( odf.wealth, Weights( odf.weight ))

println(io, "mean wealth  $(fmt(mean_wealth_odf_weights))")
# 589,610

modeldec.decile = 1:10

pretty_table( io, modeldec[!,[5,4]]; formatters=[fmt], backend=:markdown)

indexes = CSV.File( "/mnt/data/ScotBen/artifacts/augdata/indexes.tab")|>DataFrame


wbt = combine( groupby( odf, :tenure), (:weighted_net_housing_wealth=>sum))

wbt.weighted_net_housing_wealth_share = round.(100.0 .* wbt.weighted_net_housing_wealth_sum ./ sum(odf.weighted_net_housing_wealth),digits=1)

val_to_label_maps = Pair[]

pretty_table( io, wbt;  backend=:markdown)

bz = combine( groupby( odf, [:tenure,:was_tenure]), (:weight=>sum))
tentab=unstack(wbz,:was_tenure,:weight_sum;fill=0)
tm = Matrix(tentab[!,2:end])
mpc = round.(100.0 .* tm ./ sum(tm);digits=1)
nrows,ncols = size( tentab )
tentab[!,2:end] = tmpc
tentab.Total = sum.(eachrow(tentab[:, Not(:tenure)]))
rename!(pretty,tentab)
tentab.Tenure = pretty.(string.(tentab.Tenure))

# Add column totals (sum down each column)
# Create a totals row
totals_row = DataFrame( Tenure = "Total")
for col in names(tentab)
    if col != "Tenure"
        totals_row[!, col] = [sum(tentab[!, col])]
    end
end
append!(tentab, totals_row)
CSV.write( "/home/graham_s/tmp/tentab.tab", tentab; delim='\t')
CSV.write( "/home/graham_s/tmp/wbt.tab", wbt; delim='\t')

pretty_table( io, tentab; backend=:markdown)


renters = odf[ renter.(odf.tenure), [:house_price, :net_housing_wealth, :was_tenure,:tenure, :weight]]
rent_anoms = combine( groupby( renters, :was_tenure), ([:house_price=>mean,:weight=>sum,:weight=>length]))
CSV.write(  "/home/graham_s/tmp/rent_anoms.tab", rent_anoms; delim='\t')
close(io)