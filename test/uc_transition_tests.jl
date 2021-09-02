using Test
using ScottishTaxBenefitModel
using .Randoms
using .UCTransition
using .ModelHousehold
using .RunSettings


## FIXME don't need both
lmt = LegacyMeansTestedBenefitSystem{Float64}()
sys = get_system( scotland=true )

settings = Settings()
settings.means_tested_routing = modelled_phase_in
rc = @timed begin
    num_households,total_num_people,nhh2 = FRSHouseholdGetter.initialise( DEFAULT_SETTINGS )
end
println( "num_households=$num_households, num_people=$(total_num_people)")
@time for hhno in 1:num_households
    hh = FRSHouseholdGetter.get_household( hhno )
    r += 1
    intermed = make_intermediate( 
        hh, 
        sys.hours_limits, 
        sys.age_limits, 
        sys.child_limits )
    bus = get_benefit_units( hh )
    for buno in eachindex( bus )
        route = route_to_uc_or_legacy( 
            settings, 
            bus[buno], 
            intermed.buint[buno] )
    end
end