const DEFAULT_TARGETS_WALES_2023 = [
    741_397,#,1,M- Total in employment- aged 16+ July 2022 – see LFS\ headline indicators.xls m/f scottish tabs
    27_857,#,2,M- Total unemployed- aged 16+
    681_577,#,3,F- Total in employment- aged 16+
    19_354,#,4,F- Total unemployed- aged 16+
    137_862,#,5,Registered Social Landlord (Number) (4)
    969_590,#,6,Owner occupied (Number) (5)
    198_186,#,7,Privately rented (Number) 
    77_354, # 8, M - age 0:4
    90_815, # 9, M - age 5:9
    116_101, # 10, M - age 10:15
    72_723, # 11, M - age 16:19
    107_446, # 12, M - age 20:24
    107_237, # 13, M - age 25:29
    104_220, # 14, M - age 30:34
    93_688, # 15, M - age 35:39
    89_308, # 16, M - age 40:44
    85_935, # 17, M - age 45:49
    103_099, # 18, M - age 50:54
    108_620, # 19, M - age 55:59
    100_729, # 20, M - age 60:64
    88_183, # 21, M - age 65:69
    84_431, # 22, M - age 70:74
    68_883, # 23, M - age 75:79
    74_360, # 24, M - age 80:1000
    73_577, # 25, F - age 0:4
    86_386, # 26, F - age 5:9
    110_227, # 27, F - age 10:15
    68_438, # 28, F - age 16:19
    96_524, # 29, F - age 20:24
    98_837, # 30, F - age 25:29
    103_459, # 31, F - age 30:34
    95_806, # 32, F - age 35:39
    92_464, # 33, F - age 40:44
    89_987, # 34, F - age 45:49
    109_954, # 35, F - age 50:54
    115_977, # 36, F - age 55:59
    107_128, # 37, F - age 60:64
    93_949, # 38, F - age 65:69
    90_841, # 39, F - age 70:74
    77_438, # 40, F - age 75:79
    105_846, # 41, F - age 80:1000
    456_315.625,#,42,1 person
    432_153.5625,#,43,2 person no kids
    96_324.793945,#,44,"1 adult, 1+ child"
    135_747.022461,#,45,3+ person (No children) 
    269_543.250001,#,47,2+adults w children
    58_454,#,49,CARERS
    93_520,#,50,AA
    305_007,#,51,PIP/DLA
    302_261,#,83,% all in employment who are - 2: professional occupations (SOC2010)
    213_725,#,84,% all in employment who are - 3: associate prof & tech occupations (SOC2010)
    140_825,#,85,% all in employment who are - 4: administrative and secretarial occupations (SOC2010)
    152_603,#,86,% all in employment who are - 5: skilled trades occupations (SOC2010)
    143_160,#,87,"% all in employment who are - 6: caring, leisure and other service occupations (SOC2010)"
    107_015,#,88,% all in employment who are - 7: sales and customer service occupations (SOC2010)
    86_607,#,89,"% all in employment who are - 8: process, plant and machine operatives (SOC2010)"
    154_837 #,90,% all in employment who are - 9: elementary occupations (SOC2010)
]


function initialise_target_dataframe_wales_2023( n :: Integer ) :: DataFrame
    df = DataFrame(
        m_total_in_employment = zeros(n),
        m_total_unemployed = zeros(n),
        # m_total_economically_inactive = zeros(n),
        f_total_in_employment = zeros(n),
        f_total_unemployed = zeros(n),
        # f_total_economically_inactive = zeros(n),
        # owner_occupied = zeros(n),
        housing_association = zeros(n),
        owner_occupied = zeros(n),
        private_rented_plus_rent_free = zeros(n),
        m_0_4 = zeros(n),
        m_5_9 = zeros(n),
        m_10_15 = zeros(n), # note uneven gaps here
        m_16_19 = zeros(n),
        m_20_24 = zeros(n),
        m_25_29 = zeros(n),
        m_30_34 = zeros(n),
        m_35_39 = zeros(n),
        m_40_44 = zeros(n),
        m_45_49 = zeros(n),
        m_50_54 = zeros(n),
        m_55_59 = zeros(n),
        m_60_64 = zeros(n),
        m_65_69 = zeros(n),
        m_70_74 = zeros(n),
        m_75_79 = zeros(n),
        m_80_plus = zeros(n),
        f_0_4 = zeros(n),
        f_5_9 = zeros(n),
        f_10_15 = zeros(n),
        f_16_19 = zeros(n),
        f_20_24 = zeros(n),
        f_25_29 = zeros(n),
        f_30_34 = zeros(n),
        f_35_39 = zeros(n),
        f_40_44 = zeros(n),
        f_45_49 = zeros(n),
        f_50_54 = zeros(n),
        f_55_59 = zeros(n),
        f_60_64 = zeros(n),
        f_65_69 = zeros(n),
        f_70_74 = zeros(n),
        f_75_79 = zeros(n),
        f_80_plus = zeros(n),
        v_1_adult = zeros(n),
        v_2_adults = zeros(n),
        v_1_adult_1_plus_children = zeros(n),
        v_3_plus_adults = zeros(n),
        v_2_plus_adults_1_plus_children = zeros(n),
        ca = zeros(n),
        aa = zeros(n),
        pip_or_dla = zeros(n),
        # omit  Managers_Directors_and_Senior_Officials
        Soc_Professional_Occupations = zeros(n),	#	83	% all in employment who are - 2: professional occupations (SOC2010)
        Soc_Associate_Prof_and_Technical_Occupations = zeros(n),	#	84	% all in employment who are - 3: associate prof & tech occupations (SOC2010)
        Soc_Admin_and_Secretarial_Occupations = zeros(n),	#	85	% all in employment who are - 4: administrative and secretarial occupations (SOC2010)
        Soc_Skilled_Trades_Occupations = zeros(n),	#	86	% all in employment who are - 5: skilled trades occupations (SOC2010)
        Soc_Caring_leisure_and_other_service_occupations = zeros(n),	#	87	% all in employment who are - 6: caring, leisure and other service occupations (SOC2010)
        Soc_Sales_and_Customer_Service = zeros(n),	#	88	% all in employment who are - 7: sales and customer service occupations (SOC2010)
        Soc_Process_Plant_and_Machine_Operatives = zeros(n),  	#	89	% all in employment who are - 8: process, plant and machine operatives (SOC2010)
        Soc_Elementary_Occupations = zeros(n)     #   90  % all in employment who are - 9: elementary occupations (SOC2010) 
    )
    return df
end

function make_target_row_wales_2023!( row :: DataFrameRow, hh :: Household )
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

