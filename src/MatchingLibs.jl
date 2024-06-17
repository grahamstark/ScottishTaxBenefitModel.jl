
module MatchingLibs

#
# A script to match records from 2019/19 to 2020/21 lcf to 2020 FRS
# strategy is to match to a bunch of characteristics, take the top 20 of those, and then
# match between those 20 on household income. 
# TODO
# - make this into a module and a bit more general-purpose;
# - write up, so why not just Engel curves?
#
using ScottishTaxBenefitModel
using .Definitions,
    .ModelHousehold,
    .Uprating,
    .RunSettings

using CSV,
    DataFrames,
    Measures,
    StatsBase

export make_lcf_subset, 
    map_example, 
    load, 
    map_all, 
    frs_lcf_match_row

struct LCFLocation
    case :: Int
    datayear :: Int
    score :: Float64
    income :: Float64
    incdiff :: Float64
end

"""
Load 2020/21 FRS and add some matching fields
"""
function loadfrs()::Tuple
    frsrows,frscols,frshh = load( "/mnt/data/frs/2021/tab/househol.tab",2021)
    farows,facols,frsad = load( "/mnt/data/frs/2021/tab/adult.tab", 2021)
    frs_hh_pp = innerjoin( frshh, frsad, on=[:sernum,:datayear], makeunique=true )
    add_some_frs_fields!( frshh, frs_hh_pp )
    return frshh,frspers,frs_hh_pp
end
# fcrows,fccols,frsch = load( "/mnt/data/frs/2021/tab/child.tab", 2021 )

"""
Scottish Version on Pooled data
"""
function load_scottish_frss( startyear::Int, endyear :: Int )::NamedTuple
    frshh = DataFrame()
    frs_hh_pp = DataFrame()
    frspers = DataFrame()
    for year in startyear:endyear
        lhh = loadfrs( "househol", year )
        lhh = lhh[ lhh.gvtregn.== 299999999, :] # SCOTLAND
        lhh.datayear .= year
        lad = loadfrs( "adult", year )
        lad.datayear .= year
        l_hh_pp = innerjoin( lhh, lad, on=[:sernum,:datayear], makeunique=true )
        add_some_frs_fields!( lhh, l_hh_pp )
        frshh = vcat( frshh, lhh; cols=:union )
        frspers = vcat( frspers, lad; cols=:union )
        frs_hh_pp = vcat( frs_hh_pp, l_hh_pp, cols=:union )
    end
    (; frshh, frspers, frs_hh_pp )
end

function frs_regionmap( gvtregn :: Union{Int,Missing} ) :: Vector{Int}
    out = fill( 9999, 3 )
    # gvtregn = parse(Int, gvtregn )
    if ismissing( gvtregn )
        ;
    elseif gvtregn == 112000007 # london
        out[1] = 7
        out[2] = 1
    elseif gvtregn in 112000001:112000009 # rEngland
        out[1] = gvtregn - 112000000
        out[2] = 2
    elseif gvtregn == 299999999 # scotland
        out[1] = 11 
        out[2] = 3
    elseif gvtregn == 399999999
        out[1] = 10
        out[2] = 4
    elseif gvtregn == 499999999
        out[1] = 12
        out[2] = 5
    else
        @assert false "unmatched gvtregn $gvtregn";
    end 
    return out
end

function model_regionmap(  reg :: Standard_Region ) :: Vector{Int}
    return frs_regionmap( Int( reg ))
end

"""
Score for one of our 3-level matches 1 for exact 0.5 for partial 1, 0.1 for partial 2
"""
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

"""
Score for comparison between 2 ints: 1 for exact, 0.5 for within 2 steps, 0.1 for within 5. FIXME look at this again.
"""
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

function load( path::String, datayear :: Int )::Tuple
    d = CSV.File( path ) |> DataFrame
    ns = lowercase.(names( d ))
    rename!( d, ns )
    d.datayear .= datayear
    rows,cols = size(d)
    return rows,cols,d
end

export TOPCODE, within, load, uprate_incomes!, checkdiffs

const NUM_SAMPLES = 20

function checkdiffs( title::String, col1::Vector, col2::Vector )
    n = size(col1)[1]
    @assert n  ==  size(col2)[1]
    out = []
    for i in 1:n
        d = col1[i] - col2[i]
        if  abs(d) > 0.00001  
            push!( out, (i, d) )
        end
    end
    if size(out)[1] !== 0 
        println("differences at positions $out")
    end
end

function searchbaddies(lcf::DataFrame, rows, amount::Real, op=≈)
    nms = names(lcf)
    nc = size(lcf)[2]
    for i in 1:nc
        for r in rows
            if(typeof(lcf[r,i]) == Float64) && op(lcf[r,i], amount )
                println("row $r varname = $(n[i])")
            end
        end
    end
end


