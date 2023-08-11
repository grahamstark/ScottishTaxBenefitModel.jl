using CSV,DataFrames,Measures,StatsBase

function load( path::String, datayear :: Int )::Tuple
    d = CSV.File( path ) |> DataFrame
    ns = lowercase.(names( d ))
    rename!( d, ns )
    rows,cols = size(d)
    d.datayear .= datayear
    return rows,cols,d
end

const NUM_SAMPLES = 20


uprd = CSV.File("/home/graham_s/julia/vw/ScottishTaxBenefitModel/data/prices/indexes/indexes-july-2023.tab"; delim = '\t', comment = "#") |> DataFrame


# 1 years FRS
frsrows,frscols,frshh = load( "/mnt/data/frs/2021/tab/househol.tab",2021)
farows,facols,frsad = load( "/mnt/data/frs/2021/tab/adult.tab", 2021)
frs_hh_pp = innerjoin( frshh, frsad, on=[:sernum,:datayear], makeunique=true )
# fcrows,fccols,frsch = load( "/mnt/data/frs/2021/tab/child.tab", 2021 )

# 3 years lcf
lcfhrows,lcfhcols,lcfhh18 = load( "/mnt/data/lcf/1819/tab/2018_dvhh_ukanon.tab", 2018 )
lcfhrows,lcfhcols,lcfhh19 = load( "/mnt/data/lcf/1920/tab/lcfs_2019_dvhh_ukanon.tab", 2019 )
lcfhrows,lcfhcols,lcfhh20 = load( "/mnt/data/lcf/2021/tab/lcfs_2020_dvhh_ukanon.tab", 2020 )
lcfhh = vcat( lcfhh18, lcfhh19, lcfhh20, cols=:union )

lcfprows,lcpfcols,lcfpers18 = load( "/mnt/data/lcf/1819/tab/2018_dvper_ukanon201819.tab", 2018 )
lcfprows,lcpfcols,lcfpers19 = load( "/mnt/data/lcf/1920/tab/lcfs_2019_dvper_ukanon201920.tab", 2019 )
lcfprows,lcpfcols,lcfpers20 = load( "/mnt/data/lcf/2021/tab/lcfs_2020_dvper_ukanon202021.tab",2020)

lcfpers = vcat( lcfpers18, lcfpers19, lcfpers20, cols=:union )
lcf_hh_pp = innerjoin( lcfhh, lcfpers, on=[:case,:datayear], makeunique=true )

#=
grp_lcf_hh_pp = groupby(lcf_hh_pp,[:datayear,:case])
grp_frs_hh_pp = groupby(frs_hh_pp,[:datayear,:sernum])
lcfhh.thing .= 0
for i in grp_lcf_hh_pp 
    icase = i[1,:case]; 
    println(icase)
    lcfhh[lcfhh.case .== icase,:thing] .= sum( i.a200 )
end
=#

lcfhh.any_wages .= lcfhh.p356p .> 0
frshh.any_wages .= frshh.hearns .> 0

lcfhh.any_pension_income .= lcfhh.p364p .> 0
frshh.any_pension_income .= frshh.hpeninc .> 0

lcfhh.any_selfemp .= lcfhh.p320p .!= 0
frshh.any_selfemp .= frshh.hseinc .!= 0 

lcfhh.hrp_unemployed .= lcfhh.p304 .== 1
frshh.hrp_unemployed .= frshh.emp .== 1

lcfhh.num_children = lcfhh.a040 + lcfhh.a041 + lcfhh.a042
frshh.num_children = frshh.depchldh # DEPCHLDH

frshh.hrp_non_white = frshh.hheth .!= 1
# LCF case ids of non white HRPs - convoluted; see: 
# https://stackoverflow.com/questions/51046247/broadcast-version-of-in-function-or-in-operator
lcf_nonwhitepids = lcf_hh_pp[(lcf_hh_pp.a012p .∈ (["10","2","3","4"],)).&(lcf_hh_pp.a003 .== 1),:case]
lcfhh.hrp_non_white .= 0
lcfhh[lcfhh.case .∈ (lcf_nonwhitepids,),:hrp_non_white] .= 1

