


@usingany CSV
@usingany DataFrames
@usingany StatsBase
@usingany PovertyAndInequalityMeasures
@usingany Observables
@usingany CairoMakie

@usingany GLM

include("landman-to-sb-mappings.jl")

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
settings.num_households, settings.num_people, nhhs2 = 
           FRSHouseholdGetter.initialise( settings; reset=true )

# overwrite raw data with uprated/matched versions
dataset_artifact = get_data_artifact( Settings() )
hhs = HouseholdFromFrame.read_hh( 
    joinpath( dataset_artifact, "households.tab")) # CSV.File( ds.hhlds ) |> DataFrame
people = HouseholdFromFrame.read_pers( 
    joinpath( dataset_artifact, "people.tab"))
hhs = hhs[ hhs.data_year .∈ ( settings.included_data_years, ) , :]
people = people[ people.data_year .∈ ( settings.included_data_years, ) , :]
DataSummariser.overwrite_raw!( hhs, people, settings.num_households )

# eq scales rel to 2 adults
hhs.eqscale_bhc = round.( hhs.eqscale_bhc/Results.TWO_ADS_EQ_SCALES.oecd_bhc, digits=2)
hhs.eqscale_ahc = round.( hhs.eqscale_ahc/Results.TWO_ADS_EQ_SCALES.oecd_ahc, digits=2)

hbai = CSV.File( "/mnt/data/hbai/2024-ed/UKDA-5828-tab/main/i2124e_2324prices.tab"; delim='\t', missings=["","-9","A"]) |> DataFrame
rename!(lowercase, hbai)
median(hbai.s_oe_ahc,Weights(hbai.gs_indpp))

hb24 = hbai[(hbai.year.==30),[:s_oe_ahc,:s_oe_bhc,:gs_indpp]]
hb23 = hbai[(hbai.year.==29),[:s_oe_ahc,:s_oe_bhc,:gs_indpp]]
hb22 = hbai[(hbai.year.==28),[:s_oe_ahc,:s_oe_bhc,:gs_indpp]]
rename!( hb24, ["after_hc_net_equivalised", "before_hc_net_equivalised", "grossing_factor"])
rename!( hb23, ["after_hc_net_equivalised", "before_hc_net_equivalised", "grossing_factor"])
rename!( hb22, ["after_hc_net_equivalised", "before_hc_net_equivalised", "grossing_factor"])

median(hb22.after_hc_net_equivalised,Weights(hb22.grossing_factor))
median(hb23.after_hc_net_equivalised,Weights(hb23.grossing_factor))
median(hb24.after_hc_net_equivalised,Weights(hb24.grossing_factor))
# should match ... these:
unique(hbai.mdoeahc)

median(hb22.before_hc_net_equivalised,Weights(hb22.grossing_factor))
median(hb23.before_hc_net_equivalised,Weights(hb23.grossing_factor))
median(hb24.before_hc_net_equivalised,Weights(hb24.grossing_factor))
# should match ... these:
unique(hbai.mdoebhc)
