module NonMeansTestedBenefits
#
# This module provides routines for benefits which are (mostly) not means-tested benefits,
# both current and historic. See [HistoricBenefits.jl] for the imputation routines used here.
#
using Base: has_tight_type
using Dates
using Dates: Date, now, TimeType, Year
using DataFrames
using ScottishTaxBenefitModel

using .Definitions
using .STBIncomes

using .Utils: nearest

using .ModelHousehold: 
    BenefitUnit,        
    Household, 
    Person, 
    get_benefit_units,
    has_income,
    num_children

using .BenefitGenerosity: change_status

using .Intermediate:
    has_limited_capactity_for_work_activity,
    has_limited_capactity_for_work,
    make_recipient
    
using .STBParameters: 
    AgeLimits, 
    AttendanceAllowance, 
    BereavementSupport, 
    CarersAllowance, 
    ChildBenefit, 
    ContributoryESA,
    DisabilityLivingAllowance, 
    HoursLimits,
    JobSeekersAllowance, 
    MaternityAllowance,
    NonMeansTestedSys, 
    PersonalIndependencePayment, 
    RetirementPension, 
    ScottishChildDisabilityPayment,
    WidowsPensions, 
    reached_state_pension_age
    
using .Results: 
    BenefitUnitResult, 
    HouseholdResult, 
    IndividualResult, 
    LMTIncomes

using .RunSettings: Settings

export 
    calc_child_benefit!, 
    calc_dla, 
    calc_pip,
    calc_post_tax_non_means_tested!,
    calc_pre_tax_non_means_tested!, 
    calc_state_pension, 
    calc_widows_benefits
    
"""
Child Benefit - this has to be done *after* income tax, so we have
income tax `total_income` for each adult in the `BenefitUnitResult` struct.
"""
function calc_child_benefit!( 
    bures :: BenefitUnitResult,
    bu    :: BenefitUnit, 
    cb    :: ChildBenefit{T} ) :: T where T
    c = zero(T)
    #= FIXME something to check the exact type of children - 
    for now, assume the BU allocation has got this right.
    for pid in bu.children
        #
    end
    =#
    if cb.abolished 
        return c
    end
    nc = num_children(bu)
    if nc == 0
        return 0.0
    end
    c += cb.first_child
    if nc > 1
        c += (nc-1)*cb.other_children
    end
    recipient = make_recipient( bu, CHILD_BENEFIT )
    # guardian's allowance
    bures.pers[recipient].income[GUARDIANS_ALLOWANCE] = 0.0

    # println( bu.people[bu.head].relationships)
                
    if c > 0 # fixme not quite right - qualify for CB for each child
        for cp in bu.children
            # this checks if anyone in the BU has a parent-like
            # relationship to the child
            is_guardian = true
            for pid in bu.adults
                if ! (bu.people[pid].relationships[cp] in [Grand_parent, Other_relative, Other_non_relative])
                    is_guardian = false
                    break;
                end
            end
            if is_guardian 
                # FIXME we could also guess approx number of kids 
                # qualifying for GA from receipt in HistoricBenefits || has_income( bu, guardians_allowance )
                bures.pers[recipient].income[GUARDIANS_ALLOWANCE] += 
                    cb.guardians_allowance
            end
        end
    end # guardian's allowance
    # cb but not guardians withdrawn with high incomes
    # high income thing - highest of the BU's *individual* income; see cpag ch.27
    max_inc = zero(T)
    for pid in bu.adults
        max_inc = max( max_inc, bures.pers[pid].it.total_income )
        if bu.people[pid].sex == Female
            recipient = pid
        end
    end
    excess_income = max_inc - cb.high_income_thresh
    if excess_income > 0
        withdrawal_rate = excess_income * cb.withdrawal # use '*' rather than integer division here to
        # get a consident marginal rate.
        withdrawn = c*withdrawal_rate
        # this should really be done in steps £1 for every £200, but since
        # everything is weekly here we'll just multiply
        #= 
        
        Specifically, affected taxpayers will pay back one per cent of their family’s 
        Child Benefit for every £100 by which taxable income exceeds £50,000. 
        One per cent of Child Benefit is £10.56 per year for a 1-child family, and an 
        additional £6.97 per child for larger families. 
        
        Hence the marginal tax rate between £50,000 and £60,000 is increased by about 11 
        percentage points for the first child and by an additional 7 percentage points 
        for each subsequent one. So, for example, while about 320,000 people will find 
        that their marginal income tax rate increases to more than 50%, about 40,000 of them - 
        those with three or more children - will find that it jumps to at least 65%. 
        
        =#
        # withdrawn = c*cb.withdrawal*excess_income
        c = max(0.0, c-withdrawn)
    end
    bures.pers[recipient].income[CHILD_BENEFIT] = c       
