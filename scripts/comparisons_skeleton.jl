using Pkg
@usingany DrWatson
@usingany DataFrames
@usingany CSV
@usingany StatsBase
@usingany Observables


using ScottishTaxBenefitModel # put this in scope 

Pkg.activate( "ModelComparisons")
# local to ModelComparisons ... 
# using .ScottishTaxBenefitModel
using .DataSummariser
using .Definitions
using .HouseholdFromFrame
using .Monitor: Progress
using .Runner
using .RunSettings
using .STBIncomes
using .STBOutput
using .STBParameters
using .Utils


defsettings = Settings()
tot = 0
obs = Observable( Progress(defsettings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
    println(tot)
end

function make_short_cost_summary( summary::NamedTuple )::DataFrame 
    cost_summary1 = permutedims(summary.income_summary[1],122,makeunique=true)[1:109,1:3]
    cost_summary2 = permutedims(summary.income_summary[2],122,makeunique=true)[1:109,2:3]
    costsummary = hcat( cost_summary1, cost_summary2, makeunique=true )
    costsummary[!,1] = pretty.(costsummary[!,1])
    costsummary[!,2] ./= 1_000_000 # costs in £m
    costsummary[!,3] ./= 1_000 # counts in 000s
    costsummary[!,4] ./= 1_000_000
    costsummary[!,5] ./= 1_000 # counts in 000s
    costsummary[!,:change_cost] = costsummary[!,4] - costsummary[!,2]
    costsummary[!,:change_cases] = costsummary[!,5] - costsummary[!,3]
    costsummary
end

function get_raw_data( settings :: Settings )::Tuple
    dataset_artifact = get_data_artifact( Settings() )
    settings.num_households, settings.num_people, nhh2 = 
       FRSHouseholdGetter.initialise( settings; reset=false )
    hhs = HouseholdFromFrame.read_hh( 
        joinpath( dataset_artifact, "households.tab")) # CSV.File( ds.hhlds ) |> DataFrame     
    people = HouseholdFromFrame.read_pers( 
        joinpath( dataset_artifact, "people.tab"))
    @show settings.num_households
    people = people[ people.data_year .∈ ( settings.included_data_years, ) , :]
    hhs = hhs[ hhs.data_year .∈ ( settings.included_data_years, ) , :]

    overwrite_raw!( hhs, people, settings.num_households )
    return hhs, people
end

function do_basic_run( 
    settings :: Settings, 
    sys :: Vector; 
    reset :: Bool ) :: Tuple
   global tot
   tot = 0
   # force reset of data to use UK dataset
   settings.num_households, settings.num_people, nhh2 = 
       FRSHouseholdGetter.initialise( settings; reset=reset )
   results = do_one_run( settings, sys, obs )
   h1 = results.hh[1]
   # settings.poverty_line = make_poverty_line( results.hh[1], settings )
   # dump_frames( settings, results )
   println( "poverty line = $(settings.poverty_line)")
   summary = summarise_frames!( results, settings )
   return (summary, results, settings )
end

function do_run( itrates::Vector, itthresholds::Vector; sysyear = 2024 )::Tuple
    settings = Settings()
    sys1 = STBParameters.get_default_system_for_fin_year( sysyear )
    sys2 = STBParameters.get_default_system_for_fin_year( sysyear )
    sys2.it.non_savings_rates = itrates
    sys2.it.non_savings_thresholds = itthresholds
    sys2.it.non_savings_basic_rate = min( 
        length( sys2.it.non_savings_rates), 
        sys2.it.non_savings_basic_rate)
    return do_basic_run( settings, [sys1,sys2]; reset=false )
end


cd( "ModelComparisons")
pwd()
projectname()
datadir()






