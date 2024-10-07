module HouseholdFromFrame

#
# This module maps from flat-ish DataFrames containing FRS/SHS/Example data to 
# our Household/Person structures from ModelHouseholds.jl. It also does some incidental calculations -
# equivalence scales and ratios of recorded benefits to standard entitlements.
#

using DataFrames
using StatsBase
using CSV
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
    map_hhld,
    read_hh,
    read_pers

const ZERO_EQ_SCALE = EQScales(0.0,0.0,0.0,0.0,0.0,0.0,0.0)


function read_hh( filename :: String ) :: DataFrame 
    hh = CSV.File( filename; delim='\t') |> DataFrame
    hh.hid = BigInt.(hh.hid)
    hh.uhid = BigInt.(hh.uhid)
    hh.tenure = eval.( Symbol.( hh.tenure ))
    hh.region = eval.(Symbol.( hh.region))
    hh.ct_band = eval.(Symbol.( hh.ct_band))
    hh.dwelling  =  eval.(Symbol.( hh.dwelling ))
    hh.council  =  Symbol.(hh.council )
    hh.rent_includes_water_and_sewerage = Bool.(hh.rent_includes_water_and_sewerage)
    hh.nhs_board  =  Symbol.(hh.nhs_board )
    hh.onerand = strtobi.(hh.onerand)
    return hh
end

function read_pers( filename :: String ) :: DataFrame 
    pers = CSV.File( filename; delim='\t' ) |> DataFrame
    pers.pid = BigInt.(pers.pid)
    # pno
#     pers.is_hrp
#     pers.is_bu_head
    # pers.from_child_record = Bool.( pers.from_child_record )
    # default_benefit_unit
    # age
    pers.sex = eval.( Symbol.( pers.sex ))
    pers.ethnic_group = eval.( Symbol.( pers.ethnic_group ))
    pers.marital_status = eval.( Symbol.( pers.marital_status ))
    pers.highest_qualification = eval.( Symbol.( pers.highest_qualification ))
    pers.sic = eval.( Symbol.( pers.sic ))
    pers.occupational_classification = eval.( Symbol.( pers.occupational_classification ))
    pers.public_or_private = eval.( Symbol.( pers.public_or_private ))
    pers.principal_employment_type = eval.( Symbol.( pers.principal_employment_type ))
    pers.socio_economic_grouping = eval.( Symbol.( pers.socio_economic_grouping ))
#     pers.age_completed_full_time_education
#     pers.years_in_full_time_work
    pers.employment_status = eval.( Symbol.( pers.employment_status ))
#     pers.usual_hours_worked
#     pers.actual_hours_worked
#     pers.age_started_first_job
    pers.type_of_bereavement_allowance = eval.( Symbol.( pers.type_of_bereavement_allowance ))
    pers.had_children_when_bereaved = safe_to_bool.( pers.had_children_when_bereaved )
