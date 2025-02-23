using Test

using CSV,
    DataFrames,
    Measures,
    StatsBase,
    ArgCheck,
    PrettyTables
using ScottishTaxBenefitModel
using .Definitions, .MatchingLibs, .ModelHousehold, .FRSHouseholdGetter, .RunSettings

import ScottishTaxBenefitModel.MatchingLibs.SHS as shs
import ScottishTaxBenefitModel.MatchingLibs.LCF as lcf
import ScottishTaxBenefitModel.MatchingLibs.Common as common
import ScottishTaxBenefitModel.MatchingLibs.Model as mm
import ScottishTaxBenefitModel.MatchingLibs.WAS as was

# then ..
settings = Settings()
settings.num_households, settings.num_people, nhh = 
    FRSHouseholdGetter.initialise( settings; reset=false)


@testset "Model Mappings" begin
    

end

function map_one!( df :: DataFrame, key :: Symbol, pos :: Vector{Int}; weight=1.0 )
    l = length(pos)
    for i in 1:l
        p = min(pos[i],21) # deliberate miss at end
        p = p <= 0 ? 21 : p
        df[p,Symbol("$(key)_$(i)")] += weight
    end
end

function map_one!( df :: DataFrame, key :: Symbol, count :: Int; weight=1.0 )
    if count == 0
        count = 21
    end
    df[count,Symbol("$(key)_1")] += weight
end

function map_one!( df :: DataFrame, key :: Symbol, count :: Bool; weight=1.0 )
    p = Int(count)+1 # deliberate miss at end
    df[p,Symbol("$(key)_1")] += weight
end

function map_one!( df :: DataFrame, key :: Symbol, count :: Missing; weight=1.0 )
    p = 21 # deliberate miss at end
    df[p,Symbol("$(key)_1")] += weight
end

function to_pct( df:: DataFrame)::DataFrame
    nr,nc = size(df)
    for c in 2:nc
        s = sum(df[!,c])
        df[!,c] = 100 .* df[!,c] ./ s
    end
    df
end

function one_shs_model_summary_df()::DataFrame
    n = 21
    return DataFrame( 
        shelter_1 = zeros(n),
        tenure_1 = zeros(n),
        hh_composition_1 = zeros(n),
        num_adults_1 = zeros(n),
        num_children_1 = zeros(n),
        acctype_1 = zeros(n),
        agehigh_1 = zeros(n),
        empstathigh_1 = zeros(n),
        ethnichigh_1 = zeros(n),
        sochigh_1 = zeros(n),
        datayear_1 = zeros(n),
        bedrooms_1 = zeros(n),
        region_1 = zeros(n),
        shelter_2 = zeros(n),
        tenure_2 = zeros(n),
        hh_composition_2 = zeros(n),
        num_adults_2 = zeros(n),
        num_children_2 = zeros(n),
        acctype_2 = zeros(n),
        agehigh_2 = zeros(n),
        empstathigh_2 = zeros(n),
        ethnichigh_2 = zeros(n),
        sochigh_2 = zeros(n),
        datayear_2 = zeros(n),
        bedrooms_2 = zeros(n),
        region_2 = zeros(n),
        shelter_3 = zeros(n),
        tenure_3 = zeros(n),
        hh_composition_3 = zeros(n),
        num_adults_3 = zeros(n),
        num_children_3 = zeros(n),
        acctype_3 = zeros(n),
        agehigh_3 = zeros(n),
        empstathigh_3 = zeros(n),
        ethnichigh_3 = zeros(n),
        sochigh_3 = zeros(n),
        datayear_3 = zeros(n),
        bedrooms_3 = zeros(n),
        region_3 = zeros(n),
    )
end

