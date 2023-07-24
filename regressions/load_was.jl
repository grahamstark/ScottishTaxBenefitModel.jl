using CSV
using GLM
# using Makie
# using CairoMakie
using DataFrames
using RegressionTables
using StatsBase
using Statistics
using StatsModels
# using Colors
using Dates

was = CSV.File( "/mnt/data/was/UKDA-7215-tab/tab/was_round_7_hhold_eul_march_2022.tab") |> DataFrame

lcnames = lowercase.(names(was))
rename!( was, lcnames )

was.north_east = was.gorr7 .== 1
was.north_west = was.gorr7 .== 2
was.yorkshire = was.gorr7 .== 4
was.east_midlands = was.gorr7 .== 5
was.west_midlands = was.gorr7 .== 6
was.east_of_england = was.gorr7 .== 7
was.london = was.gorr7 .== 8
was.south_east = was.gorr7 .== 9
was.south_west = was.gorr7 .== 10
was.wales = was.gorr7 .== 11
was.scotland = was.gorr7 .== 12

was.hrp_u_25  =  was.hrpdvage8r7 .== 2
was.hrp_u_35 =  was.hrpdvage8r7 .== 3
was.hrp_u_45 =  was.hrpdvage8r7 .== 4
was.hrp_u_55 =  was.hrpdvage8r7 .== 5
was.hrp_u_65 =  was.hrpdvage8r7 .== 6
was.hrp_u_75 =  was.hrpdvage8r7 .== 7
was.hrp_75_plus = was.hrpdvage8r7 .== 8
was.weekly_net_income = was.hhnetincmthr7 ./ 4.35
was.owner = was.ten1r7 .== 1
was.mortgaged = was.ten1r7 .== 2 .|| was.ten1r7 .== 3
was.renter = was.ten1r7 .== 4 # should never happen
was.detatched = (was.accomr7 .== 1) .& (was.hsetyper7 .== 1)
was.semi = (was.accomr7 .== 1) .& (was.hsetyper7 .== 2)
was.terraced = (was.accomr7 .== 1) .& (was.hsetyper7 .== 3)
was.purpose_build_flat = (was.accomr7 .== 2) .& (was.flttypr7 .== 1) 
was.converted_flat = (was.accomr7 .== 2) .& (was.flttypr7 .== 2) 
was.ctamtr7 # council tax amount 
was.managerial = was.hrpnssec3r7 .== 1
was.intermediate = was.hrpnssec3r7 .== 2
was.routine = was.hrpnssec3r7 .== 3
was.total_wealth = was.totwlthr7
was.num_children = was.numchildr7
was.num_adults = was.dvhsizer7 - was.num_children

#
# wealth
#

was.net_housing = was.hpropwr7
was.net_physical = was.hphyswr7
was.total_pensions = was.totpenr7_aggr
was.net_financial = was.hfinwntr7_sum

was_owner = was[was.ten1r7 .<=3,:]

#
# Count housing wealth as 'physical' if recorded as 'renting'.
#
for r in eachrow( was )
    if r.ten1r7 >= 4  # non-owner
        r.net_physical += r.net_housing
        r.net_housing = 0
    end
end