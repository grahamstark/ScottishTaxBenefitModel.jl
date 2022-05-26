using Test

using DataFrames

using ScottishTaxBenefitModel
using .Randoms
using .UCTransition: route_to_uc_or_legacy, route_to_uc_or_legacy!
using .ModelHousehold
using .RunSettings
using .Results
using .Intermediate
using .STBIncomes
using .ExampleHelpers

sys = get_system( scotland=true )
settings = Settings()
settings.means_tested_routing = modelled_phase_in

@testset "Transition Tests on Example HHlds" begin
    examples = get_all_examples()
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
            num_households,total_num_people,nhh2 = FRSHouseholdGetter.initialise( Settings() )
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
            if on_mt_benefits( hh ) && ! (im.someone_pension_age) 
                # on actual data !! FIXME the HoC thing is actually Benefit Units
                route = route_to_uc_or_legacy( 
                    settings, 
                    bus[1], 
                    im )
                col = route == uc_bens ? :uc : :legacy
                n = 1
                if im.num_job_seekers > 0
                    row = "Job Seekers"
                    n = im.num_adults
                elseif im.limited_capacity_for_work
                    row = "Disabled"
                elseif im.num_children > 0
                    row = "W/Children"
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
        df[:, :sum] = df.uc.+df.legacy
        df[:, :pctuc] .= 100.0 .* df.uc./(df.uc.+df.legacy)
        print( df )
    end

end 

@testset "Single HH Test - UC Route checks" begin
    #
    # chasing a bug when using UC route but contrib benefits
    # are being set to zero
    # 
    examples = get_all_examples()
    hh = deepcopy( examples[cpl_w_2_children_hh])
    hhres = init_household_result( hh )
    intermed = make_intermediate( 
        hh, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits
    )
    settings.means_tested_routing = uc_full
    bus = get_benefit_units( hh )
    bres = hhres.bus[1]
    tozero!( bres, ALL_INCOMES ...)
    head = get_head( bus[1])
    hpid = head.pid
    for i in BENEFITS
        bres.pers[hpid].income[i] = 1.0
    end

    route_to_uc_or_legacy!( hhres, settings, hh, intermed )
    println( inctostr( bres.pers[hpid].income ))
    for i in LEGACY_MTBS
        println( "on $(iname(i))" )
        @test bres.pers[hpid].income[i] == 0
    end
    for i in [CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE, CONTRIB_JOBSEEKERS_ALLOWANCE]
        println( "on $(iname(i)) testing for zero " )
        @test bres.pers[hpid].income[i] == 1.0 
    end
end
