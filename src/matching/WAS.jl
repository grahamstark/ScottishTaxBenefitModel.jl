module WAS

using ..Common 
import ..Model

using ScottishTaxBenefitModel
using .RunSettings
using .Definitions
using .ModelHousehold
using .Utils

import ScottishTaxBenefitModel.MatchingLibs.Common
import ScottishTaxBenefitModel.MatchingLibs.Common: MatchingLocation
import ScottishTaxBenefitModel.MatchingLibs.Common: score as cscore
import ScottishTaxBenefitModel.MatchingLibs.Model as model
using CSV,
    DataFrames,
    Measures,
    StatsBase,
    ArgCheck

"""

from:

    Pos. = 42Variable = hholdtyper7Variable label = DV - Type of household
    This variable is    numeric, the SPSS measurement level is NOMINAL
    Value label information for hholdtyper7
    Value = 1.0Label = Single person over new SPA
    Value = 2.0Label = Single person below new SPA
    Value = 3.0Label = Couple over new SPA
    Value = 4.0Label = Couple below new SPA
    Value = 5.0Label = Couple, one over ans one below new SPA
    Value = 6.0Label = Couple and dependent children
    Value = 7.0Label = Couple and non-dependent children only
    Value = 8.0Label = Lone parent and dependent children
    Value = 9.0Label = Lone parent and non-dependent children only
    Value = 10.0Label = More than one family, other household types
    Value = -9.0Label = Not asked / applicable
    Value = -8.0Label = Don't know/ Refusal

to:


@enum HouseholdComposition1 begin
    single_person = 1,1
    single_parent = 2,2
    couple_wo_children = 3,1 
    couple_w_children = 4,2 
    mbus_wo_children = 5,3 
    mbus_w_children = 5,3
 end 
"""
function map_household_composition( htype :: Int )::Vector{Int}
    if htype <= 0
        return rand(Int,2)
    end
    h1, h2 = if htype in [1,2]
        1,1
    elseif htype in [8,9]
        2,2
    elseif htype in [3,4,5]
        3,1
    elseif htype in [6,7,8]
        4,2
    elseif htype in [10]
        5,3
    end
    return [h1,h2]
end


function model_was_map_household_composition( htype :: HouseholdComposition1 ) :: Vector{Int}
    h1, h2 = if htype == single_person
        1,1
    elseif htype == single_parent
        2,1
    elseif htype == couple_wo_children
        3,1
    elseif htype == couple_w_children
        4,2 
    elseif htype == mbus_wo_children
        5,3
    elseif htype == mbus_w_children
        5,3
    end
    return [h1,h2]
end



"""
    Value = -9.0	Label = Not asked / applicable
	Value = -8.0	Label = Don't know/ Refusal
	Value = 1.1	Label = Large employers and higher managerial occupations
	Value = 1.2	Label = Higher professional occupations
	Value = 2.0	Label = Lower managerial and professional occupations
	Value = 3.0	Label = Intermediate occupations
	Value = 4.0	Label = Small employers and own account workers
	Value = 5.0	Label = Lower supervisory and technical occupations
	Value = 6.0	Label = Semi-routine occupations
	Value = 7.0	Label = Routine occupations
	Value = 8.0	Label = Never worked and long-term unemployed
	Value = 97.0 Label = Not classified
"""
function map_socio_one( socio :: Union{Real,Missing} ) :: Int
    if ismissing( socio )
        return 9
    end
    d = Dict([
        1.1 => 1, # Employers_in_large_organisations is way out WAS vs FRS so amalgamate
        1.2 => 1,
        1 => 1,
        2 => 2,
        3 => 3,
        4 => 4,
        5 => 5,
        6 => 6,
        7 => 7,
        8 => 8,
        9 => 9,
        97=> 9,
        -8=> 9,
        -9=> 9])
    return d[socio]
end

function map_socio( socio :: Real ) :: Vector{Int}
    out = map_socio_one( socio )
    return map_socio( out, 9997 )
end 

