#
# As of September 19 2021
# Tests og budget constraints
#

using Test
using DataFrames
using PrettyTables
using Dates

using ScottishTaxBenefitModel
using .ModelHousehold
using .STBParameters
using .STBIncomes
using .Definitions
using .GeneralTaxComponents
using .SingleHouseholdCalculations
using .RunSettings
using .Utils
using .ExampleHouseholdGetter
using .BCCalcs
using .ExampleHelpers


# COLS = [:gross,:mr,:label_pch]
COLS = [:gross,:net,:mr,:reduction,:simplelabel]

function printbcs( 
    f  :: IO,
    hh :: Household,
    sys :: TaxBenefitSystem, 
    wage::Real,
    settings::Settings )

    settings.means_tested_routing = lmt_full 
    bc = BCCalcs.makebc(
        hh, 
        sys, 
        settings, 
        wage )
    println(f, "Legacy Case")
    pretty_table(f, bc[!,COLS]; backend=Val(:html),allow_html_in_cells=true)

    settings.means_tested_routing = uc_full 
    bcu = BCCalcs.makebc(
        hh, 
        sys, 
        settings, 
        wage )
    println( f, "UC CASE ")
    pretty_table(f,bcu[!,COLS];allow_html_in_cells=true, backend=Val(:html) )
end

settings = Settings()
settings.means_tested_routing = uc_full 
    
sys21_22 = get_default_system_for_date( Date( 2021, 12, 1 ))

@testset "Single Pers bc" begin
    f = open("tmp/test-bcs.html","w")
    println(f,"<!DOCTYPE html><html><head></head><body>")
    hh = crude_construct_hh( 
        "private", 
        2, 
        200.0, 
        "couple", 
        0, 
        0 )
    println( f, "<h2>2 bedrooms; 0 kids; 200 hcost</h2>")
    hres = do_one_calc(hh, sys21_22, settings )
    println( f, "<pre>$(hres.bus[1].uc)</pre>")
    printbcs( f, hh, sys21_22, 12, settings)

    println( f, "<h2>6 bedrooms; 6 kids; 300 hcost</h2>")
    hh = crude_construct_hh( 
        "council", 
        6, 
        300.0, 
        "couple", 
        2, 
        4 )
    head = get_head( hh )
    # head.employment_status = Full_time_Employee
    hres = do_one_calc(hh, sys21_22, settings)
    println( f, "<pre>$(hres.bus[1].uc)</pre>")
    printbcs( f, hh, sys21_22, 10, settings)
    println(f,"</body></html>")
    close(f)
end