end

function calc_widows_benefits(
    pers :: Person{T}, 
    has_kids :: Bool, 
    bp :: BereavementSupport{T},
    wp :: WidowsPensions{T}) :: T where T
    wid = zero(T)
    if wp.abolished || bp.abolished
        return wid
    end
    #
    # We don't know when someone was widowed
    # so we rely on this. FIXME Obviously this gets progressively worse as time goes on and
    # we keep using the old years of FRS.
    #
    # new-style: payable for 18 months at a flat rate
    # CHECK 2829 2017 why is that bereavment_support?
    if pers.bereavement_type in [bereavement_allowance,bereavement_support]
        # payable for 18 months so we'll allocate
        # 2/3rds of the weekly value of the lump-sum
        if has_kids
            wid = bp.higher + bp.lump_sum_higher*2/3
        else
            wid = bp.lower + bp.lump_sum_lower*2/3
        end
    elseif pers.bereavement_type == widowed_parents # At least 3 years ago so no 
        # need to worry about lump-sums; just scale
        # the standard rate by the ratio of
        # their receipt to the standard rate at the time
        # of interview. CHECK hhld 477 2015 for an example
        # of someone with the lump sum but no standard benefit
        # so no ratio; for us, just assign the standard 
        # rate in those cases.
        #
        # println( "pers.benefit_ratios $(pers.benefit_ratios)")
        if haskey( pers.benefit_ratios, bereavement_allowance_or_widowed_parents_allowance_or_bereavement )
            wid = pers.benefit_ratios[bereavement_allowance_or_widowed_parents_allowance_or_bereavement]*
                wp.standard_rate 
        else
            wid = wp.standard_rate
        end
    else
        # check we're not missing anyone
        @assert ! haskey( pers.benefit_ratios, bereavement_allowance_or_widowed_parents_allowance_or_bereavement) "pid $(pers.pid) bereavement_type=$(pers.bereavement_type) not recognised ratios=$(pers.benefit_ratios)"
    end
    return wid
end

function dla_greater_of( dlat :: LowMiddleHigh, pipt :: PIPType )::LowMiddleHigh
    return if dlat !==  missing_lmh
        dlat
    else 
        if pipt == enhanced_pip 
            high
        elseif pipt == standard_pip
            rand([mid,low])
        else
            missing_lmh
        end
    end
end

function pip_greater_of( pipt :: PIPType, dlat :: LowMiddleHigh)::PIPType
    return if pipt !== no_pip
        pipt
    else 
        if dlat == low
            standard_pip
        elseif dlat in [mid,high]
            enhanced_pip
        else
            no_pip
        end
    end
end

"""
PIP and DLA (below) rely on all the types being sorted out earlier
either in some kind of probit or by being inferred from receipts (see [HistoricBenefits.jl] for
what we have so far).
"""
function calc_pip( 
    pers :: Person{T},
    pip  :: PersonalIndependencePayment{T}) :: Tuple{T,T} where T
    pl = zero(T)
    pm = zero(T)
    daily_type = pip_greater_of( pers.pip_daily_living_type, pers.dla_self_care_type )
    mob_type = pip_greater_of( pers.pip_mobility_type, pers.dla_mobility_type )
    # println( "calc_pip initial: daily_type=$daily_type mob_type = $mob_type")
    if pip.abolished
        return (pl, pm )
    end
    daily_type = change_status( 
        candidates=pip.dl_candidates, 
        pid=pers.pid, 
        change=pip.extra_people,
        choices=[standard_pip,enhanced_pip],
        current_value=daily_type, 
        disqual_value=no_pip )
    mob_type = change_status( 
        candidates=pip.mobility_candidates, 
        pid=pers.pid, 
        choices=[standard_pip,enhanced_pip],
        change=pip.extra_people,
        current_value=mob_type, 
        disqual_value=no_pip )
    # println( "calc_pip after change_staus: daily_type=$daily_type mob_type = $mob_type")
        
    # fixme consistent names dl->daily living etc.
    if daily_type == standard_pip
        pl = pip.dl_standard    
    elseif daily_type == enhanced_pip
        pl = pip.dl_enhanced    
    end
    if mob_type == standard_pip
        pm = pip.mobility_standard    
    elseif mob_type == enhanced_pip
        pm = pip.mobility_enhanced             
    end
    return (pl, pm )
end # pip calc

