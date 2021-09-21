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
using .GeneralTaxComponents
using .SingleHouseholdCalculations
using .RunSettings

sys21_22 = load_file( "../params/sys_2021_22.jl" )
load_file!( sys21_22, "../params/sys_2021-uplift-removed.jl")
settings = DEFAULT_SETTINGS
@testset "Single Person, No Housing Costs 19/Sep/2021 values (without £20)" begin
    
    dob = Date( 1970, 1, 1 )
    # basic - no tax credits, no ESA/JSA, single person
    # check we've loaded correctly
    @test sys21_22.uc.age_25_and_over ≈ 324.84/WEEKS_PER_MONTH 
    hh = make_hh(
        adults = 1,
        children = 0,
        earnings = 0,
        rent = 0,
        rooms = 0,
        age = 50,
        tenure = Private_Rented_Furnished )
    
    head = get_head( hh )
    empty!( head.income )
    unemploy!( head )
    settings.means_tested_routing = uc_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )
    @test hres_scot.bhc_net_income ≈ 74.96
    println( inctostr(  hres_scot.bus[1].pers[head.pid].income ))
    @test hres_scot.bus[1].pers[head.pid].income[UNIVERSAL_CREDIT] ≈ 74.96
    

    settings.means_tested_routing = lmt_full 
    hres_scot = do_one_calc( hh, sys21_22, settings )

end