"""
Small, easier to use, subset of lfs expenditure codes kinda sorta matching the tax system we're modelling.
"""
function make_lcf_subset( lcf :: DataFrame ) :: DataFrame
    out = DataFrame( 
        case = lcf.case, 
        datayear = lcf.datayear, 
        month = lcf.a055, 
        year= lcf.year,
        a121 = lcf.a121,
        gorx = lcf.gorx,
        a065p  = lcf.a065p,
        a062 = lcf.a062,

        any_wages = lcf.any_wages,
        any_pension_income = lcf.any_pension_income,
        any_selfemp = lcf.any_selfemp,
        hrp_unemployed = lcf.hrp_unemployed,
        num_children = lcf.num_children,
        hrp_non_white = lcf.hrp_non_white,
        num_people = lcf.num_people,
        income = lcf.income,
        any_disabled = lcf.any_disabled,
        has_female_adult = lcf.has_female_adult )

    #= top level COICOP
    01	Food and Non-Alcoholic Beverages
    02	Alcoholic Beverages, Tobacco and Narcotics
    03	Clothing and Footwear
    04	Housing, Water, Electricity, Gas and Other Fuels
    05	Furnishings, Household Equipment and Routine Maintenance of the House
    06	Health
    07	Transport
    08	Communication
    09	Recreation
    10 (A)	Education
    11 (B)	Restaurant and Hotels
    12 (C)	Miscellaneous Goods and Services
    20 (K)	Non-Consumption Expenditure
    =#

    # 01) food 

    out.sweets_and_icecream = lcf.c11831t + lcf.c11841t + lcf.c11851t
    out.other_food_and_beverages = lcf.p601t - out.sweets_and_icecream
    out.hot_and_eat_out_food =  ## CHECK is this counting children's sweets twice?
        lcf.cb1111t +
        lcf.cb1112t +
        lcf.cb1113t +
        lcf.cb1114t +
        lcf.cb1115t +
        lcf.cb1116t +
        lcf.cb1117c +
        lcf.cb1118c +
        lcf.cb1119c +
        lcf.cb111ac +
        lcf.cb111bc +
        lcf.cb1121t +
        lcf.cb1122t +
        lcf.cb1123t +
        lcf.cb1124t +
        lcf.cb1125t +
        lcf.cb1126t +
        lcf.cb1127t +
        lcf.cb1128t +
        lcf.cb112bt +
        lcf.cb1213t

    # 02 Alcoholic Beverages, Tobacco and Narcotics

    out.spirits = lcf.cb111ct + lcf.c21111t
    out.wine = lcf.cb111dt + lcf.c21211t
    out.fortified_wine = lcf.cb111et + lcf.c21212t
    out.cider = lcf.cb111ft + lcf.c21213t 
    out.alcopops = lcf.cb111gt + lcf.c21214t
    out.champagne = lcf.cb111ht + lcf.c21221t
    out.beer = lcf.cb111it + lcf.cb111jt + lcf.c21311t # fixme rounds of drinks are beer!

    out.cigarettes = lcf.c22111t
    out.cigars = lcf.c22121t
    out.other_tobacco = lcf.c22131t # ?? Assume Vapes?

    # 03 Clothing and Footwear

    out.childrens_clothing_and_footwear = lcf.c31231t + lcf.c31232t + lcf.c31233t + lcf.c31234t + lcf.c31313t + lcf.c32131t
    out.helmets_etc = lcf.c31315t
    out.other_clothing_and_footwear = lcf.p603t - out.helmets_etc - out.childrens_clothing_and_footwear

    # 04	Housing, Water, Electricity, Gas and Other Fuels
    out.domestic_fuel_electric =(lcf.b175 - lcf.b178) + lcf.b227 + lcf.c45114t
    out.domestic_fuel_gas = (lcf.b170 - lcf.b173) + lcf.b226 + lcf.b018 + lcf.c45112t + lcf.c45214t + lcf.c45222t
    out.domestic_fuel_coal = lcf.c45411t
    out.domestic_fuel_other = lcf.b017 + lcf.c45312t + lcf.c45412t + lcf.c45511t
    out.other_housing = lcf.p604t - out.domestic_fuel_electric - out.domestic_fuel_gas - out.domestic_fuel_coal - out.domestic_fuel_other

    # 05	Furnishings, Household Equipment and Routine Maintenance of the House

    out.furnishings_etc = lcf.p605t

    out.medical_services = lcf.c62112t + lcf.c62113t + lcf.c62114t + lcf.c62211t + lcf.c62311t + lcf.c62321t + lcf.c63111t + lcf.c62331t + lcf.c62322t + lcf.c62212t + lcf.c62111t# exempt
    out.prescriptions = lcf.c61111t    # zero
    out.other_medicinces = lcf.c61112t # vatable
    out.spectacles_etc = lcf.c61311t + lcf.c61312t # vatable but see: https://www.chapman-opticians.co.uk/vat_on_spectacles
    out.other_health = lcf.c61211t + lcf.c61313t  # but condoms smoking medicines (?? tampons )
    checkdiffs( "health", out.medical_services + out.prescriptions + out.other_medicinces + out.spectacles_etc + out.other_health, lcf.p606t )
    
    # :c61111t,:c61112t,:c61211t,:c61311t,:c61312t,:c61313t,:c62111t,:c62112t,:c62113t,:c62114t,:c62211t,:c62212t,:c62311t,:c62321t,:c62322t,:c62331t,:c63111t
    
    # lcf[399,[:p606t, :c61111t,:c61112t,:c61211t,:c61311t,:c61312t,:c61313t,:c62111t,:c62112t,:c62113t,:c62114t,:c62211t,:c62212t,:c62311t,:c62321t,:c62322t,:c62331t,:c63111t]]

    # 07 Transport  !!1 DURABLES 
    # ?? how are outright purchases handled?
    out.bus_boat_and_train = lcf.b216 + lcf.b217 + lcf.b218 + lcf.b219 + lcf.c73212t + lcf.c73411t + lcf.c73512t + lcf.c73513t + lcf.p546c # zero FIXME I don't see why p546c - children's transport - is needed but we don't add up otherwise.
    out.air_travel = lcf.b487 + lcf.b488
    out.petrol = lcf.c72211t
    out.diesel = lcf.c72212t
    out.other_motor_oils = lcf.c72213t
    out.other_transport = lcf.p607t - (out.bus_boat_and_train + out.air_travel + out.petrol + out.diesel + out.other_motor_oils)

    # 08 Communication
    out.communication  = lcf.p608t # Standard 

    # 09 Recreation
    out.books = lcf.c95111t
    out.newspapers = lcf.c95211t
    out.magazines = lcf.c95212t
    out.gambling = lcf.c94314t  # - winnings? C9431Dt
    out.museums_etc = lcf.c94221t * 0.5 # FIXME includes theme parks
    out.postage = lcf.c81111t + lcf.cc6212t 
    out.other_recreation = lcf.p609t - (out.books + out.newspapers + out.magazines + out.gambling + out.museums_etc + out.postage)
    # FIXME deaf ebooks ..
    # 10 (A)	Education
    out.education = lcf.p610t # exempt
    # 11 (B)	Restaurant and Hotels
    out.hotels_and_restaurants = lcf.p611t - out.hot_and_eat_out_food - (lcf.cb111ct+lcf.cb111dt+lcf.cb111et+lcf.cb111ft+lcf.cb111gt+lcf.cb111ht+lcf.cb111it + lcf.cb111jt) # h&r less the food,drink,alcohol
    # 12 (C)	Miscellaneous Goods and Services

    out.insurance = lcf.b110 +
        lcf.b168 + 
        lcf.cc5213t + 
        lcf.cc5311c + 
        lcf.cc5411c + 
        lcf.cc5412t + 
        lcf.cc5413t + 
        lcf.cc6211c + 
        lcf.cc6212t + 
        lcf.cc6214t + 
        lcf.cc7111t + 
        lcf.cc7112t + 
        lcf.cc7113t + 
        lcf.cc7115t + 
        lcf.cc7116t # exempt

    out.other_financial = 
        lcf.b1802 +
        lcf.b188 +  
        lcf.b229 +
        lcf.b238 +  
        lcf.b273 +  
        lcf.b280 +  
        lcf.b281 +  
        lcf.b282 +  
        lcf.b283   # exempt

    out.prams_and_baby_chairs = 
        lcf.cc3222t +
        lcf.cc3223t # zero

    out.care_services = lcf.cc4121t + lcf.cc4111t + lcf.cc4112t

    out.trade_union_subs = lcf.cc1317t # fixme rename

    out.nappies = lcf.cc1317t * 0.5 # nappies zero rated, other baby goods standard rated FIXME wild guess

    out.funerals = lcf.cc7114t # exempt https://www.gov.uk/guidance/burial-cremation-and-commemoration-of-the-dead-notice-70132

    out.womens_sanitary = lcf.cc1312t * 0.5 # FIXME wild guess 

    out.other_misc_goods = lcf.p612t - (
        out.womens_sanitary + 
        out.insurance + 
        out.other_financial + 
        out.prams_and_baby_chairs + 
        out.care_services + 
        out.nappies + 
        out.funerals + 
        out.trade_union_subs) # rest standard rated

    out.non_consumption = lcf.p620tp 

    out.total_expenditure = lcf.p630tp

    checkdiffs( "total spending",
        out.sweets_and_icecream + 
        out.other_food_and_beverages + 
        out.hot_and_eat_out_food + 
        out.spirits + 
        out.wine + 
        out.fortified_wine + 
        out.cider + 
        out.alcopops + 
        out.champagne + 
        out.beer + 
        out.cigarettes + 
        out.cigars + 
        out.other_tobacco + 
        out.childrens_clothing_and_footwear + 
        out.helmets_etc + 
        out.other_clothing_and_footwear + 
        out.domestic_fuel_electric + 
        out.domestic_fuel_gas + 
        out.domestic_fuel_coal + 
        out.domestic_fuel_other+ 
        out.other_housing + 
        out.furnishings_etc + 
        out.medical_services + 
        out.prescriptions + 
        out.other_medicinces + 
        out.spectacles_etc + 
        out.other_health + 
        out.bus_boat_and_train  + 
        out.air_travel + 
        out.petrol + 
        out.diesel + 
        out.other_motor_oils + 
        out.other_transport + 
        out.communication + 
        out.books + 
        out.newspapers + 
        out.magazines + 
        out.museums_etc +
        out.postage +
        out.other_recreation + 
        out.education +
        out.hotels_and_restaurants + 
        out.insurance + 
        out.other_financial + 
        out.prams_and_baby_chairs + 
        out.care_services + 
        out.nappies + 
        out.funerals +
        out.womens_sanitary + 
        out.other_misc_goods + 
        out.trade_union_subs + 
        out.gambling + 
        out.non_consumption, 
        lcf.p630tp )

    out.repayments = 
        lcf.b237 + lcf.b238 + lcf.ck5316t + lcf.cc6211c 

    return out

    #= 06 
    Health 
    see https://www.gov.uk/guidance/health-professionals-pharmaceutical-products-and-vat-notice-70157
    in summary: 
    * services EXEPMT, if on the big list
    * contraception, smoking zero related
    * medicines ZERO if from a listed person
    * other stuff from pharmacy VATABLE 
    * specs VATABLE
    * opticians services EXEMPT
    * 
    
    Dataset | year |     tables      |  name   | pos | var_fmt | measurement_level |                                              label                                              | data_type 
    ---------+------+-----------------+---------+-----+---------+-------------------+-------------------------------------------------------------------------------------------------+-----------
    lcf     | 2020 | dvhh            | C61111t | 960 | numeric | scale             | NHS prescription charges and payments - children, aged between 7 and 15                         |         1
    lcf     | 2020 | dvhh            | C61112t | 961 | numeric | scale             | Medicines and medical goods (not NHS) - children, aged between 7 and 15                         |         1
    lcf     | 2020 | dvhh            | C61211t | 962 | numeric | scale             | Other medical products (eg plasters, condoms, tubigrip, etc.) - children, aged between 7 and 15 |         1
    lcf     | 2020 | dvhh            | C61311t | 963 | numeric | scale             | Purchase of spectacles, lenses, prescription glasses - children, aged between 7 and 15          |         1
    lcf     | 2020 | dvhh            | C61312t | 964 | numeric | scale             | Accessories repairs to spectacles lenses - children, aged between 7 and 15                      |         1
    lcf     | 2020 | dvhh            | C61313t | 965 | numeric | scale             | Non-optical appliances and equipment (eg wheelchairs, etc.) - children, aged between 7 and 15   |         1
    lcf     | 2020 | dvhh            | C62111t | 966 | numeric | scale             | NHS medical services - children, aged between 7 and 15                                          |         1
    lcf     | 2020 | dvhh            | C62112t | 967 | numeric | scale             | Private medical services - children, aged between 7 and 15                                      |         1
    lcf     | 2020 | dvhh            | C62113t | 968 | numeric | scale             | NHS optical services - children, aged between 7 and 15                                          |         1
    lcf     | 2020 | dvhh            | C62114t | 969 | numeric | scale             | Private optical services - children, aged between 7 and 15                                      |         1
    lcf     | 2020 | dvhh            | C62211t | 970 | numeric | scale             | NHS dental services - children, aged between 7 and 15                                           |         1
    lcf     | 2020 | dvhh            | C62212t | 971 | numeric | scale             | Private dental services - children, aged between 7 and 15                                       |         1
    lcf     | 2020 | dvhh            | C62311t | 972 | numeric | scale             | Services of medical analysis laboratorie - children, aged between 7 and 15                      |         1
    lcf     | 2020 | dvhh            | C62321t | 973 | numeric | scale             | Services of NHS medical auxiliaries - children, aged between 7 and 15                           |         1
    lcf     | 2020 | dvhh            | C62322t | 974 | numeric | scale             | Services of private medical auxiliaries - children, aged between 7 and 15                       |         1
    lcf     | 2020 | dvhh            | C62331t | 975 | numeric | scale             | Non-hospital ambulance services etc. - children, aged between 7 and 15                          |         1
    lcf     | 2020 | dvhh            | C63111t | 976 | numeric | scale             | Hospital services - children, aged between 7 and 15                                             |         1

    dataset | year | tables |  name   | pos | var_fmt | measurement_level |                                              label                                              | data_type 
    ---------+------+--------+---------+-----+---------+-------------------+-------------------------------------------------------------------------------------------------+-----------
    lcf     | 2020 | dvhh   | B216    | 163 | numeric | scale             | Bus Tube and/or rail season ticket                                                              |         1
    lcf     | 2020 | dvhh   | B217    | 164 | numeric | scale             | Season ticket-bus/coach-total net amount                                                        |         1
    lcf     | 2020 | dvhh   | B218    | 165 | numeric | scale             | Season ticket-rail/tube-total net amount                                                        |         1
    lcf     | 2020 | dvhh   | B219    | 166 | numeric | scale             | Water travel season ticket                                                                      |         1
    lcf     | 2020 | dvhh   | B244    | 173 | numeric | scale             | Vehicle - cost of new car/van outright                                                          |         1
    lcf     | 2020 | dvhh   | B245    | 175 | numeric | scale             | Vehicle - cost of second-hand car/van outright                                                  |         1
    lcf     | 2020 | dvhh   | B247    | 177 | numeric | scale             | Vehicle - cost of motorcycle outright                                                           |         1
    lcf     | 2020 | dvhh   | B248    | 178 | numeric | scale             | Car leasing on                                                                                  |         1
    lcf     | 2020 | dvhh   | B249    | 179 | numeric | scale             | Car or van - servicing : amount paid                                                            |         1
    lcf     | 2020 | dvhh   | B250    | 180 | numeric | scale             | Car or van - other works, repairs: amount paid                                                  |         1
    lcf     | 2020 | dvhh   | B252    | 181 | numeric | scale             | Motor cycle - services, repairs: amount paid                                                    |         1
    lcf     | 2020 | dvhh   | B487    | 229 | numeric | scale             | Domestic flight expenditure                                                                     |         1
    lcf     | 2020 | dvhh   | B488    | 230 | numeric | scale             | International flight expenditure                                                                |         1
    lcf     | 2020 | dvhh   | C71111c | 977 | numeric | scale             | Outright purchase of new car/van - children, aged between 7 and 15                              |         1
    lcf     | 2020 | dvhh   | C71112t |   1 | numeric | scale             | Loan / HP purchase of new car/van - children and adults                                         |         1
    lcf     | 2020 | dvhh   | C71121c | 978 | numeric | scale             | Outright purchase of second-hand car/van - children, aged between 7 and 15                      |         1
    lcf     | 2020 | dvhh   | C71122t |   1 | numeric | scale             | Loan / HP purchase of second-hand car/van - children and adults                                 |         1
    lcf     | 2020 | dvhh   | C71211c | 979 | numeric | scale             | Outright purchase of new or second-hand motorcycle - children, aged between 7 and 15            |         1
    lcf     | 2020 | dvhh   | C71212t |   1 | numeric | scale             | Loan / HP purchase of new or second-hand motorcycle - children and adults - children and adults |         1
    lcf     | 2020 | dvhh   | C71311t |   1 | numeric | scale             | Purchase of bicycle - children and adults                                                       |         1
    lcf     | 2020 | dvhh   | C71411t |   1 | numeric | scale             | Animal drawn vehicles - children and adults                                                     |         1
    lcf     | 2020 | dvhh   | C72111t |   1 | numeric | scale             | Car van accessories and fittings - children and adults                                          |         1
    lcf     | 2020 | dvhh   | C72112t |   1 | numeric | scale             | Car van spare parts - children and adults                                                       |         1
    lcf     | 2020 | dvhh   | C72113t |   1 | numeric | scale             | Motor cycle accessories and spare parts - children and adults                                   |         1
    lcf     | 2020 | dvhh   | C72114t |   1 | numeric | scale             | Anti-freeze, battery water, cleaning materials - children and adults                            |         1
    lcf     | 2020 | dvhh   | C72115t |   1 | numeric | scale             | Bicycle accessories, repairs and other costs - children and adults                              |         1
    lcf     | 2020 | dvhh   | C72211t |   1 | numeric | scale             | Petrol - children and adults                                                                    |         1
    lcf     | 2020 | dvhh   | C72212t |   1 | numeric | scale             | Diesel oil - children and adults                                                                |         1
    lcf     | 2020 | dvhh   | C72213t |   1 | numeric | scale             | Other motor oils - children and adults                                                          |         1
    lcf     | 2020 | dvhh   | C72311c | 990 | numeric | scale             | Car or van repairs and servicing - children, aged between 7 and 15                              |         1
    lcf     | 2020 | dvhh   | C72312c | 991 | numeric | scale             | Motor cycle repairs, service - children, aged between 7 and 15                                  |         1
    lcf     | 2020 | dvhh   | C72313t |   1 | numeric | scale             | Motoring organisation subscription (eg AA and RAC) - children and adults                        |         1
    lcf     | 2020 | dvhh   | C72314t |   1 | numeric | scale             | Car washing and breakdown services - children and adults                                        |         1
    lcf     | 2020 | dvhh   | C72411t |   1 | numeric | scale             | Parking fees, tolls, and permits (excluding motoring fines) - children and adults               |         1
    lcf     | 2020 | dvhh   | C72412t |   1 | numeric | scale             | Garage rent,MOT,etc.    - children and adults                                                   |         1
    lcf     | 2020 | dvhh   | C72413t |   1 | numeric | scale             | Driving lessons - children and adults                                                           |         1
    lcf     | 2020 | dvhh   | C72414t |   1 | numeric | scale             | Hire of self-drive cars, vans, bicycles - children and adults                                   |         1
    lcf     | 2020 | dvhh   | C73112t |   1 | numeric | scale             | Railway and tube fares other than season tickets - children and adults                          |         1
    lcf     | 2020 | dvhh   | C73212t |   1 | numeric | scale             | Bus and coach fares other than season tickets - children and adults                             |         1
    lcf     | 2020 | dvhh   | C73213t |   1 | numeric | scale             | Taxis and hired cars with drivers - children and adults                                         |         1
    lcf     | 2020 | dvhh   | C73214t |   1 | numeric | scale             | Other personal travel - children and adults                                                     |         1
    lcf     | 2020 | dvhh   | C73411t |   1 | numeric | scale             | Water travel - children and adults                                                              |         1
    lcf     | 2020 | dvhh   | C73512t |   1 | numeric | scale             | Combined fares other than season tickets - children and adults                                  |         1
    lcf     | 2020 | dvhh   | C73513t |   1 | numeric | scale             | School travel - children and adults                                                             |         1
    lcf     | 2020 | dvhh   | C73611t |   1 | numeric | scale             | Delivery charges and other transport services - children and adults                             |         1
    Pos. = 817	Variable = C95111	Variable label = Books - adults
