#
# This contains most of the functions used to create our model dataset from raw FRS/SHS/HBAI data.
# This has all the HBAI references removed
# FIXME too many different assignment and comparison functions - simplify
#
using DataFrames
using Revise # NOTE!! Revise not a ScottishTaxBenefit model direct dependency, but this is script
using CSV
using ArgCheck
using StatsBase
using ScottishTaxBenefitModel
using .Utils
using .Definitions
using .RunSettings
using .Randoms: mybigrandstr
using .GeneralTaxComponents: RateBands

# note: `includet` needs Revise loaded into the session
# includet( "frs_hbai_creation_libs.jl")

#
# BU head is hrp or 1st person interviewed in subsequent BUs
# see: 
function is_bu_head( 
    frs_bu     :: DataFrameRow, 
    bu_people  :: DataFrame,
    frs_person :: DataFrameRow ) :: Bool
    if frs_person.benunit == 1 # head of hh is head of bu
        return frs_person.hrpid == 1
    end
    @assert frs_person.hrpid != 1 # 2nd&subsquent bu can't be hrp
    sort!( bu_people, [:person]) # FIXME shouldn't be needed 
    return frs_person.person == bu_people[1,:person] # is this the 1st person in subsequent bus
end


function create_adults(
    year::Integer,
    frs_adults::DataFrame,
    accounts::DataFrame,
    benunit::DataFrame,
    extchild::DataFrame,
    maint::DataFrame,
    penprov::DataFrame,
    # admin::DataFrame,
    care::DataFrame,
    mortcont::DataFrame,
    pension::DataFrame,
    govpay::DataFrame,
    mortgage::DataFrame,
    assets::DataFrame,
    chldcare::DataFrame,
    househol::DataFrame,
    oddjob::DataFrame,
    benefits::DataFrame,
    endowmnt::DataFrame,
    job::DataFrame,
    frsx :: DataFrame )::DataFrame

    num_adults = size(frs_adults)[1]
    adult_model = initialise_person(num_adults)
    adno = 0
    
    for pn in 1:num_adults
        if pn % 1000 == 0
            println("adults: on year $year, pno $pn")
        end

        frs_person = frs_adults[pn, :]
        frs_bu = benunit[ (frs_person.sernum .== benunit.sernum).&(frs_person.benunit .== benunit.benunit), : ][1,:]
        # everyone in hh in same benefit unit as frs_person
        bu_people = frs_adults[ (frs_person.sernum .== frs_adults.sernum).&(frs_person.benunit .== frs_adults.benunit), : ] # FIXME do this the other way around
        sernum = frs_person.sernum
        adno += 1
        model_adult = adult_model[adno, :]
        model_adult.onerand = mybigrandstr()
            ## also for children
        model_adult = adult_model[adno, :]
        model_adult.pno = frs_person.person
        model_adult.hid = frs_person.sernum
        model_adult.is_hrp = to_bool( frs_person.hrpid )
        model_adult.uhid = get_pid( FRSSource, year, frs_person.sernum, 0 ) # unique hhid needed for mostly.ai generator
        model_adult.pid = get_pid( FRSSource, year, frs_person.sernum, frs_person.person )
        model_adult.from_child_record = false
        model_adult.data_year = year
        model_adult.default_benefit_unit = frs_person.benunit
        model_adult.age = frs_person.age80
        model_adult.sex = Sex(safe_assign(frs_person.sex))
        model_adult.ethnic_group = Ethnic_Group(safe_assign(frs_person.ethgr3))
        
        hdsp = is_bu_head( 
            frs_bu,
            bu_people,
            frs_person )
        model_adult.is_bu_head = hdsp #  == true) 
        model_adult.jsa_type, model_adult.esa_type = make_jsa_type( 
            frsx,
            frs_person.sernum,
            frs_person.benunit,
            hdsp )
        if model_adult.is_bu_head
            # see the note on capital in `docs/legalaid` - and 
            # assign BU total to head of bu
            # totsav3 us is the only measure in all of 2015-2021 FRSs
            model_adult.wealth_and_assets = safe_assign(frs_bu.totcapb3)
            # we'll also store the band 
            model_adult.totsav= safe_assign(frs_bu.totsav)
        end
        a_job = job[((job.sernum.==frs_person.sernum).&(job.benunit.==frs_person.benunit).&(job.person.==frs_person.person)), :]
        a_benunit = benunit[((frs_person.benunit .== benunit.benunit).&(frs_person.sernum.==benunit.sernum)),:]
        a_benunit = a_benunit[1,:]
        model_adult.over_20_k_saving = 0
        if hdsp
            ts = safe_assign(a_benunit.totsav)
            if ts >= 5
                model_adult.over_20_k_saving = 1
            end
        end
        # println( "model_adult.over_20_k_saving=$(model_adult.over_20_k_saving)")

        a_pension = pension[((pension.sernum.==frs_person.sernum).&(pension.benunit.==frs_person.benunit).&(pension.person.==frs_person.person)), :]
        a_penprov = penprov[((penprov.sernum.==frs_person.sernum).&(penprov.benunit.==frs_person.benunit).&(penprov.person.==frs_person.person)), :]
        an_asset = assets[((assets.sernum.==frs_person.sernum).&(assets.benunit.==frs_person.benunit).&(assets.person.==frs_person.person)), :]
        an_account = accounts[((accounts.sernum.==frs_person.sernum).&(accounts.benunit.==frs_person.benunit).&(accounts.person.==frs_person.person)), :]
        a_maint = maint[((maint.sernum.==frs_person.sernum).&(maint.benunit.==frs_person.benunit).&(maint.person.==frs_person.person)), :]
        a_oddjob = oddjob[((oddjob.sernum.==frs_person.sernum).&(oddjob.benunit.==frs_person.benunit).&(oddjob.person.==frs_person.person)), :]
        a_benefits = benefits[((benefits.sernum.==frs_person.sernum).&(benefits.benunit.==frs_person.benunit).&(benefits.person.==frs_person.person)), :]
        npens = size(a_pension)[1]
        nassets = size(an_asset)[1]
        naaccounts = size(an_account)[1]
        nojs = size(a_oddjob)[1]

        model_adult.marital_status = Marital_Status(safe_assign(frs_person.marital))
        # random variable rename for (almost) same coding frame in 2022 why, why why
        qt = if year < 2022 
            frs_person.dvhiqual
        elseif xparse(frs_person.educqual;default=-1) <= 86 # no qual/missing is 87 in educqual -1 in our old enum
            frs_person.educqual
        else 
            -1 
        end
        model_adult.highest_qualification = Qualification_Type(safe_assign(qt))
        model_adult.sic = SIC_2007(safe_assign(frs_person.sic))

        model_adult.socio_economic_grouping = Socio_Economic_Group(safe_assign(Integer(trunc(frs_person.nssec))))
        if year < 2022 # deleted in 2022 WHY DO THIS !?!?!
            model_adult.age_completed_full_time_education = safe_assign(frs_person.tea)
        end
        model_adult.years_in_full_time_work = safe_inc(0, frs_person.ftwk)
        model_adult.years_in_part_time_work = safe_inc(0, frs_person.ptwk)
        model_adult.employment_status = ILO_Employment(safe_assign(frs_person.empstati))
        model_adult.occupational_classification = Standard_Occupational_Classification(safe_assign(frs_person.soc2010))

        process_job_rec!(model_adult, a_job)
        # FIXME some duplication here
        #
        # new - assign a total earnings/se figure from both hbai and frs
        # so we can compare the two. This is in reaction to the 
        # oddly low Gini/Palma when using HBAI/SPI'd earnings
        # DELETED in this Non-HBAI version
        model_adult.wages_hbai = -1 #missing #hbaidata.wages
        model_adult.self_emp_hbai = -1# missing # hbaidata.selfemp
        model_adult.wages_frs = safe_inc( 0.0, frs_person.inearns )
        model_adult.self_emp_frs = safe_inc( 0.0, frs_person.incseo2 )
        
        penstuff = process_pensions(a_pension)
        model_adult.income_private_pensions = penstuff.pension
        model_adult.income_income_tax += penstuff.tax

        # FIXME CHECK THIS - adding PENCONT and also from work pension contributions - double counting?
        (employee,employer) = process_penprovs(a_penprov)

        model_adult.income_pension_contributions_employee = safe_inc( employee, model_adult.income_pension_contributions_employee )
        model_adult.income_pension_contributions_employer = safe_inc( employer, model_adult.income_pension_contributions_employer )
        
        map_investment_income!(model_adult, an_account)
        model_adult.income_property = safe_inc(0.0, frs_person.royyr1)
        if safe_compare_eq(frs_person.rentprof,2) # it's a loss
            model_adult.income_property *= -1 # a loss
        end
        model_adult.income_royalties = safe_inc(0.0, frs_person.royyr2)
        model_adult.income_other_income = safe_inc(0.0, frs_person.royyr3) # sleeping partners
        model_adult.income_other_income = safe_inc(
            model_adult.income_other_income,
            frs_person.royyr4
        ) # overseas pensions
        # payments from charities, bbysitting ..
        # model_adult.income_other_income = safe_inc( model_adult.income_other_income, frs_person.[x]
        model_adult.income_alimony_and_child_support_received,
        model_adult.income_alimony_and_child_support_paid = map_alimony(
            frs_person,
            a_maint )

        model_adult.income_odd_jobs = 0.0
        for o in 1:nojs
            model_adult.income_odd_jobs = safe_inc(
                model_adult.income_odd_jobs,
                a_oddjob[o, :ojamt]
            )
        end
        model_adult.income_odd_jobs /= 4.0 # since it's monthly

        ## TODO babysitting,chartities (secure version only??)
        ## TODO alimony and childcare PAID ?? // 2015/6 only
        ## TODO allowances from absent spouses apamt apdamt

        ## TODO income_education_allowances

        model_adult.income_foster_care_payments = max(0.0,coalesce(frs_person.allpd3,0.0))


        ## TODO income_student_grants
        ## TODO income_student_loans
        ## TODO income_income_tax
        ## TODO income_national_insurance
        ## TODO income_local_taxes

        process_benefits!(model_adult, a_benefits)
        process_assets!(model_adult, an_asset)

        ## also for child
        model_adult.registered_blind = to_bool( frs_person.spcreg1  )
        model_adult.registered_partially_sighted = to_bool( frs_person.spcreg2  )
        model_adult.registered_deaf = to_bool( frs_person.spcreg3  )

        model_adult.disability_vision = to_bool( frs_person.disd01 )# cdisd kids ..
        model_adult.disability_hearing = to_bool( frs_person.disd02  )
        model_adult.disability_mobility = to_bool( frs_person.disd03  )
        model_adult.disability_dexterity = to_bool( frs_person.disd04  )
        model_adult.disability_learning = to_bool( frs_person.disd05  )
        model_adult.disability_memory = to_bool( frs_person.disd06  )
        model_adult.disability_mental_health = to_bool( frs_person.disd07  )
        model_adult.disability_stamina = to_bool( frs_person.disd08  )
        model_adult.disability_socially = to_bool( frs_person.disd09  )
        model_adult.disability_other_difficulty = to_bool( frs_person.disd10  )

        model_adult.has_long_standing_illness = to_bool( frs_person.health1  )
        model_adult.how_long_adls_reduced = Illness_Length(xparse(frs_person.limitl; default=-1)) #  < 0 ? -1 : frs_person.limitl)
        adlr = max(-1, xparse(frs_person.condit; default=-1))
        model_adult.adls_are_reduced = ADLS_Inhibited(adlr) # missings to 'not at all'
        model_adult.age_started_first_job = safe_assign( frs_person.jobbyr )
        # This IGNORES the WID field and should use financial year as changeover
        # FIXME check this
        if(model_adult.income_bereavement_allowance_or_widowed_parents_allowance_or_bereavement > 0)||
           (model_adult.income_widows_payment > 0)
           if( year >= 2017 ) # || (year == 2017 && month > 3)
            model_adult.type_of_bereavement_allowance = widowed_parents
           else
            model_adult.type_of_bereavement_allowance = bereavement_allowance
           end
        end
        #=        
            BereavementType(safe_assign( frs_person.wid ))
        end
        =#

        model_adult.had_children_when_bereaved = safe_assign( frs_person.w2 ) == 1

        # dindividual_savings_accountbility_other_difficulty = Vector{Union{Real,Missing}}(missing, n),
        model_adult.health_status = Health_Status(safe_assign(frs_person.heathad))
        model_adult.hours_of_care_received = safe_inc(0.0, frs_person.hourcare)
        model_adult.hours_of_care_given = infer_hours_of_care(frs_person.hourtot) # also kid

        model_adult.is_informal_carer = to_bool( frs_person.carefl )# also kid
        process_relationships!( model_adult, frs_person )
        #
        # illness benefit levels
        # See the note on this in docs/
        # FIXME 2025 add Scottish Benefits to this
        model_adult.dlaself_care_type = LowMiddleHigh(map123( model_adult.income_dlaself_care, [30, 60 ] ))
        model_adult.dlamobility_type = LowMiddleHigh(map123(model_adult.income_dlamobility, [30] ))
        model_adult.attendance_allowance_type = LowMiddleHigh(map123( model_adult.income_attendance_allowance, [65] ))
        model_adult.personal_independence_payment_daily_living_type = PIPType(map12( model_adult.income_personal_independence_payment_daily_living, 65 ))
        model_adult.personal_independence_payment_mobility_type  = PIPType(map12( model_adult.income_personal_independence_payment_mobility, 30 ))
    end # adult loop
    println("final adno $adno")
    return adult_model[1:adno, :]
