

#
# Formatting routines for PrettyTables
#
form( v :: Missing, r, c ) = ""
form( v :: AbstractString, r, c ) = pretty(v)
form( v :: Integer, r, c ) =  Format.format(v; precision=0, commas=true )
function form( v :: Number, r, c )
    if isnan(v)
       return "" 
    end
    prec = c == 4 ? 2 : 1
    Format.format(v; precision=prec, commas=true )
end


function do_initial_fixes!(hh::DataFrame, pers::DataFrame )
    # 
    # mostly.ai replaces the hid and pid with a random string, whereas we use bigints.
    # So, create a dictionary mapping the random hid string to a BigInt, and cleanup `randstr`.
    #
    hids = Dict{String,NamedTuple}()
    hid = BigInt(0)
    hs = size(hh)[1]
    #
    # Cast rands to string as opposed to string7 or whatever so we can assign our big string.
    #
    pers.onerand = String.(pers.onerand)
    hh.onerand = String.(hh.onerand)
    #
    # `hh` level: fixup `hid`s as BigInt, add rand stringxx
    # !! NOTE that assigning `hid` this way makes `hid` unique even across multiple data years. 
    # The actual dataset has `hid` unique only within a `data_year`.
    #
    rename!( hh, [:uhid=>:uhidstr])
    hh.uhid = fill( BigInt(0), hs )
    for h in eachrow(hh)
        hid += 1
        h.onerand = mybigrandstr()
        h.uhid = get_pid( SyntheticSource, h.data_year, hid, 0 )
        h.hid = hid
        hids[h.uhidstr] = (; hid, data_year = h.data_year, uhid=h.uhid )
    end
    #
    # Check everyone is allocated to an existing household.
    # FIXME in retrospect this doesn't actually check that... I need a join to hh.
    # The next loop does check this though.
    #
    v=counts(collect(values( countmap( pers.hid ))))
    n = length(v)
    @assert sum( collect(1:n) .* v) == size( pers )[1] 
    #
    # hid/pid clean up for people, and random string
    #
    np = size( pers )[1]
    # for v3
    rename!( pers, [:uhid=>:uhidstr,:pid=>:pidstr,:hid=>:hidstr2])
    pers.uhid = fill( BigInt(0), np )
    # for v4 - dunno what happened
    #rename!( pers, [:pid=>:pidstr,:hid=>:uhidstr])
    pers.pid = fill( BigInt(0), np )
    pers.hid = fill( BigInt(0), np )
    #
    # Assign correct numeric hid/uhid/data_year to each person and fixup the random string.
    #
    for p in eachrow( pers )
        p.onerand = mybigrandstr()
        println( "p.uhidstr $(p.uhidstr)")
        p.uhid = hids[p.uhidstr].uhid
        p.hid = hids[p.uhidstr].hid
        p.data_year = hids[p.uhidstr].data_year
        if ! ismissing( p.highest_qualification ) && (p.highest_qualification == 0) # missing is -1 here, not zero
            p.highest_qualification = -1
        end
        if(p.age < 16) || ((p.from_child_record==1)&&(p.age < 20))
            p.is_hrp = 0
            if (! ismissing(p.is_bu_head)) && (p.is_bu_head == 1)
                println( "removing bu head for $(p.pno) aged $(p.age) hid=$(p.hid)")
                p.is_bu_head = 0
                p.default_benefit_unit = 1 # FIXME wild guess
            end
        end
        p.is_hrp = coalesce( p.is_hrp, 0 )
        # FIXME fixup all the relationships
        if p.is_hrp == 1
            p.relationship_to_hoh = 0 # this person
        end
    end
    #
    # Data in order - just makes inspection easier.
    #
    sort!( hh, [:hid] )
    sort!( pers, [:hid,:pno,:default_benefit_unit,:age])
    #
    # Kill a few annoying missings.
    #
    pers.is_hrp = coalesce.( pers.is_hrp, 0 )
    pers.income_self_employment_income = coalesce.( pers.income_self_employment_income, 0 )
    pers.is_bu_head = coalesce.( pers.is_bu_head, 0 )
    # work round pointless assertion in map to hh
    pers.type_of_bereavement_allowance = coalesce.(pers.type_of_bereavement_allowance, -1)
    # also, pointless check in grossing up routines on occupations
    pers.occupational_classification = coalesce.(pers.occupational_classification, 0 )
    pers.occupational_classification = max.(0, pers.occupational_classification ) 
end


"""
For each hh, check there's 1 hrp per hh, one bu head per standard benefit unit, 
and that everyone is allocated to 1 standard benefit unit. We've already 
checked that each person is allocated to a household via `hid`.
FIXME move to `tests/`
FIXME check the `relationship_x` records
"""
function do_pers_idiot_checks( pers :: AbstractDataFrame, skiplist :: DataFrame  )
    hh_pers = groupby( pers, [:hid])
    nps = size(hh_pers)[1]
    for hid in 1:nps
        hp = hh_pers[hid]
        if not_in_skiplist(hp[1,:],skiplist)
            hbus = groupby( hp, :default_benefit_unit )
            nbusps = 0
            first = hp[1,:]
            for bu in hbus 
                nbusps += size( bu )[1]
                numheads = sum( bu[:,:is_bu_head])
                @assert numheads == 1 "1 head for each bu hh.hid=$(first.hid) numheads=$numheads bu = $(bu[1,:default_benefit_unit])"
            end
            @assert nbusps == size(hp)[1] "size mismatch for hh.hid=$(first.hid)"
            @assert sum( hp[:,:is_hrp]) == 1 "1 head for each hh hh.hid=$(first.hid) was $(sum( hp[:,:is_hrp]) )"
        end
    end
