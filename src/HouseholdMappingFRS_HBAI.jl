#
# This contains most of the functions used to create our model dataset from raw FRS/SHS/HBAI data.
#
# This is for 2015-2019 FRS/HBAI; you likely need to alter this by hand
# as years are added. 
# 
#
using DataFrames
using CSV

using ScottishTaxBenefitModel
using .Utils
using .Definitions
using .Randoms: mybigrandstr
using .GeneralTaxComponents: RateBands, WEEKS_PER_YEAR

export CreateData

include( "frs_hbai_creation_libs.jl")

function is_in_hbai(
  hbai_res :: DataFrame,
  sernum::Integer,
  benunit  :: Integer,
  person :: Integer ) :: Bool

  ad_hbai = hbai_res[((hbai_res.sernum.==sernum ).&
                      ((hbai_res.personhd.==person).|(hbai_res.personsp.==person)) .&
                      (hbai_res.benunit.==benunit)), :]
  return size( ad_hbai )[1]>0
end


function is_in_hbai(
  hbai_res :: DataFrame,
  sernum::Integer   ) :: Bool

  ad_hbai = hbai_res[(hbai_res.sernum.==sernum ), :]
  return size( ad_hbai )[1]>0
end

#
# BU head on HBAI classification. Near dup of `get_incs_from_hbai` below.
#
function is_bu_head( 
    hbai_res :: DataFrame,  
    sernum::Integer,
    benunit  :: Integer,
    person :: Integer  ) :: Bool
    ad_hbai = hbai_res[((hbai_res.sernum.==sernum ).&
                       ((hbai_res.personhd.==person).|(hbai_res.personsp.==person)) .&
                       (hbai_res.benunit.==benunit)), :]
   @assert size( ad_hbai )[1] > 0
   ar = ad_hbai[1,:]
   return ar.personhd == person
end

function get_incs_from_hbai(
  hbai_res :: DataFrame,
  sernum::Integer,
  benunit  :: Integer,
  person :: Integer ) :: NamedTuple

   ad_hbai = hbai_res[((hbai_res.sernum.==sernum ).&
                       ((hbai_res.personhd.==person).|(hbai_res.personsp.==person)) .&
                       (hbai_res.benunit.==benunit)), :]
   @assert size( ad_hbai )[1] > 0
   ar = ad_hbai[1,:]
   if ar.personhd == person
       return (
            age=safe_assign(ar.agehd,0.0),
            sex=safe_assign(ar.sexhd,0.0),
            wages=safe_assign(ar.esgjobhd,0.0),
            selfemp=safe_assign(ar.esgrsehd,0.0))
   elseif ar.personsp == person
       return (
            age=safe_assign(ar.agesp,0.0),
            sex=safe_assign(ar.sexsp,0.0),
            wages=safe_assign(ar.esgjobsp,0.0),
            selfemp=safe_assign(ar.esgrsesp,0.0))
   else
       @assert false  "$person is neither head or spouse in hbai assignment; sernum=$sernum benunit=$benunit"
   end
end


