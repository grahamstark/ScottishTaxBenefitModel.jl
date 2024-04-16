
using Test
using Dates
using Format
using PrettyTables 
using Base.Threads
using ChunkSplitters

using ScottishTaxBenefitModel

using .Utils: pretty

using .ModelHousehold
using .Definitions
using .Results
using .FRSHouseholdGetter
using .RunSettings
using .HTMLLibs
using .SingleHouseholdCalculations:do_one_calc

@testset "Format a Household" begin
    settings = Settings() 
    settings.num_households,  settings.num_people, nhh2 = 
        FRSHouseholdGetter.initialise( settings; reset=false )
    for hno in 1:5
        hh = FRSHouseholdGetter.get_household( hno )
        # @show HTMLLibs.format_household( hh )
        head = get_head( hh )
        @show HTMLLibs.html_format( head.income )
        @show HTMLLibs.format_household( hh )
        @show HTMLLibs.format_person( head )
    end
    lares = LegalAidResult{Float64}()
    @show HTMLLibs.format( lares, lares )
end

@testset "Format Complete Results" begin
    sys1 = get_system( year=2023 )
    sys2 = get_uk_system( year=2023 )
    print = PrintControls()
    settings = Settings() 
    for hno in 1:5
        hh = FRSHouseholdGetter.get_household( hno )
        pre = do_one_calc( hh, sys1 )
        post = do_one_calc( hh, sys2 )
        @show HTMLLibs.format( hh, pre, post; settings=settings, print=print )
    end
end