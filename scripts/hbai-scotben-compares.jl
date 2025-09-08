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
    .Utils,
    .Weighting

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

function onerun( ;
    weighting_relative_to_ons_weights :: Bool,
    to_y::Int, 
    to_q :: Int )
    settings.included_data_years = [2019,2021,2022, 2023] # same as 3 year HBAI
    settings.requested_threads = 4
    settings.to_y=to_y #match hbai, kinda sorta
    settings.to_q=to_q
    settings.weighting_relative_to_ons_weights = weighting_relative_to_ons_weights
    Uprating.load_prices( settings, true )
    settings.num_households, settings.num_people, nhhs2 = 
            FRSHouseholdGetter.initialise( settings; reset=true )
    res = Runner.do_one_run( settings, [sys,sys], obs )
    results_hhs = res.hh[1]
    results_hhs.grossing_factor = Weights( results_hhs.weighted_people)
    results_indiv= res.indiv[1]
    results_indiv.grossing_factor = Weights( results_indiv.weight)
    #results_hhs = results_hhs[results_hhs.bhc_net_income .>= 0,:] # emulate HBAI non-neg only
    results_hhs.eq_scale_bhc ./= Results.TWO_ADS_EQ_SCALES.oecd_bhc
    results_hhs.eq_scale_ahc ./= Results.TWO_ADS_EQ_SCALES.oecd_ahc
    return res, results_hhs, results_indiv
end

function load_model_data()
    # overwrite raw data with uprated/matched versions
    dataset_artifact = get_data_artifact( settings )
    model_hhs = HouseholdFromFrame.read_hh( 
        joinpath( dataset_artifact, "households.tab")) # CSV.File( ds.hhlds ) |> DataFrame
    model_people = HouseholdFromFrame.read_pers( 
        joinpath( dataset_artifact, "people.tab"))
    model_hhs = model_hhs[ model_hhs.data_year .∈ ( settings.included_data_years, ) , :]
    model_people = model_people[ model_people.data_year .∈ ( settings.included_data_years, ) , :]
    DataSummariser.overwrite_raw!( model_hhs, model_people, settings.num_households )
    jhhs = leftjoin(results_hhs, model_hhs, on=[:hid,:data_year], makeunique=true )
    return jhhs, model_people, model_hhs
end

function get_hbai()
    hbai = CSV.File( "/mnt/data/hbai/2024-ed/UKDA-5828-tab/main/20224.csv"; delim=',', missingstring=["","-9","A"]) |> DataFrame
    rename!(lowercase, hbai)
    hbai = hbai[( .! ismissing.( hbai.s_oe_bhc .+ hbai.s_oe_ahc .+ hbai.eahchh)), :]
    hbai.eq_ahc_net_income = Float64.( hbai.s_oe_ahc )
    hbai.eq_bhc_net_income = Float64.(hbai.s_oe_bhc)
    hbai.ahc_net_income = Float64.(hbai.eahchh)
    # hbai.ahc_net_income_spi = Float64.(hbai.esahchh)
    hbai.total_housing_costs = Float64.(hbai.ehcost)
    hbai.after_hc_eqscale = Float64.(hbai.eqoahchh)
    hbai.before_hc_eqscale= Float64.(hbai.eqobhchh)
    hbai.grossing_factor = Weights( Float64.(hbai.gs_indpp))
    hbai.data_year = hbai.year .+ 1993 # 30 -> 2023
    hbai.cpi_av_pub = Float64.(hbai.ahcpubdef)
    hbai.bhc_net_income = hbai.ahc_net_income + hbai.total_housing_costs
    hbai_heads = hbai[hbai.hrpid .== 1,:]
    #=
    HBAI deflators
    AHCDEF	Value	CPI-based AHC deflator for the average of the survey year
    AHCPUBDEF	Value	CPI-based AHC deflator for latest (publication) year
    AHCYRDEF	Value	CPI-based AHC deflator for survey year (average of financial year)
    =#
    hbai_s = hbai[(hbai.gvtregn .==12),:]
    hbai_heads_s = hbai_s[hbai_s.hrpid .== 1,:]
    hb23 = hbai[(hbai.data_year.==2023),:]
    hb23_s = hbai_s[(hbai_s.data_year.==2023),:]
    hb23_heads = hb23[hb23.hrpid .== 1,:]
    hbai, hbai_s, hb23_s, hb23_heads
