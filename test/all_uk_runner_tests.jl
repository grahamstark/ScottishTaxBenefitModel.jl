using Test
using CSV
using ArgCheck
using DataFrames
using StatsBase
using BenchmarkTools
using PrettyTables
using Observables
using ScottishTaxBenefitModel
using .GeneralTaxComponents
using .HealthRegressions
using .STBParameters
using .Runner: do_one_run
using .RunSettings
using .Utils
using .Monitor: Progress
using .ExampleHelpers
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames!, make_gain_lose


BenchmarkTools.DEFAULT_PARAMETERS.seconds = 120
BenchmarkTools.DEFAULT_PARAMETERS.samples = 2


const targets = [ :label,
    :income_tax,  :national_insurance,  :local_taxes,  :social_fund_loan_repayment,  
    :student_loan_repayments,  :care_insurance,  :child_benefit,  :state_pension,  
    :bereavement_allowance,  :armed_forces_compensation_scheme,  :war_widows_pension,  
    :severe_disability_allowance,  :attendance_allowance,  :carers_allowance,  
    :industrial_injury_benefit,  :incapacity_benefit,  :personal_independence_payment_daily_living,  
    :personal_independence_payment_mobility,  :dla_self_care,  :dla_mobility,  
    :education_allowances,  :foster_care_payments,  :maternity_allowance,  
    :maternity_grant,  :funeral_grant,  :any_other_ni_or_state_benefit,  :friendly_society_benefits,  
    :government_training_allowances,  :contrib_jobseekers_allowance,  :guardians_allowance,  
    :widows_payment,  :winter_fuel_payments,  :working_tax_credit,  :child_tax_credit,  
    :non_contrib_employment_and_support_allowance,  :income_support,  :pension_credit,  
    :savings_credit,  :non_contrib_jobseekers_allowance,  
    :housing_benefit,  :free_school_meals,  :universal_credit,  :other_benefits]

@testset "UK Basic Run" begin
    summary, results, settings = do_basic_uk_run()
    #=
    # typeof( results )
    # println( results )
    outps_pre = create_health_indicator( 
        results.hh[1], 
        summary.deciles[1], 
        obs,
        settings )
    sz = size( outps_pre )
    println( "size $(results.hh[1])" )
    sz = size( results.hh[1] )
    # println( "results.hh[1] size $sz" )
    outps_post = create_health_indicator( 
        results.hh[2], 
        summary.deciles[2], 
        obs,
        settings )
    println( "outps_post=$outps_post")
    CSV.write( "/home/graham_s/tmp/income_summary_uk.csv", summary.income_summary[1])
    sf_pre = summarise_sf12( outps_pre, settings )
    sf_post = summarise_sf12( outps_post, settings )
    =#
end