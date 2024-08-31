
function do_initial_fixes!(hh::DataFrame, pers::DataFrame )
    # 
    # mostly.ai replaces the hid and pid with a random string, whereas we use bigints.
    # So, create a dictionary mapping the random hid string to a BigInt, and cleanup `randstr`.
    #
    hids = Dict{String,NamedTuple}()
    hid = BigInt(0)
    hs = size(hh)[1]
    #
    # Cast rands to string as opposed to string7 or whatever so we can assign our big string.
    #
    pers.onerand = String.(pers.onerand)
    hh.onerand = String.(hh.onerand)
    #
    # `hh` level: fixup `hid`s as BigInt, add rand stringxx
    # !! NOTE that assigning `hid` this way makes `hid` unique even across multiple data years. 
    # The actual dataset has `hid` unique only within a `data_year`.
    #
    rename!( hh, [:uhid=>:uhidstr])
    hh.uhid = fill( BigInt(0), hs )
    for h in eachrow(hh)
        hid += 1
        h.onerand = mybigrandstr()
        h.uhid = get_pid( SyntheticSource, h.data_year, hid, 0 )
        h.hid = hid
        hids[h.uhidstr] = (; hid, data_year = h.data_year, uhid=h.uhid )
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
    rename!( pers, [:uhid=>:uhidstr,:pid=>:pidstr])
    pers.uhid = fill( BigInt(0), np )
    pers.pid = fill( BigInt(0), np )
    #
    # Assign correct numeric hid/uhid/data_year to each person and fixup the random string.
    #
    for p in eachrow( pers )
        p.onerand = mybigrandstr()
        p.uhid = hids[p.uhidstr].uhid
        p.hid = hids[p.uhidstr].hid
        p.data_year = hids[p.uhidstr].data_year
        if ! ismissing( p.highest_qualification ) && (p.highest_qualification == 0) # missing is -1 here, not zero
            p.highest_qualification = -1
        end
        if(p.age < 16) || ((p.from_child_record==1)&&(p.age < 20))
            p.is_hrp = 0
            if (! ismissing(p.is_bu_head)) && (p.is_bu_head == 1)
                println( "removing bu head for $(p.pno) aged $(p.age) hid=$(p.hid)")
                p.is_bu_head = 0
                p.default_benefit_unit = 1 # FIXME wild guess
            end
        end
        p.is_hrp = coalesce( p.is_hrp, 0 )
        # FIXME fixup all the relationships
        if p.is_hrp == 1
            p.relationship_to_hoh = 0 # this person
        end
    end
    #
    # Data in order - just makes inspection easier.
    #
    sort!( hh, [:hid] )
    sort!( pers, [:hid,:pno,:default_benefit_unit,:age])
    #
    # Kill a few annoying missings.
    #
    pers.is_hrp = coalesce.( pers.is_hrp, 0 )
    pers.income_self_employment_income = coalesce.( pers.income_self_employment_income, 0 )
    pers.is_bu_head = coalesce.( pers.is_bu_head, 0 )
    # work round pointless assertion in map to hh
    pers.type_of_bereavement_allowance = coalesce.(pers.type_of_bereavement_allowance, -1)
    # also, pointless check in grossing up routines on occupations
    pers.occupational_classification = coalesce.(pers.occupational_classification, 0 )
    pers.occupational_classification = max.(0, pers.occupational_classification ) 
end


"""
For each hh, check there's 1 hrp per hh, one bu head per standard benefit unit, 
and that everyone is allocated to 1 standard benefit unit. We've already 
checked that each person is allocated to a household via `hid`.
FIXME move to `tests/`
FIXME check the `relationship_x` records
"""
function do_pers_idiot_checks( pers :: AbstractDataFrame, skiplist :: DataFrame )
    hh_pers = groupby( pers, [:hid])
    nps = size(hh_pers)[1]
    for hid in 1:nps
        hp = hh_pers[hid]
        if not_in_skiplist(hp[1,:],skiplist)
            hbus = groupby( hp, :default_benefit_unit )
            nbusps = 0
            first = hp[1,:]
            for bu in hbus 
                nbusps += size( bu )[1]
                numheads = sum( bu[:,:is_bu_head])
                @assert numheads == 1 "1 head for each bu hh.hid=$(first.hid) numheads=$numheads bu = $(bu[1,:default_benefit_unit])"
            end
            @assert nbusps == size(hp)[1] "size mismatch for hh.hid=$(first.hid)"
            @assert sum( hp[:,:is_hrp]) == 1 "1 head for each hh hh.hid=$(first.hid) was $(sum( hp[:,:is_hrp]) )"
        end
    end
end  



