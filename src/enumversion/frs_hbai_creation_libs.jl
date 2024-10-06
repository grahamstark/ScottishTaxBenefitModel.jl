
const MONTHS = Dict(
    "JAN" => 1,
    "FEB" => 2,
    "MAR" => 3,
    "APR" => 4,
    "MAY" => 5,
    "JUN" => 6,
    "JUL" => 7,
    "AUG" => 8,
    "SEP" => 9,
    "OCT" => 10,
    "NOV" => 11,
    "DEC" => 12 )


# FIXME paths in Definitions.jl broken
const L_HBAI_DIR="/mnt/data/hbai/"
const L_FRS_DIR="/mnt/data/frs/"


"""
hacky routine to add uhid - unique hhid needed for mostly.ai generator
"""
function add_uhids( settings :: Settings )
    for i in 1:2 
        datafs, data_source = if i == 1 
            main_datasets( settings ),
            settings.data_source
        else
            example_datasets( settings ),
            ExampleSource
        end
        hh = CSV.File( datafs.hhlds ) |> DataFrame
        pers = CSV.File( datafs.people ) |> DataFrame
        hh.uhid = get_pid.( data_source, hh.data_year, hh.hid, 0 ) # 
        pers.uhid = get_pid.( data_source, pers.data_year, pers.hid, 0 ) # 
        CSV.write( datafs.hhlds, hh; delim='\t' )
        CSV.write( datafs.people, pers; delim='\t' )
    end
end

"""
Make a subset of main model data.
TODO add in WAS,LCF,SHS mapping stuff 
sz - 10 for 1/10 and so on
- another approach: https://discourse.julialang.org/t/how-to-sample-a-data-frame/32791/5
"""
function make_sample( settings :: Settings; sz :: Int ) :: Tuple
    datafs = main_datasets( settings )
    hh = CSV.File( datafs.hhlds ) |> DataFrame
    pers = CSV.File( datafs.people ) |> DataFrame
    uhid = copy(hh.uhid)
    n = length(uhid)
    suhids = sample( uhid, sz; replace=false, ordered=true )
    hhsample = hh[ in.(hh.uhid, ( suhids, )),: ]
    perssample = pers[ in.(pers.uhid, ( suhids, )),: ]
    return hhsample, perssample
end

function loadfrs(which::AbstractString, year::Integer)::DataFrame
    filename = "$(L_FRS_DIR)/$(year)/tab/$(which).tab"
    df = loadtoframe(filename)
    df.data_year .= year
    return df
end


function is_in_hbai(
    hbai_res :: DataFrame,
    sernum::Integer,
    benunit  :: Integer,
    person :: Integer ) :: Bool

    ad_hbai = hbai_res[((hbai_res.sernum.==sernum ).&
                        ((hbai_res.personhd.==person).|(hbai_res.personsp.==person)) .&
                        (hbai_res.benunit.==benunit)), :]
    return size( ad_hbai )[1]>0
end

function is_in_hbai(
    hbai_res :: DataFrame,
    sernum::Integer   ) :: Bool

    ad_hbai = hbai_res[(hbai_res.sernum.==sernum ), :]
    return size( ad_hbai )[1]>0
end
    

"""
hacky hack to hack PIP, etc into l/h
"""
function map12( v :: Union{Missing,Real}, amt :: Real ) :: Integer
    r = -1
    if (! ismissing(v)) && v > 0
        r = v <= amt ? 1 : 2
    end
    @assert r in [-1,1,2]
    return r
end


"""
hacky hack to hack AA, etc into l/m/h, sometimes without the m
"""
function map123( v :: Union{Missing,Real}, amts :: Vector ) :: Integer
    n = size(amts)[1]
    @assert n in [1,2]
    # println(n)
    r = -1
    if (! ismissing(v)) && v > 0
        if n == 1
            r = v <= amts[1] ? 1 : 3
        else
            # println("r=$r")
            if v <= amts[1]
                r = 1
            elseif v <= amts[2]
                r = 2
            else
                r = 3
            end
        end
    end
    @assert r in [-1,1,2,3]
    return r
end

#
# @returns ns for the JSType enum -1=no 1=cont, 2=income 3=mixed
# !!! FIXME DUP
function make_jsa_type( frs_res::DataFrame, sernum :: Integer, benunit  :: Integer, head :: Bool )::Tuple
    ad_frs = frs_res[((frs_res.sernum.==sernum ).&
                      (frs_res.benunit.==benunit)), [:jsatyphd,:jsatypsp,:esatyphd,:esatypsp]]
    @assert size( ad_frs )[1] .== 1
    af = ad_frs[1,:]
    jsa = head ? af.jsatyphd : af.jsatypsp
    # fixme refactor
     # 2021 has mostly single blank
     if typeof(jsa) <: AbstractString
     jsa = if jsa == " " 
         -1
       else
         parse(Int,jsa)
       end
     end
     jtype = -1
     if jsa == -1
         jtype = -1
     elseif jsa in [1,3]
         jtype = 1
     elseif jsa in [2,4]
         jtype = 2
     elseif jsa in [5,6]
         jtype = 3
     else
         @assert false "JSA: value |$jsa| not mapped"
     end 
     etype = -1
     esa = head ? af.esatyphd : af.esatypsp
     # 2021 has mostly single blank
     if typeof(esa) <: AbstractString
         esa = if esa == " " 
             -1
         else
             parse(Int,esa)
         end
     end
     
     if esa == -1
         etype = -1
     elseif esa in [1,3]
         etype = 1
     elseif esa in [2,4]
         etype = 2
     elseif esa in [5,6]
         etype = 3
     else
         @assert false "ESA: value |$esa| not mapped"
     end 
     return( jtype, etype )
 
 
     
     # see benefits PDF file 
     # 1 = Contributory
     # 2 = Income Based
     # 3 = Contributory (Imputed)
     #  4 = Income Based (Imputed)
     # 5 = Both contributory and income based
     # 6 = Both contributory and income based (Imputed)
     
