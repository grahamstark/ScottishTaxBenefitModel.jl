#
# Script to clean up mostly.ai generated model Scottish datasets.
#
using ScottishTaxBenefitModel
using .Utils
using .Randoms
using .RunSettings
using .Definitions
using .Intermediate
using .ModelHousehold
using .FRSHouseholdGetter
using .SingleHouseholdCalculations: do_one_calc
using .STBParameters

using DataFrames,CSV,StatsBase
using OrderedCollections
using Revise 

include( "synth_file_libs.jl")

#=

STEPS:

1. download (as csv) synthetic hh and pers data from https://app.mostly.ai/ file is probably `synthetic-csv-data.zip`
2. unzip into `tmp/`
3. should produce something like 
    - `model_households_scotland-2015-2021/model_households_scotland-2015-2021.csv`
    - `model_people_scotland-2015-2021/model_people_scotland-2015-2021.csv`
4. check & maybe edit file read locations below
5. run this script. Output should go in `data/synthetic_datasets/` & have the names given in `RunSettings.jl`.

=#


function add_skips_from_model!( skips :: DataFrame )
    settings = Settings()
    settings.dataset_type = synthetic_data 
    settings.do_legal_aid = false    
    settings.run_name="run-$(settings.dataset_type)-$(date_string())"
    settings.skiplist = "skiplist"
  
    settings.run_name="run-$(settings.dataset_type)-$(date_string())"

    sys = [
        get_default_system_for_fin_year(2024; scotland=true), 
        get_default_system_for_fin_year( 2024; scotland=true )]
    tot = 0
    settings.num_households, 
    settings.num_people, 
    nhh2 = 
        FRSHouseholdGetter.initialise( settings; reset=true )
    for hno in 1:settings.num_households
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
            # println( stacktrace())
            println( "caught exception $(e) hh.hid=$(mhh.hid) hh.data_year=$(mhh.data_year)")
            push!( skips, (; hid=mhh.hid, data_year=mhh.data_year, reason="$(e)"))
        end
    end
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

"""
reassign over 21s not in education to non child
"""
function fixup_employment!( pers :: DataFrameRow )

end

"""
A dependent child is defined as an individual aged under 16. A person will also be
defined as a child if they are 16 to 19 years old and they are:
* Not married nor in a civil partnership nor living with a partner; and
* Living with parents (or a responsible adult); and
* In full-time non-advanced education or in unwaged government training.
Family Resource Survey United Kingdom, 2021 to 2022 Background Information and Methodology March 2023
FIXME just assign this rather than try to fix the ai one. p66 
"""
function fixup_child_status!( pers :: DataFrameRow )::Int
    oc = pers.from_child_record
    if pers.from_child_record == 1
        if pers.age >= 20
            pers.from_child_record = 0
        elseif pers.age >= 16 # i don't have any field atm for 'non-advanced education ...'
            if(! ismissing(pers.marital_status)) && (pers.marital_status != 3)
                pers.from_child_record = 0
            end
            if pers.is_hrp == 1 || pers.default_benefit_unit > 1
                pers.from_child_record = 0
            end
        end
    elseif pers.age < 16
        pers.from_child_record = 1
    end
    return oc == pers.from_child_record ? 0 : 1 # count of changes made
end 


function zeropos( p :: DataFrameRow )::Int
    for i in 1:15
        k = Symbol( "relationship_$(i)")
        if ismissing(p[k])
            return 9999
        elseif p[k] == 0
            return i
        end
    end
    9999
end