function model_was_map_socio( soc ) :: Vector{Int}
    socio = Int( soc )
    out = if socio in [1,2,3] # Employers_in_large_organisations = 0.099% FRS 5.7% WAS so amalgamate
        1
    elseif socio in [4]
        2
    elseif socio in [5,6,7]
        3
    elseif socio in [8,9]
        4
    elseif socio in [10]
        5
    elseif socio in [11,12]
        6
    elseif socio in [13]
        7
    elseif socio in [14,15]
        8
    elseif socio in [16,17,-1]
        9
    else
        @assert false "socio out of range $socio"
    end
    return map_socio( out)
end

#=
1 1.1 => 1
2 1.2 => 2,3
3 2.0 => 4
4 3.0 => 5,6,7
5 4.0 => 8,9
6 5.0 => 10
7 6.0 => 11,12,
8 7.0 => 13,
9 8.0 => 14,15
10 97,-8,-9 => 16,17,-1
=#

"""
Value = 1.0	Label = North East
	Value = 2.0	Label = North West
	Value = 4.0	Label = Yorkshire and The Humber
	Value = 5.0	Label = East Midlands
	Value = 6.0	Label = West Midlands
	Value = 7.0	Label = East of England
	Value = 8.0	Label = London
	Value = 9.0	Label = South East
	Value = 10.0	Label = South West
	Value = 11.0	Label = Wales
	Value = 12.0	Label = Scotland
"""
function regionmap_one( wasreg :: Int ) :: Standard_Region
    d = Dict( [
        1 => North_East, # = 112000001
        2 => North_West, # = 112000002
        4 => Yorks_and_the_Humber, # = 112000003
        5 => East_Midlands, # = 112000004
        6 => West_Midlands, # = 112000005
        7 => East_of_England, # = 112000006
        8 => London, # = 112000007
        9 => South_East, # = 112000008
        10 => South_West, # = 112000009
        12 => Scotland, # = 299999999
        11 => Wales ] )  # = 399999999
    return d[ wasreg ]
end

"""
Just for fuckery WAS and LCF these numbers subtly different - was ommits 4
"""
function regionmap( wasreg :: Int ) :: Vector{Int}
    out = regionmap_one(wasreg)
    return frs_regionmap( out, 9997 )
end

function map_region( wasreg :: Int ):: Vector{Int}
    return Common.map_region( wasreg )
end

"""
Value = -9.0	Label = Not asked / applicable
	Value = -8.0	Label = Don't know/ Refusal
	Value = 1.0	Label = Married
	Value = 2.0	Label = Cohabiting
	Value = 3.0	Label = Single
	Value = 4.0	Label = Widowed
	Value = 5.0	Label = Divorced
	Value = 6.0	Label = Separated
	Value = 7.0	Label = Same-sex couple
	Value = 8.0	Label = Civil Partner
	Value = 9.0	Label = Former / separated Civil Partner
"""
function map_marital_one( mar :: Int ) :: Marital_Status
    out :: Marital_Status = if mar in [1,7,8]
        Married_or_Civil_Partnership 
    elseif mar in 2
        Cohabiting
    elseif mar in 3
        Single
    elseif mar in 4
        Widowed
    elseif mar in [6,9]
        Separated
    elseif mar in [5]
        Divorced_or_Civil_Partnership_dissolved
    elseif mar in [-9,-8]
        Missing_Marital_Status
    else
        @assert false "unmapped mar $mar"
    end
    return out
end

"""
Pos. = 54Variable = hrpempstat2r7Variable label = Employment status of HRP or partner
    This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for hrpempstat2r7
    Value = 1.0Label = Employee
    Value = 2.0Label = Self-employed
    Value = 3.0Label = Unemployed
    Value = 4.0Label = Student
    Value = 5.0Label = Looking after family home
    Value = 6.0Label = Sick or disabled
    Value = 7.0Label = Retired
    Value = 8.0Label = Other
    Value = -9.0Label = Not asked / applicableValue = -8.0Label = Don't know/ Refusal

into:

@enum ILO_Employment begin  # mapped from empstati
    Missing_ILO_Employment = -1
    Full_time_Employee = 1
    Part_time_Employee = 2
    Full_time_Self_Employed = 3
    Part_time_Self_Employed = 4
    Unemployed = 5
    Retired = 6
    Student = 7
    Looking_after_family_or_home = 8
    Permanently_sick_or_disabled = 9
    Temporarily_sick_or_injured = 10
    Other_Inactive = 11
 end
 
"""
function map_empstat( ie :: Union{Int,Missing} ) :: Vector{Int}
    if(ismissing(ie))||(ie < 0)
        return rand(Int,2)
    end
    i2 = if ie <= 3
        1
    else 
        2
    end
    return [ie, i2]
