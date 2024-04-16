
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

const ROOT="https://lasim.virtual-worlds.scot/"

const HEADER = """
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta charset="UTF-8">
    <title>Scottish Legal Aid Board Sim, v0.1.0</title>
    <link rel="icon" href="$(ROOT)images/favicon.png">
    <link rel="stylesheet" href="$(ROOT)/css/bisite-bootstrap.css"/>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.9.1/font/bootstrap-icons.css"/>
    <script type='text/javascript' src='$(ROOT)/js/jquery.js'></script>
    <script type='text/javascript' src='$(ROOT)/js/jquery.periodicalupdater.js'></script>
    <script type='text/javascript' src='$(ROOT)/js/jquery.validate.js'></script>
     <!-- bootstrap -->
    <script src="$(ROOT)/js/bootstrap.bundle.js"></script>
    <!-- vega graphics -->
    <script type="text/javascript" src="$(ROOT)/js/vega-lite.min.js"></script>
    <script type="text/javascript" src="$(ROOT)/js/vega.js"></script>
    <script type="text/javascript" src="$(ROOT)/js/vega-embed.min.js"></script>
    <!-- templates -->
    <script type='text/javascript' src="$(ROOT)/js/mustache.min.js"></script>
    
</head>
<body class='text-primary p-2'>
    
         <header class="">
        
        <nav class="navbar navbar-expand-lg nav-fill text-bg-primary">
            <span class='display-4 nav-item'><a class='nav-link active' href='https://www.slab.org.uk/'>
                <img src='images/slab-logo.svg' height='120' width='280'/></a></span>
            <span class='display-2 nav-item'>EXAMPLE HOUSEHOLDS</span>
        </nav>

        </header>
"""

@testset "Format Complete Results" begin
    sys1 = get_system( year=2021 )
    sys2 = get_system( year=2023 )
    print = PrintControls()
    settings = Settings() 
    settings.means_tested_routing = uc_full
    outfname = "web/example-hh-dump.html"
    println( "writing to $outfname")
    f = open( outfname,"w")
    s = HEADER
    for hno in 1:5
        hh = FRSHouseholdGetter.get_household( hno )
        pre = do_one_calc( hh, sys1 )
        post = do_one_calc( hh, sys2 )
        s *= "<h2>Household Results #$(hno)</h2>"
        s *= HTMLLibs.format( hh, pre, post; settings=settings, print=print )
        s *= "<hr/>"
    end
    s *= """
    </body>
    </html>
    """
    println( f, s )
    close(f)
end