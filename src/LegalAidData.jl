#
# FIXME maybe amalgamate into an "ExtraData" module??
# 
module LegalAidData

using CSV,DataFrames

using ScottishTaxBenefitModel
using .RunSettings
using .ModelHousehold

export add_la_probs!

LA_PROB_DATA = DataFrame()

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