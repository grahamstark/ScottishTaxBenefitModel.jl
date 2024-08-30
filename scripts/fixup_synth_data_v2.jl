#
# Script to clean up mostly.ai generated model Scottish datasets, 2nd try
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
using PrettyTables
using ArgCheck

include( "synth_file_libs.jl")


mutable struct MiniPers
    hid::BigInt # == sernum
    pid::BigInt # == unique id (year * 100000)+
    pno:: Int # person number in household
    is_hrp :: Bool
    default_benefit_unit:: Int
    is_benefit_unit_head :: Bool 
    is_standard_child :: Bool
    is_adult::Bool
    age:: Int
    sex::Sex
    marital_status::Marital_Status
    relationships::Vector{Relationship}
    relationship_to_hoh :: Relationship
    income :: Float64
end

function all_mini_pers( h :: DataFrameRow, hp :: AbstractDataFrame )::Vector{MiniPers}
    m = MiniPers[]
    pno = 0
    n = size(hp)[1] 
    for r in eachrow(hp)
        pno += 1
        pid = get_pid( SyntheticSource, h.data_year, h.hid, pno )
        rels = fill(Missing_Relationship,n)
        rels[pno] = This_Person
        inc = 0.0
        if r.from_child_record == 0
            inc = r.income_wages +
                r.income_self_employment_income - 
                r.income_self_employment_losses
        end
        p = MiniPers(
                r.hid,
                pid, # pid
                pno, # pno
                false, # is hrp
                -1, # default bu
                false, # bu head
                r.from_child_record == 1,
                r.from_child_record == 0,
                r.age,
                Sex(r.sex),
                Missing_Marital_Status,
                rels,
                Missing_Relationship,
                inc )
        push!( m, p )
        println(inc)
    end
    return m
end


function nearest_in_age( 
    age::Int, 
    allpers :: Vector{MiniPers}, 
    sex :: Sex = Missing_Sex ) :: Int
    minage = 10000000
    targetp = -1
    for p in allpers
        if(p.pid !== pers.pid)&&(!p.is_standard_child)
            if (sex == Missing_Sex) || (p.sex == sex )
                diff = abs(p.age - age )
                if diff < minage
                    minage = diff
                    targetp = p.pno
                end
            end
        end
    end
    targetp
end

function basic_stats( hp :: AbstractDataFrame  ) :: NamedTuple
    (;
    num_adults = size( hp[hp.from_child_record.==0,:])[1],
    num_children = size( hp[hp.from_child_record.==1,:])[1],
    num_females = size( hp[hp.sex.== 2,:])[1],
    num_males = size( hp[hp.sex.== 1,:])[1],
    oldest = maximum( hp.age ),
    youngest = minimum( hp.age ),
    oldest_adult = maximum(  hp[hp.from_child_record.==0,:age] ),
    pos_oldest = findmax( hp[hp.from_child_record.==0,:age])[2],
    highest_earner = findmax( hp[hp.from_child_record.==0,:income_wages])[2],
    highest_wage = findmax( hp[hp.from_child_record.==0,:income_wages])[1],
    youngest_adult = minimum(  hp[hp.from_child_record.==0,:age]))
end

function assign_relationships!(p1::MiniPers, p2::MiniPers, p1states, freqs::AbstractWeights )
    @argcheck size(p1states) == size(freqs)
    @argcheck sum(freqs) ≈ 1
    n = length(p1.relationships)

    println( "p1.relationships[$(p2.pno)] = $(p1.relationships[p2.pno]); p2.relationships[$(p1.pno)]=$(p2.relationships[p1.pno]) ")
    if(p1.relationships[p2.pno] == Missing_Relationship) && 
      (p2.relationships[p1.pno] == Missing_Relationship)
        rel = sample(p1states,freqs)        
        println( "got rel as $rel")
        p1.relationships[p2.pno] = rel
        p2.relationships[p1.pno] = reciprocal_relationship(rel)
        if is_partner( rel ) # note includes cohabitee
            mstat = sample( [Married_or_Civil_Partnership, Cohabiting], weights([0.9,0.1]))
            p1.marital_status = mstat
            p2.marital_status = mstat
        end
    end
end

