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

function todfstr( depvar, r )
    DEPVAR = uppercase( depvar )*"_COEFFS"
    s = "const $DEPVAR = DataFrame( [ \n"
    vars = coefnames( r )
    coefs = coef( r )
    n = size(vars)[1]
    for i in 1:n
        vn = rename( vars[i], renames )
        s *= "        \"$vn\"  $(coefs[i]);\n"
    end
    s *= "], [\"var\", \"coef\"] )\n\n"
    s *= "const $(DEPVAR)_TR = unstack($(DEPVAR)[!,[:var,:coef]],:var,:coef)[1,:]\n\n"
    println(s)
end

function ustack( d :: DataFrame )
    unstack(d[!,[1,2]],1,2)[1,:]
    rename!( d, renames )
end

was = CSV.File( "/mnt/data/was/UKDA-7215-tab/tab/was_round_7_hhold_eul_march_2022.tab") |> DataFrame

lcnames = lowercase.(names(was))
rename!( was, lcnames )

wpy=365.25/7

# household reference person only 
was.employee = was.hrpdvecactr7 .== 1
was.selfemp = was.hrpdvecactr7 .== 2
was.unemployed = was.hrpdvecactr7 .== 3  # Unemployed
was.student = was.hrpdvecactr7 .== 4    # Student
was.inactive = in.(was.hrpdvecactr7,[[5,9]])    # Looking after family home
was.sick =  in.(was.hrpdvecactr7, [[6,7]])    # Sick or disabled
was.retired = was.hrpempstat2r7 .== 8     # Retired

was.bedrooms = was.hbedrmr7

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

was.age_u_25  =  was.hrpdvage8r7 .== 2
was.age_25_34 =  was.hrpdvage8r7 .== 3
was.age_35_44 =  was.hrpdvage8r7 .== 4
was.age_45_54 =  was.hrpdvage8r7 .== 5
was.age_55_64 =  was.hrpdvage8r7 .== 6
was.age_65_74 =  was.hrpdvage8r7 .== 7
was.age_75_plus = was.hrpdvage8r7 .== 8
was.weekly_gross_income = was.dvtotgirr7./wpy
was.owner = was.ten1r7 .== 1
was.mortgaged = was.ten1r7 .== 2 .|| was.ten1r7 .== 3
was.renter = was.ten1r7 .>= 4 
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
was.has_pension_wealth = was.total_pensions .> 0 

was_owner = was[was.ten1r7 .<=3,:]
was.is_in_debt = was.net_financial .< 0
was.male = was.hrpsexr7 .== 1
was.female = was.hrpsexr7 .== 2
was = was[was.weekly_gross_income .> 0, :] # drop -ive current incomes



#
# Count housing wealth as 'physical' if recorded as 'renting'.
#
for r in eachrow( was )
    if r.ten1r7 >= 4  # non-owner
        r.net_physical += r.net_housing
        r.net_housing = 0
    end
end