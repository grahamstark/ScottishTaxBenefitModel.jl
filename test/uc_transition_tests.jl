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

sys = get_system( year=2019, scotland=true )
settings = Settings()
settings.means_tested_routing = modelled_phase_in
settings.to_y = 2025

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
            hres = init_household_result( hh )
            r += 1
            intermed = make_intermediate( 
                DEFAULT_NUM_TYPE,
                settings,                
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
                    hres.bus[1] )
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
        DEFAULT_NUM_TYPE,
        settings,                
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

@testset "Transition Tests on Example HHlds" begin
    examples = get_all_examples()
    sys1 = get_system(year=2024, scotland=true)
    sys2 = get_system(year=2024, scotland=true)
    for q in 1:2
        for (hht,hh) in examples 
            settings.to_q = q
            println( "on hhld '$hht'")
            lhh = deepcopy( hh )
            hres = init_household_result( lhh )
            bus = get_benefit_units( lhh )
            nbus = size(bus)[1]
            for bno in eachindex(bus)
                @test typeof(bus[bno]) <: BenefitUnit
                hres.bus[bno].income[CHILD_TAX_CREDIT] = 1.0
                route = route_to_uc_or_legacy(
                    settings,
                    bus[bno],
                    hres.bus[bno])
                if q == 2
                    @assert route == uc_bens
                end
                route = route_to_uc_or_legacy(
                    settings,
                    bus[bno],
                    hres.bus[bno])
                hres.bus[bno].income[CHILD_TAX_CREDIT] = 0
                hres.bus[bno].income[UNIVERSAL_CREDIT] = 1
                @assert route == uc_bens

            end # bus
        end # hhlds
    end # qs 1::2
end # example tests

