using CSV, DataFrames
using Format
using StatsBase
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

DFL = joinpath( MODEL_DATA_DIR, "wales", "default_reform_levels.csv" )
DEFAULT_REFORM_LEVELS = CSV.File( DFL ) |> DataFrame

WF = joinpath( MODEL_DATA_DIR,  "wales", "local","council-weights-2023-4.csv") 
WEIGHTS = CSV.File( WF ) |> DataFrame

CCODES = Symbol.(names(WEIGHTS)[3:end])


PROGRESSIVE_RELATIVITIES = Dict{CT_Band,Float64}(
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


function infer_house_price!( hh :: Household, hhincome :: Real )
    ## wealth_regressions.jl , model 3
    hhincome = max(hhincome, 1.0)

    hp = 0.0
    if is_owner_occupier(hh.tenure)
        c = ["(Intercept)"            10.576
        "scotland"               -0.279896
        "wales"                  -0.286636
        "london"                  0.843206
        "owner"                   0.0274378
        "detatched"               0.139247
        "semi"                   -0.169271
        "terraced"               -0.257117
        "purpose_build_flat"     -0.170908
        "HBedrmr7"                0.242845
        "hrp_u_25"               -0.334261
        "hrp_u_35"               -0.266385
        "hrp_u_45"               -0.206901
        "hrp_u_55"               -0.159525
        "hrp_u_65"               -0.10077
        "hrp_u_75"               -0.0509382
        "log_weekly_net_income"   0.17728
        "managerial"              0.227192
        "intermediate"            0.165209]
        
        hrp = get_head( hh )

        v = ["(Intercept)"          1
        "scotland"                  0
        "wales"                     1
        "london"                    0
        "owner"                     hh.tenure == Owned_outright ? 1 : 0
        "detatched"                 hh.dwelling == detatched ? 1 : 0
        "semi"                      hh.dwelling == semi_detached ? 1 : 0
        "terraced"                  hh.dwelling == terraced ? 1 : 0
        "purpose_build_flat"        hh.dwelling == flat_or_maisonette ? 1 : 0
        "HBedrmr7"                  hh.bedrooms
        "hrp_u_25"                  hrp.age < 25 ? 1 : 0
        "hrp_u_35"                  hrp.age in [25:44] ? 1 : 0
        "hrp_u_45"                  hrp.age in [45:54] ? 1 : 0
        "hrp_u_55"                  hrp.age in [55:64] ? 1 : 0
        "hrp_u_65"                  hrp.age in [65:74] ? 1 : 0
        "hrp_u_75"                  hrp.age in [75:999] ? 1 : 0
        "log_weekly_net_income"     log(hhincome)
        "managerial"                hrp.socio_economic_grouping in [Managers_Directors_and_Senior_Officials,Professional_Occupations] ? 1 : 0
        "intermediate"              hrp.socio_economic_grouping in [Associate_Prof_and_Technical_Occupations,Admin_and_Secretarial_Occupations] ? 1 : 0
        ]
        hp = exp( c[:,2]'v[:,2])
        
    elseif hh.tenure !== Rent_free
        # @assert hh.gross_rent > 0 "zero rent for hh $(hh.hid) $(hh.tenure) "
        # 1 │  2272       2015         0.0
        # 2 │ 10054       2015         0.0
        # 3 │  5019       2016         0.0
        # assign 50 pw to these 3
        rent = hh.gross_rent == 0 ? 50.0 : hh.gross_rent # ?? 3 cases of 0 rent
        hp = rent * WEEKS_PER_YEAR * 20
    else
        hp = 80_000
    end
    hh.house_value = hp
end

function add_house_price( settings::Settings )
    hh_dataset = CSV.File("$(settings.data_dir)/$(settings.household_name).tab" ) |> DataFrame
    obs = Observable( Progress(settings.uuid,"",0,0,0,0))
    # coerce house_value from coltype 'Missing'
    hh_dataset.house_value = zeros(settings.num_households)
    base_sys = get_system(year=2022)
    frames = do_one_run( settings, [base_sys], obs )
    incomes = frames.hh[1].bhc_net_income     
    for i in 1:settings.num_households
        hh = get_household(i)
        hres = frames.hh[1][i,:]
        @assert hres.hid == hh.hid
        @assert hh_dataset[i,:].hid == hh.hid
        infer_house_price!( hh, hres.bhc_net_income )
        hh_dataset[i,:].house_value = hh.house_value
    end
    rent_summary = combine(groupby(hh_dataset,:tenure), [:house_value] .=> [length,mean,median])
    
    CSV.write( "$(settings.data_dir)/$(settings.household_name).tab", hh_dataset )
    rent_summary
end

"""
FIXME check if the bands needs Weeklyised 05/04/2024
"""
function get_system( ; year = 2022 ) :: TaxBenefitSystem
    sys = nothing
    if year == 2022
        sys = get_default_system_for_date( FY_2022, scotland=false )
        # sys = load_file("$(MODEL_PARAMS_DIR)/sys_2022-23.jl" )
        # load_file!( sys, "$(MODEL_PARAMS_DIR)/sys_2022-23_ruk.jl" )
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
        sys.loctax.ct.house_values = wales_ct_house_values(Float64)        

    end  # 2022
    sys.scottish_child_payment = 0.0
    # weeklyise!(sys)
    return sys
end

function setct!( sys, value )
    for k in eachindex(sys.loctax.ct.band_d)
        sys.loctax.ct.band_d[k] = value
    end

end

function fmt(v::Number) 
    return Format.format(v, commas=true, precision=0)
end

function get_sett()
    settings = Settings()
    settings.auto_weight = false
    settings.benefit_generosity_estimates_available = false
    settings.household_name = "model_households_wales"
    settings.people_name    = "model_people_wales"
    settings.do_marginal_rates = false
    settings.ineq_income_measure = eq_ahc_net_income
    settings.requested_threads = 5
    return settings
end

SYSTEM_NAMES = [
    "Current System", 
    "CT Incidence",
    "Local Income Tax",
    "Progressive Bands", 
    "Proportional Property Tax",
    "Council Tax With Revalued House Prices and compensating band D cuts", 
    "Council Tax With Revalued House Prices & Fairer Bands" ]

function make_parameter_set(;
    local_income_tax :: Real, 
    fairer_bands_band_d :: Real,  
    proportional_property_tax :: Real,
    revalued_housing_band_d :: Real,
    revalued_housing_band_d_w_fairer_bands :: Real,
    code :: Symbol )

    base_sys = get_system(year=2022)

    no_ct_sys = deepcopy( base_sys )
    no_ct_sys.loctax.ct.abolished = true
    setct!( no_ct_sys, 0.0 )
    
    local_it_sys = deepcopy( no_ct_sys )
    local_it_sys.it.non_savings_rates .+= local_income_tax/100.0

    progressive_ct_sys = deepcopy( base_sys )
    progressive_ct_sys.loctax.ct.relativities = PROGRESSIVE_RELATIVITIES
    progressive_ct_sys.loctax.ct.band_d[code] += fairer_bands_band_d / WEEKS_PER_YEAR

    ppt_sys = deepcopy(no_ct_sys)
    ppt_sys.loctax.ct.abolished = true        
    ppt_sys.loctax.ppt.abolished = false
    ppt_sys.loctax.ppt.rate = proportional_property_tax/(100.0*WEEKS_PER_YEAR)
    
    revalued_prices_sys = deepcopy( base_sys )
    revalued_prices_sys.loctax.ct.revalue = true
    revalued_prices_sys.loctax.ct.band_d[code] += revalued_housing_band_d/WEEKS_PER_YEAR

    revalued_prices_w_prog_bands_sys = deepcopy( base_sys )
    revalued_prices_w_prog_bands_sys.loctax.ct.revalue = true
    revalued_prices_w_prog_bands_sys.loctax.ct.relativities = PROGRESSIVE_RELATIVITIES
    revalued_prices_w_prog_bands_sys.loctax.ct.band_d[code] += revalued_housing_band_d_w_fairer_bands/WEEKS_PER_YEAR
        
    return base_sys,
        no_ct_sys,
        local_it_sys,
        progressive_ct_sys,
        ppt_sys, 
        revalued_prices_sys,
        revalued_prices_w_prog_bands_sys
end

function make_parameter_set( code :: Symbol )
    r = DEFAULT_REFORM_LEVELS[
        Symbol.(DEFAULT_REFORM_LEVELS.code) .== code,:][1,:]
    return make_parameter_set(;
        local_income_tax = r.local_income_tax,
        fairer_bands_band_d = r.fairer_bands_band_d,
        proportional_property_tax = r.proportional_property_tax,
        revalued_housing_band_d = r.revalued_housing_band_d,
        revalued_housing_band_d_w_fairer_bands = r.revalued_housing_band_d_w_fairer_bands,
        code = code )
end

INCREMENT_NAMES = [
    "£100pa Band D Increase",
    "£100pa Band D",
    "1p increase to all income tax bands",
    "£100pa Band D Increase",
    "0.1 increase in rate",
    "£100pa Band D Increase",
    "£100pa Band D Increase"
]

function incremented_params( code :: Symbol, pct_change = false )
    base_sys,
    no_ct_sys,
    local_it_sys,
    progressive_ct_sys,
    ppt_sys, 
    revalued_prices_sys,
    revalued_prices_w_prog_bands_sys = make_parameter_set( code )

    if( ! pct_change )
        base_sys.loctax.ct.band_d[code] += 100.0/WEEKS_PER_YEAR
        # no_ct_sys
        local_it_sys.it.non_savings_rates .+= 0.01
        progressive_ct_sys.loctax.ct.band_d[code] += 100.0/WEEKS_PER_YEAR
        ppt_sys.loctax.ppt.rate  += 0.1/(100*WEEKS_PER_YEAR)
        revalued_prices_sys.loctax.ct.band_d[code] += 100.0/WEEKS_PER_YEAR
        revalued_prices_w_prog_bands_sys.loctax.ct.band_d[code] += 100.0/WEEKS_PER_YEAR
    else
        base_sys.loctax.ct.band_d[code] *= 1.01
        # no_ct_sys
        local_it_sys.it.non_savings_rates *= 1.01
        progressive_ct_sys.loctax.ct.band_d[code] *= 1.01
        ppt_sys.loctax.ppt.rate  += 1.01
        revalued_prices_sys.loctax.ct.band_d[code] *= 1.01
        revalued_prices_w_prog_bands_sys.loctax.ct.band_d[code] *= 1.01
    end
    return base_sys,
        no_ct_sys,
        local_it_sys,
        progressive_ct_sys,
        ppt_sys, 
        revalued_prices_sys,
        revalued_prices_w_prog_bands_sys

end


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

function get_default_stuff( num_systems :: Int )
    settings = get_sett()
    T = Float64
    obs = Observable( Progress(settings.uuid,"",0,0,0,0))
    settings.num_people = 0 #num_people * size(ccodes)[1]
    settings.num_households = 0 # num_households * size(ccodes)[1]
    total_frames :: NamedTuple = initialise_frames( T, settings, num_systems )
    @time num_households, num_people, nhh2 = initialise( settings; reset=true )
    settings.num_people = num_people
    settings.num_households = num_households    
    return settings, obs, total_frames, revenues_table()
end


function get_base_cost( base_sys :: TaxBenefitSystem ) :: Real
    settings = get_sett()
    frames = do_one_run( settings, [base_sys], obs )        
    settings.poverty_line = make_poverty_line( frames.hh[1], settings )
    pc_frames = summarise_frames!(frames, settings)
    base_cost = pc_frames.income_summary[1][1,:net_cost]
    return base_cost
end

function do_equalising_runs( code :: Symbol )

    # not acually using revenue and total here
    settings = get_sett()
    obs = obs = Observable( Progress(settings.uuid,"",0,0,0,0))

    no_ct_sys,
    local_it_sys,
    progressive_ct_sys,
    ppt_sys, 
    revalued_prices_sys,
    revalued_prices_w_prog_bands_sys = make_parameter_set( code )

    load_prices( settings, false )
    @time settings.num_households, settings.num_people, nhh2 = initialise( 
        settings; reset=true )

    # switch dataset to current weights/ccode
    w = WEIGHTS[!,code]
    for i in 1:settings.num_households
        hh = get_household(i)
        hh.council = code
        hh.weight = w[i]
        FRSHouseholdGetter.MODEL_HOUSEHOLDS.weight[i] = w[i]
    end
    
    base_cost = get_base_cost( base_sys )
        
    local_income_tax = equalise( 
        eq_it, 
        local_it_sys, 
        settings, 
        base_cost, 
        obs )
    
    fairer_bands_band_d = equalise( 
            eq_ct_band_d, 
            progressive_ct_sys, 
            settings, 
            base_cost, 
            obs )
    
    proportional_property_tax = equalise( 
        eq_ppt_rate, 
        ppt_sys, 
        settings, 
        base_cost, 
        obs )
    
    revalued_housing_band_d = equalise( 
        eq_ct_band_d, 
        revalued_prices_sys, 
        settings, 
        base_cost, 
        obs )
     
    revalued_housing_band_d_w_fairer_bands = equalise( 
        eq_ct_band_d, 
        revalued_prices_w_prog_bands_sys, 
        settings, 
        base_cost, 
        obs )
    (;  local_income_tax, 
        fairer_bands_band_d, 
        proportional_property_tax, 
        revalued_housing_band_d, 
        revalued_housing_band_d_w_fairer_bands )
end

function do_equalising_runs()
    for code in CCODES 
        local_income_tax, 
        fairer_bands_band_d, 
        proportional_property_tax, 
        revalued_housing_band_d, 
        revalued_housing_band_d_w_fairer_bands = do_equalising_runs( code )
        # ...
         # cleanup we don't need code map her
         #=
        ctrevenue1 = pc_frames.income_summary[1].local_taxes[1] -
            pc_frames.income_summary[1].council_tax_benefit[1]
        ctrevenue2 = pc_frames.income_summary[2].local_taxes[1] -
            pc_frames.income_summary[2].council_tax_benefit[1]
        ctrevenue = ctrevenue1 - ctrevenue2
        revenues[(revenues.code.==code),:modelled_ct] .= 
            pc_frames.income_summary[1].local_taxes[1]
        revenues[(revenues.code.==code),:modelled_ctb] .= 
            pc_frames.income_summary[1].council_tax_benefit[1]
        revenues[(revenues.code.==code),:net_modelled] .= 
            pc_frames.income_summary[1].local_taxes[1] -
                pc_frames.income_summary[1].council_tax_benefit[1]

        revenues[(revenues.code.==code),:modelled_ct] .= 
            fmt.(pc_frames.income_summary[1].local_taxes[1])
        revenues[(revenues.code.==code),:modelled_ctb] .= 
            fmt.(pc_frames.income_summary[1].council_tax_benefit[1])
        revenues[(revenues.code.==code),:net_modelled] .= 
            fmt.(pc_frames.income_summary[1].local_taxes[1] -
                pc_frames.income_summary[1].council_tax_benefit[1])
        =#
        #=

        revenues[(revenues.code.==code),:local_income_tax] .= 100.0*itchange
        revenues[(revenues.code.==code),:fairer_bands_band_d] .= banddchange*WEEKS_PER_YEAR
        revenues[(revenues.code.==code),:proportional_property_tax] .= ppt_sys.loctax.ppt.rate*100*WEEKS_PER_YEAR
        revenues[(revenues.code.==code),:revalued_housing_band_d].= rev_banddchange*WEEKS_PER_YEAR
        revenues[(revenues.code.==code),:revalued_housing_band_d_w_fairer_bands].= prog_rev_banddchange*WEEKS_PER_YEAR
        =#

        #=
        revenues[(revenues.code.==code),:local_income_tax] .= Format.format(100.0*itchange, precision=2 )
        revenues[(revenues.code.==code),:fairer_bands_band_d] .= fmt(banddchange*WEEKS_PER_YEAR)
        revenues[(revenues.code.==code),:proportional_property_tax] .= Format.format(ppt_sys.loctax.ppt.rate*100*WEEKS_PER_YEAR, precision=3)
        revenues[(revenues.code.==code),:revalued_housing_band_d].= fmt(rev_banddchange*WEEKS_PER_YEAR)
        revenues[(revenues.code.==code),:revalued_housing_band_d_w_fairer_bands].= fmt(prog_rev_banddchange*WEEKS_PER_YEAR)
        =#
    end
end

"""
Skeleton for one non-equalising run.
"""
function calculate_local( ; incremented :: Bool = false )
    num_systems = 7
    settings, obs, total_frames = get_default_stuff(num_systems)
    load_prices( settings, false )
    pc_results = Dict{Symbol,NamedTuple}()    
    pc_frames = Dict{Symbol,NamedTuple}()    
    for code in CCODES
        # Set weights for this council.
        w = WEIGHTS[!,code] 
        for i in 1:settings.num_households
            hh = get_household(i)
            hh.council = code
            hh.weight = w[i]
            FRSHouseholdGetter.MODEL_HOUSEHOLDS.weight[i] = w[i]
        end
        all_params=nothing
        if incremented 
            all_params = collect( incremented_params( code ))
        else
            all_params = collect( make_parameter_set( code ))
        end
        println( "on council $code - starting final do_one_run" )
        pc_frames[code] = do_one_run( 
            settings, 
            all_params,
            obs )
        for i in 1:num_systems
            println( "RES $i $(pc_frames[code].hh[i][1,:bhc_net_income])")
        end
        settings.poverty_line = make_poverty_line( pc_frames[code].hh[1], 
            settings )
        pc_results[code] = summarise_frames!( pc_frames[code], settings )    
        println( "appending $code data to global")
    end # each council
    # summarise Wales totals
    incstr = incremented ? "-incremened" : ""
    JLD2.save("all_las_frames$(incstr).jld2", pc_frames );
    JLD2.save("all_las_results$(incstr).jld2", pc_results );

    (; pc_frames, pc_results )

end

function dump_la_frames( pc_frames::Dict, settings :: Settings )
    i = 0
    for code in CCODES
        i += 1
        append = i > 1 
        dump_frames( settings, pc_frames[code]; append=append)
    end
end

"""
For the 'all Wales' deciles graph.
"""
function analyse_one( title, subtitle, oneresult :: NamedTuple, sysno :: Int )
    cs = oneresult.deciles[sysno][:,4]
    c1 = oneresult.deciles[1][:,4]
    gains = 100.0 .* (cs - c1)./c1
    println( "gains $gains")
    chart=Figure() # ; resolution=(1200,1000))
    axd = Axis( # = layout[1,1] 
        chart[1,1], 
        title="$(title): Gains by Decile",
        subtitle=subtitle,
        xlabel="Decile", 
        ylabel="% change Equivalised Income" )
    ylims!( axd, [-10,10])
    barplot!(axd, 1:10, gains)
    return chart
end

"""
Create graphs and tables for one of our runs, and write them to files.
"""
function analyse_one_set( dir::String, subtitle::String, allres::NamedTuple, lares :: Dict, sysno::Int )
    overall = analyse_one( "All Wales", subtitle, 
        allres, sysno )
    save( "$(dir)/all_wales.svg", overall )
    f = Figure(; resolution=( 1240, 1754 )) # a4 @ 150ppi
    n = 1
    for row in 1:8
        for col in 1:3
            n += 1
            if n > 23
                break
            end
            r = CTRATES[n,:]
            println( "on row $(r)")
            laresult = lares[r.code]
            a = Axis( f[row,col], title="$(r.name)"); 
            ylims!(a,[-10,10])
            xdata = 1:10
            cs = laresult.deciles[sysno][:,4]
            c1 = laresult.deciles[1][:,4]
            # @assert c1 .!== 0
            ydata = 100.0 .* (cs - c1) ./ c1 
            barplot!( a, xdata, ydata )
        end
    end
    supertitle = Label(f[0, :], "$subtitle : changes by income decile", fontsize = 30) 
    sidetitle = Label(f[:, 0], "% Changes in Equivalised Income", fontsize = 20, rotation = pi/2)  
    save( "$(dir)/by_la.svg", f )
end

"""
Complete set of charts and tables written to file for each of our systems.
"""
function analyse_all( allres::NamedTuple, lares :: Dict )
    analyse_one_set("../WalesTaxation/output/ctincidence", SYSTEM_NAMES[2], allres, lares, 2 )
    analyse_one_set("../WalesTaxation/output/local_income_tax", SYSTEM_NAMES[3], allres, lares, 3 )
    analyse_one_set("../WalesTaxation/output/progressive_bands", SYSTEM_NAMES[4], allres, lares,  4 )
    analyse_one_set("../WalesTaxation/output/proportional_property_tax", SYSTEM_NAMES[5], allres, lares,  5 )
    analyse_one_set("../WalesTaxation/output/revalued_ct", SYSTEM_NAMES[6], allres, lares,  6 )
    analyse_one_set("../WalesTaxation/output/revalued_ct_w_fairer_bands", SYSTEM_NAMES[7], allres, lares,  7 )
end

"""
Honestly don't remember what this was for ..
"""
function getbands()
    settings = get_sett()
    @time settings.num_households, settings.num_people, nhh2 = initialise( settings; reset=true )
    nhhs = settings.num_households
    bands = DataFrame( weight = zeros(nhhs), 
        pre = fill(Missing_CT_Band,nhhs), 
        post = fill(Missing_CT_Band,nhhs))
    sys = get_system(year=2022)
    for i in 1:settings.num_households
        hh = get_household(i)
        bands[i,:].weight = 1 #hh.weight
        bands[i,:].pre = hh.ct_band
        ct_band = LocalLevelCalculations.band_from_value( hh.house_value, sys.loctax.ct.house_values )
        bands[i,:].post = ct_band
    end
    bands
end

"""
## accumulate totals - FIXME: isn't this all we really need?
"""
function do_all( pc_frames :: Dict; do_gain_lose=false )
    settings = get_sett()
    num_systems = 7
    settings.num_people = 0 #num_people * size(ccodes)[1]
    settings.num_households = 0 # num_households * size(ccodes)[1]
    total_frames = initialise_frames( Float64, settings, num_systems )
    for scode in CCODES
        code = String(scode)
        println( "on $code")
        for sysno in 1:num_systems
            println( "sysno $sysno")
            total_frames.bu[sysno] = 
                vcat( total_frames.bu[sysno], pc_frames[code].bu[sysno] )
            total_frames.hh[sysno] = 
                vcat( total_frames.hh[sysno], pc_frames[code].hh[sysno] )
            total_frames.income[sysno] = 
                vcat( total_frames.income[sysno], pc_frames[code].income[sysno] )
            total_frames.indiv[sysno] = 
                vcat( total_frames.indiv[sysno], pc_frames[code].indiv[sysno] )
        end
        # force gc
        # pc_frames[code] = nothing
    end
    
    settings.poverty_line = make_poverty_line( total_frames.hh[1], settings )
    println( "making overall results summarise_frames")
    overall_results = summarise_frames!( total_frames, settings; do_gain_lose=do_gain_lose ) 
    return overall_results #  do_gain_lose = false  )
end


# output formatters
countfmt = (v, i, j) -> fmt(v)
pctfmt = (v, i, j) Format.format(v, precision=2)

function how_we_doing_fmt(val, row, col )
    if col == 1 # name col
       return val
    end
    return fmt(val/1000.0)
end


function gl_fmt(val, row, col )
    if col == 1 # name col
        if typeof(val) <: AbstractFloat
            return Format.format(val, precision=0)
        else 
            return pretty("$val")
        end
    end
    return fmt(val)
end


function headline_fmt(val, row, col )
    if col == 1
       return val
    elseif col in (2,4)
       return Format.format(val, precision=2)
    end 
    return fmt(val)
end




function changes_to_table( base::Dict, changed::Dict )
    tables = []
    for sys in 1:7
        codes=copy(CTLEVELS.code) # Symbol.(CTLEVELS.code)
        push!( codes, "Total" ) # Symbol(""))
        names=copy(CTLEVELS.name)
        println( "names=$names")
        push!(names,"Total")
        d = DataFrame( 
            name=names, 
            code=codes, 
            ct_change = zeros(23), 
            ctb_change = zeros(23),
            net_change = zeros(23) )  
        
        net_total = 0.0      
        ctb_total = 0.0
        ct_total = 0.0
        for code in CCODES
            scode = String(code) ## FIXME fix base to symbol
            println( "looking for code $scode")
            if sys == 3 ## income tax
                ct_change = changed[scode].income_summary[sys][1,:income_tax] - 
                    base[scode].income_summary[sys][1,:income_tax]
            else
                ct_change = changed[scode].income_summary[sys][1,:local_taxes] - 
                    base[scode].income_summary[sys][1,:local_taxes]
            end
            ctb_change = changed[scode].income_summary[sys][1,:council_tax_benefit] - 
                base[scode].income_summary[sys][1,:council_tax_benefit]
            net_change = ct_change - ctb_change
            net_total += net_change
            ctb_total += ctb_change
            ct_total += ct_change
            d[(d.code.==scode),:ct_change] .= ct_change
            d[(d.code.==scode),:ctb_change] .= ctb_change
            d[(d.code.==scode),:net_change] .= net_change
        end
        d[23,:ct_change] = ct_total
        d[23,:ctb_change] = ctb_total
        d[23,:net_change] = net_total
        push!(tables, d)
    end
    tables
end


function write_main_tables( mainres :: NamedTuple, lares :: Dict, lares_incr :: Dict )
    open("../WalesTaxation/output/main_tables.md","w") do outfile
        println( outfile, "\n\n### Accuracy: Modelled Net Council Tax vs Actual \n£000s pa\n")
        pretty_table( outfile,
            DEFAULT_REFORM_LEVELS[!,[:name,:actual_revenues,:modelled_ct,:modelled_ctb,:net_modelled]],
            formatters=how_we_doing_fmt, 
            tf = tf_markdown )

        println( outfile, "\n\n### Baseline reform levels\n")
        pretty_table( outfile,
            DEFAULT_REFORM_LEVELS[!,
                [:name,
                :local_income_tax,
                :fairer_bands_band_d,
                :proportional_property_tax,
                :revalued_housing_band_d,
                :revalued_housing_band_d_w_fairer_bands]],
            formatters=headline_fmt, tf = tf_markdown )
        change_frames = changes_to_table( lares, lares_incr )
        for sysno in 1:7
            println( outfile, "\n\n## $(SYSTEM_NAMES[sysno])\n")
            println( outfile, "### Gainers and Losers\n" )
            println( outfile, "\n####  By Tenure  \n")
            pretty_table( outfile, mainres.gain_lose[sysno].ten_gl, formatters=gl_fmt, tf = tf_markdown )
            println( outfile, "\n\n#### By Decile\n")
            pretty_table( outfile, mainres.gain_lose[sysno].dec_gl, formatters=gl_fmt, tf = tf_markdown )
            println( outfile, "\n\n#### By Number of Children\n")
            pretty_table( outfile, mainres.gain_lose[sysno].children_gl, formatters=gl_fmt, tf = tf_markdown )
            println( outfile, "\n\n#### By Number of People \n")
            pretty_table( outfile, mainres.gain_lose[sysno].hhtype_gl, formatters=gl_fmt, tf = tf_markdown )
            println( outfile, "\n\n### Effect of $(INCREMENT_NAMES[sysno]). \n£000s pa\n")
            pretty_table( outfile, change_frames[sysno][!,[:name, :ct_change,:ctb_change,:net_change ]], formatters=how_we_doing_fmt, tf = tf_markdown )
        end
    end # file open
end

# prettytable( df; formatters=countfmt, tf = tf_markdown )

function do_everything()
    pc_frames=JLD2.load("all_las_frames.jld2")
    pc_results = JLD2.load( "all_las_results.jld2")
    # pc_frames, pc_results = calculate_local()
    overall_results = do_all( pc_frames, do_gain_lose=true )
    # res_incr = calculate_local( incremented = true )
    pc_frames_incr = JLD2.load("all_las_frames-incremened.jld2")
    pc_results_incr = JLD2.load("all_las_results-incremened.jld2")
    write_main_tables( overall_results, pc_results, pc_results_incr )
    analyse_all( overall_results, pc_results )

end