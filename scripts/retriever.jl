using CSV, DataFrames, Markdown
using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .Utils

#=
const MODEL_NAME="ScottishTaxBenefitModel"
const PROJECT_DIR=Utils.get_project_path() #"//vw/$MODEL_NAME/"
const MODEL_DATA_DIR="$(PROJECT_DIR)/data/"
const PRICES_DIR="$MODEL_DATA_DIR/prices/obr/"
const MATCHING_DIR="$MODEL_DATA_DIR/merging/"
const MODEL_PARAMS_DIR="$PROJECT_DIR/params"

const RAW_DATA = "/mnt/data/"
const FRS_DIR = "$RAW_DATA/frs/"
const HBAI_DIR = "$RAW_DATA/hbai/"
=#

include("../src/HouseholdMappingFRS_HBAI.jl")

function print_one( r :: DataFrameRow ) :: String

@enum Components 

model_person,
model_household,
adult,
accounts,
benunit,
child,
extchild,
maint,
penprov,
admin,
care,
mortcont,
pension,
govpay,
mortgage,
assets,
chldcare,
househol,
oddjob,
benefits,
endowmnt,
job,
hbai_res,
frsx 