end

function model_was_map_empstat( empstat :: ILO_Employment ):: Vector{Int}
    i1, i2 = if empstat == Missing_ILO_Employment 
        rand(Int), rand(Int)
    elseif empstat in [Full_time_Employee,Part_time_Employee]
        1,1
    elseif empstat in [Full_time_Self_Employed,Part_time_Self_Employed]
        2,1
    elseif empstat == Unemployed 
        3,1
    elseif empstat == Retired 
        7,2
    elseif empstat == Student
        4,2
    elseif empstat == Looking_after_family_or_home
        5,2
    elseif empstat == Permanently_sick_or_disabled
        6,2
    elseif empstat == Temporarily_sick_or_injured 
        6,2
    elseif empstat == Other_Inactive 
        8,2
    end
    return [i1,i2]
end


"""
was age group for hrp

Pos. = 88	Variable = HRPDVAge8r7	Variable label = Grouped Age of HRP (8 categories)
This variable is    numeric, the SPSS measurement level is NOMINAL
	Value label information for HRPDVAge8r7
	Value = -9.0	Label = Don t know
	Value = -8.0	Label = Refusal
	Value = -7.0	Label = Does not apply
	Value = -6.0	Label = Error/partial
	Value = 1.0	Label = 0 to 15
	Value = 2.0	Label = 16 to 24
	Value = 3.0	Label = 25 to 34
	Value = 4.0	Label = 35 to 44
	Value = 5.0	Label = 45 to 54
	Value = 6.0	Label = 55 to 64
	Value = 7.0	Label = 65 to 74
	Value = 8.0	Label = 75 and over


"""
function map_age_bands( age:: Int ) :: Vector{Int}
    @argcheck age in 1:13
    out = fill( 0, 2 )
    out[1] = age
    if age<= 5
        out[2] = 1
    elseif age<= 13
        out[2] = 2
    else
        @assert false "mapping $age not in 1:13"
    end
    out
end

"""
into

	Value = 1.0	Label = 0 to 15
	Value = 2.0	Label = 16 to 24
	Value = 3.0	Label = 25 to 34
	Value = 4.0	Label = 35 to 44
	Value = 5.0	Label = 45 to 54
	Value = 6.0	Label = 55 to 64
	Value = 7.0	Label = 65 to 74
	Value = 8.0	Label = 75 and over

"""
function model_was_map_age_bands( age :: Int ) :: Vector{Int}
    b = if age <= 15
        1
    elseif age <= 24
        2
    elseif age <= 34
        3
    elseif age <= 44
        4
    elseif age <= 54
        5
    elseif age <= 64
        6
    elseif age <= 74
        7
    else
        8
    end
    return map_age_bands(b)
end

function map_socio( socio :: Int ) :: Vector{Int}
    return Common.map_socio( socio )
end

"""

"""
function map_marital( marital_status_head :: Int )::Vector{Int}
    return Common.map_marital( marital_status_head )
end

"""
Map to FRS i.e 
 Missing_Tenure_Type = -1
   Council_Rented = 1
   Housing_Association = 2
   Private_Rented_Unfurnished = 3
   Private_Rented_Furnished = 4
   Mortgaged_Or_Shared = 5
   Owned_outright = 6
   Rent_free/Squat = 7
"""
function map_tenure_one( wasf :: DataFrame ) :: Vector{Int}
    nrows,ncols = size( wasf )
    out = fill(0,nrows)
    row = 0
    for was in eachrow( wasf )
        row += 1
        # ten1r7_i since 2 "-8s" so use imputed version
        @assert was.ten1_i in 1:6 "was.ten1r7 out of range $(was.ten1r7)"
        frsten = if was.ten1_i == 1 # o-outright
            Owned_outright 
        elseif was.ten1_i in 2:3
            Mortgaged_Or_Shared
        elseif was.ten1_i == 4 # rented
            if ismissing(was.llord) || (was.llord == 1) # !!! 1 missing wave 1
                Council_Rented
            elseif was.llord == 2
                Housing_Association
            elseif was.llord in 3:7
                if ismissing(was.furn) || (was.furn in 1:2) # furnished, inc part 1 missing case w2
                    Private_Rented_Furnished
                elseif was.furn == 3
                    Private_Rented_Unfurnished
                else
                    @assert false "was.furnr7 out-of-range $(was.furn)"
                end
            else
                @assert false "was.llord out of range $(was.llord)"
            end
        elseif was.ten1_i == 5
            Rent_free
        elseif was.ten1_i == 6
            Squats
        end
        out[row] = min( Int( frsten ), 7 ) # compress squat/rentfree
        @assert out[row] in 1:7
    end # each row
    out
