
@usingany CSV
@usingany DataFrames
@usingany StatsBase
@usingany PovertyAndInequalityMeasures
@usingany Observables
pv = PovertyAndInequalityMeasures # shortcut

using ScottishTaxBenefitModel
using 
    .DataSummariser,
    .Definitions,
    .FRSHouseholdGetter,
    .HouseholdFromFrame,
    .Monitor, 
    .Results,
    .Runner, 
    .RunSettings,
    .STBIncomes,
    .STBParameters,
    .Utils

function make_pov( df :: DataFrame, incf::Symbol, growth=0.02 )::Tuple
    povline = 0.6 * median( df[!,incf], Weights( df.weighted_people ))
    povstats = make_poverty( df, povline, growth, :weighted_people, incf )
    povstats, povline   
end



# one run of scotben 24 sys
sys = STBParameters.get_default_system_for_fin_year( 2024 )
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

settings.included_data_years = [2019,2021,2022]
settings.lower_multiple=0.640000000000000
settings.upper_multiple=5.86000000000000
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

# scales rel to 2 adults
hhs.eqscale_bhc = round.( hhs.eqscale_bhc/Results.TWO_ADS_EQ_SCALES.oecd_bhc, digits=2)
hhs.eqscale_ahc = round.( hhs.eqscale_ahc/Results.TWO_ADS_EQ_SCALES.oecd_ahc, digits=2)

res = Runner.do_one_run( settings, [sys,sys], obs )


settings22 = Settings()
settings22.requested_threads = 4
settings22.included_data_years = [2022]
settings22.lower_multiple=0.45000000000000
settings22.upper_multiple=7.6000000000000
settings22.num_households, settings22.num_people, nhhs2 = 
           FRSHouseholdGetter.initialise( settings22; reset=true )
res_22 = Runner.do_one_run( settings22, [sys,sys], obs )
settings22_x = Settings()
settings22_x.requested_threads = 4
settings22_x.included_data_years = [2022]
settings22_x.lower_multiple=0.45000000000000
settings22_x.upper_multiple=7.6000000000000
settings22_x.weighting_strategy = use_supplied_weights
settings22_x.num_households, settings22_x.num_people, nhhs2 = 
           FRSHouseholdGetter.initialise( settings22_x; reset=true )
res_22_x = Runner.do_one_run( settings22_x, [sys,sys], obs )

# hhlevel results
scotben_base = res.hh[1]
scotben_base_22 = res_22.hh[1]
scotben_base_22_x = res_22_x.hh[1]

# load landman base results
landman_base = CSV.File("/home/graham_s/VirtualWorlds/projects/northumbria/Landman/model/data/default_results/2024-25/base-hh-results.tab")|>DataFrame

# Howard's eq scales are relative to 2 adults, not one like HBAI, so...
# landman_base.EqDisposableIncomeAHC ./= Results.TWO_ADS_EQ_SCALES.oecd_ahc
# landman_base.EqDisposableIncomeBHC ./= Results.TWO_ADS_EQ_SCALES.oecd_bhc
# landman_base.esAHC .*= Results.TWO_ADS_EQ_SCALES.oecd_ahc
# landman_base.esBHC .*= Results.TWO_ADS_EQ_SCALES.oecd_bhc

landman_base_scot = landman_base[landman_base.Region.=="Scotland",:]

iq_landman_scot_ahc = pv.make_inequality( landman_base_scot, :weighted_people, :EqDisposableIncomeAHC )
iq_landman_scot_bhc = pv.make_inequality( landman_base_scot, :weighted_people, :EqDisposableIncomeBHC )
# UK
iq_landman_uk_ahc = pv.make_inequality( landman_base, :weighted_people, :EqDisposableIncomeAHC )
iq_landman_uk_bhc = pv.make_inequality( landman_base, :weighted_people, :EqDisposableIncomeBHC )

iq_scotben_bhc = pv.make_inequality( scotben_base, :weighted_people, :eq_bhc_net_income )
iq_scotben_ahc = pv.make_inequality( scotben_base, :weighted_people, :eq_ahc_net_income )
iq_scotben_22_bhc = pv.make_inequality( scotben_base_22, :weighted_people, :eq_bhc_net_income )
iq_scotben_22_ahc = pv.make_inequality( scotben_base_22, :weighted_people, :eq_ahc_net_income )
iq_scotben_22_x_bhc = pv.make_inequality( scotben_base_22_x, :weighted_people, :eq_bhc_net_income )
iq_scotben_22_x_ahc = pv.make_inequality( scotben_base_22_x, :weighted_people, :eq_ahc_net_income )

