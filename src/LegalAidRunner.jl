module LegalAidRunner
#
# stand alone threaded runner that just does legal aid
#
using Base.Threads 

using ChunkSplitters
using DataFrames
using Observables
using StatsBase
using CategoricalArrays

using ScottishTaxBenefitModel
using .Definitions
using .Intermediate: 
    MTIntermediate, 
    apply_2_child_policy,
    make_intermediate 
using .RunSettings:Settings
using .Results: 
    HouseholdResult,
    OneLegalAidResult   
using .Monitor: Progress
using .FRSHouseholdGetter: get_household
using .STBParameters: TaxBenefitSystem

using .LegalAidCalculations: calc_legal_aid!
using .LegalAidData
using .LegalAidOutput
using .Runner
using .Utils

# speed wrapper trick
mutable struct ResultsWrapper 
    results :: Matrix{HouseholdResult}
end

RESULTS = 
    ResultsWrapper( 
        Matrix{HouseholdResult}(undef,0,0))

function initialise( 
    settings :: Settings,
    systems  :: Vector{TaxBenefitSystem{T}},
    observer :: Observable  ) :: AllLegalOutput where T
    settings.export_full_results = true
    settings.do_legal_aid = false    
    rs = Runner.do_one_run( settings, systems, observer )

    RESULTS.results = rs.full_results

    # create takeup propensities
    settings.do_legal_aid = true
    laresults = do_one_run( settings, systems, observer )
    println( "initialise; at create wide propensities ")
    return laresults
end


"""
Hacked version for examples.
returns an array of full results, and the household
"""
#=
function calculate_one( 
    hpos :: OneIndex, 
    systems  :: Vector{TaxBenefitSystem{T}} )::Tuple where T
    res = RESULTS.results[:,hno]
    hh = get_household( hpos.id, hpos.data_year )
    intermed = make_intermediate( 
        hh, 
        systems[1].hours_limits, 
        systems[1].age_limits, 
        systems[1].child_limits )   
    num_systems = length( systems )
    for sysno in 1:num_systems 
        calc_legal_aid!( 
            res[sysno], 
            hh, 
            intermed, 
            systems[sysno].legalaid.civil )
        calc_legal_aid!( 
            res[sysno], 
            hh, 
            intermed, 
            systems[sysno].legalaid.aa )
    end
    return hh,res
end
=#

function do_one_run( 
    settings :: Settings, 
    systems  :: Vector{TaxBenefitSystem{T}},
    observer :: Observable;
    reset_data = false,
    reset_results = false ) :: AllLegalOutput where T

    if(FRSHouseholdGetter.get_num_households() == 0) || reset_data
        settings.num_households, settings.num_people = FRSHouseholdGetter.initialise( settings )
    end
    # FIXME potential for endless loop here?
    if( size( RESULTS.results )[1] <= 1) || reset_results
        println( "entering initialise")
        initialise( settings, systems, observer )
    end
    num_systems = length( systems )
    num_threads = min( nthreads(), settings.requested_threads )
    println( "num_threads $num_threads")
    println( "num_households $(settings.num_households)")
    chunks = ChunkSplitters.chunks(
        1:settings.num_households, 
        num_threads, 
        :batch )
    lout = 
        LegalAidOutput.AllLegalOutput(
            T; 
            num_systems=num_systems, 
            num_people=settings.num_people )
    @threads for thread in 1:num_threads
        for hno in chunks[thread][1]
            if hno % 500 == 0
                observer[] =Progress( 
                    settings.uuid, 
                    "run",
                    thread, 
                    hno, 
                    100, 
                    settings.num_households )
            end
            res = RESULTS.results[:,hno]
            hh = get_household( hno )
            intermed = make_intermediate( 
                DEFAULT_NUM_TYPE,
                settings,
                hh, 
                systems[1].hours_limits, 
                systems[1].age_limits, 
                systems[1].child_limits )    
            for sysno in 1:num_systems 
                calc_legal_aid!( 
                    res[sysno], 
                    hh, 
                    intermed, 
                    systems[sysno].legalaid.civil,
                    systems[sysno].nmt_bens,
                    systems[sysno].age_limits )
                calc_legal_aid!( 
                    res[sysno], 
                    hh, 
                    intermed, 
                    systems[sysno].legalaid.aa,
                    systems[sysno].nmt_bens,
                    systems[sysno].age_limits )
                LegalAidOutput.add_to_frames!( 
                    lout, 
                    settings, 
                    hh, 
                    res[sysno], 
                    sysno )
            end
        end # hhlds in each chunk 
    end # threads
    LegalAidOutput.create_propensities( lout; reset_results = reset_results )

    # @show RESULTS.civil_propensities
    LegalAidOutput.summarise_la_output!( lout )
    return lout
end 

end # module