end # proc create_adult

#
#
function create_children(
    year::Integer,
    frs_children::DataFrame,
    childcare::DataFrame,
    benefits:: DataFrame )::DataFrame
    num_children = size(frs_children)[1]
    child_model = initialise_person(num_children)
    ccount = 0
    for chno in 1:num_children
        if chno % 1000 == 0
            println("on year $year, chno $chno")
        end
        frs_person = frs_children[chno, :]
        a_childcare = childcare[((childcare.sernum.==frs_person.sernum).&(childcare.benunit.==frs_person.benunit).&(childcare.person.==frs_person.person)), :]
        nchildcares = size(a_childcare)[1]

        sernum = frs_person.sernum
        ccount += 1
            ## also for children
        model_child = child_model[ccount, :]

        model_child.pno = frs_person.person
        model_child.hid = frs_person.sernum
        model_child.uhid = get_pid( FRSSource, year, frs_person.sernum, 0 ) # unique hhid needed for mostly.ai generator
        
        model_child.pid = get_pid(FRSSource, year, frs_person.sernum, frs_person.person)
        model_child.from_child_record = true

        model_child.data_year = year
        model_child.default_benefit_unit = frs_person.benunit
        model_child.age = frs_person.age
        model_child.sex = Sex(safe_assign(frs_person.sex))
        # model_child.ethnic_group = safe_assign(frs_person.ethgr3)
        ## also for child
        # println( "frs_person.chlimitl='$(frs_person.chlimitl)'")
        model_child.has_long_standing_illness = to_bool( frs_person.chealth1  )
        model_child.how_long_adls_reduced = Illness_Length(not_missing_or_negative(frs_person.chlimitl))#  < 0 ? -1 : frs_person.chlimitl)
        model_child.adls_are_reduced = ADLS_Inhibited(not_missing_or_negative(frs_person.chcond)) # missings to 'not at all'
        model_child.over_20_k_saving = 0

        model_child.registered_blind = to_bool( frs_person.spcreg1  )
        model_child.registered_partially_sighted = to_bool( frs_person.spcreg2  )
        model_child.registered_deaf = to_bool( frs_person.spcreg3  )

        model_child.disability_vision = to_bool( frs_person.cdisd01 )# cdisd kids ..
        model_child.disability_hearing = to_bool( frs_person.cdisd02  )
        model_child.disability_mobility = to_bool( frs_person.cdisd03  )
        model_child.disability_dexterity = to_bool( frs_person.cdisd04  )
        model_child.disability_learning = to_bool( frs_person.cdisd05  )
        model_child.disability_memory = to_bool( frs_person.cdisd06  )
        model_child.disability_mental_health = to_bool( frs_person.cdisd07  )
        model_child.disability_stamina = to_bool( frs_person.cdisd08  )
        model_child.disability_socially = to_bool( frs_person.cdisd09  )
        # dindividual_savings_accountbility_other_difficulty = Vector{Union{Real,Missing}}(missing, n),
        model_child.health_status = Health_Status(safe_assign(frs_person.heathch))
        model_child.income_wages = safe_inc( 0.0, frs_person.chearns )
        model_child.income_other_investment_income = safe_inc( 0.0, frs_person.chsave )
        model_child.income_other_income = safe_inc( 0.0, frs_person.chrinc )
        model_child.income_free_school_meals = 0.0
        for t in [:fsbval,:fsfvval,:fsmlkval,:fsmval]
            model_child.income_free_school_meals = safe_inc( model_child.income_free_school_meals, frs_person[t] )
        end
        model_child.is_informal_carer = to_bool( frs_person.carefl )# also kid
        process_relationships!( model_child, frs_person )
        # TODO education grants, all the other good child stuff EMA

        model_child.cost_of_childcare = 0.0
        model_child.hours_of_childcare = 0.0
        for c in 1:nchildcares
            if c == 1 # type of care from 1st instance
                model_child.childcare_type =
                Child_Care_Type(map_child_care( year, a_childcare[c, :chlook] ))
                model_child.employer_provides_child_care = (to_bool(a_childcare[c, :emplprov]; trueval=2))
            end
            model_child.cost_of_childcare = safe_inc(
                model_child.cost_of_childcare,
                a_childcare[c, :chamt]
            )
            model_child.hours_of_childcare = safe_inc(
                model_child.hours_of_childcare,
                a_childcare[c, :chhr]
            )
        end # child care loop
        model_child.onerand = mybigrandstr()
        #
        #
        # this is zero length
        # a_oddjob = oddjob[((oddjob.sernum.==frs_person.sernum).&(oddjob.benunit.==frs_person.benunit).&(oddjob.person.==frs_person.person)), :]
        # this isn't 
        a_benefits = benefits[((benefits.sernum.==frs_person.sernum).&(benefits.benunit.==frs_person.benunit).&(benefits.person.==frs_person.person)), :]
        sb = size( a_benefits )[1]
        # println( "sb = $sb")
        # @assert sb in [0,1]
        process_benefits!( model_child, a_benefits )
        
    end # chno loop
    return child_model[1:ccount,:] # send them all back ...
