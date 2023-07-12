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

tot = 0
defsettings = get_all_uk_settings_2023()
    
# observer = Observer(Progress("",0,0,0))
obs = Observable( Progress(defsettings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)

    tot += p.step
    println(tot)
end

function make_default_settings() :: Settings
    # settings = Settings()
    settings = get_all_uk_settings_2023()
    settings.do_marginal_rates = false
    settings.requested_threads = 4
    settings.means_tested_routing = uc_full
    settings.do_health_esimates = true
    return settings
  end

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

function do_basic_uk_run()
    settings = make_default_settings()
    settings.run_name="all-uk-run-$(date_string())"
    sys = [get_system(year=2023, scotland=false), get_system(year=2023, scotland=true)]
    println( sys[1].ni)
    tot = 0
    # force reset of data to use UK dataset
    settings.num_households, settings.num_people, nhh2 = 
        FRSHouseholdGetter.initialise( settings; reset=true )
    results = do_one_run( settings, sys, obs )
    h1 = results.hh[1]
    settings.poverty_line = make_poverty_line( results.hh[1], settings )
    dump_frames( settings, results )
    println( "poverty line = $(settings.poverty_line)")
    summary = summarise_frames!( results, settings )   
    return (summary, results, settings )
end

@testset "UK Basic Run" begin
    summary, results, settings = do_basic_uk_run()
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
end