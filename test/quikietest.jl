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
    matrix_to_frame

using .ExampleHelpers

using .STBIncomes

using .GeneralTaxComponents:
    WEEKS_PER_MONTH,
    WEEKS_PER_YEAR

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

sys1 = get_system( year=2023, scotland=true )
xprint = PrintControls()


function lasettings()
    settings = Settings()
    settings.run_name = "Local Legal Aid Runner Test - base case"
    settings.export_full_results = true
    settings.do_legal_aid = true
    settings.wealth_method = other_method_1
    settings.requested_threads = 4
    settings.num_households, settings.num_people, nhh2 = 
        FRSHouseholdGetter.initialise( settings; reset=true )
    return settings
end
   
tot = 0
settings = lasettings()

settings.run_name = "top rate bug chaser"
sys2 = deepcopy(sys1)
systems = [sys1, sys2]
sys2.legalaid.civil.income_contribution_limits[end] += 10_000/WEEKS_PER_YEAR
@time results = Runner.do_one_run( settings, systems, obs )
outf = summarise_frames!( results, settings )
LegalAidOutput.dump_tables( outf.legalaid, settings; num_systems=2 )