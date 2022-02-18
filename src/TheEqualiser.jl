module TheEqualiser
#
# this module automatically adjusts taxes
# so the net cost of benefit or other changes
# is zero
# TODO needs a lot of work:
# - more options
# - check results are in bounds
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

# todo another poss approach ... 
function op_tax!( sys :: TaxBenefitSystem{T}, r :: T ) where T <: Number
    things.params.it.non_savings_rates .+= x
end

function run( x :: Number, things :: RunParameters )
    nsr = deepcopy( things.params.it )
    nsi = deepcopy( things.params.ni )
  
    if things.target in [eq_it, eq_it_ni]
        things.params.it.non_savings_rates .+= x
    end
    if things.target in [eq_ni, eq_it_ni]
        things.params.ni.primary_class_1_rates .+= x
        things.params.ni.class_4_rates .+= x
    end

    # check sensible it rates
    results = do_one_run(things.settings, [things.params], things.obs )
    # restore
    things.params.it = nsr
	things.params.ni = nsi
	summary = summarise_frames(results,settings)
	nc = summary.income_summary[1][1,:net_cost]
	return round( nc - things.base_cost, digits=0 )
end

function equalise( 
    target :: EqTargets,
    sys :: TaxBenefitSystem{T}, 
    settings :: Settings,
    base_cost :: T,
    observer :: Observable ) :: T where T<:Number
    
    zerorun = ZeroProblem( run, 0.0 ) # fixme guess at 0.0 ?

    things = RunParameters( sys, settings, base_cost, target, observer )

    incch = solve( zerorun, things )
    #
    # test incch in sensible 
    return incch
end

end # module