This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for C95111

Pos. = 818	Variable = C95211	Variable label = Newspapers - adults
This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for C95211

Pos. = 819	Variable = C95212	Variable label = Magazines and periodicals - adults
This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for C95212

BUT NOT:
Pos. = 820	Variable = C95311	Variable label = Cards, calendars, posters and other printed matter - adults
This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for C95311

Pos. = 821	Variable = C95411	Variable label = Stationery, diaries, address books, art materials - adults
This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for C95411

see: 
https://www.gov.uk/guidance/zero-rating-books-and-printed-matter-for-vat-notice-70110

    lcf     | 2020 | dvhh   | CB1111t | 586 | numeric | scale             | Catered food non-alcoholic drink eaten / drunk on premises - children and adults |         1
    lcf     | 2020 | dvhh   | CB1112t | 587 | numeric | scale             | Confectionery eaten off premises - children and adults                           |         1
    lcf     | 2020 | dvhh   | CB1113t | 588 | numeric | scale             | Ice cream eaten off premises - children and adults                               |         1
    lcf     | 2020 | dvhh   | CB1114t | 589 | numeric | scale             | Soft drinks eaten off premises - children and adults                             |         1
    lcf     | 2020 | dvhh   | CB1115t | 590 | numeric | scale             | Hot food eaten off premises - children and adults                                |         1
    lcf     | 2020 | dvhh   | CB1116t | 591 | numeric | scale             | Cold food eaten off premises - children and adults                               |         1
    lcf     | 2020 | dvhh   | CB1117c | 492 | numeric | scale             | Confectionery (child) - children, aged between 7 and 15                          |         1
    lcf     | 2020 | dvhh   | CB1118c | 493 | numeric | scale             | Ice cream (child) - children, aged between 7 and 15                              |         1
    lcf     | 2020 | dvhh   | CB1119c | 494 | numeric | scale             | Soft drinks (child) - children, aged between 7 and 15                            |         1
    lcf     | 2020 | dvhh   | CB111Ac | 495 | numeric | scale             | Hot food (child)                                                                 |         1
    lcf     | 2020 | dvhh   | CB111Bc | 496 | numeric | scale             | Cold food (child)                                                                |         1
    lcf     | 2020 | dvhh   | CB1121t | 605 | numeric | scale             | Food non-alcoholic drinks eaten drunk on premises - children and adults          |         1
    lcf     | 2020 | dvhh   | CB1122t | 606 | numeric | scale             | Confectionery - children and adults                                              |         1
    lcf     | 2020 | dvhh   | CB1123t | 607 | numeric | scale             | Ice cream - children and adults                                                  |         1
    lcf     | 2020 | dvhh   | CB1124t | 608 | numeric | scale             | Soft drinks - children and adults                                                |         1
    lcf     | 2020 | dvhh   | CB1125t | 609 | numeric | scale             | Hot food - children and adults                                                   |         1
    lcf     | 2020 | dvhh   | CB1126t | 610 | numeric | scale             | Cold food - children and adults                                                  |         1
    lcf     | 2020 | dvhh   | CB1127t | 611 | numeric | scale             | Hot take away meal eaten at home - children and adults                           |         1
    lcf     | 2020 | dvhh   | CB1128t | 612 | numeric | scale             | Cold take away meal eaten at home - children and adults                          |         1
    lcf     | 2020 | dvhh   | CB112Bt | 613 | numeric | scale             | Contract catering (food)                                                         |         1
    lcf     | 2020 | dvhh   | CB1213t | 614 | numeric | scale             | Meals bought and eaten at workplace - children and adults                        |         1

Pos. = 576	Variable = C21111t	Variable label = Spirits and liqueurs (brought home) - children and adults
This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for C21111t

Pos. = 577	Variable = C21211t	Variable label = Wine from grape or other fruit (brought home) - children and adults
This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for C21211t

Pos. = 578	Variable = C21212t	Variable label = Fortified wine (brought home) - children and adults
This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for C21212t

Pos. = 579	Variable = C21213t	Variable label = Ciders and Perry (brought home) - children and adults
This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for C21213t

Pos. = 580	Variable = C21214t	Variable label = Alcopops (brought home) - children and adults
This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for C21214t

Pos. = 581	Variable = C21221t	Variable label = Champagne and sparkling wines (brought home) - children and adults
This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for C21221t

Pos. = 582	Variable = C21311t	Variable label = Beer and lager (brought home) - children and adults
This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for C21311t

Pos. = 583	Variable = C22111t	Variable label = Cigarettes - children and adults
This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for C22111t

Pos. = 584	Variable = C22121t	Variable label = Cigars - children and adults
This variable is    numeric, the SPSS measurement level is SCALE
    Value label information for C22121t

Pos. = 585	Variable = C22131t	Variable label = Other tobacco - children and adults
This variable is    numeric, the SPSS measurement level is SCALE

lcf     | 2020 | dvhh   | CB111Ct | 597 | numeric | scale             | Spirits and liqueurs (away from home)                                            |         1
    lcf     | 2020 | dvhh   | CB111Dt | 598 | numeric | scale             | Wine from grape or other fruit (away from home)                                  |         1
    lcf     | 2020 | dvhh   | CB111Et | 599 | numeric | scale             | Fortified wines (away from home)                                                 |         1
    lcf     | 2020 | dvhh   | CB111Ft | 600 | numeric | scale             | Ciders and Perry (away from home)                                                |         1
    lcf     | 2020 | dvhh   | CB111Gt | 601 | numeric | scale             | Alcopops (away from home)                                                        |         1
    lcf     | 2020 | dvhh   | CB111Ht | 602 | numeric | scale             | Champagne and sparkling wines (away from home)                                   |         1
    lcf     | 2020 | dvhh   | CB111It | 603 | numeric | scale             | Beer and lager (away from home)                                                  |         1
    lcf     | 2020 | dvhh   | CB111Jt | 604 | numeric | scale             | Round of drinks (away from home)                                                 |         1