function assign_adult_relationships!(pers :: Vector{MiniPers}, stats::NamedTuple  )
    for p1 in pers
        for p2 in pers
            print( "checking $(p1.pno) against $(p2.pno)")                
            if (! p1.is_standard_child ) && (! p2.is_standard_child ) && (p1.pno != p2.pno)
                agediff = p1.age - p2.age
                println( "; agediff = $agediff")
                if abs(agediff) < 25 # FIXME I don't follow my own logic here...
                    if ! is_coupled( p1.marital_status ) # already married off?
                        
                        probs = Weights([0.9,0.05,0.05,0,0,0,0,0,0])
                        if p1.sex == p2.sex
                            probs = Weights([0.1,0.1,0.1,0.1,0.1,0.2,0.1,0.1,0.1])
                        end
                        assign_relationships!(p1, p2, 
                            [
                                Spouse, 
                                Cohabitee, 
                                Civil_Partner,
                                Brother_or_sister_incl_adopted,
                                Step_brother_or_sister,
                                Foster_brother_or_sister,
                                Brother_or_sister_in_law,
                                Other_relative, 
                                Other_non_relative                            
                            ], probs )
                    else
                        probs = Weights([0.2,0.2,0.1,0.2,0.1,0.2])
                        assign_relationships!(p1, p2, 
                            [
                                Brother_or_sister_incl_adopted,
                                Step_brother_or_sister,
                                Foster_brother_or_sister,
                                Brother_or_sister_in_law,
                                Other_relative, 
                                Other_non_relative                            
                            ], probs )
                        
                    end
                elseif agediff >= 25 # p1 at least 25 years older than p2
                    # since rels are reciprocal we just need one??
                    assign_relationships!(p1, p2, 
                        [Parent, 
                        Grand_parent,
                        Step_parent,
                        Foster_parent,
                        Parent_in_law,
                        Other_relative, 
                        Other_non_relative ],
                        Weights([0.5,0.1,0.05,0.0,0.05,0.2,0.1]))

                elseif agediff <= -25
                    # same but backwards
                    assign_relationships!(p2, p1, 
                        [Parent, 
                        Grand_parent,
                        Step_parent,
                        Foster_parent,
                        Parent_in_law,
                        Other_relative, 
                        Other_non_relative ],
                        Weights([0.5,0.1,0.05,0.0,0.05,0.2,0.1]))
                end
            end
        end
    end
end

function rel_matrix( pers :: Vector{MiniPers} )::Matrix
    n = length(pers)
    v = fill(Missing_Relationship,n,n)
    pnos = fill(0,n)
    ages = fill(0,n)
    buheads = fill(false,n)
    hhheads = fill(false,n)
    benunits = fill(0,n)
    sexes = fill(Missing_Sex,n)
    ischild = fill(false, n)
    marrstat = fill( Missing_Marital_Status,n)
    incomes = zeros(n)
    r = 0
    for p in pers
        r += 1
        for c in 1:n
            v[r,c] = p.relationships[c]
        end
        pnos[r] = p.pno
        ages[r] = p.age
        sexes[r] = p.sex
        marrstat[r] = p.marital_status
        hhheads[r] = p.is_hrp
        buheads[r] = p.is_benefit_unit_head
        marrstat[r] = p.marital_status
        benunits[r] = p.default_benefit_unit
        ischild[r] = p.is_standard_child
        incomes[r] = p.income
    end
    hcat( pnos, ages, sexes, ischild, benunits, hhheads, buheads, marrstat, incomes, v )
end

function pretty_print( pers :: Vector{MiniPers})
    n = length(pers)
    relations = fill("Rel_",n)
    for i in 1:n
        relations[i] *= "$i"
    end
    header=["pnos", "ages", "sexes", "ischild", "benunits", "hhheads", "buheads", "marrstat", "incomes", relations...]
    pretty_table( rel_matrix(pers), header=header )
end 


function idiotchecks( pers :: Vector{MiniPers} )
    nhrps = 0
    maxbu = -1
    n = length(pers)
    nbu_heads = zeros(n)
    for p in pers 
        if p.is_hrp 
            nhrps += 1
        end
        b = p.default_benefit_unit
        if p.is_benefit_unit_head
            nbu_heads[b] += 1
        end
        maxbu = max(maxbu, b )
        @assert all(m->m !=Missing_Relationship, p.relationships )
        @assert p.default_benefit_unit > 0
        if ! p.is_standard_child
            @assert p.marital_status != Missing_Marital_Status
        end
        @assert p.relationship_to_hoh != Missing_Relationship
    end
    @assert nhrps == 1
    @assert maxbu >= 1
    @assert all( b->b==1, nbu_heads[1:maxbu])
end

function married_to( pers :: MiniPers )::Int
    n = length(pers.relationships)
    for i in 1:n
        if is_partner(pers.relationships[i])
            return i
        end
    end
    return -1;
end

