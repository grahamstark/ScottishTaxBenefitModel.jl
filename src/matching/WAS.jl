module WAS

using ..Common 
import ..Model

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
function map_socio_one( socio :: Real ) :: Int
    d = Dict([
        1.1 => 1, # Employers_in_large_organisations is way out WAS vs FRS so amalgamate
        1.2 => 1,
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

function model_map_socio( soc ) :: Vector{Int}
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

function map_empstat( ie :: Int ) :: Vector{Int}
    return map_empstat( ie, 9997 )
end

"""
Create a WAS subset with marrstat, tenure, etc. mapped to same categories as FRS
"""
function create_subset(; outfilename="wave_7_subset.tab" )
    wasp = CSV.File( "/mnt/data/was/UKDA-7215-tab/tab/round_7_person_eul_june_2022.tab"; missingstring=["", " "]) |> DataFrame
    wash = CSV.File( "/mnt/data/was/UKDA-7215-tab/tab/round_7_hhold_eul_march_2022.tab"; missingstring=["", " "]) |> DataFrame
    rename!(wasp,lowercase.(names(wasp)))
    rename!(wash,lowercase.(names(wash)))
    wasj = innerjoin( wasp, wash; on=:caser7,makeunique=true)
    wasj.p_flag4r7 = coalesce.(wasj.p_flag4r7, -1)
    was = wasj[((wasj.p_flag4r7 .== 1) .| (wasj.p_flag4r7 .== 3)),:]
    # @assert size( was )[1] == size( wash )[1] " sizes don't match $(size( was )) $(size( wash ))" # selected 1 per hh, missed no hhs
    # this breaks! (17532, 5534) (17534, 852) - 2 missing, but that's OK??
    wpy=365.25/7

    subwas = DataFrame()
    subwas.case = was.caser7
    subwas.year = was.yearr7
    subwas.datayear .= 7 # wave 7
    subwas.month = was.monthr7
    subwas.q = div.(subwas.month .- 1, 3 ) .+ 1 
    subwas.bedrooms = was.hbedrmr7
    subwas.region = Int.(regionmap_one.(was.gorr7))
    subwas.age_head = was.hrpdvage8r7
    subwas.weekly_gross_income = was.dvtotgirr7./wpy
    subwas.tenure = tenuremap_one( was )
    subwas.accom = accommap_one( was )

    subwas.household_type = was.hholdtyper7
    subwas.occupation =  was.hrpnssec3r7
    subwas.total_wealth = was.totwlthr7
    subwas.num_children = was.numchildr7
    subwas.num_adults = was.dvhsizer7 - subwas.num_children
    subwas.sex_head = was.hrpsexr7
    subwas.empstat_head = was.hrpempstat2r7 
    subwas.socio_economic_head = map_socio_one.( was.nssec8r7 ) # hrpnssec3r7 
    subwas.marital_status_head = Int.(map_marital_one.(was.hrpdvmrdfr7))

    subwas.any_wages = was.dvgiempr7_aggr .> 0
    subwas.any_selfemp = was.dvgiser7_aggr .> 0
    subwas.any_pension_income = was.dvpinpvalr7_aggr .> 0
    subwas.has_degree = was.hrpedlevelr7 .== 1
    
    subwas.net_housing = was.hpropwr7
    subwas.net_physical = was.hphyswr7
    subwas.total_pensions = was.totpenr7_aggr
    subwas.net_financial = was.hfinwntr7_sum
    subwas.total_value_of_other_property = was.othpropvalr7_sum
    subwas.total_financial_liabilities = was.hfinlr7_excslc_aggr #   Hhold value of financial liabilities
    subwas.total_household_wealth = was.totwlthr7
    for row in eachrow( subwas )
        row.weekly_gross_income = Uprating.uprate( 
            row.weekly_gross_income,
            row.year, 
            row.q, 
            Uprating.upr_nominal_gdp )
    end
    subwas.house_price = was.hvaluer7
    CSV.write( "data/$(outfilename)", subwas; delim='\t')
    return subwas
end
# HFINWNTR7_exSLC_Sum


function uprate_was!( was :: DataFrame )

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
function tenuremap_one( wasf :: DataFrame ) :: Vector{Int}
    nrows,ncols = size( wasf )
    out = fill(0,nrows)
    row = 0
    for was in eachrow( wasf )
        row += 1
        # ten1r7_i since 2 "-8s" so use imputed version
        @assert was.ten1r7_i in 1:6 "was.ten1r7 out of range $(was.ten1r7)"
        frsten = if was.ten1r7_i == 1 # o-outright
            Owned_outright 
        elseif was.ten1r7_i in 2:3
            Mortgaged_Or_Shared
        elseif was.ten1r7_i == 4 # rented
            if was.llordr7 == 1
                Council_Rented
            elseif was.llordr7 == 2
                Housing_Association
            elseif was.llordr7 in 3:7
                if was.furnr7 in 1:2 # furnished, inc part
                    Private_Rented_Furnished
                elseif was.furnr7 == 3
                    Private_Rented_Unfurnished
                else
                    @assert false "was.furnr7 out-of-range $(was.furnr7)"
                end
            else
                @assert false "was.llord7 out of range $(was.llord7)"
            end
        elseif was.ten1r7_i == 5
            Rent_free
        elseif was.ten1r7_i == 6
            Squats
        end
        out[row] = min( Int( frsten ), 7 ) # compress squat/rentfree
        @assert out[row] in 1:7
    end # each row
    out
end

function tenuremap( was :: DataFrame  ) :: Vector{Int}
    out = tenuremap_one( was )
    return lcf_tenuremap( out, 9997 )
end

function accommap_one( wasf :: DataFrame ) :: Vector{Int}
    nrows,ncols = size( wasf )
    out = fill(0,nrows)
    row = 0
    for was in eachrow( wasf )
        row += 1
        out[row] = if was.accomr7 == 1 # house
            if was.hsetyper7 in 1:3
                was.hsetyper7
            else
                @assert false "unmapped was.hsetyper7 $(was.hsetyper7)"
            end
        elseif was.accomr7 == 2 # flat
            if was.flttypr7 == 1
                4
            elseif was.flttypr7 == 2
                5
            else
                @assert false "unmapped was.flttypr7 $(was.flttypr7)"
            end
        elseif was.accomr7 == 3 # room/rooms ? how could this be true of a household?
            6
        elseif was.accomr7 == 4
            6
        else
            @assert false "unmapped was.accomr7 $(was.accomr7)"
        end
        @assert out[row] in 1:6 "out is $out"
    end
    out
end 


"""
output:
lcf     | 2020 | dvhh            | A116          | 1     | Whole house,bungalow-detached | Whole_house_bungalow_detached
lcf     | 2020 | dvhh            | A116          | 2     | Whole hse,bungalow-semi-dtchd | Whole_hse_bungalow_semi_dtchd
lcf     | 2020 | dvhh            | A116          | 3     | Whole house,bungalow-terraced | Whole_house_bungalow_terraced
lcf     | 2020 | dvhh            | A116          | 4     | Purpose-built flat maisonette | Purpose_built_flat_maisonette
lcf     | 2020 | dvhh            | A116          | 5     | Part of house converted flat  | Part_of_house_converted_flat
lcf     | 2020 | dvhh            | A116          | 6     | Others                        | Others



"""
function accommap( was :: DataFrame ) :: Vector{Int}
    out = accommap_one( was )
    return lcf_accmap.( out, 9997 )
end



function frs_age_map( hhagegr4 :: Int, default=9998 ) :: Vector{Int}
    out = fill( default, 3 )
    out[1] = hhagegr4
    if hhagegr4 in 1:3 # u35
        out[2] = 1
    elseif hhagegr4 in 4:5 # 35-64
        out[2] = 2
    else
        out[2] = 3
    end
    out
end

function model_age_grp( age :: Int ) :: Vector{Int}
    out = if age < 16 # can't happen?
        1
    elseif age < 25
        2
    elseif age < 35
        3
    elseif age < 45
        4
    elseif age < 55
        5
    elseif age < 65
        6
    elseif age < 75
        7
    elseif age >= 75
        8
    end
    return frs_age_map( out, 9998 )
end



"""
We're JUST going to use the model dataset here
"""
function model_match( 
    hh :: Household, 
    was :: DataFrameRow ) :: Tuple
    t = 0.0
    incdiff = 0.0
    hrp = get_head( hh )
    t += score( model_age_grp( hrp.age ), frs_age_map(was.age_head, 9997 )) # ok
    t += region_score_scotland( 
        model_regionmap( hh.region ), 
        frs_regionmap( was.region, 9997 ),
        [1.5,0.8,0.3,0.2,0.1]) 
    t += score( model_accommap( hh.dwelling ), lcf_accmap( was.accom, 9997 ))
    t += score( model_tenuremap( hh.tenure ),  frs_tenuremap( was.tenure, 9997 ))
    t += score( model_map_socio( hrp.socio_economic_grouping ),  
        map_socio( was.socio_economic_head, 9997 ))
    t += score( model_map_empstat( hrp.employment_status ), map_empstat( was.empstat_head, 9997 ))
    t += Int(hrp.sex) == was.sex_head ? 1 : 0
    t += score( model_map_marital(hrp.marital_status ), map_marital( was.marital_status_head, 9997 ))
    # t += score( hh.data_year, was.year )
    any_wages, any_selfemp, any_pension_income, has_female_adult, income = do_hh_sums( hh )

    #     hh_composition 
    t += any_wages == was.any_wages ? 1 : 0
    t += any_selfemp ==  was.any_selfemp ? 1 : 0
    t += any_pension_income == was.any_pension_income ? 1 : 0
     
    t += highqual_degree_equiv(hrp.highest_qualification) == was.has_degree ? 1 : 0

    t += score( person_map(num_children( hh ),9999), person_map(was.num_children,9997 ))
    t += score( person_map(num_adults( hh ),9999), person_map(was.num_adults,9997))
    incdiff = compare_income( income, was.weekly_gross_income )
    return t, incdiff
end

end