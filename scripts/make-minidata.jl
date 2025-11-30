using CSV
using DataFrames
using GLM
using Random

using ScottishTaxBenefitModel
using .Definitions
using .FRSHouseholdGetter
using .RunSettings
using .Utils

@enum Dwelling2 house flat_or_other
@enum Employment2 no_employment employee self_employed unemployed student retired sick inactive
@enum Sex2 male female 
@enum Health2 good_health bad_health
@enum MaritalStatus2 married single 
@enum Education2 degree higher_school lower_school no_qualification
@enum Tenure2 social_renter private_renter owner_occuper 

const DDIR = "/mnt/data/Northumbria/minitax/actual_data/"

const emp_recodes = Dict([
    Missing_ILO_Employment => no_employment,
    Full_time_Employee => employee,
    Part_time_Employee => employee,
    Full_time_Self_Employed => self_employed,
    Part_time_Self_Employed => self_employed,
    Unemployed => unemployed,
    Retired => retired,
    Student => student,
    Looking_after_family_or_home => inactive,
    Permanently_sick_or_disabled => sick,
    Temporarily_sick_or_injured => sick,
    Other_Inactive => inactive ])

const ten_recodes = Dict([
    Council_Rented => social_renter,
    Housing_Association => social_renter,
    Private_Rented_Unfurnished => private_renter,
    Private_Rented_Furnished => private_renter,
    Mortgaged_Or_Shared => owner_occuper,
    Owned_outright => owner_occuper,
    Rent_free => private_renter,
    Squats => private_renter ])

const marital_recodes = Dict([
    Missing_Marital_Status => single,
    Married_or_Civil_Partnership => married,
    Cohabiting => married,
    Single => single,
    Widowed => single,
    Separated => single,
    Divorced_or_Civil_Partnership_dissolved => single])

const dwelling_recodes = Dict([
    dwell_na => flat_or_other,
    detatched => house,
    semi_detached => house,
    terraced => house,
    flat_or_maisonette => flat_or_other,
    converted_flat => flat_or_other,
    caravan => flat_or_other,
    other_dwelling => flat_or_other ])

const sex_recodes = Dict([
    Male=>male,
    Female=>female])

const health_recodes = Dict([
    Missing_Health_Status => good_health,
    Very_Good  => good_health,
    Good  => good_health,
    Fair  => good_health,
    Bad  => bad_health,
    Very_Bad => bad_health ])
   

function makedfs( nhhs, npers )
    hhlds = DataFrame(
        hno = fill(0,nhhs),
        weight = fill(0.0, nhhs ),
        tenure = fill( social_renter, nhhs ),
        dwelling = fill( house, nhhs ),
        rent = fill(0.0, nhhs ),
        mortgage = fill(0.0, nhhs ),
        total_wealth = fill(0.0, nhhs ),
        housing_wealth = fill(0.0, nhhs ),
        financial_wealth = fill(0.0, nhhs ),
        pension_wealth = fill(0.0, nhhs ),
        exp_food = fill(0.0, nhhs ),
        exp_alcohol = fill(0.0, nhhs ),
        exp_tobacco = fill(0.0, nhhs ),
        exp_clothing = fill(0.0, nhhs ),
        exp_transport = fill(0.0, nhhs ),
        exp_energy  = fill(0.0, nhhs ),
        exp_other_goods = fill(0.0, nhhs ),
        num_people = fill(0, nhhs ),
        num_children = fill(0, nhhs ),
        num_pensioners = fill(0, nhhs ))

    people = DataFrame(
        hno = fill(0,npers ),
        pno = fill(0,npers ),
        age = fill(0, npers ),
        sex = fill(male, npers ),
        employment = fill(inactive,npers ),
        marital_status = fill(single, npers),
        hours = fill(0.0, npers ),
        years_in_work = fill( 0, npers ),
        wages = fill(0.0, npers ),
        self_employment_income = fill(0.0, npers ),
        savings_income = fill(0.0, npers ),
        pension_income = fill(0.0, npers ),
        other_income = fill(0.0, npers ),
        health = fill( good_health, npers ))
    hhlds, people
end

