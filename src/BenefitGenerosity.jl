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
positive_candidates_any_disability_working_age.tab

#
# FIXME re-arrange to make this immutable
#
mutable struct EntryWrapper
    negative_candidates_any_disability_working_age::GenVec
    negative_candidates_any_disability_pensioners::GenVec   
    positive_candidates_care_working_age::GenVec
    negative_candidates_care_pensioners::GenVec
    positive_candidates_any_disability_working_age::GenVec
    positive_candidates_any_disability_pensioners::GenVec   
    positive_candidates_care_working_age::GenVec
    positive_candidates_care_pensioners::GenVec
    child_disabilities_ranked::GenVec
end

const ENTRIES = EntryWrapper(
    GenVec(),
    GenVec(),
    GenVec(),
    GenVec(),
    GenVec(),
    GenVec(),
    GenVec(),
    GenVec(),
    GenVec())

"""
This loads one of the sets of candidates for inclusion or exclusion from
one of our disabililty benefits
"""
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
            # println( "no such hh $(r.pid) $(r.data_year)")
        end
    end    
    return gv
end

function initialise( dir :: String )
    ENTRIES.negative_candidates_any_disability_working_age = load_one( "$dir/negative_candidates_any_disability_working_age.tab")
    ENTRIES.negative_candidates_any_disability_pensioners = load_one( "$dir/negative_candidates_any_disability_pensioners.tab")   
    ENTRIES.negative_candidates_any_carers_all_adults = load_one( "$dir/negative_candidates_any_carers_all_adults.tab")
    ENTRIES.positive_candidates_any_disability_working_age = load_one( "$dir/positive_candidates_any_disability_working_age.tab")
    ENTRIES.positive_candidates_any_disability_pensioners = load_one( "$dir/positive_candidates_any_disability_pensioners.tab")   
    ENTRIES.positive_candidates_any_carers_all_adults = load_one( "$dir/positive_candidates_any_carers_all_adults")
    ENTRIES.child_disabilities_ranked = load_one( "$dir/child_disabilities_ranked.tab")
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

#=
"""
This loads a set of OneIndexes with just enough people to qualify or disqualify
`extra_people` from the given benefit `which`
"""
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
=#

"""
FIXME how do to children
"""
function select_candidates(; extra_people :: Real, is_care::Bool, cgroup :: DisabilityGroup ):: Set{OneIndex}
    return if is_care
        @assert cgroup == dis_all_adults
        if extra_people > 0
            make_one_set( extra_people, ENTRIES.positive_candidates_any_carers_all_adults )
        else
            make_one_set( -1*extra_people, ENTRIES.negative_candidates_any_carers_all_adults )
        end
    else
        @assert cgroup in [dis_all_working_age, dis_pensioners]
        if extra_people > 0
            if cgroup == dis_working_age
                make_one_set( extra_people, ENTRIES.positive_candidates_care_working_age )
            else
                make_one_set( extra_people, ENTRIES.positive_candidates_care_pensioners )
            end
        else
            if cgroup == dis_working_age
                make_one_set( -1*extra_people, ENTRIES.negative_candidates_care_working_age )
            else
                make_one_set( -1*extra_people, ENTRIES.negative_candidates_any_care_pensioners )
            end
        end
    end
end

function adjust_disability_eligibility!( nmt_bens :: NonMeansTestedSys )
    nmt_bens.attendance_allowance.candidates = select_candidates(;
        extra_people=nmt_bens.attendance_allowance.extra_people,
        is_care = false,
        cgroup = dis_pensioners )
    #= FIXME CHILDREN select_candidates(;
        nmt_bens.dla.candidates = 0.0
            extra_people=nmt_bens.attendance_allowance.extra_people,
            is_care = false,
            cgroup = dis_pensioners ) 
    =#
    nmt_bens.pip.mobility_candidates = select_candidates(;
        extra_people=nmt_bens.pip.extra_people,
        is_care = false,
        cgroup = dis_working_age )
    nmt_bens.pip.dl_candidates = select_candidates(;
        extra_people=nmt_bens.pip.extra_people,
        is_care = false,
        cgroup = dis_working_age )
    nmt_bens.carers.candidates = select_candidates(;
        extra_people=nmt_bens.carers.extra_people,
        is_care = true,
        cgroup = dis_dis_all_adults )
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
end # change_status

end # module