function calc_attendance_allowance(
    pers :: Person{T},
    aa  :: AttendanceAllowance{T},
        ) :: T where T
    a =zero(T)
    if aa.abolished
        return a
    end
    at = pers.attendance_allowance_type
    at = change_status( 
        candidates=aa.candidates, 
        pid=pers.pid, 
        choices=[high,low],
        change=aa.extra_people,
        current_value=at, 
        disqual_value=missing_lmh  )
    if at == missing_lmh
        a = zero(T)
    elseif at == high
        a = aa.higher
    else
        a = aa.lower;
    end
    return a
end

function calc_state_pension( 
    pers :: Person{T}, 
    rp :: RetirementPension{T},
    age_limits :: AgeLimits ) :: T where T
    pen = zero(T)
    if rp.abolished
        return pen
    end
    if reached_state_pension_age( 
        age_limits, 
        pers.age, 
        pers.sex )
        # so, was someone over pension age *before* the new state pension?
        # if so, use the proportion of the `class_a` they seemed to be on at 
        # the time, times the current `class_a`. 
        if reached_state_pension_age(
            # old style 
            age_limits, 
            pers.age, 
            pers.sex,
            age_limits.savings_credit_to_new_state_pension )
            # println( "pers.benefit_ratios $(pers.benefit_ratios)")
            if ! haskey( pers.benefit_ratios, state_pension ) 
                ratio =  pers.age < 70 ? 0.0 : 1.0 # kinda crude deferrment
            else
                ratio = pers.benefit_ratios[state_pension]
            end
            pen = ratio*rp.cat_a
        else
            # 
            # new style
            pen = rp.new_state_pension
        end
    end
    return pen
end

"""
FIXME Model this properly
"""
function calc_esa(     
    pers :: Person{T}, 
    esa  :: ContributoryESA{T}) :: T where T
    e = zero(T)
    if esa.abolished
        return e
    end
    if pers.esa_type == contributory_jsa
        if pers.age < 25
            # FIXME not quite right since
            # could be past assessment stage;
            # maybe check time out of work?
            e = esa.assessment_u25
        else
            e = esa.main
        end
        if has_limited_capactity_for_work_activity( pers )
            e += esa.support
        end
    end
    return e
end

function calc_maternity_allowance( 
    pers :: Person{T},
    ma :: MaternityAllowance ) :: T where T
    m = zero(T)
    if ma.abolished
        return m
    end
    # fixme the design means you should never have to check the incomes dict here
    if has_income( pers, maternity_allowance ) 
        m = ma.rate
    end
    return m
end

function calc_carers_allowance( 
    pers :: Person{T}, 
    pres :: IndividualResult{T},
    carers :: CarersAllowance{T}) :: T where T
    c = zero(T)
    if carers.abolished
        return c
    end
    earnings :: T = isum(
        pres.income, 
        carers.earnings;
        deducted=carers.deductions )
    # println( "earnings=$earnings carers.gainful_employment_min=$(carers.gainful_employment_min)")
    if pers.hours_of_care_given >= carers.hours && 
        earnings < carers.gainful_employment_min
        c = carers.allowance
    end
    return c
end

"""
Completely arbitrary, but the best I can do ...
Because there are NO child receipts of disability benefits AT ALL in the data...
Ref:
https://www.socialsecurity.gov.scot/guidance-resources/guidance/child-disability-payment-decision-making-guide/determinations-and-awards/what-a-determination-of-entitlement-is
FIXME UnitTest needed.
"""
function child_disability_scores( child :: Person )::Vector{Int}
    v = [0,0]
    if child.registered_blind
        v[1] += 3
    elseif child.registered_partially_sighted
        v[1] += 1
    end
    if child.registered_deaf
        v[1] += 2
    end
    if child.adls_are_reduced == reduced_a_lot
        v[1] += 3
        v[2] += 3
    elseif child.adls_are_reduced == reduced_a_little
        v[1] += 1
        v[2] += 1
    end
    for dis in [
       vision,
       hearing,
       learning,
       memory,
       mental_health,
       stamina,
       socially,
       other_difficulty]
       if haskey(child.disabilities,dis) && child.disabilities[dis]
           v[1] += 1
       end
    end
    for dis in [
       vision,
       mobility,
       dexterity,
       stamina ]
       if haskey(child.disabilities,dis) && child.disabilities[dis]
           v[2] += 2
       end
    end
    if child.health_status == Very_Bad
        v[1] += 3
        v[2] += 2
    elseif child.health_status == Bad
        v[1] += 1
        v[2] += 1
    end
    if child.has_long_standing_illness
        v[1] += 3
        v[2] += 1
    end
    if child.adls_are_reduced == reduced_a_lot
        v[1] += 3
        v[2] += 3
    elseif child.adls_are_reduced == reduced_a_little
        v[1] += 1
        v[2] += 1
    end
    return v