#     pers.pay_includes_ssp
#     pers.pay_includes_smp
#     pers.pay_includes_spp
#     pers.pay_includes_sap
#     pers.pay_includes_mileage
#     pers.pay_includes_motoring_expenses
#     pers.income_wages
#     pers.income_self_employment_income
#     pers.income_self_employment_expenses
#     pers.income_self_employment_losses
#     pers.income_odd_jobs
#     pers.income_private_pensions
#     pers.income_national_savings
#     pers.income_bank_interest
#     pers.income_stocks_shares
#     pers.income_individual_savings_account
#     pers.income_property
#     pers.income_royalties
#     pers.income_bonds_and_gilts
#     pers.income_other_investment_income
#     pers.income_other_income
#     pers.income_alimony_and_child_support_received
#     pers.income_health_insurance
#     pers.income_alimony_and_child_support_paid
#     pers.income_care_insurance
#     pers.income_trade_unions_etc
#     pers.income_friendly_societies
#     pers.income_work_expenses
#     pers.income_avcs
#     pers.income_other_deductions
#     pers.income_loan_repayments
#     pers.income_student_loan_repayments
#     pers.income_pension_contributions_employer
#     pers.income_pension_contributions_employee
#     pers.income_education_allowances
#     pers.income_foster_care_payments
#     pers.income_student_grants
#     pers.income_student_loans
#     pers.income_income_tax
#     pers.income_national_insurance
#     pers.income_local_taxes
#     pers.income_free_school_meals
#     pers.income_dlaself_care
#     pers.income_dlamobility
#     pers.income_child_benefit
#     pers.income_pension_credit
#     pers.income_state_pension
#     pers.income_bereavement_allowance_or_widowed_parents_allowance_or_bereavement
#     pers.income_armed_forces_compensation_scheme
#     pers.income_war_widows_or_widowers_pension
#     pers.income_severe_disability_allowance
#     pers.income_attendance_allowance
#     pers.income_carers_allowance
#     pers.income_jobseekers_allowance
#     pers.income_industrial_injury_disablement_benefit
#     pers.income_employment_and_support_allowance
#     pers.income_incapacity_benefit
#     pers.income_income_support
#     pers.income_maternity_allowance
#     pers.income_maternity_grant_from_social_fund
#     pers.income_funeral_grant_from_social_fund
#     pers.income_any_other_ni_or_state_benefit
#     pers.income_trade_union_sick_or_strike_pay
#     pers.income_friendly_society_benefits
#     pers.income_private_sickness_scheme_benefits
#     pers.income_accident_insurance_scheme_benefits
#     pers.income_hospital_savings_scheme_benefits
#     pers.income_government_training_allowances
#     pers.income_guardians_allowance
#     pers.income_widows_payment
#     pers.income_unemployment_or_redundancy_insurance
#     pers.income_winter_fuel_payments
#     pers.income_child_winter_heating_assistance_payment
#     pers.income_dwp_third_party_payments_is_or_pc
#     pers.income_dwp_third_party_payments_jsa_or_esa
#     pers.income_social_fund_loan_repayment_from_is_or_pc
#     pers.income_social_fund_loan_repayment_from_jsa_or_esa
#     pers.income_extended_hb
#     pers.income_permanent_health_insurance
#     pers.income_any_other_sickness_insurance
#     pers.income_critical_illness_cover
#     pers.income_working_tax_credit
#     pers.income_child_tax_credit
#     pers.income_working_tax_credit_lump_sum
#     pers.income_child_tax_credit_lump_sum
#     pers.income_housing_benefit
#     pers.income_universal_credit
#     pers.income_personal_independence_payment_daily_living
#     pers.income_personal_independence_payment_mobility
#     pers.income_a_loan_from_the_dwp_and_dfc
#     pers.income_a_loan_or_grant_from_local_authority
#     pers.income_social_fund_loan_uc
#     pers.income_other_benefits
#     pers.income_scottish_child_payment
#     pers.income_job_start_payment
#     pers.income_troubles_permanent_disablement
#     pers.income_child_disability_payment_care
#     pers.income_child_disability_payment_mobility
#     pers.income_pupil_development_grant
#     pers.wages_frs
#     pers.self_emp_frs
#     pers.wages_hbai
#     pers.self_emp_hbai
    pers.jsa_type = eval.( Symbol.( pers.jsa_type ))
    pers.esa_type = eval.( Symbol.( pers.esa_type ))
    # @show pers.dlaself_care_type
    pers.dlaself_care_type = eval.( Symbol.( pers.dlaself_care_type ))
    # @show pers.dlaself_care_type
    pers.dlamobility_type = eval.( Symbol.( pers.dlamobility_type ))
    pers.attendance_allowance_type = eval.( Symbol.( pers.attendance_allowance_type ))
    pers.personal_independence_payment_daily_living_type = eval.( Symbol.( pers.personal_independence_payment_daily_living_type ))
    pers.personal_independence_payment_mobility_type = eval.( Symbol.( pers.personal_independence_payment_mobility_type ))
