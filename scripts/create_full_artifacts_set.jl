#=

Create a full new set of artifacts.

Linux - actual data

1. copy everything you need into "/mnt/data/ScotBen/artifacts/"
2. 



=#

using Pkg
Pkg.activate(".")
Pkg.update()

include("artifacts-bulk-upload.jl")

using ScottishTaxBenefitModel
using .Utils
using .FRSHouseholdGetter
using .MatchingLibs
using .WeightingData
using .RunSettings
using .LocalWeightGeneration
using .WeightingData

#!! @testset "Local reweighing" in local_level_calculations_tests - move here
ENV["SCOTBEN_DATA_VERSION"]="0.1.6" # change manually 
# data in development mode
ENV["SCOTBEN_DATA_DEVELOPING"]=1

settings = Settings()
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

# local authority weights (FIXME for multiple year selections?)
wd = create_la_weights( settings )
CSV.write( joinpath( datadir, "weights-la.tab"), d; delim='\t')
init_local_weights( settings; reset=true)
rd = LocalWeightGeneration.create_wage_relativities( settings )
CSV.write( joinpath( datadir, "local-nomis-frs-wage-relativities.tab"), rd; delim='\t')






ENV["SCOTBEN_DATA_VERSION"]="0.1.7"
delete!(ENV,"SCOTBEN_DATA_DEVELOPING")

# after finishing, manually edit version number in Project.toml to match bumped version