pov_landman_scot_ahc, line_scot_ahc = make_pov( landman_base_scot, :EqDisposableIncomeAHC) 
pov_landman_scot_bhc, line_scot_bhc = make_pov( landman_base_scot, :EqDisposableIncomeBHC  )
pov_landman_uk_ahc, line_uk_ahc = make_pov( landman_base, :EqDisposableIncomeAHC  ) # uk
pov_landman_uk_bhc, line_uk_bhc = make_pov( landman_base, :EqDisposableIncomeBHC  )
pov_scotben_bhc, line_bhc = make_pov( scotben_base, :eq_bhc_net_income  )
pov_scotben_ahc, line_ahc = make_pov( scotben_base, :eq_ahc_net_income  )
pov_scotben_22_bhc, line_22_bhc = make_pov( scotben_base_22, :eq_bhc_net_income  )
pov_scotben_22_ahc, line_22_ahc = make_pov( scotben_base_22, :eq_ahc_net_income  )
pov_scotben_22_x_bhc, line_22_x_bhc = make_pov( scotben_base_22_x, :eq_bhc_net_income  ) # 1 year sb,frs weights
pov_scotben_22_x_ahc, line_22_x_ahc = make_pov( scotben_base_22_x, :eq_ahc_net_income  )

scotben_base_22.eqscale = scotben_base_22.ahc_net_income ./ scotben_base_22.eq_ahc_net_income

# join landman output to scotben hh level output
scotben_landman = innerjoin( landman_base_scot, scotben_base_22; on=[:sernum=>:hid], makeunique=true)
# .. then join to raw ScotBen data
scotben_landman = innerjoin( scotben_landman, hhs; on=[:data_year=>:data_year,:sernum=>:hid], makeunique=true)

sum(scotben_landman.weighted_people_1.*scotben_landman.bhc_net_income)
sum( scotben_landman.weighted_people.*scotben_landman.DisposableIncomeBHC)

main_compares = [
    :num_people_1,:num_people,
    :num_children_1,:num_children,
    :eqscale_bhc,:esBHC, 
    :eqscale_ahc,:esAHC, 
    :weighted_people_1,:weighted_people,
    :bhc_net_income,:DisposableIncomeBHC,
    :ahc_net_income,:DisposableIncomeAHC,
    :eq_bhc_net_income,:EqDisposableIncomeBHC,
    :eq_ahc_net_income,:EqDisposableIncomeAHC]

comparedf = scotben_landman[!,main_compares]


n = 5
compares = DataFrame( 
    #               1                 2             3                 4               5
    label = ["Landman Scotland", "Landman UK", "ScotBen 3 Year", "ScotBen 2022", "ScotBen 2022/FRS Weights"],
    weight = zeros(n),
    gini_bhc = zeros(n),
    gini_ahc = zeros(n),
    palma_bhc = zeros(n),
    palma_ahc = zeros(n),
    headcount_bhc = zeros(n),
    headcount_ahc = zeros(n),
    mean_bhc = zeros(n),
    mean_ahc = zeros(n),
    median_bhc = zeros(n),
    median_ahc = zeros(n),
    mean_eq_bhc = zeros(n),
    mean_eq_ahc = zeros(n),
    median_eq_bhc = zeros(n),
    median_eq_ahc = zeros(n))

# landman sco 22

compares[1,:gini_bhc] = iq_landman_scot_bhc.gini
compares[1,:gini_ahc] = iq_landman_scot_ahc.gini
compares[2,:gini_bhc] = iq_landman_uk_bhc.gini
compares[2,:gini_ahc] = iq_landman_uk_ahc.gini
compares[3,:gini_bhc] = iq_scotben_bhc.gini
compares[3,:gini_ahc] = iq_scotben_ahc.gini
compares[4,:gini_bhc] = iq_scotben_22_bhc.gini
compares[4,:gini_ahc] = iq_scotben_22_ahc.gini
compares[5,:gini_bhc] = iq_scotben_22_x_bhc.gini
compares[5,:gini_ahc] = iq_scotben_22_x_ahc.gini
compares[1,:palma_bhc] = iq_landman_scot_bhc.palma
compares[1,:palma_ahc] = iq_landman_scot_ahc.palma
compares[2,:palma_bhc] = iq_landman_uk_bhc.palma
compares[2,:palma_ahc] = iq_landman_uk_ahc.palma
compares[3,:palma_bhc] = iq_scotben_bhc.palma
compares[3,:palma_ahc] = iq_scotben_ahc.palma
compares[4,:palma_bhc] = iq_scotben_22_bhc.palma
compares[4,:palma_ahc] = iq_scotben_22_ahc.palma
compares[5,:palma_bhc] = iq_scotben_22_x_bhc.palma
compares[5,:palma_ahc] = iq_scotben_22_x_ahc.palma
compares[1,:headcount_bhc] = pov_landman_scot_bhc.headcount
compares[1,:headcount_ahc] = pov_landman_scot_ahc.headcount
compares[2,:headcount_bhc] = pov_landman_uk_bhc.headcount
compares[2,:headcount_ahc] = pov_landman_uk_ahc.headcount
compares[3,:headcount_bhc] = pov_scotben_bhc.headcount
compares[3,:headcount_ahc] = pov_scotben_ahc.headcount
compares[4,:headcount_bhc] = pov_scotben_22_bhc.headcount
compares[4,:headcount_ahc] = pov_scotben_22_ahc.headcount
compares[5,:headcount_bhc] = pov_scotben_22_x_bhc.headcount
compares[5,:headcount_ahc] = pov_scotben_22_x_ahc.headcount

