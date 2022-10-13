using Test
using DataFrames
using PrettyTables

using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .ModelHousehold
using .BenefitGenerosity: initialise, to_set, change_status, adjust_disability_eligibility!
using .NonMeansTestedBenefits: calc_pip, calc_dla, calc_attendance_allowance
using .Definitions
using .RunSettings
using .STBIncomes

using .ExampleHelpers

settings = Settings()
ruksys = get_system( year=2019, scotland = false )
scosys = get_system( year=2019, scotland = true )

FRSHouseholdGetter.initialise( settings )

@testset "Loading Tests" begin
    
    # println( FRSHouseholdGetter.MODEL_HOUSEHOLDS.pers_map )
    ks = sort( collect( keys( FRSHouseholdGetter.MODEL_HOUSEHOLDS.pers_map )), lt=ModelHousehold.isless )
    for k in ks 
        if k.data_year == 2015
            print( k )
            if k.id == 120150847501 
                print("!!!!")
            end
            println()
        end
    end
    BenefitGenerosity.initialise( "$(MODEL_DATA_DIR)/disability/")

    for ben in [ATTENDANCE_ALLOWANCE, PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
        PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY, DLA_SELF_CARE]
        for peeps in [-100_000, -10_000, -1000, 0, 1000, 10_000, 100_000 ]
            s = to_set( ben, peeps )
            println( "set for $peeps $ben = $(s)")
        end
    end
end

"""
Quicky thing to make a little set of targets for the testset below
"""
function makeset( r :: UnitRange ) :: Set
    s = Set{OneIndex}()
    for i in r 
        push!( s, OneIndex( makePID(i),2018))
    end
    s
end

@enum Benvals noben lowben medben highben

@testset "Status Change Thingy" begin
    
    s = makeset(1:20)
    println( "s=$s")

    # in set, +ive => set to random low:high 
    @test change_status(
        candidates = s,
        pid = makePID(1),
        change = 1,
        choices = [lowben, medben, highben],
        current_value = noben,
        disqual_value = noben ) in [lowben,medben,highben]
    # not in set - unchanged
    @test change_status(
        candidates = s,
        pid = makePID(100),
        change = 1,
        choices = [lowben, medben, highben],
        current_value = lowben,
        disqual_value = noben ) == lowben
    # in set - change -ive; disqual
    @test change_status(
        candidates = s,
        pid = makePID(10),
        change = -1,
        choices = [lowben, medben, highben],
        current_value = lowben,
        disqual_value = noben ) == noben
    # out of set - no change
    @test change_status(
        candidates = s,
        pid = makePID(100),
        change = -1,
        choices = [lowben, medben, highben],
        current_value = lowben,
        disqual_value = noben ) == lowben
    # no extras - unchanged even if in set
    @test change_status(
        candidates = s,
        pid = makePID(10),
        change = 0,
        choices = [lowben, medben, highben],
        current_value = lowben,
        disqual_value = noben ) == lowben            
end


@testset "Add/Subtract from PIP aggregate tests" begin
    

    rc = @timed begin
        num_households,total_num_people,nhh2 = FRSHouseholdGetter.initialise( Settings() )
    end
    println( "num_households=$num_households, num_people=$(total_num_people)")
    BenefitGenerosity.initialise( MODEL_DATA_DIR*"/disability/" ) 
    
    out = DataFrame(
        which = ["RUK","-50,000","0","50,000"],
        pip_d = zeros(4),
        pip_m = zeros(4),
        dla_d = zeros(4),
        dla_m = zeros(4),
        aa    = zeros(4)
    )
    changes = [0,-50_000,0,50_000]
    for sysno in 1:4
        outr = out[sysno,:]
        if sysno == 1
            sys = ruksys
        else
            sys = scosys
            sys.nmt_bens.pip.extra_people = changes[sysno]
            sys.nmt_bens.dla.extra_people = changes[sysno]
            sys.nmt_bens.attendance_allowance.extra_people = changes[sysno]
            
            adjust_disability_eligibility!( sys.nmt_bens )
            adjust_disability_eligibility!( sys.nmt_bens )
        end
        r = 0      
        @time for hhno in 1:num_households
            hh = FRSHouseholdGetter.get_household( hhno )
            r += 1
            for (pid,pers) in hh.people
                (pip_d,pip_m) = calc_pip( pers, sys.nmt_bens.pip )
                if pip_d > 0 
                    outr.pip_d += hh.weight
                end
                if pip_m > 0
                    outr.pip_m += hh.weight
                end
                (dla_d,dla_m) = calc_dla( pers, sys.nmt_bens.dla )
                if dla_d > 0 
                    outr.dla_d += hh.weight
                end
                if dla_m > 0
                    outr.dla_m += hh.weight
                end
                aa = calc_attendance_allowance( pers, sys.nmt_bens.attendance_allowance )
                if aa > 0 
                    outr.aa += hh.weight
                end
            end
        end
        # should be ~50k bigger/smaller for scottish system
    end
    pretty_table( out; formatters = ft_printf("%10.0f", [2,3,4,5,6]))
    dout = 
    pretty_table( out; formatters = ft_printf("%10.0f", [2,3,4,5,6]))
end