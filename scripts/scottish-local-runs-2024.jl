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
using .TimeSeriesUtils: FY_2024
using .WeightingData

using CSV
using DataFrames
using Format
using PrettyTables
using CairoMakie

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
        revalued_housing_w_fairer_bands_net = zeros(n))
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

"""

* `local_income_tax`: pts increase in all IT band
* `fairer_bands_band_d_pct` rel change in % to current band d
* `proportional_property_tax` in pct

"""
function make_parameter_set(;
    local_income_tax :: Real, 
    fairer_bands_band_d_prop :: Real,  
    proportional_property_tax :: Real,
    revalued_housing_band_d_prop :: Real,
    revalued_housing_band_d_w_fairer_bands_prop :: Real,
    code :: Symbol )

    base_sys = get_default_system_for_date( FY_2024, scotland=true )
        
    no_ct_sys = deepcopy( base_sys )
    no_ct_sys.loctax.ct.abolished = true
    setct!( no_ct_sys, 0.0 )
    
    local_it_sys = deepcopy( no_ct_sys )
    local_it_sys.it.non_savings_rates .+= local_income_tax/100.0

    progressive_ct_sys = deepcopy( base_sys )
    progressive_ct_sys.loctax.ct.relativities = PROGRESSIVE_RELATIVITIES
    progressive_ct_sys.loctax.ct.band_d[code] *= (fairer_bands_band_d_prop)

    ppt_sys = deepcopy(no_ct_sys)
    ppt_sys.loctax.ct.abolished = true        
    ppt_sys.loctax.ppt.abolished = false
    ppt_sys.loctax.ppt.rate = proportional_property_tax/(100.0*WEEKS_PER_YEAR)
    
    revalued_prices_sys = deepcopy( base_sys )
    revalued_prices_sys.loctax.ct.revalue = true
    revalued_prices_sys.loctax.ct.band_d[code] *= revalued_housing_band_d_prop

    revalued_prices_w_prog_bands_sys = deepcopy( base_sys )
    revalued_prices_w_prog_bands_sys.loctax.ct.revalue = true
    revalued_prices_w_prog_bands_sys.loctax.ct.relativities = PROGRESSIVE_RELATIVITIES
    revalued_prices_w_prog_bands_sys.loctax.ct.band_d[code] += revalued_housing_band_d_w_fairer_bands_prop
        
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

function get_base_cost( settings, base_sys :: TaxBenefitSystem ) :: Real
    frames = do_one_run( settings, [base_sys], obs )        
    settings.poverty_line = make_poverty_line( frames.hh[1], settings )
    pc_frames = summarise_frames!(frames, settings)
    base_cost = pc_frames.income_summary[1][1,:net_cost]
    return base_cost
end

function do_equalising_runs( settings )

    # not acually using revenue and total here
    obs = obs = Observable( Progress(settings.uuid,"",0,0,0,0))

    no_ct_sys,
    local_it_sys,
    progressive_ct_sys,
    ppt_sys, 
    revalued_prices_sys,
    revalued_prices_w_prog_bands_sys = make_parameter_set( code )

    
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
for ccode in LA_CODES[1:1]
    base_sys,
    no_ct_sys,
    local_it_sys,
    progressive_ct_sys,
    ppt_sys, 
    revalued_prices_sys,
    revalued_prices_w_prog_bands_sys = make_parameter_set(
        local_income_tax = 4.4/110.45,  # pts increase in all IT bands rough calc based on Aberdeen City
        fairer_bands_band_d_prop = 0.7522830358234829,  # % diff 
        proportional_property_tax = 5.0/0.949219962009270,
        revalued_housing_band_d_prop = 1/9492199620092701,
        revalued_housing_band_d_w_fairer_bands_prop = 1/1160320145358364,
        code = ccode )
    println( "on council $(ccode) : $(WeightingData.LA_NAMES[ccode])")
    settings.ccode = ccode
    FRSHouseholdGetter.restore()
    FRSHouseholdGetter.set_local_weights_and_incomes!( settings; reset=false )
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
    # all_frames[ccode] = frames
end

function add_one!( revtab :: DataFrame, incsum::DataFrame, sys :: Symbol, ccode :: Symbol )
    revtab[revtab.code .== ccode,Symbol("$(sys)_gross")] .= incsum.local_taxes[1]/1_000
    revtab[revtab.code .== ccode,Symbol("$(sys)_rebates")] .= incsum.council_tax_benefit[1]/1_000
    revtab[revtab.code .== ccode,Symbol("$(sys)_net")] .= (incsum.local_taxes[1] - incsum.council_tax_benefit[1])/1_000
end

#=

    "Current System", 
    "CT Incidence",
    "Local Income Tax",
    "Progressive Bands", 
    "Proportional Property Tax",
    "Council Tax With Revalued House Prices and compensating band D cuts", 
    "Council Tax With Revalued House Prices & Fairer Bands" ]

=#
for ccode in LA_CODES[1:1]
    sm = all_summaries[ccode]
    ctincidence = sm.deciles[2][:,3] - sm.deciles[1][:,3]
    add_one!( revtab, sm.income_summary[1], :modelled_ct, ccode )
    add_one!( revtab, sm.income_summary[4], :fairer_bands, ccode )
    add_one!( revtab, sm.income_summary[5], :proportional_property_tax, ccode )
    add_one!( revtab, sm.income_summary[6], :revalued_housing, ccode )
    add_one!( revtab, sm.income_summary[7], :revalued_housing_w_fairer_bands, ccode )
    revtab[revtab.code .== ccode,:local_income_tax] .= 
        (sm.income_summary[3].income_tax[1] - sm.income_summary[1].income_tax[1])./1000
end