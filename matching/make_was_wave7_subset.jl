using GLM,DataFrames,CSV,StatsBase,DataStructures

renames = Dict(
    "log(weekly_gross_income)"=>"log_weekly_gross_income",
    "(Intercept)"=>"cons"
)

function rename( ins :: String, m :: Dict )::String
    get( m, ins, ins )
end

function renamecol!( d ::DataFrame, col :: Symbol, renames :: Dict )
    for r in eachrow(d)
        r[col] = rename( r[col], renames )
    end
end

function ustack( d :: DataFrame )
    unstack(d[!,[1,2]],1,2)[1,:]
    rename!( d, renames )
end

was = CSV.File( "/mnt/data/was/UKDA-7215-tab/tab/was_round_7_hhold_eul_march_2022.tab") |> DataFrame

lcnames = lowercase.(names(was))
rename!( was, lcnames )


subwas = DataFrame()
subwas.ecpos_head = was.hrpdvecactr7
subwas.bedrooms = was.hbedrmr7
subwas.region = was.gorr7
subwas.age_head = was.hrpdvage8r7
subwas.weekly_gross_income = was.dvtotgirr7./wpy
subwas.household_type = was.hholdtyper7
subwas.occupation =  was.hrpnssec3r7
subwas.total_wealth = was.totwlthr7
subwas.num_children = was.numchildr7
subwas.num_adults = was.dvhsizer7 - subwas.num_children
subwas.sex_head = was.hrpsexr7
# subwas.socio_economic_grouping
subwas.empstat_head = was.hrpempstat2r7 
# rename all thse
#=
subwas.accomr7 = was.accomr7 
subwas.hsetyper7 = was.hsetyper7
subwas.flttypr7 = was.flttypr7
subwas.ten1r7 = was.ten1r7
subwas.llord7 = was.llord7
subwas.furnr7 = was.furnr7
=#

subwas.any_wages = was.dvgiempr7_aggr .> 0
subwas.any_selfemp = was.dvgiser7_aggr .> 0
subwas.any_pension_income = was.dvpinpvalr7_aggr .> 0

subwas.net_housing = was.hpropwr7
subwas.marital_status_head = was.hrpdvmrdfr7
subwas.has_degree = was.hrpedlevelr7 .== 1
subwas.net_physical = was.hphyswr7
subwas.total_pensions = was.totpenr7_aggr
subwas.net_financial = was.hfinwntr7_sum
subwas.total_value_of_other_property = was.othpropvalr7_sum
subwas.total_financial_liabilities = was.hfinlr7_excslc_aggr #   Hhold value of financial liabilities
subwas.total_household_wealth = was.totwlthr7
subwas.house_price = was.hvaluer7
# HFINWNTR7_exSLC_Sum

CSV.write( "data/was_wave_7_subset.tab", subwas; delim='\t')
