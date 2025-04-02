using ScottishTaxBenefitModel

using .Definitions
using .FRSHouseholdGetter
using .ModelHousehold
using .LocalLevelCalculations
using .Monitor: Progress
using .Results
using .Runner: do_one_run
using .RunSettings
using .STBOutput
using .STBParameters
using .TheEqualiser
using .TimeSeriesUtils: FY_2024
using .Utils
using .WeightingData

using CairoMakie
using CSV
using DataFrames
using Format
using Parameters
using PrettyTables

function setct!( sys, value )
    for k in eachindex(sys.loctax.ct.band_d)
        sys.loctax.ct.band_d[k] = value
    end
end

function ctstats()::NamedTuple
    df = CSV.File("/mnt/data/ScotBen/data/local/local_targets_2024/ct-2023-4-by-council.tab"; header=4)|>DataFrame
    n = names(df)
    nrows,ncols = size(df)
    grossct = -1 .* Vector(df[1,2:end])
    discounts = -1 .* Vector(df[7,2:end])
    ctr = -1 .* Vector(df[6,2:end])
    ct_net_of_discounts = -1 .* Vector(df[14,2:end])
    netct = -1 .* Vector(df[15,2:end])
    return (; grossct, discounts, ctr, ct_net_of_discounts, netct )
end

function revenues_table()
    cts = ctstats()
    n = length(LA_CODES)
    return DataFrame( 
        name=String.(WeightingData.LA_NAMES[k] for k in LA_CODES), 
        code=LA_CODES, 
        grossct=cts.grossct,
        discounts = cts.discounts, 
        ctr=cts.ctr, 
        ct_net_of_discounts=cts.ct_net_of_discounts, 
        netct=cts.netct,
        modelled_ct_gross=zeros(n), 
        modelled_ct_rebates=zeros(n), 
        modelled_ct_net=zeros(n),
        
        local_income_tax = zeros(n),

        fairer_bands_gross = zeros(n),
        fairer_bands_rebates = zeros(n),
        fairer_bands_net = zeros(n),

        proportional_property_tax_gross = zeros(n),
        proportional_property_tax_rebates = zeros(n),
        proportional_property_tax_net = zeros(n),

        revalued_housing_gross = zeros(n),
        revalued_housing_rebates = zeros(n),
        revalued_housing_net = zeros(n),

        revalued_housing_w_fairer_bands_gross = zeros(n),
        revalued_housing_w_fairer_bands_rebates = zeros(n),
        revalued_housing_w_fairer_bands_net = zeros(n),
        eq_local_income_tax = zeros(n), 
        eq_fairer_bands_band_d = zeros(n), 
        eq_proportional_property_tax = zeros(n), 
        eq_revalued_housing_band_d = zeros(n), 
        eq_revalued_housing_band_d_w_fairer_bands = zeros(n) )
end

PROGRESSIVE_RELATIVITIES = Dict{CT_Band,Float64}(
    # halved below D, doubled above
    Band_A=>120/360,
    Band_B=>140/360,
    Band_C=>160/360,
    Band_D=>360/360,
    Band_E=>473/180,
    Band_F=>585/180,                                                                      
    Band_G=>705/180,
    Band_H=>882/180,
    Band_I=>-1,
    Household_not_valued_separately => 0.0 ) 

SYSTEM_NAMES = [
    (;code=:modelled_ct,label="Current System",pos=1),
    (;code=:zero_ct,label="CT Incidence",pos=2),
    (;code=:local_income_tax,label="Local Income Tax",pos=3),
    (;code=:fairer_bands,label="Progressive Bands", pos=4),
    (;code=:proportional_property_tax,label="Proportional Property Tax",pos=5),
    (;code=:revalued_housing,label="Council Tax With Revalued House Prices and compensating band D cuts", pos=6),
    (;code=:revalued_housing_w_fairer_bands,label="Council Tax With Revalued House Prices & Fairer Bands",pos=7) ]

