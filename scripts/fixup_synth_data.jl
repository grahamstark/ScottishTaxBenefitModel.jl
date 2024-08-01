#
# Script to clean up mostly.ai generated model scottish datasets.
#
using ScottishTaxBenefitModel
using .Utils
using .Randoms
using .RunSettings
using .Definitions
using DataFrames,CSV,StatsBase
using OrderedCollections
using Revise 


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
# So, create a dictionary mapping the random hid string to a BigInt, cleanup randstr
#
hids = Dict{String,BigInt}()
hid = BigInt(0)

# cast rands to string as opposed to string7 or whatever so we can assign our big string
pers.onerand = String.(pers.onerand)
hh.onerand = String.(hh.onerand)

# fixup hids as bigint, add rand string
rename!( hh, [:hid=>:hidstr])
hh.hid = fill( BigInt(0), hs )
for h in eachrow(hh)
    global hid
    hid += 1
    h.onerand = mybigrandstr()
    hids[h.hidstr] = hid
    h.hid = hid
end

v=counts(collect(values( countmap( pers.hid ))))
n = length(v)
[1:n v]
@assert sum( collect(1:n) .* v) == size( pers )[1] # everyone allocated to hhld

bus = sort(countmap( pers.default_benefit_unit ))

# start of hid/pid clean up 
np = size( pers )[1]
rename!( pers, [:hid=>:hidstr,:pid=>:pidstr])
pers.hid = fill( BigInt(0), np )
pers.pid = fill( BigInt(0), np )
# assign correct numeric hid to each person and fixup the random string 
for p in eachrow( pers )
    p.onerand = mybigrandstr()
    p.hid = hids[p.hidstr]
end

"""
For disfunctional hrps - clear any and assign highest earner, or oldest if no earner
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
    println("final buos $(hp[:,target])")
end

# more cleanups - missing in se income, hrps all missing
sort!( pers, [:data_year,:hid,:pid])
pers.is_hrp = coalesce.( pers.is_hrp, 0 )
pers.income_self_employment_income = coalesce.( pers.income_self_employment_income, 0 )
pers.is_bu_head = coalesce.( pers.is_bu_head, 0 )

## round households 
hh_pers = groupby( pers, [:hid])
nps = size(hh_pers)[1]
for hid in 1:nps
    hp = hh_pers[hid]
    first = hp[1,:]
    bus = Set()        
    hrps = sum( hp[:,:is_hrp])
    if hrps !== 1 # overwrite hrp 
        assign_hrp!( hp; target=:is_hrp )
    end
    for p in eachrow( hp )
        p.data_year = first.data_year
        p.pid = get_pid( FRS, p.data_year, p.hid, p.pno  )
        push!( bus, p.default_benefit_unit )
        # this assert fails without the assignment above
        @assert p.data_year == first.data_year "data_year $(p.data_year)  $(first.data_year) $(first.hid)"
    end
    @assert sum( hp[:,:is_hrp]) == 1 "!=1 hrp for $(first.hid)"
    if length(bus) !== maximum(bus) # non-contigious BUs
        # sbus = sort(bus)
        println( "non contig $(bus) $(first.hid)" )
        # FIXME there are only three, so..
        fixup_bus!( hp, target=:default_benefit_unit )
        #=
        for p in eachrow( hp )
            if p.default_benefit_unit == 3 
                p.default_benefit_unit = 2
            end
        end                
        =#
    end
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

    # @assert hrps == 1 "num hrps == $hrps for $(first.hid)"
    # @assert "mismatched bus for $(first.hid) $(bus)"
    # println(bus)
end

# delete working columns 
select!( hh, Not(:hidstr) )
select!( pers, Not( :pidstr ))
select!( pers, Not( :hidstr ))

## TODO FIXUP relationship_x fields

# last minute checks
do_pers_idiot_checks( pers )

CSV.write( ds.hhlds, hh )
CSV.write( ds.people, pers )