SWEETS
    Pos. = 467	Variable = C11831c	Variable label = Chocolate - children, aged between 7 and 15
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for C11831c
    
    Pos. = 468	Variable = C11841c	Variable label = Confectionery products - children, aged between 7 and 15
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for C11841c
    
    Pos. = 469	Variable = C11851c	Variable label = Edible ices and ice cream - children, aged between 7 and 15
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for C11851c
    
    Pos. = 470	Variable = C11861c	Variable label = Other sugar products - children, aged between 7 and 15
    dataset | year | tables |  name   | pos | var_fmt | measurement_level |                                        label                                         | data_type 
    ---------+------+--------+---------+-----+---------+-------------------+--------------------------------------------------------------------------------------+-----------
    lcf     | 2020 | dvhh   | C11111t | 509 | numeric | scale             | Rice - children and adults                                                           |         1
    lcf     | 2020 | dvhh   | C11121t | 510 | numeric | scale             | Bread - children and adults                                                          |         1
    lcf     | 2020 | dvhh   | C11122t | 511 | numeric | scale             | Buns, crispbread and biscuits - children and adults                                  |         1
    lcf     | 2020 | dvhh   | C11131t | 512 | numeric | scale             | Pasta products - children and adults                                                 |         1
    lcf     | 2020 | dvhh   | C11141t | 513 | numeric | scale             | Cakes and puddings - children and adults                                             |         1
    lcf     | 2020 | dvhh   | C11142t | 514 | numeric | scale             | Pastry (savoury) - children and adults                                               |         1
    lcf     | 2020 | dvhh   | C11151t | 515 | numeric | scale             | Other breads and cereals - children and adults                                       |         1
    lcf     | 2020 | dvhh   | C11211t | 516 | numeric | scale             | Beef (fresh, chilled or frozen) - children and adults                                |         1
    lcf     | 2020 | dvhh   | C11221t | 517 | numeric | scale             | Pork (fresh, chilled or frozen) - children and adults                                |         1
    lcf     | 2020 | dvhh   | C11231t | 518 | numeric | scale             | Lamb (fresh, chilled or frozen) - children and adults                                |         1
    lcf     | 2020 | dvhh   | C11241t | 519 | numeric | scale             | Poultry (fresh, chilled or frozen) - children and adults                             |         1
    lcf     | 2020 | dvhh   | C11251t | 520 | numeric | scale             | Sausages - children and adults                                                       |         1
    lcf     | 2020 | dvhh   | C11252t | 521 | numeric | scale             | Bacon and ham - children and adults                                                  |         1
    lcf     | 2020 | dvhh   | C11253t | 522 | numeric | scale             | Offal, pâté etc. - children and adults                                               |         1
    lcf     | 2020 | dvhh   | C11261t | 523 | numeric | scale             | Other preserved or processed meat and meat preparations - children and adults        |         1
    lcf     | 2020 | dvhh   | C11271t | 524 | numeric | scale             | Other fresh, chilled or frozen edible meat - children and adults                     |         1
    lcf     | 2020 | dvhh   | C11311t | 525 | numeric | scale             | Fish (fresh, chilled or frozen) - children and adults                                |         1
    lcf     | 2020 | dvhh   | C11321t | 526 | numeric | scale             | Seafood (fresh, chilled or frozen) - children and adults                             |         1
    lcf     | 2020 | dvhh   | C11331t | 527 | numeric | scale             | Dried, smoked or salted fish and seafood - children and adults                       |         1
    lcf     | 2020 | dvhh   | C11341t | 528 | numeric | scale             | Other preserved or processed fish and seafood and preparations - children and adults |         1
    lcf     | 2020 | dvhh   | C11411t | 529 | numeric | scale             | Whole milk - children and adults                                                     |         1
    lcf     | 2020 | dvhh   | C11421t | 530 | numeric | scale             | Low fat milk - children and adults                                                   |         1
    lcf     | 2020 | dvhh   | C11431t | 531 | numeric | scale             | Preserved milk - children and adults                                                 |         1
    lcf     | 2020 | dvhh   | C11441t | 532 | numeric | scale             | Yoghurt - children and adults                                                        |         1
    lcf     | 2020 | dvhh   | C11451t | 533 | numeric | scale             | Cheese and curd - children and adults                                                |         1
    lcf     | 2020 | dvhh   | C11461t | 534 | numeric | scale             | Other milk products - children and adults                                            |         1
    lcf     | 2020 | dvhh   | C11471t | 535 | numeric | scale             | Eggs - children and adults                                                           |         1
    lcf     | 2020 | dvhh   | C11511t | 536 | numeric | scale             | Butter - children and adults                                                         |         1
    lcf     | 2020 | dvhh   | C11521t | 537 | numeric | scale             | Margarine and other vegetable fats - children and adults                             |         1
    lcf     | 2020 | dvhh   | C11522t | 538 | numeric | scale             | Peanut butter - children and adults                                                  |         1
    lcf     | 2020 | dvhh   | C11531t | 539 | numeric | scale             | Olive oil - children and adults                                                      |         1
    lcf     | 2020 | dvhh   | C11541t | 540 | numeric | scale             | Edible oils - children and adults                                                    |         1
    lcf     | 2020 | dvhh   | C11551t | 541 | numeric | scale             | Other edible animal fats - children and adults                                       |         1
    lcf     | 2020 | dvhh   | C11611t | 542 | numeric | scale             | Citrus fruits (fresh) - children and adults                                          |         1
    lcf     | 2020 | dvhh   | C11621t | 543 | numeric | scale             | Bananas (fresh) - children and adults                                                |         1
    lcf     | 2020 | dvhh   | C11631t | 544 | numeric | scale             | Apples (fresh) - children and adults                                                 |         1
    lcf     | 2020 | dvhh   | C11641t | 545 | numeric | scale             | Pears (fresh) - children and adults                                                  |         1
    lcf     | 2020 | dvhh   | C11651t | 546 | numeric | scale             | Stone fruits (fresh) - children and adults                                           |         1
    lcf     | 2020 | dvhh   | C11661t | 547 | numeric | scale             | Berries (fresh) - children and adults                                                |         1
    lcf     | 2020 | dvhh   | C11671t | 548 | numeric | scale             | Other fresh, chilled or frozen fruits - children and adults                          |         1
    lcf     | 2020 | dvhh   | C11681t | 549 | numeric | scale             | Dried fruit and nuts - children and adults                                           |         1
    lcf     | 2020 | dvhh   | C11691t | 550 | numeric | scale             | Preserved fruit and fruit-based products - children and adults                       |         1
    lcf     | 2020 | dvhh   | C11711t | 551 | numeric | scale             | Leaf and stem vegetables (fresh or chilled) - children and adults                    |         1
    lcf     | 2020 | dvhh   | C11721t | 552 | numeric | scale             | Cabbages (fresh or chilled) - children and adults                                    |         1
    lcf     | 2020 | dvhh   | C11731t | 553 | numeric | scale             | Vegetables grown for their fruit (fresh, chilled or frozen) - children and adults    |         1
    lcf     | 2020 | dvhh   | C11741t | 554 | numeric | scale             | Root crops, non-starchy bulbs and mushrooms (fresh or frozen) - children and adults  |         1
    lcf     | 2020 | dvhh   | C11751t | 555 | numeric | scale             | Dried vegetables - children and adults                                               |         1
    lcf     | 2020 | dvhh   | C11761t | 556 | numeric | scale             | Other preserved or processed vegetables - children and adults                        |         1
    lcf     | 2020 | dvhh   | C11771t | 557 | numeric | scale             | Potatoes - children and adults                                                       |         1
    lcf     | 2020 | dvhh   | C11781t | 558 | numeric | scale             | Other tubers and products of tuber vegetables - children and adults                  |         1
    lcf     | 2020 | dvhh   | C11811t | 559 | numeric | scale             | Sugar - children and adults                                                          |         1
    lcf     | 2020 | dvhh   | C11821t | 560 | numeric | scale             | Jams, marmalades - children and adults                                               |         1
    lcf     | 2020 | dvhh   | C11831t | 561 | numeric | scale             | Chocolate - children and adults                                                      |         1
    lcf     | 2020 | dvhh   | C11841t | 562 | numeric | scale             | Confectionery products - children and adults                                         |         1
    lcf     | 2020 | dvhh   | C11851t | 563 | numeric | scale             | Edible ices and ice cream - children and adults                                      |         1
    lcf     | 2020 | dvhh   | C11861t | 564 | numeric | scale             | Other sugar products - children and adults                                           |         1
    lcf     | 2020 | dvhh   | C11911t | 565 | numeric | scale             | Sauces, condiments - children and adults                                             |         1
    lcf     | 2020 | dvhh   | C11921t | 566 | numeric | scale             | Salt, spices and culinary herbs - children and adults                                |         1
    lcf     | 2020 | dvhh   | C11931t | 567 | numeric | scale             | Baker's yeast, dessert preparations, soups - children and adults                     |         1
    lcf     | 2020 | dvhh   | C11941t | 568 | numeric | scale             | Other food products - children and adults                                            |         1
    lcf     | 2020 | dvhh   | C12111t | 569 | numeric | scale             | Coffee - children and adults                                                         |         1
    lcf     | 2020 | dvhh   | C12121t | 570 | numeric | scale             | Tea - children and adults                                                            |         1
    lcf     | 2020 | dvhh   | C12131t | 571 | numeric | scale             | Cocoa and powdered chocolate - children and adults                                   |         1
    lcf     | 2020 | dvhh   | C12211t | 572 | numeric | scale             | Mineral or spring waters - children and adults                                       |         1
    lcf     | 2020 | dvhh   | C12221t | 573 | numeric | scale             | Soft drinks - children and adults                                                    |         1
    lcf     | 2020 | dvhh   | C12231t | 574 | numeric | scale             | Fruit juices - children and adults                                                   |         1
    lcf     | 2020 | dvhh   | C12241t | 575 | numeric | scale             | Vegetable juices - children and adults                                               |         1
    :

    VATABLE FOOD - from resteraunts and hotels

    Pos. = 610	Variable = CB1126t	Variable label = Cold food - children and adults
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for CB1126t

    Pos. = 611	Variable = CB1127t	Variable label = Hot take away meal eaten at home - children and adults
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for CB1127t

    Pos. = 612	Variable = CB1128t	Variable label = Cold take away meal eaten at home - children and adults
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for CB1128t

    Pos. = 613	Variable = CB112Bt	Variable label = Contract catering (food)
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for CB112Bt

    Pos. = 614	Variable = CB1213t	Variable label = Meals bought and eaten at workplace - children and adults
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for CB1213t

    Pos. = 615	Variable = CB1311t	Variable label = Catered food - eaten on premises - children and adults
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for CB1311t

    Pos. = 389	Variable = CB1111	Variable label = Catered food non-alcoholic drink eaten / drunk on premises - adults
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for CB1111
    
    Pos. = 390	Variable = CB1112	Variable label = Confectionery eaten off premises - adults
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for CB1112
    
    Pos. = 391	Variable = CB1113	Variable label = Ice cream eaten off premises - adults
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for CB1113
    
    Pos. = 392	Variable = CB1114	Variable label = Soft drinks drunk off premises - adults
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for CB1114
    
    Pos. = 393	Variable = CB1115	Variable label = Hot food eaten off premises - adults
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for CB1115
    
    Pos. = 394	Variable = CB1116	Variable label = Cold food eaten off premises - adults
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for CB1116

    # 02) alcohol and tobacco subsets
    lcf     | 2020 | dvhh   | CB111Ct | 597 | numeric | scale             | Spirits and liqueurs (away from home)                                            |         1
    lcf     | 2020 | dvhh   | CB111Dt | 598 | numeric | scale             | Wine from grape or other fruit (away from home)                                  |         1
    lcf     | 2020 | dvhh   | CB111Et | 599 | numeric | scale             | Fortified wines (away from home)                                                 |         1
    lcf     | 2020 | dvhh   | CB111Ft | 600 | numeric | scale             | Ciders and Perry (away from home)                                                |         1
    lcf     | 2020 | dvhh   | CB111Gt | 601 | numeric | scale             | Alcopops (away from home)                                                        |         1
    lcf     | 2020 | dvhh   | CB111Ht | 602 | numeric | scale             | Champagne and sparkling wines (away from home)                                   |         1
    lcf     | 2020 | dvhh   | CB111It | 603 | numeric | scale             | Beer and lager (away from home)                                                  |         1
    lcf     | 2020 | dvhh   | CB111Jt | 604 | numeric | scale             | Round of drinks (away from home)                                                 |         1

Children’s Clothes and footwear
C31231 Variable label = Boys' outer garments (5-15) - adults
C31232 Variable label = Girls' outer garments (5-15) - adults
C31233 Variable label = Infants' outer garments (Under 5) - adults
C31234 Variable label = Children's under garments (Under 16) - adults
C31313 Variable label = Children's accessories - adults
C32131 Variable label = Footwear for children (5-15) and infants - adults

DOMESTIC Fuel

(B175 - B178) + B222 + (B170 - B173) + B221 + B018 + B017 + C41211t + C43111t + C43112t + C43212c + C44112u + C44211t + C45112t + C45114t + C45212t + C45214t + C45222t + C45312t + C45411t + C45412t + C45511t 

dataset | year | tables |  name   | pos | var_fmt | measurement_level |                                              label                                              | data_type 
---------+------+--------+---------+-----+---------+-------------------+-------------------------------------------------------------------------------------------------+-----------
x lcf     | 2020 | dvhh   | B017    |  62 | numeric | scale             | Oil for central heating - last quarter                                                          |         1
x lcf     | 2020 | dvhh   | B018    |  63 | numeric | scale             | Bottled gas for central heating                                                                 |         1
x lcf     | 2020 | dvhh   | B170    | 116 | numeric | scale             | Gas amount paid in last account                                                                 |         1
x lcf     | 2020 | dvhh   | B173    | 133 | numeric | scale             | Rebate for separate Gas amount                                                                  |         1
x lcf     | 2020 | dvhh   | B175    | 134 | numeric | scale             | Electricity amount paid in last account                                                         |         1
x lcf     | 2020 | dvhh   | B178    | 135 | numeric | scale             | Rebate for separate Electricity amount                                                          |         1
x lcf     | 2020 | dvhh   | C45112t |   1 | numeric | scale             | Second dwelling: electricity account pay - children and adults                                  |         1
x lcf     | 2020 | dvhh   | C45114t |   1 | numeric | scale             | Electricity slot meter payment - children and adults                                            |         1
x lcf     | 2020 | dvhh   | C45214t |   1 | numeric | scale             | Gas slot meter payment - children and adults                                                    |         1
x lcf     | 2020 | dvhh   | C45222t |   1 | numeric | scale             | Bottled gas - other - children and adults                                                       |         1
x lcf     | 2020 | dvhh   | C45312t |   1 | numeric | scale             | Paraffin - children and adults                                                                  |         1
x lcf     | 2020 | dvhh   | C45411t |   1 | numeric | scale             | Coal and coke - children and adults                                                             |         1
x lcf     | 2020 | dvhh   | C45412t |   1 | numeric | scale             | Wood and peat - children and adults                                                             |         1
lcf     | 2020 | dvhh   | C45511t |   1 | numeric | scale             | Hot water, steam and ice - children and adults                                                  |         1

    # 05 Furnishings, Household Equipment and Routine Maintenance of the House

    :furnishings P605

    # 06 Health 

    :health 
    
    :hospital # Care or medical treatment provided by a qualifying institution like a hospital, hospice or nursing home 	Exempt 	VAT Notice 701/31
    :prescriptions # Dispensing of prescriptions by a registered pharmacist 	0% 	VAT Notice 701/57
    :doctors  # Health services provided by registered doctors, dentists, opticians, pharmacists and other health professionals 	Exempt 	VAT Notice 701/57
    :incontinence # Incontinence products 	0% 	VAT Notice 701/7
    :maternity_pads # Maternity pads 	0% 	VAT Notice 701/18
    :sanitary_products # Sanitary protection products 	0% 	VAT Notice 701/18
    :low_vision_aids # Low vision aids 	0% 	Equipment for blind or partially sighted people
    :disability_aids 


dataset | year |     tables      |  name   | pos | var_fmt | measurement_level |                                              label                                              | data_type 
---------+------+-----------------+---------+-----+---------+-------------------+-------------------------------------------------------------------------------------------------+-----------
lcf     | 2020 | dvhh            | C61111c | 960 | numeric | scale             | NHS prescription charges and payments - children, aged between 7 and 15                         |         1
lcf     | 2020 | dvhh            | C61112c | 961 | numeric | scale             | Medicines and medical goods (not NHS) - children, aged between 7 and 15                         |         1
lcf     | 2020 | dvhh            | C61211c | 962 | numeric | scale             | Other medical products (eg plasters, condoms, tubigrip, etc.) - children, aged between 7 and 15 |         1
lcf     | 2020 | dvhh            | C61311c | 963 | numeric | scale             | Purchase of spectacles, lenses, prescription glasses - children, aged between 7 and 15          |         1
lcf     | 2020 | dvhh            | C61312c | 964 | numeric | scale             | Accessories repairs to spectacles lenses - children, aged between 7 and 15                      |         1
lcf     | 2020 | dvhh            | C61313c | 965 | numeric | scale             | Non-optical appliances and equipment (eg wheelchairs, etc.) - children, aged between 7 and 15   |         1
lcf     | 2020 | dvhh            | C62111c | 966 | numeric | scale             | NHS medical services - children, aged between 7 and 15                                          |         1
lcf     | 2020 | dvhh            | C62112c | 967 | numeric | scale             | Private medical services - children, aged between 7 and 15                                      |         1
lcf     | 2020 | dvhh            | C62113c | 968 | numeric | scale             | NHS optical services - children, aged between 7 and 15                                          |         1
lcf     | 2020 | dvhh            | C62114c | 969 | numeric | scale             | Private optical services - children, aged between 7 and 15                                      |         1
lcf     | 2020 | dvhh            | C62211c | 970 | numeric | scale             | NHS dental services - children, aged between 7 and 15                                           |         1
lcf     | 2020 | dvhh            | C62212c | 971 | numeric | scale             | Private dental services - children, aged between 7 and 15                                       |         1
lcf     | 2020 | dvhh            | C62311c | 972 | numeric | scale             | Services of medical analysis laboratorie - children, aged between 7 and 15                      |         1
lcf     | 2020 | dvhh            | C62321c | 973 | numeric | scale             | Services of NHS medical auxiliaries - children, aged between 7 and 15                           |         1
lcf     | 2020 | dvhh            | C62322c | 974 | numeric | scale             | Services of private medical auxiliaries - children, aged between 7 and 15                       |         1
lcf     | 2020 | dvhh            | C62331c | 975 | numeric | scale             | Non-hospital ambulance services etc. - children, aged between 7 and 15                          |         1
lcf     | 2020 | dvhh            | C63111c | 976 | numeric | scale             | Hospital services - children, aged between 7 and 15                                             |         1

