module BenefitGenerosity

using ScottishTaxBenefitModel
using .ModelHousehold: OneIndex,Person,Household
using .Definitions
using .STBIncomes
using .RunSettings: Settings

using DataFrames, CSV 
export 
    intialise

struct GenEntry # FIXME make a concrete type {T} ???
    cum_popn :: Real
    pid      :: BigInt
    datayear :: Int
end

const GenVec = Vector{GenEntry}

struct DisabilityChanges
    which  :: Incomes
    is_positive  :: Bool
    people :: Set{OneIndex}
end

struct EntryWrapper
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

function load_one!( gv :: GenVec, filename:: String )
    d = CSV.File( filename ) |> DataFrame
    n = size(d)[1]
    gv = GenVec(undef, n)
    pop = 0.0
    for i in 1:n
        r = d[i,:]        
        hh = get_household_of_person( r.pid, r.datayear )
        pop += hh.weight
        gv[i].cum_popn = pop
        gv[i].pid = r.pid
        gv[i].data_year = r.data_year
    end
end

function intialise( data_dir :: String )
    dir = "$data_dir/disability/"
    load_one( ENTRIES.negative_candidates_aa, "negative_candidates_aa.csv" )
    load_one( ENTRIES.negative_candidates_pip_mob, "negative_candidates_pip_mob.csv" )
    load_one( ENTRIES.positive_candidates_pip_care, "positive_candidates_pip_care.csv" )
    load_one( ENTRIES.negative_candidates_dla_children, "negative_candidates_dla_children.csv" )
    load_one( ENTRIES.positive_candidates_aa, "positive_candidates_aa.csv" )
    load_one( ENTRIES.positive_candidates_pip_mob, "positive_candidates_pip_mob.csv" )
    load_one( ENTRIES.negative_candidates_pip_care, "negative_candidates_pip_care.csv" )
    load_one( ENTRIES.positive_candidates_dla_children, "positive_candidates_dla_children.csv" )
end

function to_sets( extra_people :: Dict{Incomes,Real} ) :: Dict

end

end