end

"""

"""
function map_tenure( ten :: Int  ) :: Vector{Int}
    return Common.map_tenure( ten )
end

"""
into: 
1,1 detatched
2,1 semi
3,1 terrace
4,2 purpose-built flat
5,2 flat conversion
6,3 other
"""
function map_accom( accom :: Int ) :: Vector{Int}
@argcheck accom in 1:6
    return Common.map_accom( accom )
end

function model_to_was_map_accom(dwelling::DwellingType)::Vector{Int}
    id = Int(dwelling)
    if id < 0
        return rand(Int,2)
    end
    return Common.map_accom( min(6, id ))
end

"""
Fill a whole vector with accomodation type, in the standard 6 class
1 detatched
2 semi
3 terrace
4 purpose-built flat
5 flat conversion
6 other
"""
function map_accom_one( wasf :: DataFrame ) :: Vector{Int}
    nrows,ncols = size( wasf )
    out = fill(0,nrows)
    row = 0
    for was in eachrow( wasf )
        row += 1
        out[row] = if ismissing( was.accom ) || (was.accom == 1) # house
            if ismissing( was.hsetype )
                rand(1:3)
            elseif was.hsetype in 1:3
                was.hsetype
            else
                @assert false "unmapped was.hsetype $(was.hsetype)"
            end
        elseif was.accom == 2 # flat
            if ismissing(was.flttyp) || (was.flttyp == 1) # !! 1 case !! wave 1
                4
            elseif was.flttyp == 2
                5
            else
                @assert false "unmapped was.flttyp $(was.flttyp)"
            end
        elseif was.accom == 3 # room/rooms ? how could this be true of a household?
            6
        elseif was.accom == 4
            6
        else
            @assert false "unmapped was.accom $(was.accom)"
        end
        @assert out[row] in 1:6 "out is $out"
    end
    out
end 

#=
# FIXME _na -> missing ? 
@enum DwellingType begin
    dwell_na = -1
    detatched = 1
    semi_detached = 2
    terraced = 3
    flat_or_maisonette = 4
    converted_flat = 5
    caravan = 6
    other_dwelling = 7
 end
 =#
 
DIR = "/mnt/data/was/"

"""
produce 1 replace pair, deleting e.g. 'w2' or 'r1' from 1 name.
"""
function wrem( s::AbstractString, wave::Integer )::Union{Pair,Missing}
    if ! isnothing(match( r"case.*", s ))
        return missing
    end
    m =  "(.*?)[w|r]$(wave)(.*)"
    re = Regex( m )
    rep = replace( s, re=> s"\1\2" )
    if (rep != s)
        return s=>rep
    else
        return missing
    end
end

function sum_rem( s::AbstractString )::Union{Pair,Missing}
    rep = replace(s, r"(.*)_sum"=>s"\1_aggr")
    if rep != s
        return s=>rep
    else
        return missing
    end
end

function duppairvals( pairs )::AbstractSet
    s = Set()
    dups = Set()
    for p in pairs
        if p[2] in s
            push!( dups, p[1] )
        else
            push!( s, p[2] )
        end
    end
    dups
end

function duppairvals( pairs, names )::AbstractSet
    dups = Set()
    for p in pairs
        if p[2] in names
            push!( dups, p[1] )
        end
    end
    dups
end

function removedups( pairs, dels )::AbstractVector{Pair}
    out = Pair[]
    for p in pairs
        if ! (p[1] in dels)
            push!(out,p)
        end
    end
    out
end



function removedups( pairs )
    dels = duppairvals( pairs )
    return removedups( pairs, dels )
end