lcfhh.num_people = lcfhh.a049
frshh.num_people = frshh.adulth + frshh.num_children

within(x;min=min,max=max) = if x < min min elseif x > max max else x end

const TOPCODE = 2420.03

frshh.income = within.( frshh.hhinc, min=0, max=TOPCODE )
lcfhh.income = lcfhh.p344p

# not possible in lcf???
lcfhh.any_disabled .= 0
frshh.any_disabled = (frshh.diswhha1 + frshh.diswhhc1) .> 0 #DISWHHA1 DISWHHC1

lcf_femalepids = lcf_hh_pp[(lcf_hh_pp.a004 .== 2),:case]
lcfhh.has_female_adult .= 0
lcfhh[lcfhh.case .∈ (lcf_femalepids,),:has_female_adult] .= 1

frshh.has_female_adult .= 0
frs_femalepids = frs_hh_pp[(frs_hh_pp.sex .== 2),:sernum]
frshh[frshh.sernum .∈ (frs_femalepids,),:has_female_adult] .= 1

struct FRSLocation
    hid :: BigInt
    datayear :: Int
    score :: Float64
end

struct LCFLocation
    case :: Int
    datayear :: Int
    score :: Float64
    income :: Float64
    incdiff :: Float64
end

#=
 frs     | 2020 | househol | TENTYP2       | 1     | LA / New Town / NIHE / Council rented                 | LA__or__New_Town__or__NIHE__or__Council_rented
 frs     | 2020 | househol | TENTYP2       | 2     | Housing Association / Co-Op / Trust rented            | Housing_Association__or__Co_Op__or__Trust_rented
 frs     | 2020 | househol | TENTYP2       | 3     | Other private rented unfurnished                      | Other_private_rented_unfurnished
 frs     | 2020 | househol | TENTYP2       | 4     | Other private rented furnished                        | Other_private_rented_furnished
 frs     | 2020 | househol | TENTYP2       | 5     | Owned with a mortgage (includes part rent / part own) | Owned_with_a_mortgage_includes_part_rent__or__part_own
 frs     | 2020 | househol | TENTYP2       | 6     | Owned outright                                        | Owned_outright
 frs     | 2020 | househol | TENTYP2       | 7     | Rent-free                                             | Rent_free
 frs     | 2020 | househol | TENTYP2       | 8     | Squats                                                | Squats
=#
function frs_tenuremap( tentyp2 :: Union{Int,Missing} ) :: Vector{Int}
    out = fill( 9999, 3 )
    if ismissing( tentyp2 )

    elseif tentyp2 == 1
        out[1] = 1
        out[2] = 1
    elseif tentyp2 == 2
        out[1] = 2
        out[2] = 1
    elseif tentyp2 == 3
        out[1] = 3
        out[2] = 1
    elseif tentyp2 == 4
        out[1] = 4
        out[2] = 1
    elseif tentyp2 == 5 
        out[1] = 5
        out[2] = 2
    elseif tentyp2 == 6
        out[1] = 6
        out[2] = 2   
    elseif tentyp2 in [7,8]
        out[1] = 7
        out[2] = 3   
    else
        @assert false "unmatched tentyp2 $tentyp2";
    end 
    return out
end

#=
 lcf     | 2020 | dvhh   | A121          | 0     | Not Recorded                  | Not_Recorded
 lcf     | 2020 | dvhh   | A121          | 1     | Local authority rented unfurn | Local_authority_rented_unfurn
 lcf     | 2020 | dvhh   | A121          | 2     | Housing association           | Housing_association
 lcf     | 2020 | dvhh   | A121          | 3     | Other rented unfurnished      | Other_rented_unfurnished
 lcf     | 2020 | dvhh   | A121          | 4     | Rented furnished              | Rented_furnished
 lcf     | 2020 | dvhh   | A121          | 5     | Owned with mortgage           | Owned_with_mortgage
 lcf     | 2020 | dvhh   | A121          | 6     | Owned by rental purchase      | Owned_by_rental_purchase
 lcf     | 2020 | dvhh   | A121          | 7     | Owned outright                | Owned_outright
 lcf     | 2020 | dvhh   | A121          | 8     | Rent free                     | Rent_free
