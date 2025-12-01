module SFCBehavioural

# I changed some of the code, which now creates two tables. One by TIE band.
# It creates the function, but doesn't call it. So it's a choice in each script.
# Haven't progressed on testing yet.
#  sit * weights doesn't match summary results exactly - small differences!

using DataFrames

using ScottishTaxBenefitModel
using .ModelHousehold #unsure what actually goes here
using .Results
using .STBParameters

export calc_behavioural_response, BehaviouralResult

# =============================================================================
# Constants - SFC methodology parameters
# to be moved to param?
# =============================================================================

const TIE_RATES = [0.015, 0.10, 0.20, 0.35, 0.55, 0.75]
const PERSONAL_ALLOWANCE = 12_570.0

const TIE_EDGES = [
    0.0,
    50_270.0 - PERSONAL_ALLOWANCE,
    80_000.0 - PERSONAL_ALLOWANCE,
    150_000.0,
    300_000.0,
    500_000.0,
    Inf
]
const TIE_BAND_LABELS = [
    "£0 - £37,700",
    "£37,700 - £67,430",
    "£67,430 - £150,000",
    "£150,000 - £300,000",
    "£300,000 - £500,000",
    "£500,000+"
]

const AETR_RATES = [0.00, 0.06, 0.06, 0.25, 0.25, 0.25]
const AETR_EDGES = copy(TIE_EDGES)

# =============================================================================
# Result structures
# =============================================================================

struct BehaviouralResult
    band_label::String
    tie_rate::Union{Float64, Missing}
    aetr_rate::Union{Float64, Missing}
    n_taxpayers::Int
    static_baseline::Float64
    static_reform::Float64
    static_change::Float64
    change_intensive::Float64
    change_extensive::Float64
    total_behavioural::Float64
    sfc_change::Float64
    behavioural_offset_pct::Float64
end

# =============================================================================
# Helper functions
# =============================================================================

function lookup_band_index(x::Real, edges::AbstractVector)::Int
    for i in 1:(length(edges)-1)
        if edges[i] <= x < edges[i+1]
            return i
        end
    end
    return length(edges) - 1
end

function lookup_band_value(x::Real, edges::AbstractVector, values::AbstractVector)
    return values[lookup_band_index(x, edges)]
end

function get_rate(band, rates)
    band > 0 ? rates[band] : 0.0
end

function get_threshold_below(x::Real, thresholds::AbstractVector)::Float64
    for i in length(thresholds):-1:1
        if x > thresholds[i]
            return thresholds[i]
        end
    end
    return 0.0
end

# =============================================================================
# Main calculation function
# =============================================================================

