#
# FIXME maybe amalgamate into an "ExtraData" module??
# 
module LegalAidData

using CSV,DataFrames,CategoricalArrays

using ScottishTaxBenefitModel
using .RunSettings
using .ModelHousehold

export LA_PROB_DATA, PROBLEM_TYPES

LA_PROB_DATA = DataFrame()

const PROBLEM_TYPES = 
    ["no_problem",
    "divorce",
    "home",
    "money",
    "unfairness",
    "neighbours",
    "employment"]

const ESTIMATE_TYPES = ["lower","prediction","upper"]

function load_awards( filename::String )::DataFrame
    awards = CSV.File( filename; missingstring=["#NULL!","","-"] )|>DataFrame
    nrows,ncols = size( awards )
    rename!( awards, lowercase.( names(awards)))
    println( names( awards ))
    for t in [
        :primary_category,
        :hsm,
        :case_status,
        :with_certificate,
        :age_banded,
        :consolidatedsex,
        :whichform]
        awards[:,t] = CategoricalArray( awards[:,t] )
    end
    awards
end

function load_costs( filename::String )::DataFrame
    cost = CSV.File( filename; missingstring=["#NULL!","","-"] )|>DataFrame
    nrows,ncols = size( cost )
    rename!( cost, lowercase.( names(cost)))
    for t in [
        :highersubject,
        :aidtype,
        :appcode,
        :categorydescription,
        :highersubject,
        :sex,
        :catecode,  
        :whichform ]
        cost[:,t] = CategoricalArray( cost[:,t] )
    end
    cost.passported = .! ismissing.( cost.passported )
    cost.maxcon = coalesce.(cost.maxcon, 0.0 )
    cost
end

# psa = groupby(awards, [:hsm,:age_banded,:consolidatedsex])

# NOT NEEDED
function add_la_probs!( hh :: Household )
    global LA_PROB_DATA
    la_hhdata = LA_PROB_DATA[ (LA_PROB_DATA.data_year .== hh.data_year) .& (LA_PROB_DATA.hid.==hh.hid),: ]
    for (pid, pers ) in hh.people
        pdat = la_hhdata[la_hhdata.pid .== pers.pid,:]
        @assert size(pdat)[1] == 1
        pers.legal_aid_problem_probs = pdat[1,:]
    end
end

function init( settings::Settings; reset=false )
    global LA_PROB_DATA
    if settings.do_legal_aid 
        if(size( LA_PROB_DATA )[1] == 0) || reset 
            LA_PROB_DATA = CSV.File( "$(settings.data_dir)/$(settings.legal_aid_probs_data).tab")|>DataFrame 
        end
    end
end

end # module