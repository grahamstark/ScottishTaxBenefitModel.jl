# module ... 
using CSV, DataFrames, Markdown

using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .Definitions
using .Utils
using .ModelHousehold
using .FRSHouseholdGetter: initialise, get_household, get_num_households
using Logging, LoggingExtras


include("$(PROJECT_DIR)/src/HouseholdMappingFRS_HBAI.jl")

"""
LOCAL version treating '-1' as missing.
main version in `Utils.jl`.
load a file into a dataframe and force all the identifiers into
lower case
"""
function l_load_to_frame(filename::AbstractString)::DataFrame
    println( "loading $filename")
    df = CSV.File(filename, delim = '\t',missingstrings=["-1",""]) |> DataFrame #
    lcnames = Symbol.(lowercase.(string.(names(df))))
    rename!(df, lcnames)
    df
end

"""
Local so we can treat "-1" as a missing string and add a datayear
"""
function l_loadfrs(which::AbstractString, year::Integer)::DataFrame
    filename = "$(FRS_DIR)/$(year)/tab/$(which).tab"
    df = l_load_to_frame(filename)
    n = size(df)[1]
    df.data_year = fill( year, n )
    return df
end


function addqstrdict(app, req  :: Dict )
    req[:parsed_querystring] = qstrtodict(req[:query])
    return app(req)
 end
 

struct RawData 
    frsx  :: DataFrame
    hbai_res :: DataFrame
    accounts :: DataFrame
    benunit :: DataFrame
    extchild :: DataFrame
    maint :: DataFrame
    penprov :: DataFrame
    care :: DataFrame
    mortcont :: DataFrame
    pension :: DataFrame
    adult :: DataFrame
    child :: DataFrame
    govpay :: DataFrame
    mortgage :: DataFrame
    assets :: DataFrame
    childcare :: DataFrame
    househol :: DataFrame
    oddjob :: DataFrame
    rentcont :: DataFrame
    benefits :: DataFrame
    endowmnt :: DataFrame
    job :: DataFrame
    owner :: DataFrame
    renter :: DataFrame

end

