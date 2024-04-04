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

# speed wrapper trick
mutable struct ResultsWrapper 
    results :: Matrix{HouseholdResult}
end

RESULTS = 
    ResultsWrapper( Matrix{HouseholdResult}(undef,0,0))

function intialise( 
    settings :: Settings,
    systems  :: Vector{TaxBenefitSystem{T}},
    observer :: Observable  ) where T
    settings.export_full_results = true
    settings.do_legal_aid = false    
    rs = Runner.do_one_run( settings, systems, observer )
    RESULTS.results = rs.full_results
end

function do_one_run( 
    settings :: Settings, 
    systems  :: Vector{TaxBenefitSystem{T}},
    observer :: Observable;
    reset_data = false,
    reset_results = false ) :: AllLegalOutput where T

    if(FRSHouseholdGetter.get_num_households() == 0) || reset_data
        settings.num_households, settings.num_people = FRSHouseholdGetter.initialise( settings )
    end
    if( size( RESULTS.results )[1] <= 1) || reset_results
        intialise( settings, systems, observer )
    end
    num_systems = length( systems )
    num_threads = min( nthreads(), settings.requested_threads )
    println( "num_threads $num_threads")
    println( "num_households $(settings.num_households)")
    chunks = ChunkSplitters.chunks(1:settings.num_households, num_threads, :batch )
    lout = 
        LegalAidOutput.AllLegalOutput(
            T; 
            num_systems=num_systems, 
            num_people=settings.num_people )
    @threads for thread in 1:num_threads
        for hno in chunks[thread][1]
            if hno % 500 == 0
                observer[] =Progress( settings.uuid, "run",thread, hno, 100, settings.num_households )
            end
            res = RESULTS.results[:,hno]
            hh = get_household( hno )
            intermed = make_intermediate( 
                hh, 
                systems[1].hours_limits, 
                systems[1].age_limits, 
                systems[1].child_limits )            
            
            for sysno in 1:num_systems 
                calc_legal_aid!( res[sysno], hh, intermed, systems[sysno].legalaid.civil )
                calc_legal_aid!( res[sysno], hh, intermed, systems[sysno].legalaid.aa )
                LegalAidOutput.add_to_frames!( lout, settings, hh, res[sysno], sysno )
            end
        end # hhlds in each chunk 
    end # threads
    LegalAidOutput.summarise_la_output!( lout )
    return lout
end 

"""
This is the base of the costs model
"""
function create_base_propensities( 
    settings :: Settings, 
    systems  :: Vector{TaxBenefitSystem{T}},
    observer :: Observable ) :: DataFrame
    outp = do_one_run( settings, systems, observer, reset_data=true, reset_results=true )
    bp = out.breakdown_pers[1]
    rename!( pb, [:entitlement=>:la_status]) # match names in the actual output
    n = 100
    out = DataFrame( 
        hsm = fill("",n ), 
        age2 = fill("",n), 
        sex = fill(Male,n),
        case_freq = zeros(n), 
        popn = zeros(n),        
        la_status = fill( la_none, n ),
        cost_max = zeros(n), 
        cost_mean = zeros(n), 
        cost_median = zeros(n), 
        cost_min = zeros(n), 
        cost_nmiss = zeros(n), 
        cost_nobs = zeros(n), 
        cost_q25 = zeros(n), 
        cost_q75 = zeros(n))
    i = 0
    bp_grp_ns = groupby(bp, [:age2, :sex])
    bp_grp1 = bp
    bp_grp2 = groupby(bp, [:la_status])
    bp_grp3 = groupby(bp, [:la_status, :sex])
    bp_grp4 = groupby(bp, [:la_status, :age2, :sex])
end

end # module