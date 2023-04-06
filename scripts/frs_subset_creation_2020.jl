#
# Stuff to read FRS and HBAI files into frames and merge them
# a lot of this is just to overcome the weird way I have these stored
# and would need adaption by anyone with a sensible layout who had all the
# files in the one format
# SINGLE (LATEST) year only
#
using ScottishTaxBenefitModel
using DataFrames
using StatFiles
using TableTraits
using CSV
using .Utils
using .Definitions
# using CSVFiles

function loadfrs(which::AbstractString, year::Integer)::DataFrame
    filename = "$(FRS_DIR)/$(year)/tab/$(which).tab"
    loadtoframe(filename)
end

## FIXME Move these and stb versions to libs

function infer_hours_of_care(hourtot::Integer)::Real
    hrs = Dict(
        0 => 0.0,
        1 => 2.0,
        2 => 7.0,
        3 => 14.0,
        4 => 27.5,
        5 => 42.5,
        6 => 75.0,
        7 => 100.0,
        8 => 10.0,
        9 => 27.5,
        10 => 50.0
    )
    h = 0.0
    if hourtot in keys(hrs)
        h = hrs[hourtot]
    end
    h
end

function remapRegion( r :: Integer )
        if r == 112000001 # North East
                r = 1
        elseif r == 112000002 # North West
                r = 2
        # no region 3
        elseif r == 112000003 # Yorks and the Humber
                r = 4
        elseif r == 112000004 # East Midlands
                r = 5
        elseif r == 112000005 # West Midlands
                r = 6
        elseif r == 112000006
                r = 7  # East of England
        elseif r == 112000007 # | London
                r = 8
        elseif r == 112000008 # South East
                r = 9
        elseif r == 112000009 # South West
                r = 10
        elseif r == 399999999 #  wales
                r = 11
        elseif r == 299999999
                r = 12        # Scotland
        elseif r == 499999999 # Northern Ireland
                r = 13
        end
        return r
end

function initialise_person( n::Integer )::DataFrame
    DataFrame(
        frs_year    = Vector{Union{Int64,Missing}}(missing,n),
        household_number  = Vector{Union{Int64,Missing}}(missing,n),
        benefit_unit = Vector{Union{Int8,Missing}}(missing,n),
        person  = Vector{Union{Int8,Missing}}(missing,n),
        government_region  = Vector{Union{Int8,Missing}}(missing,n),
        tenure_type  = Vector{Union{Int8,Missing}}(missing,n), # f enums OK
        household_income = Vector{Union{Real,Missing}}(missing,n),
        benefit_unit_income = Vector{Union{Real,Missing}}(missing,n),
        num_children = Vector{Union{Int8,Missing}}(missing,n),
        num_adults = Vector{Union{Int8,Missing}}(missing,n),
        age = Vector{Union{Int8,Missing}}(missing,n), # age80 - 2005-2012 ; iagegr2 full
        employment_status = Vector{Union{Int8,Missing}}(missing,n),
        sex = Vector{Union{Int8,Missing}}(missing,n),     # full
        marital_status = Vector{Union{Int8,Missing}}(missing,n), # full
        ethnic_group  = Vector{Union{Int8,Missing}}(missing,n), # ethgr3
        years_in_full_time_work =  Vector{Union{Int64,Missing}}(missing,n), # ftwk
        age_completed_full_time_education = Vector{Union{Int64,Missing}}(missing,n), # tea
        socio_economic_grouping = Vector{Union{Real,Missing}}(missing,n), # FIXME Really a Decimal nssc
        highest_qualification = Vector{Union{Int8,Missing}}(missing,n), # 2008-11
        occupational_classification = Vector{Union{Int64,Missing}}(missing,n),
        registered_blind_or_deaf = Vector{Union{Int8,Missing}}(missing,n), # full years
        any_disability = Vector{Union{Int8,Missing}}(missing,n), # disd01..09
        health_status = Vector{Union{Int8,Missing}}(missing,n), # heathad
        hours_of_care_received = Vector{Union{Real,Missing}}(missing,n), # full
        hours_of_care_given = Vector{Union{Real,Missing}}(missing,n), # f
        is_informal_carer = Vector{Union{Int8,Missing}}(missing,n), # carefl
        employment_earnings = Vector{Union{Real,Missing}}(missing,n), # 07-08 missing
        self_employment_income = Vector{Union{Real,Missing}}(missing,n),
        in_poverty = Vector{Union{Int8,Missing}}(missing,n), # low60ahc hbai adult
        happiness = Vector{Union{Int8,Missing}}(missing,n), # happywb adult
        in_debt_now = Vector{Union{Int8,Missing}}(missing,n),
        in_debt_in_last_year = Vector{Union{Int8,Missing}}(missing,n),
        total_hours_worked  = Vector{Union{Real,Missing}}(missing,n),
    )