end
 
#
# @returns ns for the JSType enum -1=no 1=cont, 2=income 3=mixed
#
function make_jsa_type( frs_res::DataFrame, sernum :: Integer, benunit  :: Integer, head :: Bool )::Tuple
    ad_frs = frs_res[((frs_res.sernum.==sernum ).&
                      (frs_res.benunit.==benunit)), [:jsatyphd,:jsatypsp,:esatyphd,:esatypsp]]
    @assert size( ad_frs )[1] .== 1
    af = ad_frs[1,:]
    jsa = head ? af.jsatyphd : af.jsatypsp
    # fixme refactor
     # 2021 has mostly single blank
     # FIXME DON'T NEED THIS
     if typeof(jsa) <: AbstractString
        jsa = if (jsa == " ") 
         -1
       else
         parse(Int,jsa)
       end
     end

     jtype = -1
     if ismissing(jsa) || (jsa == -1)
        jsa == -1
        #  jtype = -1
     elseif jsa in [1,3]
         jtype = 1
     elseif jsa in [2,4]
         jtype = 2
     elseif jsa in [5,6]
         jtype = 3
     else
         @assert false "JSA: value |$jsa| not mapped"
     end 
     etype = -1
     esa = head ? af.esatyphd : af.esatypsp
     # 2021 has mostly single blank
     if typeof(esa) <: AbstractString
         esa = if esa == " " 
             -1
         else
             parse(Int,esa)
         end
     end
     
     if ismissing(esa) || (esa == -1)
         etype = -1
     elseif esa in [1,3]
         etype = 1
     elseif esa in [2,4]
         etype = 2
     elseif esa in [5,6]
         etype = 3
     else
         @assert false "ESA: value |$esa| not mapped"
     end 
     return( JSAType(jtype), JSAType(etype) )
 
 
     
     # see benefits PDF file 
     # 1 = Contributory
     # 2 = Income Based
     # 3 = Contributory (Imputed)
     #  4 = Income Based (Imputed)
     # 5 = Both contributory and income based
     # 6 = Both contributory and income based (Imputed)
     
 end
 
 function initialise_person(n::Integer)::DataFrame
    pers = DataFrame(
        data_year = fill( 0, n ), # Vector{Union{Int64,Missing}}(missing, n),
        hid = fill( BigInt(0), n ), #Vector{Union{BigInt,Missing}}(missing, n),
        uhid = fill( BigInt(0), n ),  # Vector{Union{BigInt,Missing}}(missing, n), # unique combination of hid&data_year, needed for ai generation 
        pid = fill( BigInt(0), n ), # Vector{Union{BigInt,Missing}}(missing, n),
        pno = fill( 0, n ), # Vector{Union{Integer,Missing}}(missing, n),
        is_hrp = fill( false, n ), # Vector{Union{Integer,Missing}}(missing, n),
        is_bu_head = fill( false, n ), # = Vector{Union{Integer,Missing}}(missing, n),

        from_child_record = fill( false, n ), # Vector{Union{Integer,Missing}}(missing, n),
        default_benefit_unit = fill( 0, n ), # = Vector{Union{Integer,Missing}}(missing, n),
        age = fill( 0, n ), # Vector{Union{Integer,Missing}}(missing, n),
        sex = fill( Missing_Sex, n ), #  Vector{Union{Integer,Missing}}(missing, n),
        ethnic_group = fill( Missing_Ethnic_Group, n ), # Vector{Union{Integer,Missing}}(missing, n),
        marital_status = fill( Missing_Marital_Status, n ), # Vector{Union{Integer,Missing}}(missing, n),
        highest_qualification = fill( Missing_Highest_Qualification, n ), # Vector{Union{Integer,Missing}}(missing, n),
        sic = fill( Missing_SIC_2007, n ), # Missing_Vector{Union{Integer,Missing}}(missing, n),
        occupational_classification = fill( Missing_Standard_Occupational_Classification, n ), # Vector{Union{Integer,Missing}}(missing, n),
        public_or_private = fill( Missing_Employment_Sector, n ), # Vector{Union{Integer,Missing}}(missing, n),
        principal_employment_type = fill( Missing_Employment_Type, n ), # Vector{Union{Integer,Missing}}(missing, n),
        socio_economic_grouping = fill( Missing_Socio_Economic_Group, n ), # Vector{Union{Integer,Missing}}(missing, n),
        age_completed_full_time_education = fill(0,n), # Vector{Union{Integer,Missing}}(missing, n),
        years_in_full_time_work = fill(0,n), # Vector{Union{Integer,Missing}}(missing, n),
        employment_status = fill( Missing_ILO_Employment, n ), #Vector{Union{Integer,Missing}}(missing, n),
        usual_hours_worked = fill(0.0, n ), # Vector{Union{Real,Missing}}(missing, n),
        actual_hours_worked = fill(0.0, n), # Vector{Union{Real,Missing}}(missing, n),
        age_started_first_job = fill(0, n), # Vector{Union{Real,Missing}}(missing, n),
        # for widow's benefits
        type_of_bereavement_allowance = fill( missing_bereave, n ), # Vector{Union{Real,Missing}}(missing, n),
        had_children_when_bereaved = fill( false, n ), #Vector{Union{Real,Missing}}(missing, n),

        pay_includes_ssp = fill( false, n ), # Vector{Union{Integer,Missing}}(missing, n),
        pay_includes_smp = fill( false, n ), # Vector{Union{Integer,Missing}}(missing, n),
        pay_includes_spp = fill( false, n ), # Vector{Union{Integer,Missing}}(missing, n),
        pay_includes_sap = fill( false, n ), # Vector{Union{Integer,Missing}}(missing, n),
        pay_includes_mileage = fill( false, n ), # Vector{Union{Integer,Missing}}(missing, n),
        pay_includes_motoring_expenses = fill( false, n ), # Vector{Union{Integer,Missing}}(missing, n),

        income_wages = zeros(n),
        income_self_employment_income = zeros(n),
        income_self_employment_expenses = zeros(n),
        income_self_employment_losses = zeros(n),
        income_odd_jobs = zeros(n),
        income_private_pensions = zeros(n),
        income_national_savings = zeros(n),
        income_bank_interest = zeros(n),
        income_stocks_shares = zeros(n),
        income_individual_savings_account = zeros(n),
        # income_dividends = zeros(n),
        income_property = zeros(n),
        income_royalties = zeros(n),
        income_bonds_and_gilts = zeros(n),
        income_other_investment_income = zeros(n),
        income_other_income = zeros(n),
        income_alimony_and_child_support_received = zeros(n),
        income_health_insurance = zeros(n),
        income_alimony_and_child_support_paid = zeros(n),
        income_care_insurance = zeros(n),
        income_trade_unions_etc = zeros(n),
        income_friendly_societies = zeros(n),
        income_work_expenses = zeros(n),
        income_avcs = zeros(n),
        income_other_deductions = zeros(n),
        income_loan_repayments = zeros(n),
        income_student_loan_repayments = zeros(n),
        income_pension_contributions_employer = zeros(n),
        income_pension_contributions_employee = zeros(n),
        income_education_allowances = zeros(n),
        income_foster_care_payments = zeros(n),
        income_student_grants = zeros(n),
        income_student_loans = zeros(n),
        income_income_tax = zeros(n),
        income_national_insurance = zeros(n),
        income_local_taxes = zeros(n),
        income_free_school_meals = zeros(n),
        income_dlaself_care = zeros(n),
        income_dlamobility = zeros(n),
        income_child_benefit = zeros(n),
        income_pension_credit = zeros(n),
        income_state_pension = zeros(n),
        income_bereavement_allowance_or_widowed_parents_allowance_or_bereavement = zeros(n),
        income_armed_forces_compensation_scheme = zeros(n),
        income_war_widows_or_widowers_pension = zeros(n),
        income_severe_disability_allowance = zeros(n),
        income_attendance_allowance = zeros(n),
        income_carers_allowance = zeros(n),
        income_jobseekers_allowance = zeros(n),
        income_industrial_injury_disablement_benefit = zeros(n),
        income_employment_and_support_allowance = zeros(n),
        income_incapacity_benefit = zeros(n),
        income_income_support = zeros(n),
        income_maternity_allowance = zeros(n),
        income_maternity_grant_from_social_fund = zeros(n),
        income_funeral_grant_from_social_fund = zeros(n),
        income_any_other_ni_or_state_benefit = zeros(n),
        income_trade_union_sick_or_strike_pay = zeros(n),
        income_friendly_society_benefits = zeros(n),
        income_private_sickness_scheme_benefits = zeros(n),
        income_accident_insurance_scheme_benefits = zeros(n),
        income_hospital_savings_scheme_benefits = zeros(n),
        income_government_training_allowances = zeros(n),
        income_guardians_allowance = zeros(n),
        income_widows_payment = zeros(n),
        income_unemployment_or_redundancy_insurance = zeros(n),
        income_winter_fuel_payments = zeros(n),
        income_child_winter_heating_assistance_payment = zeros(n),
        income_dwp_third_party_payments_is_or_pc = zeros(n),
        income_dwp_third_party_payments_jsa_or_esa = zeros(n),
        income_social_fund_loan_repayment_from_is_or_pc = zeros(n),
        income_social_fund_loan_repayment_from_jsa_or_esa = zeros(n),
        income_extended_hb = zeros(n),
        income_permanent_health_insurance = zeros(n),
        income_any_other_sickness_insurance = zeros(n),
        income_critical_illness_cover = zeros(n),
        income_working_tax_credit = zeros(n),
        income_child_tax_credit = zeros(n),
        income_working_tax_credit_lump_sum = zeros(n),
        income_child_tax_credit_lump_sum = zeros(n),
        income_housing_benefit = zeros(n),
        income_universal_credit = zeros(n),
        income_personal_independence_payment_daily_living = zeros(n),
        income_personal_independence_payment_mobility = zeros(n),
        income_a_loan_from_the_dwp_and_dfc = zeros(n),
        income_a_loan_or_grant_from_local_authority = zeros(n),
        income_social_fund_loan_uc = zeros(n),
        income_other_benefits = zeros(n),
        income_scottish_child_payment = zeros(n),
        income_job_start_payment = zeros(n),
        income_troubles_permanent_disablement = zeros(n),
        income_child_disability_payment_care = zeros(n),
        income_child_disability_payment_mobility = zeros(n),
        income_pupil_development_grant = zeros(n),
        # FIXME next 4 shouldn't be needed
        wages_frs = zeros(n), # Vector{Union{Real,Missing}}(missing, n),
        self_emp_frs = zeros(n), # Vector{Union{Real,Missing}}(missing, n),
        wages_hbai = zeros(n), # Vector{Union{Real,Missing}}(missing, n),
        self_emp_hbai = zeros(n), # Vector{Union{Real,Missing}}(missing, n),

        jsa_type = fill( no_jsa, n ), #  Vector{Union{Integer,Missing}}(missing, n),
        esa_type = fill( no_jsa, n ), # Vector{Union{Integer,Missing}}(missing, n),
        dlaself_care_type = fill( missing_lmh, n ), # Vector{Union{Integer,Missing}}(missing, n),
        dlamobility_type = fill( missing_lmh, n ), # Vector{Union{Integer,Missing}}(missing, n),
        attendance_allowance_type = fill( missing_lmh, n ),   # = Vector{Union{Integer,Missing}}(missing, n),
        # FIXME names consistent 
        personal_independence_payment_daily_living_type = fill( no_pip, n ), # Vector{Union{Integer,Missing}}(missing, n),
        personal_independence_payment_mobility_type  = fill( no_pip, n ), #  = Vector{Union{Integer,Missing}}(missing, n),
        
        over_20_k_saving = fill(false,n),
        asset_current_account = zeros(n),
        asset_nsb_ordinary_account = zeros(n),
        asset_nsb_investment_account = zeros(n),
        asset_not_used = zeros(n),
        asset_savings_investments_etc = zeros(n),
        asset_government_gilt_edged_stock = zeros(n),
        asset_unit_or_investment_trusts = zeros(n),
        asset_stocks_shares_bonds_etc = zeros(n),
        asset_pep = zeros(n),
        asset_national_savings_capital_bonds = zeros(n),
        asset_index_linked_national_savings_certificates = zeros(n),
        asset_fixed_interest_national_savings_certificates = zeros(n),
        asset_pensioners_guaranteed_bonds = zeros(n),
        asset_saye = zeros(n),
        asset_premium_bonds = zeros(n),
        asset_national_savings_income_bonds = zeros(n),
        asset_national_savings_deposit_bonds = zeros(n),
        asset_first_option_bonds = zeros(n),
        asset_yearly_plan = zeros(n),
        asset_isa = zeros(n),
        asset_fixd_rate_svngs_bonds_or_grntd_incm_bonds_or_grntd_growth_bonds = zeros(n),
        asset_geb = zeros(n),
        asset_basic_account = zeros(n),
        asset_credit_unions = zeros(n),
        asset_endowment_policy_not_linked = zeros(n),
        asset_informal_assets = zeros(n),
        asset_post_office_card_account= Vector{Union{Real,Missing}}(missing, n),
        asset_friendly_society_investment = zeros(n),

        contracted_out_of_serps = fill( false, n ),
        registered_blind = fill( false, n ),
        registered_partially_sighted = fill( false, n ),
        registered_deaf = fill( false, n ),
        disability_vision = fill( false, n ),
        disability_hearing = fill( false, n ),
        disability_mobility = fill( false, n ),
        disability_dexterity = fill( false, n ),
        disability_learning = fill( false, n ),
        disability_memory = fill( false, n ),
        disability_mental_health = fill( false, n ),
        disability_stamina = fill( false, n ),
        disability_socially = fill( false, n ),
        disability_other_difficulty = fill( false, n ),
        health_status = fill( Missing_Health_Status, n ),

        has_long_standing_illness = fill( false, n ), # = Vector{Union{Integer,Missing}}(missing, n),
        adls_are_reduced = fill( Missing_ADLS_Inhibited, n ), #Vector{Union{Integer,Missing}}(missing, n),
        how_long_adls_reduced = fill( Missing_Illness_Length, n ), #Vector{Union{Integer,Missing}}(missing, n),

        is_informal_carer = fill( false, n ), # Vector{Union{Integer,Missing}}(missing, n),
        receives_informal_care_from_non_householder = fill( false, n ), 
        hours_of_care_received = zeros( n ), # Vector{Union{Real,Missing}}(missing, n),
        hours_of_care_given = zeros(n), #Vector{Union{Real,Missing}}(missing, n),
        hours_of_childcare = zeros(n), # Vector{Union{Real,Missing}}(missing, n),
        cost_of_childcare = zeros(n), # Vector{Union{Real,Missing}}(missing, n),
        childcare_type = fill( Missing_Child_Care_Type, n ), #Vector{Union{Integer,Missing}}(missing, n),
        employer_provides_child_care = fill( false, n ), # Vector{Union{Integer,Missing}}(missing, n),


        work_expenses = zeros(n),
        travel_to_work = zeros(n),
        debt_repayments = zeros(n),
        wealth_and_assets = zeros(n),
        totsav= zeros(Int,n),

        company_car_fuel_type = fill( Missing_Fuel_Type, n ), # Vector{Union{Integer,Missing}}(missing, n),
        company_car_value  = zeros(n), # Vector{Union{Real,Missing}}(missing, n),
        company_car_contribution  = zeros(n), # Vector{Union{Real,Missing}}(missing, n),
        fuel_supplied  = zeros(n), # Vector{Union{Real,Missing}}(missing, n),

        relationship_to_hoh = fill( Missing_Relationship, n ), #
        relationship_1 = fill( Missing_Relationship, n ), #
        relationship_2 = fill( Missing_Relationship, n ), #
        relationship_3 = fill( Missing_Relationship, n ), #
        relationship_4 = fill( Missing_Relationship, n ), #
        relationship_5 = fill( Missing_Relationship, n ), #
        relationship_6 = fill( Missing_Relationship, n ), #
        relationship_7 = fill( Missing_Relationship, n ), #
        relationship_8 = fill( Missing_Relationship, n ), #
        relationship_9 = fill( Missing_Relationship, n ), #
        relationship_10 = fill( Missing_Relationship, n ), #
        relationship_11 = fill( Missing_Relationship, n ), #
        relationship_12 = fill( Missing_Relationship, n ), #
        relationship_13 = fill( Missing_Relationship, n ), #
        relationship_14 = fill( Missing_Relationship, n ), #
        relationship_15 = fill( Missing_Relationship, n ), #
        onerand = fill( "", n ) # Vector{String}(undef,n)
    )