function load_raw()::RawData
    year = 2015
    y = year - 2000
    ystr = "$(y)$(y+1)"
    frsx = l_loadfrs( "frs$ystr", year )
    hbai_res = l_load_to_frame("$(HBAI_DIR)/tab/"*HBAIS[year])
    print("on year $year ")
    accounts = l_loadfrs("accounts", year)
    benunit = l_loadfrs("benunit", year)
    extchild = l_loadfrs("extchild", year)
    maint = l_loadfrs("maint", year)
    penprov = l_loadfrs("penprov", year)
    care = l_loadfrs("care", year)
    mortcont = l_loadfrs("mortcont", year)
    pension = l_loadfrs("pension", year)
    adult = l_loadfrs("adult", year)
    child = l_loadfrs("child", year)
    govpay = l_loadfrs("govpay", year)
    mortgage = l_loadfrs("mortgage", year)
    assets = l_loadfrs("assets", year)
    chldcare = l_loadfrs("chldcare", year)
    househol = l_loadfrs("househol", year)
    oddjob = l_loadfrs("oddjob", year)
    rentcont = l_loadfrs("rentcont", year)
    benefits = l_loadfrs("benefits", year)
    endowmnt = l_loadfrs("endowmnt", year)
    job = l_loadfrs("job", year)
    owner = l_loadfrs("owner", year)
    renter = l_loadfrs("renter", year)


    for year in 2019:2018
        #=
        global frsx 
        global hbai_res
        global accounts
        global benunit
        global extchild
        global maint
        global penprov
        global care
        global mortcont
        global pension
        global adult
        global child
        global govpay
        global mortgage
        global assets
        global childcare
        global househol
        global oddjob
        global rentcont
        global benefits
        global endowmnt
        global job
        global owner
        global renter
        =#
        y = year - 2000
        ystr = "$(y)$(y+1)"
        frsx = vcat( frsx, l_loadfrs( "frs$ystr", year ), cols=:union )
        n = size(frsx)
        hbai_res = vcat( hbai_res, l_load_to_frame("$(HBAI_DIR)/tab/"*HBAIS[year]),  cols=:union )
        print("on year $year frsx size=$n")
        accounts = vcat( accounts, l_loadfrs("accounts", year),  cols=:union )
        benunit = vcat( benunit, l_loadfrs("benunit", year),  cols=:union )
        extchild = vcat( extchild, l_loadfrs("extchild", year),  cols=:union )
        maint = vcat( maint, l_loadfrs("maint", year),  cols=:union )
        penprov = vcat( penprov, l_loadfrs("penprov", year),  cols=:union )
        care = vcat( care, l_loadfrs("care", year),  cols=:union )
        mortcont = vcat( mortcont, l_loadfrs("mortcont", year),  cols=:union )
        pension = vcat( pension, l_loadfrs("pension", year),  cols=:union )
        adult = vcat( adult, l_loadfrs("adult", year),  cols=:union )
        child = vcat( child, l_loadfrs("child", year),  cols=:union )
        govpay = vcat( govpay, l_loadfrs("govpay", year),  cols=:union )
        mortgage = vcat( mortgage, l_loadfrs("mortgage", year),  cols=:union )
        assets = vcat( assets, l_loadfrs("assets", year),  cols=:union )
        chldcare = vcat( chldcare, l_loadfrs("chldcare", year),  cols=:union )
        househol = vcat( househol, l_loadfrs("househol", year),  cols=:union )
        oddjob = vcat( oddjob, l_loadfrs("oddjob", year),  cols=:union )
        rentcont = vcat( rentcont, l_loadfrs("rentcont", year),  cols=:union )
        benefits = vcat( benefits, l_loadfrs("benefits", year),  cols=:union )
        endowmnt = vcat( endowmnt, l_loadfrs("endowmnt", year),  cols=:union )
        job = vcat( job, l_loadfrs("job", year),  cols=:union )
        owner = vcat( owner, l_loadfrs("owner", year),  cols=:union )
        renter = vcat( renter, l_loadfrs("renter", year),  cols=:union )
    end
    model_households = CSV.File( "data/model_households_scotland.tab") |> DataFrame
    model_people = CSV.File( "data/model_people_scotland.tab") |> DataFrame   
    
    return RawData(
            frsx ,
            hbai_res,
            accounts,
            benunit,
            extchild,
            maint,
            penprov,
            care,
            mortcont,
            pension,
            adult,
            child,
            govpay,
            mortgage,
            assets,
            chldcare,
            househol,
            oddjob,
            rentcont,
            benefits,
            endowmnt,
            job,
            owner,
            renter
    )
end

const rd = load_raw()

function init_data(; reset :: Bool = false )
    nhh = get_num_households()
    num_people = -1
    if( nhh == 0 ) || reset 
       @time nhh, num_people,nhh2 = initialise(
             household_name = "model_households_scotland",
             people_name    = "model_people_scotland" )
    end
    (nhh,num_people)
 end
 
function print_one( r :: DataFrameRow ) :: String
    nms = names( r )
    s = "|:-----------|-------------:|\n"
    for n in nms
        sym = Symbol(n)
        v = r[sym] 
        if ! ismissing( v )
            s *= "|**$n**|$v|\n"
        end
    end
    s *= "\n\n"
    return s
end

function get_one( label :: String, frame :: DataFrame, sernum :: BigInt, data_year :: Int ) :: String
    s = ""
    items = frame[(frame.sernum .== sernum).&(frame.data_year .== data_year),:]
    n = size(items)[1]
    if n == 0
        s *= "###No $(label)s\n"
        return s
    elseif n == 1
        s *= "##$label\n"
        s *= print_one(items[1,:])
    else
        i = 1        
        for item in eachrow(items)
            s *= "##$label ($i)\n"
            s *= print_one(item)
            i += 1
        end
    end
    return s
end
    
