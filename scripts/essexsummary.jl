
using ScottishTaxBenefitModel
using .Definitions
using .FRSHouseholdGetter
using .HouseholdFromFrame
using .Intermediate
using .ModelHousehold
using .RunSettings
using .STBParameters
using .DataSummariser
using .Weighting

using CSV,DataFrames,StatsBase,DataStructures

"""

"""
function do_one_summary_set(;
    use_essex_years :: Bool,
    use_essex_weights :: Bool,
    do_matching :: Bool )    
    settings = Settings()
    settings.do_legal_aid = false
    settings.use_shs = true
    if use_essex_years
        settings.included_data_years = [2019,2021,2022]
        settings.upper_multiple=9 # doesn't converge with 7 with just these 3 years
    end
    settings.weighting_strategy = use_essex_weights ? use_precomputed_weights : use_runtime_computed_weights
    if do_matching 
        settings.indirect_method = matching
        settings.wealth_method = matching
    else 
        settings.indirect_method = no_method
        settings.wealth_method = no_method
    end
    # dup load but hard to avoid..
    dataset_artifact = get_data_artifact( Settings() )
    hhs = HouseholdFromFrame.read_hh( 
        joinpath( dataset_artifact, "households.tab")) # CSV.File( ds.hhlds ) |> DataFrame
    people = HouseholdFromFrame.read_pers( 
        joinpath( dataset_artifact, "people.tab"))
    sys = STBParameters.get_default_system_for_fin_year( 2024 )
    settings.num_households, settings.num_people, nhhs2 = 
        FRSHouseholdGetter.initialise( settings; reset=true )
    if use_essex_years
        people = people[ people.data_year .∈ ( settings.included_data_years, ) , :]
        hhs = hhs[ hhs.data_year .∈ ( settings.included_data_years, ) , :]
    end
    interframe = make_intermed_dataframe( settings, 
        sys, 
        settings.num_households )
    # this seems to be what they work with.. weird
    phhs = leftjoin( hhs, people, on=[:hid,:data_year], makeunique=true)
    # Write the uprated and whatevered mode hhld data back into the frame we're comparing with.
    overwrite_raw!( phhs, settings.num_households )
    # Cast weights as StatsBase weights type - this doesn't persist well.
    phhs.weight = Weights( phhs.weight )
    interframe.weight = Weights( interframe.weight )
    df_numvars, df_enums = make_data_summaries( phhs )
    tmpdir = joinpath( tempdir(), "output" )
    if ! isdir( tmpdir )
        mkdir( tmpdir )
    end
    year_str = use_essex_years ? "essex-data-years" : "full-data-years"
    weight_str = use_essex_weights ? "frs-weights" : "computed-weights"
    match_str = do_matching ? "matched-was-lcf-data" : "frs-data-only"
    CSV.write( joinpath( tmpdir, "scotben-numeric-variable-summaries_$(year_str)_$(weight_str)_$(match_str).tab" ), df_numvars; delim='\t')
    CSV.write( joinpath( tmpdir, "scotben-enum-variable-summaries_$(year_str)_$(weight_str)_$(match_str).tab"), df_enums; delim='\t')
end

for essex_years in [true, false ]
    for essex_weights in [true, false ]
        for matching in [true, false]
            do_one_summary_set( 
                use_essex_years = essex_years,
                use_essex_weights = essex_weights,
                do_matching = matching )
        end
    end
end