end  

"""
Hacky 
"""
function renormalise( joint :: DataFrame ) :: Tuple{DataFrame}

    hgrp = groupby( joint, :uhid )
    mpt[!, Between( begin, :uhid )]
    mpt[!, Between( :pid, end )]
end

function dumppersonal( )
    pers = CSV.File( "data/actual_data/model_people_scotland-2015-2021.tab") |> DataFrame
end

function formiss( x, RT = Float64 )
    x = max(0,x)
    return ismissing(x) ? RT(0) : RT(x)
end

function dumphh(RT=Float64)
    hh = CSV.File( "data/actual_data/model_households_scotland-2015-2021.tab") |> DataFrame
    hh.data_year = Int.(hh.data_year)
    hh.interview_year = Int.(hh.interview_year)
    hh.interview_month = Int.(hh.interview_month)
    hh.quarter = Int.(hh.quarter)
    hh.hid = BigInt.(hh.hid)
    hh.uhid = BigInt.(hh.uhid)
    hh.tenure = Tenure_Type.( hh.tenure )
    hh.region = Standard_Region.(hh.region)
    hh.ct_band = CT_Band.(hh.ct_band)
    hh.dwelling  =  DwellingType.(hh.dwelling )
    hh.council_tax = formiss.(hh.council_tax)
    hh.water_and_sewerage  = formiss.(hh.water_and_sewerage )
    hh.mortgage_payment = formiss.(hh.mortgage_payment)
    hh.mortgage_interest = formiss.(hh.mortgage_interest)
    hh.years_outstanding_on_mortgage =  formiss.(hh.years_outstanding_on_mortgage,Int)
    hh.mortgage_outstanding = formiss.(hh.mortgage_outstanding)
    hh.year_house_bought =  formiss.(hh.year_house_bought,Int)
    hh.gross_rent = formiss.( hh.gross_rent ) # rentg Gross rent including Housing Benefit  or rent Net amount of last rent payment.(hh.gross_rent)
    hh.rent_includes_water_and_sewerage = Bool.(hh.rent_includes_water_and_sewerage)
    hh.other_housing_charges = formiss.(hh.other_housing_charges)
    hh.gross_housing_costs = formiss.(hh.gross_housing_costs)
    # hh.# total_income = formiss.(hh.# total_income)
    hh.total_wealth = formiss.(hh.total_wealth)
    hh.house_value = formiss.(hh.house_value)
    hh.weight = formiss.(hh.weight)
    hh.council  =  Symbol.(hh.council )
    hh.nhs_board  =  Symbol.(hh.nhs_board )
    hh.bedrooms  =  Int.(hh.bedrooms )
    # fixme make these a set based on WealthTypes
    hh.net_physical_wealth  =  formiss.(hh.net_physical_wealth )
    hh.net_financial_wealth  =  formiss.(hh.net_financial_wealth )
    hh.net_housing_wealth  =  formiss.(hh.net_housing_wealth )
    hh.net_pension_wealth  =  formiss.(hh.net_pension_wealth )
    CSV.write( "data/actual_data/model_households_scotland-2015-2021-w-enums.tab", hh )
end

function readhh(RT=Float64)
    hh = CSV.File( "data/actual_data/model_households_scotland-2015-2021-w-enums.tab") |> DataFrame
    hh.hid = BigInt.(hh.hid)
    hh.uhid = BigInt.(hh.uhid)
    hh.tenure = eval.( Symbol.( hh.tenure ))
    hh.region = eval.(Symbol.( hh.region))
    hh.ct_band = eval.(Symbol.( hh.ct_band))
    hh.dwelling  =  eval.(Symbol.( hh.dwelling ))
    hh.council  =  Symbol.(hh.council )
    hh.rent_includes_water_and_sewerage = Bool.(hh.rent_includes_water_and_sewerage)
    hh.nhs_board  =  Symbol.(hh.nhs_board )
    hh
end

function safe_to_bool( x :: Union{Integer,Missing} )
    return if ismissing(x)
        false
    elseif x == 1
        true
    else
        false
    end        
end

function etype(x :: Union{Integer,Missing}, T )
    if ismissing(x)
        return T(-1)
    else
        return T(x)
    end
end

function read_pers()
    pers = CSV.File( "data/actual_data/model_people_scotland-2015-2021-w-enums.tab") |> DataFrame
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
    pers.dlaself_care_type = eval.( Symbol.( pers.dlaself_care_type ))
    pers.dlamobility_type = eval.( Symbol.( pers.dlamobility_type ))
    pers.attendance_allowance_type = eval.( Symbol.( pers.attendance_allowance_type ))
    pers.personal_independence_payment_daily_living_type = eval.( Symbol.( pers.personal_independence_payment_daily_living_type ))
    pers.personal_independence_payment_mobility_type = eval.( Symbol.( pers.personal_independence_payment_mobility_type ))
#     pers.over_20_k_saving
    println("#1")
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
    println("#2")
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
    println("#3")
    pers.onerand .= ""
    pers.uhid = BigInt.(pers.uhid)
    CSV.write( "data/actual_data/model_people_scotland-2015-2021-w-enums.tab", pers )
    pers
end