"""

"""
function fixup_relationships!( hp :: AbstractDataFrame )::Int
    # sort the hh people in order of the zero (itself) relationship field
    # that 
    hp.zpos .= zeropos.( eachrow(hp) )
    sort!( hp, :zpos )
    num_people = size(hp)[1] # 
    # println( "num people $num_people")
    @assert size( hp[hp.is_hrp.==1,:])[1] == 1 # exactly 1 hrp 
    nfixes = 0        
    for p in eachrow(hp) # for each person .. (only need 1st 1/2?)
        if p.is_hrp == 1 
            p.relationship_to_hoh = 0 # this person
        end
        ok = Symbol( "relationship_$(p.pno)") # a person's relationship to this person
        p[ok] = 0 # this person is him/herself
        # test each relationship for this person
        # is matched by a reciprocal one in the other people: 
        # father->child=>child<-father, partner=>partner and so on.
        for j in 1:num_people 
            # change the other person's relationship to match this one, if needed.
            if j != p.pno
                k = Symbol( "relationship_$(j)")
                relationship = if ismissing( p[k] )  # relationship of this person to person j
                    Missing_Relationship
                else 
                    Relationship(p[k])
                end
                if relationship == This_Person # can't be this person if pno != j
                    relationship = Missing_Relationship
                end
                oper = hp[j,:] # look up the other person
                recip_relationship = Relationship(oper[ok])
                if (relationship == Missing_Relationship) # lookup other way around if missing
                    relationship = reciprocal_relationship( recip_relationship )
                end
                shouldbe_rel = reciprocal_relationship( relationship )
                if recip_relationship != shouldbe_rel
                    # println("hh $(p.hid): changing for $(p.pno)=>$(oper.pno) relationships $(relationship)=>$(recip_relationship)")
                    nfixes += 1
                    oper[ok] = Int(shouldbe_rel)
                    # println("final relationships: $(relationship)=>$(Relationship(oper[ok]))")             
                end
                if relationship == This_Person # can't be this person if pno != j
                    oper[ok] = Int(Other_non_relative)
                end
            end # other people
        end # each relationship of this person 
        # clear out the rest
        for j in (num_people+1):15
            k = Symbol( "relationship_$(j)")
            # println( "clearing $k")
            if ! ismissing(p[k])
                p[k] = -1
            end
        end # clearout unneeded relationships
    end # each person 
    # clear out zero sort marker
    # select!( pers, Not( :zpos ))
    return nfixes
end # function

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
    println( "setting $hrpp $target to 1")
    hp[hrpp,target] = 1;    
end

"""
if bus numbers are 1,3,9 replace with 1,2,3
@param `hp` grouped sub-dataframe grouped in `hid`.
"""
function fixup_bus!( hp :: AbstractDataFrame; target :: Symbol )
    targets = hp[:,target]
    buos = collect(sort( OrderedSet(hp[:,target])))
    # println("initial buos $(hp[:,target])")
    for p in eachrow(hp)
        defb = p[target]
        nb = searchsorted(buos, defb )[1]
        p[target] = nb
    end
    # println("final bunos $(hp[:,target])")
end

"""
Allocate anyone, say, in Grand_parent relationship in a bu with a head to a new bu.
FIXME won't work for couples 
"""
function add_lonely_bus!( hp :: AbstractDataFrame )
    nbus = maximum( hp[:,:default_benefit_unit])
    buheads = hp[ hp.is_bu_head .== 1, : ]
    for b in eachrow(buheads)
        for p in eachrow(hp)
            if p.pno != b.pno
                if(p.default_benefit_unit == b.default_benefit_unit) # nominally in this bu
                    k = Symbol( "relationship_$(b.pno)")
                    if(is_not_immediate_family(Relationship(p[k]))&&(p.age >= 16))
                        println( "adding $nbus for hh $(p.hid) age $(p.age) pno $(p.pno)")
                        nbus += 1
                        p.default_benefit_unit = nbus
                        p.is_bu_head = true
                    end
                end
            end
        end
    end
end

function put_relationships!( hp :: AbstractDataFrame, rels :: Matrix{Int})

end


function change_pids!( hp :: AbstractDataFrame )# from::Int, to::Int )
    pno = 0
    for p in eachrow(hp) 
        pno += 1
        if p.pno != pno

            p.pno = pno

        end
        p.pid = get_pid( SyntheticSource, p.data_year, p.hid, p.pno )
    end