function to_pct( revtab :: DataFrame )
    revpc = deepcopy(revtab)
    for r in eachrow( revpc )
        r[:local_income_tax] /= r[:modelled_ct_net]/100
        for s in SYSTEM_NAMES[4:end] # after LIT
            for n in ["gross","rebates", "net"]
                r[Symbol("$(s.code)_$(n)")] /= r[Symbol("modelled_ct_$(n)")]/100
            end            
        end
    end
    revpc
end



@with_kw mutable struct InitialIncrements
    local_income_tax = 4.4/1.1045 # pts increase in all IT bands rough calc based on Aberdeen City
    fairer_bands_band_d = 0.7522830358234829
    proportional_property_tax = 5.0*0.07841108126618404
    revalued_housing_band_d = 1.0/1.6588543231593292
    revalued_housing_band_d_w_fairer_bands = 1.0/1.9282500675989838
end

"""

* `local_income_tax`: pts increase in all IT band
* `fairer_bands_band_d_pct` rel change in % to current band d
* `proportional_property_tax` in pct

"""
function make_parameter_set( initr :: InitialIncrements, ccode :: Symbol )

    base_sys = get_default_system_for_date( FY_2024, scotland=true )
        
    no_ct_sys = deepcopy( base_sys )
    no_ct_sys.loctax.ct.abolished = true
    setct!( no_ct_sys, 0.0 )
    
    local_it_sys = deepcopy( no_ct_sys )
    local_it_sys.it.non_savings_rates .+= initr.local_income_tax/100.0

    progressive_ct_sys = deepcopy( base_sys )
    progressive_ct_sys.loctax.ct.relativities = PROGRESSIVE_RELATIVITIES
    progressive_ct_sys.loctax.ct.band_d[code] *= initr.fairer_bands_band_d

    ppt_sys = deepcopy(no_ct_sys)
    ppt_sys.loctax.ct.abolished = true        
    ppt_sys.loctax.ppt.abolished = false
    ppt_sys.loctax.ppt.rate = initr.proportional_property_tax/(100.0*WEEKS_PER_YEAR)
    
    revalued_prices_sys = deepcopy( base_sys )
    revalued_prices_sys.loctax.ct.revalue = true
    revalued_prices_sys.loctax.ct.house_values = Dict{CT_Band,Float64}(
        Band_A=>44_000.0,
        Band_B=>65_000.0,
        Band_C=>91_000.0,
        Band_D=>123_000.0,
        Band_E=>162_000.0,
        Band_F=>223_000.0,                                                                      
        Band_G=>324_000.0,
        Band_H=>99999999999999999999999.999, # 424_000.00,
        Band_I=>-1, # wales only
        Household_not_valued_separately => 0.0 )
    revalued_prices_sys.loctax.ct.band_d[code] *= initr.revalued_housing_band_d

    revalued_prices_w_prog_bands_sys = deepcopy( revalued_prices_sys )
    revalued_prices_w_prog_bands_sys.loctax.ct.relativities = PROGRESSIVE_RELATIVITIES
    revalued_prices_w_prog_bands_sys.loctax.ct.band_d[code] *= initr.revalued_housing_band_d_w_fairer_bands
        
    return base_sys,
        no_ct_sys,
        local_it_sys,
        progressive_ct_sys,
        ppt_sys, 
        revalued_prices_sys,
        revalued_prices_w_prog_bands_sys
end

function get_base_cost( settings, base_sys :: TaxBenefitSystem ) :: Real
    obs = obs = Observable( Progress(settings.uuid,"",0,0,0,0))
    frames = do_one_run( settings, [base_sys], obs )        
    pc_frames = summarise_frames!(frames, settings)
    base_cost = pc_frames.income_summary[1][1,:net_cost]
    return base_cost
end

function do_equalising_runs( settings )::InitialIncrements

    # not acually using revenue and total here
    obs = obs = Observable( Progress(settings.uuid,"",0,0,0,0))

    base_sys,
    no_ct_sys,
    local_it_sys,
    progressive_ct_sys,
    ppt_sys, 
    revalued_prices_sys,
    revalued_prices_w_prog_bands_sys = make_parameter_set( InitialIncrements(), settings.ccode )
    
    base_cost = get_base_cost( settings, base_sys )
        
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
    return InitialIncrements(local_income_tax, 
        fairer_bands_band_d, 
        proportional_property_tax, 
        revalued_housing_band_d, 
        revalued_housing_band_d_w_fairer_bands )