function dump_pers()
    pers = CSV.File( "data/actual_data/model_people_scotland-2015-2021.tab") |> DataFrame
    pers.pid = BigInt.(pers.pid)
    # pno
    pers.is_hrp = formiss.( pers.is_hrp, Bool )
    pers.is_bu_head = formiss.( pers.is_bu_head, Bool )
    pers.from_child_record = Bool.( pers.from_child_record )
    # default_benefit_unit
    # age
    pers.sex = etype.( pers.sex, Sex )
    pers.ethnic_group = etype.( pers.ethnic_group, Ethnic_Group )
    pers.marital_status = etype.( pers.marital_status, Marital_Status )
    pers.highest_qualification = etype.( pers.highest_qualification, Qualification_Type )
    pers.sic = etype.( pers.sic, SIC_2007 )
    pers.occupational_classification = etype.( pers.occupational_classification, Standard_Occupational_Classification )
    pers.public_or_private = etype.( pers.public_or_private, Employment_Sector )
    pers.principal_employment_type = etype.( pers.principal_employment_type, Employment_Type )
    pers.socio_economic_grouping = etype.( pers.socio_economic_grouping, Socio_Economic_Group )
    pers.age_completed_full_time_education = formiss.(pers.age_completed_full_time_education, Int )
    pers.years_in_full_time_work = formiss.( pers.years_in_full_time_work, Int )
    pers.employment_status = etype.(pers.employment_status, ILO_Employment )
    pers.usual_hours_worked = formiss.( pers.usual_hours_worked )
    pers.actual_hours_worked = formiss.( pers.actual_hours_worked )
    pers.age_started_first_job = formiss.(pers.age_started_first_job,Int)
    pers.type_of_bereavement_allowance = etype.(pers.type_of_bereavement_allowance, BereavementType)
    pers.had_children_when_bereaved = safe_to_bool.( pers.had_children_when_bereaved )
    pers.pay_includes_ssp = formiss.( pers.pay_includes_ssp, Bool )
    pers.pay_includes_smp = formiss.( pers.pay_includes_smp, Bool )
    pers.pay_includes_spp = formiss.( pers.pay_includes_spp, Bool )
    pers.pay_includes_sap = formiss.( pers.pay_includes_sap, Bool )
    pers.pay_includes_mileage = formiss.( pers.pay_includes_mileage, Bool )
    pers.pay_includes_motoring_expenses = formiss.( pers.pay_includes_motoring_expenses, Bool )
    pers.income_wages = formiss.(pers.income_wages)
    pers.income_self_employment_income = formiss.(pers.income_self_employment_income)
    pers.income_self_employment_expenses = formiss.(pers.income_self_employment_expenses)
    pers.income_self_employment_losses = formiss.(pers.income_self_employment_losses)
    pers.income_odd_jobs = formiss.(pers.income_odd_jobs)
    pers.income_private_pensions = formiss.(pers.income_private_pensions)
    pers.income_national_savings = formiss.(pers.income_national_savings)
    pers.income_bank_interest = formiss.(pers.income_bank_interest)
    pers.income_stocks_shares = formiss.(pers.income_stocks_shares)
    pers.income_individual_savings_account = formiss.(pers.income_individual_savings_account)
    pers.income_property = formiss.(pers.income_property)
    pers.income_royalties = formiss.(pers.income_royalties)
    pers.income_bonds_and_gilts = formiss.(pers.income_bonds_and_gilts)
    pers.income_other_investment_income = formiss.(pers.income_other_investment_income)
    pers.income_other_income = formiss.(pers.income_other_income)
    pers.income_alimony_and_child_support_received = formiss.(pers.income_alimony_and_child_support_received)
    pers.income_health_insurance = formiss.(pers.income_health_insurance)
    pers.income_alimony_and_child_support_paid = formiss.(pers.income_alimony_and_child_support_paid)
    pers.income_care_insurance = formiss.(pers.income_care_insurance)
    pers.income_trade_unions_etc = formiss.(pers.income_trade_unions_etc)
    pers.income_friendly_societies = formiss.(pers.income_friendly_societies)
    pers.income_work_expenses = formiss.(pers.income_work_expenses)
    pers.income_avcs = formiss.(pers.income_avcs)
    pers.income_other_deductions = formiss.(pers.income_other_deductions)
    pers.income_loan_repayments = formiss.(pers.income_loan_repayments)
    pers.income_student_loan_repayments = formiss.(pers.income_student_loan_repayments)
    pers.income_pension_contributions_employer = formiss.(pers.income_pension_contributions_employer)
    pers.income_pension_contributions_employee = formiss.(pers.income_pension_contributions_employee)
    pers.income_education_allowances = formiss.(pers.income_education_allowances)
    pers.income_foster_care_payments = formiss.(pers.income_foster_care_payments)
    pers.income_student_grants = formiss.(pers.income_student_grants)
    pers.income_student_loans = formiss.(pers.income_student_loans)
    pers.income_income_tax = formiss.(pers.income_income_tax)
    pers.income_national_insurance = formiss.(pers.income_national_insurance)
    pers.income_local_taxes = formiss.(pers.income_local_taxes)
    pers.income_free_school_meals = formiss.(pers.income_free_school_meals)
    pers.income_dlaself_care = formiss.(pers.income_dlaself_care)
    pers.income_dlamobility = formiss.(pers.income_dlamobility)
    pers.income_child_benefit = formiss.(pers.income_child_benefit)
    pers.income_pension_credit = formiss.(pers.income_pension_credit)
    pers.income_state_pension = formiss.(pers.income_state_pension)
    pers.income_bereavement_allowance_or_widowed_parents_allowance_or_bereavement = formiss.(pers.income_bereavement_allowance_or_widowed_parents_allowance_or_bereavement)
    pers.income_armed_forces_compensation_scheme = formiss.(pers.income_armed_forces_compensation_scheme)
    pers.income_war_widows_or_widowers_pension = formiss.(pers.income_war_widows_or_widowers_pension)
    pers.income_severe_disability_allowance = formiss.(pers.income_severe_disability_allowance)
    pers.income_attendance_allowance = formiss.(pers.income_attendance_allowance)
    pers.income_carers_allowance = formiss.(pers.income_carers_allowance)
    pers.income_jobseekers_allowance = formiss.(pers.income_jobseekers_allowance)
    pers.income_industrial_injury_disablement_benefit = formiss.(pers.income_industrial_injury_disablement_benefit)
    pers.income_employment_and_support_allowance = formiss.(pers.income_employment_and_support_allowance)
    pers.income_incapacity_benefit = formiss.(pers.income_incapacity_benefit)
    pers.income_income_support = formiss.(pers.income_income_support)
    pers.income_maternity_allowance = formiss.(pers.income_maternity_allowance)
    pers.income_maternity_grant_from_social_fund = formiss.(pers.income_maternity_grant_from_social_fund)
    pers.income_funeral_grant_from_social_fund = formiss.(pers.income_funeral_grant_from_social_fund)
    pers.income_any_other_ni_or_state_benefit = formiss.(pers.income_any_other_ni_or_state_benefit)
    pers.income_trade_union_sick_or_strike_pay = formiss.(pers.income_trade_union_sick_or_strike_pay)
    pers.income_friendly_society_benefits = formiss.(pers.income_friendly_society_benefits)
    pers.income_private_sickness_scheme_benefits = formiss.(pers.income_private_sickness_scheme_benefits)
    pers.income_accident_insurance_scheme_benefits = formiss.(pers.income_accident_insurance_scheme_benefits)
    pers.income_hospital_savings_scheme_benefits = formiss.(pers.income_hospital_savings_scheme_benefits)
    pers.income_government_training_allowances = formiss.(pers.income_government_training_allowances)
    pers.income_guardians_allowance = formiss.(pers.income_guardians_allowance)
    pers.income_widows_payment = formiss.(pers.income_widows_payment)
    pers.income_unemployment_or_redundancy_insurance = formiss.(pers.income_unemployment_or_redundancy_insurance)
    pers.income_winter_fuel_payments = formiss.(pers.income_winter_fuel_payments)
    pers.income_child_winter_heating_assistance_payment = formiss.(pers.income_child_winter_heating_assistance_payment)
    pers.income_dwp_third_party_payments_is_or_pc = formiss.(pers.income_dwp_third_party_payments_is_or_pc)
    pers.income_dwp_third_party_payments_jsa_or_esa = formiss.(pers.income_dwp_third_party_payments_jsa_or_esa)
    pers.income_social_fund_loan_repayment_from_is_or_pc = formiss.(pers.income_social_fund_loan_repayment_from_is_or_pc)
    pers.income_social_fund_loan_repayment_from_jsa_or_esa = formiss.(pers.income_social_fund_loan_repayment_from_jsa_or_esa)
    pers.income_extended_hb = formiss.(pers.income_extended_hb)
    pers.income_permanent_health_insurance = formiss.(pers.income_permanent_health_insurance)
    pers.income_any_other_sickness_insurance = formiss.(pers.income_any_other_sickness_insurance)
    pers.income_critical_illness_cover = formiss.(pers.income_critical_illness_cover)
    pers.income_working_tax_credit = formiss.(pers.income_working_tax_credit)
    pers.income_child_tax_credit = formiss.(pers.income_child_tax_credit)
    pers.income_working_tax_credit_lump_sum = formiss.(pers.income_working_tax_credit_lump_sum)
    pers.income_child_tax_credit_lump_sum = formiss.(pers.income_child_tax_credit_lump_sum)
    pers.income_housing_benefit = formiss.(pers.income_housing_benefit)
    pers.income_universal_credit = formiss.(pers.income_universal_credit)
    pers.income_personal_independence_payment_daily_living = formiss.(pers.income_personal_independence_payment_daily_living)
    pers.income_personal_independence_payment_mobility = formiss.(pers.income_personal_independence_payment_mobility)
    pers.income_a_loan_from_the_dwp_and_dfc = formiss.(pers.income_a_loan_from_the_dwp_and_dfc)
    pers.income_a_loan_or_grant_from_local_authority = formiss.(pers.income_a_loan_or_grant_from_local_authority)
    pers.income_social_fund_loan_uc = formiss.(pers.income_social_fund_loan_uc)
    pers.income_other_benefits = formiss.(pers.income_other_benefits)
    pers.income_scottish_child_payment = formiss.(pers.income_scottish_child_payment)
    pers.income_job_start_payment = formiss.(pers.income_job_start_payment)
    pers.income_troubles_permanent_disablement = formiss.(pers.income_troubles_permanent_disablement)
    pers.income_child_disability_payment_care = formiss.(pers.income_child_disability_payment_care)
    pers.income_child_disability_payment_mobility = formiss.(pers.income_child_disability_payment_mobility)
    pers.income_pupil_development_grant = formiss.(pers.income_pupil_development_grant)
    pers.wages_frs = formiss.(pers.wages_frs)
    pers.self_emp_frs = formiss.(pers.self_emp_frs)
    pers.wages_hbai = formiss.(pers.wages_hbai)
    pers.self_emp_hbai = formiss.(pers.self_emp_hbai)
    pers.jsa_type = etype.( pers.jsa_type, JSAType )
    pers.esa_type = etype.( pers.esa_type, JSAType )
    pers.dlaself_care_type = etype.( pers.dlaself_care_type, LowMiddleHigh )
    pers.dlamobility_type = etype.( pers.dlamobility_type, LowMiddleHigh )
    pers.attendance_allowance_type = etype.( pers.attendance_allowance_type, LowMiddleHigh )
    pers.personal_independence_payment_daily_living_type = etype.( pers.personal_independence_payment_daily_living_type, PIPType )
    pers.personal_independence_payment_mobility_type = etype.( pers.personal_independence_payment_mobility_type, PIPType )
    pers.over_20_k_saving = formiss.( pers.over_20_k_saving, Bool )
    println("#1")
    pers.asset_current_account = formiss.(pers.asset_current_account)
    pers.asset_nsb_ordinary_account = formiss.(pers.asset_nsb_ordinary_account)
    pers.asset_nsb_investment_account = formiss.(pers.asset_nsb_investment_account)
    pers.asset_not_used = formiss.(pers.asset_not_used)
    pers.asset_savings_investments_etc = formiss.(pers.asset_savings_investments_etc)
    pers.asset_government_gilt_edged_stock = formiss.(pers.asset_government_gilt_edged_stock)
    pers.asset_unit_or_investment_trusts = formiss.(pers.asset_unit_or_investment_trusts)
    pers.asset_stocks_shares_bonds_etc = formiss.(pers.asset_stocks_shares_bonds_etc)
    pers.asset_pep = formiss.(pers.asset_pep)
    pers.asset_national_savings_capital_bonds = formiss.(pers.asset_national_savings_capital_bonds)
    pers.asset_index_linked_national_savings_certificates = formiss.(pers.asset_index_linked_national_savings_certificates)
    pers.asset_fixed_interest_national_savings_certificates = formiss.(pers.asset_fixed_interest_national_savings_certificates)
    pers.asset_pensioners_guaranteed_bonds = formiss.(pers.asset_pensioners_guaranteed_bonds)
    pers.asset_saye = formiss.(pers.asset_saye)
    pers.asset_premium_bonds = formiss.(pers.asset_premium_bonds)
    pers.asset_national_savings_income_bonds = formiss.(pers.asset_national_savings_income_bonds)
    pers.asset_national_savings_deposit_bonds = formiss.(pers.asset_national_savings_deposit_bonds)
    pers.asset_first_option_bonds = formiss.(pers.asset_first_option_bonds)
    pers.asset_yearly_plan = formiss.(pers.asset_yearly_plan)
    pers.asset_isa = formiss.(pers.asset_isa)
    pers.asset_fixd_rate_svngs_bonds_or_grntd_incm_bonds_or_grntd_growth_bonds = formiss.(pers.asset_fixd_rate_svngs_bonds_or_grntd_incm_bonds_or_grntd_growth_bonds)
    pers.asset_geb = formiss.(pers.asset_geb)
    pers.asset_basic_account = formiss.(pers.asset_basic_account)
    pers.asset_credit_unions = formiss.(pers.asset_credit_unions)
    pers.asset_endowment_policy_not_linked = formiss.(pers.asset_endowment_policy_not_linked)
    pers.asset_informal_assets = formiss.(pers.asset_informal_assets)
    pers.asset_post_office_card_account = formiss.(pers.asset_post_office_card_account)
    pers.asset_friendly_society_investment = formiss.(pers.asset_friendly_society_investment)
    println("#2")
    # contracted_out_of_serps
    pers.registered_blind = formiss.( pers.registered_blind, Bool )
    pers.registered_partially_sighted = formiss.( pers.registered_partially_sighted, Bool )
    pers.registered_deaf = formiss.( pers.registered_deaf, Bool )
    pers.disability_vision = formiss.( pers.disability_vision, Bool )
    pers.disability_hearing = formiss.( pers.disability_hearing, Bool )
    pers.disability_mobility = formiss.( pers.disability_mobility, Bool )
    pers.disability_dexterity = formiss.( pers.disability_dexterity, Bool )
    pers.disability_learning = formiss.( pers.disability_learning, Bool )
    pers.disability_memory = formiss.( pers.disability_memory, Bool )
    pers.disability_mental_health = formiss.( pers.disability_mental_health, Bool )
    pers.disability_stamina = formiss.( pers.disability_stamina, Bool )
    pers.disability_socially = formiss.( pers.disability_socially, Bool )
    pers.disability_other_difficulty = formiss.( pers.disability_other_difficulty, Bool )
    pers.health_status = etype.(pers.health_status, Health_Status)
    pers.has_long_standing_illness = formiss.(pers.has_long_standing_illness, Bool)
    pers.adls_are_reduced = etype.( pers.adls_are_reduced, ADLS_Inhibited )
    pers.how_long_adls_reduced = etype.( pers.how_long_adls_reduced, Illness_Length )
    pers.is_informal_carer = formiss.(pers.is_informal_carer,Bool)
    pers.receives_informal_care_from_non_householder = formiss.(pers.receives_informal_care_from_non_householder,Bool)
    pers.hours_of_care_received = formiss.(pers.hours_of_care_received)
    pers.hours_of_care_given = formiss.(pers.hours_of_care_given)
    pers.hours_of_childcare = formiss.(pers.hours_of_childcare)
    pers.cost_of_childcare = formiss.(pers.cost_of_childcare)
    pers.childcare_type = etype.(pers.childcare_type, Child_Care_Type)
    pers.employer_provides_child_care = formiss.(pers.employer_provides_child_care, Bool)
    pers.work_expenses  = formiss.(pers.work_expenses )
    pers.travel_to_work = formiss.(pers.travel_to_work)
    pers.debt_repayments = formiss.(pers.debt_repayments)
    pers.wealth_and_assets = formiss.(pers.wealth_and_assets)
    pers.totsav = formiss.(pers.totsav)
    pers.company_car_fuel_type = etype.(pers.company_car_fuel_type, Fuel_Type)
    pers.company_car_value = formiss.(pers.company_car_value)
    pers.company_car_contribution = formiss.(pers.company_car_contribution)
    pers.fuel_supplied = formiss.(pers.fuel_supplied)
    pers.relationship_to_hoh = etype.(pers.relationship_to_hoh, Relationship )
    pers.relationship_1 = etype.(pers.relationship_1, Relationship )
    pers.relationship_2 = etype.(pers.relationship_2, Relationship )
    pers.relationship_3 = etype.(pers.relationship_3, Relationship )
    pers.relationship_4 = etype.(pers.relationship_4, Relationship )
    pers.relationship_5 = etype.(pers.relationship_5, Relationship )
    pers.relationship_6 = etype.(pers.relationship_6, Relationship )
    pers.relationship_7 = etype.(pers.relationship_7, Relationship )
    pers.relationship_8 = etype.(pers.relationship_8, Relationship )
    pers.relationship_9 = etype.(pers.relationship_9, Relationship )
    pers.relationship_10 = etype.(pers.relationship_10, Relationship )
    pers.relationship_11 = etype.(pers.relationship_11, Relationship )
    pers.relationship_12 = etype.(pers.relationship_12, Relationship )
    pers.relationship_13 = etype.(pers.relationship_13, Relationship )
    pers.relationship_14 = etype.(pers.relationship_14, Relationship )
    pers.relationship_15 = etype.(pers.relationship_15, Relationship )
    println("#3")
    pers.onerand .= ""
    pers.uhid = BigInt.(pers.uhid)
    CSV.write( "data/actual_data/model_people_scotland-2015-2021-w-enums.tab", pers )
    pers
