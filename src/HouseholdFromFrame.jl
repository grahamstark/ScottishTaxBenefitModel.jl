module HouseholdFromFrame

#
# This module maps from flat-ish DataFrames containing FRS/SHS/Example data to 
# our Household/Person structures from ModelHouseholds.jl. It also does some incidental calculations -
# equivalence scales and ratios of recorded benefits to standard entitlements.
#

using DataFrames
using StatsBase
# using CSVFiles

using ScottishTaxBenefitModel
using .Definitions
using .ModelHousehold
using .TimeSeriesUtils
using .HistoricBenefits: 
    make_benefit_ratios!, 
    switch_dla_to_pip!
using .EquivalenceScales: EQScales
using .Utils: not_zero_or_missing
using .Randoms: strtobi
using .RunSettings
using .Pensions: impute_employer_pension!

export 
    create_regression_dataframe,
    load_hhld_from_frame, 
    map_hhld 

const ZERO_EQ_SCALE = EQScales(0.0,0.0,0.0,0.0,0.0,0.0,0.0)

"""
A vector which is 1 if element is one of the things, 0 otherwise.
"""
function in_vect( f :: Vector, things... )::Vector{Int}
    nr = size(f)[1]
    its = [Int.( collect(things))]; 
    return in.(Int.(coalesce.(f,-1)),its)
end