end


hbai, hbai_s, hb23_s, hb23_heads = get_hbai()
jhhs, model_people, model_hhs = load_model_data()
n=16*4
df = DataFrame(
    uprated = fill("",n),
    gross_type_relative_to = fill("",n),
    grossed = fill("",n),
    stat=fill("",n), 
    inc_measure = fill("",n),
    scotben_hh = zeros(n), # [sb_h_mean_grossed, sb_h_mean_ungrossed,sb_h_median_grossed, sb_h_median_ungrossed ],
    scotben_indiv = zeros(n), #[sb_i_mean_grossed, sb_i_mean_ungrossed,sb_i_median_grossed, sb_i_median_ungrossed ],
    hbai = zeros(n)) #[hbai_mean_grossed, hbai_mean_ungrossed, hbai_median_grossed, hbai_median_ungrossed])

r = 0

for uprate in ["current", "y2024"]
    to_y, to_q = if uprate=="current"
        2025,3
    else
        2024,2 # kinda sorta
    end
    for weighting_relative_to_ons_weights in [false,true]
        results, results_hhs, results_indiv = onerun( 
            weighting_relative_to_ons_weights = weighting_relative_to_ons_weights,
            to_y = to_y, 
            to_q = to_q)
        for inc in [:bhc_net_income, :ahc_net_income,:eq_bhc_net_income, :eq_ahc_net_income]
            for grossed in [true, false]
                for f in [mean, median]
                    global r
                    r += 1
                    row = df[r,:]
                    row.gross_type_relative_to = if weighting_relative_to_ons_weights
                        "ONS Weights"
                    else
                        "Uniform Weights"
                    end 
                    row.uprated = "$uprate ($to_y q$(to_q))"
                    row.grossed = grossed ? "Grossed" : "Ungrossed"
                    row.inc_measure = pretty(string(inc))
                    row.stat = string(f)
                    hhs_weights, indiv_weights, hbai_weights = if grossed 
                        results_hhs.grossing_factor,
                        results_indiv.grossing_factor,
                        hbai_s.grossing_factor
                    else
                        Weights( results_hhs.num_people ),
                        Weights( ones( size( results_indiv)[1])),
                        Weights( ones( size( hbai_s)[1]))
                    end
                    row.scotben_hh = f(results_hhs[!,inc], hhs_weights )
                    row.scotben_indiv = f( results_indiv[!,inc], indiv_weights )
                    row.hbai = f( hbai_s[!,inc], hbai_weights )
                end # func
            end # gross
        end # incs
    end
end # uprating


sbmedian_frs_weights = median( jhhs.bhc_net_income, Weights( jhhs.weight_1 ./ 3) )
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


median(hbai.eq_ahc_net_income,Weights(hbai.grossing_factor))
median(hb23.eq_ahc_net_income,Weights(hb23.grossing_factor))
# should match ... these:
unique(hbai.mdoeahc)
# should match ... these:
unique(hbai.mdoebhc)

# test of weighting relative to exis

household_total,
    targets, # no institutional,
    initialise_target_dataframe,
    make_target_row! = Weighting.get_targets( settings )
popsum = sum( jhhs.weight )
wscale = household_total/popsum
initial_weights = jhhs.weight .* wscale

@time weightsp, data = generate_weights( 
               settings.num_households;
               weight_type = settings.weight_type,
               lower_multiple = settings.lower_multiple,
               upper_multiple = settings.upper_multiple,
               household_total = household_total,
               targets = targets, # no institutional,
               initialise_target_dataframe = initialise_target_dataframe,
               make_target_row! = make_target_row!, 
               initial_weights=initial_weights )