end


function get_relationships( hp :: AbstractDataFrame ) :: Matrix{Relationship}
    num_people = size(hp)[1]
    v = fill(Missing_Relationship,15,15)
    for i in 1:num_people
        k = Symbol("relationship_$i")
        for j in 1:num_people
            v[j,i] = Relationship(hp[j,k])
        end
    end
    v
end


function print_relationships( m::Matrix{Relationship} )
    n = findfirst( isequal( Missing_Relationship ), m[1,:])-1
    hc = hcat(m[1:n,1:n ],collect(1:n))
    pretty_table( hc )
end


function select_irredemably_bad_hhs( hh :: DataFrame, pers :: DataFrame )::DataFrame
    kills = DataFrame( hid=zeros(BigInt,0), data_year=zeros(Int,0), reason=fill("",0))
    for h in eachrow( hh )
        p = pers[pers.hid .== h.hid,:]
        n = size(p)[1]
        # all children - killem all
        if(maximum( p[!,:age]) < 16) && (sum( p[!,:from_child_record]) == n)
            println( "want to kill $(h.hid)")
            push!(kills, (; hid=h.hid, data_year=h.data_year, reason="all child hh child "))
        end
        hbus = groupby( p, :default_benefit_unit )
        nbusps = 0
        for bu in hbus 
            nbusps += size( bu )[1]
            numheads = sum( bu[:,:is_bu_head])
            if numheads != 1 
                msg = "!= 1 head for each bu hh.hid=$(h.hid) numheads=$numheads bu = $(bu[1,:default_benefit_unit])"
                push!( kills, (; hid=h.hid, data_year=h.data_year, reason=msg))
            end
        end
        if sum( p[:,:is_hrp]) != 1 
            msg = "!=1 head for each hh hh.hid=$(p.hid) was $(sum( p[:,:is_hrp]) )"
            push!( kills, (; hid=h.hid, data_year=h.data_year, reason=msg) )
        end
        # fixable, but hey..
        age_oldest_child = maximum(p[p.from_child_record.==1,:age];init=-99)
        if age_oldest_child >= 20
            msg = "age_oldest_child=$age_oldest_child for $(h.hid)"
            push!( kills,  (; hid=h.hid, data_year=h.data_year, reason=msg))
        end

    end
    # println( "killing $(kills)")
    return kills;
    # deleteat!(hh, hh.hid .∈ (kills,))
    # deleteat!(pers, pers.hid .∈ (kills,))
