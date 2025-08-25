#=

Include file for `Runner.jl` initialising what's needed for the new costs model to work. 
This is intended to be inserted into the `Runner` module. Doing it this way fixes some
nasty cross-dependences. 

!!! This code is not used in the live SLAB version, or included anymore in `Runner.jl`:

 - nasty cross-dependency (needs a run to start a run with the initialised data);
 - very slow, even with threading (num_people x 1 set per sample weight - so ≈ 5.5m always);
 - existing code works reasonably well once a bug was fixed.

But keep around as it's nice code by my standards and could be useful someday.
Also .. sunk costs.

=#

"""

"""
function la_initialise( 
    settings :: Settings, 
    sys :: TaxBenefitSystem,
    observer :: Observable ;
    reset_data = false, 
    system_type = sys_civil)::Tuple
    LegalAidData.init( settings )
    hh, people = get_raw_data!( settings; reset=reset_data )
    probdata = rename( s->"prob_"*s, LegalAidData.LA_PROB_DATA)
    mpeople = leftjoin( people, probdata, on=[
        :data_year=>:prob_data_year,
        :hid=>:prob_hid,
        :pno=>:prob_pno] )
    rename!( hh, [
        :data_year=>:hh_data_year, 
        :hid=>:hh_hid,
        :uhid=>:hh_uhid,
        :onerand=>:hh_onerand])
    mpeople = rightjoin( mpeople, hh, on=[
        :data_year=>:hh_data_year,
        :hid=>:hh_hid] ) # just to get weights
    results = Runner.do_one_run( settings, [sys], observer )
    # outf = summarise_frames!( results, settings )
    modelled_results = if system_type == sys_civil
        rename( s->"modelled_"*s, results.legalaid.civil.data[1])
    else 
        rename( s->"modelled_"*s, results.legalaid.aa.data[1])
    end
    mrpeople = leftjoin( mpeople, modelled_results, on=[:pid=>:modelled_pid] ) # add baseline results
    @show names( mrpeople )
    # @show mrpeople.modelled_entitlement
    mrpeople.modelled_la_status_agg = agg_la_status.( mrpeople.modelled_entitlement )
    eligible_people = mrpeople[ mrpeople.modelled_entitlement .!== la_none, :]
    needs, cases_per_need = LegalAidData.get_needs_and_cases( eligible_people, system_type )
    mpeople.rand15k .= rand.(15_000)
    needs, cases_per_need, mpeople
end

function la_make_default_settings(def_settings :: Settings)::Tuple
    settings = deepcopy( def_settings )
    # settings.included_data_years = [2019,2021,2022]
    # emulate, as far as we can, the system in place in 2024, 
    # when the SLAB data was created.
    settings.to_y = 2024
    settings.to_q = 1
    settings.means_tested_routing = modelled_phase_in
    # settings.num_households, settings.num_people, nhh2 = 
    #    FRSHouseholdGetter.initialise( settings; reset=true )
    settings.do_legal_aid = true
    sys = STBParameters.get_default_system_for_fin_year( 2024 )
    settings, sys 
end

"""

"""
function la_initialise( def_settings::Settings, observer :: Observable )
    if ! isnothing( LegalAidData.CIVIL_CASES_PER_NEED ) # not already initialised
        return 
    end
    settings, sys = la_make_default_settings( def_settings )
    LegalAidData.CIVIL_NEEDS,
    LegalAidData.CIVIL_CASES_PER_NEED,
    LegalAidData.CIVIL_PEOPLE = 
        la_initialise( settings, sys, observer, reset_data=false, system_type=sys_civil )
    LegalAidData.AA_NEEDS,
    LegalAidData.AA_CASES_PER_NEED,
    LegalAidData.AA_PEOPLE = 
        la_initialise( settings, sys, observer, reset_data=false, system_type=sys_aa )
end