"""
Attempt to rename each wave of WAS consistently, deleting e.g. 'w2' or 'r1' from all names.
"""
function renwas!( df::DataFrame, wave::Integer, is_hh::Bool )
    n = names(df)
    # make a list of replacements
    rens = wrem.(n, wave) |> skipmissing |> collect |> removedups 
    # @show sort(rens)
    # sort(unique(collect(skipmissing())))
    if length(rens) > 0
        rename!( df, rens... )
    end
    # hacky rename of wave 
    if wave <= 4
        if is_hh
            rename!(df, "hrpdvage9"=>"hrpdvage")
        end
    else
        if is_hh
            rename!( df, "hrpdvage8"=>"hrpdvage")
        end
    end
    rens = sum_rem.( names(df)) |> skipmissing |> collect |> removedups
    # @show rens
    wrong_renames = duppairvals( rens, names(df) )
    # @show wrong_renames
    rens = removedups( rens, wrong_renames)
    # @show sort(rens)
    if length(rens) > 0
        rename!(df, rens... )
    end
end

const WAS_WAVE_HH=[
    "was_wave_1_hhold_eul_final_jan_2020.tab",
    "was_wave_2_hhold_eul_feb_2020.tab",
    "was_wave_3_hh_eul_march_2020.tab",
    "was_wave_4_hhold_eul_march_2020.tab",
    "was_wave_5_hhold_eul_sept_2020.tab",
    "was_round_6_hhold_eul_april_2022.tab",
    "was_round_7_hhold_eul_march_2022.tab",
    "was_round_8_hhold_eul_may_2025_230525.tab"]

const WAS_WAVE_PERS=[
    "was_wave_1_person_eul_nov_2020.tab",
    "was_wave_2_person_eul_nov_2020.tab",
    "was_wave_3_person_eul_oct_2020.tab",
    "was_wave_4_person_eul_oct_2020.tab",
    "was_wave_5_person_eul_oct_2020.tab",
    "was_round_6_person_eul_april_2022.tab",
    "was_round_7_person_eul_june_2022.tab",
    "was_round_8_person_eul_may_2025_230525.tab"]

function remove_dup_wave6rs_and_ws!( df::DataFrame, wave )
    n = names(df)
    wrex = Regex( "(.+)w$(wave)(.*)")
    rrex = Regex( "(.+)r$(wave)(.*)")
    r5s = filter( x->match(r".*[r|w]5$",x)!==nothing, n)
    ws = []
    rs = []    
    for i in eachindex(n)
        if isnothing(match( r"case.*", n[i]))
            m = match(wrex,n[i])
            if ! isnothing(m)
                push!( ws, (m[1],m[2]))
            end
            m = match(rrex,n[i])
            if ! isnothing(m)
                push!( rs, (m[1],m[2]))
            end
        end
    end
    killa = intersect( ws,rs )
    kills = []
    for k in killa
        push!( kills, "$(k[1])r$(wave)$(k[2])")
    end
    # kills = union( kills, r5s)
    # @show kills
    select!( df, Not( kills ))
end

function load_one_was( wave :: Int )    
    wasp = CSV.File( "$(DIR)UKDA-7215-tab/tab/$(WAS_WAVE_PERS[wave])"; missingstring=["", " ","-6","-7","-8","-9"]) |> DataFrame
    wash = CSV.File( "$(DIR)UKDA-7215-tab/tab/$(WAS_WAVE_HH[wave])"; missingstring=["", " ","-6","-7","-8","-9"]) |> DataFrame
    rename!(lowercase,wasp)
    rename!(lowercase,wash)
    if wave == 6
        # dup hack rf and rfw1 - drop rf
        println( "deleting rf")
        select!(wasp, Not([:rf,:rs]))
        remove_dup_wave6rs_and_ws!( wasp, 6 )
        remove_dup_wave6rs_and_ws!( wash, 6 )
        remove_dup_wave6rs_and_ws!( wasp, 5 )
        remove_dup_wave6rs_and_ws!( wash, 5 )
    end
    renwas!( wasp, wave, false )
    renwas!( wash, wave, true )    
    casesym = if wave <= 5
        Symbol("casew$wave" )
    else
        Symbol("caser$wave" )
    end
    wasj = innerjoin( wash, wasp ; on=casesym,makeunique=true)
    wasj.p_flag4 = coalesce.(wasj.p_flag4, -1)
    was = wasj[((wasj.p_flag4 .== 1) .| (wasj.p_flag4 .== 3)),:]
    was.hid = 10_000_000 .* wave .+ was[!,casesym]
    sort!(was,[:hid])
    if wave == 6 # spurious dup row
        deleteat!( was, findall( was.caser6.==14625 )[2])
    end
    was
