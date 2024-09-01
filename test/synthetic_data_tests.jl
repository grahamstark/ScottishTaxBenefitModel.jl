using Test
using BenchmarkTools
using CSV
using ArgCheck
using DataFrames
using Format
using Observables
using PrettyTables
using StatsBase
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

settings = Settings()

# observer = Observer(Progress("",0,0,0))
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)

    tot += p.step
    println(tot)
end

fmt(x,i,j) = format(x, precision=0, commas=true)


#
# Formatting routines for PrettyTables
#
form( v :: Missing, r, c ) = ""
form( v :: AbstractString, r, c ) = pretty(v)
form( v :: Integer, r, c ) = "$v"
function form( v :: Number, r, c )
    if isnan(v)
       return "" 
    end
    prec = c == 4 ? 2 : 0
    Format.format(v; precision=prec, commas=true )
end



@testset "basic run timing" begin
    settings = Settings()
    settings.do_legal_aid = false
    settings.skiplist = ""
    # lower_multiple :: Real = 0.10 # these values can be narrowed somewhat, to around 0.25-4.7
    # upper_multiple :: Real = 10.0
    sys = [
        get_default_system_for_fin_year(2024; scotland=true), 
        get_default_system_for_fin_year( 2024; scotland=true )]
    summaries = []
    for source in [FRSSource, SyntheticSource]
        settings.data_source = source 
        settings.run_name="run-$(settings.data_source)-$(date_string())"
        tot = 0
        summary, results, settings = do_basic_run( settings, sys; reset = true )
        push!( summaries, summary )
    end
    nms = names(summaries[1].income_summary[1])[1:108]
    frsinc = Vector(summaries[1].income_summary[1][1,1:108])./1_000_000
    syninc = Vector(summaries[2].income_summary[1][1,1:108])./1_000_000
    diff = 100 .* ((syninc .- frsinc) ./ frsinc)
    
    incs = DataFrame( item=nms, frs=frsinc, synth=syninc, diff=diff )
    sort!(incs,[:frs],rev=true)
    io = open( "frs-vs-synth.html", "w")
    t = pretty_table( 
        io,
        incs[1:50,:]; 
        formatters=( form ), 
        header = ["", "FRS", "Synthetic", "Diff (%)"],
        alignment = [:l,:r,:r,:r],
        table_class="table table-sm table-striped table-responsive", 
        backend = Val(:html))
    close(io)
end