function fill_cons!( hr :: DataFrameRow, cons :: DataFrameRow )

    hr.exp_food = 
        cons.sweets_and_icecream +
        cons.other_food_and_beverages +
        cons.hot_and_eat_out_food

    hr.exp_alcohol = 
        cons.spirits +
        cons.wine +
        cons.fortified_wine +
        cons.cider +
        cons.alcopops +
        cons.champagne +
        cons.beer

    hr.exp_tobacco = 
        cons.cigarettes +
        cons.cigars +
        cons.other_tobacco

    hr.exp_clothing = 
        cons.childrens_clothing_and_footwear +
        cons.helmets_etc +
        cons.other_clothing_and_footwear

    hr.exp_energy = 
        cons.domestic_fuel_electric +
        cons.domestic_fuel_gas +
        cons.domestic_fuel_coal +
        cons.domestic_fuel_other

    hr.exp_transport =    
        cons.bus_boat_and_train +
        cons.air_travel +
        cons.petrol +
        cons.diesel +
        cons.other_motor_oils +
        cons.other_transport

    hr.exp_other_goods = 
        cons.other_housing +
        cons.furnishings_etc +
        cons.medical_services +
        cons.prescriptions +
        cons.other_medicinces +
        cons.spectacles_etc +
        cons.other_health +
        cons.communication +
        cons.books +
        cons.newspapers +
        cons.magazines +
        cons.gambling +
        cons.museums_etc +
        cons.postage +
        cons.other_recreation +
        cons.education +
        cons.hotels_and_restaurants +
        cons.insurance +
        cons.other_financial +
        cons.prams_and_baby_chairs +
        cons.care_services +
        cons.trade_union_subs +
        cons.nappies +
        cons.funerals +
        cons.womens_sanitary +
        cons.other_misc_goods +
        cons.non_consumption +
        cons.repayments
end

const GROSS_OTHER_INC = Incomes_Set([ 
    royalties, 
    odd_jobs, 
    other_income,
    alimony_and_child_support_received,
    education_allowances,
    foster_care_payments,
    student_grants,
    student_loans,
    free_school_meals,
    dlaself_care,
    dlamobility,
    child_benefit,
    pension_credit,
    state_pension,
    bereavement_allowance_or_widowed_parents_allowance_or_bereavement,
    armed_forces_compensation_scheme,
    war_widows_or_widowers_pension,
    severe_disability_allowance,
    attendance_allowance, ## FIXME SP!
    carers_allowance,
    jobseekers_allowance,
    industrial_injury_disablement_benefit,
    employment_and_support_allowance,
    incapacity_benefit,
    income_support,
    maternity_allowance,
    maternity_grant_from_social_fund,
    funeral_grant_from_social_fund,
    any_other_ni_or_state_benefit,
    trade_union_sick_or_strike_pay,
    friendly_society_benefits,
    private_sickness_scheme_benefits,
    accident_insurance_scheme_benefits,
    hospital_savings_scheme_benefits,
    government_training_allowances,
    guardians_allowance,
    widows_payment,
    unemployment_or_redundancy_insurance,
    winter_fuel_payments,
    child_winter_heating_assistance_payment,
    dwp_third_party_payments_is_or_pc,
    dwp_third_party_payments_jsa_or_esa,
    social_fund_loan_repayment_from_is_or_pc,
    social_fund_loan_repayment_from_jsa_or_esa,
    extended_hb,
    permanent_health_insurance,
    any_other_sickness_insurance,
    critical_illness_cover,
    working_tax_credit,
    child_tax_credit,
    working_tax_credit_lump_sum,
    child_tax_credit_lump_sum,
    housing_benefit,
    universal_credit,
    personal_independence_payment_daily_living,
    personal_independence_payment_mobility,
    scottish_child_payment,
    job_start_payment,
    troubles_permanent_disablement,
    child_disability_payment_care,
    child_disability_payment_mobility,
    pupil_development_grant,
    adp_daily_living,
    adp_mobility,
    pension_age_disability,
    carers_allowance_supplement,
    carers_support_payment,
    discretionary_housing_payment,
    other_benefits ])


