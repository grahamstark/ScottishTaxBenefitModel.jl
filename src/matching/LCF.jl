module LCF 

using ScottishTaxBenefitModel
using .RunSettings

using CSV,
    DataFrames,
    Measures,
    StatsBase,
    ArgCheck

using ..Common 
import ..Model

"""

a094	Not recorded	0
	Large employers and higher managerial occupations      	1
	Higher Professional occupations 	2
	Lower managerial and professional occupations     	3
	Intermediate occupations       	4
	Small employers and own account workers       	5
	Lower supervisory and technical occupations      	6
	Semi-routine occupations      	7
	Routine occupations       	8
	Never worked and long term unemployed 	9
	Students	10
	Occupation not stated	11
	Not classified for other reasons                                      	12


"""
function map_socio( a094 :: Int )::Vector{Int}

end

"""
a206	Not recorded             	0
NOTE 7		
	ECONOMICALLY ACTIVE	
	Self-employed	1
	Full-time employee at work	2
	Part-time employee at work	3
	Unemployed	4
	Work related Government Training Programmes	5
		
	ECONOMICALLY INACTIVE	
	Retired/unoccupied and of minimum NI Pension age	6
    Retired/unoccupied but under minimum NI Pension age	7

if a206 == 1 # self-employed	1

elseif a206 == 2 # Full-time employee at work	2

elseif a206 == 3 # Part-time employee at work	3

elseif a206 == 4 # Unemployed	4 

elseif a206 == 5 # Work related Government Training Programmes	5

elseif a206 == 6 # Retired/unoccupied and of minimum NI Pension age	6

elseif a206 == 7 #     Retired/unoccupied but under minimum NI Pension age	6


else 

end

"""
function map_empstat( a206 :: Int )::Vector{Int}

end
"""
a006p	Marital status; spouse in household	1
	Marital status; spouse not household	2
	Single	3
	Widowed	4
	Divorced	5
	Separated	6
	Civil Partner or Former Civil Partner	7
"""
function map_marital( a006p )::Vector{Int}

end



#=
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
        if r.month > 20
            r.month -= 20
        end
        q = ((r.month-1) ÷ 3) + 1 # 1,2,3=q1 and so on
        # lcf year seems to be actual interview year 
        y = r.year
        r.income = Uprating.uprate( r.income, y, q, Uprating.upr_nominal_gdp )
    end