end

#
# open unpacked synthetic files
#
function load_unpacked_files(; version=3)::Tuple
    dir = "$(RAW_DATA)/synthetic_data/mostly_ai/"
    hh,pers = if version == 2
        hh = CSV.File("$(dir)/v2/model_households_scotland-2015-2021/model_households_scotland-2015-2021.csv")|>DataFrame
        pers = CSV.File("$(dir)/v2/model_people_scotland-2015-2021/model_people_scotland-2015-2021.csv")|>DataFrame
        hh,pers
    # version with child/adult seperate
    elseif version == 3
        hh = CSV.File("$(dir)/v3/model_households_scotland-2015-2021/model_households_scotland-2015-2021.csv")|>DataFrame
        child = CSV.File("$(dir)/v3/model_children_scotland-2015-2021/model_children_scotland-2015-2021.csv")|>DataFrame
        adult = CSV.File("$(dir)/v3/model_adults_scotland-2015-2021/model_adults_scotland-2015-2021.csv")|>DataFrame
        # Not actually needed with current sets but just in case.
        child.from_child_record .= 1
        adult.from_child_record .= 0
        pers = vcat( adult, child )
        hh,pers
    elseif version == 4
        hh = CSV.File("$(dir)/v4/model_households_scotland-2015-2021/model_households_scotland-2015-2021.csv")|>DataFrame
        pers = CSV.File("$(dir)/v4/model_people_scotland-2015-2021/model_people_scotland-2015-2021.csv")|>DataFrame
        hh,pers    
    end