## FIXME add Oddjobs here for non-hbai case

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
    hbai_res::DataFrame,
    frsx :: DataFrame,
    override_se_and_wage_with_hbai :: Bool = true )::DataFrame

    num_adults = size(frs_adults)[1]
    adult_model = initialise_person(num_adults)
    adno = 0
    hbai_year = year - 1993
    println("hbai_year $hbai_year")
    for pn in 1:num_adults
        if pn % 1000 == 0
            println("adults: on year $year, pno $pn")
        end

        frs_person = frs_adults[pn, :]
        sernum = frs_person.sernum
        if is_in_hbai(
            hbai_res,
            frs_person.sernum,
            frs_person.benunit,
            frs_person.person ) # fixme probably only need to check sernum
            adno += 1
            model_adult = adult_model[adno, :]
            model_adult.onerand = mybigrandstr()
                ## also for children
            model_adult = adult_model[adno, :]
            model_adult.pno = frs_person.person
            model_adult.hid = frs_person.sernum
            model_adult.is_hrp = (frs_person.hrpid == 1) ? 1 : 0

            model_adult.pid = get_pid( FRS, year, frs_person.sernum, frs_person.person )
            model_adult.from_child_record = 0
            model_adult.data_year = year
            model_adult.default_benefit_unit = frs_person.benunit
            model_adult.age = frs_person.age80
            model_adult.sex = safe_assign(frs_person.sex)
            model_adult.ethnic_group = safe_assign(frs_person.ethgr3)
            
            hdsp = is_bu_head( 
                hbai_res,
                frs_person.sernum,
                frs_person.benunit,
                frs_person.person )
            
            model_adult.jsa_type, model_adult.esa_type = make_jsa_type( 
                frsx,
                frs_person.sernum,
                frs_person.benunit,
                hdsp )
            
            # plan 'B' wages and SE from HBAI; first work out hd/spouse so we can extract right ones
            # is_hbai_spouse = ( model_hbai.personsp == model_hbai.person )
            # is_hbai_head = ( model_hbai.personhd == model_hbai.person )
            # @assert is_hbai_head || is_hbai_spouse  "neither head nor spouse"

            ## adult only
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

            model_adult.marital_status = safe_assign(frs_person.marital)
            model_adult.highest_qualification = safe_assign(frs_person.dvhiqual)
            model_adult.sic = safe_assign(frs_person.sic)

            model_adult.socio_economic_grouping = safe_assign(Integer(trunc(frs_person.nssec)))
            model_adult.age_completed_full_time_education = safe_assign(frs_person.tea)
            model_adult.years_in_full_time_work = safe_inc(0, frs_person.ftwk)
            model_adult.employment_status = safe_assign(frs_person.empstati)
            model_adult.occupational_classification = safe_assign(frs_person.soc2010)

            process_job_rec!(model_adult, a_job)
            # FIXME some duplication here
            hbaidata = get_incs_from_hbai(
                hbai_res,
                frs_person.sernum,
                frs_person.benunit,
                frs_person.person ) # fixme probably only need to check sernum
            @assert model_adult.sex == hbaidata.sex
            @assert model_adult.age == hbaidata.age
            if( override_se_and_wage_with_hbai )
                model_adult.income_wages = hbaidata.wages
                model_adult.income_self_employment_income = hbaidata.selfemp
                model_adult.income_self_employment_losses = 0.0
                model_adult.income_self_employment_expenses = 0.0
            end
            #
            # new - assign a total earnings/se figure from both hbai and frs
            # so we can compare the two. This is in reaction to the 
            # oddly low Gini/Palma when using HBAI/SPI'd earnings
            #
            model_adult.wages_hbai = hbaidata.wages
            model_adult.self_emp_hbai = hbaidata.selfemp
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
            if frs_person.rentprof == 2 # it's a loss
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
            model_adult.income_alimony_and_child_support_recieved,
            model_adult.income_alimony_and_child_support_paid = map_alimony(
                frs_person,
                a_maint
            )

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
            model_adult.registered_blind = (frs_person.spcreg1 == 1 ? 1 : 0)
            model_adult.registered_partially_sighted = (frs_person.spcreg2 == 1 ? 1 : 0)
            model_adult.registered_deaf = (frs_person.spcreg3 == 1 ? 1 : 0)

            model_adult.disability_vision = (frs_person.disd01 == 1 ? 1 : 0) # cdisd kids ..
            model_adult.disability_hearing = (frs_person.disd02 == 1 ? 1 : 0)
            model_adult.disability_mobility = (frs_person.disd03 == 1 ? 1 : 0)
            model_adult.disability_dexterity = (frs_person.disd04 == 1 ? 1 : 0)
            model_adult.disability_learning = (frs_person.disd05 == 1 ? 1 : 0)
            model_adult.disability_memory = (frs_person.disd06 == 1 ? 1 : 0)
            model_adult.disability_mental_health = (frs_person.disd07 == 1 ? 1 : 0)
            model_adult.disability_stamina = (frs_person.disd08 == 1 ? 1 : 0)
            model_adult.disability_socially = (frs_person.disd09 == 1 ? 1 : 0)
            model_adult.disability_other_difficulty = (frs_person.disd10 == 1 ? 1 : 0)

            model_adult.has_long_standing_illness = (frs_person.health1 == 1 ? 1 : 0)
            model_adult.how_long_adls_reduced = (frs_person.limitl < 0 ? -1 : frs_person.limitl)
            model_adult.adls_are_reduced = (frs_person.condit < 0 ? -1 : frs_person.condit) # missings to 'not at all'

            model_adult.age_started_first_job = safe_assign( frs_person.jobbyr )
            # 2017/18 only
            if year >= 2017
                model_adult.type_of_bereavement_allowance = safe_assign( frs_person.wid )
            end
            model_adult.had_children_when_bereaved = safe_assign( frs_person.w2 )

            # dindividual_savings_accountbility_other_difficulty = Vector{Union{Real,Missing}}(missing, n),
            model_adult.health_status = safe_assign(frs_person.heathad)
            model_adult.hours_of_care_received = safe_inc(0.0, frs_person.hourcare)
            model_adult.hours_of_care_given = infer_hours_of_care(frs_person.hourtot) # also kid

            model_adult.is_informal_carer = (frs_person.carefl == 1 ? 1 : 0) # also kid
            process_relationships!( model_adult, frs_person )
            #
            # illness benefit levels
            # See the note on this in docs/
            model_adult.dlaself_care_type = map123( model_adult.income_dlaself_care, [30, 60 ] )
            model_adult.dlamobility_type = map123(model_adult.income_dlamobility, [30] )
            model_adult.attendance_allowance_type = map123( model_adult.income_attendance_allowance, [65] )
            model_adult.personal_independence_payment_daily_living_type = map12( model_adult.income_personal_independence_payment_daily_living, 65 )
            model_adult.personal_independence_payment_mobility_type  = map12( model_adult.income_personal_independence_payment_mobility, 30 )            
        end # if in HBAI
    end # adult loop
    println("final adno $adno")
    return adult_model[1:adno, :]