function create_simple( settings; reset=false )
    nhhs, npers, nhhs2 = FRSHouseholdGetter.initialise( settings; reset=reset )
    hhlds, people = makedfs( nhhs, npers )
    pno = 0
    for hno in 1:nhhs
        hh = get_household( hno )
        hr = hhlds[hno,:]
        fill_cons!( hr, hh.expenditure )
        hr.weight = hh.weight
        hr.hno = hno
        hr.tenure = ten_recodes[ hh.tenure ]
        hr.dwelling = dwelling_recodes[ hh.dwelling ]
        hr.rent = hh.gross_rent
        hr.mortgage = hh.mortgage_payment
        hr.total_wealth = hh.total_wealth
        hr.housing_wealth = hh.net_housing_wealth
        hr.financial_wealth = hh.net_financial_wealth
        hr.pension_wealth = hh.net_pension_wealth

        pids = sort(collect(keys( hh.people )))
        lpno = 0
        for p in pids
            pno += 1
            lpno += 1
            pers = hh.people[p]
            pr = people[pno,:]
            pr.age = pers.age
            pr.sex = sex_recodes[pers.sex]
            pr.marital_status = marital_recodes[ pers.marital_status]
            pr.years_in_work = pers.years_in_full_time_work
            pr.hours = pers.usual_hours_worked
            pr.health = health_recodes[pers.health_status]
            pr.employment = emp_recodes[pers.employment_status]
            if pr.employment == sick # make this consistent for the poor wee AI
                pr.health = bad_health
            end
            pr.hno = hno
            pr.pno = lpno     
            pr.wages = sum( pers.income, Set([wages]))  
            pr.self_employment_income = sum( pers.income, Set([self_employment_income]))  
            pr.savings_income = sum( pers.income, Set([   
                national_savings,bank_interest,stocks_shares,
                individual_savings_account,property,
                bonds_and_gilts,
                other_investment_income ]))
            pr.other_income = sum( pers.income, GROSS_OTHER_INC )  
            pr.pension_income = sum( pers.income, Set([private_pensions]))
        end
    end
    gdf = groupby(people,:hno)
    hhlds.num_children = combine(gdf,:age=>(a->sum(a.<=16)) =>:num_children)[:,2]
    hhlds.num_pensioners = combine(gdf,:age=>(a->sum(a.>=66)) =>:num_pensioners)[:,2]
    hhlds.num_people = combine(gdf,:age=>length)[:,2]
    hhlds.num_females = combine(gdf,:sex=>(s->sum(s.==female)))[:,2]
    hhlds.num_males = combine(gdf,:sex=>(s->sum(s.==male)))[:,2]
    hhlds.gross_income = combine(gdf,
        [:wages, :savings_income, :pension_income, :other_income, :self_employment_income]
        =>(w,s,p,o,e)->sum(w .+ s .+ p .+ o .+ e))[:,2]
    hhlds.total_spending = 
        hhlds.exp_food .+ 
        hhlds.exp_alcohol .+ 
        hhlds.exp_tobacco .+ 
        hhlds.exp_clothing .+ 
        hhlds.exp_transport .+ 
        hhlds.exp_energy .+ 
        hhlds.exp_other_goods .+
        hhlds.rent .+
        hhlds.mortgage
    heads = people[people.pno.==1,:]
    hhlds.age_head = heads.age
    hhlds.employment_head = heads.employment
    
    hhlds, people 
end

function run_regressions( hhlds::DataFrame, people::DataFrame )
    hl = deepcopy(hhlds)
    pp = deepcopy(people)
    hl = hl[hl.gross_income .> 0, : ]
    hl.l_gross_income = log.(hl.gross_income)
    
    #=


@enum Dwelling2 house flat_or_other
@enum Employment2 no_employment employee self_employed unemployed student retired sick inactive
@enum Sex2 male female 
@enum Health2 good_health bad_health
@enum MaritalStatus2 married single 
@enum Education2 degree higher_school lower_school no_qualification
@enum Tenure2 social_renter private_renter owner_occuper 

    =#
  
    hl.sh_food  = hl.exp_food ./ hl.total_spending 
    hl.sh_alcohol  = hl.exp_alcohol ./ hl.total_spending 
    hl.sh_tobacco  = hl.exp_tobacco ./ hl.total_spending 
    hl.sh_clothing  = hl.exp_clothing ./ hl.total_spending 
    hl.sh_transport  = hl.exp_transport ./ hl.total_spending 
    hl.sh_energy  = hl.exp_energy ./ hl.total_spending 
    hl.sh_other_goods  = hl.exp_other_goods ./ hl.total_spending
    hl.sh_rent = hl.rent ./ hl.total_spending
    hl.sh_mortgage = hl.mortgage ./ hl.total_spending
    
    hl_rent = hl[ hl.tenure .∈ ( [social_renter, private_renter], ), : ]
    hl_mort = hl[ hl.mortgage .> 0, :]

end

settings = Settings()
settings.do_indirect_tax_calculations = true
hhlds, people = create_simple( settings )
CSV.write( "$(DDIR)/simple_hhlds.tab", hhlds; delim='\t')
CSV.write( "$(DDIR)/simple_pers.tab", people; delim='\t')

run_regressions( hhlds, people )