end

function create_household(
    year::Integer,
    frs_household::DataFrame,
    renter::DataFrame,
    mortgage::DataFrame,
    mortcont::DataFrame,
    owner::DataFrame,
    frsx :: DataFrame )::DataFrame

    num_households = size(frs_household)[1]
    hh_model = initialise_household(num_households)
    hhno = 0
    for hn in 1:num_households
        if hn % 1000 == 0
            println("on year $year, hid $hn")
        end
        hh = frs_household[hn, :]
        frx = frsx[(frsx.sernum.==hh.sernum ), :]

        sernum = hh.sernum
        hhno += 1
        dd = split(hh.intdate, "/")
        hh_model[hhno, :interview_year] = parse(Int64, dd[3])
        interview_month = parse(Int8, dd[1])
        hh_model[hhno, :interview_month] = interview_month
        hh_model[hhno, :quarter] = div(interview_month - 1, 3) + 1

        hh_model[hhno, :hid] = sernum
        hh_model[hhno, :uhid] = get_pid( FRSSource, year, sernum, 0 ) # unique hhid needed for mostly.ai generator
        
        hh_model[hhno, :data_year] = year
        hh_model[hhno, :tenure] = Tenure_Type( max(-1,coalesce(hh.tentyp2,-1)))
        hh_model[hhno, :dwelling] = DwellingType(max(-1,coalesce(hh.typeacc,-1)))
        hh_model[hhno, :region] = Standard_Region(max(-1,coalesce(hh.gvtregn,-1)))
        ctb = max(-1,coalesce( hh.ctband, -1 ))
        hh_model[hhno, :ct_band] = CT_Band(ctb)
        hh_model[hhno, :weight] = hh.gross4
        # hh_model[hhno, :tenure] = hh.tentyp2 > 0 ? Tenure_Type(hh.tentyp2) :
        #                          Missing_Tenure_Type
        # hh_model[hhno, :region] = hh.gvtregn > 0 ? Standard_Region(hh.gvtregn) :
        #                           Missing_Standard_Region
        # hh_model[hhno, :ct_band] = hh.ctband > 0 ? CT_Band(hh.ctband) : Missing_CT_Band
        #
        # council_tax::Real
        # FIXME this is rounded to £
        if hh_model[hhno, :region] == 299999999 # Scotland # FIXME this is whole £s only
            # also 16 missings in 2015 - investigate 
            hh_model[hhno, :water_and_sewerage] = safe_assign(hh.cwatamtd)
        elseif hh_model[hhno, :region] == 399999999 # Nireland
            hh_model[hhno, :water_and_sewerage] = 0.0 # FIXME NIreland in rates????
        else #
            hh_model[hhno, :water_and_sewerage] = safe_assign(hh.watsewrt)
        end
        # FIXME this needs renamed: actually capital component
        hh_model[hhno, :mortgage_payment] = mortage_capital_payments( frx )
        mit = safe_assign( hh.mortint )
        hh_model[hhno, :mortgage_interest] = max( 0.0, mit ) # > 0 ? mit : missing 

        # TODO
        # years_outstanding_on_mortgage::Integer
        # mortgage_outstanding::Real
        # year_house_bought::Integer
        # FIXME rounded to £1
        hh_model[hhno, :gross_rent] = safe_inc(0.0, hh.hhrent) #  rentg Gross rent including Housing Benefit  or rent Net amount of last rent payment

        rents = renter[(renter.sernum.==sernum), :]
        nrents = size(rents)[1]
        hh_model[hhno, :rent_includes_water_and_sewerage] = false
        for r in 1:nrents
            rc = coalesce(rents[r, :wsinc],-1)
            if (rc in [1, 2, 3])
                hh_model[hhno, :rent_includes_water_and_sewerage] = true
            end
        end
        ohc = 0.0
        ohc = safe_inc(ohc, hh.chrgamt1)
        ohc = safe_inc(ohc, hh.chrgamt2)
        ohc = safe_inc(ohc, hh.chrgamt3)
        ohc = safe_inc(ohc, hh.chrgamt4)
        ohc = safe_inc(ohc, hh.chrgamt5)
        ohc = safe_inc(ohc, hh.chrgamt6)
        ohc = safe_inc(ohc, hh.chrgamt7)
        ohc = safe_inc(ohc, hh.chrgamt8)
        ohc = safe_inc(ohc, hh.chrgamt9)
        hh_model[hhno, :other_housing_charges] = ohc
        hh_model[hhno, :bedrooms] = coalesce(hh.bedroom6,0)
        hh_model[hhno, :onerand] = mybigrandstr()
        hh_model[hhno, :original_gross_income] = coalesce(hh.hhinc,0.0)
        # TODO
        # gross_housing_costs::Real
        # total_wealth::Real
        # house_value::Real
        # people::People_Dict
    end
    hh_model[1:hhno, :]