DOMESTIC Fuel

(B175 - B178) + B222 + (B170 - B173) + B221 + B018 + B017 + C41211t + C43111t + C43112t + C43212c + C44112u + C44211t + C45112t + C45114t + C45212t + C45214t + C45222t + C45312t + C45411t + C45412t + C45511t 

dataset | year | tables |  name   | pos | var_fmt | measurement_level |                                              label                                              | data_type 
---------+------+--------+---------+-----+---------+-------------------+-------------------------------------------------------------------------------------------------+-----------
lcf     | 2020 | dvhh   | B017    |  62 | numeric | scale             | Oil for central heating - last quarter                                                          |         1
lcf     | 2020 | dvhh   | B018    |  63 | numeric | scale             | Bottled gas for central heating                                                                 |         1
lcf     | 2020 | dvhh   | B170    | 116 | numeric | scale             | Gas amount paid in last account                                                                 |         1
lcf     | 2020 | dvhh   | B173    | 133 | numeric | scale             | Rebate for separate Gas amount                                                                  |         1
lcf     | 2020 | dvhh   | B175    | 134 | numeric | scale             | Electricity amount paid in last account                                                         |         1
lcf     | 2020 | dvhh   | B178    | 135 | numeric | scale             | Rebate for separate Electricity amount                                                          |         1
lcf     | 2020 | dvhh   | C41211t |   1 | numeric | scale             | Second dwelling - rent - children and adults                                                    |         1
lcf     | 2020 | dvhh   | C43111t |   1 | numeric | scale             | Paint, wallpaper, timber - children and adults                                                  |         1
lcf     | 2020 | dvhh   | C43112t |   1 | numeric | scale             | Equipment hire, small materials - children and adults                                           |         1
lcf     | 2020 | dvhh   | C43212c | 906 | numeric | scale             | Other services for the maintenance and repair of the dwelling - children, aged between 7 and 15 |         1
lcf     | 2020 | dvhh   | C44211t |   1 | numeric | scale             | Refuse collection, including skip hire - children and adults                                    |         1
lcf     | 2020 | dvhh   | C45112t |   1 | numeric | scale             | Second dwelling: electricity account pay - children and adults                                  |         1
lcf     | 2020 | dvhh   | C45114t |   1 | numeric | scale             | Electricity slot meter payment - children and adults                                            |         1
lcf     | 2020 | dvhh   | C45214t |   1 | numeric | scale             | Gas slot meter payment - children and adults                                                    |         1
lcf     | 2020 | dvhh   | C45222t |   1 | numeric | scale             | Bottled gas - other - children and adults                                                       |         1
lcf     | 2020 | dvhh   | C45312t |   1 | numeric | scale             | Paraffin - children and adults                                                                  |         1
lcf     | 2020 | dvhh   | C45411t |   1 | numeric | scale             | Coal and coke - children and adults                                                             |         1
lcf     | 2020 | dvhh   | C45412t |   1 | numeric | scale             | Wood and peat - children and adults                                                             |         1
lcf     | 2020 | dvhh   | C45511t |   1 | numeric | scale             | Hot water, steam and ice - children and adults                                                  |         1


    # 07	Transport

    :other_transport
    :bus_boat_and_train_tickets
    :air_travel 
    :petrol
    :diesel
    :other_motor_oils

    # 08	Communication



    #  09	Recreation

    :other_recreation 
    :books
    :newspapers
    :periodicals

    # 10 (A)	Education

    :education

    # 11 (B)	Restaurant and Hotels - note takeaway food is already covered above

    lcf     | 2020 | dvhh   | B260    | 183 | numeric | scale             | School meals - total amount paid last week                                       |         1
    lcf     | 2020 | dvhh   | B482    | 224 | numeric | scale             | Holiday hotel within United Kingdom                                              |         1
    lcf     | 2020 | dvhh   | B483    | 225 | numeric | scale             | Holiday hotel outside United Kingdom                                             |         1
    lcf     | 2020 | dvhh   | B484    | 226 | numeric | scale             | Holiday self-cathering within United Kingdom                                     |         1
    lcf     | 2020 | dvhh   | B485    | 227 | numeric | scale             | Holiday self-cathering outside United Kingdom                                    |         1
    lcf     | 2020 | dvhh   | CB1111t | 586 | numeric | scale             | Catered food non-alcoholic drink eaten / drunk on premises - children and adults |         1
    lcf     | 2020 | dvhh   | CB1112t | 587 | numeric | scale             | Confectionery eaten off premises - children and adults                           |         1
    lcf     | 2020 | dvhh   | CB1113t | 588 | numeric | scale             | Ice cream eaten off premises - children and adults                               |         1
    lcf     | 2020 | dvhh   | CB1114t | 589 | numeric | scale             | Soft drinks eaten off premises - children and adults                             |         1
    lcf     | 2020 | dvhh   | CB1115t | 590 | numeric | scale             | Hot food eaten off premises - children and adults                                |         1
    lcf     | 2020 | dvhh   | CB1116t | 591 | numeric | scale             | Cold food eaten off premises - children and adults                               |         1
    lcf     | 2020 | dvhh   | CB1117c | 492 | numeric | scale             | Confectionery (child) - children, aged between 7 and 15                          |         1
    lcf     | 2020 | dvhh   | CB1118c | 493 | numeric | scale             | Ice cream (child) - children, aged between 7 and 15                              |         1
    lcf     | 2020 | dvhh   | CB1119c | 494 | numeric | scale             | Soft drinks (child) - children, aged between 7 and 15                            |         1
    lcf     | 2020 | dvhh   | CB111Ac | 495 | numeric | scale             | Hot food (child)                                                                 |         1
    lcf     | 2020 | dvhh   | CB111Bc | 496 | numeric | scale             | Cold food (child)                                                                |         1
    lcf     | 2020 | dvhh   | CB1121t | 605 | numeric | scale             | Food non-alcoholic drinks eaten drunk on premises - children and adults          |         1
    lcf     | 2020 | dvhh   | CB1122t | 606 | numeric | scale             | Confectionery - children and adults                                              |         1
    lcf     | 2020 | dvhh   | CB1123t | 607 | numeric | scale             | Ice cream - children and adults                                                  |         1
    lcf     | 2020 | dvhh   | CB1124t | 608 | numeric | scale             | Soft drinks - children and adults                                                |         1
    lcf     | 2020 | dvhh   | CB1125t | 609 | numeric | scale             | Hot food - children and adults                                                   |         1
    lcf     | 2020 | dvhh   | CB1126t | 610 | numeric | scale             | Cold food - children and adults                                                  |         1
    lcf     | 2020 | dvhh   | CB1127t | 611 | numeric | scale             | Hot take away meal eaten at home - children and adults                           |         1
    lcf     | 2020 | dvhh   | CB1128t | 612 | numeric | scale             | Cold take away meal eaten at home - children and adults                          |         1
    lcf     | 2020 | dvhh   | CB112Bt | 613 | numeric | scale             | Contract catering (food)                                                         |         1
    lcf     | 2020 | dvhh   | CB1213t | 614 | numeric | scale             | Meals bought and eaten at workplace - children and adults                        |         1
    dataset | year | tables |  name   | pos | var_fmt | measurement_level |                                        label                                         | data_type 
    ---------+------+--------+---------+-----+---------+-------------------+--------------------------------------------------------------------------------------+-----------
    lcf     | 2020 | dvhh   | B110    |  90 | numeric | scale             | Structure insurance - last payment                                                   |         1
    lcf     | 2020 | dvhh   | B168    | 115 | numeric | scale             | Content insurance amount of last premium                                             |         1
    lcf     | 2020 | dvhh   | B1802   | 137 | numeric | scale             | Bank and Building societies charges - net amount last 3 months                       |         1
    lcf     | 2020 | dvhh   | B188    | 142 | numeric | scale             | Vehicle insurance - amount paid last year                                            |         1
    lcf     | 2020 | dvhh   | B229    | 168 | numeric | scale             | Medical insurance - total amount premium                                             |         1
    lcf     | 2020 | dvhh   | B238    | 172 | numeric | scale             | Annual standing charge for credit cards                                              |         1
    lcf     | 2020 | dvhh   | B273    | 201 | numeric | scale             | Furniture removal and or storage                                                     |         1
    lcf     | 2020 | dvhh   | B280    | 202 | numeric | scale             | Property transaction - purchase and sale                                             |         1
    lcf     | 2020 | dvhh   | B281    | 203 | numeric | scale             | Property transaction - sale only                                                     |         1
    lcf     | 2020 | dvhh   | B282    | 204 | numeric | scale             | Property transaction - purchase only                                                 |         1
    lcf     | 2020 | dvhh   | B283    | 205 | numeric | scale             | Property transaction - other payments                                                |         1
    lcf     | 2020 | dvhh   | CC1111t |   1 | numeric | scale             | Hairdressing salons and personal grooming - children and adults                      |         1
    lcf     | 2020 | dvhh   | CC1211t |   1 | numeric | scale             | Electrical appliances for personal care - children and adults                        |         1
    lcf     | 2020 | dvhh   | CC1311t |   1 | numeric | scale             | Toilet paper - children and adults                                                   |         1
    lcf     | 2020 | dvhh   | CC1312t |   1 | numeric | scale             | Toiletries (disposables - tampons, lip balm, toothpaste, etc.) - children and adults |         1
    lcf     | 2020 | dvhh   | CC1313t |   1 | numeric | scale             | Bar of soap, liquid soap, shower gel, etc. - children and adults                     |         1
    lcf     | 2020 | dvhh   | CC1314t |   1 | numeric | scale             | Toilet requisites (durables - razors, hairbrushes, etc.) - children and adults       |         1
    lcf     | 2020 | dvhh   | CC1315t |   1 | numeric | scale             | Hair products - children and adults                                                  |         1
    lcf     | 2020 | dvhh   | CC1316t |   1 | numeric | scale             | Cosmetics and related accessories - children and adults                              |         1
    lcf     | 2020 | dvhh   | CC3111t |   1 | numeric | scale             | Jewellery, clocks and watches - children and adults                                  |         1
    lcf     | 2020 | dvhh   | CC3112t |   1 | numeric | scale             | Repairs to personal goods - children and adults                                      |         1
    lcf     | 2020 | dvhh   | CC3211t |   1 | numeric | scale             | Leather and travel goods (excluding baby items) - children and adults                |         1
    lcf     | 2020 | dvhh   | CC3221t |   1 | numeric | scale             | Other personal effects n.e.c. - children and adults                                  |         1
    lcf     | 2020 | dvhh   | CC1317t |   1 | numeric | scale             | Baby toiletries and accessories (disposable) - children and adults                   |         1
    lcf     | 2020 | dvhh   | CC3222t |   1 | numeric | scale             | Baby equipment (excluding prams and pushchairs) - children and adults                |         1
    lcf     | 2020 | dvhh   | CC3223t |   1 | numeric | scale             | Prams, pram accessories and pushchairs - children and adults                         |         1
    lcf     | 2020 | dvhh   | CC3224t |   1 | numeric | scale             | Sunglasses (non-prescription) - children and adults                                  |         1
    lcf     | 2020 | dvhh   | CC4111t |   1 | numeric | scale             | Residential homes - children and adults                                              |         1
    lcf     | 2020 | dvhh   | CC4112t |   1 | numeric | scale             | Home help - children and adults                                                      |         1
    lcf     | 2020 | dvhh   | CC4121t |   1 | numeric | scale             | Nursery, creche, playschools - children and adults                                   |         1
    lcf     | 2020 | dvhh   | CC4122t |   1 | numeric | scale             | Child care payments - children and adults                                            |         1
    lcf     | 2020 | dvhh   | CC5213t |   1 | numeric | scale             | Insurance for household appliances - children and adults                             |         1
    lcf     | 2020 | dvhh   | CC5311c |   1 | numeric | scale             | Private medical insurance - children, aged between 7 and 15                          |         1
    lcf     | 2020 | dvhh   | CC5411c |   1 | numeric | scale             | Vehicle insurance - children, aged between 7 and 15                                  |         1
    lcf     | 2020 | dvhh   | CC5412t |   1 | numeric | scale             | Boat insurance (not home) - children and adults                                      |         1
    lcf     | 2020 | dvhh   | CC5413t |   1 | numeric | scale             | Non-package holiday, other travel insurance - children and adults                    |         1
    lcf     | 2020 | dvhh   | CC6211c |   1 | numeric | scale             | Bank service charges - children, aged between 7 and 15                               |         1
    lcf     | 2020 | dvhh   | CC6212t |   1 | numeric | scale             | Bank and Post Office counter charges - children and adults                           |         1
    lcf     | 2020 | dvhh   | CC6214t |   1 | numeric | scale             | Commission travellers cheques and currency - children and adults                     |         1
    lcf     | 2020 | dvhh   | CC7111t |   1 | numeric | scale             | Legal fees paid to banks - children and adults                                       |         1
    lcf     | 2020 | dvhh   | CC7112t |   1 | numeric | scale             | Legal fees paid to solicitors - children and adults                                  |         1
    lcf     | 2020 | dvhh   | CC7113t |   1 | numeric | scale             | Other payments for services eg photocopy - children and adults                       |         1
    lcf     | 2020 | dvhh   | CC7114t |   1 | numeric | scale             | Funeral expenses - children and adults                                               |         1
    lcf     | 2020 | dvhh   | CC7115t |   1 | numeric | scale             | Other professional fees including court fines - children and adults                  |         1
    lcf     | 2020 | dvhh   | CC7116t |   1 | numeric | scale             | TU and professional organisations - children and adults                              |         1

    # 20 (K)	Non-Consumption Expenditure

    :non_consumption_expenditure 

    dataset | year | tables |  name   | pos | var_fmt | measurement_level |                                          label                                           | data_type 
    ---------+------+--------+---------+-----+---------+-------------------+------------------------------------------------------------------------------------------+-----------
    lcf     | 2020 | dvhh   | B030    |  68 | numeric | scale             | Domestic rates - last net payment                                                        |         1
    lcf     | 2020 | dvhh   | B038p   |  69 | numeric | scale             | Council tax - last payment weekly amount                                                 |         1
    lcf     | 2020 | dvhh   | B130    |  92 | numeric | scale             | Mortgage interest only - last payment                                                    |         1
    lcf     | 2020 | dvhh   | B150    |  94 | numeric | scale             | Mortgage interest / principle - interest paid                                            |         1
    lcf     | 2020 | dvhh   | B179    | 136 | numeric | scale             | Vehicle road tax - amount refunded last                                                  |         1
    lcf     | 2020 | dvhh   | B187    | 141 | numeric | scale             | Vehicle road tax - amount paid last year                                                 |         1
    lcf     | 2020 | dvhh   | B1961   | 150 | numeric | scale             | Life insurance premium - amount premium                                                  |         1
    lcf     | 2020 | dvhh   | B199    | 152 | numeric | scale             | Insurance for household and electrical a                                                 |         1
    lcf     | 2020 | dvhh   | B2011   | 154 | numeric | scale             | Mortgage endowment policy amount premium                                                 |         1
    lcf     | 2020 | dvhh   | B205    | 157 | numeric | scale             | Friendly socs - deductions from main pay                                                 |         1
    lcf     | 2020 | dvhh   | B206    | 158 | numeric | scale             | Other insurance - total amount premium                                                   |         1
    lcf     | 2020 | dvhh   | B2081   | 160 | numeric | scale             | Mortgage protection amount premium                                                       |         1
    lcf     | 2020 | dvhh   | B228    | 167 | numeric | scale             | Personal pension                                                                         |         1
    lcf     | 2020 | dvhh   | B237    | 171 | numeric | scale             | Credit card interest payments                                                            |         1
    lcf     | 2020 | dvhh   | B265    | 188 | numeric | scale             | Maintenance allowance expenditure                                                        |         1
    lcf     | 2020 | dvhh   | B334h   |   1 | numeric | scale             | Money sent abroad - household                                                            |         1
    lcf     | 2020 | dvhh   | CC5111c |   1 | numeric | scale             | Life, death, non-house endowment - children, aged between 7 and 15                       |         1
    lcf     | 2020 | dvhh   | CC5312c |   1 | numeric | scale             | Accident, sickness, redundancy, animal insurance, etc. - children, aged between 7 and 15 |         1
    lcf     | 2020 | dvhh   | CC5511c |   1 | numeric | scale             | Other insurance - children, aged between 7 and 15                                        |         1
    lcf     | 2020 | dvhh   | CK1313t |   1 | numeric | scale             | Central heating installation (DIY) - children and adults                                 |         1
    lcf     | 2020 | dvhh   | CK1314t |   1 | numeric | scale             | Double Glazing, Kitchen Units, Sheds etc. - children and adults                          |         1
    lcf     | 2020 | dvhh   | CK1315t |   1 | numeric | scale             | Purchase of materials for Capital Improvements - children and adults                     |         1
    lcf     | 2020 | dvhh   | CK1316t |   1 | numeric | scale             | Bathroom fittings - children and adults                                                  |         1
    lcf     | 2020 | dvhh   | CK2111t |   1 | numeric | scale             | Food stamps, other food related expenditure - children and adults                        |         1
    lcf     | 2020 | dvhh   | CK3111t |   1 | numeric | scale             | Stamp duty, licences and fines (excluding motoring fines) - children and adults          |         1
    lcf     | 2020 | dvhh   | CK3112t |   1 | numeric | scale             | Motoring Fines - children and adults                                                     |         1
    lcf     | 2020 | dvhh   | CK4111t |   1 | numeric | scale             | Money spent abroad - children and adults                                                 |         1
    lcf     | 2020 | dvhh   | CK4112t |   1 | numeric | scale             | Duty free goods bought in UK - children and adults                                       |         1
    lcf     | 2020 | dvhh   | CK5111t |   1 | numeric | scale             | Savings, investments (excluding AVCs) - children and adults                              |         1
    lcf     | 2020 | dvhh   | CK5113t |   1 | numeric | scale             | Additional Voluntary Contributions - children and adults                                 |         1
    lcf     | 2020 | dvhh   | CK5212t |   1 | numeric | scale             | Money given to members for specific purposes: pocket money - children and adults         |         1
    lcf     | 2020 | dvhh   | CK5213t |   1 | numeric | scale             | Money given to members for specific purposes: school dinner - children and adults        |         1
    lcf     | 2020 | dvhh   | CK5214t |   1 | numeric | scale             | Money given to members for specific purposes: school travel - children and adults        |         1
    lcf     | 2020 | dvhh   | CK5215t |   1 | numeric | scale             | Money given to children for specific purposes - children and adults                      |         1
    lcf     | 2020 | dvhh   | CK5216t |   1 | numeric | scale             | Cash gifts to children - children and adults                                             |         1
    lcf     | 2020 | dvhh   | CK5221t |   1 | numeric | scale             | Money given to those outside the household - children and adults                         |         1
    lcf     | 2020 | dvhh   | CK5222t |   1 | numeric | scale             | Present - not specified - children and adults                                            |         1
    lcf     | 2020 | dvhh   | CK5223t |   1 | numeric | scale             | Charitable donations and subscriptions - children and adults                             |         1
    lcf     | 2020 | dvhh   | CK5224c |   1 | numeric | scale             | Money sent abroad - children, aged between 7 and 15                                      |         1
    lcf     | 2020 | dvhh   | CK5315c |   1 | numeric | scale             | Club instalment payment - children, aged between 7 and 15                                |         1
    

