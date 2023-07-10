using Test
using CSV
using ArgCheck
using DataFrames
using StatsBase
using BenchmarkTools
using PrettyTables
using Observables
using ScottishTaxBenefitModel
using ScottishTaxBenefitModel.GeneralTaxComponents
using ScottishTaxBenefitModel.STBParameters
using ScottishTaxBenefitModel.Runner: do_one_run
using ScottishTaxBenefitModel.RunSettings
using .Utils
using .Monitor: Progress
using .ExampleHelpers
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames!, make_gain_lose



BenchmarkTools.DEFAULT_PARAMETERS.seconds = 120
BenchmarkTools.DEFAULT_PARAMETERS.samples = 2

tot = 0
settings = get_all_uk_settings_2023()
    
# observer = Observer(Progress("",0,0,0))
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)

    tot += p.step
    println(tot)
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

function do_basic_uk_run( ; print_test :: Bool )
    settings = get_all_uk_settings_2023()
    settings.run_name="all-uk-run-$(date_string())"
    sys = [get_uk_system(), get_uk_system()]
    println( sys[1].ni)
    tot = 0
    results = do_one_run( settings, sys, obs )
    h1 = results.hh[1]
    # pretty_table( h1[:,[:weighted_people,:bhc_net_income,:eq_bhc_net_income,:ahc_net_income,:eq_ahc_net_income]] )
    settings.poverty_line = make_poverty_line( results.hh[1], settings )
    dump_frames( settings, results )
    println( "poverty line = $(settings.poverty_line)")
    summarise_frames!( results, settings )
    
end

@testset "UK Basic Run" begin
    outf = do_basic_uk_run( print_test=true )
    #=
    k = 1
    println(outf.income_summary[1][1:5,targets[1:5]] )
    println(outf.income_summary[1][1:5,targets[6:10]] )
    println(outf.income_summary[1][1:5,targets[11:15]] )
    println(outf.income_summary[1][1:5,targets[16:20]] )
    println(outf.income_summary[1][1:5,targets[21:25]] )
    println(outf.income_summary[1][1:5,targets[26:30]] )
    println(outf.income_summary[1][1:5,targets[31:35]] )
    println(outf.income_summary[1][1:5,targets[36:40]] )
    println(outf.income_summary[1][1:5,targets[41:end]] )
    println(names( outf.income_summary[1] ))
    =#
    CSV.write( "/home/graham_s/tmp/income_summary_uk.csv", outf.income_summary[1])
end