end

const HH_TYPE_HINTS = [
    :region => Standard_Region,
    :ct_band => CT_Band,
    :tenure => Tenure_Type
]




function initialise_household(n::Integer)::DataFrame
    # .. example check
    # FIXME change all VectorUnion to fill(0,n)
    # select value,count(value),label from dictionaries.enums where dataset='frs' and tables='househol' and variable_name='hhcomps' group by value,label;
    return DataFrame(
        data_year = fill(0,n), # Vector{Union{Integer,Missing}}(missing, n),
        interview_year = fill(0,n), # = Vector{Union{Integer,Missing}}(missing, n),
        interview_month = fill(0,n), # = Vector{Union{Integer,Missing}}(missing, n),
        quarter= fill(0,n), # = Vector{Union{Integer,Missing}}(missing, n),
        hid = fill(BigInt(0),n), # = Vector{Union{BigInt,Missing}}(missing, n),
        uhid = fill(BigInt(0),n), # Vector{Union{BigInt,Missing}}(missing, n), # unique combination of hid&data_year, needed for ai generation 
        tenure = fill(Missing_Tenure_Type,n), # Vector{Union{Integer,Missing}}(missing, n),
        region = fill( Missing_Standard_Region, n ), # Vector{Union{Integer,Missing}}(missing, n),
        ct_band = fill( Missing_CT_Band, n ), # Vector{Union{Integer,Missing}}(missing, n),
        dwelling = fill( dwell_na, n ), # Vector{Union{Integer,Missing}}(missing, n),
        council_tax = zeros(n), # Vector{Union{Real,Missing}}(missing, n),
        water_and_sewerage = zeros(n), #  = Vector{Union{Real,Missing}}(missing, n),
        mortgage_payment = zeros(n), #  = Vector{Union{Real,Missing}}(missing, n),
        mortgage_interest = zeros(n), #  = Vector{Union{Real,Missing}}(missing, n),
        years_outstanding_on_mortgage = fill(0,n), # Vector{Union{Integer,Missing}}(missing, n),
        mortgage_outstanding = zeros(n), #  = Vector{Union{Real,Missing}}(missing, n),
        year_house_bought = fill(0,n), # = Vector{Union{Integer,Missing}}(missing, n),
        gross_rent = zeros(n), # = Vector{Union{Real,Missing}}(missing, n),
        rent_includes_water_and_sewerage = fill( false,  n ), #Vector{Union{Integer,Missing}}(missing, n),
        other_housing_charges = zeros(n), # Vector{Union{Real,Missing}}(missing, n),
        gross_housing_costs = zeros(n), # = Vector{Union{Real,Missing}}(missing, n),
        original_gross_income = zeros(n), # = Vector{Union{Real,Missing}}(missing, n),
        total_wealth = zeros(n), # = Vector{Union{Real,Missing}}(missing, n),
        house_value = zeros(n), # = Vector{Union{Real,Missing}}(missing, n),
        weight = zeros(n), # = Vector{Union{Real,Missing}}(missing, n),
        council = fill( "", n ),
        nhs_board = fill( "", n ),
        bedrooms = fill( 0, n ),
        # these should map to the corresponding WAS hh categories
        net_physical_wealth = zeros(n), # todo change all the rest to zeros(n)
        net_financial_wealth = zeros(n),
        net_housing_wealth = zeros(n),
        net_pension_wealth = zeros(n),
        onerand = fill("", n ) # Vector{String}(undef,n)
    )