"""
    calc_behavioural_response(results, sys_baseline, sys_reform) 

Calculate aggregate income tax revenue change due to behavioural responses
using the SFC TIE/AETR methodology.

Only call this function when comparing two different tax systems - use the 
@assert to verify policy has changed before calling.

# Arguments
- `results`: Microsimulation results containing `.income[1]` (baseline) and `.income[2]` (reform)
- `sys_baseline`: Baseline tax system parameters
- `sys_reform`: Reform tax system parameters

# Returns
Vector{BehaviouralResult} - rows for each TIE band plus a TOTAL row

# To call within a script (after the model has run) use for example:
aggregate, by_band = calc_behavioural_response(results, sys1, sys2)
... and then display using
Data.Table( BehaviouralResult )

"""
function calc_behavioural_response(
    df_baseline::DataFrame,
    df_reform :: DataFrame,    
    sys_baseline :: TaxBenefitSystem,
    sys_reform   :: TaxBenefitSystem )::Vector{BehaviouralResult}
    #= You don't need this assertion. 
    @assert sys_baseline.it.non_savings_rates != sys_reform.it.non_savings_rates ||
    sys_baseline.it.non_savings_thresholds != sys_reform.it.non_savings_thresholds "No IT policy change"
    =#

    n_obs = length(df_baseline.weight)
    
    # Convert to annual figures
    taxable_baseline = df_baseline.it_non_savings_taxable .* 52
    taxable_reform = df_reform.it_non_savings_taxable .* 52
    tax_baseline = df_baseline.scottish_income_tax .* 52
    tax_reform = df_reform.scottish_income_tax .* 52
    weights = df_baseline.weight
    
    # Get marginal income tax rates
  	mtr_baseline = get_rate.(df_baseline.it_non_savings_band, Ref(sys_baseline.it.non_savings_rates))
    mtr_reform = get_rate.(df_reform.it_non_savings_band, Ref(sys_reform.it.non_savings_rates))
	ni_class_1_baseline = get_rate.(
		df_baseline.ni_class_1_primary_band, Ref(sys_baseline.ni.primary_class_1_rates))
    ni_class_1_reform = get_rate.(
		df_reform.ni_class_1_primary_band, Ref(sys_reform.ni.primary_class_1_rates))
	ni_class_4_baseline = get_rate.(
		df_baseline.ni_class_4_band, Ref(sys_baseline.ni.class_4_rates))
	ni_class_4_reform = get_rate.(
		df_reform.ni_class_4_band, Ref(sys_reform.ni.class_4_rates))
    ni_baseline = max.(ni_class_1_baseline, ni_class_4_baseline) # which to apply if someone is earning wages and se imcome? Here higher of the two is applied.
	ni_reform = max.(ni_class_1_reform, ni_class_4_reform)

    # Marginal retention rates: MRR = 1 - MTR - NI
    mrr_baseline = @. 1.0 - mtr_baseline - ni_baseline
    mrr_reform = @. 1.0 - mtr_reform - ni_reform
    
    # Percentage change in MRR (avoiding div by zero)
    mrr_pct_change = @. ifelse(mrr_baseline == 0.0, 0.0, mrr_reform / mrr_baseline - 1.0)
    
    # TIE and AETR lookup by baseline income
    tie = [lookup_band_value(x, TIE_EDGES, TIE_RATES) for x in taxable_baseline]
    aetr = [lookup_band_value(x, AETR_EDGES, AETR_RATES) for x in taxable_baseline]
    band_indices = [lookup_band_index(x, TIE_EDGES) for x in taxable_baseline]
    
    # === INTENSIVE MARGIN (METR/TIE effect) ===
    taxable_change = @. tie * mrr_pct_change * taxable_baseline
    intensive_change = @. taxable_change * mtr_reform
    
    # === EXTENSIVE MARGIN (AETR effect) ===
    total_tax_change = tax_reform .- tax_baseline
    
    # Decompose into marginal and non-marginal components
    thres_baseline = [get_threshold_below(x, sys_baseline.it.non_savings_thresholds) 
                      for x in taxable_baseline]
    thres_reform = [get_threshold_below(x, sys_reform.it.non_savings_thresholds) 
                    for x in taxable_baseline]
    
    relevant_threshold = max.(thres_baseline, thres_reform)
    marginal_component = @. (mtr_reform - mtr_baseline) * max(0.0, taxable_baseline - relevant_threshold)
    non_marginal_component = total_tax_change .- marginal_component
    
    extensive_change = @. -non_marginal_component * aetr
    
    # === BUILD RESULTS TABLE ===
    combined = BehaviouralResult[]
    
     # Running totals for the TOTAL row
    total_n = 0
    total_baseline = 0.0
    total_reform = 0.0
    total_static = 0.0
    total_intensive = 0.0
    total_extensive = 0.0
    total_behavioural = 0.0
    total_sfc = 0.0

    # Each TIE band
    for band_idx in 1:length(TIE_RATES)
        mask = band_indices .== band_idx
        
        if !any(mask)
            push!(combined, BehaviouralResult(
                TIE_BAND_LABELS[band_idx],
                TIE_RATES[band_idx],
                AETR_RATES[band_idx],
                0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
            ))
            continue
        end

        w = weights[mask]
        band_total_baseline = sum(tax_baseline[mask] .* w)
        band_total_reform = sum(tax_reform[mask] .* w)
        band_static_change = sum(tax_reform[mask] .* w) - sum(tax_baseline[mask] .* w)
        band_intensive = sum(intensive_change[mask] .* w)
        band_extensive = sum(extensive_change[mask] .* w)
        band_total_behav = band_intensive + band_extensive
        band_sfc_change = band_static_change + band_total_behav
        band_n = round(Int, sum(w))
        
        band_offset_pct = band_static_change != 0.0 ? 
            (-band_total_behav / band_static_change) * 100.0 : 0.0
        
        push!(combined, BehaviouralResult(
            TIE_BAND_LABELS[band_idx],
            TIE_RATES[band_idx],
            AETR_RATES[band_idx],
            band_n,
            band_total_baseline,
            band_total_reform,
            band_static_change,
            band_intensive,
            band_extensive,
            band_total_behav,
            band_sfc_change,
            band_offset_pct
        ))
        
        # Accumulate totals
        total_n += band_n
        total_baseline += band_total_baseline
        total_reform += band_total_reform
        total_static += band_static_change
        total_intensive += band_intensive
        total_extensive += band_extensive
        total_behavioural += band_total_behav
        total_sfc += band_sfc_change
    end
    
    # Add TOTAL row
    total_offset_pct = total_static != 0.0 ? 
        (-total_behavioural / total_static) * 100.0 : 0.0
    
    push!(combined, BehaviouralResult(
        "TOTAL",
        missing,
        missing,
        total_n,
        total_baseline,
        total_reform,
        total_static,
        total_intensive,
        total_extensive,
        total_behavioural,
        total_sfc,
        total_offset_pct
    ))
    
    return combined
end

end # module SFCBehavioural