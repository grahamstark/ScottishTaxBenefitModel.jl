


function loaddf()::DataFrame
    males = CSV.File( "males-proj-edited.csv")|>DataFrame
    females = CSV.File( "females-proj-edited.csv")|>DataFrame
    popn=hcat(males,females;makeunique=true)
    select!( popn, Not( [:".", :"._1", :"._2", :"year_1", :"._3", "._1_1", "._2_1"]))
    rename!( hhlds, [    
        :"all hhlds" => :v_all_hhlds,
        :"1 person " => :v_1_adult,
        :"2 person (No children) " => :v_2_adults,
        :"2 person (1 adult, 1 child) " => :v_1_adult_1_child, 
        :"3 person (No children) " 
        :"3 person (2 adults, 1 child) "
        :"3 person (1 adult, 2 children) "
        :"4 person (No children) "
        :"4 person (2+ adults, 1+ children) "
        :"4 person (1 adult, 3 children) "
        :"5+ person (No children) "
        :"5+ person (2+ adults, 1+ children) "
        :"5+ person (1 adult, 4+ children) "
        :"total w/kids"
        :"1 adult household with children "
        :"2+ adult household with children "
    ])


    hhlds = CSV.File( "household-projections-by-household-type-and-year-edited.csv")|> DataFrame
    select!( hhlds, Not(:Column1))
    hhlds_long = stack( hhlds, Not(:type))
    hhlds_wide = unstack( hhlds_long, :type, :value )
end

const TARGET_DF :: DataFrame = loaddf()

function initialise_target_dataframe( n :: Integer ) :: DataFrame
    df = DataFrame(
        m_u16 = zeros(n),
        m_age16_64 = zeros(n),
        m_age65_plus = zeros(n), # note uneven gaps here
        f_u16 = zeros(n),
        f_age16_64 = zeros(n),
        f_age65_plus = zeros(n), # note uneven gaps here
        v_1_adult = zeros(n),
        v_2_adults = zeros(n),
        v_1_adult_1_plus_children = zeros(n),
        v_3_plus_adults = zeros(n),
        v_2_plus_adults_1_plus_children = zeros(n)
    )
    return df
end

