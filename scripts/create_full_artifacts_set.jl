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
using .WeightingData
using .RunSettings
using .LocalWeightGeneration
#!! @testset "Local reweighing" in local_level_calculations_tests - move here

# bump the data version 

v = get_data_version()

ENV["SCOTBEN_DATA_VERSION"]="0.1.7" # change manually 

#=
create new frs datasets 

load data into artifacts source

cd /mnt/data/ScotBen/
cp data/actual_data/model_people_scotland-2015-2023-w-enums-1.tab people.tab
cp data/actual_data/model_households_scotland-2015-2023-w-enums-1.tab households.tab

LOCAL - local_level_calculations_tests has create wage data

=#
# DON'T create saved Scottish weights

create_la_weights( settings )

# at the end, set data version back

ENV["SCOTBEN_DATA_VERSION"]="0.1.6"

# after finishing, manually edit version number in Project.toml to match bumped version