function one_lcf_model_summary_df()::DataFrame
    n = 21
    return DataFrame( 
        n = 1:n,
        marstat_1 = zeros(n),
        socio_1 = zeros(n),
        empstat_1 = zeros(n),
        tenure_1 = zeros(n),
        acctype_1 = zeros(n),
        region_1 = zeros(n),
        num_people_1 = zeros(n),
        num_children_1 = zeros(n),
        any_disabled_1 = zeros(n),
        has_female_adult_1 = zeros(n),
        num_employees_1 = zeros(n),
        num_pensioners_1 = zeros(n),
        num_fulltime_1 = zeros(n),
        num_parttime_1 = zeros(n),
        num_selfemp_1 = zeros(n),
        num_unemployed_1 = zeros(n),
        num_unoccupied_1 = zeros(n),
        hrp_has_partner_1 = zeros(n),
        any_wages_1 = zeros(n),
        any_pension_income_1 = zeros(n),
        any_selfemp_1 = zeros(n),
        hrp_unemployed_1 = zeros(n),
        marstat_2 = zeros(n),
        socio_2 = zeros(n),
        empstat_2 = zeros(n),
        tenure_2 = zeros(n),
        acctype_2 = zeros(n),
        region_2 = zeros(n),
        num_people_2 = zeros(n),
        any_disabled_2 = zeros(n),
        has_female_adult_2 = zeros(n),
        num_employees_2 = zeros(n),
        num_pensioners_2 = zeros(n),
        num_fulltime_2 = zeros(n),
        num_parttime_2 = zeros(n),
        num_selfemp_2 = zeros(n),
        num_unemployed_2 = zeros(n),
        num_unoccupied_2 = zeros(n),
        hrp_has_partner_2 = zeros(n),
        any_wages_2 = zeros(n),
        any_pension_income_2 = zeros(n),
        any_selfemp_2 = zeros(n),
        hrp_unemployed_2 = zeros(n),
        marstat_3 = zeros(n),
        socio_3 = zeros(n),
        empstat_3 = zeros(n),
        tenure_3 = zeros(n),
        acctype_3 = zeros(n),
        region_3 = zeros(n),
        num_people_3 = zeros(n),
        any_disabled_3 = zeros(n),
        has_female_adult_3 = zeros(n),
        num_employees_3 = zeros(n),
        num_pensioners_3 = zeros(n),
        num_fulltime_3 = zeros(n),
        num_parttime_3 = zeros(n),
        num_selfemp_3 = zeros(n),
        num_unemployed_3 = zeros(n),
        num_unoccupied_3 = zeros(n),
        hrp_has_partner_3 = zeros(n),
        any_wages_3 = zeros(n),
        any_pension_income_3 = zeros(n),
        any_selfemp_3 = zeros(n),
        hrp_unemployed_3 = zeros(n))
end