function make_target_row!( row :: DataFrameRow, hh :: Household )
    num_male_ads = 0
    num_female_ads = 0
    num_u_16s = 0
    for (pid,pers) in hh.people
        if( pers.age < 16 )
            num_u_16s += 1;
        end
        if pers.sex == Male

            if( pers.age >= 16 )
                num_male_ads += 1;
            end
            if pers.employment_status in [
                Full_time_Employee,
                Part_time_Employee,
                Full_time_Self_Employed,
                Part_time_Self_Employed
                ]
                row.m_total_in_employment += 1
            elseif pers.employment_status in [Unemployed]
                row.m_total_unemployed += 1
            else
                # row.m_total_economically_inactive += 1 # delete!
            end
            if pers.age <= 4
                row.m_0_4 += 1
            elseif pers.age <= 9
                row.m_5_9 += 1
            elseif pers.age <= 15
                row.m_10_15 += 1
            elseif pers.age <= 19
                row.m_16_19 += 1
            elseif pers.age <= 24
                row.m_20_24 += 1
            elseif pers.age <= 29
                row.m_25_29 += 1
            elseif pers.age <= 34
                row.m_30_34 += 1
            elseif pers.age <= 39
                row.m_35_39 += 1
            elseif pers.age <= 44
                row.m_40_44 += 1
            elseif pers.age <= 49
                row.m_45_49 += 1
            elseif pers.age <= 54
                row.m_50_54 += 1
            elseif pers.age <= 59
                row.m_55_59 += 1
            elseif pers.age <= 64
                row.m_60_64 += 1
            elseif pers.age <= 69
                row.m_65_69 += 1
            elseif pers.age <= 74
                row.m_70_74 += 1
            elseif pers.age <= 79
                row.m_75_79 += 1
            else
                row.m_80_plus += 1
            end
        else  # female
            if( pers.age >= 16 )
                num_female_ads += 1;
            end
            if pers.employment_status in [
                Full_time_Employee,
                Part_time_Employee,
                Full_time_Self_Employed,
                Part_time_Self_Employed
                ]
                row.f_total_in_employment += 1
            elseif pers.employment_status in [Unemployed]
                row.f_total_unemployed += 1
            else
                # row.f_total_economically_inactive += 1
            end
            if pers.age <= 4
                row.f_0_4 += 1
            elseif pers.age <= 9
                row.f_5_9 += 1
            elseif pers.age <= 15
                row.f_10_15 += 1
            elseif pers.age <= 19
                row.f_16_19 += 1
            elseif pers.age <= 24
                row.f_20_24 += 1
            elseif pers.age <= 29
                row.f_25_29 += 1
            elseif pers.age <= 34
                row.f_30_34 += 1
            elseif pers.age <= 39
                row.f_35_39 += 1
            elseif pers.age <= 44
                row.f_40_44 += 1
            elseif pers.age <= 49
                row.f_45_49 += 1
            elseif pers.age <= 54
                row.f_50_54 += 1
            elseif pers.age <= 59
                row.f_55_59 += 1
            elseif pers.age <= 64
                row.f_60_64 += 1
            elseif pers.age <= 69
                row.f_65_69 += 1
            elseif pers.age <= 74
                row.f_70_74 += 1
            elseif pers.age <= 79
                row.f_75_79 += 1
            else
                row.f_80_plus += 1
            end


        end # female
        if get(pers.income,attendance_allowance,0.0) > 0 ### sp!!!!!
            row.aa += 1
        end
        if get(pers.income,carers_allowance,0.0) > 0
            row.ca += 1
        end
        if get( pers.income, personal_independence_payment_daily_living, 0.0 ) > 0 ||
           get( pers.income, personal_independence_payment_mobility, 0.0 ) > 0 ||
           get( pers.income, dlaself_care, 0.0 ) > 0 ||
           get( pers.income, dlamobility, 0.0 ) > 0
           row.pip_or_dla += 1
       end
       if pers.employment_status in [
            Full_time_Employee,
            Part_time_Employee,
            Full_time_Self_Employed,
            Part_time_Self_Employed
            ]      
            p = pers.occupational_classification      
            @assert p in [
                Undefined_SOC, ## THIS SHOULD NEVER HAPPEN, but does
                Managers_Directors_and_Senior_Officials,
                Professional_Occupations,
                Associate_Prof_and_Technical_Occupations,
                Admin_and_Secretarial_Occupations,
                Skilled_Trades_Occupations,
                Caring_leisure_and_other_service_occupations,
                Sales_and_Customer_Service,
                Process_Plant_and_Machine_Operatives,
                Elementary_Occupations
            
            ] "$p not recognised hhld $(hh.hid) $(hh.data_year) pid $(pers.pid)"
            # FIXME HACK
            if p == Undefined_SOC
                println( "undefined soc for working person pid $(pers.pid)")
                p = Elementary_Occupations
            end
            if p != Managers_Directors_and_Senior_Officials
                psoc = Symbol( "Soc_$(p)")            
                row[psoc] += 1
            end
       end
    end
    if is_owner_occupier(hh.tenure)
        row.owner_occupied = 1
    elseif hh.tenure == Council_Rented
        # row.las_etc_rented = 1
    elseif hh.tenure == Housing_Association
        row.housing_association = 1
    else
        row.private_rented_plus_rent_free = 1
    end
    num_people = num_u_16s+num_male_ads+num_female_ads
    num_adults = num_male_ads+num_female_ads
    if num_people == 1
        row.v_1_adult = 1
    elseif num_adults == 1
        @assert num_u_16s > 0
        row.v_1_adult_1_plus_children = 1
    elseif num_adults == 2 && num_u_16s == 0
        row.v_2_adults = 1
    elseif num_adults > 2 && num_u_16s == 0
        row.v_3_plus_adults = 1
    elseif num_adults >= 2 && num_u_16s > 0
        row.v_2_plus_adults_1_plus_children = 1
    else
        @assert false "should never get here num_male_ads=$num_male_ads num_female_ads=$num_female_ads num_u_16s=$num_u_16s"
    end
    ## las
    #=
    if hh.council !== :S12000033 
        # aberdeen city, dropped to avoid collinearity, otherwise ...
        row[hh.council] = 1
    end
    =#
end