end

#
# the way this seems to work: if deduc1 in job record
# is > 0, the employee contrib here is set to -1
#
function process_penprovs(a_pens::DataFrame)::Tuple
    npens = size(a_pens)[1]
    penconts_employer = 0.0
    penconts_employee = 0.0
    for p in 1:npens
        pen = a_pens[p,:]
        pc = safe_inc(0.0, pen.penamt)
        if pen.penamtpd == 95
            pc /= 52.0
        end
        if pen.pencon in [1,4,5] # ish ...
            penconts_employee += pc
        elseif pen.pencon == 2 # employer
            penconts_employer += pc
        elseif pen.pencon == 3 # oth employer and employee
            penconts_employer += pc/2
            penconts_employee += pc/2   
        end
    end
    # FIXME something about SERPS
    (penconts_employee,penconts_employer)
end

function process_pensions(a_pens::DataFrame)::NamedTuple
    npens = size(a_pens)[1]
    private_pension = 0.0
    tax = 0.0
    for p in 1:npens
        private_pension = safe_inc(private_pension, a_pens[p, :penpay])
        private_pension = safe_inc(private_pension, a_pens[p, :ptamt]) # tax
        private_pension = safe_inc(private_pension, a_pens[p, :penpd2]) # other deduction
        tax = safe_inc(tax, a_pens[p, :ptamt])
    end
    return (pension = private_pension, tax = tax)
