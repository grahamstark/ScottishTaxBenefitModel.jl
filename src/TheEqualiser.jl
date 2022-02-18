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
using .Utils

@enum EqTargets eq_it eq_ni eq_it_ni
export EqTargets,eq_it,eq_ni,eq_it_ni
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
function op_tax!( sys :: TaxBenefitSystem{T}, r :: T ) where T <: Number
    sys.it.non_savings_rates .+= r
end

function run( x :: Number, rparams :: RunParameters )
    nsr = deepcopy( rparams.params.it )
    nsi = deepcopy( rparams.params.ni )
    if rparams.target in [eq_it, eq_it_ni]
        rparams.params.it.non_savings_rates .+= x
    end
    # TODO check sensible it rates
    if rparams.target in [eq_ni, eq_it_ni]
        rparams.params.ni.primary_class_1_rates .+= x
        rparams.params.ni.class_4_rates .+= x
    end
    # TODO check sensible ni rates    
    results = do_one_run(rparams.settings, [rparams.params], rparams.obs )
    # restore
    rparams.params.it = nsr
    rparams.params.ni = nsi
    summary = summarise_frames(results, rparams.settings)
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
    observer :: Observable ) :: T where T<:Number  
    zerorun = ZeroProblem( run, 0.0 ) # fixme guess at 0.0 ?
    rparams = RunParameters( sys, settings, base_cost, target, observer )
    incch = solve( zerorun, rparams )
    #
    # TODO test incch is sensible 
    return incch
end

end # module