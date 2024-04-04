#
# FIXME maybe amalgamate into an "ExtraData" module??
# 
module LegalAidData

using CSV,DataFrames,CategoricalArrays

using ScottishTaxBenefitModel
using .RunSettings
using .Definitions
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
    rename!( awards, [:consolidatedsex=>:sex,:age_banded=>:age])
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
    rename!( cost, [:highersubject=>:hsm,:age_banded=>:age])
    cost.passported = .! ismissing.( cost.passported )
    cost.maxcon = coalesce.(cost.maxcon, 0.0 )
    cost
end

const CIVIL_COSTS = load_costs( joinpath(MODEL_DATA_DIR, "civil-legal-aid-case-costs.tab" ))
const CIVIL_COSTS_GRP = groupby(CIVIL_COSTS, [:hsm,:age,:sex])
const CIVIL_AWARDS = load_awards( joinpath(MODEL_DATA_DIR, "civil-applications.tab" ))
const CIVIL_AWARDS_GRP = groupby(CIVIL_AWARDS, [:hsm,:age,:sex])
#= 
  psa = groupby(awards, [:hsm,:age_banded,:consolidatedsex])
  k=(hsm = "Discrimination", age_banded = "5 - 9", consolidatedsex = "Male")
  psa[k]
  haskey(psa,k)
  for( k, v ) in pairs( psa )
   println( "k=$k ")
  end
=#

function agestr( age :: Int ) :: String
    return if age < 5
        "0 - 4"
    elseif age < 10
        "5 - 9"
    elseif age < 15
        "10 - 14"
    elseif age < 20
        "15 - 19"
    elseif age < 25
        "20 - 24"
    elseif age < 30
        "25 - 29"
    elseif age < 35
        "30 - 34"
    elseif age < 40
        "35 - 39"
    elseif age < 45
        "40 - 44"
    elseif age < 50
        "45 - 49"
    elseif age < 55
        "50 - 54"
    elseif age < 60
        "55 - 59"
    elseif age < 65
        "60 - 64"
    elseif age < 70
        "65 - 69"
    elseif age < 75
        "70 - 74"
    elseif age < 80
        "75 - 79"
    elseif age < 85
        "80 - 84"
    elseif age >= 85
        "85 and above"
    end
end

function get_awards( hsm :: String, age :: Int, sex :: Sex )
    k = (hsm=hsm, age_banded=agestr(age), consolidatedsex=string(sex))
    CIVIL_AWARDS_GRP[k]
end

function get_costs( hsm :: String, age :: Int, sex :: Sex )
    k = (highersubject=hsm, age_banded=agestr(age), sex=string(sex))
    CIVIL_COSTS_GRP[k]
end



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