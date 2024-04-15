
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
end