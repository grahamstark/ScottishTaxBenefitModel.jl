#
# see: https://github.com/JuliaWeb/Mux.jl
# and:
#
using Mux
using JSON

using Definitions
using FRSHouseholdGetter
using ExampleHouseholdGetter
using ModelHousehold
using Utils
using MiniTB
using GeneralTaxComponents
using BudgetConstraints
using HttpCommon
using Logging, LoggingExtras
using WebModelLibs

import Mux.WebSockets


## !!! needs Julia 1.3:w
import Base.Threads.@spawn

const DEFAULT_PORT=8000
const DEFAULT_SERVER="http://localhost:$DEFAULT_PORT/"

const DEFAULT_TEST_URL="$(DEFAULT_SERVER)/bc?it_allow=300.0&it_rate_1=0.25&it_rate_2=0.5&it_band=10000&benefit1=150.0&benefit2=60.0&ben2_min_hours = 150.0&ben2_taper=0.5&ben2_u_limit = 250.0"
const ZERO_TEST_URL="$(DEFAULT_SERVER)/bc?it_allow=0&it_rate_1=0&it_rate_2=0&it_band=0&benefit1=0&benefit2=0.0&ben2_taper=0&ben2_min_hours=0&ben2_u_limit=0"

@debug "server starting up"

# gks work round some (version?) thing in the diffeq code
function get_thing( thing::AbstractArray, key :: AbstractString, default :: AbstractString )
   for i in thing
      if i[1] == key
         return i[2]
      end
   end # loop
   default
end #get


function web_get_hh( hdstr::AbstractString )
   hid = parse(Int64, hdstr)
   JSON.json(FRSHouseholdGetter.get_household(hid))
end

function addqstrdict(app, req  :: Dict )
   req[:parsed_querystring] = qstrtodict(req[:query])
   return app(req)
end

# Better error handling
function errorCatch( app, req  :: Dict )
   try
      app(req)
   catch e
      @error "Error occured!"
      io = IOBuffer()
      showerror(io, e)
      err_text = takebuf_string(io)
      @error err_text
      resp = withHeaders(JSON.json(Dict("message" => err_text, "error" => true)), req)
      resp[:status] = 500
      return resp
   end
end

function d100( v :: Number ) :: Number
   v/100.0
end

function web_map_params( req  :: Dict, defaults = MiniTB.DEFAULT_PARAMS ) :: MiniTB.TBParameters
   querydict = req[:parsed_querystring]
   tbparams = deepcopy( defaults )
   tbparams.it_allow = get_if_set("it_allow", querydict, tbparams.it_allow, operation=weeklyise )
   tbparams.it_rate[1] = get_if_set("it_rate_1", querydict, tbparams.it_rate[1], operation=d100 )
   tbparams.it_rate[2] = get_if_set("it_rate_2", querydict, tbparams.it_rate[2], operation=d100 )
   tbparams.it_band[1] = get_if_set("it_band", querydict, tbparams.it_band[1], operation=weeklyise)
   tbparams.benefit1 = get_if_set("benefit1", querydict, tbparams.benefit1)
   tbparams.benefit2 = get_if_set("benefit2", querydict, tbparams.benefit2)
   tbparams.ben2_min_hours = get_if_set("ben2_min_hours", querydict, tbparams.ben2_min_hours)
   tbparams.ben2_taper = get_if_set("ben2_taper", querydict, tbparams.ben2_taper, operation=d100)
   tbparams.ben2_u_limit = get_if_set("ben2_u_limit", querydict, tbparams.ben2_u_limit)
   tbparams.basic_income = get_if_set("basic_income", querydict, tbparams.basic_income)
   @debug "DEFAULT_PARAMS\n$DEFAULT_PARAMS"
   @debug "tbparams\n$tbparams"
   tbparams
end


const example_names, num_households, num_people = load_data( load_examples = true, load_main = true, start_year = 2015 )

const DEFAULT_BC = local_makebc(MiniTB.DEFAULT_PERSON, MiniTB.DEFAULT_PARAMS)

const BASE_RESULTS = create_base_results( num_households, num_people )

function makeztparams() :: MiniTB.TBParameters
   pars = deepcopy( MiniTB.DEFAULT_PARAMS )
   pars.it_rate = [0.0,0.0]
   pars
end

const BC_500_SETTINGS = BCSettings( maxgross=500 )


const ZERO_TAX_PARAMS = makeztparams()
const ZERO_DEFAULT_BC = local_makebc(MiniTB.DEFAULT_PERSON, MiniTB.ZERO_PARAMS)
const ZERO_TAX_BC = local_makebc(MiniTB.DEFAULT_PERSON, ZERO_TAX_PARAMS, BC_500_SETTINGS )

