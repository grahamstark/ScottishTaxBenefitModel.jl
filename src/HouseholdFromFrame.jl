module HouseholdFromFrame

using DataFrames
using CSVFiles

using ScottishTaxBenefitModel
using .Definitions
using .ModelHousehold
using .TimeSeriesUtils
using .HistoricBenefits: benefit_ratio, HISTORIC_BENEFITS, RATIO_BENS
using .Utils: not_zero_or_missing

export load_hhld_from_frame, map_hhld, create_regression_dataframe

#
# Create the dataframe used in the regressions for (e.g) disability
# by joining the household and person frames, and adding
# some disability fields
#
function create_regression_dataframe(
    model_households :: DataFrame,
    model_people :: DataFrame ) :: DataFrame

    fm = innerjoin( model_households, model_people, on=[:data_year, :hid ] )

    fm.deaf_blind=fm.registered_blind .| fm.registered_deaf .| fm.registered_partially_sighted
    fm.yr = fm.data_year .- 2014
    fm.any_dis = (
        fm.disability_vision .|
        fm.disability_hearing .|
        fm.disability_mobility .|
        fm.disability_dexterity .|
        fm.disability_learning .|
        fm.disability_memory .|
        fm.disability_other_difficulty .|
        fm.disability_mental_health .|
        fm.disability_stamina .|
        fm.disability_socially )
    fm.adls_bad=fm.adls_are_reduced.==1
    fm.adls_mid=fm.adls_are_reduced.==2
    fm.rec_dla = ( fm.income_dlamobility.>0.0) .| ( fm.income_dlaself_care .>0.0 )
    fm.rec_dla_care = ( fm.income_dlaself_care .>0.0 )
    fm.rec_dla_mob = ( fm.income_dlamobility.>0.0 )
    fm.rec_pip = ( fm.income_personal_independence_payment_mobility.>0.0) .| ( fm.income_personal_independence_payment_daily_living .>0.0 )
    fm.rec_pip_care = ( fm.income_personal_independence_payment_daily_living .>0.0 )
    fm.rec_pip_mob = ( fm.income_personal_independence_payment_mobility.>0.0)
    fm.rec_esa = ( fm.income_employment_and_support_allowance.>0.0)
    fm.rec_aa = ( fm.income_attendence_allowance.>0.0)
    fm.rec_carers = ( fm.income_carers_allowance.>0.0)
    fm_rec_aa = ( fm.income_attendence_allowance.>0.0)
    fm.scotland = fm.region .== 299999999
    fm.male = fm.sex .== 1

    return fm
end



function make_benefit_ratios( 
    interview_year :: Integer, 
    interview_month :: Integer,
    mp :: DataFrameRow ) :: Incomes_Dict
    d = Incomes_Dict{Float64}()
    finyear :: Int = fy_from_bits( interview_year, interview_month )

    for target in RATIO_BENS
        dkey = Symbol( "income_$(target)")
        if not_zero_or_missing( mp[dkey])
            d[target] = benefit_ratio( finyear, mp[dkey], target )
        end
    end
    if not_zero_or_missing( mp.income_personal_independence_payment_daily_living )  
        v = mp.income_personal_independence_payment_daily_living
        if v ≈ HISTORIC_BENEFITS[finyear][:pip_daily_daily_living_enhanced]
            d[personal_independence_payment_daily_living] = 1
        elseif v ≈ HISTORIC_BENEFITS[finyear][:pip_daily_daily_living_standard]
            d[personal_independence_payment_daily_living] = 2
        else
            println( "personal_independence_payment_daily_living $finyear $(interview_year) $(interview_month) $v not matched")
        end
    end
    if not_zero_or_missing( mp.income_personal_independence_payment_mobility )    
        v = mp.income_personal_independence_payment_mobility
        if v ≈ HISTORIC_BENEFITS[finyear][:pip_mobility_enhanced]
            d[personal_independence_payment_mobility] = 1
        elseif v ≈ HISTORIC_BENEFITS[finyear][:pip_mobility_standard]
            d[personal_independence_payment_mobility] = 2
        else
            println( "personal_independence_payment_mobility $finyear $v not matched")
        end
    end
    return d
end