lcf     | 2020 | dvhh   | C31315  | 630 | numeric | scale             | Protective head gear (crash helmets) - adults                          |         1
lcf     | 2020 | dvhh   | C31315c | 896 | numeric | scale             | Protective head gear (crash helmets) - children, aged between 7 and 15 |         1
lcf     | 2020 | dvhh   | C31315t |   1 | numeric | scale             | Protective head gear (crash helmets) - children and adults             |         1

    :other_transport
    :bus_boat_and_train_tickets
    :air_travel
    :petrol
    :diesel
    :other_motor_oils

    Pos. = 721	Variable = C72211	Variable label = Petrol - adults
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for C72211
    
    Pos. = 722	Variable = C72212	Variable label = Diesel oil - adults
    This variable is    numeric, the SPSS measurement level is SCALE
        Value label information for C72212
    
    Pos. = 723	Variable = C72213	Variable label = Other motor oils - adults
    This variable is    numeric, the SPSS measurement level is SCALE
=#

end

function uprate_incomes!( frshh :: DataFrame, lcfhh :: DataFrame )
    for r in eachrow( frshh )
        dd = split(r.intdate, "/")
        y = parse(Int, dd[3])
        m = parse(Int, dd[1])
        q = div( m - 1, 3) + 1
        r.income = Uprating.uprate( r.income, y, q, Uprating.upr_nominal_gdp )
        println( "r.yearcode $(r.yearcode); r.mnthcode $(r.mnthcode); y=$y q=$q income=$(r.income) orig = $(r.income)")
    end
    for r in eachrow( lcfhh )
        #
        # This is e.g January REIS and I don't know what REIS means 
        #
        if r.a055 > 20
            r.a055 -= 20
        end
        q = ((r.a055-1) ÷ 3) + 1 # 1,2,3=q1 and so on
        # lcf year seems to be actual interview year 
        y = r.year
        r.income = Uprating.uprate( r.income, y, q, Uprating.upr_nominal_gdp )
    end
end

const TOPCODE = 2420.03

function within(x;min=min,max=max) 
    return if x < min min elseif x > max max else x end
end


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

function model_tenuremap(  t :: Tenure_Type ) :: Vector{Int}
    return frs_tenuremap( Int( t ) )
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
Value = 1.0	Label = Own it outright
	Value = 2.0	Label = Buying with mortgage
	Value = 3.0	Label = Part rent part mortgage
	Value = 4.0	Label = Rent it
	Value = 5.0	Label = Rent-free
	Value = 6.0	Label = Squatting
	Value = -9.0	Label = Not asked / applicable
	Value = -8.0	Label = Don't know/Refusal
=#
function was_tenuremap( tenure :: Int )::Vector{Int}

end

#=  WAS ten1r7
    Value = 1.0	Label = Own it outright
	Value = 2.0	Label = Buying with mortgage
	Value = 3.0	Label = Part rent part mortgage
	Value = 4.0	Label = Rent it
	Value = 5.0	Label = Rent-free
	Value = 6.0	Label = Squatting
	Value = -9.0	Label = Not asked / applicable
	Value = -8.0	Label = Don't know/Refusal

    llord7

Value = 1.0	Label = Local authority / council / Scottish Homes
	Value = 2.0	Label = Housing association / charitable trust / local housing company
	Value = 3.0	Label = Employer (organisation) of household member
	Value = 4.0	Label = Another organisation
	Value = 5.0	Label = Relative / friend of household member
	Value = 6.0	Label = Employer (individual) of household member
	Value = 7.0	Label = Another individual private landlord
	Value = -9.0	Label = Not asked / applicable
	Value = -8.0	Label = Don't know/ Refusal

=#
function was_tenuremap( was :: DataFrame  ) :: Vector{Int}
    @argcheck was.ten1r7 in 1:6 "was.ten1r7 out of range"
    out = if was.ten1r7 == 1 # o-outright
        6 
    elseif was.ten1r7 in 2:3
        5 # mortgaged
    elseif was.ten1r7 == 4 # rented
        if was.llord7 == 1
            1 # council
        elseif was.llord7 == 2
            2 # housing assoc
        elseif was.llord == 3:7
            if was.furnr7 in 1:2 # furnished, inc part
                4
            elseif was.furnr7 == 3
                3 # unfurnished
            else
                @assert false "was.furnr7 out-of-range $(was.furnr7)"
            end
        else
            @assert false "was.llord7 out of range $(was.llord7)"
        end
    elseif was.ten1r7 == 5
        7
    elseif was.ten1r7 == 6
        8
    end
    @assert out in 1:8
    return   lcf_tenuremap( out )
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

