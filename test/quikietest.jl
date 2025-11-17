   #=
 Ist Spreadsheet Examples from calculator 
 docs/legalaid/testcalcs.ods
=#

using Test
using Dates
using Format
using PrettyTables 
using Base.Threads
using ChunkSplitters
using ArgCheck

using DataFrames, CSV

using ScottishTaxBenefitModel

using .Utils: pretty

using .ModelHousehold: 
    Household, 
    Person, 
    People_Dict,     
    default_bu_allocation, 
    get_benefit_units, 
    get_head, 
    get_spouse, 
    has_disabled_member,
    household_composition_1,
    is_single,
    num_people,
    num_children,
    num_std_bus,

    pers_is_carer,
    pers_is_disabled, 
    search,
    to_string

using .RunSettings: Settings 

using .STBParameters

using .IncomeTaxCalculations: 
    calc_income_tax!

using .Definitions
 
using .Intermediate: 
    MTIntermediate, 
    apply_2_child_policy,
    make_intermediate 

using .Results: 
    get_indiv_result,
    init_household_result, 
    init_benefit_unit_result, 
    to_string,
    BenefitUnitResult,
    HouseholdResult,
    OneLegalAidResult

using .Utils: 
    eq_nearest_p,
    to_md_table,
    make_crosstab,
    matrix_to_frame,
    basiccensor

using .ExampleHelpers

using .STBIncomes


using .LegalAidCalculations: calc_legal_aid!
using .LegalAidData
using .LegalAidOutput
# using .LegalAidRunner

using .SingleHouseholdCalculations: do_one_calc

using .STBOutput: LA_TARGETS

using .HTMLLibs

import .Runner

# not really a test - something to cut&paste

include( "testutils.jl")

xprint = PrintControls()


function lasettings( reset :: Bool )
    settings = Settings()
    settings.run_name = "Local Legal Aid Runner Test - base case"
    settings.export_full_results = true
    settings.do_legal_aid = true
    settings.requested_threads = 4
    settings.wealth_method = matching
    settings.do_dodgy_takeup_corrections = false
    settings.num_households, settings.num_people, nhh2 = 
        FRSHouseholdGetter.initialise( settings; reset=reset )
    return settings
end
   
function do_quickierun(; topextra = 10_000.0, ila=6_000.0, reset=false )
    global tot
    tot = 0
    @time begin
        sys1 = get_system( year=2023, scotland=true )
        settings = lasettings( reset )
        settings.run_name = "top rate bug chaser"
        sys2 = deepcopy(sys1)
        sys3 = deepcopy(sys1)
        sys2.legalaid.civil.income_contribution_limits[end] += topextra/WEEKS_PER_YEAR
        sys3.legalaid.civil.income_living_allowance = ila/WEEKS_PER_YEAR 
        systems = [sys1, sys2, sys3]
        results = Runner.do_one_run( settings, systems, obs )
        outf = summarise_frames!( results, settings )
        LegalAidOutput.dump_tables( outf.legalaid, settings; num_systems=2 )
        #
        fbase = basiccensor(settings.run_name)
        #
        fname = joinpath( settings.output_dir, fbase*"-civil_propensities.tab" )
        CSV.write( fname, LegalAidOutput.PROPENSITIES.civil_propensities ;  delim='\t' )
        #
        fname = joinpath( settings.output_dir, fbase*"-civil_costs.tab" )
        CSV.write( fname, LegalAidData.CIVIL_COSTS;  delim='\t' )
        #
        for sysno in 1:length(systems)
            fname = joinpath( settings.output_dir, fbase*"-civil_data-$(sysno).tab" )
            println( "writing to |$fname|")
            CSV.write( fname,  outf.legalaid.civil.data[sysno];  delim='\t' )
        end
        laout = outf.legalaid.civil
        diffdata = innerjoin( laout.data[1], laout.data[2], on=[:hid,:pid]; makeunique=true )
        diffdata = innerjoin( diffdata, laout.data[3], on=[:hid,:pid]; makeunique=true )
        diffdata.dq_base_2 = (diffdata.disqualified_on_income - diffdata.disqualified_on_income_1) .!= 0
        diffdata.dq_base_3 = (diffdata.disqualified_on_income - diffdata.disqualified_on_income_2) .!= 0
        
        gh = groupby( CIVIL_COSTS, :hsm_censored )
        actualpay = combine(gh, :totalpaid=>sum, :totalpaid=>length)
        laout, diffdata, actualpay
    end
end
