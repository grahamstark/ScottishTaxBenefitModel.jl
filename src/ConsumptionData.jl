#=
    
This module holds both the data for indirect tax calculations. Quickie pro tem thing
for Northumberland, but you know how that goes..

TODO add mapping for example households.
TODO all uprating is nom gdp for now.
TODO Factor costs for excisable goods and base excisable good parameters.
TODO Better calculation of exempt goods.
TODO Recheck allocations REALLY carefully.
TODO Much more detailed uprating.
TODO costs of spirits etc.

=#
module ConsumptionData

using ArgCheck
using CSV
using DataFrames
using StatsBase
using Pkg, LazyArtifacts
using LazyArtifacts

using ScottishTaxBenefitModel
using .Definitions
using .GeneralTaxComponents
using .ModelHousehold
using .RunSettings
using .Uprating

IND_MATCHING = DataFrame()
EXPENDITURE_DATASET = DataFrame() 
FACTOR_COST_DATASET = DataFrame()  # expenditure less taxes *at the time*.

export 
    LFS_CATEGORIES,
    DEFAULT_EXEMPT,
    DEFAULT_REDUCED_RATE, 
    DEFAULT_STANDARD_RATE, 
    DEFAULT_ZERO_RATE, 
    find_consumption_for_hh!, 
    impute_co2_emissions,
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

const CO2BY_DECILE = [
    0.674,
    0.679,
    0.789,
    0.866,
    0.956,
    1.033,
    1.133,
    1.220,
    1.275,
    1.440 ] ./ WEEKS_PER_YEAR
#=
    1 .674 .020 .633 .714
    2 .679 .019 .641 .718
    3 .789 .021 .747 .831
    4 .866 .025 .811 .922
    5 .956 .025 .901 1.012
    6 1.033 .018 .997 1.069
    7 1.133 .020 1.091 1.175
    8 1.220 .031 1.147 1.293
    9 1.275 .033 1.196 1.353
    10 1.440 .026 1.384 1.496
=#

"""
From: https://www.jrf.org.uk/report/distribution-uk-household-co2-emissions
    7. Appendices
    Table A1: The distribution of total household CO 2 emissions from all
    sources – means, standard errors and confidence intervals (metric tons)
    Mean SE 95%CI lo 95%CI hi
    OECD
    equivilised net
    household
    disposable
    income
    bs but whau=t do you do?
"""
function impute_co2_emissions(equiv_decile::Int)::Real
    #   Mean SE 95%CI lo 95%CI hi
    return CO2BY_DECILE[equiv_decile]
end

const DEFAULT_EXEMPT = default_exempt()
const DEFAULT_EXEMPT_RATE = 0.08 # FIXME wild guess