end

const NS_RATE = 0.01/WEEKS_PER_YEAR

#     | 2016 | accounts | nsamt         | 1     | Jan-50                                                       | Jan_50                                                             |    0
#     | 2016 | accounts | nsamt         | 2     | 51 - 100                                                     | v_51_100                                                           |    0
#     | 2016 | accounts | nsamt         | 3     | 101 - 250                                                    | v_101_250                                                          |    0
#     | 2016 | accounts | nsamt         | 4     | 251 - 500                                                    | v_251_500                                                          |    0
#     | 2016 | accounts | nsamt         | 5     | 501 - 1000                                                   | v_501_1000                                                         |    0
#     | 2016 | accounts | nsamt         | 6     | 1001 - 2000                                                  | v_1001_2000                                                        |    0
#     | 2016 | accounts | nsamt         | 7     | 2001 - 3000                                                  | v_2001_3000                                                        |    0
#     | 2016 | accounts | nsamt         | 8     | 3001 - 5000                                                  | v_3001_5000                                                        |    0
#     | 2016 | accounts | nsamt         | 9     | 5001 - 10,000                                                | v_5001_10_000                                                      |    0
#     | 2016 | accounts | nsamt         | 10    | 10,001 - 20,000                                              | v_10_001_20_000                                                    |    0
#     | 2016 | accounts | nsamt         | 11    | 20,001 - 30,000                                              | v_20_001_30_000                                                    |    0
#     | 2016 | accounts | nsamt         | 12    | 30,001 or over                                               | v_30_001_or_over                                                   |    0
const NSAMT_ENUM_MIDPOINTS = [
    25.0,
    75.0,
    175.0,
    375.0,
    750.0,
    1_500.0,
    2_500.0,
    4_000.0,
    7_500.0,
    15_000.0,
    25_000.0,
    40_000.0
]

