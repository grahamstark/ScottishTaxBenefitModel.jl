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
## using AbstractPlotting.MakieLayout


export load_all_census,
    copysbdata,
    create_target_matrix,
    get_run_settings,
    DATADIR

CTF = joinpath( MODEL_DATA_DIR, "wales", "counciltax", "council-tax-levels-23-24-edited.csv")
CTRATES = CSV.File( CTF ) |> DataFrame

CTL = joinpath( MODEL_DATA_DIR, "wales", "counciltax", "council-tax-reveues-23-24-edited.csv" )
CTLEVELS = CSV.File( CTL ) |> DataFrame

function get_system( ; year = 2022 ) :: TaxBenefitSystem
    sys = nothing
    if year == 2022
        sys = load_file("$(MODEL_PARAMS_DIR)/sys_2022-23.jl" )
        load_file!( sys, "$(MODEL_PARAMS_DIR)/sys_2022-23_ruk.jl" )
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
        p = 0
        band_ds = Dict{Symbol,Float64}()
        for r in eachrow(CTRATES)
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
    sys3 = deepcopy( sys1 )
    sys4 = deepcopy( sys1 )
    ProgressiveRels = Dict{CT_Band,Float64}(
            # halved below, doubled above
            Band_A=>120/360,
            Band_B=>140/360,
            Band_C=>160/360,
            Band_D=>360/360,
            Band_E=>880/360,
            Band_F=>1040/360,                                                                      
            Band_G=>1200/360,
            Band_H=>1440/360,
            Band_I=>1680/360,
            Household_not_valued_separately => 0.0 ) 
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
    pc_frames2 = Dict()
    ## for the individual results, num people 
    settings.num_people = num_people
    settings.num_households = num_households    

    revenues = DataFrame( 
        name=CTLEVELS.name, 
        code=Symbol.(CTLEVELS.code), 
        actual_revenues=CTLEVELS.to_be_collected .*= 1_000.0, 
        modelled_ct=zeros(22), 
        modelled_ctb=zeros(22), 
        net_modelled=zeros(22),
        local_income_tax = zeros(22),
        fairer_bands_band_d = zeros(22),
        local_wealth_tax = zeros(22) )

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

        # cleanup we don't need code map her
        pc_frames[code] = summarise_frames(frames, settings)
        ctrevenue1 = pc_frames[code].income_summary[1].local_taxes[1] -
            pc_frames[code].income_summary[1].council_tax_benefit[1]
        ctrevenue2 = pc_frames[code].income_summary[2].local_taxes[1] -
            pc_frames[code].income_summary[2].council_tax_benefit[1]
        ctrevenue = ctrevenue1 - ctrevenue2
        revenues[(revenues.code.==code),:modelled_ct] .= 
            pc_frames[code].income_summary[1].local_taxes[1]
        revenues[(revenues.code.==code),:modelled_ctb] .= 
            pc_frames[code].income_summary[1].council_tax_benefit[1]
        revenues[(revenues.code.==code),:net_modelled] .= 
            pc_frames[code].income_summary[1].local_taxes[1] -
            pc_frames[code].income_summary[1].council_tax_benefit[1]
        
        base_cost = pc_frames[code].income_summary[1][1,:net_cost]
        sys3 = deepcopy(sys2)
        itchange = equalise( 
            eq_it, 
            sys3, 
            settings, 
            base_cost, 
            obs )
        # sys3 = deepcopy(sys2)
        sys3.it.non_savings_rates .+= itchange
        sys4 = deepcopy(sys1)
        sys4.loctax.ct.relativities = ProgressiveRels
        banddchange = equalise( 
            eq_ct_rels, 
            sys4, 
            settings, 
            base_cost, 
            obs )
        sys4.loctax.ct.band_d[code] += banddchange
        # just do everything again
        frames = do_one_run( settings, [sys1,sys2,sys3,sys4], obs )
        pc_frames[code] = summarise_frames(frames, settings)

        revenues[(revenues.code.==code),:local_income_tax] .= itchange
        revenues[(revenues.code.==code),:fairer_bands_band_d] .= banddchange*WEEKS_PER_YEAR
        rc = revenues[revenues.code.==code,:][1,:]

        for sysno in 1:num_systems
            total_frames.bu[sysno] = vcat( total_frames.bu[sysno ], frames.bu[sysno] )
            total_frames.hh[sysno] = vcat( total_frames.hh[sysno ], frames.hh[sysno] )
            total_frames.income[sysno] = vcat( total_frames.income[sysno ], frames.income[sysno] )
            total_frames.indiv[sysno] = vcat( total_frames.indiv[sysno ], frames.indiv[sysno] )
        end
    end # each council
    settings.poverty_line = make_poverty_line( total_frames.hh[1], settings )
    overall_results = summarise_frames( total_frames, settings )
    (; overall_results, pc_frames, total_frames, revenues, sys1, sys2, sys3, sys4 )
end

function analyseone( title, oneresult :: NamedTuple, compsys :: Int )
    CairoMakie.activate!()
    gains = (oneresult.deciles[compsys] -
        oneresult.deciles[1])[:,3]
    ## scene, layout = layoutscene(resolution = (1200, 900))
    chart=Figure() # ; resolution=(1200,1000))
    axd = Axis( # = layout[1,1] 
        chart[1,1], 
        title="$(title): Gains by Decile",
        xlabel="Decile", 
        ylabel="£s pw" )
    ylims!( axd, [0,40])
    barplot!(axd, 1:10, gains)
    table = pretty_table( 
        String, 
        tf=tf_markdown, 
        formatters = ft_printf("%.2f", [1, 9]),
        oneresult.deciles[1][:,3] )
    return (chart,table)
end


function analyseall( dir, res )
    for r in eachrow( CTRATES )
        if( r.code != "XX")
            (pic,table) = analyseone( r.name, res.pc_frames[Symbol(r.code)], 2 )
            println( table )
            save( "$(dir)/$(r.code).svg", pic )
        end
      end
end

#=
    save( "main.svg", charts )

    # res.pc_frames[:W06000024].income_summary[1][:, [:label,:income_tax,:local_taxes,:council_tax_benefit]][1:2,:]
    i = 0
    for r in eachrow( CTRATES )
        if i > 0
            lcharts=Figure() # ; resolution=(1200,1000))
            row = (i ÷ 4) + 1
            col = (i % 4) + 1
            ores = res.pc_frames[Symbol(r.code)]
            gains = (ores.deciles[compsys]-ores.deciles[1])[:,3] 
            title = "$(r.name)"           
            axd = Axis( # layout[row,col] = 
                lcharts[1,1], 
                title=title,
                xlabel="Decile", 
                ylabel="£s pw"),            
            barplot!(axd, 
                 1:10, 
                 gains)   
            save( "$(r.code).svg", lcharts )         
        end
        i += 1
    end
    (charts, allcharts)
end
=#