module BenefitGenerosity
#
# This module provides a simple way of modelling
# the generosity of the tests for PIP,DLA and AA & their Scottish replacements.
# see also the benefit regressions in tge `regressions/`
# folder, and the blog post. For a less generous test, the recipient people with the lowest probs in 
# the regressions are removed, for more generous the non-recipients
# with the highest modelled probs are added.
# 
# This is crazily over/under designed and needs re-doing
# Je n'ai fait celle-ci plus longue que parce que je n'ai pas eu le loisir de la faire plus courte.
#
using ScottishTaxBenefitModel
using .ModelHousehold: OneIndex,Person,Household
using .Definitions
using .STBIncomes
using .STBParameters: NonMeansTestedSys
using .RunSettings: Settings
using .FRSHouseholdGetter: get_household_of_person
using DataFrames, CSV 
using ArgCheck

export initialise, to_set, adjust_disability_eligibility!, change_status

struct GenEntry # FIXME make a concrete type {T} ???
    cum_popn :: Real
    pid      :: BigInt
    data_year :: Int
end

const GenVec = Vector{GenEntry}

struct DisabilityChanges
    which  :: Incomes
    is_positive  :: Bool
    people :: Set{OneIndex}
end

#
# FIXME re-arrange to make this immutable
#
mutable struct EntryWrapper
    negative_candidates_aa::GenVec
    negative_candidates_pip_mob::GenVec   
    positive_candidates_pip_care::GenVec
    negative_candidates_dla_children::GenVec
    positive_candidates_aa::GenVec
    positive_candidates_pip_mob::GenVec
    negative_candidates_pip_care::GenVec
    positive_candidates_dla_children::GenVec
end

const ENTRIES = EntryWrapper(
    GenVec(),
    GenVec(),
    GenVec(),
    GenVec(),
    GenVec(),
    GenVec(),
    GenVec(),
    GenVec()
)

function load_one( filename :: String ) :: GenVec
    d = CSV.File( filename ) |> DataFrame
    n = size(d)[1]
    gv = Vector{GenEntry}(undef, n)
    popn = 0.0
    for i in 1:n
        r = d[i,:]        
        hh = get_household_of_person( BigInt(r.pid), r.data_year )
        if hh !== nothing
            popn += hh.weight
            gv[i] = GenEntry( popn, BigInt(r.pid), r.data_year )            
        else
            println( "no such hh $(r.pid) $(r.data_year)")
        end
    end    
    return gv
end

function initialise( dir :: String )
    ENTRIES.negative_candidates_aa = load_one( "$dir/negative_candidates_aa.csv" )
    ENTRIES.negative_candidates_pip_mob = load_one( "$dir/negative_candidates_pip_mob.csv" )
    ENTRIES.positive_candidates_pip_care = load_one( "$dir/positive_candidates_pip_care.csv" )
    ENTRIES.negative_candidates_dla_children = load_one( "$dir/negative_candidates_dla_children.csv" )
    ENTRIES.positive_candidates_aa = load_one( "$dir/positive_candidates_aa.csv" )
    ENTRIES.positive_candidates_pip_mob = load_one( "$dir/positive_candidates_pip_mob.csv" )
    ENTRIES.negative_candidates_pip_care = load_one( "$dir/negative_candidates_pip_care.csv" )
    ENTRIES.positive_candidates_dla_children = load_one( "$dir/positive_candidates_dla_children.csv" )
end

function make_one_set( extra_people::Number, candidates :: GenVec ) :: Set{OneIndex}
    s = Set{OneIndex}()
    for c in candidates
        if c.cum_popn >= extra_people
            break
        end
        push!(s, OneIndex( c.pid, c.data_year ))
    end
    return s
end
#
# FIXME just merge with the thing below
#
function to_set( which :: Incomes, extra_people :: Real ) :: Set{OneIndex}
    @argcheck which in SICKNESS_ILLNESS
    s = Set{OneIndex}()
    if extra_people > 0
        if which == ATTENDANCE_ALLOWANCE
            return make_one_set( extra_people, ENTRIES.positive_candidates_aa )
        elseif which == PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING
            return make_one_set( extra_people, ENTRIES.positive_candidates_pip_care )
        elseif which == PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY
            return make_one_set( extra_people, ENTRIES.positive_candidates_pip_mob )
        elseif which == DLA_SELF_CARE || which == DLA_MOBILITY
            return make_one_set( extra_people, ENTRIES.positive_candidates_dla_children )
        end
    elseif extra_people < 0
        if which == ATTENDANCE_ALLOWANCE
            return make_one_set( -1*extra_people, ENTRIES.negative_candidates_aa )
        elseif which == PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING
            return make_one_set( -1*extra_people, ENTRIES.negative_candidates_pip_care )
        elseif which == PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY
            return make_one_set( -1*extra_people, ENTRIES.negative_candidates_pip_mob )
        elseif which == DLA_SELF_CARE || which == DLA_MOBILITY
            return make_one_set( -1*extra_people, ENTRIES.negative_candidates_dla_children )
        end
    end
    return s
end

function adjust_disability_eligibility!( nmt_bens :: NonMeansTestedSys )
    nmt_bens.attendance_allowance.candidates = to_set(  ATTENDANCE_ALLOWANCE, nmt_bens.attendance_allowance.extra_people )
    nmt_bens.dla.candidates= to_set( DLA_SELF_CARE, nmt_bens.dla.extra_people )
    nmt_bens.pip.dl_candidates = to_set( PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING, nmt_bens.pip.extra_people )
    nmt_bens.pip.mobility_candidates = to_set( PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY, nmt_bens.pip.extra_people )
end


function change_status(
    ; 
    candidates::Set{OneIndex}, 
    pid::BigInt, 
    change ::Real,
    choices,
    current_value,
    disqual_value )
    if change == 0
        return current_value
    elseif ! in_indexes( candidates, pid )
        return current_value
    else
        if change < 0
            return disqual_value
        else
            return rand(choices)
        end
    end
end


end