"""
infer amounts from holdings (nsamt) assuming 1% pa interest rate
see: https://www.nsandi.com/historical-interest-rates for rates
why FRS records like this I have no idea
"""
function infer_national_savings_income( nsamt :: Integer )::Real
    @assert ! (nsamt in [1:12]) "nsr out of range for enum: $nsamt"
    NSAMT_ENUM_MIDPOINTS[ nsamt ]*NS_RATE
end

function map_investment_income!(model_adult::DataFrameRow, accounts::DataFrame)
    naccts = size(accounts)[1]

    model_adult.income_national_savings = 0.0
    model_adult.income_bank_interest = 0.0
    model_adult.income_stocks_shares = 0.0
    model_adult.income_individual_savings_account = 0.0
    model_adult.income_property = 0.0
    model_adult.income_royalties = 0.0
    model_adult.income_bonds_and_gilts = 0.0
    model_adult.income_other_investment_income = 0.0


    for i in 1:naccts
        v = max(0.0, accounts[i, :accint]) # FIXME national savings stuff appears to be coded -1 for missing
        if accounts[i, :invtax] == 1
            # FIXME is this right for dividends anymore?
            v /= 0.8
        end
        # FIXME building society - check with other models
        # FIXME go over assignment to broad types against income
        # tax book
        atype = Account_Type(accounts[i, :account])
        nsamt = accounts[i, :nsamt]
        #
        # for national savings, amount held is recorded
        # for the rest acctoint = interest pw from account
        if nsamt > 0
            model_adult.income_national_savings +=
                infer_national_savings_income( nsamt ) # FIXME appears to be all zero!
        elseif atype in [
            Current_account,
            Basic_Account,
            NSB_Investment_account,
            NSB_Direct_Saver

        ]
            model_adult.income_bank_interest += v
        elseif atype in [
            National_Savings_capital_bonds,
            Index_Linked_National_Savings_Certificates,
            Fixed_Interest_National_Savings_Certificates,
            National_Savings_income_bonds,
            National_Savings_deposit_bonds
        ]
            ## this should never happen given, but does..
            # the weird way the FRS records National Savings as stocks
            # nsamt should always be set for these records & handled above.
            # @assert false
            # println( "atype = $atype but nsamt is $nsamt" )
        elseif atype in [
            Stocks_Shares_Bonds_etc,
            Member_of_Share_Club]
            model_adult.income_stocks_shares += v
        elseif atype in [ISA]
            model_adult.income_individual_savings_account += v
        elseif atype in [
            SAYE,
            Savings_investments_etc,
            Unit_or_Investment_Trusts,
            Endowment_Policy_Not_Linked,
            Profit_sharing,
            Credit_Unions,
            Yearly_Plan,
            Premium_bonds,
            Company_Share_Option_Plans,
            Post_Office_Card_Account,
            Pensioners_Guaranteed_Bonds,
            Informal_Assets,            
            Friendly_Society_Investment
        ]
            model_adult.income_other_investment_income += v
        elseif atype in [
            Guaranteed_Equity_Bond,
            Fixed_Rate_Savings_or_Guaranteed_Income_or_Guaranteed_Growth_Bonds,
            First_Option_bonds,
            Government_Gilt_Edged_Stock]
            model_adult.income_bonds_and_gilts += v
        else
            @assert false "failed to map $atype"
        end
    end # accounts loop
end # map_investment_income

function map_alimony(frs_person::DataFrameRow, a_maint::DataFrame)::Tuple
    nmaints = size(a_maint)[1]
    alimony_paid = 0.0 # note: not including children
    alimony_recieved = 0.0 # note: not including children
    if frs_person.alimny == 1 # receives alimony
        if frs_person.alius == 2 # not usual
            alimony_recieved = safe_inc(0.0, frs_person.aluamt)
        else
            alimony_recieved = safe_inc(0.0, frs_person.aliamt)
        end
    end
    for c in 1:nmaints
        alimony_paid = safe_inc(alimony_paid, a_maint[c, :mramt])
    end
    alimony_recieved, alimony_paid
end

function map_car_value( cv :: Integer ) :: Real
    v = 0.0
    @assert cv <= 10 "cv out-of-range = $cv"
    if cv < 0
        v = 0.0
    elseif cv == 1
        v = 5_000.0
    elseif cv == 2
        v = 11_500.0
    elseif cv == 3
        v = 14_500.0
    elseif cv == 4
        v = 17_500.0
    elseif cv == 5
        v = 20_500.0
    elseif cv == 6
        v = 23_500.0
    elseif cv == 7
        v = 27_500.0
    elseif cv == 8
        v = 35_000.0
    elseif cv == 9
        v = 45_000.0
    elseif cv == 10
        v = 20_000 # Don't_know = 10
    end
    v
end

