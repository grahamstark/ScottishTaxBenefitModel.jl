using CSV, DataFrames, Markdown
using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .Utils
using .ModelHousehold
using .FRSHouseholdGetter: initialise, get_household, get_num_households




#=
const MODEL_NAME="ScottishTaxBenefitModel"
const PROJECT_DIR=Utils.get_project_path() #"//vw/$MODEL_NAME/"
const MODEL_DATA_DIR="$(PROJECT_DIR)/data/"
const PRICES_DIR="$MODEL_DATA_DIR/prices/obr/"
const MATCHING_DIR="$MODEL_DATA_DIR/merging/"
const MODEL_PARAMS_DIR="$PROJECT_DIR/params"

const RAW_DATA = "/mnt/data/"
const FRS_DIR = "$RAW_DATA/frs/"
const HBAI_DIR = "$RAW_DATA/hbai/"
=#

include("../src/HouseholdMappingFRS_HBAI.jl")


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

adult = DataFrame()

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


for year in 2016:2018
    global ystr, y
    global frsx, hbai_res
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
   
    y = year - 2000
    ystr = "$(y)$(y+1)"
    frsx = vcat( frsx, l_loadfrs( "frs$ystr", year ), cols=:union )
    hbai_res = vcat( hbai_res, l_load_to_frame("$(HBAI_DIR)/tab/"*HBAIS[year]),  cols=:union )
    print("on year $year ")
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
    childcare = vcat( chldcare, l_loadfrs("chldcare", year),  cols=:union )
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
    
function get_hhld( hno, bits )
    mhh = FRSHouseholdGetter.get_household( hno )
    s = to_string( mhh )
    if :househol in bits
        s *= get_one( "Househol", househol, mhh.hid, mhh.data_year)
        s *= get_one( "Renter", renter, mhh.hid, mhh.data_year)
        s *= get_one( "Mortcont", mortcont, mhh.hid, mhh.data_year)
        s *= get_one( "Owner", owner, mhh.hid, mhh.data_year)
        s *= get_one( "RentCont", rentcont, mhh.hid, mhh.data_year)
    end
    if :adult in bits
        s *= get_one( "Adult", adult, mhh.hid, mhh.data_year)
        
        s *= get_one( "Job", job, mhh.hid, mhh.data_year)
        s *= get_one( "Benefits", benefits, mhh.hid, mhh.data_year)
        s *= get_one( "OddJob", oddjob, mhh.hid, mhh.data_year)
        s *= get_one( "Accounts", accounts, mhh.hid, mhh.data_year)
        s *= get_one( "Pension", pension, mhh.hid, mhh.data_year)
        s *= get_one( "Penprov", penprov, mhh.hid, mhh.data_year)
        s *= get_one( "Assets", assets, mhh.hid, mhh.data_year)
        s *= get_one( "Endowment", endowmnt, mhh.hid, mhh.data_year)
        s *= get_one( "GovPay", govpay, mhh.hid, mhh.data_year)
        s *= get_one( "Maint", maint, mhh.hid, mhh.data_year)
        s *= get_one( "Care", care, mhh.hid, mhh.data_year)
    end
    if :child in bits
        s *= get_one( "Child", child, mhh.hid, mhh.data_year)
        s *= get_one( "ExtChild", extchild, mhh.hid, mhh.data_year)
        s *= get_one( "Childcare", chldcare, mhh.hid, mhh.data_year)
    end
    if :hbai in bits
        s *= get_one( "HBAI", hbai_res, mhh.hid, mhh.data_year)
    end
    if :frsx in bits
        s *= get_one( "FRS-Flatfile", frsx, mhh.hid, mhh.data_year)
    end

    return s
end


init_data()



