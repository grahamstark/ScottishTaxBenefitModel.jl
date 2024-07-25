using ScottishTaxBenefitModel
using .Utils
using .Randoms
using .RunSettings
using .Definitions
using DataFrames,CSV,StatsBase

using Revise

settings = Settings()
settings.dataset_type = synthetic_data

ds = main_datasets( settings )

hh = CSV.File( ds.hhlds ) |> DataFrame
hs = size(hh)[1]
pers = CSV.File( ds.people ) |> DataFrame

hids = Dict{String,BigInt}()
hid = BigInt(0)
hh.onerand = String.(hh.onerand)
rename!( hh, [:hid=>:hidstr])
hh.hid = fill( BigInt(0), hs )
for h in eachrow(hh)
    hid += 1
    hids[h.hidstr] = hid
    h.hid = hid
end

v=counts(collect(values( countmap( pers.hid ))))
n = length(v)
[1:n v]
@assert sum( collect(1:n) .* v) == size( pers )[1] # everyone allocated to hhld

bus = sort(countmap( pers.default_benefit_unit ))

np = size( pers )[1]
rename!( pers, [:hid=>:hidstr,:pid=>:pidstr])
pers.hid = fill( BigInt(0), np )
pers.pid = fill( BigInt(0), np )
pers.onerand = String.(pers.onerand)

for p in eachrow( pers )
    p.onerand = mybigrandstr()
    p.hid = hids[p.hidstr]
end

hh_pers = groupby( pers, [:hid])
nps = size(hh_pers)[1]
for hid in 1:nps
    hp = hh_pers[hid]
    first = hp[1,:]
    bus = Set()        
    hrps = 0
    for p in eachrow( hp )
        p.data_year = first.data_year
        p.pid = get_pid( FRS, p.data_year, p.hid, p.pno  )
        if p.is_hrp == 1
            hrps += 1
        end
        push!( bus, p.default_benefit_unit )
        @assert p.data_year == first.data_year "data_year $(p.data_year)  $(first.data_year) $(first.hid)"
    end
    if hrps !== 1 # overwrite hrp 

    end
    if length(bus) == maximum(bus) # non-contigious BUs

    end
    # @assert hrps == 1 "num hrps == $hrps for $(first.hid)"
    # @assert "mismatched bus for $(first.hid) $(bus)"
    println(bus)
end