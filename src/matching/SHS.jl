module SHS
using ..Common 
import ..Model

using ScottishTaxBenefitModel
using .RunSettings
using .Definitions

import ScottishTaxBenefitModel.MatchingLibs.Common

using CSV,
    DataFrames,
    Measures,
    StatsBase,
    ArgCheck

function loadshs( year::Int )::DataFrame
    year -= 2000
    ystr = "$(year)$(year+1)"
    fname = "$(DIR)/shs/$(ystr)/tab/shs20$(year)_social_public.tab"
    println( "loading '$fname'" )

    shs = CSV.File( fname; 
        missingstring=["NA",""],normalizenames=true,
        types=Dict(:UNIQIDNEW=>String)) |> DataFrame
    lcnames = Symbol.(lowercase.(string.(names(shs))))
rename!(shs,lcnames)
shs[!,:datayear] .= year
return shs
end


"""
Stack scottish household surveys. 
"""
function create_shs( years :: UnitRange ) :: DataFrame
    n = length(years)
    shs = Array{DataFrame}(undef,n)
    i = 0
    for year in years
        i += 1
        shs[i] = loadshs(year)
    end
    return vcat( shs...; cols=:intersect )
end

end