function default_zero_rate()::Set{Symbol}
    s = Set([
        :bus_boat_and_train,
        :air_travel,
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

const DEFAULT_ZERO_RATE = default_zero_rate()

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

const DEFAULT_REDUCED_RATE = default_reduced_rate()

function default_standard_rate()::Set{Symbol}
    non_standard = union( 
        default_exempt(), 
        default_zero_rate(), 
        default_reduced_rate())
    s = setdiff( LFS_CATEGORIES, non_standard )
    @assert union(  s, non_standard ) == LFS_CATEGORIES
    return s
end

const DEFAULT_STANDARD_RATE = default_standard_rate()

"""
Match in the lcf data using the lookup table constructed in 'matching/lcf_frs_matching.jl'
'which' best, 2nd best etc match (<=20)
"""
#=
function find_consumption_for_hh!( hh :: Household, case :: Int, datayear :: Int)
    # println( "find_consumption_for_hh! matching to case $case datayear $datayear")
    hh.expenditure = EXPENDITURE_DATASET[(EXPENDITURE_DATASET.case .== case).&(EXPENDITURE_DATASET.datayear.==datayear),:][1,:]
    hh.factor_costs = FACTOR_COST_DATASET[(FACTOR_COST_DATASET.case .== case).&(FACTOR_COST_DATASET.datayear.==datayear),:][1,:]
    @assert ! isnothing( hh.expenditure )
    @assert ! isnothing( hh.factor_costs )
end
=#

"""
allocate
"""
function impute_stuff_from_consumption!( hh :: Household, settings :: Settings )
    head = get_head( hh )
    head.debt_repayments = hh.expenditure[:repayments]

    working = 0
    employees = 0
    for (pid,pers) in hh.people
        if is_working(pers.employment_status )
            working += 1
        end
        if is_employee( pers.employment_status )
            employees += 1
        end
    end
    #
    # Note it's possible that there 
    # are no employees on both sides of the FRS/LCF
    # matches. 
    # 80% of transport costs allocated equally
    # amongst everyone in the hh who works.
    # FIXME the is_working stuff should be lists of pids
    # in ModelHousehold
    #
    if working > 0
        trans = sum(hh.expenditure[[
            :bus_boat_and_train, 
            :petrol,
            :diesel,
            :other_motor_oils, 
            :other_transport  # COMPLETELY MADE UP
        ]]) * 0.5/working     
        for (pid,pers) in hh.people
            if is_working( pers.employment_status )
                pers.travel_to_work = trans
            end
        end
    end
    if employees > 0
        # MAD, Wild guess 
        workexp = (hh.expenditure.trade_union_subs +
        hh.expenditure.other_clothing_and_footwear*0.2)/employees
        for (pid,pers) in hh.people
            if is_employee( pers.employment_status )
                pers.work_expenses = workexp
            end
        end

    end
end


"""
Match in the lcf data using the lookup table constructed in 'matching/lcf_frs_matching.jl'
'which' best, 2nd best etc match (<=20)
"""
function find_consumption_for_hh!( hh :: Household, settings :: Settings, which = -1 )
    @argcheck settings.indirect_method == matching
    @argcheck which <= 20
    match = IND_MATCHING[(IND_MATCHING.frs_datayear .== hh.data_year).&(IND_MATCHING.frs_sernum .== hh.hid),:][1,:]
    case_sym, datayear_sym = if which > 0      
        Symbol( "hhid_$(which)" ),
        Symbol( "datayear_$(which)")
    else
        :default_hhld,
        :default_datayear    
    end
    case = match[case_sym]
    datayear = match[datayear_sym]
    hh.expenditure = EXPENDITURE_DATASET[(EXPENDITURE_DATASET.case .== case).&(EXPENDITURE_DATASET.datayear.==datayear),:][1,:]
    hh.factor_costs = FACTOR_COST_DATASET[(FACTOR_COST_DATASET.case .== case).&(FACTOR_COST_DATASET.datayear.==datayear),:][1,:]
    @assert ! isnothing( hh.expenditure )
    @assert ! isnothing( hh.factor_costs )
end

# FIXME FIXME CHAOTIC EVIL this is the diff between actual 157bn and crude modelled VAT receipts of 102mb. 2022
const EVIL_VAT_HACK = 157_546/102_758

"""
Quick n dirty uprating using nominal gdp for everything for now. Factor costs are just ex VAT not excise duties.
"""
function uprate_expenditure( settings :: Settings )
    ## TODO much more specific uprating factors - just nom_gdp for now
    ## TODO just add q into created dataset 
    # more lazy loading - prices
    Uprating.load_prices( settings )
    nms = names( EXPENDITURE_DATASET )
    nr = size(EXPENDITURE_DATASET)[1]
    for i in 1:nr 
        r = EXPENDITURE_DATASET[i,:]
        f = FACTOR_COST_DATASET[i,:]
        if r.month > 20 # a055 is interview Month code: > 20 is e.g January REIS and I don't know what REIS means 
            r.month -= 20
        end
        q = ((r.month-1) ÷ 3) + 1 # 1,2,3=q1 and so on
        # lcf year seems to be actual interview year 
        y = r.year
        r.income =  Uprating.uprate( r.income, y, q, Uprating.upr_earnings )
        f.income =  Uprating.uprate( f.income, y, q, Uprating.upr_earnings )
        for n in LFS_CATEGORIES
            sym = Symbol(n)
            r[sym] = Uprating.uprate( r[sym], y, q, Uprating.upr_nominal_gdp ) * EVIL_VAT_HACK
            ### FIXME WE NEED EXCISE DUTIES HERE AND PARAMETERISE THESE NUMBERS. See GeneralTaxComponents.jl for
            ## proper factor cost calcs
            if sym in DEFAULT_EXEMPT
                f[sym] /= 1.1 # 
            elseif sym in DEFAULT_REDUCED_RATE
                f[sym] /= 1.05
            elseif sym in DEFAULT_STANDARD_RATE
                f[sym] /= 1.20
            end           
            f[sym] = Uprating.uprate( f[sym], y, q, Uprating.upr_nominal_gdp ) * EVIL_VAT_HACK
        end
    end
end

"""
FIXME DO FACTOR COSTS!!!!
fixme selectable artifacts
"""
function init( settings :: Settings; reset = false )
    # `do_indirect_tax_calculations` doesn't really need to hold. You
    # might just want to display something.
    # @argcheck settings.do_indirect_tax_calculations 
    @argcheck settings.indirect_method == matching
    global IND_MATCHING
    global EXPENDITURE_DATASET
    global FACTOR_COST_DATASET
    if (reset || (size(EXPENDITURE_DATASET)[1] == 0 )) # needed but uninitialised
        c_artifact = RunSettings.get_artifact(; 
            name="expenditure", 
            source=settings.data_source == SyntheticSource ? "synthetic" : "lcf", 
            scottish=settings.target_nation == N_Scotland )
        IND_MATCHING = CSV.File( joinpath( c_artifact, "matches.tab" )) |> DataFrame
        EXPENDITURE_DATASET = CSV.File( joinpath( c_artifact, "dataset.tab")) |> DataFrame
        FACTOR_COST_DATASET = CSV.File( joinpath( c_artifact, "dataset.tab" )) |> DataFrame
        println( EXPENDITURE_DATASET[1:2,:])
        uprate_expenditure( settings )
    end
end

function add_default_lcf_mapping_to_model( mhh :: DataFrame )
    
end

end # module