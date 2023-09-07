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
      .Uprating,
      .RunSettings


using CSV,
      DataFrames,
      Measures,
      StatsBase


    
const NUM_SAMPLES = 20


Uprating.load_prices( Settings() )


"""
Load 2020/21 FRS and add some matching fields
"""
function loadfrs()::Tuple
    frsrows,frscols,frshh = load( "/mnt/data/frs/2021/tab/househol.tab",2021)
    farows,facols,frsad = load( "/mnt/data/frs/2021/tab/adult.tab", 2021)
    frs_hh_pp = innerjoin( frshh, frsad, on=[:sernum,:datayear], makeunique=true )
    frshh.any_wages .= frshh.hearns .> 0    
    frshh.any_pension_income .= frshh.hpeninc .> 0    
    frshh.any_selfemp .= frshh.hseinc .!= 0     
    frshh.hrp_unemployed .= frshh.emp .== 1    
    frshh.num_children = frshh.depchldh # DEPCHLDH    
    frshh.hrp_non_white = frshh.hheth .!= 1
    # LCF case ids of non white HRPs - convoluted; see: 
    # https://stackoverflow.com/questions/51046247/broadcast-version-of-in-function-or-in-operator
    frshh.num_people = frshh.adulth + frshh.num_children
    frshh.income = within.( frshh.hhinc, min=0, max=TOPCODE )    
    # not possible in lcf???
    frshh.any_disabled = (frshh.diswhha1 + frshh.diswhhc1) .> 0 #DISWHHA1 DISWHHC1    
    frshh.has_female_adult .= 0
    frs_femalepids = frs_hh_pp[(frs_hh_pp.sex .== 2),:sernum]
    frshh[frshh.sernum .∈ (frs_femalepids,),:has_female_adult] .= 1
    return frshh,frspers,frs_hh_pp
end
# fcrows,fccols,frsch = load( "/mnt/data/frs/2021/tab/child.tab", 2021 )

"""
Load 2018/9 - 2020/1 LCFs and add some matching fields.
"""
function load3lcfs()::Tuple
    lcfhrows,lcfhcols,lcfhh18 = load( "/mnt/data/lcf/1819/tab/2018_dvhh_ukanon.tab", 2018 )
    lcfhrows,lcfhcols,lcfhh19 = load( "/mnt/data/lcf/1920/tab/lcfs_2019_dvhh_ukanon.tab", 2019 )
    lcfhrows,lcfhcols,lcfhh20 = load( "/mnt/data/lcf/2021/tab/lcfs_2020_dvhh_ukanon.tab", 2020 )
    lcfhh = vcat( lcfhh18, lcfhh19, lcfhh20, cols=:union )
    lcfhrows = size(lcfhh)[1]

    lcfprows,lcpfcols,lcfpers18 = load( "/mnt/data/lcf/1819/tab/2018_dvper_ukanon201819.tab", 2018 )
    lcfprows,lcpfcols,lcfpers19 = load( "/mnt/data/lcf/1920/tab/lcfs_2019_dvper_ukanon201920.tab", 2019 )
    lcfprows,lcpfcols,lcfpers20 = load( "/mnt/data/lcf/2021/tab/lcfs_2020_dvper_ukanon202021.tab",2020)
    lcfpers = vcat( lcfpers18, lcfpers19, lcfpers20, cols=:union )
    lcf_hh_pp = innerjoin( lcfhh, lcfpers, on=[:case,:datayear], makeunique=true )
    lcfhh.any_wages .= lcfhh.p356p .> 0
    lcfhh.any_pension_income .= lcfhh.p364p .> 0
    lcfhh.any_selfemp .= lcfhh.p320p .!= 0
    lcfhh.hrp_unemployed .= lcfhh.p304 .== 1
    lcfhh.num_children = lcfhh.a040 + lcfhh.a041 + lcfhh.a042
    # LCF case ids of non white HRPs - convoluted; see: 
    # https://stackoverflow.com/questions/51046247/broadcast-version-of-in-function-or-in-operator
    lcf_nonwhitepids = lcf_hh_pp[(lcf_hh_pp.a012p .∈ (["10","2","3","4"],)).&(lcf_hh_pp.a003 .== 1),:case]
    lcfhh.hrp_non_white .= 0
    lcfhh[lcfhh.case .∈ (lcf_nonwhitepids,),:hrp_non_white] .= 1    
    lcfhh.num_people = lcfhh.a049
    lcfhh.income = lcfhh.p344p    
    # not possible in lcf???
    lcfhh.any_disabled .= 0
    lcf_femalepids = lcf_hh_pp[(lcf_hh_pp.a004 .== 2),:case]
    lcfhh.has_female_adult .= 0
    lcfhh[lcfhh.case .∈ (lcf_femalepids,),:has_female_adult] .= 1
    lcfhh.is_selected = fill( false, lcfhrows )
    lcfhh,lcfpers,lcf_hh_pp
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

=#