function get_relationships( hp :: AbstractDataFrame ) :: Matrix{Relationship}
    num_people = size(hp)[1]
    v = fill(Missing_Relationship,15,15)
    for i in 1:num_people
        k = Symbol("relationship_$i")
        for j in 1:num_people
            v[j,i] = Relationship(hp[j,k])
        end
    end
    v
end


function print_relationships( m::Matrix{Relationship} )
    n = findfirst( isequal( Missing_Relationship ), m[1,:])-1
    hc = hcat(m[1:n,1:n ],collect(1:n))
    pretty_table( hc )
end


function select_irredemably_bad_hhs( hh :: DataFrame, pers :: DataFrame )::DataFrame
    kills = DataFrame( hid=zeros(BigInt,0), data_year=zeros(Int,0), reason=fill("",0))
    for h in eachrow( hh )
        p = pers[pers.hid .== h.hid,:]
        n = size(p)[1]
        # all children - killem all
        if(maximum( p[!,:age]) < 16) && (sum( p[!,:from_child_record]) == n)
            println( "want to kill $(h.hid)")
            push!(kills, (; hid=h.hid, data_year=h.data_year, reason="all child hh child "))
        end
        hbus = groupby( p, :default_benefit_unit )
        nbusps = 0
        for bu in hbus 
            nbusps += size( bu )[1]
            numheads = sum( bu[:,:is_bu_head])
            if numheads != 1 
                msg = "!= 1 head for each bu hh.hid=$(h.hid) numheads=$numheads bu = $(bu[1,:default_benefit_unit])"
                push!( kills, (; hid=h.hid, data_year=h.data_year, reason=msg))
            end
        end
        if sum( p[:,:is_hrp]) != 1 
            msg = "!=1 head for each hh hh.hid=$(p.hid) was $(sum( p[:,:is_hrp]) )"
            push!( kills, (; hid=h.hid, data_year=h.data_year, reason=msg) )
        end
        # fixable, but hey..
        age_oldest_child = maximum(p[p.from_child_record.==1,:age];init=-99)
        if age_oldest_child >= 20
            msg = "age_oldest_child=$age_oldest_child for $(h.hid)"
            push!( kills,  (; hid=h.hid, data_year=h.data_year, reason=msg))
        end

    end
    # println( "killing $(kills)")
    return kills;
    # deleteat!(hh, hh.hid .∈ (kills,))
    # deleteat!(pers, pers.hid .∈ (kills,))
end

#
# open unpacked synthetic files
#
function load_unpacked_files()::Tuple
    #= original version 
    hh = CSV.File("tmp/model_households_scotland-2015-2021/model_households_scotland-2015-2021.csv") |> DataFrame
    pers = CSV.File( "tmp/model_people_scotland-2015-2021/model_people_scotland-2015-2021.csv" ) |> DataFrame
    =#
    # version with child/adult seperate
    hh = CSV.File("tmp/v3/model_households_scotland-2015-2021/model_households_scotland-2015-2021.csv")|>DataFrame
    child = CSV.File("tmp/v3/model_children_scotland-2015-2021/model_children_scotland-2015-2021.csv")|>DataFrame
    adult = CSV.File("tmp/v3/model_adults_scotland-2015-2021/model_adults_scotland-2015-2021.csv")|>DataFrame
    # Not actually needed with current sets but just in case.
    child.from_child_record .= 1
    adult.from_child_record .= 0
    pers = vcat( adult, child )
    hh,pers
end


function add_skips_from_model!( skips :: DataFrame )
    settings = Settings()
    settings.data_source = SyntheticSource 
    settings.do_legal_aid = false    
    settings.run_name="run-$(settings.data_source)-$(date_string())"
    settings.skiplist = "skiplist"
  
    settings.run_name="run-$(settings.data_source)-$(date_string())"

    sys = [
        get_default_system_for_fin_year(2024; scotland=true), 
        get_default_system_for_fin_year( 2024; scotland=true )]
    tot = 0
    settings.num_households, 
    settings.num_people, 
    nhh2 = 
        FRSHouseholdGetter.initialise( settings; reset=true )
    for hno in 1:1 # settings.num_households
        println( "on hh $hno num_households=$(settings.num_households)")
        mhh = FRSHouseholdGetter.get_household( hno )  
        try
            intermed = make_intermediate( 
                Float64,
                settings,
                mhh,  
                sys[1].lmt.hours_limits,
                sys[1].age_limits,
                sys[1].child_limits )
            for sysno in 1:2
                res = do_one_calc( mhh, sys[sysno], settings )
            end
        catch e
            @show mhh.people #relationships          
            # println( stacktrace())
            println( "caught exception $(e) hh.hid=$(mhh.hid) hh.data_year=$(mhh.data_year)")
            push!( skips, (; hid=mhh.hid, data_year=mhh.data_year, reason="$(e)"))
        end
    end
end

