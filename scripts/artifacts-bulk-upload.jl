#=
Bulk upload all the various ScotBen data artifacts
=#
using ScottishTaxBenefitModel
using .Utils

LOCALS = [
    "scottish-frs-data", 
    "scottish-slab-legalaid", 
    "scottish-lcf-expenditure", 
    "scottish-was-wealth",
    "uk-frs-data", 
    "uk-lcf-expenditure", 
    "uk-was-wealth"]

PUBLICS = [
    "scottish-synthetic-data",
    "scottish-synthetic-expenditure",
    "scottish-synthetic-legalaid",
    "scottish-synthetic-wealth",
    "scottish-was-wealth",
    "uk-synthetic-data",
    "uk-synthetic-expenditure",
    "uk-synthetic-wealth",
    "uk-was-wealth",
    "augdata",
    "disability",
    "example_data",
]

for name in union(PUBLICS,LOCALS)
    is_local = name in LOCALS
    Utils.make_artifact( ; artifact_name=name, is_local=is_local )
end