#     pers.over_20_k_saving
#    println("#1")
#     pers.asset_current_account
#     pers.asset_nsb_ordinary_account
#     pers.asset_nsb_investment_account
#     pers.asset_not_used
#     pers.asset_savings_investments_etc
#     pers.asset_government_gilt_edged_stock
#     pers.asset_unit_or_investment_trusts
#     pers.asset_stocks_shares_bonds_etc
#     pers.asset_pep
#     pers.asset_national_savings_capital_bonds
#     pers.asset_index_linked_national_savings_certificates
#     pers.asset_fixed_interest_national_savings_certificates
#     pers.asset_pensioners_guaranteed_bonds
#     pers.asset_saye
#     pers.asset_premium_bonds
#     pers.asset_national_savings_income_bonds
#     pers.asset_national_savings_deposit_bonds
#     pers.asset_first_option_bonds
#     pers.asset_yearly_plan
#     pers.asset_isa
#     pers.asset_fixd_rate_svngs_bonds_or_grntd_incm_bonds_or_grntd_growth_bonds
#     pers.asset_geb
#     pers.asset_basic_account
#     pers.asset_credit_unions
#     pers.asset_endowment_policy_not_linked
#     pers.asset_informal_assets
#     pers.asset_post_office_card_account
#     pers.asset_friendly_society_investment
#    println("#2")
    # contracted_out_of_serps
#     pers.registered_blind
#     pers.registered_partially_sighted
#     pers.registered_deaf
#     pers.disability_vision
#     pers.disability_hearing
#     pers.disability_mobility
#     pers.disability_dexterity
#     pers.disability_learning
#     pers.disability_memory
#     pers.disability_mental_health
#     pers.disability_stamina
#     pers.disability_socially
#     pers.disability_other_difficulty
    pers.health_status = eval.( Symbol.( pers.health_status ))
#     pers.has_long_standing_illness
    pers.adls_are_reduced = eval.( Symbol.( pers.adls_are_reduced ))
    pers.how_long_adls_reduced = eval.( Symbol.( pers.how_long_adls_reduced ))
#     pers.is_informal_carer
#     pers.receives_informal_care_from_non_householder
#     pers.hours_of_care_received
#     pers.hours_of_care_given
#     pers.hours_of_childcare
#     pers.cost_of_childcare
    pers.childcare_type = eval.( Symbol.( pers.childcare_type ))
#     pers.employer_provides_child_care
#     pers.work_expenses 
#     pers.travel_to_work
#     pers.debt_repayments
#     pers.wealth_and_assets
#     pers.totsav
    pers.company_car_fuel_type = eval.( Symbol.( pers.company_car_fuel_type ))