end


function do_main_fixes!(hh::DataFrame,pers::DataFrame)
    #
    # Loop round households-worth of person records.
    #
    n_relationships_changed = 0
    hh_pers = groupby( pers, [:hid])
    nps = size(hh_pers)[1]
    for hid in 1:nps
        thishh = hh[hh.hid.==hid,:][1,:]
        hp = hh_pers[hid]
        first = hp[1,:] # 1st person, just randomly chosen.
        #
        # fixup child records
        #
        #
        # force pnos to be consecutive from 1
        #
        change_pids!( hp )
        for p in eachrow( hp )
            fixup_child_status!( p )
        end
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
            #
            # fixup employment
            #
            fixup_employment!( p )
        end
        @assert sum( hp[:,:is_hrp]) == 1 "!=1 hrp for $(thishh.hid)"
        # Fixup non-contigious default BU allocations.
        if length(bus) !== maximum(bus) 
            # println( "non contig $(bus) $(thishh.hid)" )
            fixup_bus!( hp, target=:default_benefit_unit )
        end
        # For each of these now nicely numbered bus, ensure 1 bu head.
        hbus = groupby( hp, :default_benefit_unit )
        nbusps = 0
        for bu in hbus 
            nbusps += size( bu )[1]
            numheads = sum( bu[:,:is_bu_head])
            if numheads !== 1
                # println( "numheads $numheads")
                assign_hrp!( bu; target=:is_bu_head )
            end
        end
        # this is very unfinished
        @assert nbusps == size(hp)[1] "size mismatch for $(hp.hid)"
        n_relationships_changed += fixup_relationships!(hp)
        for p in eachrow( hp ) 
            if(p.age < 16) || ((p.from_child_record==1)&&(p.age < 20))
                p.is_hrp = 0
                if (! ismissing(p.is_bu_head)) && (p.is_bu_head == 1)
                    println( "#2 removing bu head for $(p.pno) aged $(p.age) hid=$(p.hid)")
                    p.is_bu_head = 0
                    p.default_benefit_unit = 1 # FIXME wild guess
                end
            end
        end
        add_lonely_bus!( hp )
        # endlessly repeated FIXME
        nbusps = 0
        # regroup bus
        hbus = groupby( hp, :default_benefit_unit )
        for bu in hbus 
            nbusps += size( bu )[1]
            numheads = sum( bu[:,:is_bu_head])
            if numheads !== 1
                println( "numheads wrong for $numheads")
                assign_hrp!( bu; target=:is_bu_head )
            end
        end
    end # hh loop
end

"""

"""
function fixall!( hh::DataFrame, pers::DataFrame)
    settings = Settings()
    settings.dataset_type = synthetic_data
    settings.skiplist = "skiplist"
    do_initial_fixes!( hh, pers )
    do_main_fixes!( hh, pers )
    skiplist = select_irredemably_bad_hhs( hh, pers )
    # Last minute checks - these are actually just a repeat of the hrp and bu checks in the main loop above.
    do_pers_idiot_checks( pers, skiplist )
    # Delete working columns with the mostly.ai string primary keys - we've replaced them
    # with BigInts as in the actual data.
    select!( hh, Not(:uhidstr) )
    select!( pers, Not( :pidstr ))
    select!( pers, Not( :uhidstr ))
    # write synth files to default locations.
    ds = main_datasets( settings )
    CSV.write( ds.hhlds, hh; delim='\t' )
    CSV.write( ds.people, pers; delim='\t' )
    CSV.write( ds.skiplist, skiplist; delim='\t')
    # 2nd try - just let the model fail
    add_skips_from_model!( skiplist )
    CSV.write( ds.skiplist, skiplist; delim='\t')
end

hh, pers = load_unpacked_files()