function map_person( 
    hh :: Household, 
    model_person :: DataFrameRow, source::DataSource )
    income = Dict{Incomes_Type,Float64}()
    for i in instances(Incomes_Type)
        ikey = make_sym_for_frame("income", i)
        if ! ismissing(model_person[ikey])
            if model_person[ikey] != 0.0
                v = model_person[ikey] # this is a hack because in j 1.3 csv is parsing many cols as strings & I don't understand why
                tv = typeof(v)
                if tv == String # FIXME delete not needed
                    v = parse( Float64, v )
                end
                # println( "setting ikey = $ikey to $v of type $tv")
                income[i] = v
            end
        end
    end
    
    pay_includes  = Included_In_Pay_Dict{Bool}()
    for i in instances(Included_In_Pay_Type)
        s = String(Symbol(i))
        ikey = Symbol(lowercase("pay_includes_" * s))
        if ! ismissing(model_person[ikey])
            if model_person[ikey] == 1
                pay_includes[i] = true
            end
        end
    end
    
    assets = Dict{Asset_Type,Float64}() # fixme asset_type_dict
    for i in instances(Asset_Type)
        if i != Missing_Asset_Type
            ikey = make_sym_for_asset( i )
            if ! ismissing(model_person[ikey])
                v = model_person[ikey]
                if typeof(v) == String
                    v = parse( Float64, v )
                end
                if model_person[ikey] != 0.0
                    assets[i] = model_person[ikey]
                end
            end
        end
    end

    disabilities = Dict{Disability_Type,Bool}()
    for i in instances(Disability_Type)
        ikey = make_sym_for_frame("disability", i)
        if ! ismissing(model_person[ikey])
            if model_person[ikey] == 1
                disabilities[i] = Bool(model_person[ikey])
            end
        end
    end

    bereavement_type = missing 
    if not_zero_or_missing( model_person.income_bereavement_allowance_or_widowed_parents_allowance_or_bereavement ) ||
       not_zero_or_missing( model_person.income_widows_payment )
        if interview_date( hh ) < FY_2017        
            bereavement_type = 2 # widowed parents allow    
        else
            @assert ! ismissing( model_person.type_of_bereavement_allowance )
            bereavement_type = model_person.type_of_bereavement_allowance
        end
    end
    relationships = Relationship_Dict()
    for i in 1:14
        relmod = Symbol( "relationship_$(i)") # :relationship_10 or :relationship_2
        irel = model_person[relmod]
        if (! ismissing( irel )) & ( irel >= 0 )
            pid = get_pid(
                source,
                model_person.data_year,
                model_person.hid,
                i )
            relationships[pid] = Relationship( irel )
        end
    end

    benefit_ratios = make_benefit_ratios( hh.interview_year, hh.interview_month, model_person )

    Person{Float64}(

        BigInt(model_person.hid),  # BigInt# == sernum
        BigInt(model_person.pid),  # BigInt# == unique id (year * 100000)+
        model_person.pno,  # Integer# person number in household
        safe_to_bool(model_person.is_hrp), 
        model_person.default_benefit_unit,  # Integer
        safe_to_bool(model_person.from_child_record), # Bool
        model_person.age,  # Integer
        Sex(model_person.sex),  # Sex
        Ethnic_Group(safe_assign(model_person.ethnic_group)),  # Ethnic_Group
        Marital_Status(safe_assign(model_person.marital_status)),  # Marital_Status
        Qualification_Type(safe_assign(model_person.highest_qualification)),  # Qualification_Type

        SIC_2007(safe_assign(model_person.sic)),  # SIC_2007
        Standard_Occupational_Classification(safe_assign(model_person.occupational_classification)),  # Standard_Occupational_Classification
        Employment_Sector(safe_assign(model_person.public_or_private)),  #  Employment_Sector
        Employment_Type(safe_assign(model_person.principal_employment_type)),  #  Employment_Type

        Socio_Economic_Group(safe_assign(model_person.socio_economic_grouping)),  # Socio_Economic_Group
        m2z(model_person.age_completed_full_time_education),  # Integer
        m2z(model_person.years_in_full_time_work),  # Integer
        ILO_Employment(safe_assign(model_person.employment_status)),  # ILO_Employment
        m2z(model_person.actual_hours_worked),  # Real
        m2z(model_person.usual_hours_worked),  # Real

        m2z(model_person.age_started_first_job),

        income,
        benefit_ratios,
        
        JSAType(safe_assign(model_person.jsa_type)),
        JSAType(safe_assign(model_person.esa_type)),
        
        LowMiddleHigh( safe_assign( model_person.dlaself_care_type )),
        LowMiddleHigh( safe_assign( model_person.dlamobility_type)),
        LowMiddleHigh( safe_assign( model_person.attendence_allowance_type )),
        PIPType( safe_assign( model_person.personal_independence_payment_daily_living_type )),
        PIPType( safe_assign( model_person.personal_independence_payment_mobility_type )),
        BereavementType( safe_assign( bereavement_type )),
        safe_to_bool(model_person.had_children_when_bereaved), 
        assets,
        pay_includes,

        safe_to_bool(model_person.registered_blind),
        safe_to_bool(model_person.registered_partially_sighted),
        safe_to_bool(model_person.registered_deaf),

        disabilities,

        Health_Status(safe_assign(model_person.health_status)),

        safe_to_bool(model_person.has_long_standing_illness),
        ADLS_Inhibited(model_person.adls_are_reduced),
        Illness_Length(model_person.how_long_adls_reduced),

        relationships,
        Relationship(model_person.relationship_to_hoh),
        safe_to_bool(model_person.is_informal_carer),
        safe_to_bool(model_person.receives_informal_care_from_non_householder),
        m2z(model_person.hours_of_care_received),
        m2z(model_person.hours_of_care_given),
        m2z(model_person.hours_of_childcare),
        m2z(model_person.cost_of_childcare),
        Child_Care_Type(safe_assign(model_person.childcare_type )),
        safe_to_bool( model_person.employer_provides_child_care ),

        Fuel_Type( m2z(model_person.company_car_fuel_type )),
        m2z(model_person.company_car_value),
        m2z(model_person.company_car_contribution),
        m2z(model_person.fuel_supplied)

    )