compares[1,:mean_eq_bhc] = iq_landman_scot_bhc.average_income
compares[1,:mean_eq_ahc] = iq_landman_scot_ahc.average_income
compares[2,:mean_eq_bhc] = iq_landman_uk_bhc.average_income
compares[2,:mean_eq_ahc] = iq_landman_uk_ahc.average_income
compares[3,:mean_eq_bhc] = iq_scotben_bhc.average_income
compares[3,:mean_eq_ahc] = iq_scotben_ahc.average_income
compares[4,:mean_eq_bhc] = iq_scotben_22_bhc.average_income
compares[4,:mean_eq_ahc] = iq_scotben_22_ahc.average_income
compares[5,:mean_eq_bhc] = iq_scotben_22_x_bhc.average_income
compares[5,:mean_eq_ahc] = iq_scotben_22_x_ahc.average_income
compares[1,:median_eq_bhc] = iq_landman_scot_bhc.median
compares[1,:median_eq_ahc] = iq_landman_scot_ahc.median
compares[2,:median_eq_bhc] = iq_landman_uk_bhc.median
compares[2,:median_eq_ahc] = iq_landman_uk_ahc.median
compares[3,:median_eq_bhc] = iq_scotben_bhc.median
compares[3,:median_eq_ahc] = iq_scotben_ahc.median
compares[4,:median_eq_bhc] = iq_scotben_22_bhc.median
compares[4,:median_eq_ahc] = iq_scotben_22_ahc.median
compares[5,:median_eq_bhc] = iq_scotben_22_x_bhc.median
compares[5,:median_eq_ahc] = iq_scotben_22_x_ahc.median

compares[1,:mean_bhc] = mean( landman_base.DisposableIncomeBHC, Weights(landman_base.weighted_people ))
compares[1,:mean_ahc] = mean( landman_base.DisposableIncomeAHC, Weights(landman_base.weighted_people ))
compares[2,:mean_bhc] = mean( landman_base_scot.DisposableIncomeBHC, Weights(landman_base_scot.weighted_people ))
compares[2,:mean_ahc] = mean( landman_base_scot.DisposableIncomeAHC, Weights(landman_base_scot.weighted_people ))
compares[3,:mean_bhc] = mean( scotben_base.bhc_net_income, Weights(scotben_base.weighted_people ))
compares[3,:mean_ahc] = mean( scotben_base.ahc_net_income, Weights(scotben_base.weighted_people ))
compares[4,:mean_bhc] = mean( scotben_base_22.bhc_net_income, Weights(scotben_base_22.weighted_people ))
compares[4,:mean_ahc] = mean( scotben_base_22.ahc_net_income, Weights(scotben_base_22.weighted_people ))
compares[5,:mean_bhc] = mean( scotben_base_22_x.bhc_net_income, Weights(scotben_base_22_x.weighted_people ))
compares[5,:mean_ahc] = mean( scotben_base_22_x.ahc_net_income, Weights(scotben_base_22_x.weighted_people ))

compares[1,:median_bhc] = median( landman_base.DisposableIncomeBHC, Weights(landman_base.weighted_people ))
compares[1,:median_ahc] = median( landman_base.DisposableIncomeAHC, Weights(landman_base.weighted_people ))
compares[2,:median_bhc] = median( landman_base_scot.DisposableIncomeBHC, Weights(landman_base_scot.weighted_people ))
compares[2,:median_ahc] = median( landman_base_scot.DisposableIncomeAHC, Weights(landman_base_scot.weighted_people ))
compares[3,:median_bhc] = median( scotben_base.bhc_net_income, Weights(scotben_base.weighted_people ))
compares[3,:median_ahc] = median( scotben_base.ahc_net_income, Weights(scotben_base.weighted_people ))
compares[4,:median_bhc] = median( scotben_base_22.bhc_net_income, Weights(scotben_base_22.weighted_people ))
compares[4,:median_ahc] = median( scotben_base_22.ahc_net_income, Weights(scotben_base_22.weighted_people ))
compares[5,:median_bhc] = median( scotben_base_22_x.bhc_net_income, Weights(scotben_base_22_x.weighted_people ))
compares[5,:median_ahc] = median( scotben_base_22_x.ahc_net_income, Weights(scotben_base_22_x.weighted_people ))

CSV.write("landman-vs-scotben.tab", compares; delim='\t')
pp = permutedims( compares, 1 )
pp.label = pretty.( pp.label )
CSV.write("landman-vs-scotben-transposed.tab", pp; delim='\t')