end

"""
Hacky version of DLA/SCDP that only works for Scotland.
FIXME Tests update
"""
function calc_dla(
    pers :: Person{T},
    dla  :: DisabilityLivingAllowance{T},
    scdp :: ScottishChildDisabilityPayment{T} ) :: Tuple{T,T} where T
    dc = zero(T)
    dm = zero(T)
    if dla.abolished
        return (dc,dm)
    end
    if (length(scdp.care_thresholds) == 3) && (length(scdp.mobility_thresholds) == 2)
        # new version has been initialised using `calibrate_child_disability`
        scores = child_disability_scores( pers )
        dc = if scores[1] >= scdp.care_thresholds[1]
            dla.care_high
        elseif scores[1] >= scdp.care_thresholds[2]
            dla.care_middle
        elseif scores[1] >= scdp.care_thresholds[3]
            dla.care_low
        else
            zero(T)
        end
        dm = if scores[2] >= scdp.mobility_thresholds[1]
            dla.mob_high
        elseif scores[2] >= scdp.mobility_thresholds[2]
            dla.mob_low
        else
            zero(T)
        end
    end
    return dc, dm     
    #=

    dla_s = dla_greater_of( pers.dla_self_care_type, pers.pip_daily_living_type )
    dla_m = dla_greater_of( pers.dla_mobility_type, pers.pip_mobility_type )
    # FIXME we use the same list for both mob and self
    # I think because of small sample size (kids only)
    dla_s = change_status( 
        candidates=dla.candidates, 
        pid=pers.pid, 
        choices=[high,mid,low],
        change=dla.extra_people,
        current_value=dla_s, 
        disqual_value=missing_lmh  )
    dla_m = change_status( 
        candidates=dla.candidates, 
        pid=pers.pid, 
        choices=[high,mid,low],
        change=dla.extra_people,
        current_value=dla_m, 
        disqual_value=missing_lmh  )
    # FIXME make all these names constisent (mid/middle,care->self_care etc.)
    if dla_s == high 
        dc = dla.care_high
    elseif dla_s == mid
        dc = dla.care_middle
    elseif dla_s == low 
        dc = dla.care_low
    end
    if dla_m == high 
        dm = dla.mob_high
    elseif dla_m in (low,mid)
        dm = dla.mob_low
    end
    # println( "setting DLA as $dc, $dm")
    =#
    return (dc,dm);
end # dla calc

"""
return the score from child_disability_scores that generates the given target number.
FIXME UnitTest needed.
"""
function calibrate_child_disability( settings:: Settings, care_targets :: Vector, mob_targets :: Vector)::Tuple
    settings.num_households, settings.num_people, nhhs2 = 
        FRSHouseholdGetter.initialise( settings; reset=false )
    df = DataFrame(
        pid = zeros(BigInt,settings.num_people),
        care_score = zeros(Integer,settings.num_people),
        mob_score = zeros(Integer,settings.num_people),
        weight = zeros(settings.num_people))
    nks = 0
    for hno in 1:settings.num_households
        hh = FRSHouseholdGetter.get_household( hno )
        for (pid,person) in hh.people
            if person.age <= 15
                nks += 1
                r = df[nks,:]
                r.weight = hh.weight
                r.pid = pid
                scores = child_disability_scores( person )
                r.care_score = scores[1]
                r.mob_score = scores[2]
            end
        end
    end
    df = df[1:nks,:]
    sort!( df, :care_score; rev=true )
    start = 1
    l = 0
    target_care_score = zeros( length( care_targets ))
    for care_target in care_targets
        cumpop = 0
        for i in start:nks
            r = df[i,:]
            cumpop += r.weight
            # @show cumpop care_target r.care_score 
            if( cumpop >= care_target ) || (i == nks)
                l += 1
                target_care_score[l] = r.care_score             
                @show target_care_score cumpop start l
                cumpop = 0
                start = i+1
                break
            end
        end
    end
    sort!( df, :mob_score; rev=true )
    start = 1
    l = 0
    target_mob_score = zeros( length( mob_targets ))
    for mob_target in mob_targets
        cumpop = 0
        for i in start:nks
            r = df[i,:]
            cumpop += r.weight
            # @show cumpop mob_target r.mob_score 
            if( cumpop >= mob_target ) || (i == nks)
                l += 1
                target_mob_score[l] = r.mob_score             
                # @show target_mob_score
                @show target_care_score cumpop start l
                cumpop = 0
                start = i+1
                break
            end
        end
    end
    return target_care_score, target_mob_score, df
end

