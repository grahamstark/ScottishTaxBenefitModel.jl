module IndirectTaxes

using CSV,DataFrames,StatsBase

using ScottishTaxBenefitModel
using .GeneralTaxComponents
using .RunSettings

IND_MATCHING = DataFrame()
EXPENDITURE_DATASET = DataFrame()


function init( settings :: Settings )
    if settings.indirect_method == matching
        IND_MATCHING = CSV.File( "$(settings.data_dir)/$(settings.indirect_matching_dataframe).tab") |> DataFrame
        EXPENDITURE_DATASET = CSV.File("$(settings.data_dir)/$(settings.expenditure_dataset).tab" ) |> DataFrame
    end
end


end