"""
 Create the dataframe used in the regressions for (e.g) disability
 by joining the household and person frames, and adding
 some disability fields
"""
function create_regression_dataframe(
    model_households :: DataFrame,
    model_people :: DataFrame ) :: DataFrame

    fm = innerjoin( model_households, model_people, on=[:data_year, :hid ],makeunique=true )
    nrows,ncols = size( fm )
    fm.age_sq = fm.age.^2
    fm.cons = ones( nrows )
    fm.deaf_blind=fm.registered_blind .| fm.registered_deaf .| fm.registered_partially_sighted
    fm.yr = fm.data_year .- 2014
    fm.any_dis = (
        fm.disability_vision .|
        fm.disability_hearing .|
        fm.disability_mobility .|
        fm.disability_dexterity .|
        fm.disability_learning .|
        fm.disability_memory .|
        fm.disability_other_difficulty .|
        fm.disability_mental_health .|
        fm.disability_stamina .|
        fm.disability_socially )
    fm.adls_bad=fm.adls_are_reduced.==1
    fm.adls_mid=fm.adls_are_reduced.==2
    fm.rec_dla = ( fm.income_dlamobility.>0.0) .| ( fm.income_dlaself_care .>0.0 )
    fm.rec_dla_care = ( fm.income_dlaself_care .>0.0 )
    fm.rec_dla_mob = ( fm.income_dlamobility.>0.0 )
    fm.rec_pip = ( fm.income_personal_independence_payment_mobility.>0.0) .| ( fm.income_personal_independence_payment_daily_living .>0.0 )
    fm.rec_pip_care = ( fm.income_personal_independence_payment_daily_living .>0.0 )
    fm.rec_pip_mob = ( fm.income_personal_independence_payment_mobility.>0.0)
    fm.rec_esa = ( fm.income_employment_and_support_allowance.>0.0)
    fm.rec_aa = ( fm.income_attendance_allowance.>0.0)
    fm.rec_carers = ( fm.income_carers_allowance.>0.0)
    fm.rec_aa = ( fm.income_attendance_allowance.>0.0)
    
    fm.scotland = fm.region .== 299999999

    ## these rather cryptic names below are to match Howard' Stata regressions.
    ## FIXME make them all consistent 
    fm.mlogbhc = zeros(nrows)
    fm.gor_nw = Int.(fm.region .== Int(North_West))
    fm.gor_yh = Int.(fm.region .== Int(Yorks_and_the_Humber))
    fm.gor_em = Int.(fm.region .== Int(East_Midlands))
    fm.gor_wm = Int.(fm.region .== Int(West_Midlands))
    fm.gor_ee = Int.(fm.region .== Int(East_of_England))
    fm.gor_lo = Int.(fm.region .== Int(London))
    fm.gor_se = Int.(fm.region .== Int(South_East))
    fm.gor_sw = Int.(fm.region .== Int(South_West))
    fm.gor_wa = Int.(fm.region .== Int(Wales))
    fm.gor_sc = Int.(fm.region .== Int(Scotland))
    fm.gor_ni = Int.(fm.region .== Int(Northern_Ireland))
    fm.ten_own = in_vect(fm.tenure,Owned_outright, Mortgaged_Or_Shared )
    fm.ten_sr = in_vect(fm.tenure,Council_Rented, Housing_Association )

    fm.male = Int.(fm.sex .== 1) 
    fm.female = Int.(fm.sex .== 2)

    eg = safe_assign.(fm.ethnic_group)

    fm.race_ms = Int.( eg .== Int(Missing_Ethnic_Group))
    fm.race_mx = Int.( eg .== Int(Mixed_or_Multiple_ethnic_groups))
    fm.race_as = Int.( eg .== Int(Asian_or_Asian_British ))
    fm.race_bl = Int.( eg .== Int(Black_or_African_or_Caribbean_or_Black_British ))
    fm.race_ot = Int.( eg  .== Int(Other_ethnic_group ))
    fm.born_m = zeros(nrows)
    fm.born_uk = zeros(nrows)
    fm.llsid = safe_to_bool.(fm.has_long_standing_illness) .| (fm.adls_bad)
    ms = safe_assign.(fm.marital_status)
    fm.marciv = Int.(ms .== Int(Married_or_Civil_Partnership))
    fm.divsep = in_vect(ms, Separated,Divorced_or_Civil_Partnership_dissolved )
    fm.widow = in_vect(ms, Widowed )

    fm.age2534 = Int.(in.(fm.age, [25:34] ))
    fm.age3544 = Int.(in.(fm.age, [35:44] ))
    fm.age4554 = Int.(in.(fm.age, [45:54] ))

    # FIXME check HR 5564
    fm.age5565 = Int.(in.(fm.age, [55:64] ))
    fm.age6574 = Int.(in.(fm.age, [65:74] ))
    fm.age75 = Int.(in.(fm.age,[75:200]))
    hq = Qualification_Type.(safe_assign.(fm.highest_qualification))
    fm.hq_deg = Int.(highqual_degree_equiv.( hq ))
    fm.hq_ohe = Int.(highqual_other_he.( hq ))
    fm.hq_al = Int.(highqual_alevel_equiv.( hq ))
    fm.hq_gcse = Int.(highqual_gcse_equiv.( hq ))
    fm.hq_oth = Int.(highqual_other.( hq))
    es = safe_assign.( fm.employment_status )
    fm.ec_emp = in_vect(es, Full_time_Employee, Part_time_Employee )
    fm.ec_se = in_vect(es, Full_time_Self_Employed,Part_time_Self_Employed )
    fm.ec_fam = in_vect(es, Looking_after_family_or_home )
    fm.ec_un = in_vect(es, Unemployed )
    fm.ec_ret = in_vect(es, Retired )

    fm.q1mlog = zeros(nrows)
    fm.q2mlog = zeros(nrows)
    fm.q3mlog = zeros(nrows)
    fm.q4mlog = zeros(nrows)
    fm.q5mlog = zeros(nrows)
    fm.mlogbhc = zeros(nrows)

    fm.rural = zeros(nrows) # missing from frs public version

    ## region renames for my wealth and housing regressions - 
    ## this eats memory, obs, but still...

    fm.wales = fm.gor_wa  
    fm.london = fm.gor_lo  
    fm.north_west = fm.gor_nw
    fm.yorkshire = fm.gor_yh 
    fm.east_midlands = fm.gor_em
    fm.west_midlands = fm.gor_wm  
    fm.east_of_england = fm.gor_ee
    fm.south_east = fm.gor_se 
    fm.south_west = fm.gor_sw

    fm.age_u_25 = Int.(in.(fm.age, [0:24] ))
    fm.age_25_34 = fm.age2534 
    fm.age_35_44 = fm.age3544
    fm.age_45_54 = fm.age4554
    fm.age_55_64 = fm.age5565 # check
    fm.age_65_74 = fm.age6574
    fm.age_75_plus = fm.age75

    fm.employee = in_vect(es, Full_time_Employee, Part_time_Employee )
    fm.selfemp = in_vect(es, Full_time_Self_Employed,Part_time_Self_Employed )
    fm.inactive = in_vect(es, Looking_after_family_or_home, Other_Inactive )
    fm.unemployed = in_vect(es, Unemployed )
    fm.student = in_vect(es, Student )
    fm.sick = in_vect(es, Permanently_sick_or_disabled, Temporarily_sick_or_injured )
    fm.retired = in_vect(es, Retired )

    fm.log_weekly_gross_income = log.( max.(0.0001, fm.original_gross_income))
    fm.weekly_gross_income = fm.original_gross_income
    fm.detatched = in_vect( fm.dwelling, detatched )
    fm.semi = in_vect( fm.dwelling, semi_detached )
    fm.terraced = in_vect( fm.dwelling, terraced )
    fm.purpose_build_flat = in_vect(fm.dwelling, flat_or_maisonette )
    fm.converted_flat = in_vect(fm.dwelling, converted_flat )

    fm.managerial = in_vect(fm.socio_economic_grouping, 
        Employers_in_large_organisations,
        Higher_managerial_occupations,
        Lower_managerial_occupations,
        Higher_supervisory_occupations, 
        Higher_professional_occupations_New_self_employed,
        Lower_supervisory_occupations )

    fm.intermediate = in_vect(fm.socio_economic_grouping, 
        Lower_prof_and_higher_technical_Traditional_employee,
        Lower_technical_craft,
        Own_account_workers_non_professional )

    fm.routine = in_vect(fm.socio_economic_grouping,
        Lower_technical_craft,
        Semi_routine_sales,
        Routine_sales_and_service )

    fm.num_people = zeros(Int,nrows)
    fm.num_adults = zeros(Int,nrows)
    fm.num_children = zeros(Int,nrows)

    hhlds = groupby( fm, [:hid,:data_year])
    for hhld in hhlds 
        hhld.num_children .= Int.(sum( hhld.from_child_record ))
        hhld.num_people .= Int.(size( hhld )[1])
        hhld.num_adults .= Int.(hhld.num_people - hhld.num_children)
    end

    fm.owner = in_vect( fm.tenure, Owned_outright )
    fm.mortgaged = in_vect( fm.tenure, Mortgaged_Or_Shared )
    fm.renter = in_vect( fm.tenure, Council_Rented,
        Housing_Association,
        Private_Rented_Unfurnished,
        Private_Rented_Furnished )

    fm.is_hrp = coalesce.(fm.is_hrp,0)

    ## wealth for head only
    fm[fm.is_hrp.==0,[:net_housing_wealth,:net_pension_wealth,:net_financial_wealth,:net_physical_wealth]] .= 0.0

    #
    # added for legal aid, matching scjs - see scjs_mappings.jl, civil_problems-scjs.jl in regressions/
    # 
    fm.lives_in_flat = fm.purpose_build_flat .| fm.converted_flat
    fm.non_white = fm.race_mx .| fm.race_as .| fm.race_bl .| fm.race_ot 
    fm.is_carer = fm.rec_carers .| fm.is_informal_carer
    fm.single_parent = (fm.num_children .> 0) .& (fm.num_adults .== 1) # FIXME this is hhld level 
    fm.divorced_or_separated = in_vect( fm.marital_status, Separated, Divorced_or_Civil_Partnership_dissolved )
    fm.out_of_labour_market = fm.inactive .| fm.unemployed .| fm.student .| fm.retired 
    fm.is_limited = in_vect(fm.adls_are_reduced, reduced_a_lot, reduced_a_little ) .| (fm.has_long_standing_illness .== 1)
    fm.health_good_or_better = in_vect( fm.health_status, Very_Good, Good )
    fm.has_condition = coalesce.( fm.any_dis .| fm.adls_bad .| fm.adls_mid .| fm.is_limited, 0 )
    fm.agesq = fm.age .^2
    #
    # 2nd
    #

    return fm