#     pers.company_car_value
#     pers.company_car_contribution
#     pers.fuel_supplied
    pers.relationship_to_hoh = eval.( Symbol.( pers.relationship_to_hoh ))
    pers.relationship_1 = eval.( Symbol.( pers.relationship_1 ))
    pers.relationship_2 = eval.( Symbol.( pers.relationship_2 ))
    pers.relationship_3 = eval.( Symbol.( pers.relationship_3 ))
    pers.relationship_4 = eval.( Symbol.( pers.relationship_4 ))
    pers.relationship_5 = eval.( Symbol.( pers.relationship_5 ))
    pers.relationship_6 = eval.( Symbol.( pers.relationship_6 ))
    pers.relationship_7 = eval.( Symbol.( pers.relationship_7 ))
    pers.relationship_8 = eval.( Symbol.( pers.relationship_8 ))
    pers.relationship_9 = eval.( Symbol.( pers.relationship_9 ))
    pers.relationship_10 = eval.( Symbol.( pers.relationship_10 ))
    pers.relationship_11 = eval.( Symbol.( pers.relationship_11 ))
    pers.relationship_12 = eval.( Symbol.( pers.relationship_12 ))
    pers.relationship_13 = eval.( Symbol.( pers.relationship_13 ))
    pers.relationship_14 = eval.( Symbol.( pers.relationship_14 ))
    pers.relationship_15 = eval.( Symbol.( pers.relationship_15 ))
    # println("#3")
    pers.onerand = strtobi.(pers.onerand)
    pers.uhid = BigInt.(pers.uhid)
    # CSV.write( "data/actual_data/model_people_scotland-2015-2021-w-enums.tab", pers )
    return pers
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
    fm.gor_nw = fm.region .== North_West
    fm.gor_yh = fm.region .== Yorks_and_the_Humber
    fm.gor_em = fm.region .== East_Midlands
    fm.gor_wm = fm.region .== West_Midlands
    fm.gor_ee = fm.region .== East_of_England
    fm.gor_lo = fm.region .== London
    fm.gor_se = fm.region .== South_East
    fm.gor_sw = fm.region .== South_West
    fm.gor_wa = fm.region .== Wales
    fm.gor_sc = fm.region .== Scotland
    fm.gor_ni = fm.region .== Northern_Ireland
    fm.ten_own = in.( fm.tenure,( [Owned_outright, Mortgaged_Or_Shared], ))
    fm.ten_sr = in.(fm.tenure, ( [Council_Rented, Housing_Association], ) )

    fm.male = fm.sex .== 1 
    fm.female = fm.sex .== 2

    # eg = safe_assign.(fm.ethnic_group)

    fm.race_ms =  fm.ethnic_group .== Missing_Ethnic_Group
    fm.race_mx =  fm.ethnic_group .== Mixed_or_Multiple_ethnic_groups
    fm.race_as =  fm.ethnic_group .== Asian_or_Asian_British 
    fm.race_bl =  fm.ethnic_group .== Black_or_African_or_Caribbean_or_Black_British 
    fm.race_ot =  fm.ethnic_group .== Other_ethnic_group 
    fm.born_m = zeros(nrows)
    fm.born_uk = zeros(nrows)
    fm.llsid = fm.has_long_standing_illness .| fm.adls_bad
    # ms = safe_assign.(fm.marital_status)
    fm.marciv = fm.marital_status .== Int(Married_or_Civil_Partnership)
    fm.divsep = in.(fm.marital_status , ([Separated,Divorced_or_Civil_Partnership_dissolved],) )
    fm.widow = in.(fm.marital_status, ([Widowed],) )

    fm.age2534 = in.(fm.age, [25:34] )
    fm.age3544 = in.(fm.age, [35:44] )
    fm.age4554 = in.(fm.age, [45:54] )

    # FIXME check HR 5564
    fm.age5565 = in.(fm.age, [55:64] )
    fm.age6574 = in.(fm.age, [65:74] )
    fm.age75 = in.(fm.age,[75:200])
    hq = fm.highest_qualification
    fm.hq_deg = highqual_degree_equiv.( hq )
    fm.hq_ohe = highqual_other_he.( hq )
    fm.hq_al = highqual_alevel_equiv.( hq )
    fm.hq_gcse = highqual_gcse_equiv.( hq )
    fm.hq_oth = highqual_other.( hq)
    # es = safe_assign.( fm.employment_status )
    fm.ec_emp = in.(fm.employment_status, ([Full_time_Employee, Part_time_Employee], ))
    fm.ec_se = in.(fm.employment_status, ([Full_time_Self_Employed,Part_time_Self_Employed],) )
    fm.ec_fam = in.(fm.employment_status, ([Looking_after_family_or_home],) )
    fm.ec_un = in.(fm.employment_status, ([Unemployed],) )
    fm.ec_ret = in.(fm.employment_status, ([Retired],))

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

    fm.age_u_25 = in.(fm.age, [0:24] )
    fm.age_25_34 = fm.age2534 
    fm.age_35_44 = fm.age3544
    fm.age_45_54 = fm.age4554
    fm.age_55_64 = fm.age5565 # check
    fm.age_65_74 = fm.age6574
    fm.age_75_plus = fm.age75

    fm.employee = in.(fm.employment_status, ([Full_time_Employee, Part_time_Employee],) )
    fm.selfemp = in.(fm.employment_status, ([Full_time_Self_Employed,Part_time_Self_Employed],) )
    fm.inactive = in.(fm.employment_status, ([Looking_after_family_or_home, Other_Inactive],) )
    fm.unemployed = in.(fm.employment_status, ([Unemployed],) )
    fm.student = in.(fm.employment_status, ([Student],) )
    fm.sick = in.(fm.employment_status, ([Permanently_sick_or_disabled, Temporarily_sick_or_injured],) )
    fm.retired = in.(fm.employment_status, ([Retired],))

    fm.log_weekly_gross_income = log.( max.(0.0001, fm.original_gross_income))
    fm.weekly_gross_income = fm.original_gross_income
    fm.detatched = in.( fm.dwelling, ([detatched],) )
    fm.semi = in.( fm.dwelling, ([semi_detached],) )
    fm.terraced = in.( fm.dwelling, ([terraced],))
    fm.purpose_build_flat = in.(fm.dwelling, ([flat_or_maisonette],))
    fm.converted_flat = in.(fm.dwelling, ([converted_flat],))

    fm.managerial = in.(fm.socio_economic_grouping, 
        ( [Employers_in_large_organisations,
        Higher_managerial_occupations,
        Lower_managerial_occupations,
        Higher_supervisory_occupations, 
        Higher_professional_occupations_New_self_employed,
        Lower_supervisory_occupations],) )

    fm.intermediate = in.(fm.socio_economic_grouping, 
        ([Lower_prof_and_higher_technical_Traditional_employee,
        Lower_technical_craft,
        Own_account_workers_non_professional],) )

    fm.routine = in.(fm.socio_economic_grouping,
        ([Lower_technical_craft,
        Semi_routine_sales,
        Routine_sales_and_service],) )

    fm.num_people = zeros(Int,nrows)
    fm.num_adults = zeros(Int,nrows)
    fm.num_children = zeros(Int,nrows)

    hhlds = groupby( fm, [:hid,:data_year])
    for hhld in hhlds 
        hhld.num_children .= sum( hhld.from_child_record )
        hhld.num_people .= size( hhld )[1]
        hhld.num_adults .= hhld.num_people - hhld.num_children
    end

    fm.owner = in.( fm.tenure, ([Owned_outright],) )
    fm.mortgaged = in.( fm.tenure, ([Mortgaged_Or_Shared],) )
    fm.renter = in.( fm.tenure, ([Council_Rented,
        Housing_Association,
        Private_Rented_Unfurnished,
        Private_Rented_Furnished], ))

    # fm.is_hrp = coalesce.(fm.is_hrp,0)

    ## wealth for head only
    fm[ .!fm.is_hrp,[:net_housing_wealth,:net_pension_wealth,:net_financial_wealth,:net_physical_wealth]] .= 0.0

    #
    # added for legal aid, matching scjs - see scjs_mappings.jl, civil_problems-scjs.jl in regressions/
    # 
    fm.lives_in_flat = fm.purpose_build_flat .| fm.converted_flat
    fm.non_white = fm.race_mx .| fm.race_as .| fm.race_bl .| fm.race_ot 
    fm.is_carer = fm.rec_carers .| fm.is_informal_carer
    fm.single_parent = (fm.num_children .> 0) .& (fm.num_adults .== 1) # FIXME this is hhld level 
    fm.divorced_or_separated = in.( fm.marital_status, ([Separated, Divorced_or_Civil_Partnership_dissolved],) )
    fm.out_of_labour_market = fm.inactive .| fm.unemployed .| fm.student .| fm.retired 
    fm.is_limited = in.(fm.adls_are_reduced, ([reduced_a_lot, reduced_a_little],) ) .| (fm.has_long_standing_illness )
    fm.health_good_or_better = in.( fm.health_status, ([Very_Good, Good],) )
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
    settings     :: Settings  )
    income = Dict{Incomes_Type,Float64}()

    for i in instances(Incomes_Type)
        ikey = make_sym_for_frame("income", i)
        if model_person[ikey] != 0.0
            income[i] = model_person[ikey]
        end
    end
    #
    # override wages and se
    # wage needs to be set
    if settings.income_data_source == ds_frs
        income[wages] = model_person.wages_frs
        income[self_employment_income] = model_person.self_emp_frs
    else # not really needed since hbai is the default
        income[wages] = model_person.wages_hbai
        income[self_employment_income] = model_person.self_emp_hbai
    end
    
    # FIXME should be set
    pay_includes  = Included_In_Pay_Dict{Bool}()
    for i in instances(Included_In_Pay_Type)
        s = String(Symbol(i))
        ikey = Symbol(lowercase("pay_includes_" * s))
        if model_person[ikey]
            pay_includes[i] = true # model_person[ikey]
        end
    end
    
    assets = Dict{Asset_Type,Float64}() # fixme asset_type_dict
    for i in instances(Asset_Type)
        if i != Missing_Asset_Type
            ikey = make_sym_for_asset( i )
            # println(ikey)
            if model_person[ikey] != 0
                assets[i] = model_person[ikey]
            end
        end
    end

    # FIXME disabilties should be a set, not a map
    disabilities = Dict{Disability_Type,Bool}()
    for i in instances(Disability_Type)
        ikey = make_sym_for_frame("disability", i)
        if model_person[ikey]
            disabilities[i] = true # model_person[ikey
        end
    end

    #= ??? not needed ???
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
    =#

    relationships = Relationship_Dict()
    for i in 1:15
        relmod = Symbol( "relationship_$(i)") # :relationship_10 or :relationship_2
        irel = model_person[relmod]
        if irel != Missing_Relationship
            pid = get_pid(
                settings.data_source,
                model_person.data_year,
                model_person.hid,
                i )
            relationships[pid] = irel
        end
    end

    benefit_ratios = Incomes_Dict{Float64}()
    
    pers = Person{Float64}(
        model_person.hid,
        model_person.pid,
        model_person.uhid,
        model_person.pno,  # Integer# person number in household
        model_person.is_hrp,
        model_person.default_benefit_unit,  # Integer
        model_person.is_bu_head,
        model_person.from_child_record,
        model_person.age,  # Integer
        model_person.sex,
        model_person.ethnic_group,
        model_person.marital_status,
        model_person.highest_qualification,
        model_person.sic,
        model_person.occupational_classification,
        model_person.public_or_private,
        model_person.principal_employment_type,
        model_person.socio_economic_grouping,
        model_person.age_completed_full_time_education,
        model_person.years_in_full_time_work,
        model_person.employment_status,
        model_person.actual_hours_worked,
        model_person.usual_hours_worked,
        model_person.age_started_first_job,
        income,
        benefit_ratios,                
        model_person.jsa_type,
        model_person.esa_type,
        model_person.dlaself_care_type,
        model_person.dlamobility_type,
        model_person.attendance_allowance_type,
        model_person.personal_independence_payment_daily_living_type,
        model_person.personal_independence_payment_mobility_type,
        model_person.type_of_bereavement_allowance,
        model_person.had_children_when_bereaved,                
        assets,
        model_person.over_20_k_saving,
        pay_includes,
        model_person.registered_blind,
        model_person.registered_partially_sighted,
        model_person.registered_deaf,
        disabilities,
        model_person.health_status,
        model_person.has_long_standing_illness,
        model_person.adls_are_reduced,
        model_person.how_long_adls_reduced,
        relationships,
        model_person.relationship_to_hoh,
        model_person.is_informal_carer,
        model_person.receives_informal_care_from_non_householder,
        model_person.hours_of_care_received,
        model_person.hours_of_care_given,
        model_person.hours_of_childcare,
        model_person.cost_of_childcare,
        model_person.childcare_type,
        model_person.employer_provides_child_care ,
        model_person.company_car_fuel_type,
        model_person.company_car_value,
        model_person.company_car_contribution,
        model_person.fuel_supplied,
        model_person.work_expenses ,
        model_person.travel_to_work ,
        model_person.debt_repayments ,
        model_person.wealth_and_assets ,
        model_person.totsav, # FIXME unedited FRS totsav field needs enum ??? 
        strtobi(model_person.onerand),
        nothing # legal aid added as needed FIXME? maybe make this 'other data'??
    )
    # println( "model_person.pid=$(model_person.pid) model_person.dlaself_care_type $(model_person.dlaself_care_type) pers.dla_self_care_type $(pers.dla_self_care_type) ")
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
        frs_hh.uhid,
        frs_hh.data_year, 
        frs_hh.interview_year,
        frs_hh.interview_month,
        frs_hh.quarter,
        frs_hh.tenure,
        frs_hh.region,
        frs_hh.ct_band,
        frs_hh.dwelling ,
        frs_hh.council_tax,
        frs_hh.water_and_sewerage ,
        frs_hh.mortgage_payment,
        frs_hh.mortgage_interest,
        frs_hh.years_outstanding_on_mortgage,
        frs_hh.mortgage_outstanding,
        frs_hh.year_house_bought,
        frs_hh.gross_rent,
        frs_hh.rent_includes_water_and_sewerage,
        frs_hh.other_housing_charges,
        frs_hh.gross_housing_costs,
        # frs_hh.total_income,
        frs_hh.total_wealth,
        frs_hh.house_value,
        frs_hh.weight,
        frs_hh.council ,
        frs_hh.nhs_board ,
        frs_hh.bedrooms,
        head_of_household,
        frs_hh.net_physical_wealth,
        frs_hh.net_financial_wealth,
        frs_hh.net_housing_wealth,
        frs_hh.net_pension_wealth,
        frs_hh.original_gross_income,
        # frs_hh.lcf_default_matched_case, 
        # frs_hh.lcf_default_data_year,    
        -1, # original_income_decile
        -1, # equiv_original_income_decile
        nothing, # Recorded expenditure; loaded afterwards as needed.
        nothing, # Expenditure factor costs i.e. minus taxes.
        nothing, # raw_wealth
        people,        
        strtobi(frs_hh.onerand),
        ZERO_EQ_SCALE )
    return hh
end

function load_hhld_from_frame( 
    hseq     :: Integer, 
    hhld_fr  :: DataFrameRow, 
    pers_fr  :: DataFrame, 
    settings :: Settings ) :: Household
    hh = map_hhld( hseq, hhld_fr, settings )
    pers_fr_in_this_hh = pers_fr[((pers_fr.data_year .== hhld_fr.data_year).&(pers_fr.hid .== hh.hid)),:]
    npers = size( pers_fr_in_this_hh )[1]
    @assert npers in 1:19
    head_of_household = -1
    for p in 1:npers
        pers = map_person( hh, pers_fr_in_this_hh[p,:], settings )
        hh.people[pers.pid] = pers
        # println( "pers.pid=$(pers.pid) pers.relationship_to_hoh=$(pers.relationship_to_hoh)")
        if pers.relationship_to_hoh == This_Person
            hh.head_of_household = pers.pid
        end
    end
    @assert hh.head_of_household > 0 "head for hid $(hh.hid) = $(hh.head_of_household); should be +ive"    
    # rewrite the eq scale once we know everything
    make_eq_scales!( hh )
    # infer_wealth!( hh )    
    @assert hh.head_of_household !== -1
    return hh
end

end # module