=#
function lcf_tenuremap( a121 :: Union{Int,Missing} ) :: Vector{Int}
    out = fill( 9998, 3 )
    if ismissing( a121 )
        ;
    elseif a121 == 1
        out[1] = 1
        out[2] = 1
    elseif a121 == 2
        out[1] = 2
        out[2] = 1
    elseif a121  == 3
        out[1] = 3
        out[2] = 1
    elseif a121 == 4
        out[1] = 3
        out[2] = 1
    elseif a121 in [5,6] 
        out[1] = 5
        out[2] = 2
    elseif a121 == 7
        out[1] = 6
        out[2] = 2  
    elseif a121 == 8
        out[1] = 7
        out[2] = 3  
    else
        @assert false "unmatched tentyp2 $tentyp2";
    end 
    return out
end

#=
frs     | 2020 | househol | GVTREGN       | 112000001 | North East           | North_East
frs     | 2020 | househol | GVTREGN       | 112000002 | North West           | North_West
frs     | 2020 | househol | GVTREGN       | 112000003 | Yorks and the Humber | Yorks_and_the_Humber
frs     | 2020 | househol | GVTREGN       | 112000004 | East Midlands        | East_Midlands
frs     | 2020 | househol | GVTREGN       | 112000005 | West Midlands        | West_Midlands
frs     | 2020 | househol | GVTREGN       | 112000006 | East of England      | East_of_England
frs     | 2020 | househol | GVTREGN       | 112000007 | London               | London
frs     | 2020 | househol | GVTREGN       | 112000008 | South East           | South_East
frs     | 2020 | househol | GVTREGN       | 112000009 | South West           | South_West
frs     | 2020 | househol | GVTREGN       | 299999999 | Scotland             | Scotland
frs     | 2020 | househol | GVTREGN       | 399999999 | Wales                | Wales
frs     | 2020 | househol | GVTREGN       | 499999999 | Northern Ireland     | Northern_Ireland
=#
function frs_regionmap( gvtregn :: Union{Int,Missing} ) :: Vector{Int}
    out = fill( 9999, 3 )
    # gvtregn = parse(Int, gvtregn )
    if ismissing( gvtregn )
        ;
    elseif gvtregn in 112000001:112000009
        out[1] = gvtregn - 112000000
        out[2] = 1
    elseif gvtregn == 299999999
        out[1] = 11 # note swap wales/scot
        out[2] = 2
    elseif gvtregn == 399999999
        out[1] = 10
        out[2] = 3
    elseif gvtregn == 499999999
        out[1] = 12
        out[2] = 4
    else
        @assert false "unmatched gvtregn $gvtregn";
    end 
    return out
end

#=
 lcf     | 2020 | dvhh            | Gorx          | 1     | North East                | North_East
 lcf     | 2020 | dvhh            | Gorx          | 2     | North West and Merseyside | North_West_and_Merseyside
 lcf     | 2020 | dvhh            | Gorx          | 3     | Yorkshire and the Humber  | Yorkshire_and_the_Humber
 lcf     | 2020 | dvhh            | Gorx          | 4     | East Midlands             | East_Midlands
 lcf     | 2020 | dvhh            | Gorx          | 5     | West Midlands             | West_Midlands
 lcf     | 2020 | dvhh            | Gorx          | 6     | Eastern                   | Eastern
 lcf     | 2020 | dvhh            | Gorx          | 7     | London                    | London
 lcf     | 2020 | dvhh            | Gorx          | 8     | South East                | South_East
 lcf     | 2020 | dvhh            | Gorx          | 9     | South West                | South_West
 lcf     | 2020 | dvhh            | Gorx          | 10    | Wales                     | Wales
 lcf     | 2020 | dvhh            | Gorx          | 11    | Scotland                  | Scotland
 lcf     | 2020 | dvhh            | Gorx          | 12    | Northern Ireland          | Northern_Ireland