end

settings = Settings()
settings.do_local_run = true
settings.requested_threads = 4
# FIXME we need ahc here because we treat *all* local taxes as a housing cost
# and I need to check if HBAI does this.
settings.ineq_income_measure = eq_ahc_net_income    
settings.weighting_strategy = use_precomputed_weights

observer = Observable( Progress(settings.uuid,"",0,0,0,0))

FRSHouseholdGetter.initialise( settings; reset=true )
FRSHouseholdGetter.backup()
revtab = revenues_table()
all_summaries = Dict()
all_frames = Dict()
all_params = Dict{Symbol, InitialIncrements}()
for ccode in LA_CODES[1:1]
    settings.ccode = ccode
    FRSHouseholdGetter.restore()
    FRSHouseholdGetter.set_local_weights_and_incomes!( settings; reset=false )
    increments = do_equalising_runs( settings )
    base_sys,
    no_ct_sys,
    local_it_sys,
    progressive_ct_sys,
    ppt_sys, 
    revalued_prices_sys,
    revalued_prices_w_prog_bands_sys = make_parameter_set( increments, ccode )
    println( "on council $(ccode) : $(WeightingData.LA_NAMES[ccode])")
    systems = [base_sys, # 1
        no_ct_sys, # 2
        local_it_sys, # 3
        progressive_ct_sys, #4
        ppt_sys, #5
        revalued_prices_sys,
        revalued_prices_w_prog_bands_sys]
    frames = do_one_run( settings, systems, observer )
    summaries = summarise_frames!(frames, settings)
    all_summaries[ccode] = summaries
    all_params[ccode] = increments
    # all_frames[ccode] = frames
end

function draw_graphs_for_la( ccode :: Symbol, sm :: NamedTuple )
    f = Figure(; fontsize = 8)
    r = 1
    c = 1
    council = WeightingData.LA_NAMES[ccode]
    Label(f[0, 1:2], council, fontsize = 20)
    for s in SYSTEM_NAMES[2:end]
        dch = sm.deciles[s.pos][:,3] - sm.deciles[1][:,3]
        ax = Axis(f[r,c]; title=s.label, 
            xlabel="Decile", 
            ylabel="Δ £s pw", 
            titlesize=8)
        barplot!( ax, dch )
        c += 1
        if c == 3
            r += 1
            c = 1
        end
    end    
    save("tmp/$(ccode).svg", f )
    save("tmp/$(ccode).png", f )
end

function draw_graphs_for_system( all_summaries::Dict, system :: Int )
    f = Figure(; fontsize = 10, size = (1040, 2000))
    r = 1
    c = 1
    s = SYSTEM_NAMES[system]
    council = WeightingData.LA_NAMES[ccode]
    Label(f[0, 1:2], s.label, fontsize = 16)
    for la in WeightingData.LA_CODES[1:1]
        sm = all_summaries[la]
        dch = sm.deciles[s.pos][:,3] - sm.deciles[1][:,3]
        ax = Axis(f[r,c]; title=WeightingData.LA_NAMES[la], 
            xlabel="Decile", 
            ylabel="Δ £s pw", 
            titlesize=8)
        # maybe but -400 + 400 income tax ylims!(ax, -40, 40 )
        barplot!( ax, dch )
        c += 1
        if c == 5
            r += 1
            c = 1
        end
    end    
    save("tmp/$(s.code).svg", f )
    save("tmp/$(s.code).png", f )
end

function add_one!( revtab :: DataFrame, incsum::DataFrame, sys :: Symbol, ccode :: Symbol )
    revtab[revtab.code .== ccode,Symbol("$(sys)_gross")] .= incsum.local_taxes[1]/1_000
    revtab[revtab.code .== ccode,Symbol("$(sys)_rebates")] .= incsum.council_tax_benefit[1]/1_000
    revtab[revtab.code .== ccode,Symbol("$(sys)_net")] .= (incsum.local_taxes[1] - incsum.council_tax_benefit[1])/1_000
