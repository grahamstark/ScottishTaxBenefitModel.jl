#
# As of September 19 2021
# Tests og budget constraints
#

using Test
using DataFrames
using PrettyTables
using Dates
using Format

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
COLS = [:gross,:net,:mr,:cap,:reduction,:simplelabel]


function format_bc_df( title::String, bc::DataFrame)

    function fm(v, r,c)
        return if c in [1,7]
            v
        elseif c == 4
            if abs(v) > 4000
                "Discontinuity"
            else
                Format.format(v, precision=3, commas=false)
            end
        else
            Format.format(v, precision=2, commas=true)
        end
        s
    end

    function add_hidden_to_label( lab :: String )::String
        i = rand(100000:100000000)
        id = "id-$i"
        return "<button class='btn btn-primary' type='button' data-bs-toggle='collapse' data-bs-target='#$(id)' aria-expanded='false' aria-controls='collapseExample'>More Detail</button><div class='collapse' id='$id'><div class='card card-body'>$(lab)</div></div>"
    end

    bc.char_labels = BCCalcs.get_char_labels(size(bc)[1])
    bc[!,:simplelabel_hide] = add_hidden_to_label.( bc.simplelabel )
    pretty_table(
        String,
        bc[!,[:char_labels,:gross,:net,:mr,:cap,:reduction,:simplelabel_hide]];
        backend = :html,
        formatters=[fm],
        allow_html_in_cells=true,
        table_class="table table-sm table-striped table-responsive",
        column_labels = ["ID", "Earnings &pound;pw","Net Income AHC &pound;pw", "METR", "Benefit Cap", "Benefits Reduced By", "Breakdown"],
        alignment=[fill(:r,6)...,:l],
        title = title )
end


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
    pretty_table(f, bc[!,COLS]; backend=:html,allow_html_in_cells=true)

    settings.means_tested_routing = uc_full 
    bcu = BCCalcs.makebc(
        hh, 
        sys, 
        settings, 
        wage )
    println( f, format_bc_df( "UC CASE ", bcu[!,COLS] ))
    # println( f, "UC CASE ")
    # pretty_table(f,bcu[!,COLS];allow_html_in_cells=true, backend=:html )
    for r in eachrow( bc )
        rdf = row_to_detail_frame( r )
        println( f, "details for gross $(r.gross) net $(r.net)")
        pretty_table(f, rdf; backend=:html )
    end
    bc
end

settings = Settings()
settings.means_tested_routing = uc_full 
    
sys21_22 = get_default_system_for_date( Date( 2021, 12, 1 ))

@testset "Single Pers bc" begin
    tmp = tempdir()
    println( "writing to $tmp")
    f = open("$(tmp)/test-bcs.html","w")
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
    bc = printbcs( f, hh, sys21_22, 12, settings)
    CSV.write( joinpath( tmpdir, "bc-example.csv"), bc )
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