end


function add_skips_from_model!( skips ::  DataFrame )
    settings = Settings()
    settings.data_source = SyntheticSource 
    settings.do_legal_aid = false    
    settings.run_name="run-$(settings.data_source)-$(date_string())"
    settings.skiplist = "skiplist"
  
    settings.run_name="run-$(settings.data_source)-$(date_string())"

    sys = [
        get_default_system_for_fin_year(2024; scotland=true), 
        get_default_system_for_fin_year( 2024; scotland=true )]
    tot = 0
    settings.num_households, 
    settings.num_people, 
    nhh2 = 
        FRSHouseholdGetter.initialise( settings; reset=true )
    for hno in 1:1 # settings.num_households
        println( "on hh $hno num_households=$(settings.num_households)")
        mhh = FRSHouseholdGetter.get_household( hno )  
        try
            intermed = make_intermediate( 
                Float64,
                settings,
                mhh,  
                sys[1].lmt.hours_limits,
                sys[1].age_limits,
                sys[1].child_limits )
            for sysno in 1:2
                res = do_one_calc( mhh, sys[sysno], settings )
            end
        catch e
            @show mhh.people #relationships          
            # println( stacktrace())
            println( "caught exception $(e) hh.hid=$(mhh.hid) hh.data_year=$(mhh.data_year)")
            push!( skips, (; hid=mhh.hid, data_year=mhh.data_year, reason="$(e)"))
        end
    end
