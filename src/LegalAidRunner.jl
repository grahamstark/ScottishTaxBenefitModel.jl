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
    civil_propensities :: DataFrame
    aa_propensities :: DataFrame
end

RESULTS = 
    ResultsWrapper( 
        Matrix{HouseholdResult}(undef,0,0),
        DataFrame(),
        DataFrame())

function intialise( 
    settings :: Settings,
    systems  :: Vector{TaxBenefitSystem{T}},
    observer :: Observable  ) where T
    settings.export_full_results = true
    settings.do_legal_aid = false    
    rs = Runner.do_one_run( settings, systems, observer )

    RESULTS.results = rs.full_results

    # create takeup propensities
    settings.do_legal_aid = true
    laresults = do_one_run( settings, systems, observer )
    RESULTS.civil_propensities = create_wide_propensities( laresults.civil.data[1], LegalAidData.CIVIL_COSTS )
    RESULTS.aa_propensities = create_wide_propensities( laresults.aa.data[1], LegalAidData.AA_COSTS )
    
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
                hh, 
                systems[1].hours_limits, 
                systems[1].age_limits, 
                systems[1].child_limits )    
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
                LegalAidOutput.add_to_frames!( 
                    lout, 
                    settings, 
                    hh, 
                    res[sysno], 
                    sysno )
            end
        end # hhlds in each chunk 
    end # threads
    LegalAidOutput.summarise_la_output!( 
        lout,
        RESULTS.civil_propensities,
        RESULTS.aa_propensities )
    return lout
end 

"""
This is the base of the costs model
entitlement = out.civil.data[1]  or out.aa

"""
function create_base_propensities( 
    entitlement :: DataFrame,
    costs :: DataFrame ) :: NamedTuple

    function rn( s :: AbstractString ) :: String
        matches = match(r"(.*)_1",s)
        if ! isnothing(matches)
           return matches[1]*"_prop"
        end
        if s in ["hsm", "age2", "sex", "popn", "case_freq", "la_status" ]        
            return s
        end
        return s*"_cost"
     end

    subjects = levels( costs.hsm )    
    entitlement.la_status = entitlement.entitlement # match names in the actual output
    # so this is the calculated entitlements, individual level, grouped by entitlement, age & sex
    entitlement_grp = groupby(entitlement, [:la_status, :age2, :sex])
    # and these are the SLAB costs, grouped by same and also by problem type (hsm = Higher Subject)
    costs_grp4 = groupby( costs, [:hsm, :la_status, :age2, :sex])
    # .. and without the subject to get a quick and dirty way to get total costs
    costs_grp3 = groupby( costs, [:la_status, :age2, :sex])
    # make a dataframe class by types of claim, la entitlement, age & sex
    n = size( entitlement_grp )[1]*(1+length(subjects)) 
    out = DataFrame( 
        hsm = fill("",n ), 
        age2 = fill("",n), 
        sex = fill(Male,n),
        case_freq = zeros(n), 
        popn = zeros(n),        
        la_status = fill( la_none, n ),
        costs_max = zeros(n), 
        costs_mean = zeros(n), 
        costs_median = zeros(n), 
        costs_min = zeros(n), 
        costs_nmiss = zeros(n), 
        costs_nobs = zeros(n), 
        costs_q25 = zeros(n), 
        costs_q75 = zeros(n))
    i = 0
    
    for (k,v) in pairs( entitlement_grp )
        for hsm in subjects
            i += 1
            lout = out[i,:]
            lout.popn = sum( v.weight )
            lout.sex = k.sex
            lout.age2 = k.age2
            lout.hsm = hsm
            lout.la_status = k.la_status
            # now, look up corresponding costs data: first make a key to disagg grouped dataframe
            costk = make_key( 
                la_status = k.la_status, 
                hsm = hsm,
                age = k.age2,
                sex = k.sex )
            @show costk
            # then look up & fill if there are records for the costs for that combo 
            # FIXME won't work properly for "Adults with incapacity" since there isn't a status for this in the costs
            if haskey( costs_grp4, costk ) 
                cv = costs_grp4[costk] 
                r = summarystats( cv.totalpaid )
                lout.costs_max = r.max     
                lout.costs_mean = r.mean
                lout.costs_median = r.median  
                lout.costs_min = r.min
                lout.costs_nmiss = r.nmiss   
                lout.costs_nobs = r.nobs
                lout.costs_q25 = r.q25     
                lout.costs_q75 = r.q75
                lout.case_freq = r.nobs / lout.popn 
            end
        end # each subject
        # total 
        i += 1
        lout = out[i,:]
        lout.popn = sum( v.weight )
        lout.sex = k.sex
        lout.age2 = k.age2
        lout.hsm = "aa_total"
        lout.la_status = k.la_status
        # now, look up corresponding costs data: first make a key to disagg grouped dataframe
        costk = make_key( 
            la_status = k.la_status, 
            age = k.age2,
            sex = k.sex )
        @show costk
        # then look up & fill if there are records for the costs for that combo 
        # FIXME won't work properly for "Adults with incapacity" since there isn't a status for this in the costs
        if haskey( costs_grp3, costk ) 
            cv = costs_grp3[costk] 
            r = summarystats( cv.totalpaid )
            lout.costs_max = r.max     
            lout.costs_mean = r.mean
            lout.costs_median = r.median  
            lout.costs_min = r.min
            lout.costs_nmiss = r.nmiss   
            lout.costs_nobs = r.nobs
            lout.costs_q25 = r.q25     
            lout.costs_q75 = r.q75
            lout.case_freq = r.nobs / lout.popn 
        end
    end
    sort!( out, [:hsm,:la_status,:sex, :age2])
    av_costs_by_type = unstack(out[!,[:hsm,:sex,:age2,:popn,:la_status,:costs_mean]],:hsm,:costs_mean)
    rename!( av_costs_by_type, Utils.basiccensor.(names(av_costs_by_type)))
    cases_by_type = unstack(out[!,[:hsm,:sex,:age2,:la_status,:popn,:case_freq]],:hsm,:case_freq)
    rename!( cases_by_type, Utils.basiccensor.(names(cases_by_type)))
    cost_and_count = hcat( av_costs_by_type, cases_by_type, makeunique=true )
    rename!( rn, cost_and_count )
    return (; cost_and_count, long_data=out )
end

function create_wide_propensities(
    entitlement :: DataFrame,
    costs :: DataFrame ) :: DataFrame
    return create_base_propensities( 
        entitlement, costs ).cost_and_count
end

end # module