
"""
Load 2020/21 FRS and add some matching fields
"""
function loadfrs()::Tuple
    frsrows,frscols,frshh = load( "/mnt/data/frs/2021/tab/househol.tab",2021)
    farows,facols,frsad = load( "/mnt/data/frs/2021/tab/adult.tab", 2021)
    frs_hh_pp = innerjoin( frshh, frsad, on=[:sernum,:datayear], makeunique=true )
    add_some_frs_fields!( frshh, frs_hh_pp )
    return frshh,frspers,frs_hh_pp
end
# fcrows,fccols,frsch = load( "/mnt/data/frs/2021/tab/child.tab", 2021 )

"""
Scottish Version on Pooled data
"""
function load_scottish_frss( startyear::Int, endyear :: Int )::NamedTuple
    frshh = DataFrame()
    frs_hh_pp = DataFrame()
    frspers = DataFrame()
    for year in startyear:endyear
        lhh = loadfrs( "househol", year )
        lhh = lhh[ lhh.gvtregn.== 299999999, :] # SCOTLAND
        lhh.datayear .= year
        lad = loadfrs( "adult", year )
        lad.datayear .= year
        l_hh_pp = innerjoin( lhh, lad, on=[:sernum,:datayear], makeunique=true )
        add_some_frs_fields!( lhh, l_hh_pp )
        frshh = vcat( frshh, lhh; cols=:union )
        frspers = vcat( frspers, lad; cols=:union )
        frs_hh_pp = vcat( frs_hh_pp, l_hh_pp, cols=:union )
    end
    (; frshh, frspers, frs_hh_pp )
end


"""
Map housing type. Not used because the f**ing this is deleted in 19/20 public lcf.
"""
function frs_accmap( typeacc :: Union{Int,Missing})  :: Vector{Int}
    out = fill( 9999, 3 )
    out[1] = min(6,typeacc)
    if typeacc in 1:3
        out[2] = 1
    elseif typeacc in 4:5
        out[2] = 2
    elseif typeacc in 6:7
        out[2] = 3
    else
        @assert false "unmatched typeacc $typeacc"
    end
    out
end


"""
Produce a comparison between on frs and one lcf row on tenure, region, wages, etc.
"""
function frs_lcf_match_row( frs :: DataFrameRow, lcf :: DataFrameRow ) :: Tuple
    t = 0.0
    t += score( lcf_tenuremap( lcf.a121 ), frs_tenuremap( frs.tentyp2 ))
    t += score( lcf_regionmap( lcf.gorx ), frs_regionmap( frs.gvtregn, 9997 ))
    # !!! both next missing in 2020 LCF FUCKKK 
    # t += score( lcf_accmap( lcf.a116 ), frs_accmap( frs.typeacc ))
    # t += score( rooms( lcf.a111p, 998 ), rooms( frs.bedroom6, 999 ))
    t += score( lcf_age_hrp(  lcf.a065p ), frs_age_hrp( frs.hhagegr4 ))
    t += score( lcf_composition_map( lcf.a062 ), frs_composition_map( frs.hhcomps ))
    t += lcf.any_wages == frs.any_wages ? 1 : 0
    t += lcf.any_pension_income == frs.any_pension_income ? 1 : 0
    t += lcf.any_selfemp == frs.any_selfemp ? 1 : 0
    t += lcf.hrp_unemployed == frs.hrp_unemployed ? 1 : 0
    t += lcf.hrp_non_white == frs.hrp_non_white ? 1 : 0
    t += lcf.datayear == frs.datayear ? 0.5 : 0 # - a little on same year FIXME use date range
    # t += lcf.any_disabled == frs.any_disabled ? 1 : 0 -- not possible in LCF??
    t += lcf.has_female_adult == frs.has_female_adult ? 1 : 0
    t += score( lcf.num_children, frs.num_children )
    t += score( lcf.num_people, frs.num_people )
    # fixme should we include this at all?
    incdiff = compare_income( lcf.income, frs.income )
    t += 10.0*incdiff
    return t,incdiff
end


