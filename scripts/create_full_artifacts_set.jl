#=

Create a full new set of artifacts.

Linux - actual data

1. copy everything you need into "/mnt/data/ScotBen/artifacts/"
2. 

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

## Minimal update list

* extra year historic benefits

=#
#!! @testset "Local reweighing" in local_level_calculations_tests - move here
settings = Settings() 
#
# Turn of all the matching and weighting till we have matching in.
#
settings.use_shs = false
settings.indirect_method = no_method
settings.wealth_method = no_method
settings.weighting_strategy = dont_use_weights
settings.included_data_years = [2019,2021,2022,2023] # new 4 year sample MANUALLY EDIT THIS FOR EXTRA YEARS

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

#=
create new frs datasets 

load data into artifacts source

cd /mnt/data/ScotBen/
cp data/actual_data/model_people_scotland-2015-2023-w-enums-1.tab people.tab
cp data/actual_data/model_households_scotland-2015-2023-w-enums-1.tab households.tab

LOCAL - local_level_calculations_tests has create wage data

=#
# DON'T create saved Scottish weights

# at the end, set data version back

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

# increment data version, turn of writing to the base datadir
ENV["SCOTBEN_DATA_VERSION"]="0.1.7"
delete!(ENV,"SCOTBEN_DATA_DEVELOPING")

# now write the data
#
# disability candidates
#


upload_all()