end


function make_intermed_df( n :: Int ) :: DataFrame 
    RT = Float64
    return DataFrame(
        benefit_unit_number = zeros( Int, n ),
        num_people = zeros( Int, n ),
        age_youngest_adult = zeros( Int, n ),
        age_oldest_adult = zeros( Int, n ),
        age_youngest_child = zeros( Int, n ),
        age_oldest_child = zeros( Int, n ),
        num_adults = zeros( Int, n ),
        someone_pension_age  = zeros( Bool, n ),
        someone_pension_age_2016 = zeros( Bool, n ),
        all_pension_age = zeros( Bool, n ),
        someone_working_ft  = zeros( Bool , n ),
        #
        someone_working_ft_and_25_plus = zeros( Bool, n ),

        num_not_working = zeros( Int, n ),
        num_working_ft = zeros( Int, n ),
        num_working_pt = zeros( Int , n ),
        num_working_24_plus = zeros( Int , n ),
        num_working_16_or_less = zeros( Int, n ),
        total_hours_worked = zeros( Int, n ),
        someone_is_carer = zeros( Bool , n ),
        num_carers = zeros( Int, n ),

        is_sparent  = zeros( Bool , n ),
        is_sing  = zeros( Bool, n ),
        is_disabled = zeros( Bool, n ),

        num_disabled_adults = zeros( Int, n ),
        num_disabled_children = zeros( Int, n ),
        num_severely_disabled_adults = zeros( Int, n ),
        num_severely_disabled_children = zeros( Int, n ),

        num_job_seekers = zeros( Int, n ),

        num_children = zeros( Int, n ),
        num_allowed_children = zeros( Int, n ),
        num_children_born_before = zeros( Int, n ),
        ge_16_u_pension_age  = zeros( Bool , n ),
        limited_capacity_for_work  = zeros( Bool , n ),
        has_children  = zeros( Bool , n ),
        economically_active = zeros( Bool, n ),
        working_disabled = zeros( Bool, n ),
        num_benefit_units = zeros( Int, n ),
        all_student_bu = zeros( Bool, n ),

        net_physical_wealth = zeros( RT, n ),
        net_financial_wealth = zeros( RT, n ),
        net_housing_wealth = zeros( RT, n ),
        net_pension_wealth = zeros( RT, n ),
        total_value_of_other_property = zeros( RT, n ))
end

function add_to_intermed_frame!( df :: AbstractDataFrame, intermed :: MTIntermediate, n :: Int)
    df[n,:benefit_unit_number] = intermed.benefit_unit_number
    df[n,:num_people] = intermed.num_people
    df[n,:age_youngest_adult] = intermed.age_youngest_adult
    df[n,:age_oldest_adult] = intermed.age_oldest_adult
    df[n,:age_youngest_child] = intermed.age_youngest_child
    df[n,:age_oldest_child] = intermed.age_oldest_child
    df[n,:num_adults] = intermed.num_adults
    df[n,:someone_pension_age ] = intermed.someone_pension_age 
    df[n,:someone_pension_age_2016] = intermed.someone_pension_age_2016
    df[n,:all_pension_age] = intermed.all_pension_age
    df[n,:someone_working_ft ] = intermed.someone_working_ft 
            #
    df[n,:someone_working_ft_and_25_plus] = intermed.someone_working_ft_and_25_plus

    df[n,:num_not_working] = intermed.num_not_working
    df[n,:num_working_ft] = intermed.num_working_ft
    df[n,:num_working_pt] = intermed.num_working_pt
    df[n,:num_working_24_plus] = intermed.num_working_24_plus
    df[n,:num_working_16_or_less] = intermed.num_working_16_or_less
    df[n,:total_hours_worked] = intermed.total_hours_worked
    df[n,:someone_is_carer] = intermed.someone_is_carer
    df[n,:num_carers] = intermed.num_carers

    df[n,:is_sparent ] = intermed.is_sparent 
    df[n,:is_sing ] = intermed.is_sing 
    df[n,:is_disabled] = intermed.is_disabled

    df[n,:num_disabled_adults] = intermed.num_disabled_adults
    df[n,:num_disabled_children] = intermed.num_disabled_children
    df[n,:num_severely_disabled_adults] = intermed.num_severely_disabled_adults
    df[n,:num_severely_disabled_children] = intermed.num_severely_disabled_children

    df[n,:num_job_seekers] = intermed.num_job_seekers

    df[n,:num_children] = intermed.num_children
    df[n,:num_allowed_children] = intermed.num_allowed_children
    df[n,:num_children_born_before] = intermed.num_children_born_before
    df[n,:ge_16_u_pension_age ] = intermed.ge_16_u_pension_age 
    df[n,:limited_capacity_for_work ] = intermed.limited_capacity_for_work 
    df[n,:has_children ] = intermed.has_children 
    df[n,:economically_active] = intermed.economically_active
    df[n,:working_disabled] = intermed.working_disabled
    df[n,:num_benefit_units] = intermed.num_benefit_units
    df[n,:all_student_bu] = intermed.all_student_bu

    df[n,:net_physical_wealth] = intermed.net_physical_wealth
    df[n,:net_financial_wealth] = intermed.net_financial_wealth
    df[n,:net_housing_wealth] = intermed.net_housing_wealth
    df[n,:net_pension_wealth] = intermed.net_pension_wealth
    df[n,:total_value_of_other_property] = intermed.total_value_of_other_property