"""
print out our lcf and frs records
"""
function comparefrslcf( frshh::DataFrame, lcfhh:: DataFrame, frs_sernums, frs_datayear::Int, lcf_case::Int, lcf_datayear::Int )
    lcf1 = lcfhh[(lcfhh.case .== lcf_case).&(lcfhh.datayear .== lcf_datayear),
        [:any_wages,:any_pension_income,:any_selfemp,:hrp_unemployed,
        :hrp_non_white,:has_female_adult,:num_children,:num_people,
        :a121,:gorx,:a065p,:a062,:income]]
    println(lcf1)
    println( "lcf tenure",lcf_tenuremap( lcf1.a121[1] ))
    println( "lcf region", lcf_regionmap( lcf1.gorx[1] ))
    println( "lcf age_hrp", lcf_age_hrp( lcf1.a065p[1] ))
    println( "lcf composition", lcf_composition_map( lcf1.a062[1] ))
    for i in frs_sernums
        println( "sernum $i")
        frs1 = frshh[(frshh.sernum .== i).&(frshh.datayear.==frs_datayear),
            [:any_wages,:any_pension_income,:any_selfemp,:hrp_unemployed,:hrp_non_white,:has_female_adult,
            :num_children,:num_people,:tentyp2,:gvtregn,:hhagegr4,:hhcomps,:income]]
        println(frs1)
        println( "frs tenure", frs_tenuremap( frs1.tentyp2[1]))
        println( "frs region", frs_regionmap( frs1.gvtregn[1] ))
        println( "frs age hrp", lcf_age_hrp( frs1.hhagegr4[1] ))
        println( "frs composition", frs_composition_map( frs1.hhcomps[1] ))
        println( "income $(frs1.income)")
    end
end


function xxmodel_age_grp( age :: Int )
    return if age < 20
        1
    elseif age < 25
        2
    elseif age < 30
        3
    elseif age < 35
        4
    elseif age < 40
        5
    elseif age < 45
        6
    elseif age < 50
        7
    elseif age < 55
        8
    elseif age < 60
        9
    elseif age < 65
        10
    elseif age < 70
        11
    elseif age < 75
        12
    elseif age >= 75
        13
    end
end


"""
Produce a comparison between on frs and one lcf row on tenure, region, wages, etc.
"""

function match_row( hh :: Household, lcf :: DataFrameRow ) :: Tuple
    t = 0.0
    t += score( lcf_tenuremap( lcf.a121 ), frs_tenuremap( frs.tentyp2 ))
    t += score( lcf_regionmap( lcf.gorx ), frs_regionmap( frs.gvtregn, 9997 ))
    # !!! both next missing in 2020 LCF FUCKKK 
    # t += score( lcf_accmap( lcf.a116 ), frs_accmap( frs.typeacc ))
    # t += score( rooms( lcf.a111p, 998 ), rooms( frs.bedroom6, 999 ))
    t += score( lcf_age_hrp(  lcf.a065p ), frs_age_hrp( frs.hhagegr4 ))
    t += score( lcf_composition_map( lcf.a062 ), Model.composition_map( frs.hhcomps ))
    t += lcf.any_wages == frs.any_wages ? 1 : 0
    t += lcf.any_pension_income == frs.any_pension_income ? 1 : 0
    t += lcf.any_selfemp == frs.any_selfemp ? 1 : 0
    t += lcf.hrp_unemployed == frs.hrp_unemployed ? 1 : 0
    t += lcf.hrp_non_white == frs.hrp_non_white ? 1 : 0
    t += lcf.datayear == frs.datayear ? 0.5 : 0 # - a little on same year FIXME use date range
    # t += lcf.any_disabled == frs.any_disabled ? 1 : 0 -- not possible in LCF??
    t += lcf.has_female_adult == frs.has_female_adult ? 1 : 0
    t += score( lcf.num_children, frs.num_children )
    t += score( lcf.num_people, frs.num_people )
    # fixme should we include this at all?
    incdiff = compare_income( lcf.income, frs.income )
    t += 10.0*incdiff
    return t,incdiff
end

