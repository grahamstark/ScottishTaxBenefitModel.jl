module LegalAidRunner
#
# stand alone threaded runner that just does legal aid
#
using Base.Threads
using ChunkSplitters
using Observables

using ScottishTaxBenefitModel
using .Definitions
using .Intermediate: 
    MTIntermediate, 
    apply_2_child_policy,
    make_intermediate 
using .LegalAidCalculations: calc_legal_aid!
using .LegalAidData
using .LegalAidOutput
using RunSettings:Settings
using .Results: 
    HouseholdResult,
    OneLegalAidResult   
using .Monitor: Progress
using FRSHouseholdGetter: get_household

# speed wrapper trick
struct ResultsWrapper 
    results :: Array{HouseholdResult}
end

const RESULTS = 
    ResultsWrapper( Array{HouseholdResult}(undef,0,0))

function intialise( 
    settings :: Settings,
    systems  :: Vector{TaxBenefitSystem{T}},
    observer :: Observable  )
    RESULTS.results = do_one_run( settings, systems, observer )
end

function do_one_run( 
    settings :: Settings, 
    systems  :: Vector{TaxBenefitSystem{T}},
    observer :: Observable;
    reset = false ) :: AllLegalOutput where T

    if(size( RESULTS.results )[1] == 0) || reset
        intialise( settings, systems, observer )
    end

    num_systems = length( systems )
    num_threads = min( nthreads(), settings.requested_threads )
    println( "num_threads $num_threads")
    chunks = ChunkSplitters.chunks(1:settings.num_households, num_threads, :batch )
    settings.do_legal_aid = true
    lout = 
        LegalAidOutput.AllLegalOutput(
            T; 
            num_systems=num_systems, 
            num_people=settings.num_people )
    @time @threads for thread in 1:num_threads
        for hno in chunks[thread][1]
            if hno % 500 == 0
                observer[] =Progress( settings.uuid, "run",thread, hno, 100, settings.num_households )
            end
            res = RESULTS.results.full_results[:,hno]
            hh = get_household( hno )
            intermed = make_intermediate( 
                hh, 
                systems[1].hours_limits, 
                systems[1].age_limits, 
                systems[1].child_limits )            
            if settings.do_legal_aid
                for sysno in 1:num_systems 
                    calc_legal_aid!( res[sysno], hh, intermed, systems[sysno].legalaid.civil )
                    calc_legal_aid!( res[sysno], hh, intermed, systems[sysno].legalaid.aa )
                    LegalAidOutput.add_to_frames!( lout, settings, hh, res[sysno], sysno, )
                end
            end
        end # hhlds in each chunk 
    end # threads
    LegalAidOutput.summarise_la_output!( lout )
    # LegalAidOutput.dump_tables( lout, settings, num_systems )
    return lout
end 

end