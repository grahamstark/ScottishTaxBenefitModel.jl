#=
    
This module holds both the data for indirect tax calculations. Quickie pro tem thing
for Northumberland, but you know how that goes..

TODO move the declarations to a Seperate module/ModelHousehold module.
TODO add mapping for example households.
TODO all uprating is nom gdp for now.

=#


module ConsumptionData

using ArgCheck
using CSV
using DataFrames
using StatsBase

using ScottishTaxBenefitModel
using .Definitions
using .GeneralTaxComponents
using .ModelHousehold
using .RunSettings
using .Uprating

IND_MATCHING = DataFrame()
EXPENDITURE_DATASET = DataFrame()

export 
    LFS_CATEGORIES,
    default_exempt, 
    default_reduced_rate, 
    default_standard_rate, 
    default_zero_rated, 
    find_consumption_for_hh!, 
    init,
    uprate_expenditure

# FIXME this seems very brittle 
const LFS_CATEGORIES = Set([
    :sweets_and_icecream,
    :other_food_and_beverages,
    :hot_and_eat_out_food,
    :spirits,
    :wine,
    :fortified_wine,
    :cider,
    :alcopops,
    :champagne,
    :beer,
    :cigarettes,
    :cigars,
    :other_tobacco,
    :childrens_clothing_and_footwear,
    :helmets_etc,
    :other_clothing_and_footwear,
    :domestic_fuel_electric,
    :domestic_fuel_gas,
    :domestic_fuel_coal,
    :domestic_fuel_other,
    :other_housing,
    :furnishings_etc,
    :medical_services,
    :prescriptions,
    :other_medicinces,
    :spectacles_etc,
    :other_health,
    :bus_boat_and_train,
    :air_travel,
    :petrol,
    :diesel,
    :other_motor_oils,
    :other_transport,
    :communication,
    :books,
    :newspapers,
    :magazines,
    :gambling,
    :museums_etc,
    :postage,
    :other_recreation,
    :education,
    :hotels_and_restaurants,
    :insurance,
    :other_financial,
    :prams_and_baby_chairs,
    :care_services,
    :trade_union_subs,
    :nappies,
    :funerals,
    :womens_sanitary,
    :other_misc_goods ])

function all_other( sets... ) :: Set{Symbol}
    for s in sets

    end
end


function default_exempt()
    s = Set([:insurance,
        :gambling,
        :funerals,
        :other_financial,
        :education,
        :medical_services,
        :museums_etc,
        :trade_union_subs,
        :care_services,
        :medical_services,
        :postage])
    @assert issubset(s, LFS_CATEGORIES )
    return s
    # sports from charities
end

function default_zero_rated()::Set{Symbol}
    s = Set([
        :bus_boat_and_train,
        :other_food_and_beverages,
        :books,
        :newspapers,
        :magazines,
        :helmets_etc,
        :prescriptions,
        :childrens_clothing_and_footwear])
    @assert issubset(s, LFS_CATEGORIES )
    return s
    # talking books & audio for the deaf, contraceptives on prescription
end

function default_reduced_rate()::Set{Symbol}
    s = Set([:domestic_fuel_electric,
        :domestic_fuel_gas,
        :domestic_fuel_coal,
        :domestic_fuel_other,
        :womens_sanitary])
    @assert issubset(s, LFS_CATEGORIES )
    return s
    # contraceptives,insulation and energy saving, anti-smoking, car child seats, condoms
end

function default_standard_rate()::Set{Symbol}
    nonstandard = union( 
        default_exempt(), 
        default_zero_rated(), 
        default_reduced_rate())
    s = setdiff( LFS_CATEGORIES, non_standard )
    @assert union(  s, nonstandard ) == LFS_CATEGORIES
    return s
end


"""
Match in the lcf data using the lookup table constructed in 'matching/lcf_frs_matching.jl'
'which' best, 2nd best etc match (<=20)
"""
function find_consumption_for_hh!( hh :: Household, settings :: Settings, which :: Int )::DataFrameRow  
    @argcheck settings.indirect_method == matching
    @argcheck which <= 20
    match = IND_MATCHING[(IND_MATCHING.frs_datayear .== hh.data_year).&(IND_MATCHING.frs_sernum .== hh.hid),:][1,:]
    lcf_case_sym = Symbol( "lcf_case_$(which)" )
    lcf_datayear_sym = Symbol( "lcf_datayear_$(which)")
    case = match[lcf_case_sym]
    datayear = match[lcf_datayear_sym]
    return hh.consumption = EXPENDITURE_DATASET[(EXPENDITURE_DATASET.case .== case).&(EXPENDITURE_DATASET.datayear.==datayear),:][1,:]
end

"""
Quick n dirty uprating using nominal gdp for everything for now.
"""
function uprate_expenditure( settings :: Settings )
    ## TODO much more specific uprating factors - just nom_gdp for now
    ## TODO just add q into created dataset 
    nms = names( EXPENDITURE_DATASET )
    for r in eachrow( EXPENDITURE_DATASET)
        if r.month > 20 # a055 is interview Month code: > 20 is e.g January REIS and I don't know what REIS means 
            r.month -= 20
        end
        q = ((r.month-1) ÷ 3) + 1 # 1,2,3=q1 and so on
        # lcf year seems to be actual interview year 
        y = r.year
        r.income =  Uprating.uprate( r.income, y, q, Uprating.upr_earnings )
        for n in LFS_CATEGORIES
            sym = Symbol(n)
            r[sym] = Uprating.uprate( r[sym], y, q, Uprating.upr_nominal_gdp )
        end
    end
end

function init( settings :: Settings; reset = false )
    if(settings.indirect_method == matching) && (reset || (size(EXPENDITURE_DATASET)[1] == 0 )) # needed but uninitialised
        global IND_MATCHING
        global EXPENDITURE_DATASET
        IND_MATCHING = CSV.File( "$(settings.data_dir)/$(settings.indirect_matching_dataframe).tab") |> DataFrame
        EXPENDITURE_DATASET = CSV.File("$(settings.data_dir)/$(settings.expenditure_dataset).tab" ) |> DataFrame
        nms = names( EXPENDITURE_DATASET )
        # coerce coicop int cols to floats
        for n in nms
            if( match( r"^c[0-9]+[a-z]*$",  n ) !== nothing) || # coicop disagregates so c1234x, for example - CIOCP code
                ( match( r"^p6[0-9]+[a-z]*$",  n ) !== nothing) || 
                ( match( r"^c[0-9a-z]+$",  n ) !== nothing)
                sym = Symbol(n)
                EXPENDITURE_DATASET[!,sym] = Float64.(EXPENDITURE_DATASET[:,sym])
            end
        end        
        println( EXPENDITURE_DATASET[1:2,:])
        uprate_expenditure(  settings )
    end
end

end # module