"""
process the "r01..r014 and relhrp codes. Note we're adding 'this person' (=0) rather than missing as in the raw data"
"""
function process_relationships!( model_person :: DataFrameRow, frs_person :: DataFrameRow )
    relhh = safe_assign( frs_person.relhrp )
    if (relhh == -1 )
        relhh = 0 # map 'this person'; note hrp/head no longer needs to be 1
    end
    model_person.relationship_to_hoh =  Relationship( relhh )#
    for i in 1:14
        rel = i < 10 ? "r0" : "r"
        relfrs = Symbol( "$(rel)$i" ) # :r10 or :r02 and so on
        relmod = Symbol( "relationship_$(i)") # :relationship_10 or :relationship_2
        relp = safe_assign(frs_person[relfrs])
        if (frs_person.person == i) & (relp == -1) # again "this person = 0; makes mapping code (and just reading output) easier
            relp = 0
        end
        model_person[relmod] = Relationship(relp)
    end
end

function process_job_rec!(model_adult::DataFrameRow, a_job::DataFrame)
    njobs = size(a_job)[1]

    earnings = 0.0
    actual_hours = 0.0
    usual_hours = 0.0
    health_insurance = 0.0
    alimony_and_child_support_paid = 0.0
    # care_insurance  = 0.0
    trade_unions_etc = 0.0
    friendly_societies = 0.0
    work_expenses = 0.0
    pension_contributions_employee = 0.0
    avcs = 0.0
    other_deductions = 0.0
    student_loan_repayments = 0.0
    loan_repayments = 0.0
    self_employment_income = 0.0
    self_employment_expenses = 0.0
    self_employment_losses = 0.0
    tax = 0.0
    principal_employment_type = -1
    public_or_private = -1

    company_car_fuel_type = 0
    company_car_value = 0.0
    company_car_contribution = 0.0
    fuel_supplied = 0.0

    for j in 1:njobs
        jb = a_job[j,:] # 1 row
        if j == 1 # take 1st record job for all of these
            principal_employment_type = safe_assign(jb.etype)
            public_or_private = safe_assign(jb.jobsect)
        end
        usual_hours = safe_inc(usual_hours, jb.dvushr)
        actual_hours = safe_inc(actual_hours, jb.jobhours)

        # alimony_and_child_support_paid  = safe_inc( alimony_and_child_support_paid , a_job[j,udeduc0X])
        # care_insurance  = safe_inc( care_insurance , jb.othded0X
        # note these are *Usual* deductions
        # "1... contribution *by you* to a Pension or superannuation scheme?"
        # I *think* these contributions 
        pension_contributions_employee = safe_inc(pension_contributions_employee, jb.udeduc1)
        avcs = safe_inc(avcs, jb.udeduc2)
        trade_unions_etc = safe_inc(trade_unions_etc, jb.udeduc3)
        friendly_societies = safe_inc(friendly_societies, jb.udeduc4)
        other_deductions = safe_inc(other_deductions, jb.udeduc5)
        loan_repayments = safe_inc(loan_repayments, jb.udeduc6)
        health_insurance = safe_inc(health_insurance, jb.udeduc7)
        other_deductions = safe_inc(other_deductions, jb.udeduc8)
        student_loan_repayments = safe_inc(student_loan_repayments, jb.udeduc9)
        work_expenses = safe_inc(work_expenses, jb.umotamt)# CARS FIXME add to this
        
        if jb.inclpay1 == 1
            model_adult.pay_includes_ssp = true
        end
        if jb.inclpay2 == 1
            model_adult.pay_includes_smp = true
        end
        # it refund .. 3
        if jb.inclpay4 == 1
            model_adult.pay_includes_mileage = true
        end
        if jb.inclpay5 == 1
            model_adult.pay_includes_motoring_expenses = true
        end
        if jb.inclpay6 == 1
            model_adult.pay_includes_spp = true
        end
        if jb.inclpay7 == 1
            model_adult.pay_includes_sap = true
        end
        
        # self employment
        if jb.prbefore > 0.0
            self_employment_income += jb.prbefore
        elseif jb.profit1 > 0.0 
            if jb.profit2 == -1
                # println( "jb.profit2 is |$(jb.profit2)| should be 1,2 pid=$(model_adult.pid)")
                jb.profit2 = 1# jb.profit2 catch 1 weird -1 profit2 pid=120191636601 just treat as profit not loss
            end
            @assert jb.profit2 in [1, 2] 
            if jb.profit2 == 1
                self_employment_income += jb.profit1
            else
                self_employment_losses += jb.profit1
            end
        elseif jb.seincamt > 0.0
            self_employment_income += jb.seincamt
        end
        # setax = safe_inc(0.0, jb.setaxamt)
        # tax += setax / 52.0

        # earnings
        addBonus = false
        if jb.ugross > 0.0 # take usual when last not usual
            earnings += jb.ugross
            addBonus = true
        elseif jb.grwage > 0.0 # then take last
            earnings += jb.grwage
            addBonus = true
        elseif jb.ugrspay > 0.0 # then take total pay, but don't add bonuses
            earnings += jb.ugrspay
        end
        if addBonus
            for i in 1:6
                bon = Symbol(string("bonamt", i))
                tax = Symbol(string("bontax", i))
                if a_job[j, bon] > 0.0
                    bon = a_job[j, bon]
                    if a_job[j, tax] == 2
                        bon /= (1 - 0.22) # fixme hack basic rate
                    end
                    earnings += bon / 52.0 # fixwme weeks per year
                end
            end # bonuses loop
        end # add bonuses
        # cars
        # assign once
        if company_car_fuel_type < 0
            company_car_fuel_type = jb.fueltyp
        end
        mv = map_car_value(jb.carval)
        # println( mv )
        company_car_value = safe_inc(company_car_value, mv )
        company_car_contribution = safe_inc(company_car_contribution, jb.caramt)
        fuel_supplied = safe_inc(fuel_supplied, jb.fuelamt)

    end # jobs loop

    model_adult.usual_hours_worked = usual_hours
    model_adult.actual_hours_worked = actual_hours
    model_adult.income_wages = earnings
    model_adult.principal_employment_type = Employment_Type(principal_employment_type)
    model_adult.public_or_private = Employment_Sector(public_or_private)
    ## FIXME look at this mapping again: pcodes
    model_adult.income_health_insurance = health_insurance
    # model_adult.income_# care_insurance  = # care_insurance
    model_adult.income_trade_unions_etc = trade_unions_etc
    model_adult.income_friendly_societies = friendly_societies
    model_adult.income_work_expenses = work_expenses
    model_adult.income_pension_contributions_employee = pension_contributions_employee
    model_adult.income_avcs = avcs
    model_adult.income_other_deductions = other_deductions
    model_adult.income_student_loan_repayments = student_loan_repayments # fixme maybe "slrepamt" or "slreppd"
    model_adult.income_loan_repayments = loan_repayments # fixme maybe "slrepamt" or "slreppd"

    model_adult.income_self_employment_income = self_employment_income
    model_adult.income_self_employment_expenses = self_employment_expenses
    model_adult.income_self_employment_losses = self_employment_losses

    model_adult.company_car_fuel_type = Fuel_Type(company_car_fuel_type)
    model_adult.company_car_value = company_car_value
    model_adult.company_car_contribution = company_car_contribution
    model_adult.fuel_supplied = fuel_supplied
