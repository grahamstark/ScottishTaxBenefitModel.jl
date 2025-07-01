
@usingany CSV
@usingany DataFrames
@usingany StatsBase
@usingany PovertyAndInequalityMeasures

using .RunSettings,.STBParameters,.FRSHouseholdGetter,.Runner, .Monitor

# one run of scotben 24 sys
sys = STBParameters.get_default_system_for_fin_year( 2024 )

obs = Observable( Progress(settings.uuid,"",0,0,0,0))
Observable(Progress(Base.UUID("c2ae9c83-d24a-431c-b04f-74662d2ba07e"), "", 0, 0, 0, 0))
of = on(obs) do p
    global tot
    println(p)

    tot += p.step
    println(tot)
end

settings = Settings()
settings.included_data_years = [2019,2021,2022]
settings.lower_multiple=0.640000000000000
settings.upper_multiple=5.86000000000000

settings.num_households, settings.num_people, nhhs2 = 
           FRSHouseholdGetter.initialise( settings; reset=true )
res = Runner.do_one_run( settings, [sys,sys], obs )
settings22 = Settings()
settings22.included_data_years = [2022]
settings22.lower_multiple=0.45000000000000
settings22.upper_multiple=7.6000000000000
settings22.num_households, settings22.num_people, nhhs2 = 
           FRSHouseholdGetter.initialise( settings22; reset=true )
res_22 = Runner.do_one_run( settings22, [sys,sys], obs )

# hhlevel results
scotben_base = res.hh[1]
scotben_base_22 = res_22.hh[1]


# load landman base results
landman_base = CSV.File("/home/graham_s/VirtualWorlds/projects/northumbria/Landman/model/data/default_results/2024-25/base-hh-results.tab")|>DataFrame
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

landman_base_scot.eqscale = landman_base_scot.DisposableIncomeAHC./landman_base_scot.EqDisposableIncomeAHC
scotben_base_22.eqscale = scotben_base_22.ahc_net_income ./ scotben_base_22.eq_ahc_net_income

scotben_landman = innerjoin( landman_base_scot, scotben_base_22; on=[:sernum=>:hid], makeunique=true)

sum(scotben_landman.weighted_people_1.*scotben_landman.bhc_net_income)
sum( scotben_landman.weighted_people.*scotben_landman.DisposableIncomeBHC)

scotben_landman.eqscale_1 ./= 1.72

scotben_landman[!,[:num_people_1,:num_people,:num_children_1,:num_children,:weighted_people_1,:weighted_people,:bhc_net_income,:DisposableIncomeBHC,:eqscale_1,:eqscale]]