2nd level is London=1,REngland=2,Scotland=3,Wales=4,NI=5

WAS 
Value = 1.0	Label = Employee
	Value = 2.0	Label = Self-employed
	Value = 3.0	Label = Unemployed
	Value = 4.0	Label = Student
	Value = 5.0	Label = Looking after family home
	Value = 6.0	Label = Sick or disabled
	Value = 7.0	Label = Retired
	Value = 8.0	Label = Other
	Value = -9.0	Label = Not asked / applicable
	Value = -8.0	Label = Don't know/ Refusal
WAS 

Value = 96.0	Label = Never worked and long-term unemployed
	Value = 1.0	Label = Managerial and professional occupations
	Value = 2.0	Label = Intermediate occupations
	Value = 3.0	Label = Routine and manual occupations
	Value = 97.0	Label = Not classified
	Value = -8.0	Label = Don't know/ Refusal
	Value = -9.0	Label = Not asked / applicable

=#

"""
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

load 2 levels of region from LCF into a 3 vector - 1= actual/ 2=London/rEngland/Scot/Wales/Ni

"""
function lcf_regionmap( gorx :: Union{Int,Missing} ) :: Vector{Int}
    out = fill( 9998, 3 )
    if ismissing( gorx )
        ;
    elseif gorx == 7 # london
        out[1] = gorx
        out[2] = 1
    elseif gorx in 1:9
        out[1] = gorx
        out[2] = 2
    elseif gorx == 10 # wales
        out[1] = 10 
        out[2] = 4
    elseif gorx == 11 # scotland
        out[1] = 11
        out[2] = 3
    elseif gorx == 12
        out[1] = 12
        out[2] = 5
    else
        @assert false "unmatched gorx $gorx";
    end 
    return out
end

"""
Convoluted household type map. See the note `lcf_frs_composition_mapping.md`.
"""
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

function lcf_composition_map( a062 :: Int ) :: Vector{Int}
    mappings = (lcf1=[1],lcf2=[2],lcf3=[3,4],lcf4=[5,6],lcf5=[7,8],lcf6=[18,23,26,28],lcf7=[9,10],lcf8=[11,12],lcf9=[13,14,15,16,17],lcf10=[19,24,20,21,22,25,27,29,30])
    return composition_map( a062,  mappings, default=9998 )
end

function frs_composition_map( hhcomps :: Int ) :: Vector{Int}
    mappings=(frs1=[1,3],frs2=[2,4],frs3=[9],frs4=[10],frs5=[5,6,7],frs6=[8],frs7=[12],frs8=[13],frs9=[14],frs10=[11,15,16,17])
    return composition_map( hhcomps,  mappings, default=9999 )
end

## Move to Intermediate 
function model_composition_map( hh :: Household ) :: Vector{Int}
    num_male_pens = 0
    num_female_pens = 0
    num_male_npens = 0
    num_female_npens = 0
    num_children = 0
    for (k,p) in hh.people 
    if p.is_standard_child
            num_children += 1
        elseif p.sex == Male
            if p.age >= 66
                num_male_pens += 1
            else 
                num_male_npens += 1
            end
        else
            if p.age >= 65
                num_female_pens += 1
            else 
                num_female_npens += 1
            end
        end
    end
    c = -1
    num_adults = num_male_npens + num_male_pens + num_female_npens + num_female_pens
    num_pens = num_male_pens + num_female_pens
    if num_adults == 1
        if num_children == 0
            c = if num_male_pens == 1
                1
            elseif num_female_pens == 1
                2
            elseif num_male_npens == 1
                3
            elseif num_female_npens == 1
                4
            end
        else
            c = if num_children == 1
                9
            elseif num_children == 2
                10
            elseif num_children >= 3
                11
            end
        end
    elseif num_adults == 2
        if num_children == 0
            c = if num_pens == 0
                7
            elseif num_pens == 1
                6
            elseif num_pens == 2
                5
            end
        else
            c = if num_children == 1
                12
            elseif num_children == 2
                13
            elseif num_children >= 3 
                14
            end
        end
    elseif num_adults >= 3
        c = if num_children == 0
            8
        elseif num_children == 1
            15
        elseif num_children == 2
            16
        elseif num_children >= 3
            17
        end
    end
    @assert c in 1:17
    return frs_composition_map( c )
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
"""
Map accomodation. Unused in the end.
"""
function lcf_accmap( a116 :: Any)  :: Vector{Int}
    @argcheck a116 in 1:6
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
Pos. = 58	Variable = accomr7	Variable label = Type of accommodation
This variable is    numeric, the SPSS measurement level is NOMINAL
	Value label information for accomr7
	Value = 1.0	Label = House / bungalow
	Value = 2.0	Label = Flat / maisonette
	Value = 3.0	Label = Room / rooms
	Value = 4.0	Label = Other
	Value = -9.0	Label = Not asked / applicable
	Value = -8.0	Label = Don't know/ Refusal

Pos. = 59	Variable = hsetyper7	Variable label = Type of house / bungalow
This variable is    numeric, the SPSS measurement level is SCALE
	Value label information for hsetyper7
	Value = 1.0	Label = Detached
	Value = 2.0	Label = Semi-detached
	Value = 3.0	Label = Terraced (including end of terrace)
	Value = -9.0	Label = Not asked / applicable
	Value = -8.0	Label = Don't know/ Refusal

Pos. = 60	Variable = flttypr7	Variable label = Type of flat / maisonette
This variable is    numeric, the SPSS measurement level is SCALE
	Value label information for flttypr7
	Value = 1.0	Label = Purpose-built block
	Value = 2.0	Label = Converted house / some other kind of building
	Value = -9.0	Label = Not asked / applicable
	Value = -8.0	Label = Don't know/ Refusal

Pos. = 61	Variable = accothr7	Variable label = Other types of accommodation
This variable is    numeric, the SPSS measurement level is SCALE
	Value label information for accothr7
	Value = 1.0	Label = Caravan, mobile home or houseboat
	Value = 2.0	Label = Other
	Value = -9.0	Label = Not asked / applicable
	Value = -8.0	Label = Don't know/ Refusal

=#
"""
output:
lcf     | 2020 | dvhh            | A116          | 1     | Whole house,bungalow-detached | Whole_house_bungalow_detached
lcf     | 2020 | dvhh            | A116          | 2     | Whole hse,bungalow-semi-dtchd | Whole_hse_bungalow_semi_dtchd
lcf     | 2020 | dvhh            | A116          | 3     | Whole house,bungalow-terraced | Whole_house_bungalow_terraced
lcf     | 2020 | dvhh            | A116          | 4     | Purpose-built flat maisonette | Purpose_built_flat_maisonette
lcf     | 2020 | dvhh            | A116          | 5     | Part of house converted flat  | Part_of_house_converted_flat
lcf     | 2020 | dvhh            | A116          | 6     | Others                        | Others

"""
function was_accommap( was :: DataFrame ) :: Vector{Int}
    out = if was.accomr7 == 1 # house
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
    @assert out in 1:6 "out is $out"

    return lcf_accmap( out )
end

"""
   dwell_na = -1
   detatched = 1
   semi_detached = 2
   terraced = 3
   flat_or_maisonette = 4
   converted_flat = 5
   caravan = 6
   other_dwelling = 7
"""
function model_accommap( dwelling :: DwellingType ):: Vector{Int}
    id = Int( dwelling )
    id = max(6,id) # caravan=>other
    return lcf_accmap( out )
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

"""
Map housing type. Not used because the f**ing this is deleted in 19/20 public lcf.
"""
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

"""
Infuriatingly, this can't be used as rooms is deleted in 19/20 lcf
"""
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

"""
frs age group for hrp - 1st is exact, 2nd u40,40+
"""
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

function model_age_grp( age :: Int )
    return if age < 20
        1
    elseif age < 25
        2
    elseif age < 30
        3
    elseif age < 35
        4
    elseif age < 40
        5
    elseif age < 45
        6
    elseif age < 50
        7
    elseif age < 55
        8
    elseif age < 60
        9
    elseif age < 65
        10
    elseif age < 70
        11
    elseif age < 75
        12
    elseif age >= 75
        13
    end
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

"""
Triple for the age group for the lcf hrp - 1st is groups above to 75, 2nd is 16-39, 40+ 3rd no match.
See coding frame above.
"""
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


function was_frs_age_hrp( agegrp :: Int ) :: Vector{Int}
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

"""
 HRPDVAge8r7	Variable label = Grouped Age of HRP (8 categories)
This variable is    numeric, the SPSS measurement level is NOMINAL
	Value label information for HRPDVAge8r7
	Value = 1.0	Label = 0 to 15
	Value = 2.0	Label = 16 to 24
	Value = 3.0	Label = 25 to 34
	Value = 4.0	Label = 35 to 44
	Value = 5.0	Label = 45 to 54
	Value = 6.0	Label = 55 to 64
	Value = 7.0	Label = 65 to 74
	Value = 8.0	Label = 75 and over
	Value = -9.0	Label = Not Routed
	Value = -8.0	Label = Don t know
"""
function was_age_hrp( age :: Int ) :: Vector{Int}
    out = if age in 1:2
        1
    else
        age -1 
    end
    return was_frs_age_hrp( out )
end

function was_model_age_grp( age :: Int )
    out = if age < 25
        1
    elseif age < 35
        2
    elseif age < 45
        3
    elseif age < 55
        4
    elseif age < 65
        5
    elseif age < 75
        6
    elseif age >= 75
        7
    end
    return was_frs_age_hrp( out )
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

"""
Absolute difference in income, scaled by max difference (TOPCODE,since the possible range is zero to the top-coding)
"""
function compare_income( hhinc :: Real, p344p :: Real ) :: Real
    # top & bottom code hhinc to match the lcf p344
    # hhinc = max( 0, hhinc )
    # hhinc = min( TOPCODE, hhinc ) 
    1-abs( hhinc - p344p )/TOPCODE # topcode is also the range 
end

"""
Produce a comparison between on frs and one lcf row on tenure, region, wages, etc.
"""
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
    # fixme should we include this at all?
    incdiff = compare_income( lcf.income, frs.income )
    t += 10.0*incdiff
    return t,incdiff
end

function example_lcf_match( hh :: Household, lcf :: DataFrameRow ) :: Tuple
    hrp = get_head( hh )
    t = 0.0
    t += score( lcf_tenuremap( lcf.a121 ), model_tenuremap( hh.tenure ))
    t += score( lcf_regionmap( lcf.gorx ), model_regionmap( hh.region ))
    # !!! both next missing in 2020 LCF FUCKKK 
    # t += score( lcf_accmap( lcf.a116 ), frs_accmap( frs.typeacc ))
    # t += score( rooms( lcf.a111p, 998 ), rooms( frs.bedroom6, 999 ))
    t += score( lcf_age_hrp(  lcf.a065p ), frs_age_hrp(model_age_grp( hrp.age )))
    t += score( lcf_composition_map( lcf.a062 ), model_composition_map( hh ))
    any_wages = false
    any_selfemp = false
    any_pension_income = false 
    has_female_adult = false
    income = 0.0
    for (pid,pers) in hh.people
        if get(pers.income,wages,0) > 0
            any_wages = true
        end
        if get(pers.income,self_employment_income,0) > 0
            any_selfemp = true
        end
        if (get(pers.income,private_pensions,0) > 0) || pers.age >= 66
            any_pension_income = true
        end
        if (! pers.is_standard_child) && (pers.sex == Female )
            has_female_adult = true
        end
        income += sum( pers.income, start=wages, stop=alimony_and_child_support_received ) # FIXME
    end
    t += lcf.any_wages == any_wages ? 1 : 0
    t += lcf.any_pension_income == any_pension_income ? 1 : 0
    t += lcf.any_selfemp == any_selfemp ? 1 : 0
    t += lcf.hrp_unemployed == hrp.employment_status == Unemployed ? 1 : 0
    t += lcf.hrp_non_white == hrp.ethnic_group !== White ? 1 : 0
    # t += lcf.datayear == frs.datayear ? 0.5 : 0 # - a little on same year FIXME use date range
    # t += lcf.any_disabled == frs.any_disabled ? 1 : 0 -- not possible in LCF??
    t += Int(lcf.has_female_adult) == Int(has_female_adult) ? 1 : 0
    t += score( lcf.num_children, num_children(hh) )
    t += score( lcf.num_people, num_people(hh) )
    # fixme should we include this at all?
    incdiff = compare_income( lcf.income, income )
    t += 10.0*incdiff
    return t,incdiff