end

function create_adults(
        year         :: Integer,
        hhld         :: DataFrame,
        benunit      :: DataFrame,
        frs_adults   :: DataFrame,
        hbai_adults  :: DataFrame )

        num_adults = size(frs_adults)[1]
        adult_model = initialise_person(num_adults)
        adno = 0
        hbai_year = year - 1993
        println("hbai_year $hbai_year")
        for pn in 1:num_adults
            if pn % 1000 == 0
                println("adults: on year $year, pno $pn")
            end

            single_person = frs_adults[pn, :]
            sernum = single_person.sernum
            matching_hbai = hbai_adults[((hbai_adults.year.==hbai_year).&(hbai_adults.sernum.==sernum).&(hbai_adults.person.==single_person.person).&(hbai_adults.benunit.==single_person.benunit)), :]
            matching_hhld = hhld[ single_person.sernum .==  hhld.sernum,:]
            matching_benunit = benunit[ ((single_person.sernum .==  benunit.sernum).&(single_person.benunit.==benunit.benunit)),:]
            # print( "matching_benunit=$(matching_benunit)\n" )
            @assert size( matching_benunit)[1] == 1
            @assert size( matching_hhld )[1] == 1
            nhbai = size(matching_hbai)[1]
            @assert nhbai in [0, 1]

            if nhbai == 1 # only non-missing in HBAI
                adno += 1
                    ## also for children
                output_adult = adult_model[adno, :]
                # 'single' here just extracts 1 row and allows us to treat
                # it like a tuple/struct
                single_hbai = matching_hbai[1,:]
                single_hhld = matching_hhld[1,:]
                single_benunit = matching_benunit[1,:]
                output_adult.tenure_type = safe_assign( single_hhld.tentyp2 )
                output_adult.government_region = remapRegion( single_hhld.gvtregn )
                output_adult.frs_year = year
                output_adult.benefit_unit = single_benunit.benunit
                output_adult.household_income = single_hbai.esninchh
                output_adult.benefit_unit_income = single_hbai.esnincbu
                output_adult.person = single_person.person
                output_adult.household_number = single_person.sernum
                output_adult.household_number = single_person.sernum
                output_adult.num_children = single_hbai.depchldh
                output_adult.num_adults =  single_hbai.adulth
                is_hbai_spouse = ( single_hbai.personsp == single_hbai.person )
                is_hbai_head = ( single_hbai.personhd == single_hbai.person )

                output_adult.age = single_person.age80
                output_adult.sex = safe_assign(single_person.sex)
                output_adult.ethnic_group = safe_assign(single_person.ethgr3)
                # plan 'B' wages and SE from HBAI; first work out hd/spouse so we can extract right ones
                ## adult only

                output_adult.marital_status = safe_assign(single_person.marital)
                output_adult.highest_qualification = safe_assign(single_person.dvhiqual)

                output_adult.socio_economic_grouping = safe_assign(Integer(trunc(single_person.nssec)))
                output_adult.age_completed_full_time_education = safe_assign(single_person.tea)
                output_adult.years_in_full_time_work = safe_inc(0, single_person.ftwk)
                output_adult.employment_status = safe_assign(single_person.empstati)
                output_adult.occupational_classification = safe_assign(single_person.soc2010)
                hbai_wages = coalesce( is_hbai_head ? single_hbai.esgjobhd : single_hbai.esgjobsp, 0.0 )
                hbai_se = coalesce( is_hbai_head ? single_hbai.esgrsehd : single_hbai.esgrsesp, 0.0 )
                output_adult.employment_earnings = hbai_wages
                output_adult.self_employment_income = hbai_se
                ## also for child
                output_adult.registered_blind_or_deaf =
                    ((single_person.spcreg1 == 1 ) ||
                     (single_person.spcreg2 == 1 ) ||
                     (single_person.spcreg3 == 1)) ? 1 : 0

                output_adult.any_disability = (
                    (single_person.disd01 == 1) || # cdisd kids ..
                    (single_person.disd02 == 1) ||
                    (single_person.disd03 == 1) ||
                    (single_person.disd04 == 1) ||
                    (single_person.disd05 == 1) ||
                    (single_person.disd06 == 1) ||
                    (single_person.disd07 == 1) ||
                    (single_person.disd08 == 1) ||
                    (single_person.disd09 == 1)) ? 1 : 0


                # dindividual_savings_accountbility_other_difficulty = Vector{Union{Real,Missing}}(missing, n),
                output_adult.health_status = safe_assign(single_person.heathad)
                output_adult.hours_of_care_received = safe_inc(0.0, single_person.hourcare)
                output_adult.hours_of_care_given = infer_hours_of_care(single_person.hourtot) # also kid

                output_adult.is_informal_carer = (single_person.carefl == 1 ? 1 : 0) # also kid
                output_adult.in_poverty =  single_hbai.low60ahc == 1

                output_adult.in_debt_now = (
                    (single_benunit.debt01 == 1 ) ||
                    (single_benunit.debt02 == 1 ) ||
                    (single_benunit.debt03 == 1 ) ||
                    (single_benunit.debt04 == 1 ) ||
                    (single_benunit.debt05 == 1 ) ||
                    (single_benunit.debt06 == 1 ) ||
                    (single_benunit.debt07 == 1 ) ||
                    (single_benunit.debt08 == 1 ) ||
                    (single_benunit.debt09 == 1 ) ||
                    (single_benunit.debt10 == 1 ) ||
                    (single_benunit.debt11 == 1 ) ||
                    (single_benunit.debt12 == 1 ) ||
                    (single_benunit.debt13 == 1 )) ? 1 : 0
                output_adult.in_debt_in_last_year = (
                    (single_benunit.debtar01 == 1 ) ||
                    (single_benunit.debtar02 == 1 ) ||
                    (single_benunit.debtar03 == 1 ) ||
                    (single_benunit.debtar04 == 1 ) ||
                    (single_benunit.debtar05 == 1 ) ||
                    (single_benunit.debtar06 == 1 ) ||
                    (single_benunit.debtar07 == 1 ) ||
                    (single_benunit.debtar08 == 1 ) ||
                    (single_benunit.debtar09 == 1 ) ||
                    (single_benunit.debtar10 == 1 ) ||
                    (single_benunit.debtar11 == 1 ) ||
                    (single_benunit.debtar12 == 1 ) ||
                    (single_benunit.debtar13 == 1 )) ? 1 : 0
                output_adult.happiness =  safe_assign(single_person.happywb)
                output_adult.total_hours_worked = safe_assign(single_person.tothours )
            end # if in HBAI
        end # adult loop
        println("final adno $adno")
        adult_model[1:adno, :]

end


hbai_adults = loadtoframe("$(HBAI_DIR)/tab/i1718_all.tab")
output_adults = initialise_person(0)

for year in 2017:2017

    print("on year $year ")

    ## hbf = HBAIS[year]
    ## hbai_adults = loadtoframe("$(HBAI_DIR)/tab/$hbf")
    househol =loadfrs("househol", year)
    benunit = loadfrs("benunit", year)
    adult = loadfrs("adult", year)

    output_adults_yr = create_adults(
        year,
        househol,
        benunit,
        adult,
        hbai_adults
    )
    append!(output_adults, output_adults_yr)
end

CSV.write( "/mnt/data/teaching/frs/2019J/data/dd309_frs_adults_2017.tab" ,
    output_adults, delim = "\t",  nastring="")