=#
function lcf_regionmap( gorx :: Union{Int,Missing} ) :: Vector{Int}
    out = fill( 9998, 3 )
    if ismissing( gorx )
        ;
    elseif gorx in 1:9
        out[1] = gorx
        out[2] = 1
    elseif gorx == 10
        out[1] = 10 # note swap wales/scot
        out[2] = 3
    elseif gorx == 11
        out[1] = 11
        out[2] = 2
    elseif gorx == 12
        out[1] = 12
        out[2] = 4
    else
        @assert false "unmatched gorx $gorx";
    end 
    return out
end

#=
 
See lcf_frs_composition_mapping.md

=#
function composition_map( comp :: Int, mappings; default::Int ) Vector{Int}
    out = fill( default, 3 )
    n = length(mappings)
    for i in 1:n
        if comp in mappings[i]
            out[1] = i
            break
        end
    end
    @assert out[1] in 1:10 "unmatched comp $comp"
    out[2] = 
        if out[1] in [1,2] # single m/f people
            1
        elseif out[1] in [3,4,7,8,9,10] # any with children
            2
        else # no children
            3
        end
    return out
end

function lcf_composition_map( a062 :: Int ) Vector{Int}
    mappings = (lcf1=[1],lcf2=[2],lcf3=[3,4],lcf4=[5,6],lcf5=[7,8],lcf6=[18,23,26,28],lcf7=[9,10],lcf8=[11,12],lcf9=[13,14,15,16,17],lcf10=[19,24,20,21,22,25,27,29,30])
    return composition_map( a062,  mappings, default=9998 )
end

function frs_composition_map( hhcomps :: Int ) Vector{Int}
    mappings=(frs1=[1,3],frs2=[2,4],frs3=[9],frs4=[10],frs5=[5,6,7],frs6=[8],frs7=[12],frs8=[13],frs9=[14],frs10=[11,15,16,17])
    return composition_map( hhcomps,  mappings, default=9999 )
end


# sort(vcat(frsc...))

#=
lcf     | 2020 | dvhh            | A116          | 0     | Not Recorded                  | Not_Recorded
lcf     | 2020 | dvhh            | A116          | 1     | Whole house,bungalow-detached | Whole_house_bungalow_detached
lcf     | 2020 | dvhh            | A116          | 2     | Whole hse,bungalow-semi-dtchd | Whole_hse_bungalow_semi_dtchd
lcf     | 2020 | dvhh            | A116          | 3     | Whole house,bungalow-terraced | Whole_house_bungalow_terraced
lcf     | 2020 | dvhh            | A116          | 4     | Purpose-built flat maisonette | Purpose_built_flat_maisonette
lcf     | 2020 | dvhh            | A116          | 5     | Part of house converted flat  | Part_of_house_converted_flat
lcf     | 2020 | dvhh            | A116          | 6     | Others                        | Others
=#
function lcf_accmap( a116 :: Any)  :: Vector{Int}
    out = fill( 9998, 3 )
    # missing in 2020 f*** 
    if typeof(a116) <: AbstractString
        return out
        # a116 = tryparse( Int, a116 )
    end

    out[1] = a116
    if a116 in 1:3
        out[2] = 1
    elseif a116 in 4:5
        out[2] = 2
    elseif a116 == 6
        out[2] = 3
    else
        @assert false "unmatched a116 $a116"
    end
    out
end

#=
 frs     | 2020 | househol | TYPEACC       | 1     | Whole house/bungalow, detached      | Whole_house_or_bungalow_detached
 frs     | 2020 | househol | TYPEACC       | 2     | Whole house/bungalow, semi-detached | Whole_house_or_bungalow_semi_detached
 frs     | 2020 | househol | TYPEACC       | 3     | Whole house/bungalow, terraced      | Whole_house_or_bungalow_terraced
 frs     | 2020 | househol | TYPEACC       | 4     | Purpose-built flat or maisonette    | Purpose_built_flat_or_maisonette
 frs     | 2020 | househol | TYPEACC       | 5     | Converted house/building            | Converted_house_or_building
 frs     | 2020 | househol | TYPEACC       | 6     | Caravan/Mobile home or Houseboat    | Caravan_or_Mobile_home_or_Houseboat
 frs     | 2020 | househol | TYPEACC       | 7     | Other                               | Other
