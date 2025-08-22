#=

Create a full new set of artifacts.

Linux - actual data

1. copy everything you need into "/mnt/data/ScotBen/artifacts/"
2. check the update of HistoricBenefits

=#

#=
put these env variables at the top to make sure the ScotBen constants (e.g. historic_benefits.csv) are
loaded from the development files
=#
ENV["SCOTBEN_DATA_VERSION"]="0.1.6" # change manually 
# data in development mode
ENV["SCOTBEN_DATA_DEVELOPING"]=1

using Pkg
Pkg.activate(".")
Pkg.update()

include("artifacts-bulk-upload.jl")
include("create_all_disability_regressions.jl")

using ScottishTaxBenefitModel
using .Definitions
using .FRSHouseholdGetter
using .HistoricBenefits
using .LocalWeightGeneration
using .MatchingLibs
using .RunSettings
using .Utils
using .WeightingData

using CSV
using DataFrames

#=
Note that we create for these years only. Previously we created for all years
and made a years subset at run time with the run-settings.
=#
const DATA_YEARS = [2019,2021,2022,2023]

# Where the original created datasets live.
const SCOTBEN_DATA = "/mnt/data/ScotBen/data/actual_data"


#!! @testset "Local reweighing" in local_level_calculations_tests - move here
settings = Settings() 
#
# Turn of all the matching and weighting till we have matching in.
#
settings.use_shs = false
settings.indirect_method = no_method
settings.wealth_method = no_method
settings.weighting_strategy = dont_use_weights
settings.included_data_years = DATA_YEARS # new 4 year sample MANUALLY EDIT THIS FOR EXTRA YEARS

const datadir = get_data_artifact(settings) 

const workdir = joinpath( homedir(), "tmp", "working-output" )
if ! isdir( workdir )
   mkpath( workdir )
end

# bump the data version 

v = get_data_version()
#=
matching data
=#
settings.num_households, 
settings.num_people = 
    FRSHouseholdGetter.initialise( settings; reset=true )

MatchingLibs.create_shs_matches(joinpath( Utils.ARTIFACT_DIR, "scottish-shs-data" ))
MatchingLibs.create_lcf_matches(joinpath( Utils.ARTIFACT_DIR, "scottish-lcf-expenditure" ))
MatchingLibs.create_was_matches(joinpath( Utils.ARTIFACT_DIR, "scottish-was-wealth" ))

# turn matching back on for weight generation
settings.use_shs = true
settings.indirect_method = matching
settings.wealth_method = matching

# local authority weights (FIXME for multiple year selections?)
wd = create_la_weights( settings )
CSV.write( joinpath( datadir, "weights-la.tab"), wd; delim='\t')
WeightingData.init_local_weights( settings; reset=true)
rd = LocalWeightGeneration.create_wage_relativities( settings )
CSV.write( joinpath( datadir, "local-nomis-frs-wage-relativities.tab"), rd; delim='\t')

#=
## Disability candidates.

Edit `hhfile and `peoplefile` to point to the full, all years, UK-wide model datasets 
created each year and input_dir to where they live.
Probably worth manually revisiting the regressions.
=#
create_all_disability_regressions( ;
  input_dir = SCOTBEN_DATA,
  output_dir = qualified_artifact( "disability" ), 
  hhfile = "model_households-2015-2023-w-enums-2.tab", 
  peoplefile = "model_people-2015-2023-w-enums-2.tab",
  datayears = DATA_YEARS )
#=
Make precomputed Scotland Weights - CAREFUL - for this combination of years only!
this just sets up the data 
=#
settings.weighting_strategy = use_runtime_computed_weights
settings.num_households, settings.num_people, np = FRSHouseholdGetter.initialise( settings; reset=true )
settings.output_dir = get_data_artifact( settings )
FRSHouseholdGetter.extract_weights_and_deciles( settings, "weights" )


# increment data version, and turn of writing to the base datadir.
ENV["SCOTBEN_DATA_VERSION"]="0.1.7"
delete!(ENV,"SCOTBEN_DATA_DEVELOPING")

# now write the data
#
upload_all()

# finally remember to set `version` in `Project.toml` to match the new `SCOTBEN_DATA_VERSION`.
