using Test
using CSV
using DataFrames
using StatsBase
using BenchmarkTools

using ScottishTaxBenefitModel
using ScottishTaxBenefitModel.GeneralTaxComponents
using ScottishTaxBenefitModel.STBParameters
using ScottishTaxBenefitModel.Runner: do_one_run!, RunSettings

using .Utils

include("testutils.jl")

settings = RunSettings()

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 120
BenchmarkTools.DEFAULT_PARAMETERS.samples = 2

sys = [get_system(), get_system( true )]

function basic_run( )

    global print_test

    results = do_one_run!( settings, sys )

    #
    #  = summarise_results!( results=results, base_results=base_results )
    #
    # if print_test
    #     print( "   deciles = $( summary_output.deciles)\n\n" )
    #
    #     print( "   poverty_line = $(summary_output.poverty_line)\n\n" )
    #
    #     print( "   inequality = $(summary_output.inequality)\n\n" )
    #
    #     print( "   poverty = $(summary_output.poverty)\n\n" )
    #
    #     print( "   gainlose_by_sex = $(summary_output.gainlose_by_sex)\n\n" )
    #     print( "   gainlose_by_thing = $(summary_output.gainlose_by_thing)\n\n" )
    #
    #     print( "   metr_histogram= $(summary_output.metr_histogram)\n\n")
    #     println( "SUMMARY OUTPUT")
    #     println( summary_output )
    #     println( "as JSON")
    #     println( JSON.json( summary_output ))
    # end

end # summary_output.timing summary_output.blockt = JSON.json( summary_output )

# example_names, total_num_households, total_num_people = load_data( load_examples = true, load_main = true, start_year = 2015 )
#
# params = deepcopy(ScottishTaxBenefitModel.MiniTB.DEFAULT_PARAMS)
#
# base_results = create_base_results( total_num_households, total_num_people )

@testset "basic run timing" begin
    t = @benchmark basic_run()

    print(t)
end