function assign_ben_units!(pers :: Vector{MiniPers}, stats::NamedTuple  )
    n = length(pers)
    @show stats
    if stats.num_children > 0
        if stats.num_adults == 1
            pers[1].default_benefit_unit = 1
        elseif(stats.num_adults == 2) && (is_coupled(pers[1].marital_status))
            pers[1].default_benefit_unit = 1
            pers[2].default_benefit_unit = 1
        else
            p = nearest_in_age( 40, pers )
            pers[p].default_benefit_unit = 1
            if is_coupled(pers[p].marital_status)
                q = married_to( pers[p])
                pers[q].default_benefit_unit = 1
            end
        end
        for i in 1:n
            if pers[i].is_standard_child 
                pers[i].default_benefit_unit = 1
            end
        end
        i = 0
        bno = 2
        while i < n
            i += 1
            if pers[i].default_benefit_unit < 0
                pers[i].default_benefit_unit = bno
                q = married_to( pers[i])
                if q > 0
                    pers[q].default_benefit_unit = bno
                end
                bno += 1
            end
        end
    else
        bno = 1
        for i in 1:n
            if pers[i].default_benefit_unit < 0
                pers[i].default_benefit_unit = bno
                q = married_to( pers[i])
                if q > 0                
                    pers[q].default_benefit_unit = bno
                 end
                bno += 1
            end
        end
    end
end

"""
If A is child of B, and C is child of B, B and C are siblings
"""
function relationship_from_rel1( r1::Relationship, r2::Relationship )::Relationship
    @argcheck is_dependent_child(r1) && is_dependent_child(r2)
    if r1 == Son_or_daughter_incl_adopted
        return if r2 == Son_or_daughter_incl_adopted
            Brother_or_sister_incl_adopted
        elseif r2 == Foster_child
            Foster_brother_or_sister
        elseif r2 == Step_son_or_daughter
            Step_brother_or_sister
        end
    elseif r1 == Step_son_or_daughter
        return if r2 == Son_or_daughter_incl_adopted
            Step_brother_or_sister
        elseif r2 == Foster_child
            Foster_brother_or_sister
        elseif r2 == Step_son_or_daughter
            Brother_or_sister_incl_adopted            
        end
    elseif r1 == Foster_child
        return if r2 == Son_or_daughter_incl_adopted
            Foster_brother_or_sister
        elseif r2 == Foster_child
            Brother_or_sister_incl_adopted                        
        elseif r2 == Step_son_or_daughter
            Step_brother_or_sister
        end
    end
end

function assign_heads!( pers :: Vector{MiniPers}, stats::NamedTuple)
    hrp = if stats.highest_wage > 0 # fixme not wage
        stats.highest_earner
    else
        stats.pos_oldest
    end
    println("hrp=$hrp")
    pers[hrp].is_hrp = true
    # allocate bu heads on income and then age 
    # next is 1 line using a dataframe, but hey ho.
    n = length(pers)
    maxbu = zeros(n,4)
    nbu = 0
    for p in pers
        if ! p.is_standard_child
            b = p.default_benefit_unit
            if p.age > maxbu[b,2]
                maxbu[b,1] = p.pno
                maxbu[b,2] = p.age
            end
            if p.income > maxbu[b,4]
                maxbu[b,3] = p.pno
                maxbu[b,4] = p.income
            end
            nbu = max(b,nbu)
        end
        p.relationship_to_hoh = p.relationships[hrp] # no real need for this 
    end
    pretty_table(maxbu)
    for b in 1:nbu 
        buh = Int(if maxbu[b,4] > 0
            maxbu[b,3]
        else
            maxbu[b,1]
        end)
        pers[buh].is_benefit_unit_head = true
    end
    
end

#=
@enum Marital_Status begin  # mapped from marital
    Missing_Marital_Status = -1
    Married_or_Civil_Partnership = 1
    Cohabiting = 2
    Single = 3
    Widowed = 4
    Separated = 5
    Divorced_or_Civil_Partnership_dissolved = 6
 end
 =#

function assign_marital_statuses!( pers :: Vector{MiniPers}, stats::NamedTuple)
    for p in pers
        if (! p.is_standard_child) && (p.marital_status == Missing_Marital_Status)
            w = if p.age < 40
                [0.7,0.1,0.1,0.1]
            elseif p.age < 70
                [0.6,0.2,0.1,0.1]
            else
                [0.4,0.4,0.1,0.1]
            end
            p.marital_status = sample( 
                [Single, Widowed, Separated, Divorced_or_Civil_Partnership_dissolved], 
                weights(w))
        end
    end
end