end

function summarise_data( source :: DataSource )
    settings = Settings()
    settings.data_source = source
    settings.do_legal_aid = false
    settings.skiplist = ""
    sys = [ # for intermed
        get_default_system_for_fin_year(2024; scotland=true), 
        get_default_system_for_fin_year( 2024; scotland=true )]

    ds = main_datasets( settings )
    hh = CSV.File( ds.hhlds ) |> DataFrame
    hn = size(hh)[1]
    hh.household_composition_1 = fill(single_person,hn)

    pers = CSV.File( ds.people ) |> DataFrame
    adults=pers[pers.from_child_record.==0,:]
    
    settings.num_households, settings.num_people, nhh2 = 
        FRSHouseholdGetter.initialise( settings; reset=true )
    bu_interdf = make_intermed_df( settings.num_people )
    hh_interdf = make_intermed_df( settings.num_households )
    nbus = 0
    for hno in 1:settings.num_households
        mhh = get_household( hno )
        hh.household_composition_1[hno] = household_composition_1( mhh )
        intermed = make_intermediate( 
            Float64,
            settings,
            mhh, 
            sys[1].hours_limits, 
            sys[1].age_limits, 
            sys[1].child_limits )
        add_to_intermed_frame!( bu_interdf, intermed.hhint, hno  )
        for bi in intermed.buint
            nbus += 1
            add_to_intermed_frame!( bu_interdf, bi, nbus  )
        end
    end
    bu_interdf = bu_interdf[1:nbus,:]
    d = Dict()
    vnames = []
    for n in names(pers)
        v = adults[!,n] # collect(skipmissing(adults[!,n]))
        if( length(v) > 0) && (eltype(v) <: Number )
            d[n] = summarystats( v )
            push!( vnames, n  ) 
        end
    end 
    hh_inames=[]
    bu_inames=[]
    bu_id = Dict()
    hh_id = Dict()
    #FIXME don't need if?/ dups
    for n in names(bu_interdf)
        v = bu_interdf[!,n] # collect(skipmissing(adults[!,n]))
        if( length(v) > 0) && (eltype(v) <: Number )
            bu_id[n] = summarystats( v )
            push!( bu_inames, n  ) 
        end
    end 
    for n in names(hh_interdf)
        v = hh_interdf[!,n] # collect(skipmissing(adults[!,n]))
        if( length(v) > 0) && (eltype(v) <: Number )
            hh_id[n] = summarystats( v )
            push!( hh_inames, n  ) 
        end
    end 
    return (;
        nadults = size( adults )[1],
        nchildren = sum( pers.from_child_record ),
        names = vnames,
        summaries = d,
        hh_inames = hh_inames,
        bu_inames = bu_inames,
        bu_isummaries = bu_id,
        hh_isummaries = hh_id,
        household_composition_1=sort(countmap(hh.household_composition_1)),
        marital_status=sort(countmap(Marital_Status.(adults.marital_status))),
        default_benefit_unit=sort(countmap(adults.default_benefit_unit)))
end

function smerge(f::AbstractDict,s::AbstractDict)
    l = length(f)
    d = DataFrame( k = fill("",l), f=fill(0,l),s=fill(0,l),ch=fill(0.0,l))
    i = 0
    for k in keys(f)
        i += 1
        d.k[i] = pretty( k )
        d.f[i] = f[k]
        d.s[i] = s[k]
        d.ch[i] = 100 .* ( s[k] - f[k])/f[k]
    end
    pretty_table(d;
        formatters=(form), 
        header=["", "FRS", "Synthetic", "Diff (%)"], 
        alignment = [:l,:r,:r,:r],
        backend = Val(:markdown))
end

function smerge(f::StatsBase.SummaryStats, s::StatsBase.SummaryStats)
    fn = fieldnames(typeof(f))
    l = length(fn)
    println("l=$l")
    d = DataFrame( k = fill("",l), f=fill(0.0,l),s=fill(0.0,l),ch=fill(0.0,l))
    i = 0
    for k in fn
        i += 1
        println( "i=$i, k=$k")
        d.k[i] = pretty( string(k) )
        fv = getfield(f,k)
        d.f[i] = fv
        println( "fv=$fv")
        sv = getfield(s,k)
        d.s[i] = sv
        d.ch[i] = 100 .* ( sv - fv)/fv
    end
    pretty_table(d;
        formatters=(form), 
        header=["", "FRS", "Synthetic", "Diff (%)"], 
        alignment = [:l,:r,:r,:r],
        backend = Val(:markdown))
end