end

function map_person( 
    hh           :: Household, 
    model_person :: DataFrameRow, 
    source       :: DataSource, 
    settings     :: Settings  )
    income = Dict{Incomes_Type,Float64}()

    for i in instances(Incomes_Type)
        ikey = make_sym_for_frame("income", i)
        if ! ismissing(model_person[ikey])
            if model_person[ikey] != 0.0
                v = model_person[ikey] # this is a hack because in j 1.3 csv is parsing many cols as strings & I don't understand why
                tv = typeof(v)
                if tv == String # FIXME delete not needed
                    v = parse( Float64, v )
                end
                # println( "setting ikey = $ikey to $v of type $tv")
                income[i] = v
            end
        end
    end
    #
    # override wages and se
    #
    if settings.income_data_source == ds_frs
        income[wages] = m2z(model_person.wages_frs)
        income[self_employment_income] = m2z(model_person.self_emp_frs)
    else # not really needed since hbai is the default
        income[wages] = m2z(model_person.wages_hbai)
        income[self_employment_income] = m2z(model_person.self_emp_hbai)
    end
    pay_includes  = Included_In_Pay_Dict{Bool}()
    for i in instances(Included_In_Pay_Type)
        s = String(Symbol(i))
        ikey = Symbol(lowercase("pay_includes_" * s))
        if ! ismissing(model_person[ikey])
            if model_person[ikey] == 1
                pay_includes[i] = true
            end
        end
    end
    
    assets = Dict{Asset_Type,Float64}() # fixme asset_type_dict
    for i in instances(Asset_Type)
        if i != Missing_Asset_Type
            ikey = make_sym_for_asset( i )
            if ! ismissing(model_person[ikey])
                v = model_person[ikey]
                if typeof(v) == String
                    v = parse( Float64, v )
                end
                if model_person[ikey] != 0.0
                    assets[i] = model_person[ikey]
                end
            end
        end
    end

    disabilities = Dict{Disability_Type,Bool}()
    for i in instances(Disability_Type)
        ikey = make_sym_for_frame("disability", i)
        if ! ismissing(model_person[ikey])
            if model_person[ikey] == 1
                disabilities[i] = Bool(model_person[ikey])
            end
        end
    end

    bereavement_type = missing 
    if not_zero_or_missing( model_person.income_bereavement_allowance_or_widowed_parents_allowance_or_bereavement ) ||
       not_zero_or_missing( model_person.income_widows_payment )
        if interview_date( hh ) < FY_2017        
            bereavement_type = 2 # widowed parents allow    
        else
            @assert ! ismissing( model_person.type_of_bereavement_allowance )
            bereavement_type = model_person.type_of_bereavement_allowance
            # hack for 1 household: pid 120210849301 
            if bereavement_type == -1
                bereavement_type = 1
            end
        end
    end
    relationships = Relationship_Dict()
    for i in 1:14
        relmod = Symbol( "relationship_$(i)") # :relationship_10 or :relationship_2
        irel = model_person[relmod]
        if (! ismissing( irel )) & ( irel >= 0 )
            pid = get_pid(
                source,
                model_person.data_year,
                model_person.hid,
                i )
            relationships[pid] = Relationship( irel )
        end
    end

    benefit_ratios = Incomes_Dict{Float64}()
    
    pers = Person{Float64}(

        BigInt(model_person.hid),  # BigInt# == sernum
        BigInt(model_person.pid),  # BigInt# == unique id (year * 100000)+
        model_person.pno,  # Integer# person number in household
        safe_to_bool(model_person.is_hrp), 
        model_person.default_benefit_unit,  # Integer
        safe_to_bool(model_person.from_child_record), # Bool
        model_person.age,  # Integer
        Sex(model_person.sex),  # Sex
        Ethnic_Group(safe_assign(model_person.ethnic_group)),  # Ethnic_Group
        Marital_Status(safe_assign(model_person.marital_status)),  # Marital_Status
        Qualification_Type(safe_assign(model_person.highest_qualification)),  # Qualification_Type

        SIC_2007(safe_assign(model_person.sic)),  # SIC_2007
        Standard_Occupational_Classification(safe_assign(model_person.occupational_classification)),  # Standard_Occupational_Classification
        Employment_Sector(safe_assign(model_person.public_or_private)),  #  Employment_Sector
        Employment_Type(safe_assign(model_person.principal_employment_type)),  #  Employment_Type

        Socio_Economic_Group(safe_assign(model_person.socio_economic_grouping)),  # Socio_Economic_Group
        m2z(model_person.age_completed_full_time_education),  # Integer
        m2z(model_person.years_in_full_time_work),  # Integer
        ILO_Employment(safe_assign(model_person.employment_status)),  # ILO_Employment
        m2z(model_person.actual_hours_worked),  # Real
        m2z(model_person.usual_hours_worked),  # Real

        m2z(model_person.age_started_first_job),

        income,
        benefit_ratios,
        
        JSAType(safe_assign(model_person.jsa_type)),
        JSAType(safe_assign(model_person.esa_type)),
        
        LowMiddleHigh( safe_assign( model_person.dlaself_care_type )),
        LowMiddleHigh( safe_assign( model_person.dlamobility_type)),
        LowMiddleHigh( safe_assign( model_person.attendance_allowance_type )),
        PIPType( safe_assign( model_person.personal_independence_payment_daily_living_type )),
        PIPType( safe_assign( model_person.personal_independence_payment_mobility_type )),
        BereavementType( safe_assign( bereavement_type )),
        safe_to_bool(model_person.had_children_when_bereaved), 
        
        assets,
        safe_to_bool(model_person.over_20_k_saving),

        pay_includes,

        safe_to_bool(model_person.registered_blind),
        safe_to_bool(model_person.registered_partially_sighted),
        safe_to_bool(model_person.registered_deaf),

        disabilities,

        Health_Status(safe_assign(model_person.health_status)),

        safe_to_bool(model_person.has_long_standing_illness),
        ADLS_Inhibited(model_person.adls_are_reduced),
        Illness_Length(model_person.how_long_adls_reduced),

        relationships,
        Relationship(model_person.relationship_to_hoh),
        safe_to_bool(model_person.is_informal_carer),
        safe_to_bool(model_person.receives_informal_care_from_non_householder),
        m2z(model_person.hours_of_care_received),
        m2z(model_person.hours_of_care_given),
        m2z(model_person.hours_of_childcare),
        m2z(model_person.cost_of_childcare),
        Child_Care_Type(safe_assign(model_person.childcare_type )),
        safe_to_bool( model_person.employer_provides_child_care ),

        Fuel_Type( m2z(model_person.company_car_fuel_type )),
        m2z(model_person.company_car_value),
        m2z(model_person.company_car_contribution),
        m2z(model_person.fuel_supplied),
        strtobi(model_person.onerand),
        nothing # legal aid added as needed 
    )
    # FIXME we need a separate switch for make benefit ratios 
    if settings.benefit_generosity_estimates_available
        make_benefit_ratios!( 
            pers, hh.interview_year, hh.interview_month )
        switch_dla_to_pip!( pers, hh.interview_year, hh.interview_month )
    end
    if settings.impute_employer_pension
        impute_employer_pension!( pers )
    end
    return pers;