"""
All children in bu 1. All adults in bu 1
"""
function assign_child_relationships!(pers :: Vector{MiniPers}, stats::NamedTuple )
    n = length(pers)
    parents = []
    children = [] 
    non_family = []
    for p in pers
        if p.default_benefit_unit == 1 
            if p.is_standard_child
                push!( children, p.pno )
            else
                push!( parents, p.pno )
            end
        else
            push!( non_family, p.pno )
        end
    end 
    # fill out parents relationships with each child
    for cn in children
        child = pers[cn]
        child.relationships[cn] = This_Person
        for pn in parents
            parents_relationship_to_child = sample( [
                Parent,
                Foster_parent,
                Step_parent], 
                weights( [0.95, 0.025, 0.025 ]))
            parent = pers[pn]
            parent.relationships[cn] = parents_relationship_to_child
        end
    end
    println( "parents = $parents children=$children non_family=$non_family")
    # child->parent
    for cn in children
        child = pers[cn]
        for pn in parents
            parent = pers[pn]
            child.relationships[pn] = reciprocal_relationship(parent.relationships[cn])
        end
    end

    # child->child
    parent = pers[parents[1]]
    for c1 in children
        child1 = pers[c1]
        for c2 in children
            child2 = pers[c2]
            if c1 != c2 
                child1.relationships[c2] = reciprocal_relationship(parent.relationships[c1])
                child2.relationships[c1] = child1.relationships[c2]
            end
        end
    end

    #=
    for nf in non_family
        nfp = pers[nf]
        for cn in children
            child = pers[cn]
            #nfp.relationships[cn] = 
        end
    end
    =#

    # child -> child relationships, from 1st col which should always be rel to bu head
    reltop1 = []
    buhead = parents[1]
    for p in pers
        push!( reltop1, p.relationships[buhead])
    end
    for i in 1:n
        for j in 1:n
            if i != j
                if is_dependent_child(reltop1[i])&&(is_dependent_child(reltop1[j]))
                    rel = relationship_from_rel1( reltop1[i], reltop1[j] )
                    pers[i].relationships[j] = rel
                end
            end
        end
    end

    for nf in non_family
        for cn in children
            rel1 = pers[cn].relationships[buhead]
            rel2 = pers[nf].relationships[buhead]
            println( "rel1=$rel1 rel2=$rel2")
            nfrel = one_generation_relationship( 
                relationship_to_parent=rel1, 
                parents_relationship_to_person=rel2)
            pers[nf].relationships[cn] = nfrel
            pers[cn].relationships[nf] = reciprocal_relationship(nfrel)
        end
    end
end

function writeback!( hp :: AbstractDataFrame, pers  :: Vector{MiniPers})
@argcheck size(hp)[1] == length(pers)
    n = length(pers)
    i = 0
    for r in eachrow( hp )
        i += 1
        p = pers[i]

        @assert r.hid == p.hid "r.hid = $(r.hid) != p.pid=$(p.hid)"
        r.pid = p.pid
        r.pno = p.pno
        r.is_hrp = p.is_hrp ? 1 : 0
        r.default_benefit_unit = p.default_benefit_unit
        r.is_bu_head = p.is_benefit_unit_head
        @assert r.from_child_record == p.is_standard_child 
        @assert r.age == p.age
        @assert Sex(r.sex) == p.sex
        r.marital_status = Int( p.marital_status )
        for k in 1:15
            rs = Symbol( "relationship_$k")
            if eltype( hp[!,rs]) !== Missing # skip all missing vectors
                r[rs] = -1
            end
        end
        for k in 1:n
            rs = Symbol( "relationship_$k")
            r[rs] = Int(p.relationships[k])
        end
        r.relationship_to_hoh = Int(p.relationship_to_hoh)
    end
end 

function fixup_one_family!( h :: DataFrameRow, hp :: AbstractDataFrame )
    sort!( hp, [:age, :from_adult_record],rev=true)
    pers = all_mini_pers( h, hp )
    stats = basic_stats( hp )
    assign_adult_relationships!( pers, stats )
    assign_ben_units!( pers, stats )
    pretty_print( pers )
    if stats.num_children > 0
        assign_child_relationships!(pers,stats)
    end
    assign_marital_statuses!(pers,stats)
    assign_heads!(pers,stats)
    pretty_print( pers )
    idiotchecks( pers )
    writeback!( hp, pers )
end

function fixall!( hhs :: DataFrame, pers :: DataFrame )
    nps = size(hhs)[1]
    hh_pers = groupby( pers, [:hid])
    pers.from_adult_record = pers.from_child_record .== false
    # nps = 5
    for hid in 1:nps
        thishh = hh[hh.hid.==hid,:][1,:]
        fixup_one_family!( thishh, hh_pers[hid] )
    end
end

function overwrite_all( hp :: AbstractDataFrame )
    # 1 
end
