
using ScottishTaxBenefitModel
using .STBParameters
using .BCCalcs
using .RunSettings
using .Definitions
using .ExampleHelpers
using .ModelHousehold
using .RunSettings
using .Utils

using BudgetConstraints
using DataFrames
using CairoMakie

using CSV


"""
Generate a pair of budget constraints (as Dataframes) for the given household.
"""
function getbc( 
    hh  :: Household, 
    sys :: TaxBenefitSystem, 
    wage :: Real,
    settings :: Settings )::Tuple
    defroute = settings.means_tested_routing
    settings.means_tested_routing = lmt_full 
    lbc = BCCalcs.makebc( hh, sys, settings, wage )
    settings.means_tested_routing = uc_full 
    ubc = BCCalcs.makebc( hh, sys, settings, wage )
    settings.means_tested_routing = defroute
    (lbc,ubc)
end

"""
This is stolen from the bcd service.
"""
function get_hh( ;
    country   :: AbstractString,
    tenure    :: AbstractString,
    bedrooms  :: Integer, 
    hcost     :: Real, 
    marrstat  :: AbstractString, 
    chu6      :: Integer, 
    ch6p      :: Integer ) :: Household
    hh = get_example( single_hh )
    head = get_head(hh)
    head.age = 30
    sp = get_spouse(hh)
    enable!(head) # clear dla stuff from example
    hh.region = if country == "scotland"
            Scotland
    elseif country == "wales" # not actually possible with current interface
            Wales 
    else # just pick a random English one.
            North_East
    end 
    hh.tenure = if tenure == "private"
            Private_Rented_Unfurnished
    elseif tenure == "council"
            Council_Rented
    elseif tenure == "owner"
            Mortgaged_Or_Shared
    else
            @assert false "$tenure not recognised"
    end
    hh.bedrooms = bedrooms
    hh.other_housing_charges = hh.water_and_sewerage = 0
    if hh.tenure == Mortgaged_Or_Shared
            hh.mortgage_payment = hcost
            hh.mortgage_interest = hcost
            hh.gross_rent = 0
    else
            hh.mortgage_payment = 0
            hh.mortgage_interest = 0
            hh.gross_rent = hcost
    end
    if marrstat == "couple"
            sex = head.sex == Male ? Female : Male # hetero ..
            add_spouse!( hh, 30, sex )
            sp = get_spouse(hh)
            enable!(sp)
            set_wage!( sp, 0, 10 )
    end
    age = 0
    for ch in 1:chu6
            sex = ch % 1 == 0 ? Male : Female
            age += 1
            add_child!( hh, age, sex )
    end
    age = 7
    for ch in 1:ch6p
            sex = ch % 1 == 0 ? Male : Female
            age += 1
            add_child!( hh, age, sex )
    end
    set_wage!( head, 0, 10 )
    for (pid,pers) in hh.people
            # println( "age=$(pers.age) empstat=$(pers.employment_status) " )
            empty!( pers.income )
            empty!( pers.assets )
    end
    return hh
end

function do_everything(sys :: TaxBenefitSystem, settings::Settings)::Dict
    tenures = ["private", "council", "owner"]
    country = "scotland"
    hcosts = [0.0,100,200,300,400.0,500]
    marrstats = ["single", "couple"]
    out = Dict()
    processed = 0
    num_bedrooms = 1:6
    for wage in [10,20,30]
        for tenure in tenures
            for marrstat in marrstats
                for hcost in hcosts
                    for bedrooms in num_bedrooms
                        for chu6 in 0:2:4
                            for ch6p in 0:2:4
                                processed += 1
                                hh =  get_hh( ;
                                    country = country,
                                    tenure  = tenure,
                                    bedrooms = bedrooms,
                                    hcost    = hcost,
                                    marrstat = marrstat, 
                                    chu6     = chu6, 
                                    ch6p     = ch6p )
                                lbc, ubc = getbc( hh, sys, wage, settings )
                                key = (wage, tenure, marrstat, hcost, bedrooms, chu6, ch6p )
                                println( "on $key")
                                println( "processed $processed")
                                out[key] = (; lbc, ubc )
                            end
                        end
                    end
                end
            end
        end
    end
    return out
end
#=
settings = Settings()
sys = STBParameters.get_default_system_for_fin_year( 2024 )
=#
    