end

islessscore( l1::LCFLocation, l2::LCFLocation ) = l1.score < l2.score
islessincdiff( l1::LCFLocation, l2::LCFLocation ) = l1.incdiff < l2.incdiff

"""
Match one row in the FRS (recip) with all possible lcf matches (donor). Intended to be general
but isn't really any more. FIXME: pass in a saving function so we're not tied to case/datayear.
"""
function match_recip_row( recip, donor :: DataFrame, matcher :: Function ) :: Vector{LCFLocation}
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



"""
Create a dataframe for storing all the matches. 
This has the FRS record and then 20 lcf records, with case,year,income and matching score for each.
"""
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

"""
Map the entire datasets.
"""
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
        if p > 10000000
            break
        end
    end
    return df
end

function map_example( example :: Household, donor :: DataFrame, matcher::Function )::LCFLocation
    matches = map_recip_row( example, donor, matcher )
    return matches[1]
end

"""
print out our lcf and frs records
"""
function comparefrslcf( frshh::DataFrame, lcfhh:: DataFrame, frs_sernums, frs_datayear::Int, lcf_case::Int, lcf_datayear::Int )
    lcf1 = lcfhh[(lcfhh.case .== lcf_case).&(lcfhh.datayear .== lcf_datayear),
        [:any_wages,:any_pension_income,:any_selfemp,:hrp_unemployed,
        :hrp_non_white,:has_female_adult,:num_children,:num_people,
        :a121,:gorx,:a065p,:a062,:income]]
    println(lcf1)
    println( "lcf tenure",lcf_tenuremap( lcf1.a121[1] ))
    println( "lcf region", lcf_regionmap( lcf1.gorx[1] ))
    println( "lcf age_hrp", lcf_age_hrp( lcf1.a065p[1] ))
    println( "lcf composition", lcf_composition_map( lcf1.a062[1] ))
    for i in frs_sernums
        println( "sernum $i")
        frs1 = frshh[(frshh.sernum .== i).&(frshh.datayear.==frs_datayear),
            [:any_wages,:any_pension_income,:any_selfemp,:hrp_unemployed,:hrp_non_white,:has_female_adult,
            :num_children,:num_people,:tentyp2,:gvtregn,:hhagegr4,:hhcomps,:income]]
        println(frs1)
        println( "frs tenure", frs_tenuremap( frs1.tentyp2[1]))
        println( "frs region", frs_regionmap( frs1.gvtregn[1] ))
        println( "frs age hrp", lcf_age_hrp( frs1.hhagegr4[1] ))
        println( "frs composition", frs_composition_map( frs1.hhcomps[1] ))
        println( "income $(frs1.income)")
    end
end
#= to run this, so

lcfhh,lcfpers,lcf_hh_pp = load3lcfs()
frshh,frspers,frs_hh_pp = loadfrs()
uprate_incomes!( frshh, lcfhh ) # all in constant prices
alldf = map_all(frshh, lcfhh, frs_lcf_match_row )
CSV.write( "frs_lcf_matches_2020_vx.csv", alldf )
CSV.write( "data/lcf_edited.csv", lcfhh )

# test stuff 
lcfhrows = size(lcfhh)[1]
lcfhh.is_selected = fill( false, lcfhrows )
for i in eachrow(alldf)
    lcfhh[(lcfhh.datayear.==i.lcf_datayear_1).&(lcfhh.case.==i.lcf_case_1),:is_selected] .= true
end

sellcfhh = lcfhh[lcfhh.is_selected,:]

=#

"""
Load 2018/9 - 2020/1 LCFs and add some matching fields.
"""
function load3lcfs()::Tuple
    lcfhrows,lcfhcols,lcfhh18 = load( "/mnt/data/lcf/1819/tab/2018_dvhh_ukanon.tab", 2018 )
    lcfhrows,lcfhcols,lcfhh19 = load( "/mnt/data/lcf/1920/tab/lcfs_2019_dvhh_ukanon.tab", 2019 )
    lcfhrows,lcfhcols,lcfhh20 = load( "/mnt/data/lcf/2021/tab/lcfs_2020_dvhh_ukanon.tab", 2020 )
    lcfhh = vcat( lcfhh18, lcfhh19, lcfhh20, cols=:union )
    lcfhrows = size(lcfhh)[1]

    lcfprows,lcpfcols,lcfpers18 = load( "/mnt/data/lcf/1819/tab/2018_dvper_ukanon201819.tab", 2018 )
    lcfprows,lcpfcols,lcfpers19 = load( "/mnt/data/lcf/1920/tab/lcfs_2019_dvper_ukanon201920.tab", 2019 )
    lcfprows,lcpfcols,lcfpers20 = load( "/mnt/data/lcf/2021/tab/lcfs_2020_dvper_ukanon202021.tab",2020)
    lcfpers = vcat( lcfpers18, lcfpers19, lcfpers20, cols=:union )
    lcf_hh_pp = innerjoin( lcfhh, lcfpers, on=[:case,:datayear], makeunique=true )
    lcfhh.any_wages .= lcfhh.p356p .> 0
    lcfhh.any_pension_income .= lcfhh.p364p .> 0
    lcfhh.any_selfemp .= lcfhh.p320p .!= 0
    lcfhh.hrp_unemployed .= lcfhh.p304 .== 1
    lcfhh.num_children = lcfhh.a040 + lcfhh.a041 + lcfhh.a042
    # LCF case ids of non white HRPs - convoluted; see: 
    # https://stackoverflow.com/questions/51046247/broadcast-version-of-in-function-or-in-operator
    lcf_nonwhitepids = lcf_hh_pp[(lcf_hh_pp.a012p .∈ (["10","2","3","4"],)).&(lcf_hh_pp.a003 .== 1),:case]
    lcfhh.hrp_non_white .= 0
    lcfhh[lcfhh.case .∈ (lcf_nonwhitepids,),:hrp_non_white] .= 1    
    lcfhh.num_people = lcfhh.a049
    lcfhh.income = lcfhh.p344p    
    # not possible in lcf???
    lcfhh.any_disabled .= 0
    lcf_femalepids = lcf_hh_pp[(lcf_hh_pp.a004 .== 2),:case]
    lcfhh.has_female_adult .= 0
    lcfhh[lcfhh.case .∈ (lcf_femalepids,),:has_female_adult] .= 1
    lcfhh.is_selected = fill( false, lcfhrows )
    lcfhh,lcfpers,lcf_hh_pp
end

end # FRS_TO_LCF 

#=
Value = 1.0	Label = 0 to 15
Value = 2.0	Label = 16 to 24
Value = 3.0	Label = 25 to 34
Value = 4.0	Label = 35 to 44
Value = 5.0	Label = 45 to 54
Value = 6.0	Label = 55 to 64
Value = 7.0	Label = 65 to 74
Value = 8.0	Label = 75 and over
Value = -9.0	Label = Not Routed
Value = -8.0	Label = Don t know
=#

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

function was_age_grp( age :: Int )::Vector{Int}
    out = fill( 9998, 3 )
    out[1] = age
    out[2] = age[2] < 3 ? 1 : 2
    out
end

function model_age_grp( age :: Int )
    return if age < 16
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
    else
        8
    end
end

#=
   
 Missing_Socio_Economic_Group = -1
   Employers_in_large_organisations = 1
   Higher_managerial_occupations = 2
   Higher_professional_occupations_New_self_employed = 3
   Lower_prof_and_higher_technical_Traditional_employee = 4
   Lower_managerial_occupations = 5
   Higher_supervisory_occupations = 6
   Intermediate_clerical_and_administrative = 7
   Employers_in_small_organisations_non_professional = 8
   Own_account_workers_non_professional = 9
   Lower_supervisory_occupations = 10
   Lower_technical_craft = 11
   Semi_routine_sales = 12
   Routine_sales_and_service = 13
   Never_worked = 14
   Full_time_student = 15
   Not_classified_or_inadequately_stated = 16
   Not_classifiable_for_other_reasons = 17
end

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

1.1 => 1 
1.2 => 2
2 => 3
3 => 4
4 => 5
5 => 6
6 => 7
7 => 8
8 => 9
9 => 10

nssec8r7
    Value = -9.0	Label = Not asked / applicable
	Value = -8.0	Label = Don't know/ Refusal
	1 Value = 1.1	Label = Large employers and higher managerial occupations
	2 Value = 1.2	Label = Higher professional occupations
	3 Value = 2.0	Label = Lower managerial and professional occupations
	4 Value = 3.0	Label = Intermediate occupations
	5 Value = 4.0	Label = Small employers and own account workers
	6 Value = 5.0	Label = Lower supervisory and technical occupations
	7 Value = 6.0	Label = Semi-routine occupations
	8 Value = 7.0	Label = Routine occupations
	9 Value = 8.0	Label = Never worked and long-term unemployed
	10 Value = 97.0	Label = Not classified

=#

function map_was_socio( socio :: Real ) :: Vector{Int}
    d = Dict([
        1.1 => 1, 
        1.2 => 2,
        2 => 3,
        3 => 4,
        4 => 5,
        5 => 6,
        6 => 7,
        7 => 8,
        8 => 9,
        9 => 10,
        97=>10,
        -8=>10,
        -9=>10])
    return fill(d[socio],3)
end

function frs_map_socio( socio :: Int )  :: Vector{Int}
    out = if socio == 1
        1
    elseif socio in [2,3]
        2
    elseif socio in [4]
        3
    elseif socio in [5,6,7]
        4
    elseif socio in [8,9]
        5
    elseif socio in [10]
        6
    elseif socio in [11,12]
        7
    elseif socio in [13]
        8
    elseif socio in [14,15]
        9
    elseif socio in [16,17,-1]
        10
    else
        @assert false "socio out of range $socio"
    end
    return fill( out, 3)
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

function map_frs_socio( socio :: Socio_Economic_Group )

"""
Just for fuckery WAS and LCF these numbers subtly different - was ommits 4
"""
function was_regionmap( wasreg :: int ) :: Vector{Int}
    wasreg = wasreg <= 2 ? wasreg : wasreg - 1
    return lcf_regionmap( wasreg )
end
#=
Value = 96.0	Label = Never worked and long-term unemployed
	Value = 1.0	Label = Managerial and professional occupations
	Value = 2.0	Label = Intermediate occupations
	Value = 3.0	Label = Routine and manual occupations
	Value = 97.0	Label = Not classified
	Value = -8.0	Label = Don't know/ Refusal
	Value = -9.0	Label = Not asked / applicable
=#

#=
wasp = CSV.File( "/mnt/data/was/UKDA-7215-tab/tab/was_round_7_person_eul_june_2022.tab") |> DataFrame
wash = CSV.File( "/mnt/data/was/UKDA-7215-tab/tab/was_round_7_hhold_eul_march_2022.tab") |> DataFrame
rename!(wasp,lowercase.(names(wasp)))
rename!(wash,lowercase.(names(wash)))
washj = innerjoin( wasp, wash; on=:caser7,makeunique=true)
washj[washj.p_flag4r7 .∈ (1,3),:] # hrp only
washj[(washj.p_flag4r7 .== "1") .| (washj.p_flag4r7 .== "3"),:]

mpers = CSV.File( "data/model_people_scotland-2015-2021.tab")|>DataFrame

=#

"""
We're JUST going to use the model dataset here
"""
function model_was_match( 
    hh :: Household, 
    was :: DataFrameRow ) :: Tuple
    t = 0.0
    incdiff = 0.0
    hrp = get_head( hh )
    t += score( was_model_age_grp( hrp.age ), was_age_grp(was.age_head))
    t += score( model_regionmap( hh.region ), was_regionmap( was.region ))
    t += score( model_accommap( hh.dwelling ), was_accommap( was ))
    t += score( model_tenuremap( hh.tenure ), was.tenuremap( was )) 
   
    was.socio_economic_grouping
    
    sex
    marital_status
    hh_composition 
    any_wages
    any_pension_income
    any_selfemp = lcf.any_selfemp,
    
    has_any_se 
    

    num_children( hh )
    num_adults( hh )
    return t, incdiff
end

end # module