using ScottishTaxBenefitModel

using .LegalAidData
using .RunSettings
using .FRSHouseholdGetter

using StatsBase
using CSV
using DataFrames

include( "comparisons_skeleton.jl")

settings = Settings()
LegalAidData.init( settings )

settings.num_households, settings.num_people, nhh2 = 
    FRSHouseholdGetter.initialise( settings; reset=false )

const N = size( CIVIL_COSTS)[1]
const GROUPS_BY_CASE = groupby( CIVIL_COSTS, :hsm_censored )

function civ_sample( casetype :: String )::DataFrameRow
    p = sample(1:N)
    return CIVIL_COSTS[p]
    #sample(CIVIL_COSTS[CIVIL_COSTS.hsm_censored .== casetype,:]

end

for hno in 1:settings.num_households
    hh = get_household( hno )
    LegalAidData.add_la_probs!( hh )
    reps = Int( round( hh.weight ))
    for i in 1:reps
        for (pid, pers) in hh.people
            for problem in PROBLEM_TYPES
                sym = Symbol( "$(prefix)_prediction")
                prob = legal_aid_problem_probs[sym]
                if rand() < prob
                    case = civ_sample( [problem])
                end
            end # problem 
        end # people
    end
end