end # proc create_adult

#
# FIXME This doesn't drop children from hhls dropped from the HBAI; harmless but it confused me ...
#
function create_children(
    year::Integer,
    frs_children::DataFrame,
    childcare::DataFrame,
    hbai_res::DataFrame,
    benefits:: DataFrame
)::DataFrame
    num_children = size(frs_children)[1]
    child_model = initialise_person(num_children)
    ccount = 0
    for chno in 1:num_children
        if chno % 1000 == 0
            println("on year $year, chno $chno")
        end
        frs_person = frs_children[chno, :]
        if is_in_hbai( hbai_res, frs_person.sernum )

            a_childcare = childcare[((childcare.sernum.==frs_person.sernum).&(childcare.benunit.==frs_person.benunit).&(childcare.person.==frs_person.person)), :]
            nchildcares = size(a_childcare)[1]

            sernum = frs_person.sernum
            ccount += 1
                ## also for children
            model_child = child_model[ccount, :]

            model_child.pno = frs_person.person
            model_child.hid = frs_person.sernum
            model_child.pid = get_pid(FRS, year, frs_person.sernum, frs_person.person)
            model_child.from_child_record = 1

            model_child.data_year = year
            model_child.default_benefit_unit = frs_person.benunit
            model_child.age = frs_person.age
            model_child.sex = safe_assign(frs_person.sex)
            # model_child.ethnic_group = safe_assign(frs_person.ethgr3)
            ## also for child
            # println( "frs_person.chlimitl='$(frs_person.chlimitl)'")
            model_child.has_long_standing_illness = (frs_person.chealth1 == 1 ? 1 : 0)
            model_child.how_long_adls_reduced = (frs_person.chlimitl < 0 ? -1 : frs_person.chlimitl)
            model_child.adls_are_reduced = (frs_person.chcond < 0 ? -1 : frs_person.chcond) # missings to 'not at all'
            model_child.over_20_k_saving = 0

            model_child.registered_blind = (frs_person.spcreg1 == 1 ? 1 : 0)
            model_child.registered_partially_sighted = (frs_person.spcreg2 == 1 ? 1 : 0)
            model_child.registered_deaf = (frs_person.spcreg3 == 1 ? 1 : 0)

            model_child.disability_vision = (frs_person.cdisd01 == 1 ? 1 : 0) # cdisd kids ..
            model_child.disability_hearing = (frs_person.cdisd02 == 1 ? 1 : 0)
            model_child.disability_mobility = (frs_person.cdisd03 == 1 ? 1 : 0)
            model_child.disability_dexterity = (frs_person.cdisd04 == 1 ? 1 : 0)
            model_child.disability_learning = (frs_person.cdisd05 == 1 ? 1 : 0)
            model_child.disability_memory = (frs_person.cdisd06 == 1 ? 1 : 0)
            model_child.disability_mental_health = (frs_person.cdisd07 == 1 ? 1 : 0)
            model_child.disability_stamina = (frs_person.cdisd08 == 1 ? 1 : 0)
            model_child.disability_socially = (frs_person.cdisd09 == 1 ? 1 : 0)
            # dindividual_savings_accountbility_other_difficulty = Vector{Union{Real,Missing}}(missing, n),
            model_child.health_status = safe_assign(frs_person.heathch)
            model_child.income_wages = safe_inc( 0.0, frs_person.chearns )
            model_child.income_other_investment_income = safe_inc( 0.0, frs_person.chsave )
            model_child.income_other_income = safe_inc( 0.0, frs_person.chrinc )
            model_child.income_free_school_meals = 0.0
            for t in [:fsbval,:fsfvval,:fsmlkval,:fsmval]
                model_child.income_free_school_meals = safe_inc( model_child.income_free_school_meals, frs_person[t] )
            end
            model_child.is_informal_carer = (frs_person.carefl == 1 ? 1 : 0) # also kid
            process_relationships!( model_child, frs_person )
            # TODO education grants, all the other good child stuff EMA

            model_child.cost_of_childcare = 0.0
            model_child.hours_of_childcare = 0.0
            for c in 1:nchildcares
                if c == 1 # type of care from 1st instance
                    model_child.childcare_type =
                        map_child_care( year, a_childcare[c, :chlook] )
                    model_child.employer_provides_child_care = (a_childcare[c, :emplprov] == 2 ?
                                                                1 : 0)
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
            println( "sb = $sb")
            # @assert sb in [0,1]
            process_benefits!( model_child, a_benefits )
            
        end  # if in HBAI
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
    hbai_res::DataFrame )::DataFrame

    num_households = size(frs_household)[1]
    hh_model = initialise_household(num_households)
    hhno = 0
    # hbai_year = year - 1993

    for hn in 1:num_households
        if hn % 1000 == 0
            println("on year $year, hid $hn")
        end
        hh = frs_household[hn, :]
        sernum = hh.sernum
        if is_in_hbai( hbai_res, hh.sernum ) # only non-missing in HBAI
            ad1_hbai = hbai_res[(hbai_res.sernum.==hh.sernum), :][1,:]
            hhno += 1
            dd = split(hh.intdate, "/")
            hh_model[hhno, :interview_year] = parse(Int64, dd[3])
            interview_month = parse(Int8, dd[1])
            hh_model[hhno, :interview_month] = interview_month
            hh_model[hhno, :quarter] = div(interview_month - 1, 3) + 1

            hh_model[hhno, :hid] = sernum
            hh_model[hhno, :data_year] = year
            hh_model[hhno, :tenure] = hh.tentyp2 > 0 ? hh.tentyp2 : -1
            hh_model[hhno, :dwelling] = hh.typeacc > 0 ? hh.typeacc : -1
            hh_model[hhno, :region] = hh.gvtregn > 0 ? hh.gvtregn : -1
            hh_model[hhno, :ct_band] = hh.ctband > 0 ? hh.ctband : -1
            hh_model[hhno, :weight] = hh.gross4
            # hh_model[hhno, :tenure] = hh.tentyp2 > 0 ? Tenure_Type(hh.tentyp2) :
            #                          Missing_Tenure_Type
            # hh_model[hhno, :region] = hh.gvtregn > 0 ? Standard_Region(hh.gvtregn) :
            #                           Missing_Standard_Region
            # hh_model[hhno, :ct_band] = hh.ctband > 0 ? CT_Band(hh.ctband) : Missing_CT_Band
            #
            # council_tax::Real
            # FIXME this is rounded to £
            if hh_model[hhno, :region] == 299999999 # Scotland
                hh_model[hhno, :water_and_sewerage] = safe_assign(ad1_hbai.cwathh)
            elseif hh_model[hhno, :region] == 399999999 # Nireland
                hh_model[hhno, :water_and_sewerage] = 0.0 # FIXME
            else #
                hh_model[hhno, :water_and_sewerage] = safe_assign(ad1_hbai.watsewhh)
            end
            # hh_model[hhno, :mortgage_payment]
            hh_model[hhno, :mortgage_interest] = ad1_hbai.hbxmort

            # TODO
            # years_outstanding_on_mortgage::Integer
            # mortgage_outstanding::Real
            # year_house_bought::Integer
            # FIXME rounded to £1
            hh_model[hhno, :gross_rent] = max(0.0, hh.hhrent) #  rentg Gross rent including Housing Benefit  or rent Net amount of last rent payment

            rents = renter[(renter.sernum.==sernum), :]
            nrents = size(rents)[1]
            hh_model[hhno, :rent_includes_water_and_sewerage] = false
            for r in 1:nrents
                if (rents[r, :wsinc] in [1, 2, 3])
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
            hh_model[hhno, :bedrooms] = hh.bedroom6
            hh_model[hhno, :onerand] = mybigrandstr()
            hh_model[hhno, :original_gross_income] = hh.hhinc
            # TODO
            # gross_housing_costs::Real
            # total_wealth::Real
            # house_value::Real
            # people::People_Dict
        end
    end
    hh_model[1:hhno, :]
