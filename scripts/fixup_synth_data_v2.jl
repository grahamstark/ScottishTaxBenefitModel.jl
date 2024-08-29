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
                0.0 )
        push!( m, p )
        
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
            p1.marital_status = Married_or_Civil_Partnership
            p2.marital_status = Married_or_Civil_Partnership
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
                if abs(agediff) < 25
                    if p1.marital_status != Married_or_Civil_Partnership
                        probs = Weights([1,0,0,0,0,0,0,0,0])
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
                    assign_relationships!(p1, p2, 
                        [Parent, 
                        Grand_parent,
                        Step_parent,
                        Foster_parent,
                        Parent_in_law,
                        Other_relative, 
                        Other_non_relative ],
                        Weights([1,0,0,0,0,0,0]))

                elseif agediff <= -25
                    assign_relationships!(p1, p2, 
                        [Foster_child,
                        Step_son_or_daughter,
                        Son_or_daughter_incl_adopted,
                        Other_relative, 
                        Other_non_relative ],
                        Weights([0,0,0,0.5,0.5]))
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
    benunits = fill(0,n)
    sexes = fill(Missing_Sex,n)
    ischild = fill(false, n)
    r = 0
    for p in pers
        r += 1
        for c in 1:n
            v[r,c] = p.relationships[c]
        end
        pnos[r] = p.pno
        ages[r] = p.age
        sexes[r] = p.sex
        benunits[r] = p.default_benefit_unit
        ischild[r] = p.is_standard_child
    end
    hcat( pnos, ages, sexes, ischild, benunits, v )
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
        elseif(stats.num_adults == 2) && (pers[1].marital_status == Married_or_Civil_Partnership)
            pers[1].default_benefit_unit = 1
            pers[2].default_benefit_unit = 1
        else
            p = nearest_in_age( 40, pers )
            pers[p].default_benefit_unit = 1
            if pers[p].marital_status == Married_or_Civil_Partnership
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
#=

   Step_son_or_daughter = 4
   Foster_child = 5
   Son_in_law_or_daughter_in_law = 6
   Parent = 7
   Step_parent = 8
   Foster_parent = 9
   Parent_in_law = 10
   Brother_or_sister_incl_adopted = 11
   Step_brother_or_sister = 12
   Foster_brother_or_sister = 13
   Brother_or_sister_in_law = 14
   Grand_child = 15
   Grand_parent = 16
   Other_relative = 17
   Other_non_relative = 18
   Civil_Partner = 20
   
=#


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
    for nf in non_family
        nfp = pers[nf]
        for cn in children
            child = pers[cn]
            #nfp.relationships[cn] = 
        end
    end

    pretty_table( rel_matrix(pers) )

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

    #=    
        # non 1st bu people. Nearest they can be is sibling, then othen
        for nf in non_family
            nfp = pers[nf]
            # brother of the parent => Other_relative of parent's child
            is_rel_of_parent = false
            rel_to_bu_1 = []
            for pn in parents
                if is_dependent_child( nfp.relationships[pn] )
                    push!(rel_to_bu_1, pn )
                elseif is_non_relative(nfp.relationships[pn])
                    is_rel_of_parent = true
                end
            end
            nfp.relationships[cn] = 
            if length(rel_to_bu_1)>0  # 2nd is son of bu1 head, etc
                one_generation_relationship( ; 
                    relationship_to_parent = nfp.relationships[1],
                    parents_relationship_to_person = child.relationships[nf])
            elseif is_rel_of_parent 
                Other_non_relative
            else
                Other_non_relative
            end
        end
    end
    =#
    # non bu relationships
end


function writeback!( hp :: AbstractDataFrame, pers  :: Vector{MiniPers})

end 

function fixup_one_family!( h :: DataFrameRow, hp :: AbstractDataFrame )
    sort!( hp, [:age, :from_adult_record],rev=true)
    pers = all_mini_pers( h, hp )
    stats = basic_stats( hp )
    assign_adult_relationships!( pers, stats )
    assign_ben_units!( pers, stats )
    pretty_table( rel_matrix(pers) )
    if stats.num_children > 0
        assign_child_relationships!(pers,stats)
    end
    pretty_table( rel_matrix(pers) )
    writeback!( hp, pers )
end

function fixall!( hhs :: DataFrame, pers :: DataFrame )
    nps = size(hhs)[1]
    hh_pers = groupby( pers, [:hid])
    pers.from_adult_record = pers.from_child_record .== false
    # nps = 12
    for hid in 1:nps
        thishh = hh[hh.hid.==hid,:][1,:]
        fixup_one_family!( thishh, hh_pers[hid] )
    end
end

function overwrite_all( hp :: AbstractDataFrame )
    # 1 
end