end

"""
Create a WAS subset with marrstat, tenure, etc. mapped to same categories as FRS
"""
function create_subset(
    was :: DataFrame,
    wave :: Int )::Tuple
    println( "on wave $wave ")
    subwas = DataFrame()
    casesym = if wave <= 5
        Symbol("casew$wave" )
    else
        Symbol("caser$wave" )
    end
    nrows, ncols = size(was)

    subwas.wave = fill(wave,nrows)
    subwas.case = was[!,casesym]
    subwas.year = was.year
    subwas.uid = 10_000_000 .* wave .+ was[!,casesym]
    subwas.all_waves_id = fill(0,nrows)
    subwas.weight = if wave == 1
            was.xs_wgt
        elseif wave == 2
            was.xs_calwgt
        elseif wave == 3
            was.xswgt
        else
            was.xshhwgt
        end
    subwas.weight = Float64.( subwas.weight )
    subwas.datayear .= wave # wave 7
    subwas.month = was.month
    subwas.q = div.(subwas.month .- 1, 3 ) .+ 1 
    subwas.bedrooms = was.hbedrm
    subwas.region = Int.(regionmap_one.(was.gor))
    # 9 age vals in wave 1 up to 85; 8 vals up to 75 in the rest
    subwas.age_head = min.(was.hrpdvage, 8 ) # 75+ waves 2- 85+ wave 1
    if wave >= 3
        subwas.weekly_gross_income = Float64.(coalesce.(was.dvtotgir./WEEKS_PER_YEAR,0.0))
    else
        subwas.weekly_gross_income = zeros(nrows)
    end
    subwas.tenure = map_tenure_one( was )
    subwas.accom = map_accom_one( was )

    subwas.household_type = was.hholdtype
    subwas.occupation =  was.hrpnssec3
    subwas.num_children = was.numchild
    subwas.num_adults = was.dvhsize - subwas.num_children
    subwas.sex_head = was.hrpsex
    subwas.empstat_head = was.hrpempstat2
    subwas.socio_economic_head = map_socio_one.( was.nssec8 ) # hrpnssec3r7 
    subwas.marital_status_head = Int.(map_marital_one.(was.hrpdvmrdf))

    if wave >= 3
        subwas.any_wages = was.dvgiemp_aggr .> 0
        subwas.any_selfemp = was.dvgise_aggr .> 0
        subwas.any_pension_income = if wave < 8
            was.dvpinpval_aggr .> 0
        else
            was.dvpinpval_old_aggr .> 0
        end
        subwas.has_degree = was.hrpedlevel .== 1
        if wave >= 5
            subwas.total_value_of_other_property = was.othpropval_aggr
        else 
            subwas.total_value_of_other_property = zeros(nrows)
        end
    else
        subwas.any_wages = zeros(nrows)
        subwas.any_selfemp = zeros(nrows)
        subwas.any_pension_income = zeros(nrows)
        subwas.has_degree = zeros(nrows)
        subwas.total_value_of_other_property = zeros(nrows)
    end
    subwas.net_housing = was.hpropw
    subwas.net_physical = was.hphysw
    subwas.total_pensions = if wave < 8 
        was.totpen_aggr
    else
        was.totalpen_aggr
    end
    subwas.net_financial = was.hfinwnt_aggr
    if wave >= 7
        subwas.total_financial_liabilities = was.hfinl_excslc_aggr #   Hhold value of financial liabilities
    else
        subwas.total_financial_liabilities = zeros(nrows)
    end
    subwas.total_household_wealth = if wave <= 7
        was.totwlth
    else
        was.totalwlth
    end
    subwas.total_household_wealth = Float64.(coalesce.(subwas.total_household_wealth,0.0))
    subwas.total_wealth = subwas.total_household_wealth
    if wave >= 3
        for row in eachrow( subwas )
            row.weekly_gross_income = Uprating.uprate( 
                row.weekly_gross_income,
                row.year, 
                row.q, 
                Uprating.upr_nominal_gdp )
        end
    end
    subwas.house_price = was.hvalue
    # deciles of total wealth
    subwas.total_wealth_decile = fill(0,nrows)
    insert_quantile!( 
        subwas; 
        measure_col=:total_wealth, 
        quant_col=:total_wealth_decile )
    return subwas, was
