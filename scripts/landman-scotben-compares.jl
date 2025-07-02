
@usingany CSV
@usingany DataFrames
@usingany StatsBase
@usingany PovertyAndInequalityMeasures
@usingany Observables
pv = PovertyAndInequalityMeasures # shortcut

using ScottishTaxBenefitModel
using .Definitions,
    .FRSHouseholdGetter,
    .Monitor, 
    .Results,
    .Runner, 
    .RunSettings,
    .STBParameters

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
landman_base.EqDisposableIncomeAHC ./ Results.TWO_ADS_EQ_SCALES.oecd_ahc
landman_base.EqDisposableIncomeBHC ./ Results.TWO_ADS_EQ_SCALES.oecd_bhc

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

line_scot_ahc = 0.6 * median( landman_base_scot.EqDisposableIncomeAHC, Weights(landman_base_scot.weighted_people ))
pov_landman_scot_ahc = pv.make_poverty( landman_base_scot, line_scot_ahc, 0.02, :weighted_people, :EqDisposableIncomeAHC )

line_scot_bhc = 0.6 * median( landman_base_scot.EqDisposableIncomeBHC, Weights(landman_base_scot.weighted_people ))
pov_landman_scot_bhc = pv.make_poverty( landman_base_scot, line_scot_bhc, 0.02, :weighted_people, :EqDisposableIncomeBHC )
# UK
line_uk_ahc = 0.6 * median( landman_base.EqDisposableIncomeAHC, Weights(landman_base.weighted_people ))
pov_landman_uk_ahc = pv.make_poverty( landman_base, line_uk_ahc, 0.02, :weighted_people, :EqDisposableIncomeAHC )

line_uk_bhc = 0.6 * median( landman_base.EqDisposableIncomeBHC, Weights(landman_base.weighted_people ))
pov_landman_uk_bhc = pv.make_poverty( landman_base, line_uk_bhc, 0.02, :weighted_people, :EqDisposableIncomeBHC )

line_bhc = 0.6 * median( scotben_base.eq_bhc_net_income, Weights(scotben_base.weighted_people ))
pov_scotben_bhc = pv.make_poverty( scotben_base, line_bhc, 0.02, :weighted_people, :eq_bhc_net_income )

line_ahc = 0.6 * median( scotben_base.eq_ahc_net_income, Weights(scotben_base.weighted_people ))
pov_scotben_ahc = pv.make_poverty( scotben_base, line_ahc, 0.02, :weighted_people, :eq_ahc_net_income )

line_22_bhc = 0.6 * median( scotben_base_22.eq_bhc_net_income, Weights(scotben_base_22.weighted_people ))
pov_scotben_22_bhc = pv.make_poverty( scotben_base_22, line_22_bhc, 0.02, :weighted_people, :eq_bhc_net_income )

line_22_ahc = 0.6 * median( scotben_base_22.eq_ahc_net_income, Weights(scotben_base_22.weighted_people ))
pov_scotben_22_ahc = pv.make_poverty( scotben_base_22, line_22_ahc, 0.02, :weighted_people, :eq_ahc_net_income )

line_22_x_bhc = 0.6 * median( scotben_base_22_x.eq_bhc_net_income, Weights(scotben_base_22_x.weighted_people ))
pov_scotben_22_x_bhc = pv.make_poverty( scotben_base_22_x, line_22_x_bhc, 0.02, :weighted_people, :eq_bhc_net_income )

line_22_x_ahc = 0.6 * median( scotben_base_22_x.eq_ahc_net_income, Weights(scotben_base_22_x.weighted_people ))
pov_scotben_22_x_ahc = pv.make_poverty( scotben_base_22_x, line_22_x_ahc, 0.02, :weighted_people, :eq_ahc_net_income )

landman_base_scot.eqscale = landman_base_scot.DisposableIncomeAHC./landman_base_scot.EqDisposableIncomeAHC
scotben_base_22.eqscale = scotben_base_22.ahc_net_income ./ scotben_base_22.eq_ahc_net_income

scotben_landman = innerjoin( landman_base_scot, scotben_base_22; on=[:sernum=>:hid], makeunique=true)

sum(scotben_landman.weighted_people_1.*scotben_landman.bhc_net_income)
sum( scotben_landman.weighted_people.*scotben_landman.DisposableIncomeBHC)

scotben_landman[!,[:num_people_1,:num_people,:num_children_1,:num_children,:weighted_people_1,:weighted_people,:bhc_net_income,:DisposableIncomeBHC,:eqscale_1,:eqscale]]


# landman sco 22
@show iq_landman_scot_bhc.gini
@show iq_landman_scot_ahc.gini
# landman UK 22
@show iq_landman_uk_bhc.gini
@show iq_landman_uk_ahc.gini
# scotben 2019-22
@show iq_scotben_bhc.gini
@show iq_scotben_ahc.gini
# scotben 2022, sb weights
@show iq_scotben_22_bhc.gini
@show iq_scotben_22_ahc.gini
# sb 22 frs weights
@show iq_scotben_22_x_bhc.gini
@show iq_scotben_22_x_ahc.gini

# landman sco 22
@show iq_landman_scot_bhc.palma
@show iq_landman_scot_ahc.palma
# landman UK 22
@show iq_landman_uk_bhc.palma
@show iq_landman_uk_ahc.palma
# scotben 2019-22
@show iq_scotben_bhc.palma
@show iq_scotben_ahc.palma
# scotben 2022, sb weights
@show iq_scotben_22_bhc.palma
@show iq_scotben_22_ahc.palma
# sb 22 frs weights
@show iq_scotben_22_x_bhc.palma
@show iq_scotben_22_x_ahc.palma

# landman sco 22
@show pov_landman_scot_bhc.headcount
@show pov_landman_scot_ahc.headcount
# landman UK 22
@show pov_landman_uk_bhc.headcount
@show pov_landman_uk_ahc.headcount
# scotben 2019-22
@show pov_scotben_bhc.headcount
@show pov_scotben_ahc.headcount
# scotben 2022, sb weights
@show pov_scotben_22_bhc.headcount
@show pov_scotben_22_ahc.headcount
# sb 22 frs weights
@show pov_scotben_22_x_bhc.headcount
@show pov_scotben_22_x_ahc.headcount