=#
function frs_accmap( typeacc :: Union{Int,Missing})  :: Vector{Int}
    out = fill( 9999, 3 )
    out[1] = min(6,typeacc)
    if typeacc in 1:3
        out[2] = 1
    elseif typeacc in 4:5
        out[2] = 2
    elseif typeacc in 6:7
        out[2] = 3
    else
        @assert false "unmatched typeacc $typeacc"
    end
    out
end

function score( a3 :: Vector{Int}, b3 :: Vector{Int})::Float64
    return if a3[1] == b3[1]
        1.0
    elseif a3[2] == b3[2]
        0.5
    elseif a3[3] == b3[3]
        0.1
    else
        0.0
    end
end

function score( a :: Int, b :: Int ) :: Float64
    return if a == b
        1.0
    elseif abs( a - b ) < 2
        0.5
    elseif abs( a - b ) < 5
        0.1
    else
        0.0
    end
end


function rooms( rooms :: Union{Missing,Int,AbstractString}, def::Int ) :: Vector{Int}
    # !!! Another missing in lcf 2020 for NO FUCKING REASON
    out = fill(def,3)    
    if (typeof(rooms) <: AbstractString) || rooms < 0
        return out
        # a116 = tryparse( Int, a116 )
    end

    rooms = min( 6, rooms )
    if (ismissing(rooms) || (rooms == 0 )) 
        return [0,0, 1]
    end
    out = fill(0,3)   
    out[1] = rooms
    out[2] = min( rooms, 3)
    out[3] = rooms == 1 ? 1 : 2
    return out
end

#=
 frs     | 2020 | househol | HHAGEGR4      | 1     | Age 16 to 19   | Age_16_to_19
 frs     | 2020 | househol | HHAGEGR4      | 2     | Age 20 to 24   | Age_20_to_24
 frs     | 2020 | househol | HHAGEGR4      | 3     | Age 25 to 29   | Age_25_to_29
 frs     | 2020 | househol | HHAGEGR4      | 4     | Age 30 to 34   | Age_30_to_34
 frs     | 2020 | househol | HHAGEGR4      | 5     | Age 35 to 39   | Age_35_to_39
 frs     | 2020 | househol | HHAGEGR4      | 6     | Age 40 to 44   | Age_40_to_44
 frs     | 2020 | househol | HHAGEGR4      | 7     | Age 45 to 49   | Age_45_to_49
 frs     | 2020 | househol | HHAGEGR4      | 8     | Age 50 to 54   | Age_50_to_54
 frs     | 2020 | househol | HHAGEGR4      | 9     | Age 55 to 59   | Age_55_to_59
 frs     | 2020 | househol | HHAGEGR4      | 10    | Age 60 to 64   | Age_60_to_64
 frs     | 2020 | househol | HHAGEGR4      | 11    | Age 65 to 69   | Age_65_to_69
 frs     | 2020 | househol | HHAGEGR4      | 12    | Age 70 to 74   | Age_70_to_74
 frs     | 2020 | househol | HHAGEGR4      | 13    | Age 75 or over | Age_75_or_over
=#
function frs_age_hrp( hhagegr4 :: Int ) :: Vector{Int}
    out = fill( 9998, 3 )
    out[1] = hhagegr4
    if hhagegr4 <= 5
        out[2] = 1
    elseif hhagegr4 <= 13
        out[2] = 2
    else
        @assert false "mapping hhagegr4 $hhagegr4"
    end
    out
end

#=
	Value = 3.0	Label =  15 but under 20 yrs
	Value = 4.0	Label =  20 but under 25 yrs
	Value = 5.0	Label =  25 but under 30 yrs
	Value = 6.0	Label =  30 but under 35 yrs
	Value = 7.0	Label =  35 but under 40 yrs
	Value = 8.0	Label =  40 but under 45 yrs
	Value = 9.0	Label =  45 but under 50 yrs
	Value = 10.0	Label =  50 but under 55 yrs
	Value = 11.0	Label =  55 but under 60 yrs
	Value = 12.0	Label =  60 but under 65 yrs
	Value = 13.0	Label =  65 but under 70 yrs
	Value = 14.0	Label =  70 but under 75 yrs
	Value = 15.0	Label =  75 but under 80 yrs
	Value = 16.0	Label =  80 and over