end

"""
Convoluted - take the benefit enum, make ...
FIXME: some represent one-off payments (winter fuel..) so maybe weeklyise, but all that
really matters is whether they are present
"""
function process_benefits!( model_adult::DataFrameRow, a_benefits::DataFrame)
    nbens = size(a_benefits)[1]
    for i in instances(Incomes_Type)
        if i >= dlaself_care && i <= personal_independence_payment_mobility
            ikey = make_sym_for_frame("income", i)
            model_adult[ikey] = 0.0
        end
    end
    for b in 1:nbens
        bno = a_benefits[b, :benefit]
        if !(bno in [46, 47]) # 2015 receipt in last 6 months of tax credits
            btype = Benefit_Type(bno)
            # println( "bno=$bno BenefitType=$btype")
            if btype <= Personal_Independence_Payment_Mobility
                ikey = make_sym_for_frame("income", btype)
                # println( "ikey=$ikey")
                model_adult[ikey] = safe_inc(model_adult[ikey], a_benefits[b, :benamt])
            end
        end
    end
end

"""
Convoluted - take the benefit enum, make ...
"""
function process_assets!(model_adult::DataFrameRow, an_asset::DataFrame)
    nassets = size(an_asset)[1]
    for i in instances(Asset_Type)
        if (i > Missing_Asset_Type)
            ikey = make_sym_for_asset(i)
            model_adult[ikey] = 0.0
        end
    end
    for a in 1:nassets
        ano = an_asset[a, :assetype]
        atype = Asset_Type(ano)
        ikey = make_sym_for_asset(atype)
        v = an_asset[a, :howmuch]
        if an_asset[a, :howmuche] > 0
            v = an_asset[a, :howmuche]
        end
        model_adult[ikey] = safe_inc(model_adult[ikey], v)
    end
end

function infer_hours_of_care(hourtot::Integer)::Real
    hrs = Dict(
        0 => 0.0,
        1 => 2.0,
        2 => 7.0,
        3 => 14.0,
        4 => 27.5,
        5 => 42.5,
        6 => 75.0,
        7 => 100.0,
        8 => 10.0,
        9 => 27.5,
        10 => 50.0
    )
    h = 0.0
    if hourtot in keys(hrs)
        h = hrs[hourtot]
    end
    h
end

"""
remap child care type from pre-2017 version to 2017+
"""
function map_child_care( year :: Integer, care ) :: Integer
    if ismissing( care ) || care < -1
        care = -1
    end
    if year >= 2017
        return care
    end
    if care > 0 # remap to2015/16 care to 2017+
        m = Dict(
            1=>1,
            2=>2,
            3=>3,
            4=>5,
            5=>4,
            6=>5,
            7=>4,
            8=>7,
            9=>8,
            10=>9,
            11=>10,
            12=>10,
            13=>11,
            14=>12,
            15=>13,
            16=>14,
            17=>15,
            18=>16,
            19=>17,
            20=>18
        )
        care = m[care]
    end
    care
end


function xparse(s::AbstractString)::Real
    parse(Float64,s)
end

function xparse(s::Missing)::Number
    0
end

function xparse(s::Number)::Number
    s
end

"""
Weekly equivalent of annual capital repayment on a mortgage. FIXME: Note the misnamed slot I'm putting this in pro. tem.
The mortgage record has been murdered in FRS 2021/2
but the fields we need are in the monster record, so get from
that. Note early versions have 3 records and later frsxs have 2.
"""
function mortage_capital_payments( frsx :: AbstractDataFrame )::Real
    #=
    if size(frsx)[1] == 0
        return 0.0
    end
    =#
    @argcheck size(frsx)[1] in 1:10 # count of BUs
    nmortgages = frsx.data_year[1] < 2020 ? 3 : 2
    cappay = 0.0
    for fx in eachrow(frsx)
        for mortno in 1:nmortgages 
            mortends = fx[Symbol("mortend$mortno")]
            if ! ismissing( mortends )
                mortend = xparse( mortends )
                rmort = xparse(fx[Symbol("rmort$mortno")])
                rmamt = xparse(fx[Symbol("rmamt$mortno")])
                borramt = xparse(fx[Symbol("borramt$mortno")])
                cap = if rmort == 1
                    rmamt 
                else
                    borramt
                end
                repay = cap/mortend
                # println( "mortend=$mortend rmort=$rmort ramt=$rmamt borramt=$borramt => $cap => repay=$repay")
                cappay += repay
            end
        end
    end
    cappay/WEEKS_PER_YEAR;
end