function main_run_to_json( tbparams :: MiniTB.TBParameters ):: String
   results = doonerun( tbparams, num_households, num_people, NUM_REPEATS )
   summary_output = summarise_results!( results=results, base_results=BASE_RESULTS )
   JSON.json( summary_output )
end

function web_doonerun( req :: Dict ) :: AbstractString
   @info "web_doonerun; running on thread $(Threads.threadid())"
   tbparams = web_map_params( req )
   json = main_run_to_json( tbparams )
   # headers could include (e.g.) a timestamp, so add after caching
end # doonerun


function web_makebc( req  :: Dict ) :: AbstractString
   @debug "web_makebc; running on thread $(Threads.threadid())"
   tbparams = web_map_params( req )
   bc =  local_makebc( DEFAULT_PERSON, tbparams )
   JSON.json((base = DEFAULT_BC, changed = bc))
end

function web_makezbc( req  :: Dict ) :: AbstractString
   @debug "web_makezbc; running on thread $(Threads.threadid())"
   tbparams = web_map_params( req, MiniTB.ZERO_PARAMS )
   bc =  local_makebc( DEFAULT_PERSON, tbparams )
   JSON.json((base = ZERO_DEFAULT_BC, changed = bc))
end

function web_makeztbc( req  :: Dict ) :: AbstractString
   @debug "web_makeztbc; running on thread $(Threads.threadid())"
   tbparams = web_map_params( req, ZERO_TAX_PARAMS )
   bc =  local_makebc( DEFAULT_PERSON, tbparams, BC_500_SETTINGS )
   JSON.json((base = ZERO_TAX_BC, changed = bc))
end

function web_doineq( req  :: Dict ) :: AbstractString
   @debug "web_doineq; running on thread $(Threads.threadid())"
   querydict = req[:parsed_querystring]
   inc=zeros(0)
   pop=zeros(0)
   for i in 1:10 # can's see how to pass a json array from js to this, so ...
      push!( inc, Float64(get_if_set("inc_$i", querydict, 0 )))
      push!( pop, Float64(get_if_set("pop_$i", querydict, 0 )))
   end
   data = hcat( pop, inc )
   ineq = GeneralTaxComponents.makeinequality( data, 1, 2 )
   JSON.json( ( data=data, ineq=ineq ))
end


# Headers -- set Access-Control-Allow-Origin for either dev or prod
# this is from https://github.com/JuliaDiffEq/DiffEqOnlineServer
#
function add_headers( json :: AbstractString ) :: Dict
    headers  = HttpCommon.headers()
    headers["Content-Type"] = "application/json; charset=utf-8"
    headers["Access-Control-Allow-Origin"] = "*"
    Dict(
       :headers => headers,
       :body=> json
    )
end

#
# This is my attempt at starting a task using the 1.3 @spawn macro
# 1st parameter is a function that returns String (probably a json string) and accepts the req Dict
#
function do_in_thread( the_func::Function, req :: Dict ) :: Dict
   response = @spawn the_func( req )
   # note that the func returns a string but response is a Future type
   # line below converts response to a string
   @debug "do_in_thread response is $response"
   json = fetch( response )
   add_headers( json )
end

# configure logger; see: https://docs.julialang.org/en/v1/stdlib/Logging/index.html
# and: https://github.com/oxinabox/LoggingExtras.jl
logger = FileLogger("/var/tmp/stb_log.txt")
global_logger(logger)
LogLevel( Logging.Info )

#
# from diffeq thingy instead of Mux.defaults
#
# ourstack = stack(Mux.todict, errorCatch, Mux.splitquery, Mux.toresponse) # from DiffEq
#
@app dd226 = (
   Mux.defaults,
   addqstrdict,
   page( respond("<h1>A Scottish Tax-Benefit Model</h1><p>; very early version</p>")),
   page( "/hhld/:hid", req -> web_get_hh((req[:params][:hid]))), # note no headers
   page("/ineq", req -> do_in_thread( web_doineq, req )),
   page("/bc", req -> do_in_thread( web_makebc, req )),
   page("/zbc", req -> do_in_thread( web_makezbc, req )),
   page("/ztbc", req -> do_in_thread( web_makeztbc, req )),
   # handle main stb run a bit differently so we can
   # check & cache the results.
   # page("/stb", req -> web_doonerun_cached( req )),
   page("/stb", req -> do_in_thread( web_doonerun, req )),
   Mux.notfound(),
)

port = DEFAULT_PORT
if length(ARGS) > 0
   port = parse(Int64, ARGS[1])
end

serve(dd226, port)

while true # FIXME better way?
   @debug "main loop; server running on port $port"
   sleep( 60 )
end
