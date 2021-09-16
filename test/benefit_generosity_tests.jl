using Test

using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .ModelHousehold
using .BenefitGenerosity: initialise, to_set, change_status, adjust_disability_eligibility!
using .NonMeansTestedBenefits: calc_pip
using .Definitions
using .RunSettings
using .STBIncomes

settings = Settings()
ruksys = get_system( scotland = false )
scosys = get_system( scotland = true )

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
        num_households,total_num_people,nhh2 = FRSHouseholdGetter.initialise( DEFAULT_SETTINGS )
    end
    println( "num_households=$num_households, num_people=$(total_num_people)")
    BenefitGenerosity.initialise( MODEL_DATA_DIR*"/disability/" ) 
    for gen in [-50_000,0,50_000]
        scosys.nmt_bens.pip.extra_people = gen
        adjust_disability_eligibility!( ruksys.nmt_bens )
        adjust_disability_eligibility!( scosys.nmt_bens )
        pip_m_ruk = 0.0
        pip_d_ruk = 0.0
        pip_d_sco = 0.0
        pip_m_sco = 0.0
        r = 0      
        @time for hhno in 1:num_households
            hh = FRSHouseholdGetter.get_household( hhno )
            r += 1
            for (pid,pers) in hh.people
                (pdl_uk,pmob_uk) = calc_pip( pers, ruksys.nmt_bens.pip )
                if pdl_uk > 0 
                    pip_d_ruk += hh.weight
                end
                if pmob_uk > 0 
                    pip_m_ruk += hh.weight
                end
                (pdl_sco,pmob_sco) = calc_pip( pers, scosys.nmt_bens.pip )
                if pdl_sco > 0 
                    pip_d_sco += hh.weight
                end
                if pmob_sco > 0 
                    pip_m_sco += hh.weight
                end
            end
        end
        # should be ~50k bigger/smaller for scottish system
        println( "pip_d_ruk (total PIP daily living in Scotland, RUK system )= $pip_d_ruk  ")
        println( "pip_m_ruk (total PIP mob in Scotland, RUK system )= $pip_m_ruk  ")
        println( "pip_d_sco (total PIP daily living in Scotland, SCO System $gen extra )= $pip_d_sco  ")
        println( "pip_m_sco (total PIP mob in Scotland, SCO System $gen extra )= $pip_m_sco  ")
    end
end