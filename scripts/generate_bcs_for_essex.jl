
using ScottishTaxBenefitModel
using .STBParameters
using .BCCalcs
using .RunSettings
using .Definitions
using .ExampleHelpers
using .ModelHousehold
using .RunSettings
using .Utils

using BudgetConstraints
using DataFrames
using CairoMakie
using Format
using PrettyTables
using CSV


"""
Generate a pair of budget constraints (as Dataframes) for the given household.
"""
function getbc( 
    hh  :: Household, 
    sys :: TaxBenefitSystem, 
    wage :: Real,
    settings :: Settings )::Tuple
    defroute = settings.means_tested_routing
    settings.means_tested_routing = lmt_full 
    lbc = BCCalcs.makebc( hh, sys, settings, wage; to_html=true )
    lbc = recensor(lbc)
    lbc.mr .*= 100.0
    lbc.char_labels = BCCalcs.get_char_labels(size(lbc)[1])
    settings.means_tested_routing = uc_full 
    ubc = BCCalcs.makebc( hh, sys, settings, wage; to_html=true )
    ubc = recensor(ubc)
    ubc.mr .*= 100.0 # MR to percent
    ubc.char_labels = BCCalcs.get_char_labels(size(ubc)[1])
    settings.means_tested_routing = defroute
    (lbc,ubc)
end

"""
This is stolen from the bcd service.
"""
function get_hh( ;
    country   :: AbstractString,
    tenure    :: AbstractString,
    bedrooms  :: Integer, 
    hcost     :: Real, 
    marrstat  :: AbstractString, 
    chu6      :: Integer, 
    ch6p      :: Integer ) :: Household
    hh = get_example( single_hh )
    head = get_head(hh)
    hh.net_financial_wealth = 0.0
    hh.net_housing_wealth = 0.0
    hh.net_pension_wealth = 0.0
    hh.net_physical_wealth = 0.0
    head.age = 30
    sp = get_spouse(hh)
    enable!(head) # clear dla stuff from example
    hh.region = if country == "scotland"
            Scotland
    elseif country == "wales" # not actually possible with current interface
            Wales 
    else # just pick a random English one.
            North_East
    end 
    hh.tenure = if tenure == "private"
            Private_Rented_Unfurnished
    elseif tenure == "council"
            Council_Rented
    elseif tenure == "owner"
            Mortgaged_Or_Shared
    else
            @assert false "$tenure not recognised"
    end
    hh.bedrooms = bedrooms
    hh.other_housing_charges = hh.water_and_sewerage = 0
    if hh.tenure == Mortgaged_Or_Shared
            hh.mortgage_payment = hcost
            hh.mortgage_interest = hcost
            hh.gross_rent = 0
    else
            hh.mortgage_payment = 0
            hh.mortgage_interest = 0
            hh.gross_rent = hcost
    end
    if marrstat == "couple"
            sex = head.sex == Male ? Female : Male # hetero ..
            add_spouse!( hh, 30, sex )
            sp = get_spouse(hh)
            enable!(sp)
            set_wage!( sp, 0, 10 )
    end
    age = 0
    for ch in 1:chu6
            sex = ch % 1 == 0 ? Male : Female
            age += 1
            add_child!( hh, age, sex )
    end
    age = 7
    for ch in 1:ch6p
            sex = ch % 1 == 0 ? Male : Female
            age += 1
            add_child!( hh, age, sex )
    end
    set_wage!( head, 0, 10 )
    for (pid,pers) in hh.people
            # println( "age=$(pers.age) empstat=$(pers.employment_status) " )
            empty!( pers.income )
            empty!( pers.assets )
    end
    return hh
end

function do_everything( sys :: TaxBenefitSystem, settings::Settings)::Tuple
    tenures = ["private", "owner"]
    country = "scotland"
    hcosts = [200,400.0]
    marrstats = ["single", "couple"]
    out = Dict()
    processed = 0
    num_bedrooms = [1,4]
    keys = []
    for wage in [12,30] # !! above mw or mr results look weird (though they're ight)
        for tenure in tenures
            for marrstat in marrstats
                for hcost in hcosts
                    for bedrooms in num_bedrooms
                        for chu6 in [0,3]
                            for ch6p in [0,3]
                                if((ch6p + chu6) > 0)&&(bedrooms <2)
                                    ; # skip pointless examples
                                elseif((ch6p + chu6) == 0)&&(bedrooms > 1)
                                    ;
                                else
                                    processed += 1
                                    hh =  get_hh( ;
                                        country = country,
                                        tenure  = tenure,
                                        bedrooms = bedrooms,
                                        hcost    = hcost,
                                        marrstat = marrstat, 
                                        chu6     = chu6, 
                                        ch6p     = ch6p )
                                    lbc, ubc = getbc( hh, sys, wage, settings )
                                    key = (; wage, tenure, marrstat, hcost, bedrooms, chu6, ch6p )
                                    println( "on $key")
                                    println( "processed $processed")
                                    out[key] = (; lbc, ubc )                                
                                    push!( keys, key )
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return keys, out
end

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

function format_bc_df( title::String, bc::DataFrame)
    bc[!,:simplelabel_hide] = add_hidden_to_label.( bc.simplelabel )
    pretty_table( 
        String,
        bc[!,[:char_labels,:gross,:net,:mr,:cap,:reduction,:simplelabel_hide]]; 
        backend = Val(:html),
        formatters=fm,
        allow_html_in_cells=true,
        table_class="table table-sm table-striped table-responsive",
        header = ["ID", "Earnings &pound;pw","Net Income AHC &pound;pw", "METR", "Benefit Cap", "Benefits Reduced By", "Breakdown"], 	
        alignment=[fill(:r,6)...,:l],
        title = title )
