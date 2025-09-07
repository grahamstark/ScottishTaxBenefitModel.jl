@usingany CSV
@usingany DataFrames
@usingany StatsBase
@usingany PovertyAndInequalityMeasures
@usingany Observables
@usingany CairoMakie
@usingany GLM
@usingany Pluto

# include("landman-to-sb-mappings.jl")

pv = PovertyAndInequalityMeasures # shortcut

using ScottishTaxBenefitModel
using 
    .DataSummariser,
    .Definitions,
    .FRSHouseholdGetter,
    .HouseholdFromFrame,
    .ModelHousehold,
    .Monitor, 
    .Results,
    .Runner, 
    .RunSettings,
    .SingleHouseholdCalculations,
    .STBIncomes,
    .STBParameters,
    .Uprating,
    .Utils

function make_pov( df :: DataFrame, incf::Symbol, growth=0.02 )::Tuple
    povline = 0.6 * median( df[!,incf], Weights( df.weighted_people ))
    povstats = make_poverty( df, povline, growth, :weighted_people, incf )
    povstats, povline   
end

# Raw FRS
hhold = CSV.File( "/mnt/data/frs/2022/tab/househol.tab"; missingstring=[" ", ""])|>DataFrame
rename!( hhold, lowercase.(names(hhold)))
hhold_scot = @view hhold[hhold.gvtregn .== 299999999,:]

# one run of scotben 24 sys
sys = STBParameters.get_default_system_for_fin_year( 2025 )
settings = Settings()
tot = 0
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
Observable(Progress(Base.UUID("c2ae9c83-d24a-431c-b04f-74662d2ba07e"), "", 0, 0, 0, 0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
    println(tot)
end

settings.included_data_years = [2019,2021,2022, 2023]
settings.requested_threads = 4
settings.to_y=2025
settings.to_q=3
Uprating.load_prices( settings, true )
settings.num_households, settings.num_people, nhhs2 = 
           FRSHouseholdGetter.initialise( settings; reset=true )
res = Runner.do_one_run( settings, [sys,sys], obs )
results_hhs = res.hh[1]
results_hhs.grossing_factor = Weights( results_hhs.weighted_people)
results_hhs = results_hhs[results_hhs.bhc_net_income .>= 0,:] # emulate HBAI non-neg only
results_hhs.eq_scale_bhc ./= Results.TWO_ADS_EQ_SCALES.oecd_bhc
results_hhs.eq_scale_ahc ./= Results.TWO_ADS_EQ_SCALES.oecd_ahc

# overwrite raw data with uprated/matched versions
dataset_artifact = get_data_artifact( settings )
model_hhs = HouseholdFromFrame.read_hh( 
    joinpath( dataset_artifact, "households.tab")) # CSV.File( ds.hhlds ) |> DataFrame
model_people = HouseholdFromFrame.read_pers( 
    joinpath( dataset_artifact, "people.tab"))
model_hhs = model_hhs[ model_hhs.data_year .∈ ( settings.included_data_years, ) , :]
model_people = model_people[ model_people.data_year .∈ ( settings.included_data_years, ) , :]
DataSummariser.overwrite_raw!( model_hhs, model_people, settings.num_households )

# eq scales rel to 2 adults
# .. already done now
# hhs.eqscale_bhc = round.( hhs.eqscale_bhc/Results.TWO_ADS_EQ_SCALES.oecd_bhc, digits=2)
# hhs.eqscale_ahc = round.( hhs.eqscale_ahc/Results.TWO_ADS_EQ_SCALES.oecd_ahc, digits=2)
#
# NOTE column label missing 3rd from end in the HBAI files - I added `nothinggks` as a 
# label
#
hbai = CSV.File( "/mnt/data/hbai/2024-ed/UKDA-5828-tab/main/20224.csv"; delim=',', missingstring=["","-9","A"]) |> DataFrame
rename!(lowercase, hbai)
hbai = hbai[( .! ismissing.( hbai.s_oe_bhc .+ hbai.s_oe_ahc .+ hbai.eahchh)), :]
hbai.after_hc_net_equivalised = Float64.( hbai.s_oe_ahc )
hbai.after_hc_net_equivalised = Float64.(hbai.s_oe_ahc)
hbai.before_hc_net_equivalised = Float64.(hbai.s_oe_bhc)
hbai.ahc_net_income = Float64.(hbai.eahchh)
# hbai.ahc_net_income_spi = Float64.(hbai.esahchh)
hbai.total_housing_costs = Float64.(hbai.ehcost)
hbai.after_hc_eqscale = Float64.(hbai.eqoahchh)
hbai.before_hc_eqscale= Float64.(hbai.eqobhchh)
hbai.grossing_factor = Weights( Float64.(hbai.gs_indpp))
hbai.data_year = hbai.year .+ 1993 # 30 -> 2023
hbai.cpi_av_pub = Float64.(hbai.ahcpubdef)
hbai.bhc_net_income = hbai.ahc_net_income + hbai.total_housing_costs

#=
HBAI deflators
AHCDEF	Value	CPI-based AHC deflator for the average of the survey year
AHCPUBDEF	Value	CPI-based AHC deflator for latest (publication) year
AHCYRDEF	Value	CPI-based AHC deflator for survey year (average of financial year)
=#

hbai_s = hbai[(hbai.gvtregn .==12),:]
hb23 = hbai[(hbai.data_year.==2023),:]
hb23_s = hbai_s[(hbai_s.data_year.==2023),:]

sbmean_grossed = mean( results_hhs.bhc_net_income, results_hhs.grossing_factor)
sbmean_ungrossed = mean( results_hhs.bhc_net_income)
hbai_mean_grossed = mean(hbai_s.bhc_net_income,hbai_s.grossing_factor)
hbai_mean_ungrossed = mean(hbai_s.bhc_net_income )

sbmedian_grossed = median( results_hhs.bhc_net_income, results_hhs.grossing_factor)
sbmedian_ungrossed = median( results_hhs.bhc_net_income)
hbai_median_grossed = median(hbai_s.bhc_net_income,hbai_s.grossing_factor)
hbai_median_ungrossed = median(hbai_s.bhc_net_income )

# select summary hbai
hbai_s[!,[:sernum,:grossing_factor,:ahc_net_income,:before_hc_eqscale,:data_year,:ahcpubdef,:ahcyrdef]]

summarystats( results_hhs.bhc_net_income )
summarystats( hbai_s.bhc_net_income )

#1. is it my weights?
# Problem: my mean income is >100 higher than SPI mean income.
# 
# join hbai and my hh data
# read CSV version?? 
# uprate mine to HBAI target
# use HBAI weights/my weights
#


median(hbai.after_hc_net_equivalised,Weights(hbai.grossing_factor))
median(hb23.after_hc_net_equivalised,Weights(hb23.grossing_factor))
# should match ... these:
unique(hbai.mdoeahc)
# should match ... these:
unique(hbai.mdoebhc)