function one_was_model_summary_df()::DataFrame
    n = 21
    return DataFrame( 
        n = 1:n,
        agehigh_1 = zeros(n),
        marstat_1 = zeros(n),
        socio_1 = zeros(n),
        hh_composition_1 = zeros(n),
        empstat_1 = zeros(n),
        tenure_1 = zeros(n),
        acctype_1 = zeros(n),
        region_1 = zeros(n),
        bedrooms_1 = zeros(n),
        num_adults_1 = zeros(n),
        num_children_1 = zeros(n),
        any_disabled_1 = zeros(n),
        has_female_adult_1 = zeros(n),
        num_employees_1 = zeros(n),
        num_pensioners_1 = zeros(n),
        num_fulltime_1 = zeros(n),
        num_parttime_1 = zeros(n),
        num_selfemp_1 = zeros(n),
        num_unemployed_1 = zeros(n),
        num_unoccupied_1 = zeros(n),
        hrp_has_partner_1 = zeros(n),
        any_wages_1 = zeros(n),
        any_pension_income_1 = zeros(n),
        any_selfemp_1 = zeros(n),
        hrp_unemployed_1 = zeros(n),
        agehigh_2 = zeros(n),
        marstat_2 = zeros(n),
        socio_2 = zeros(n),
        hh_composition_2 = zeros(n),
        empstat_2 = zeros(n),
        tenure_2 = zeros(n),
        acctype_2 = zeros(n),
        region_2 = zeros(n),
        bedrooms_2 = zeros(n),
        num_adults_2 = zeros(n),
        num_children_2 = zeros(n),
        any_disabled_2 = zeros(n),
        has_female_adult_2 = zeros(n),
        num_employees_2 = zeros(n),
        num_pensioners_2 = zeros(n),
        num_fulltime_2 = zeros(n),
        num_parttime_2 = zeros(n),
        num_selfemp_2 = zeros(n),
        num_unemployed_2 = zeros(n),
        num_unoccupied_2 = zeros(n),
        hrp_has_partner_2 = zeros(n),
        any_wages_2 = zeros(n),
        any_pension_income_2 = zeros(n),
        any_selfemp_2 = zeros(n),
        hrp_unemployed_2 = zeros(n),
        agehigh_3 = zeros(n),
        marstat_3 = zeros(n),
        socio_3 = zeros(n),
        hh_composition_3 = zeros(n),
        empstat_3 = zeros(n),
        tenure_3 = zeros(n),
        acctype_3 = zeros(n),
        region_3 = zeros(n),
        bedrooms_3 = zeros(n),
        num_adults_3 = zeros(n),
        num_children_3 = zeros(n),
        any_disabled_3 = zeros(n),
        has_female_adult_3 = zeros(n),
        num_employees_3 = zeros(n),
        num_pensioners_3 = zeros(n),
        num_fulltime_3 = zeros(n),
        num_parttime_3 = zeros(n),
        num_selfemp_3 = zeros(n),
        num_unemployed_3 = zeros(n),
        num_unoccupied_3 = zeros(n),
        hrp_has_partner_3 = zeros(n),
        any_wages_3 = zeros(n),
        any_pension_income_3 = zeros(n),
        any_selfemp_3 = zeros(n),
        hrp_unemployed_3 = zeros(n))
end

@testset "WAS Mappings" begin
    wass = was.create_subset()
    model_summaries = one_was_model_summary_df()
    was_summaries = one_was_model_summary_df()
    map_one!.( (was_summaries,), (:tenure,), was.map_tenure.(wass.tenure)) 
    map_one!.( (was_summaries,), (:acctype,), was.map_accom.(wass.accom) ) 
    # bedrooms to common
    map_one!.( (was_summaries,), (:bedrooms,), shs.bedrooms.(wass.bedrooms)) 
    map_one!.( (was_summaries,), (:hh_composition,), was.map_household_composition.(wass.household_type)) 
    map_one!.( (was_summaries,), (:any_wages,), wass.any_wages )
    map_one!.( (was_summaries,), (:any_pension_income,), wass.any_pension_income )
    map_one!.( (was_summaries,), (:any_selfemp,), wass.any_selfemp )   
    #fixme total people to common     
    map_one!.( (was_summaries,), (:num_adults,), shs.total_people.(wass.num_adults, false )) 
    map_one!.( (was_summaries,), (:num_children,), shs.total_people.(wass.num_children, true )) 
    map_one!.( (was_summaries,), (:agehigh,), was.map_age_hrp.(wass.age_head)) 
    map_one!.( (was_summaries,), (:marstat,), was.map_marital.(wass.marital_status_head))
    map_one!.( (was_summaries,), (:socio,), was.map_socio.(wass.socio_economic_head))
    map_one!.( (was_summaries,), (:empstat,), was.map_empstat.(wass.empstat_head))
    for hno in 1:settings.num_households
        hh = FRSHouseholdGetter.get_household(hno)
        cts = mm.counts_for_match( hh )
        map_one!( model_summaries, :region, mm.map_region( hh.region ))
        map_one!( model_summaries, :tenure, shs.shs_model_tenure( hh.tenure ))
        map_one!( model_summaries, :acctype, shs.model_to_shs_accommap(hh.dwelling)) 
        map_one!( model_summaries, :bedrooms, shs.bedrooms( hh.bedrooms )) 
        map_one!( model_summaries, :hh_composition, shs.model_shs_map_composition( household_composition_1(hh)))
        map_one!( model_summaries, :num_adults, cts.num_adults )
        map_one!( model_summaries, :num_children, cts.num_children )
        map_one!( model_summaries, :any_wages, cts.any_wages )
        map_one!( model_summaries, :any_pension_income, cts.any_pension_income )
        map_one!( model_summaries, :any_selfemp, cts.any_selfemp )     
        head = get_head(hh)   
        # age!! 
        map_one!( model_summaries, :empstat, was.model_was_map_empstat( head.employment_status))
        map_one!( model_summaries, :marstat, mm.map_marital( head.marital_status))
        map_one!( model_summaries, :socio, was.model_was_map_socio( head.socio_economic_grouping))     
    end
    pretty_table( to_pct(was_summaries ))
    pretty_table( to_pct(model_summaries ))
