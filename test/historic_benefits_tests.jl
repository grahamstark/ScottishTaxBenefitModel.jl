using Test
using ScottishTaxBenefitModel
using ScottishTaxBenefitModel
using .HistoricBenefits
using .Definitions
using .Utils
using .Randoms
using .ExampleHelpers
using .RunSettings: Settings
using .FRSHouseholdGetter: get_interview_years

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

 
    #= FIXME presently unused transition code 
    d = Date( 2019, 1, 1)
    @test DLA_RECEIPTS[nearest( d, DLA_RECEIPTS ),:Scotland] ≈ 182_154  
    @test PIP_RECEIPTS[nearest( d, PIP_RECEIPTS ),:Scotland] ≈ 220_043

    @test should_switch_dla_to_pip( "000000000000", 2016, 1, 40 )
    @test ! should_switch_dla_to_pip("99999999999", 2016, 1, 40 )

    =#

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
    #=
    FIXME code unused ATM 31/3/2025
    switch_dla_to_pip!( head, 2016, 3 )
    @test head.dla_self_care_type == missing_lmh
    @test head.dla_mobility_type == missing_lmh
    @test head.pip_mobility_type == enhanced_pip
    @test head.pip_daily_living_type == enhanced_pip
    =#
end # testset