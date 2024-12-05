module LocalTaxRunner
using CSV, DataFrames
using Format
using StatsBase
using ArgCheck
using PrettyTables
using CairoMakie
using JLD2

using ScottishTaxBenefitModel
using .LocalLevelCalculations
using .Definitions
using .ModelHousehold
using .FRSHouseholdGetter
using .Intermediate
using .Weighting
using .RunSettings
using .STBParameters
using .STBIncomes
using .Results: 
    BenefitUnitResult,
    HouseholdResult,
    IndividualResult,
    get_net_income,
    get_indiv_result,
    total
using .TimeSeriesUtils: FY_2022
using .TheEqualiser
using .LocalLevelCalculations
using .GeneralTaxComponents: WEEKS_PER_YEAR
using .Uprating: load_prices
using .SingleHouseholdCalculations: do_one_calc
using .STBOutput: 
    initialise_frames, 
    add_to_frames!, 
    summarise_frames!, 
    make_poverty_line,
    dump_frames
using .Monitor: Progress
using .Runner: do_one_run
using .Utils: pretty

mutable struct WS 
    weights::DataFrame
end 

const WEIGHTS = WS(DataFrame())

const SYSTEM_NAMES = [
    "Current System", 
    "CT Incidence",
    "Local Income Tax",
    "Progressive Bands", 
    "Proportional Property Tax",
    "Council Tax With Revalued House Prices and compensating band D cuts", 
    "Council Tax With Revalued House Prices & Fairer Bands" ]

function revenues_table()
    return DataFrame( 
        name=CTLEVELS.name, 
        code=Symbol.(CTLEVELS.code), 
        actual_revenues=CTLEVELS.to_be_collected, 
        modelled_ct=zeros(22), 
        modelled_ctb=zeros(22), 
        net_modelled=zeros(22),
        local_income_tax = zeros(22),
        fairer_bands_band_d = zeros(22),
        proportional_property_tax = zeros(22),
        revalued_housing_band_d = zeros(22),
        revalued_housing_band_d_w_fairer_bands = zeros(22))
end


function get_base_cost( ;
    settings::Settings, 
    base_sys :: TaxBenefitSystem,
    observer :: Observable ) :: Real
    frames = do_one_run( settings, [base_sys], obs )        
    settings.poverty_line = make_poverty_line( frames.hh[1], settings )
    pc_frames = summarise_frames!(frames, settings)
    base_cost = pc_frames.income_summary[1][1,:net_cost]
    return base_cost
end


const PROGRESSIVE_RELATIVITIES = Dict{CT_Band,Float64}(
    # halved below, doubled above
    Band_A=>120/360,
    Band_B=>140/360,
    Band_C=>160/360,
    Band_D=>360/360,
    Band_E=>880/360,
    Band_F=>1040/360,                                                                      
    Band_G=>1200/360,
    Band_H=>1440/360,
    Household_not_valued_separately => 0.0 ) 


"""
Note ATM this is Scotland only!
"""
function do_local_level_run(; 
    target :: EqTargets,
    systems :: Vector{TaxBenefitSystem}, 
    settings::Settings, 
    ccode :: Symbol,
    observer :: Observable,
    reset = false,
    restore = false )::DataFrame
@argcheck settings.target_nation == N_Scotland
    # lazy load reweights
    observer[]=Progress( settings.uuid, "do-one-run-start", 0, 0, 0, 0 )     
    
    revtab = revenues_table()

    if size( WEIGHTS.weights ) == (0,0)
        fname = joinpath( artifact"augdata", "la-frs-weights-scotland-2024.tab")
        WEIGHTS.weights = CSV.File(fname) |> DataFrame
    end
    num_threads = min( nthreads(), settings.requested_threads )
    # always load data
    if reset || (settings.num_households == 0)
        @time settings.num_households, settings.num_people, nhh2 = 
            FRSHouseholdGetter.initialise( settings )
        if settings.benefit_generosity_estimates_available
            BenefitGenerosity.initialise( artifact"disability" )  
            observer[]= Progress( 
                settings.uuid, "disability_eligibility", 0, 0, 0, settings.num_households )
            for sysno in 1:num_systems
                adjust_disability_eligibility!( params[sysno].nmt_bens )
            end
        end
    end
    start,stop = make_start_stops( settings.num_households, num_threads )
    observer[] =Progress( settings.uuid, "starting",0, 0, 0, settings.num_households )
    observer[]= Progress( settings.uuid, "weights", 0, 0, 0, 0  )
    weight = WEIGHTS.weights[!,ccode] 
    for i in 1:settings.num_households
        hh = get_household(i)
        hh.council = ccode
        hh.weight = weight[i]
        # FRSHouseholdGetter.MODEL_HOUSEHOLDS.weight[i] = weight[i]
    end
     
    base_cost = get_base_cost( ;
        settings = settings, base_sys=system[1], observer = observer )

    local_income_tax = equalise( 
        target, 
        system[2], 
        settings, 
        base_cost, 
        obs )


    # always reload data at the end so we haven't messed up councils and weights
    if restore
        @time settings.num_households, settings.num_people, nhh2 = 
            FRSHouseholdGetter.initialise( settings )
    end
    return revtab
end


progressive_ct_sys = deepcopy( base_sys )
progressive_ct_sys.loctax.ct.relativities = PROGRESSIVE_RELATIVITIES

for ccode in LA_CODES

end

end