#=
    
This module holds both the data for indirect tax calculations. Quickie pro tem thing
for Northumberland, but you know how that goes..

=#
module ConsumptionData

using ArgCheck
using CSV
using DataFrames
using StatsBase
using LazyArtifacts

using ScottishTaxBenefitModel
using .Definitions
using .GeneralTaxComponents
using .ModelHousehold
using .RunSettings
using .Uprating

SHS_DATASET = DataFrame() 
IND_MATCHING = DataFrame()

"""
Match in the lcf data using the lookup table constructed in 'matching/lcf_frs_matching.jl'
'which' best, 2nd best etc match (<=20)
"""
function find_shs_for_hh!( hh :: Household, settings :: Settings, which = -1 )
    @argcheck which <= 20
    match = IND_MATCHING[(IND_MATCHING.frs_datayear .== hh.data_year) .& 
        (IND_MATCHING.frs_sernum .== hh.hid),:][1,:]
    lcf_case_sym, lcf_datayear_sym = if which > 0      
         Symbol( "hhid_$(which)" )
         Symbol( "datayear_$(which)")
    else 
        :default_hhld
        :default_datayear    
    end
    case = match[lcf_case_sym]
    datayear = match[lcf_datayear_sym]
    hh.shsdata = SHS_DATASET[(SHS_DATASET.uniqidnew .== case).&(SHS_DATASET.datayear.==datayear),:][1,:]
    hh.council = hh.shsdata.council
    hh.nhs_board = hh.shsdata.health_board
end


"""
FIXME This is bad design:
* England?
* we should have the default LA in somehow
"""
function init( settings :: Settings; reset = false )
    if settings.do_indirect_tax_calculations 
        if(settings.indirect_method == matching) && (reset || (size(EXPENDITURE_DATASET)[1] == 0 )) # needed but uninitialised
            global IND_MATCHING
            global EXPENDITURE_DATASET
            c_artifact = RunSettings.get_artifact(; 
                name="data", 
                source=settings.data_source == SyntheticSource ? "synthetic" : "shs", 
                scottish=settings.target_nation == N_Scotland )
            IND_MATCHING = CSV.File( joinpath( c_artifact, "matches.tab" )) |> DataFrame
            SHS_DATASET = CSV.File( joinpath( c_artifact, "dataset.tab")) |> DataFrame
            SHS_DATA.lad_2017 = Symbol.( SHS_DATA.lad_2017 )
            SHS_DATA.health_board = Symbol.( SHS_DATA.health_board )            
        end
    end
end


end # module