function calc_jsa( 
    pers :: Person{T}, 
    jsa :: JobSeekersAllowance{T},
    hrs  :: HoursLimits ) :: T where T
    j = zero(T)        
    if jsa.abolished
        return j
    end
    if pers.jsa_type == contributory_jsa &&
        pers.usual_hours_worked <= hrs.med &&
        (! has_limited_capactity_for_work( pers ))
        j = pers.age < 25 ? jsa.u25 : jsa.o24
    end
    return j
end

"""
Household level calculations for all nmt benefits that don't require knowlege
of income tax/ni liabilties - not necessarily taxable benefits, just things
that don't require any kind of net income calculation and so can be done
before IT/NI.
"""
function calc_pre_tax_non_means_tested!( 
    hhres :: HouseholdResult,
    hh    :: Household,
    sys   :: NonMeansTestedSys,
    hours_limits   :: HoursLimits,
    age_limits :: AgeLimits ) 
    ## maybe add a benefit unit allocator
    bus = get_benefit_units( hh )
    buno = 1 
    for bu in bus 
        has_children = size( bu.children )[1] > 0
        bures = hhres.bus[buno]
        for adno in bu.adults
            pers = bu.people[adno]
            pres = bures.pers[adno]
            pres.income[STATE_PENSION] = calc_state_pension( 
                pers,
                sys.pensions, age_limits );
            pres.income[WIDOWS_PAYMENT] = calc_widows_benefits(
                pers, has_children, sys.bereavement, sys.widows_pension )
            #
            # FIXME
            # pip/dla can only be claimed 
            # if ! reached_state_pension_age( age_limits, pers.age, pers.sex )
            # but claims can run on indefinitely and for now we're just using 
            # receipts, so ignore any upper age limits until we model these fully.
            #
            if pers.age <= 16
                pres.income[sys.dla.care_slot],
                pres.income[sys.dla.mob_slot] = calc_dla( pers, sys.dla, sys.scdp );
            else 
                pres.income[sys.pip.care_slot],
                pres.income[sys.pip.mob_slot] = calc_pip( pers, sys.pip )
            end
            #
            # .. conversely, this age limit seems safe: a 62 yo female recieving
            # in the data should be disallowed now the pension age has increased.
            #
            if reached_state_pension_age( age_limits, pers.age, pers.sex )
                pres.income[sys.attendance_allowance.slot] = calc_attendance_allowance( pers, sys.attendance_allowance )
            else
                pres.income[CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE] = calc_esa( pers, sys.esa )
                pres.income[CONTRIB_JOBSEEKERS_ALLOWANCE] = calc_jsa( pers, sys.jsa, hours_limits )
                pres.income[MATERNITY_ALLOWANCE] = calc_maternity_allowance( pers, sys.maternity )
            end
            # NON-overlapping rules p1178 go here 
            for chno in bu.children
                child = bu.people[chno]
                pres = bures.pers[chno]
                if child.age <= 16 # fixme parameterise 16
                    pres.income[sys.dla.care_slot],
                    pres.income[sys.dla.mob_slot] = calc_dla( child, sys.dla, sys.scdp );
                else 
                    pres.income[sys.pip.care_slot],
                    pres.income[sys.pip.mob_slot] = calc_pip( child, sys.pip )
                end
            end
        end # ad loop
        buno += 1
    end # bu loop
end # calc_non_means_tested

"""
NMT Benefits that require knowlege of tax and NI liabilities and so have to be done
after a tax calculation - not necessarily tax free as such (CB higher charge). Kinda-sorta
means-tested bens, I suppose.
"""
function calc_post_tax_non_means_tested!( 
    hhres :: HouseholdResult,
    hh    :: Household,
    sys   :: NonMeansTestedSys,
    age_limits :: AgeLimits ) 
    ## maybe add a benefit unit allocator
    bus = get_benefit_units( hh )
    buno = 1 
    for bu in bus 
        has_children = size( bu.children )[1] > 0
        bures = hhres.bus[buno]
        calc_child_benefit!( 
            bures,
            bu, 
            sys.child_benefit )
        for adno in bu.adults
            pers = bu.people[adno]
            pres = bures.pers[adno]
            pres.income[sys.carers.slot] = 
                calc_carers_allowance( pers, pres, sys.carers )        
            if hh.region == Scotland
                if pres.income[sys.carers.slot] > 0
                    pres.income[CARERS_ALLOWANCE_SUPPLEMENT] = sys.carers.scottish_supplement
                end
            end
            # NON-overlapping rules p1178 go here 
        end # ad loop
        buno += 1
    end # bu loop
end # calc_non_means_tested

end # package non-means-tested