#
# Script to clean up mostly.ai generated model Scottish datasets.
#
using ScottishTaxBenefitModel
using .Utils
using .Randoms
using .RunSettings
using .Definitions
using DataFrames,CSV,StatsBase
using OrderedCollections
using Revise 

"""
For each hh, check there's 1 hrp per hh, one bu head per standard benefit unit, 
and that everyone is allocated to 1 standard benefit unit. We've already 
checked that each person is allocated to a household via `hid`.
FIXME move to `tests/`
FIXME check the `relationship_x` records
"""
function do_pers_idiot_checks( pers :: AbstractDataFrame )
    hh_pers = groupby( pers, [:hid])
    nps = size(hh_pers)[1]
    for hid in 1:nps
        hp = hh_pers[hid]
        hbus = groupby( hp, :default_benefit_unit )
        nbusps = 0
        first = hp[1,:]
        for bu in hbus 
            nbusps += size( bu )[1]
            numheads = sum( bu[:,:is_bu_head])
            @assert numheads == 1 "1 head for each bu hh.hid=$(first.hid)"
        end
        @assert nbusps == size(hp)[1] "size mismatch for hh.hid=$(hp.hid)"
        @assert sum( hp[:,:is_hrp]) == 1 "1 head for each hh hh.hid=$(hp.hid)"
    end
end        

"""
For disfunctional houshold `hrps` (without exactly 1 hrp).
Clear any hrp and assign highest earner, or oldest if no earner
NOTE: this code is also reused to reassign benefit unit heads from grouped benefit units.
Should really change name.

@param `hp` is a grouped sub-dataframe grouped in `hid`. 
@param `target` is a symbol of the col to check e.g. `is_hrp` or `is_bu_head`
"""
function assign_hrp!( hp :: AbstractDataFrame; target::Symbol )
    hp[!,target] .= 0
    # REALLY CRUDE
    income = hp.income_wages .+ hp.income_self_employment_income
    hrpp = -1 # fall over if not assigned below
    if any(income .> 0.0) # highest earned/se income
        hrpp = findmax(income)[2]
    else # .. or oldest if no income
        hrpp = findmax(hp.age)[2]
    end
    hp[hrpp,target] = 1;
end

"""
if bus numbers are 1,3,9 replace with 1,2,3
@param `hp` grouped sub-dataframe grouped in `hid`.
"""
function fixup_bus!( hp :: AbstractDataFrame; target :: Symbol )
    targets = hp[:,target]
    buos = collect(sort( OrderedSet(hp[:,target])))
    println("initial buos $(hp[:,target])")
    for p in eachrow(hp)
        defb = p[target]
        nb = searchsorted(buos, defb )[1]
        p[target] = nb
    end
    println("final bunos $(hp[:,target])")
end

#
# Load synthetic datasets using default settings.
#
settings = Settings()
settings.dataset_type = synthetic_data
ds = main_datasets( settings )
hh = CSV.File( ds.hhlds ) |> DataFrame
hs = size(hh)[1]
pers = CSV.File( ds.people ) |> DataFrame
# 
# mostly.ai replaces the hid and pid with a random string, whereas we use bigints.
# So, create a dictionary mapping the random hid string to a BigInt, and cleanup `randstr`.
#
hids = Dict{String,BigInt}()
hid = BigInt(0)
#
# Cast rands to string as opposed to string7 or whatever so we can assign our big string.
#
pers.onerand = String.(pers.onerand)
hh.onerand = String.(hh.onerand)
#
# `hh` level: fixup `hid`s as BigInt, add rand string
# !! NOTE that assigning `hid` this way makes `hid` unique even across multiple data years. 
# The actual dataset has `hid` unique only within a `data_year`.
#
rename!( hh, [:hid=>:hidstr])
hh.hid = fill( BigInt(0), hs )
for h in eachrow(hh)
    global hid
    hid += 1
    h.onerand = mybigrandstr()
    hids[h.hidstr] = hid
    h.hid = hid
end
#
# Check everyone is allocated to an existing household.
# FIXME in retrospect this doesn't actually check that... I need a join to hh.
# The next loop does check this though.
#
v=counts(collect(values( countmap( pers.hid ))))
n = length(v)
@assert sum( collect(1:n) .* v) == size( pers )[1] 
#
# hid/pid clean up for people, and random string
#
np = size( pers )[1]
rename!( pers, [:hid=>:hidstr,:pid=>:pidstr])
pers.hid = fill( BigInt(0), np )
pers.pid = fill( BigInt(0), np )
#
# Assign correct numeric hid to each person and fixup the random string.
#
for p in eachrow( pers )
    p.onerand = mybigrandstr()
    p.hid = hids[p.hidstr]
end
#
# Data in order - just makes inspection easier.
#
sort!( hh, [:data_year,:hid] )
sort!( pers, [:data_year,:hid,:pid])
#
# Kill a few annoying missings.
#
pers.is_hrp = coalesce.( pers.is_hrp, 0 )
pers.income_self_employment_income = coalesce.( pers.income_self_employment_income, 0 )
pers.is_bu_head = coalesce.( pers.is_bu_head, 0 )
#
# Loop round households-worth of person records.
#
hh_pers = groupby( pers, [:hid])
nps = size(hh_pers)[1]
for hid in 1:nps
    thishh = hh[hh.hid.==hid,:][1,:]
    hp = hh_pers[hid]
    first = hp[1,:] # 1st person, just randomly chosen.
    # Overwrite `is_hrp` if not exactly one in the hhlds' people.
    hrps = sum( hp[:,:is_hrp])
    if hrps !== 1 # overwrite hrp 
        assign_hrp!( hp; target=:is_hrp )
    end
    # Round the hh people: check benefit unit number sequencing, rewrite `pid` to a number, data_year always 
    # matches data_year for hh.
    bus = Set()        
    for p in eachrow( hp )
        p.data_year = thishh.data_year
        p.pid = get_pid( FRS, p.data_year, p.hid, p.pno  )
        push!( bus, p.default_benefit_unit )
        # this assert can sometimes fail without the assignment above
        @assert p.data_year == first.data_year "data_year $(p.data_year)  $(thishh.data_year) $(thishh.hid)"
    end
    @assert sum( hp[:,:is_hrp]) == 1 "!=1 hrp for $(thishh.hid)"
    # Fixup non-contigious default BU allocations.
    if length(bus) !== maximum(bus) 
        println( "non contig $(bus) $(thishh.hid)" )
        fixup_bus!( hp, target=:default_benefit_unit )
    end
    # For each of these now nicely numbered bus, ensure 1 bu head.
    hbus = groupby( hp, :default_benefit_unit )
    nbusps = 0
    for bu in hbus 
        nbusps += size( bu )[1]
        numheads = sum( bu[:,:is_bu_head])
        if numheads !== 1
            println( "numheads $numheads")
            assign_hrp!( bu; target=:is_bu_head )
        end
    end
    @assert nbusps == size(hp)[1] "size mismatch for $(hp.hid)"
end

# Delete working columns with the mostly.ai string primary keys - we've replaced them
# with BigInts as in the actual data.
select!( hh, Not(:hidstr) )
select!( pers, Not( :pidstr ))
select!( pers, Not( :hidstr ))

## TODO FIXUP relationship_x fields

# Last minute checks - these are actually just a repeat of the hrp and bu checks in the main loop above.
do_pers_idiot_checks( pers )

CSV.write( ds.hhlds, hh )
CSV.write( ds.people, pers )