function get_data( hno, bits )
    mhh = FRSHouseholdGetter.get_household( hno )
    s = to_string( mhh )
    if :househol in bits
        s *= get_one( "Househol", rd.househol, mhh.hid, mhh.data_year)
        s *= get_one( "Renter", rd.renter, mhh.hid, mhh.data_year)
        s *= get_one( "Mortcont", rd.mortcont, mhh.hid, mhh.data_year)
        s *= get_one( "Owner", rd.owner, mhh.hid, mhh.data_year)
        s *= get_one( "RentCont", rd.rentcont, mhh.hid, mhh.data_year)
    end
    if :adult in bits
        s *= get_one( "Adult", rd.adult, mhh.hid, mhh.data_year)
        
        s *= get_one( "Job", rd.job, mhh.hid, mhh.data_year)
        s *= get_one( "Benefits", rd.benefits, mhh.hid, mhh.data_year)
        s *= get_one( "OddJob", rd.oddjob, mhh.hid, mhh.data_year)
        s *= get_one( "Accounts", rd.accounts, mhh.hid, mhh.data_year)
        s *= get_one( "Pension", rd.pension, mhh.hid, mhh.data_year)
        s *= get_one( "Penprov", rd.penprov, mhh.hid, mhh.data_year)
        s *= get_one( "Assets", rd.assets, mhh.hid, mhh.data_year)
        s *= get_one( "Endowment", rd.endowmnt, mhh.hid, mhh.data_year)
        s *= get_one( "GovPay", rd.govpay, mhh.hid, mhh.data_year)
        s *= get_one( "Maint", rd.maint, mhh.hid, mhh.data_year)
        s *= get_one( "Care", rd.care, mhh.hid, mhh.data_year)
    end
    if :child in bits
        s *= get_one( "Child", rd.child, mhh.hid, mhh.data_year)
        s *= get_one( "ExtChild", rd.extchild, mhh.hid, mhh.data_year)
        s *= get_one( "Childcare", rd.chldcare, mhh.hid, mhh.data_year)
    end
    if :hbai in bits
        s *= get_one( "HBAI", rd.hbai_res, mhh.hid, mhh.data_year)
    end
    if :frsx in bits
        s *= get_one( "FRS-Flatfile", rd.frsx, mhh.hid, mhh.data_year)
    end

    return s
end

WEB = false

if WEB

    using Mux
    import Mux.WebSockets
    using JSON
    using HttpCommon

    const DEFAULT_PORT=8002

    # Headers -- set Access-Control-Allow-Origin for either dev or prod
    # this is from https://github.com/JuliaDiffEq/DiffEqOnlineServer
    #
    function add_headers( md :: AbstractString ) :: Dict
        headers  = HttpCommon.headers()
        headers["Content-Type"] = "text/markdown; charset=utf-8"
        headers["Access-Control-Allow-Origin"] = "*"
        return Dict(
        :headers => headers,
        :body=> md
        )
    end

    function get_hh( hdstr :: AbstractString ) :: Dict
        @debug "get hh hdstr=$hdstr"
        hno = parse( Int, hdstr )
        @debug "get hh parsed hid=$hno"    
        bits = [:househol]
        s = get_data( hno, bits )
        println( "got s $s")
        return add_headers( s )
    end

    function x_get_hh( req  :: Dict ) :: Dict
        println( "get_hh entered")
        querydict = req[:parsed_querystring]
        println("get_hh; req=$req")
        println( "querydict=$(querydict)")
        hno = querydict["hno"]
        bits = [:househol] # todo
        s = get_hhld( hno, bits )
        println( "got s $s")
        return add_headers( s )
    end

    init_data()
    println("data initialised")
    logger = FileLogger("/var/tmp/retriever.log")
    global_logger(logger)
    LogLevel( Logging.Info )

    @app retriever = (
    Mux.defaults,
    page( respond("<h1>STB Data Retrieval</h1>")),   
    # addqstrdict,
    # page("/get_hh:hid", req -> get_hh( ) )
    page( "/hhld/:hid", req -> get_hh( req[:params][:hid] )),
    Mux.notfound()
    )
    println("app created")

    port = DEFAULT_PORT
    if length(ARGS) > 0
    port = parse(Int, ARGS[1])
    end

    serve( retriever, port )
    println( "server started on port $port ")

    while true # FIXME better way?
    println( "main loop; server running on port $port" )
    sleep( 60 )
    end

end # run as web server