=#
function lcf_age_hrp( a065p :: Int ) :: Vector{Int}
    out = fill( 9998, 3 )
    a065p -= 2
    a065p = min( 13, a065p ) # 75+
    out[1] = a065p
    if a065p <= 5
        out[2] = 1
    elseif a065p <= 13
        out[2] = 2
    else
        @assert false "mapping a065p $a065p"
    end
    out
end

#=

hh gross income

lcf     | 2020 | dvhh            | P389p      |   1 | numeric | scale             | Normal weekly disposable hhld income - top-coded                                                                                                                                                |         1

p344p
lcf     | 2020 | dvhh            | p344p |   1 | numeric | scale             | Gross normal weekly household income - top-coded |         1
lcf     | 2020 | dvhh            | P352p      |   1 | numeric | scale             | Gross current income of household - top-coded    
frs     | 2020 | househol | HHINC    | 249 | numeric | scale             | HH - Total Household income                 |         1

julia> summarystats( lcfhh.p344p )
Summary Stats:
Length:         5400
Missing Count:  0
Mean:           872.313711
Minimum:        0.000000
1st Quartile:   432.048923
Median:         744.151615
3rd Quartile:   1172.362500
Maximum:        2420.030000 ## TOPCODED


julia> summarystats( frshh.hhinc )
Summary Stats:
Length:         16364
Missing Count:  0
Mean:           855.592520
Minimum:        -7024.000000
1st Quartile:   380.000000
Median:         636.000000
3rd Quartile:   1070.000000
Maximum:        30084.000000

=#

function compare_income( hhinc :: Real, p344p :: Real ) :: Real
    # top & bottom code hhinc to match the lcf p344
    # hhinc = max( 0, hhinc )
    # hhinc = min( TOPCODE, hhinc ) 
    1-abs( hhinc - p344p )/TOPCODE # topcode is also the range 
end

function frs_lcf_match_row( frs :: DataFrameRow, lcf :: DataFrameRow ) :: Tuple
    t = 0.0
    t += score( lcf_tenuremap( lcf.a121 ), frs_tenuremap( frs.tentyp2 ))
    t += score( lcf_regionmap( lcf.gorx ), frs_regionmap( frs.gvtregn ))
    # !!! both next missing in 2020 LCF FUCKKK 
    # t += score( lcf_accmap( lcf.a116 ), frs_accmap( frs.typeacc ))
    # t += score( rooms( lcf.a111p, 998 ), rooms( frs.bedroom6, 999 ))
    t += score( lcf_age_hrp(  lcf.a065p ), frs_age_hrp( frs.hhagegr4 ))
    t += score( lcf_composition_map( lcf.a062 ), frs_composition_map( frs.hhcomps ))
    t += lcf.any_wages == frs.any_wages ? 1 : 0
    t += lcf.any_pension_income == frs.any_pension_income ? 1 : 0
    t += lcf.any_selfemp == frs.any_selfemp ? 1 : 0
    t += lcf.hrp_unemployed == frs.hrp_unemployed ? 1 : 0
    t += lcf.hrp_non_white == frs.hrp_non_white ? 1 : 0
    t += lcf.datayear == frs.datayear ? 0.5 : 0 # - a little on same year FIXME use date range
    # t += lcf.any_disabled == frs.any_disabled ? 1 : 0 -- not possible in LCF??
    t += lcf.has_female_adult == frs.has_female_adult ? 1 : 0
    t += score( lcf.num_children, frs.num_children )
    t += score( lcf.num_people, frs.num_people )
    incdiff = compare_income( lcf.income, frs.income )
    t += 20.0*incdiff
    return t,incdiff
end

islessscore( l1::LCFLocation, l2::LCFLocation ) = l1.score < l2.score
islessincdiff( l1::LCFLocation, l2::LCFLocation ) = l1.incdiff < l2.incdiff