end
=#

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
function map_tenure( a121 :: Union{Int,Missing}, default=9997 ) :: Vector{Int}
    out = fill( default, 3 )
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
function map_region( gorx :: Union{Int,Missing} ) :: Vector{Int}
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
Load 2018/9 - 2020/1 LCFs and add some matching fields.
"""
function load4lcfs()::Tuple
    lcfhrows,lcfhcols,lcfhh18 = Common.load( "/mnt/data/lcf/1819/tab/2018_dvhh_ukanon.tab", 2018 )
    lcfhrows,lcfhcols,lcfhh19 = Common.load( "/mnt/data/lcf/1920/tab/lcfs_2019_dvhh_ukanon.tab", 2019 )
    lcfhrows,lcfhcols,lcfhh20 = Common.load( "/mnt/data/lcf/2021/tab/lcfs_2020_dvhh_ukanon.tab", 2020 )
    lcfhrows,lcfhcols,lcfhh21 = Common.load( "/mnt/data/lcf/2022/tab/dvhh_ukanon_2022.tab", 2021 )
    lcfhh = vcat( lcfhh18, lcfhh19, lcfhh20, lcfhh21,cols=:union )
    lcfhrows = size(lcfhh)[1]

    lcfprows,lcpfcols,lcf_pers_stacked18 = Common.load( "/mnt/data/lcf/1819/tab/2018_dvper_ukanon201819.tab", 2018 )
    lcfprows,lcpfcols,lcf_pers_stacked19 = Common.load( "/mnt/data/lcf/1920/tab/lcfs_2019_dvper_ukanon201920.tab", 2019 )
    lcfprows,lcpfcols,lcf_pers_stacked20 = Common.load( "/mnt/data/lcf/2021/tab/lcfs_2020_dvper_ukanon202021.tab",2020)
    lcfprows,lcpfcols,lcf_pers_stacked21 = Common.load( "/mnt/data/lcf/2022/tab/dvper_ukanon_2022-23.tab",2021 )
    lcf_pers_stacked = vcat( lcf_pers_stacked18, lcf_pers_stacked19, lcf_pers_stacked20, lcf_pers_stacked21,cols=:union )
    hh_pp = innerjoin( lcfhh, lcf_pers_stacked, on=[:case,:datayear], makeunique=true )
    lcfhh.any_wages .= lcfhh.p356p .> 0
    lcfhh.any_pension_income .= lcfhh.p364p .> 0
    lcfhh.any_selfemp .= lcfhh.p320p .!= 0
    lcfhh.hrp_unemployed .= lcfhh.p304 .== 1
    lcfhh.num_children = lcfhh.a040 + lcfhh.a041 + lcfhh.a042
    # LCF case ids of non white HRPs - convoluted; see: 
    # https://stackoverflow.com/questions/51046247/broadcast-version-of-in-function-or-in-operator
    # 2025- the STUPID FUCKS have deleted a012 from the 2022 public release.
    # nonwhitepids = hh_pp[(hh_pp.a012p .∈ (["10","2","3","4"],)).&(hh_pp.a003 .== 1),:case]
    # lcfhh.hrp_non_white .= 0
    # lcfhh[lcfhh.case .∈ (nonwhitepids,),:hrp_non_white] .= 1    
    lcfhh.num_people = lcfhh.a049
    lcfhh.income = lcfhh.p344p  
    lcfhh.a003 .= 1 # person MUST be hRP
    # not possible in lcf???
    lcfhh.any_disabled .= 0
    # femalepids = hh_pp[(hh_pp.a004 .== 2),:case]
    # pers - hrp-only
    hrp_only = hh_pp[hh_pp.a003.==1,:]
    lcfhh.a006p = hrp_only.a006p
    lcfhh.has_female_adult .= 0
    lcfhh.num_employees .= 0
    lcfhh.num_pensioners .= 0
    lcfhh.num_fulltime .= 0
    lcfhh.num_parttime .= 0
    lcfhh.num_selfemp .= 0
    lcfhh.num_unemployed .= 0
    lcfhh.num_retired .= 0
    lcfhh.num_unoccupied .= 0
    for r in eachrow( hh_pp )
        pc = (lcfhh.case.== r.case) .& (lcfhh.datayear .== r.datayear)
        if (r.a004 == 2) && (r.a005p >= 16) # female
            lcfhh[pc,:has_female_adult] .= 1
        end
        if r.a206 == 1 # self-employed	1
            lcfhh[pc,:num_selfemp] .+= 1
        elseif r.a206 == 2 # Full-time employee at work	2
            lcfhh[pc,:num_employees] .+= 1
            lcfhh[pc,:num_fulltime] .+= 1
        elseif r.a206 == 3 # Part-time employee at work	3
            lcfhh[pc,:num_employees] .+= 1
            lcfhh[pc,:num_parttime] .+= 1                
        elseif r.a206 == 4 # Unemployed	4 
            lcfhh[pc,:num_unemployed] .+= 1
        elseif r.a206 == 5 # Work related Government Training Programmes	5
            # lcfhh.num_unemployed .+= 1 # kinda sorta
        elseif r.a206 == 6 # Retired/unoccupied and of minimum NI Pension age	6
            lcfhh[pc,:num_retired] .+= 1
        elseif r.a206 == 7 # Retired/unoccupied and of minimum NI Pension age	6
            lcfhh[pc,:num_unoccupied] .+= 1       
        elseif r.a206 == 0
            if (r.a005p <= 18) # a child
                ;
            else 
                @assert false "unmatched $(r.a206) age $(r.a005p)"        
            end
        end
        
    end
    lcfhh.a206 = hrp_only.a206
    # lcfhh.a206 = hrp_only.a206
    # lcfhh[lcfhh.case .∈ (femalepids,),:has_female_adult] .= 1
    lcfhh.is_selected = fill( false, lcfhrows )
    lcfhh,lcf_pers_stacked,hh_pp,hrp_only
end

function uprate_incomes!( lcfsubset :: DataFrame )
    for r in eachrow( lcfsubset )
        #
        # This is e.g January REIS and I don't know what REIS means 
        #
        if r.month > 20
            r.month -= 20
        end
        q = ((r.month-1) ÷ 3) + 1 # 1,2,3=q1 and so on
        # lcf year seems to be actual interview year 
        y = r.year
        r.income = Uprating.uprate( r.income, y, q, Uprating.upr_nominal_gdp )
    end
end


"""
Small, easier to use, subset of lfs expenditure codes kinda sorta matching the tax system we're modelling.
"""
function create_subset( ) :: DataFrame
    lcf, lcf_pers, hh_pp, hrp_only =  load4lcfs()    
    out = DataFrame( 
        case = lcf.case, 
        datayear = lcf.datayear, 
        month = lcf.a055, 
        year= lcf.year,
        a121 = lcf.a121,
        a003 = lcf.a003, # is_hrp
        a006 = lcf.a006p, # marital status!!! anonymised version 
        a091 = lcf.a091, # socio-economic
        a206 = lcf.a206, # empstat
        a094 = lcf.a094, # NS-SEC 12 Class of HRP
        gorx = lcf.gorx, # govt region
        a065p  = lcf.a065p,
        a062 = lcf.a062,

        any_wages = lcf.any_wages,
        any_pension_income = lcf.any_pension_income,
        any_selfemp = lcf.any_selfemp,
        hrp_unemployed = lcf.hrp_unemployed,
        num_children = lcf.num_children,
        # hrp_non_white = lcf.hrp_non_white,
        num_people = lcf.num_people,
        income = lcf.income,
        any_disabled = lcf.any_disabled,
        has_female_adult = lcf.has_female_adult,
        num_employees = lcf.num_employees,
        num_pensioners = lcf.num_pensioners,
        num_fulltime = lcf.num_fulltime,
        num_parttime = lcf.num_parttime,
        num_selfemp = lcf.num_selfemp,
        num_unemployed = lcf.num_unemployed,
        num_retired = lcf.num_retired,
        num_unoccupied = lcf.num_unoccupied )

    
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
    # !! 5 mismatched hhlds, can't track down why
    out.repayments = 
        lcf.b237 + lcf.b238 + lcf.ck5316t + lcf.cc6211c 
    uprate_incomes!( out )
    return out    
end

function composition_map( a062 :: Int ) :: Vector{Int}
    mappings = (lcf1=[1],lcf2=[2],lcf3=[3,4],lcf4=[5,6],lcf5=[7,8],lcf6=[18,23,26,28],lcf7=[9,10],lcf8=[11,12],lcf9=[13,14,15,16,17],lcf10=[19,24,20,21,22,25,27,29,30])
    return composition_map( a062,  mappings, default=9998 )
end

"""
Map accomodation. Unused in the end.
"""
function map_accom( a116 :: Any, default=9998)  :: Vector{Int}
    @argcheck a116 in 1:6
    return Common.map_accom( a116 )
end




"""
Triple for the age group for the lcf hrp - 1st is groups above to 75, 2nd is 16-39, 40+ 3rd no match.
See coding frame above.
"""
function map_age_hrp( a065p :: Int ) :: Vector{Int}
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

end # module LCF