end

function map_hhld( hno::Integer, frs_hh :: DataFrameRow, settings :: Settings )

    people = People_Dict{Float64}()
    head_of_household = BigInt(-1) # this is set when we scan the actual people below
    hh = Household{Float64}(
        hno,
        frs_hh.hid,
        frs_hh.data_year, 
        frs_hh.interview_year,
        frs_hh.interview_month,
        frs_hh.quarter,
        Tenure_Type(frs_hh.tenure),
        Standard_Region(frs_hh.region),
        CT_Band(frs_hh.ct_band),
        DwellingType( frs_hh.dwelling ),
        m2z(frs_hh.council_tax),
        m2z(frs_hh.water_and_sewerage ),
        m2z(frs_hh.mortgage_payment),
        m2z(frs_hh.mortgage_interest),
        m2z(frs_hh.years_outstanding_on_mortgage),
        m2z(frs_hh.mortgage_outstanding),
        m2z(frs_hh.year_house_bought),
        m2z(frs_hh.gross_rent),
        safe_to_bool(frs_hh.rent_includes_water_and_sewerage),
        m2z(frs_hh.other_housing_charges),
        m2z(frs_hh.gross_housing_costs),
        # m2z(frs_hh.total_income),
        m2z(frs_hh.total_wealth),
        m2z(frs_hh.house_value),
        m2z(frs_hh.weight),
        Symbol( frs_hh.council ),
        Symbol( frs_hh.nhs_board ),
        frs_hh.bedrooms,
        head_of_household,
        frs_hh.net_physical_wealth,
        frs_hh.net_financial_wealth,
        frs_hh.net_housing_wealth,
        frs_hh.net_pension_wealth,
        frs_hh.original_gross_income,
        -1, # original_income_decile
        -1, # equiv_original_income_decile
        nothing, # Recorded expenditure; loaded afterwards as needed.
        nothing, # Expenditure factor costs i.e. minus taxes.
        people,        
        strtobi(frs_hh.onerand),
        ZERO_EQ_SCALE )
    return hh
end

function load_hhld_from_frame( 
    hseq     :: Integer, 
    hhld_fr  :: DataFrameRow, 
    pers_fr  :: DataFrame, 
    source   :: DataSource, 
    settings :: Settings ) :: Household
    hh = map_hhld( hseq, hhld_fr, settings )
    pers_fr_in_this_hh = pers_fr[((pers_fr.data_year .== hhld_fr.data_year).&(pers_fr.hid .== hh.hid)),:]
    npers = size( pers_fr_in_this_hh )[1]
    @assert npers in 1:19
    head_of_household = -1
    for p in 1:npers
        pers = map_person( hh, pers_fr_in_this_hh[p,:], source, settings )
        hh.people[pers.pid] = pers
        if pers.relationship_to_hoh == This_Person
            hh.head_of_household = pers.pid
        end
    end
    # rewrite the eq scale once we know everything
    make_eq_scales!( hh )
    # infer_wealth!( hh )    
    @assert hh.head_of_household !== -1
    return hh
end

end # module
