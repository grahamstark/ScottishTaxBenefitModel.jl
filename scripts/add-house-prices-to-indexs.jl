#=
# Code to parse House Price data from 
# https://www.gov.uk/government/statistical-data-sets/uk-house-price-index-data-downloads-august-2025
# into Scotland-only, 1st month in quarter.
=#
using DataFrames
using CSV
using Dates
using GLM

using Pkg,LazyArtifacts
using LazyArtifacts

using ScottishTaxBenefitModel
using .RunSettings
using .Definitions
using .TimeSeriesUtils
using .Utils

DDIR="/mnt/data/ScotBen/data/2025-6/"

hp = CSV.File( DDIR*"Indices-seasonally-adjusted-2025-08.csv") |> DataFrame
rename!(lowercase,hp)
shp = hp[hp.area_code.=="S92000003",:]

# it's auto converted .. shp.date = Date.(shp.date)
# 1st quarter only
shp = shp[month.(shp.date) .∈ ([1,4,7,10],),:]
shp = shp[shp.date .>= Date(2008,1,1),:] # same size as upr

CSV.write(DDIR*"house-prices-indices-seasonally-adjusted-2025-08-scotland-quarters.tab", shp; delim='\t');


upr = CSV.File(joinpath(qualified_artifact( "augdata" ),"indexes.tab"); delim = '\t', comment = "#") |> DataFrame
nrows = size(upr)[1]
ncols = size(upr)[2]
println( "read $nrows rows and $ncols cols ")
lcnames = Symbol.(basiccensor.(string.(names(upr))))
rename!(upr, lcnames)

upr[!,:year] = zeros(Int64, nrows)
upr[!,:q] = zeros(Int8, nrows) #zeros(Union{Int64,Missing},np)


# add year, quarter cols parsed from the 'YYYY QQ' field
dp = r"([0-9]{4}) Q([1-4])"
for i in 1:nrows
    rc = match(dp, upr[i, :date])
    if (rc !== nothing)
        upr[i, :year] = parse(Int64, rc[1])
        upr[i, :q] = parse(Int8, rc[2])
    end
end

# linear regression of log(hp) on log(nomgdp)
# for crude forecast 2025q4 - 
# manually update this
upr = upr[upr.year .<= 2025,:][1:end-1,:]
upr.house_price = shp.index_sa
upr.l_hp = log.(upr.house_price)
upr.l_gdp = log.(upr.nominal_gdp)

r1 = lm( @formula( l_hp ~ l_gdp ), upr )

upr.pred_hp = exp.(predict(r1))

#= FORECAST VALUES 2025 Q4- (scaled so 2025q3 matches)
108.978776884764
109.781347304186
110.524896584069
111.285226229154
112.049106695446
112.836045754225
113.572741202749
114.317789066766
115.127893354119
115.946988500864
116.736776772035
117.513186776831
118.299267502059
119.092164942599
119.897286475665
120.723226452225
121.563695118571
122.418692280827

=#