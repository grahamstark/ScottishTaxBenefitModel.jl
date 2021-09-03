using Test

using DataFrames

using ScottishTaxBenefitModel
using .Randoms
using .UCTransition: route_to_uc_or_legacy
using .ModelHousehold
using .RunSettings
using .Intermediate

sys = get_system( scotland=true )
settings = Settings()
settings.means_tested_routing = modelled_phase_in

@testset "Transition Tests on Example HHlds" begin
    examples = get_ss_examples()
    for (hht,hh) in examples 
        println( "on hhld '$hht'")
        lhh = deepcopy( hh )
        bus = get_benefit_units( lhh )
        nbus = size(bus)[1]
        for bno in eachindex(bus)
            @test typeof(bus[bno]) <: BenefitUnit
            intermed = make_intermediate( 
                bno,
                bus[bno],  
                sys.lmt.hours_limits,
                sys.age_limits,
                sys.child_limits,
                nbus )
            route = route_to_uc_or_legacy(
                settings,
                bus[bno],
                intermed )
        end
    end
end # example tests

@testset "Live Data Transitions" begin

    if IS_LOCAL
        rc = @timed begin
            num_households,total_num_people,nhh2 = FRSHouseholdGetter.initialise( DEFAULT_SETTINGS )
        end
        r = 0
        df = DataFrame( typ=["Job Seekers", "Disabled", "W/Children", "W/Housing", "Other", "Total"], legacy=zeros(6), uc=zeros(6))
        println( "num_households=$num_households, num_people=$(total_num_people)")
        @time for hhno in 1:num_households
            hh = FRSHouseholdGetter.get_household( hhno )
            bus = get_benefit_units(hh)
            r += 1
            intermed = make_intermediate( 
                hh, 
                sys.hours_limits, 
                sys.age_limits, 
                sys.child_limits )
            im = intermed.hhint
            if on_mt_benefits( hh ) && ! (im.someone_pension_age) # on actual data
                route = route_to_uc_or_legacy( 
                    settings, 
                    bus[1], 
                    im )
                col = route == uc_bens ? :uc : :legacy
                n = 1
                if im.num_job_seekers > 0
                    row = "Job Seekers"
                    n = im.num_adults
                elseif im.num_children > 0
                    row = "W/Children"
                elseif im.limited_capacity_for_work
                    row = "Disabled"
                elseif im.benefit_unit_number == 1
                    row = "W/Housing"
                else
                    row = "Other"
                end
                k = ( df.typ .== row )
                println( "adding |$row| |$col| weight $(hh.weight)" )
                # println( col )
                df[ k, col ] .+= hh.weight*n
                df[ (df.typ.=="Total"), col ] .+= hh.weight
            end
        end
        df[:, :pctuc] .= 100.0 .* df.uc./(df.uc.+df.legacy)
        print( df )
    end

end 