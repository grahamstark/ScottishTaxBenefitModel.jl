#
# A script to match records from 2019/19 to 2020/21 lcf to 2020 FRS
# strategy is to match to a bunch of characteristics, take the top 20 of those, and then
# match between those 20 on household income. 
# TODO
# - make this into a module and a bit more general-purpose;
# - write up, so why not just Engel curves?
#
using ScottishTaxBenefitModel
using .Definitions,
      .MatchingLibs,
      .MatchingLibs.LCF_TO_FRS,
      .Uprating,
      .RunSettings

using .GeneralTaxComponents: WEEKS_PER_YEAR, WEEKS_PER_MONTH
using .Utils: loadtoframe

using CSV,
      DataFrames,
      Measures,
      StatsBase


    
const NUM_SAMPLES = 20

const TOPCODE = MatchingLibs.TOPCODE

include( "$(Definitions.SRC_DIR)/frs_hbai_creation_libs.jl")

Uprating.load_prices( Settings() )

function add_some_frs_fields!( frshh :: DataFrame, frs_hh_pp :: DataFrame )
    frshh.any_wages .= frshh.hearns .> 0    
    frshh.any_pension_income .= frshh.hpeninc .> 0    
    frshh.any_selfemp .= frshh.hseinc .!= 0     
    frshh.hrp_unemployed .= frshh.emp .== 1    
    frshh.num_children = frshh.depchldh # DEPCHLDH    
    frshh.hrp_non_white = frshh.hheth .!= 1
    # LCF case ids of non white HRPs - convoluted; see: 
    # https://stackoverflow.com/questions/51046247/broadcast-version-of-in-function-or-in-operator
    frshh.num_people = frshh.adulth + frshh.num_children
    frshh.income = within.( frshh.hhinc, min=0, max=MatchingLibs.TOPCODE )    
    # not possible in lcf???
    frshh.any_disabled = (frshh.diswhha1 + frshh.diswhhc1) .> 0 #DISWHHA1 DISWHHC1    
    frshh.has_female_adult .= 0
    frs_femalepids = frs_hh_pp[(frs_hh_pp.sex .== 2),:sernum]
    frshh[frshh.sernum .∈ (frs_femalepids,),:has_female_adult] .= 1
end

function insert_defaults_in_model_dataset(
    dataset :: String,
    matching :: String )
    hhd = CSV.File( dataset ) |> DataFrame
    mtch = CSV.File( matching ) |> DataFrame
end


#= to run this, so

lcfhh,lcfpers,lcf_hh_pp = load3lcfs()
frshh,frspers,frs_hh_pp = loadfrs()
uprate_incomes!( frshh, lcfhh ) # all in constant prices
alldf = map_all(frshh, lcfhh, frs_lcf_match_row )
CSV.write( "frs_lcf_matches_2020_vx.csv", alldf )
CSV.write( "data/lcf_edited.csv", lcfhh )

# test stuff 
lcfhrows = size(lcfhh)[1]
lcfhh.is_selected = fill( false, lcfhrows )
for i in eachrow(alldf)
    lcfhh[(lcfhh.datayear.==i.lcf_datayear_1).&(lcfhh.case.==i.lcf_case_1),:is_selected] .= true
end

sellcfhh = lcfhh[lcfhh.is_selected,:]
# FIXME Add something to fit default_matched_case hh.lcf_default_data_year 
=#