end

function model_row_match( 
    hh :: Household, wass :: DataFrameRow ) :: MatchingLocation
    head = get_head(hh)
    cts = model.counts_for_match( hh )   
    t = 0.0
    t += cscore( map_tenure(wass.tenure), model.map_tenure( hh.tenure ))
    t += cscore( map_accom(wass.accom), model_to_was_map_accom(hh.dwelling)) 
    # bedrooms to common
    t += cscore( Common.map_bedrooms(wass.bedrooms), 
        Common.map_bedrooms( hh.bedrooms ))
    t += cscore( map_household_composition(wass.household_type), 
                model_was_map_household_composition( household_composition_1(hh)))
    t += cscore( wass.any_wages, cts.any_wages )
    t += cscore( wass.any_pension_income, cts.any_pension_income )  
    t += cscore( wass.any_selfemp, cts.any_selfemp )
    t += cscore( Common.map_total_people( wass.num_adults ), Common.map_total_people(cts.num_adults ))
    t += cscore( Common.map_total_people(wass.num_children ), Common.map_total_people(cts.num_children )) 
    t += cscore( map_age_bands(wass.age_head), model_was_map_age_bands( head.age ))
    t += cscore( map_marital(wass.marital_status_head), model.map_marital( head.marital_status))
    t += cscore( map_socio(wass.socio_economic_head), model_was_map_socio( head.socio_economic_grouping) )
    t += cscore( map_empstat(wass.empstat_head), model_was_map_empstat( head.employment_status))
    t += Common.region_score_scotland( Standard_Region(wass.region))
    incdiff = Common.compare_income( wass.weekly_gross_income, cts.income )
    return  MatchingLocation( wass.case, wass.datayear, t, wass.weekly_gross_income, incdiff ) 
end

#=
# 
=#
function fill_all_waves_ids!( stacked::DataFrame, wass::DataFrame, wave::Int )
    for r in eachrow( wass )
        caseid = if wave >= 6
            Symbol( "caser$wave")
        else
            Symbol( "casew$wave")
        end
        subr = stacked[(stacked.case .== r[caseid]) .& (stacked.wave .== wave),:]
        @assert size( subr )[1] == 1 "$(size( subr )[1]) should always be 1 $(caseid) wave $wave r[caseid]=$(r[caseid])"
        subr = subr[1,:]
        for w in wave:-1:5
            casesym = if wave >= 6
                Symbol("caser$(w)")
            else 
                Symbol("casew$(w)")
            end
            v = r[casesym]
            if( ! ismissing(v))
                stackr = stacked[(stacked.wave .== w) .& (stacked.case.== v),:]
                if size(stackr)[1] == 1
                    # @assert size(stackr)[1] == 1 "w=$w v=$v has size $(size(stackr)[1])"
                    # stackr = stackr[1,:]
                    if stackr[1,:all_waves_id] == 0
                        stackr.all_waves_id .= subr.uid
                        println( "fill_all_waves_ids! setting full id $(stackr.uid),wave $(stackr.wave) to $(stackr[1,:all_waves_id]) ")
                        stacked[(stacked.wave .== w) .& (stacked.case.== v),:all_waves_id] .= subr.uid
                        #stackr
                    end
                else
                    println( "Missing! v=$v w=$w")
                end # unfound
            end # ! is missing
        end # waves 8..5
    end # eachrow(wass)
end # fill_all_waves_ids!

function stack_wass()
    stacked = nothing
    wass = []
    for wave in 1:8
        was = load_one_was( wave )
        subwas, was = create_subset( was, wave )
        push!(wass, was)
        if wave == 1
            stacked = subwas
        else
            stacked = vcat( stacked, subwas )
        end
    end
    # sort( stacked, [:case,:wave])
    stacked, wass
end

end