using HTTP
using JSON
## !!! needs Julia 1.3:w
import Base.Threads.@spawn

const TEST_URL = "http://localhost:8000/stb"
const LIVE_URL = "https://oustb.virtual-worlds.scot/oustb/stb/"

function getdata( rate1:: Real, rate2 :: Real ) :: Dict
    url = "$(LIVE_URL)/?it_allow=12500&it_rate_1=$rate1&it_rate_$rate2&it_band=50000"
    println( "fetching from URL $url" )
    resp = HTTP.request( "GET", url )
    json = JSON.parse(join((map(Char,resp.body))))
    return json;
end

function doRunBatch( max :: Integer ) :: String
    n = 0
    threadid = Threads.threadid()
    println("doRunBatch; running on thread $threadid")
    rc = @timed for r1 in 2968:30
        for r2 in 40:50
            println( "getting data r1=$r1 r2=$r2 " )
            json = getdata( r1, r2 )
            if n % 1 == 0
                print( json )
            end
            n += 1
            if n > max
                break
            end
        end # rand2
    end # rand1
    secs = rc[2]
    "total runs on thread $threadid = $n in $secs secs"
end # func doRunBatch

# FIXME something unsafe about connections
function doall_threads( threadno :: Integer )
    println(" at start" )
    out = []
    for i in 1:threadno
        @time response = @spawn doRunBatch(1_000)
        s = fetch( response )
        push!( out, s )
    end
    out
end

function doall( threadno :: Integer )
    println(" at start" )
    doRunBatch(1_000)
end

out = doall(1)
println( out )
