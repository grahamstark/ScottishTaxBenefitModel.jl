using CSV, DataFrames
using Formatting
using StatsBase
using PrettyTables
using CairoMakie

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
using .TheEqualiser
using .GeneralTaxComponents: WEEKS_PER_YEAR
using .Uprating: load_prices
using .SingleHouseholdCalculations: do_one_calc
using .STBOutput: 
    initialise_frames, 
    add_to_frames!, 
    summarise_frames, 
    make_poverty_line
using .Monitor: Progress
using .Runner: do_one_run

export load_all_census,
    copysbdata,
    create_target_matrix,
    get_run_settings,
    DATADIR

function get_system( ; year = 2022 ) :: TaxBenefitSystem
    sys = nothing
    if year == 2022
        sys = load_file("$(MODEL_PARAMS_DIR)/sys_2022-23.jl" )
        ## wales specific CT rels; see []??
        sys.loctax.ct.relativities = Dict{CT_Band,Float64}(
            Band_A=>240/360,
            Band_B=>280/360,
            Band_C=>320/360,
            Band_D=>360/360,
            Band_E=>440/360,
            Band_F=>520/360,                                                                      
            Band_G=>600/360,
            Band_H=>720/360,
            Band_I=>840/360,
            Household_not_valued_separately => 0.0 ) 
        ctf = joinpath( MODEL_DATA_DIR, "wales", "counciltax", "council-tax-levels-23-24-edited.csv")
        ctrates = CSV.File( ctf ) |> DataFrame
        p = 0
        band_ds = Dict{Symbol,Float64}()
        for r in eachrow(ctrates)
            p += 1
            if p > 1 # skip 1
                band_ds[Symbol(r.code)] = r.D
            end
        end
        sys.loctax.ct.band_d = band_ds

    end  # 2022
    sys.scottish_child_payment = 0.0
    weeklyise!(sys)
    return sys
end

function setct!( sys, value )
    for k in eachindex(sys.loctax.ct.band_d)
        sys.loctax.ct.band_d[k] = value
    end

end

function get_sett()
    settings = Settings()
    settings.auto_weight = false
    settings.benefit_generosity_estimates_available = false
    settings.household_name = "model_households_wales"
    settings.people_name    = "model_people_wales"
    settings.do_marginal_rates = false
    settings.ineq_income_measure = eq_ahc_net_income
    settings.requested_threads = 6
    return settings
end

function calculate_local()
    wf = joinpath( MODEL_DATA_DIR,  "wales", "local","council-weights-2023-4.csv") 
    weights = CSV.File( wf ) |> DataFrame
    #  
    ccodes = Symbol.(names(weights)[3:end])
    settings = get_sett()
    obs = Observable( Progress(settings.uuid,"",0,0,0,0))

    load_prices( settings, false )

    sys1 = get_system(year=2022)
    sys2 = deepcopy( sys1 )
    setct!( sys2, 0.0 )

    T = eltype( sys1.it.personal_allowance )
        
    params = [sys1,sys2]
    num_systems = size(params)[1]

    @time num_households, num_people, nhh2 = initialise( settings; reset=true )
    # hack num people - repeated for each council in 1 big output record
    settings.num_people = 0 #num_people * size(ccodes)[1]
    settings.num_households = 0 # num_households * size(ccodes)[1]
    total_frames :: NamedTuple = initialise_frames( T, settings, num_systems )
    pc_frames = Dict()
    ## for the individual results, num people 
    settings.num_people = num_people
    settings.num_households = num_households    
    for code in ccodes        
        w = weights[!,code]
        for i in 1:settings.num_households
            hh = get_household(i)
            hh.council = code
            hh.weight = w[i]
            FRSHouseholdGetter.MODEL_HOUSEHOLDS.weight[i] = w[i]
        end
        frames = do_one_run( settings, [sys1, sys2], obs )
        settings.poverty_line = make_poverty_line( frames.hh[1], settings )
        pc_frames[code] = summarise_frames(frames, settings)
        for sysno in 1:num_systems
            total_frames.bu[sysno ] = vcat( total_frames.bu[sysno ], frames.bu[sysno] )
            total_frames.hh[sysno ] = vcat( total_frames.hh[sysno ], frames.hh[sysno] )
            total_frames.income[sysno ] = vcat( total_frames.income[sysno ], frames.income[sysno] )
            total_frames.indiv[sysno ] = vcat( total_frames.indiv[sysno ], frames.indiv[sysno] )
        end
    end # each council
    settings.poverty_line = make_poverty_line( total_frames.hh[1], settings )
    overall_results = summarise_frames( total_frames, settings )
    (; overall_results, pc_frames, total_frames )
end

function analyse( res :: NamedTuple, compsys :: Int )
    CairoMakie.activate!()
    gains = (res.overall_results.deciles[compsys]-res.overall_results.deciles[1])[:,3]
    charts=Figure(; resolution=(1200,1000))
    axd = Axis(charts[1,1], title="Gains by Decile",xlabel="Decile", ylabel="£s pw")
    barplot!(axd, 1:10, gains)

    res.pc_frames[:W06000024].income_summary[1][:, [:label,:income_tax,:local_taxes,:council_tax_benefit]][1:2,:]

    charts
end