end


function title_from_key(k::NamedTuple, legstr::String )::String
    s = []
    push!( s, k.marrstat == "single" ? "Single Person" : "Couple")
    push!( s, "Wage: &pound;$(k.wage)p.h")
    push!( s, k.tenure == "private" ? "Private Renting" : "Owner Occupier")
    push!( s, "Housing Costs: &pound;$(k.hcost)p.w")
    push!( s, "$(k.bedrooms) bedroom(s)")
    push!( s, "$(k.chu6) children under 6")
    push!( s, "$(k.ch6p) children 6+")
    return legstr*" : " *join(s,", ", " and ")
end

function id_from_key( k :: NamedTuple, legacy::Bool )::String
    leg = legacy ? "legacy" : "uc"
    return "$(leg)-$(k.wage)-$(k.tenure)-$(k.marrstat)-$(k.hcost)-$(k.bedrooms)-$(k.chu6)-$(k.ch6p)" 
end

# convoluted way of making pairs of (0,-10),(0,10) for label offsets
const OFFSETS = collect( Iterators.flatten(fill([(0,-10),(0,10)],50)))

function draw_bc( title :: String, df :: DataFrame )::Figure
    f = Figure(size=(1200,1200))
    nrows,ncols = size(df)
    xmax = maximum(df.gross)*1.1
    ymax = maximum(df.net)*1.1
    ymin = minimum(df.net)
    ax = Axis(f[1,1]; xlabel="Earnings &pound;s pw", ylabel="Net Income (AHC) &pound;s pw", title=title)
    ylims!( ax, 0, ymax )
    xlims!( ax, -10, xmax )
    lines!( ax, df.gross, df.net )
    scatter!( ax, df.gross, df.net; marker=df.char_labels, marker_offset=OFFSETS[1:nrows], markersize=15, color=:black )
    lines!( ax, [0,xmax], [0, ymax]; color=:lightgrey)
    scatter!( ax, df.gross, df.net, markersize=5, color=:red )
    f
end

function draw_one( dir::String, key::NamedTuple, bc :: DataFrame, legacy :: Bool )::String
    legstr = legacy ? "Old Benefit System" : "Universal Credit"
    title = title_from_key(key, legstr )
    id = id_from_key( key, legacy )
    table = format_bc_df( "", bc )
    f = draw_bc( "After Housing Costs, $legstr", bc )
    save( "$(dir)/img/$(id).svg", f )
    CSV.write( "$(dir)/data/$(id).tab", bc[!,Not(r"label")]; delim='\t')
    return """
<div class='row justify-content-center text-secondary pt-3 pb-3' id=$(id)>
    <h3>$title</h3>
    <div class="col-6">
        $(table)
   </div>  
    <div class="col-6">
    <img src='img/$(id).svg'>
    <br/>
    <a href="data/$(id).tab" download="$(id).tab">Dataset (tab-delimited)</a>
    </div>
    <p><a href='#home'>Top</a></p>
</div>
    """
end

function make_big_file(sys :: TaxBenefitSystem, settings::Settings)
    keys, dfs = do_everything(sys, settings )
    dir = joinpath("/", "home", "graham_s", "tmp","essex")
    io = open( joinpath(dir, "index.html"), "w")
    header = """
    <!DOCTYPE html>
    <html>
        <head>
        <title>Sample Budget Constraints</title>
        <link rel="stylesheet" href="css/northumbria-bootstrap.css"/>
        <script src='js/jquery.js'></script>
        <script src='js/bootstrap.bundle.js'></script>
    </head>
    <body class='p-2'>
    <h1>Sample Budget Constraints</h1>
    <p>
    Assumptions:
    </p>
    <ul>
        <li>2024/5 Scottish system;<li>
        <li>Lives in Glasgow (for ct, lha);
        <li>CT Band C;</li>
        <li>No other source of income;</li>
        <li>zero personal wealth;</li>
        <li>no disabilities;</li>
        <li>Head is aged 30;</li>
        <li>Where present, Spouse is also 30; does not earn; and</li>
        <li>Expenses (pension contributions, etc) are 0 and do not change as earnings change.
    </ul>
    <p>
    All these assumptions can be changed but there's a lot here as it is.
    The tables show combinations of (AHC, unequivalised) net income and wages for the household
    for various (too many!) combinations of numbers of children, bedrooms, tenure, coupledom and housing costs.
    </p>
    """

    footer = """
    <footer>

    </footer>
    </body>
    </html>
    """
    println(io, header)

    println( io, "<h3>Index</h3>")
    println( io, "<ol id='home'>")
    for key in keys
        for legacy in [true, false]
            legstr = legacy ? "Old Benefit System" : "Universal Credit"
            title = title_from_key(key, legstr )
            id = id_from_key( key, legacy )
            println(io, "<li><a href='#$id'>$title</a></li>")
        end
    end 
    println( io, "</ol>")

    for key in keys
        print( io, draw_one( dir, key, dfs[key].lbc, true ))
        print( io, draw_one( dir, key, dfs[key].ubc, false ))
    end

    println(io, footer )
    close(io)
end


#=
settings = Settings()
sys = STBParameters.get_default_system_for_fin_year( 2024 )
=#