end

function fm(v, r,c) 
    return if c == 1
        v
    elseif c < 7
        Format.format(v, precision=0, commas=true)
    else
        Format.format(v, precision=2, commas=true)
    end
    s
end

"""

"""
function format_gainlose(io::IOStream, title::String, gl::DataFrame)
    gl[!,1] = pretty.(gl[!,1])
    pretty_table(io, gl[!,1:end-1]; 
        backend = Val(:markdown),
        formatters=fm,alignment=[:l,fill(:r,6)...],
        title = title,
        header=["",
            "Lose £10.01+",
            "Lose £1.01-£10",
            "No Change",
            "Gain £1.01-£10",
            "Gain £10.01+",
            "Av. Change"])
end

for ccode in LA_CODES[1:1]
    sm = all_summaries[ccode]
    sp = all_params[ccode]
    ctincidence = sm.deciles[2][:,3] - sm.deciles[1][:,3]
    add_one!( revtab, sm.income_summary[1], :modelled_ct, ccode )
    add_one!( revtab, sm.income_summary[4], :fairer_bands, ccode )
    add_one!( revtab, sm.income_summary[5], :proportional_property_tax, ccode )
    add_one!( revtab, sm.income_summary[6], :revalued_housing, ccode )
    add_one!( revtab, sm.income_summary[7], :revalued_housing_w_fairer_bands, ccode )
    revtab[revtab.code .== ccode,:local_income_tax] .= 
        (sm.income_summary[3].income_tax[1] - sm.income_summary[1].income_tax[1])./1000

    revtab[revtab.code .== ccode,eq_local_income_tax] .= sp.local_income_tax
    revtab[revtab.code .== ccode,eq_fairer_bands_band_d] .= sp.fairer_bands_band_d
    revtab[revtab.code .== ccode,eq_proportional_property_tax] .= sp.proportional_property_tax
    revtab[revtab.code .== ccode,eq_revalued_housing_band_d] .= sp.revalued_housing_band_d
    revtab[revtab.code .== ccode,eq_revalued_housing_band_d_w_fairer_bands] .= sp.revalued_housing_band_d_w_fairer_bands
    

    draw_graphs_for_la( ccode, sm )
end

for sno in 2:7
    draw_graphs_for_system(all_summaries, sno )
end

revpc = to_pct( revtab )

insert = """

### DONE

* A *huge* upgrade to data, inc rewritten matching. 2022 FRS, LCF, SHS data.
* Rewritten Disability Benefit system (not fully finished).

### TODOs

* Disability Benefits routine still not revised fully;
* 2015/6 benefit system;
* Transition - credits all 0 from April;
* Council Tax Needs revised, especially the 2017 reduction and a takeup fix;

### Questions:

* Progressive rates need defined;
* Thresholds for CT bands with revalued houses;
* How to value rented accomodation, esp Council/HA (currently 20x annual rent);


"""

for ccode in WeightingData.LA_CODES[1:1]
    laname = WeightingData.LA_NAMES[ccode]
    io = open( "tmp/fes-tables-$(ccode).md","w")
    println( io, "# Distributional Effects of Local Finance Schemes, by LA\n")
    println( io, insert )
    println(io, "<div style='page-break-after: always;'></div>" )
        println( io, "\n## $laname")
    sm = all_summaries[ccode]
    println( io, "![Image of $laname]($(ccode).svg)")
    for sno in 2:7
        s = SYSTEM_NAMES[sno]
        println( io, "\n### $(s.label)\n")
        println( io, "\n### By Decile\n\n" )        
        format_gainlose(io, "By Decile", sm.gain_lose[s.pos].dec_gl)
        println( io, "\n### By Tenure\n\n" )        
        format_gainlose(io, "By Tenure", sm.gain_lose[s.pos].ten_gl)
    end
    println(io, "<div style='page-break-after: always;'></div>" )
    close(io)
end
