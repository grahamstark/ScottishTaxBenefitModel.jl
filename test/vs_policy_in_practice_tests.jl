#
# As of September 19 2021
#

using Test
using Dates
using ScottishTaxBenefitModel
using .ModelHousehold
using .STBParameters
using .STBIncomes
using .Definitions

sys2 = load_file( "../params/sys_2021.jl" )

@testset "Single Person, No Housing Costs 19/Sep/2021 values (without £20)" begin
    
    dob = Date( 1970, 1, 1 )
    # basic - no tax credits, no ESA/JSA, single person

end