end

function map_hhld( hno::Integer, frs_hh :: DataFrameRow )

    people = People_Dict()
    head_of_household = BigInt(-1) # this is set when we scan the actual people below
    Household{Float64}(
        hno,
        frs_hh.hid,
        frs_hh.interview_year,
        frs_hh.interview_month,
        frs_hh.quarter,
        Tenure_Type(frs_hh.tenure),
        Standard_Region(frs_hh.region),
        CT_Band(frs_hh.ct_band),
        m2z(frs_hh.council_tax),
        m2z(frs_hh.water_and_sewerage ),
        m2z(frs_hh.mortgage_payment),
        m2z(frs_hh.mortgage_interest),
        m2z(frs_hh.years_outstanding_on_mortgage),
        m2z(frs_hh.mortgage_outstanding),
        m2z(frs_hh.year_house_bought),
        m2z(frs_hh.gross_rent),
        safe_to_bool(frs_hh.rent_includes_water_and_sewerage),
        m2z(frs_hh.other_housing_charges),
        m2z(frs_hh.gross_housing_costs),
        m2z(frs_hh.total_income),
        m2z(frs_hh.total_wealth),
        m2z(frs_hh.house_value),
        m2z(frs_hh.weight),
        Symbol( frs_hh.council ),
        Symbol( frs_hh.nhs_board ),
        frs_hh.bedrooms,
        head_of_household,
        people )
end

function load_hhld_from_frame( hseq::Integer, hhld_fr :: DataFrameRow, pers_fr :: DataFrame, source::DataSource ) :: Household
     hh = map_hhld( hseq, hhld_fr )
     pers_fr_in_this_hh = pers_fr[((pers_fr.data_year .== hhld_fr.data_year).&(pers_fr.hid .== hh.hid)),:]
     npers = size( pers_fr_in_this_hh )[1]
     @assert npers in 1:19
     head_of_household = -1
     for p in 1:npers
         pers = map_person( hh, pers_fr_in_this_hh[p,:], source )
         hh.people[pers.pid] = pers
         if pers.relationship_to_hoh == This_Person
            hh.head_of_household = pers.pid
         end
     end
     @assert hh.head_of_household !== -1
     hh
end

end # module