end

#= 

not used anymore

const HBAIS = Dict(
    
    2018 => "h1819.tab",
    2017 => "h1718.tab",
    2016 => "hbai1617_g4.tab",
    2015 => "hbai1516_g4.tab",
    2014 => "hbai1415_g4.tab",
    2013 => "hbai1314_g4.tab",
    2012 => "hbai1213_g4.tab",
    2011 => "hbai1112_g4.tab",
    2010 => "hbai1011_g4.tab",
    2009 => "hbai0910_g4.tab",
    2008 => "hbai0809_g4.tab",
    2007 => "hbai0708_g4.tab",
    2006 => "hbai0607_g4.tab",
    2005 => "hbai0506_g4.tab",
    2004 => "hbai0405_g4.tab",
    2003 => "hbai0304_g4.tab"
)
=#

function loadfrs(which::AbstractString, year::Integer)::DataFrame
    filename = "$(L_FRS_DIR)/$(year)/tab/$(which).tab"
    loadtoframe(filename)
end

function create_data(;start_year::Int, end_year::Int, hbai::String)
    #
    # every time I do this the HBAI has been re-arranged
    # now, there's one file for the years 2015-2019; despite the name
    # the variables we use aren't uprated. See:
    # `5828_hbai_1920_harmonised_dataset_variables_guide.xlsx`
    # in the doc bundle 
    #
    hbai_res = loadtoframe("$(L_HBAI_DIR)/tab/$(hbai).tab")
    # hbai_res = vcat( hbai_res, loadtoframe("$(HBAI_DIR)/tab/i1820e_1920prices.tab"))

    model_households = initialise_household(0)
    model_people = initialise_person(0)
    
    for year in start_year:end_year
        hbai_year = year - 1993
        print("on year $year ")
        appendb = year > 2015
        y = year - 2000
        ystr = "$(y)$(y+1)"
        # we only want this massive thing for a couple of
        # benefit variables.
        #frsx = ""
        # if year < 2019
        frsx = loadfrs( "frs$ystr", year )
        # else
        #    frsx=CSV.File( "$(L_FRS_DIR)/$(year)/tab/frs1920.tab", missingstring=["", " "]) |> DataFrame
        #  
        # end
        accounts = loadfrs("accounts", year)
        adult = loadfrs("adult", year)
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

        model_children_yr = create_children(
            year, 
            child, 
            chldcare, 
            hbai_res[(hbai_res.year .== hbai_year),:], benefits )

        append!(model_people, model_children_yr)
        model_adults_yr = create_adults(
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
            hbai_res[(hbai_res.year .== hbai_year),:],
            frsx )
        append!(model_people, model_adults_yr)
        model_households_yr = create_household(
            year,
            househol,
            renter,
            mortgage,
            mortcont,
            owner,
            hbai_res[(hbai_res.year .== hbai_year),:] )
        append!(model_households, model_households_yr)
        println( "on year $year")
        println( "hhlds")
        # CSV.write("$(MODEL_DATA_DIR)/model_households-$(start_year)-$(end_year).tab", model_households_yr, delim = "\t", append=appendb)
        # println( "adults")
        # CSV.write("$(MODEL_DATA_DIR)/model_people.tab-$(start_year)-$(end_year)", model_adults_yr, delim = "\t", append=appendb)
        # println( "children")
        # CSV.write("$(MODEL_DATA_DIR)/model_people.tab-$(start_year)-$(end_year)", model_children_yr, delim = "\t", append=true)
    end    
    CSV.write("$(MODEL_DATA_DIR)model_households-$(start_year)-$(end_year).tab", model_households, delim = "\t")
    CSV.write("$(MODEL_DATA_DIR)model_people-$(start_year)-$(end_year).tab", model_people, delim = "\t")
end