end

"""
Override loadfrs for all the weird missings in frx1920 etc.
"""
function loadfrsx(which::AbstractString, year )::DataFrame
    filename = "$(L_FRS_DIR)/$(year)/tab/$(which).tab"
    df = CSV.File(filename, delim = '\t', missingstring=[""," ","-1"]) |> DataFrame #
    lcnames = Symbol.(lowercase.(string.(names(df))))
    rename!(df, lcnames)
    df.data_year .= year
    df
end

"""

Main entry point for data creation. Creates UK - wide datasets; scottish subset is made later.

"""
function create_data(;start_year::Int, end_year::Int)
    for year in start_year:end_year
            print("on year $year ")
        y = year - 2000
        ystr = "$(y)$(y+1)"
        # we only want this massive thing for a couple of
        # benefit variables.
        frsx = loadfrsx( "frs$ystr", year )
        accounts = loadfrs("accounts", year)
        adult = loadfrs("adult", year)
        # probably *is* sorted by this.
        sort!( adult, [:sernum, :benunit, :person ])
        assets = loadfrs("assets", year)
        benefits = loadfrs("benefits", year)
        benunit = loadfrs("benunit", year)
        care = loadfrs("care", year)
        child = loadfrs("child", year)
        chldcare = loadfrs("chldcare", year)
        endowmnt = loadfrs("endowmnt", year)
        extchild = loadfrs("extchild", year)
        govpay = loadfrs("govpay", year)
        househol = loadfrs("househol", year)
        job = loadfrs("job", year)
        maint = loadfrs("maint", year)
        mortcont = loadfrs("mortcont", year)
        mortgage = loadfrs("mortgage", year)
        oddjob = loadfrs("oddjob", year)
        owner = loadfrs("owner", year)
        penprov = loadfrs("penprov", year)
        pension = loadfrs("pension", year)
        rentcont = loadfrs("rentcont", year)
        renter = loadfrs("renter", year)
        #
        # 2021 renames ... these are all the same variables
        #
        renameif!( adult, ["nssec20"=> "nssec", "soc2020"=>"soc2010"]) # 2021 change; this seems to be the same variable

        model_children = create_children(
            year, 
            child, 
            chldcare, 
            benefits )

        model_people = create_adults(
            year,
            adult,
            accounts,
            benunit,
            extchild,
            maint,
            penprov,
            # admin,
            care,
            mortcont,
            pension,
            govpay,
            mortgage,
            assets,
            chldcare,
            househol,
            oddjob,
            benefits,
            endowmnt,
            job,
            frsx )
        model_households = create_household(
            year,
            househol,
            renter,
            mortgage,
            mortcont,
            owner,
            frsx )
        println( "on year $year")
        println( "hhlds")
        append = year > start_year
        CSV.write("$(MODEL_DATA_DIR)/actual_data/model_households-$(start_year)-$(end_year)-w-enums-2.tab", model_households, delim = "\t", append=append)
        CSV.write("$(MODEL_DATA_DIR)/actual_data/model_people-$(start_year)-$(end_year)-w-enums-2.tab", model_people, delim = "\t", append=append)
        CSV.write("$(MODEL_DATA_DIR)/actual_data/model_people-$(start_year)-$(end_year)-w-enums-2.tab", model_children, delim = "\t", append=true)
    
    end    
end