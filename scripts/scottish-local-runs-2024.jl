using ScottishTaxBenefitModel

using .Definitions
using .FRSHouseholdGetter
using .LocalLevelCalculations
using .LocalTaxRunner
using .RunSettings
using .STBParameters
using .WeightingData

using CSV
using DataFrames
using Format
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
        modelled_ct=zeros(n), 
        modelled_ctb=zeros(n), 
        net_modelled=zeros(n),
        local_income_tax = zeros(n),
        fairer_bands_band_d = zeros(n),
        proportional_property_tax = zeros(n),
        revalued_housing_band_d = zeros(n),
        revalued_housing_band_d_w_fairer_bands = zeros(n))
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

    base_sys = get_system(year=2024)

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


function get_base_cost( base_sys :: TaxBenefitSystem ) :: Real
    settings = get_sett()
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
settings.weighting_strategy = use_precomputed_weights
FRSHouseholdGetter.initialise( settings; reset=true )
FRSHouseholdGetter.backup()

for ccode in LA_CODES

    revtab = revenues_table()
    println( "on council $(ccode) : $(WeightingData.LA_NAMES[ccode])")
    settings.ccode = ccode
    FRSHouseholdGetter.restore()
    FRSHouseholdGetter.set_local_weights_and_incomes!( settings; reset=false )

end
        base_sys,
        no_ct_sys,
        local_it_sys,
        progressive_ct_sys,
        ppt_sys, 
        revalued_prices_sys,
        revalued_prices_w_prog_bands_sys = 


