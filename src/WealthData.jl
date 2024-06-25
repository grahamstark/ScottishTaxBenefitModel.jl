#=
    
This module holds both the data for wealth tax calculations. Quickie pro tem thing
for Northumberland, but you know how that goes..

TODO add mapping for example households.
TODO all uprating is nom gdp for now.
TODO Factor costs for excisable goods and base excisable good parameters.
TODO Better calculation of exempt goods.
TODO Recheck allocations REALLY carefully.
TODO Much more detailed uprating.
TODO costs of spirits etc.

=#
module WealthData

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

export find_wealth_for_hh!

IND_MATCHING = DataFrame()
WEALTH_DATASET = DataFrame() 
const WEALTH_COLS = [:net_housing,:net_physical,:total_pensions,:net_financial,
                :total_value_of_other_property,
                :total_financial_liabilities,:total_household_wealth]   
function jam_on_float( i :: Int, name )
    return name in WEALTH_COLS ? Float64 : nothing
end
                
function find_wealth_for_hh!( hh :: Household, case :: Integer )
    raw_wealth = WEALTH_DATASET[WEALTH_DATASET.case .== case,:]
    @assert size(raw_wealth)[1] == 1 "find_wealth_for_hh! should be (x,1) is: size=$(size(raw_wealth))"# exactly 1 selection
    hh.raw_wealth = raw_wealth[1,:]
    # FIXME make all these names consistent
    hh.net_physical_wealth = hh.raw_wealth.net_physical
    hh.net_financial_wealth = hh.raw_wealth.net_financial
    hh.net_housing_wealth = hh.raw_wealth.net_housing
    hh.net_pension_wealth = hh.raw_wealth.total_pensions
    hh.total_wealth = hh.raw_wealth.total_household_wealth
end

"""
Match in the was data using the lookup table constructed in 'matching/was_frs_matching.jl'
'which' best, 2nd best etc match (<=20)
"""
function find_wealth_for_hh!( hh :: Household, settings :: Settings, which = 1 )
    @argcheck settings.wealth_method == matching
    @argcheck which in 1:20
    match = IND_MATCHING[(IND_MATCHING.frs_datayear .== hh.data_year).&(IND_MATCHING.frs_sernum .== hh.hid),:][1,:]
    was_case_sym = Symbol( "was_case_$(which)" )
    case = match[was_case_sym]
    find_wealth_for_hh!( hh, case )
end

function uprate_raw_wealth()
    if isnothing(Uprating.UPRATING_DATA)
        Uprating.load_prices( settings )
    end
    nr = size(WEALTH_DATASET)[1]
    for i in 1:nr
        r = WEALTH_DATASET[i,:]
        for sym in WEALTH_COLS
            r[sym] = Uprating.uprate( r[sym], r.year, r.q, Uprating.upr_nominal_gdp )
        end
    end
end

"""
"""
function init( settings :: Settings; reset = false )
    if(settings.wealth_method == matching) && (reset || (size(wealth_DATASET)[1] == 0 )) # needed but uninitialised
        global IND_MATCHING
        global WEALTH_DATASET
        IND_MATCHING = CSV.File( joinpath( settings.data_dir, "$(settings.wealth_matching_dataframe).tab" )) |> DataFrame
        WEALTH_DATASET = CSV.File( joinpath( settings.data_dir, settings.wealth_dataset * ".tab"); types=jam_on_float ) |> DataFrame
        uprate_raw_wealth()
        println( WEALTH_DATASET[1:2,:])
    end
end

end # module
