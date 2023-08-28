module TheEqualiser
#
# This module automatically adjusts taxes (it and ni, optionally)
# so the net cost of benefit or other changes
# is close to zero.
# 
# TODO needs a lot of work:
# 
# - more options - so basic rate only etc;
# - use passed-in functions to equalise (like op_tax! below);
# - check results are in sensible bounds (e.g. >= 0 < 100 tax rates).
# 
using Roots
using UUIDs
using Observables

using ScottishTaxBenefitModel
using .Definitions
using .Monitor
using .Results
using .Runner
using .RunSettings
using .STBOutput
using .STBParameters
using .LocalLevelCalculations
using .Utils

@enum EqTargets begin 
    eq_it 
    eq_ni 
    eq_it_ni 
    eq_ct_rels 
    eq_ct_band_d 
    eq_ppt_rate 
    eq_ct_bands_proportional 
    eq_ct_bands_progressive 
    eq_wealth_tax 
    eq_corporation_tax 
    eq_all_vat 
    eq_std_vat
end

export EqTargets,
    eq_it,
    eq_ni,
    eq_it_ni, 
    eq_ct_rels, 
    eq_ct_band_d, 
    eq_ppt_rate, 
    eq_ct_bands_proportional, 
    eq_ct_bands_progressive,
    eq_wealth_tax,
    eq_corporation_tax,
    eq_all_vat,
    eq_std_vat

export equalise
#
# Roots only allows 1 parameter, I think, so:
#
mutable struct RunParameters{T<:AbstractFloat}
    params :: TaxBenefitSystem{T}
    settings :: Settings
	base_cost :: T
    target :: EqTargets
    obs    :: Observable
end

# TODO another possible approach is to pass in editing
# functions such as:
function op_tax!( sys :: TaxBenefitSystem{T}, r :: T ) where T <: AbstractFloat
    sys.it.non_savings_rates .+= r
end

function run( x :: T, rparams :: RunParameters{T} ) where T <: AbstractFloat
    # backup
    nsr = deepcopy( rparams.params.it )
    nsi = deepcopy( rparams.params.ni )
    nbandd = deepcopy( rparams.params.loctax.ct.band_d )
    npptrate = rparams.params.loctax.ppt.rate
    hvals = deepcopy(rparams.params.loctax.ct.house_values)
    othvals = deepcopy(rparams.params.othertaxes )
    vat = deepcopy(rparams.params.indirect.vat )

    if rparams.target in [eq_it, eq_it_ni]
        rparams.params.it.non_savings_rates .+= x
    end

    # TODO check sensible it rates
    if rparams.target in [eq_ni, eq_it_ni]
        rparams.params.ni.primary_class_1_rates .+= x
        rparams.params.ni.class_4_rates .+= x
    end
    
    if rparams.target == eq_ct_band_d
        for k in keys( rparams.params.loctax.ct.band_d )
            rparams.params.loctax.ct.band_d[k] += x
        end
        # println( "set band ds to $(rparams.params.loctax.ct.band_d)")
    end

    if rparams.target == eq_ppt_rate
        rparams.params.loctax.ppt.rate += x
    end

    if rparams.target in [eq_ct_bands_proportional, eq_ct_bands_progressive] 
        progressive = (rparams.target == eq_ct_bands_progressive)
        change_ct_valuations!(rparams.params.loctax.ct.house_values, x, progressive )
    end

    if rparams.target == eq_wealth_tax
        rparams.params.othertaxes.wealth_tax += x
    end
    if rparams.target == eq_corporation_tax
        rparams.params.othertaxes.implicit_wage_tax += x
    end

    if rparams.target == eq_all_vat
        rparams.params.indirect.vat.standard_rate += x
        rparams.params.indirect.vat.reduced_rate += x
        # FIXME wild guess
        rparams.params.indirect.vat.assumed_exempt_rate += x*0.5
    end

    if rparams.target == eq_std_vat
        rparams.params.indirect.vat.standard_rate += x
        # FIXME wild guess at % of vat in exempt goods
        rparams.params.indirect.vat.assumed_exempt_rate += x*0.4
    end

    # TODO check sensible ni rates    
    results = do_one_run( rparams.settings, [rparams.params], rparams.obs )
    # restore
    rparams.params.it = nsr
    rparams.params.ni = nsi
    rparams.params.loctax.ct.band_d = nbandd
    rparams.params.loctax.ppt.rate = npptrate
    rparams.params.loctax.ct.house_values = hvals
    rparams.params.othertaxes = othvals 
    rparams.params.indirect.vat = vat
    summary = summarise_frames!(results, rparams.settings)
    nc = summary.income_summary[1][1,:net_cost]
    return round( nc - rparams.base_cost, digits=0 )
end

"""
Adjust the thing in `target` so that the net cost of the changes in `sys`
is close to `base_cost`
"""
function equalise( 
    target :: EqTargets,
    sys :: TaxBenefitSystem{T}, 
    settings :: Settings,
    base_cost :: T,
    observer :: Observable ) :: T where T<:AbstractFloat  
    zerorun = ZeroProblem( run, 0.0 ) # fixme guess at 0.0 ?
    rparams = RunParameters( sys, settings, base_cost, target, observer )
    incch = solve( zerorun, rparams )
    #
    # TODO test incch is sensible 
    return incch
end

end # module