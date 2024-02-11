using Test
using ScottishTaxBenefitModel
using ScottishTaxBenefitModel
using .HistoricBenefits
using .Definitions
using .Utils
using .Randoms
using .ExampleHelpers
using .RunSettings: Settings

## NOTE this test has the 2019 OBR data and 2019Q4 as a target jammed on - will need
## changing with update versions

@testset "historic tests" begin
 
    be_99 = 66.75
    pe_99 = 66.75
    @test benefit_ratio(
        1999,
        be_99,
        bereavement_allowance_or_widowed_parents_allowance_or_bereavement
    ) ≈ 1

    @test benefit_ratio(
        2020,
        be_99,
        bereavement_allowance_or_widowed_parents_allowance_or_bereavement
    ) ≈ be_99/121.95

    @test benefit_ratio(
        1999,
        pe_99,
        state_pension
    ) ≈ 1

 
    d = Date( 2019, 1, 1)
    @test DLA_RECEIPTS[nearest( d, DLA_RECEIPTS ),:Scotland] ≈ 182_154  
    @test PIP_RECEIPTS[nearest( d, PIP_RECEIPTS ),:Scotland] ≈ 220_043

    @test should_switch_dla_to_pip( "000000000000", 2016, 1 )
    @test ! should_switch_dla_to_pip("99999999999", 2016, 1 )



    names = ExampleHouseholdGetter.initialise( Settings() )
    scot = ExampleHouseholdGetter.get_household( "mel_c2_scot" ) # scots are a married couple
    head = scot.people[SCOT_HEAD]
    spouse = scot.people[SCOT_SPOUSE]

    disable_seriously!( head ) # don't really need this ... 
    head.onerand = String(fill( '9', 100 )) # 0.99999.. switch will never be made
    @test randchunk( head.onerand, 3, 3 ) ≈ 0.999
    head.dla_self_care_type = high
    head.dla_mobility_type = high
    switch_dla_to_pip!( head, 2016, 3 )
    @test head.dla_self_care_type == high
    @test head.dla_mobility_type == high
    @test head.pip_mobility_type == no_pip
    @test head.pip_daily_living_type == no_pip


    head.onerand = String(fill( '0', 100 )) # switch always made
    @test randchunk( head.onerand, 3, 3 ) == 0
    head.dla_self_care_type = high
    head.dla_mobility_type = high
    head.pip_mobility_type = no_pip
    head.pip_daily_living_type = no_pip
    switch_dla_to_pip!( head, 2016, 3 )
    @test head.dla_self_care_type == missing_lmh
    @test head.dla_mobility_type == missing_lmh
    @test head.pip_mobility_type == enhanced_pip
    @test head.pip_daily_living_type == enhanced_pip

end # testset
    
@testset "Run on actual Data" begin
    # just see if switcher roughly works on actual data
    nhhs,npeople = init_data( reset=true )
    nyears = 6
    pips_dlas = DataFrame(
        year = zeros( Int, nyears ),
        orig_dla_self_care = zeros( Int, nyears ),
        new_dla_self_care = zeros( Int, nyears ),
        orig_dla_mobility = zeros( Int, nyears ),
        new_dla_mobility = zeros( Int, nyears ),
        orig_pip_daily_living = zeros( Int, nyears ),
        new_pip_daily_living = zeros( Int, nyears ),
        orig_pip_mobility = zeros( Int, nyears ),
        new_pip_mobility = zeros( Int, nyears ),
    )
    for hno in 1:nhhs
        hh = get_household(hno)
        year = hh.interview_year 
        month = hh.interview_month
        yp = year - 2014
        println( "on year $year month $month yp=$yp hno=$hno")
        for (pid,pers) in hh.people # just unweighted counts
            dr = pips_dlas[yp,:]
            pips_dlas[yp,:year] = year
            if pers.dla_self_care_type != missing_lmh
                dr.orig_dla_self_care += 1
            end
            if pers.dla_mobility_type != missing_lmh
                dr.orig_dla_mobility += 1
            end
            if pers.pip_daily_living_type != no_pip
                dr.orig_pip_daily_living += 1
            end
            if pers.pip_mobility_type != no_pip
                dr.orig_pip_mobility += 1
            end
            println( pers.onerand )
            switch_dla_to_pip!( pers, year, month )
            # ss = should_switch_dla_to_pip( pers.onerand, year, month )
            # println( "should switch $ss ")
            if pers.dla_self_care_type != missing_lmh
                dr.new_dla_self_care += 1
            end
            if pers.dla_mobility_type != missing_lmh
                dr.new_dla_mobility += 1
            end
            if pers.pip_daily_living_type != no_pip
                dr.new_pip_daily_living += 1
            end
            if pers.pip_mobility_type != no_pip
                dr.new_pip_mobility += 1
            end

        end # people
    end # hhs
    println( pips_dlas )
end # testset