function match_recip_row( recip :: DataFrameRow, donor :: DataFrame, matcher :: Function ) :: Vector{LCFLocation}
    drows, dcols = size(donor)
    i = 0
    similar = Vector{LCFLocation}( undef, drows )
    for lr in eachrow(donor)
        i += 1
        score, incdiff = matcher( recip, lr )
        similar[i] = LCFLocation( lr.case, lr.datayear, score, lr.income, incdiff )
    end
    # sort by characteristics   
    similar = sort( similar; lt=islessscore, rev=true )[1:NUM_SAMPLES]
    # .. then the nearest income amongst those
    similar = sort( similar; lt=islessincdiff, rev=true )[1:NUM_SAMPLES]
    return similar
end

function makeoutdf( n :: Int ) :: DataFrame
    d = DataFrame(
    frs_sernum = zeros(Int, n),
    frs_datayear = zeros(Int, n),
    frs_income = zeros(n))
    for i in 1:NUM_SAMPLES
        lcf_case_sym = Symbol( "lcf_case_$i")
        lcf_datayear_sym = Symbol( "lcf_datayear_$i")
        lcf_score_sym = Symbol( "lcf_score_$i")
        lcf_income_sym = Symbol( "lcf_income_$i")
        d[!,lcf_case_sym] .= 0
        d[!,lcf_datayear_sym] .= 0
        d[!,lcf_score_sym] .= 0.0
        d[!,lcf_income_sym] .= 0.0
    end
    d
end

function map_all( recip :: DataFrame, donor :: DataFrame, matcher :: Function )::DataFrame
    p = 0
    nrows = size(recip)[1]
    df = makeoutdf( nrows )
    for fr in eachrow(recip); 
        p += 1
        println(p)
        df[p,:frs_sernum] = fr.sernum
        df[p,:frs_datayear] = fr.datayear
        df[p,:frs_income] = fr.income
        matches = match_recip_row( fr, donor, matcher ) 
        for i in 1:NUM_SAMPLES
            lcf_case_sym = Symbol( "lcf_case_$i")
            lcf_datayear_sym = Symbol( "lcf_datayear_$i")
            lcf_score_sym = Symbol( "lcf_score_$i")
            lcf_income_sym = Symbol( "lcf_income_$i")
            df[p,lcf_case_sym] = matches[i].case
            df[p,lcf_datayear_sym] = matches[i].datayear
            df[p,lcf_score_sym] = matches[i].score
            df[p,lcf_income_sym] = matches[i].income    
        end
        if p > 100
            break
        end
    end
    return df
end


function comparefrslcf( frs_sernum::Int, frs_datayear::Int, lcf_case::Int, lcf_datayear::Int )
    frs1 = frshh[(frshh.sernum .== frs_sernum).&(frshh.datayear.==frs_datayear),
        [:any_wages,:any_pension_income,:any_selfemp,:hrp_unemployed,:hrp_non_white,:has_female_adult,
         :num_children,:num_people,:tentyp2,:gvtregn,:hhagegr4]]

    lcf1 = lcfhh[(lcfhh.case .== lcf_case).&(lcfhh.datayear .== lcf_datayear),
        [:any_wages,:any_pension_income,:any_selfemp,:hrp_unemployed,
         :hrp_non_white,:has_female_adult,:num_children,:num_people,
         :a121,:gorx,:a065p]]
    println(frs1)
    println( "frs tenure", frs_tenuremap( frs1.tentyp2[1]))
    println( "frs region", frs_regionmap( frs1.gvtregn[1] ))
    println( "lcf age hrp", lcf_age_hrp( frshh.hhagegr4[1] ))
    println( "frs composition", frs_composition_map( frshh.hhcomps[1] ))

    println(lcf1)
    println( "lcf tenure",lcf_tenuremap( lcf1.a121[1] ))
    println( "lcf region", lcf_regionmap( lcf1.gorx[1] ))
    println( "lcf age_hrp", lcf_age_hrp( lcfhh.a065p[1] ))
    println( "lcf composition", lcf_composition_map( lcfhh.a062[1] ))
end
