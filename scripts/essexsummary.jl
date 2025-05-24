
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


function initialise(; 
    wealth_method = no_method, 
    indirect_method = no_method, 
    weighing_strategy = use_runtime_computed_weights,
    included_data_years = [],
    lower_multiple = 0.15,
    upper_multiple = 7.0 )::Tuple
    sys = STBParameters.get_default_system_for_fin_year( 2024 )
    settings = Settings()
    settings.indirect_method = indirect_method
    settings.do_legal_aid = false
    settings.wealth_method = wealth_method
    settings.use_shs = true
    settings.weighting_strategy = use_runtime_computed_weights
    settings.lower_multiple = lower_multiple
    settings.upper_multiple = upper_multiple
    settings.included_data_years = included_data_years # [2019,2020,2022] # match Essex
    nhhs, npeople, nhhs2 = FRSHouseholdGetter.initialise( settings; reset=true )
    settings, sys, nhhs
end 

included_data_years = [2019,2021,2022]
# dup load but hard to avoid..
dataset_artifact = get_data_artifact( Settings() )
hhs = HouseholdFromFrame.read_hh( 
    joinpath( dataset_artifact, "households.tab")) # CSV.File( ds.hhlds ) |> DataFrame
people = HouseholdFromFrame.read_pers( 
    joinpath( dataset_artifact, "people.tab"))

settings, sys, nhhs = initialise( included_data_years=included_data_years, lower_multiple=0.15, upper_multiple=9)

# restrict to Essex's three years
people = people[ people.data_year .∈ ( included_data_years, ) , :]
hhs = hhs[ hhs.data_year .∈ ( included_data_years, ) , :]
interframe = make_intermed_dataframe( settings, 
    sys, 
    nhhs )
# this seems to be what they work with.. weird
phhs = leftjoin( hhs, people, on=[:hid,:data_year], makeunique=true)
# Write the uprated and whatevered mode hhld data back into the frame we're comparing with.
overwrite_raw!( phhs, nhhs )
# Cast weights as StatsBase weights type - this doesn't persist well.
phhs.weight = Weights( phhs.weight )
interframe.weight = Weights( interframe.weight )
df1, df2 = make_data_summaries( phhs )
tmpdir = joinpath( tempdir(), "output" )
if ! isdir( tmpdir )
   mkdir( tmpdir )
end
CSV.write( joinpath( tmpdir, "scotben-numeric-variable-summaries.tab" ), df1; delim='\t')
CSV.write( joinpath( tmpdir, "scotben-enum-variable-summaries.tab"), df2; delim='\t')