end

@testset "SHS Mappings" begin
    shss = shs.create_shs(2018:2022)
    model_summaries = one_shs_model_summary_df()
    shs_summaries = one_shs_model_summary_df()
    map_one!.( (shs_summaries,), (:shelter,), shss.accsup1 )
    map_one!.( (shs_summaries,), (:tenure,), shs.tenuremap.(shss.tenure)) 
    map_one!.( (shs_summaries,), (:acctype,), shs.accomtype.(shss.hb1, shss.hb2) ) 
    map_one!.( (shs_summaries,), (:bedrooms,), shs.bedrooms.(shss.hc4 )) 
    map_one!.( (shs_summaries,), (:hh_composition,), shs.map_composition.(shss.hhtype_new ))
    map_one!.((shs_summaries,), (:num_adults,), shs.total_people.(shss.totads, false )) 
    map_one!.( (shs_summaries,), (:num_children,), shs.total_people.(shss.numkids, true )) 
    map_one!.( (shs_summaries,), (:agehigh,), shs.age.(shss.hihage )) 
    map_one!.( (shs_summaries,), (:empstathigh,), shs.empstat.(shss.hihecon )) 
    map_one!.( (shs_summaries,), (:ethnichigh,), shs.ethnic.(shss.hih_eth2012 )) 
    map_one!.( (shs_summaries,), (:sochigh,), shs.map_social.(shss.hihsoc )) 
    map_one!.( (shs_summaries,), (:datayear,), shss.datayear .- 2017 ) 
    for hno in 1:settings.num_households
        hh = FRSHouseholdGetter.get_household(hno)
        cts = mm.counts_for_match( hh )
        map_one!( model_summaries, :region, mm.map_region( hh.region ))
        map_one!( model_summaries, :tenure, shs.shs_model_tenure( hh.tenure ))
        map_one!( model_summaries, :acctype, shs.model_to_shs_accommap(hh.dwelling)) 
        map_one!( model_summaries, :bedrooms, shs.bedrooms( hh.bedrooms )) 
        map_one!( model_summaries, :hh_composition, shs.model_shs_map_composition( household_composition_1(hh)))
        map_one!( model_summaries, :num_adults, cts.num_adults )
        map_one!( model_summaries, :num_children, cts.num_children )
        head = get_head(hh)   
        map_one!( model_summaries, :agehigh, shs.age.(head.age ))
        map_one!( model_summaries, :empstathigh, shs.shs_model_empstat(head.employment_status))
        map_one!( model_summaries, :ethnichigh, shs.shs_model_ethnic(head.ethnic_group))
        map_one!( model_summaries, :sochigh, shs.shs_model_map_social( head.occupational_classification )) 
    end # households
    pretty_table( to_pct(shs_summaries ))
    pretty_table( to_pct(model_summaries ))
end


