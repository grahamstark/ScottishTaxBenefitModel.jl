using CSV, DataFrames
using Formatting
using StatsBase

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

using .Uprating: load_prices
using .SingleHouseholdCalculations: do_one_calc


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
    weeklyise!(sys)
    return sys
end
 
function calculate_local()
    wf = joinpath( MODEL_DATA_DIR,  "wales", "local","council-weights-2023-4.csv") 
    weights = CSV.File( wf ) |> DataFrame
    #  
    ccodes = Symbol.(names(weights)[3:end])
    settings = Settings()

    settings.auto_weight = false
    settings.benefit_generosity_estimates_available = false
    settings.household_name = "model_households_wales"
    settings.people_name    = "model_people_wales"
    load_prices( settings, false )

    
    sys1 = get_system(year=2022)
    sys2 = deepcopy( sys1 )
    
    
    params = [sys1,sys2]

    @time nhh, num_people, nhh2 = initialise( settings; reset=true )

    revs = DataFrame( 
        code=fill("", 22), 
        ctrev = zeros(22), 
        average_wage=zeros(22), 
        average_se=zeros(22), 
        ft_jobs=zeros(22), 
        semp=zeros(22) )
    p = 0
    for code in ccodes

        # localincometax = deepcopy( sys1.it )
        # localincometax.non_savings_rates .+= 0.01
    
        # scode = Symbol(code)
        w = weights[!,code]
        p += 1
        # band_d = ctrates[(ctrates.code .== code),:D][1]
        ctrev = 0.0
        average_wage = 0.0
        average_se = 0.0
        nearers = 0.0
        nses = 0.0

        for i in 1:nhh
            hh = get_household(i)
            hh.council = code
            hh.weight = w[i]
            for sysno in 1:2
                res = do_one_calc( hh, params[sysno], settings )
                if sysno == 1
                    ctrev += w[i]*total( res, LOCAL_TAXES )
                end
            end
            #=            
            intermed = make_intermediate( 
                hh, sys.lmt.hours_limits,
                sys.age_limits,
                sys.child_limits )
            ct = calc_council_tax(  hh, intermed.hhint, sys.loctax.ct )
            =#
            for (pid,pers) in hh.people
                if pers.employment_status in [
                    Full_time_Employee ]
                    # Part_time_Employee ]
                    nearers += w[i]
                    average_wage += (w[i]*pers.income[wages])
                elseif  pers.employment_status in [
                    Full_time_Self_Employed,
                    Part_time_Self_Employed]
                    average_se += pers.income[self_employment_income]*w[i]
                    nses += w[i]
                end
            end
            
        end 
        average_se /= nses
        average_wage /= nearers
        revs.code[p] = code
        revs.ctrev[p] = ctrev
        revs.average_wage[p] = average_wage
        revs.average_se[p] = average_se
        revs.ft_jobs[p] = nearers
        revs.semp[p] = nses
    end
    #=
    for code in ctrates.code[2:end]
        f = Formatting.format(revs[code],precision=0, commas=true)
        println( "$code = $(f)")
    end
    =#

    revs
end