@testset "LCF Mappings" begin
    model_summaries = one_lcf_model_summary_df()
    lcf_summaries = one_lcf_model_summary_df()
    lcfs = lcf.create_subset()
    map_one!.( (lcf_summaries,), (:acctype,), lcf.map_marital.(lcfs.a006p, lcfs.hrp_has_partner ))
    map_one!.( (lcf_summaries,), (:marstat,), lcf.map_marital.(lcfs.a006p, lcfs.hrp_has_partner ))
    map_one!.( (lcf_summaries,), (:socio,), lcf.map_socio.( lcfs.a094 ))
    map_one!.( (lcf_summaries,), (:empstat,), lcf.map_empstat.( lcfs.a206, lcfs.a005p ))
    map_one!.( (lcf_summaries,), (:tenure,), lcf.map_tenure.(lcfs.a121 ))
    map_one!.( (lcf_summaries,), (:region,), lcf.map_region.( lcfs.gorx ))
    map_one!.( (lcf_summaries,), (:num_people,), lcfs.num_people )
    map_one!.( (lcf_summaries,), (:num_children,), lcfs.num_children )
    map_one!.( (lcf_summaries,), (:any_disabled,), lcfs.has_disabled_member )
    map_one!.( (lcf_summaries,), (:has_female_adult,), lcfs.has_female_adult )
    map_one!.( (lcf_summaries,), (:num_employees,), lcfs.num_employees )
    map_one!.( (lcf_summaries,), (:num_pensioners,), lcfs.num_pensioners )
    map_one!.( (lcf_summaries,), (:num_fulltime,), lcfs.num_fulltime )
    map_one!.( (lcf_summaries,), (:num_parttime,), lcfs.num_parttime )
    map_one!.( (lcf_summaries,), (:num_selfemp,), lcfs.num_selfemp )
    map_one!.( (lcf_summaries,), (:num_unemployed,), lcfs.num_unemployed )
    map_one!.( (lcf_summaries,), (:num_unoccupied,), lcfs.num_unoccupied )
    map_one!.( (lcf_summaries,), (:hrp_has_partner,), lcfs.hrp_has_partner )
    map_one!.( (lcf_summaries,), (:any_wages,), lcfs.any_wages )
    map_one!.( (lcf_summaries,), (:any_pension_income,), lcfs.any_pension_income )
    map_one!.( (lcf_summaries,), (:any_selfemp,), lcfs.any_selfemp )        
    for hno in 1:settings.num_households
        hh = FRSHouseholdGetter.get_household(hno)
        cts = mm.counts_for_match( hh )
        map_one!( model_summaries, :region, mm.map_region( hh.region ))
        map_one!( model_summaries, :tenure, mm.map_tenure( hh.tenure ))
        head = get_head(hh)   
        map_one!( model_summaries, :socio, lcf.model_lcf_map_socio( head.socio_economic_grouping, head.employment_status ))
        map_one!( model_summaries, :empstat, lcf.map_empstat( head.employment_status ))           
        map_one!( model_summaries, :marstat, lcf.map_marital( head.marital_status ))
        map_one!( model_summaries, :num_people, cts.num_people )
        map_one!( model_summaries, :num_children, cts.num_children )
        map_one!( model_summaries, :any_disabled, cts.has_disabled_member )
        map_one!( model_summaries, :has_female_adult, cts.has_female_adult )
        map_one!( model_summaries, :num_employees, cts.num_employees )
        map_one!( model_summaries, :num_pensioners, cts.num_pensioners )
        map_one!( model_summaries, :num_fulltime, cts.num_fulltime )
        map_one!( model_summaries, :num_parttime, cts.num_parttime )
        map_one!( model_summaries, :num_selfemp, cts.num_selfemp )
        map_one!( model_summaries, :num_unemployed, cts.num_unemployed )
        map_one!( model_summaries, :num_unoccupied, cts.num_unoccupied )
        map_one!( model_summaries, :hrp_has_partner, cts.hrp_has_partner )
        map_one!( model_summaries, :any_wages, cts.any_wages )
        map_one!( model_summaries, :any_pension_income, cts.any_pension_income )
        map_one!( model_summaries, :any_selfemp, cts.any_selfemp )        
    end
    pretty_table( to_pct(lcf_summaries ))
    pretty_table( to_pct(model_summaries ))
end