
const DEFAULT_TARGETS_SCOTLAND_2022 = [
    1_347_880.73,	#	1	M- Total in employment- aged 16+ July 2022 – see LFS\ headline indicators.xls m/f scottish tabs
    63_487.44,	#	2	M- Total unemployed- aged 16+
    1_352_983.44,	#	3	F- Total in employment- aged 16+
    35_890.28,	#	4	F- Total unemployed- aged 16+
    396_292.1,	#	5	private rented+rent free
    292_100.2,	#	6	housing association
    317_656.5,	#	7	las etc rented
    125_921.40,	#	8	M – 0 - 4
    147_410.39,	#	9	5 - 9
    186_088.58,	#	10	10 – 15
    103_761.46,	#	11	16 - 19
    151_956.50,	#	12	20 - 24
    177_806.87,	#	13	25 - 29
    189_613.07,	#	14	 30 - 34
    174_449.43,	#	15	 35 - 39
    165_566.56,	#	16	40 - 44
    156_883.79,	#	17	 45 - 49
    181_617.65,	#	18	 50 - 54
    191_912.96,	#	19	 55 - 59
    176_250.87,	#	20	 60 - 64
    148_622.84,	#	21	 65 - 69
    130_764.75,	#	22	 70 - 74
    99_683.51,	#	23	 75 - 79
    102_280.18,	#	24	80+
    119_487.43,	#	25	F – 0 - 4
    139162.75,	#	26	5 - 9
    178360.88,	#	27	10 – 15
    94149.95,	#	28	16 - 19
    146720.30,	#	29	20 - 24
    175980.22,	#	30	25 - 29
    193729.51,	#	31	 30 - 34
    182677.55,	#	32	 35 - 39
    173862.68,	#	33	40 - 44
    165536.58,	#	34	 45 - 49
    198225.35,	#	35	 50 - 54
    206606.40,	#	36	 55 - 59
    189092.45,	#	37	 60 - 64
    161055.78,	#	38	 65 - 69
    144934.45,	#	39	 70 - 74
    117987.97,	#	40	 75 - 79
    149195.50,	#	41	80+
    472953.00,	#	42	 # 42 - 1 adult: male
    455762.00,	#	43	 # 43 - 1 adult: female
    804_003.00,	#	44	 # 44 - 2 adults
    157_469.00,	#	45	 # 45 - 1 adult 1+ child
    439_658.00,	#	47	 # 47 - 2+ adults 1+ children
    208_126.00,	#	48	 # 48 - 3+ adults
    80_383.00,	#	49	CARERS
    123_909.00,	#	50	AA
    428_125.00,	#	51	PIP/DLA
    114_078.76,	#	52	 # S12000034 - 52 Aberdeenshire  
    54_620.52,	#	53	 # S12000041 - Angus  
    41_607.77,	#	54	 # S12000035 - Argyll and Bute  
    24_6540.44,	#	55	 # S12000036 - City of Edinburgh  
    24_138.19,	#	56	 # S12000005 - Clackmannanshire  
    69930.18,	#	57	 # S12000006 - Dumfries and Galloway  
    71266.65,	#	58	 # S12000042 - Dundee City  
    55757.16,	#	59	 # S12000008 - East Ayrshire  
    46916.83,	#	60	 # S12000045 - East Dunbartonshire  
    48217.59,	#	61	 # S12000010 - East Lothian  
    40304.71,	#	62	 # S12000011 - East Renfrewshire  
    74175.94,	#	63	 # S12000014 - Falkirk  
    171156.22,	#	64	 # S12000047 - Fife  
    300829.79,	#	65	 # S12000049 - Glasgow City  
    111066.78,	#	66	 # S12000017 - Highland  
    37340.41,	#	67	 # S12000018 - Inverclyde  
    41684.58,	#	68	 # S12000019 - Midlothian  
    43669.41,	#	69	 # S12000020 - Moray  
    12774.80,	#	70	 # S12000013 - Na h-Eileanan Siar  
    64256.52,	#	71	 # S12000021 - North Ayrshire  
    154606.93,	#	72	 # S12000050 - North Lanarkshire  
    10773.99,	#	73	 # S12000023 - Orkney Islands  
    70140.47,	#	74	 # S12000048 - Perth and KinroS  
    88474.37,	#	75	 # S12000038 - Renfrewshire  
    55464.62,	#	76	 # S12000026 - Scottish Borders  
    10565.88,	#	77	 # S12000027 - Shetland Islands  
    52978.43,	#	78	 # S12000028 - South Ayrshire  
    149931.06,	#	79	 # S12000029 - South Lanarkshire  
    40765.49,	#	80	 # S12000030 - Stirling  
    43222.73,	#	81	 # S12000039 - West Dunbartonshire  
    81415.06,	#	82	 # S12000040 - West Lothian  
    657_107.48,	#	83	% all in employment who are - 2: professional occupations (SOC2010)
    425_792.91,	#	84	% all in employment who are - 3: associate prof & tech occupations (SOC2010)
    271_866.28,	#	85	% all in employment who are - 4: administrative and secretarial occupations (SOC2010)
    247_450.33,	#	86	% all in employment who are - 5: skilled trades occupations (SOC2010)
    256_792.08,	#	87	% all in employment who are - 6: caring, leisure and other service occupations (SOC2010)
    230_889.95,	#	88	% all in employment who are - 7: sales and customer service occupations (SOC2010)
    144_372.57,	#	89	% all in employment who are - 8: process, plant and machine operatives (SOC2010)
    272_503.22 ]	#	90	% all in employment who are - 9: elementary occupations (SOC2010)

    const NUM_HOUSEHOLDS_SCOTLAND_2022 = sum( DEFAULT_TARGETS_SCOTLAND_2022[42:48]) # 2_537_971

    function initialise_target_dataframe_scotland_2022( n :: Integer ) :: DataFrame
        df = DataFrame(
            m_total_in_employment = zeros(n),
            m_total_unemployed = zeros(n),
            # m_total_economically_inactive = zeros(n),
            f_total_in_employment = zeros(n),
            f_total_unemployed = zeros(n),
            # f_total_economically_inactive = zeros(n),
            # owner_occupied = zeros(n),
            private_rented_plus_rent_free = zeros(n),
            housing_association = zeros(n),
            las_etc_rented = zeros(n),
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
            v_1_adult_male = zeros(n),
            v_1_adult_female = zeros(n),
            v_2_adults = zeros(n),
            v_1_adult_1_plus_children = zeros(n),
            v_2_plus_adults_1_plus_children = zeros(n),
            v_3_plus_adults = zeros(n),
            ca = zeros(n),
            aa = zeros(n),
            pip_or_dla = zeros(n),
            # councils    
            # S12000033 = zeros(n), #  Aberdeen City  # removed for collinearity 
            S12000034 = zeros(n), #  Aberdeenshire  
            S12000041 = zeros(n), #  Angus  
            S12000035 = zeros(n), #  Argyll and Bute  
            S12000036 = zeros(n), #  City of Edinburgh  
            S12000005 = zeros(n), #  Clackmannanshire  
            S12000006 = zeros(n), #  Dumfries and Galloway  
            S12000042 = zeros(n), #  Dundee City  
            S12000008 = zeros(n), #  East Ayrshire  
            S12000045 = zeros(n), #  East Dunbartonshire  
            S12000010 = zeros(n), #  East Lothian  
            S12000011 = zeros(n), #  East Renfrewshire  
            S12000014 = zeros(n), #  Falkirk  
            S12000047 = zeros(n), #  Fife  
            S12000049 = zeros(n), #  Glasgow City  
            S12000017 = zeros(n), #  Highland  
            S12000018 = zeros(n), #  Inverclyde  
            S12000019 = zeros(n), #  Midlothian  
            S12000020 = zeros(n), #  Moray  
            S12000013 = zeros(n), #  Na h-Eileanan Siar  
            S12000021 = zeros(n), #  North Ayrshire  
            S12000050 = zeros(n), #  North Lanarkshire  
            S12000023 = zeros(n), #  Orkney Islands  
            S12000048 = zeros(n), #  Perth and KinroS  
            S12000038 = zeros(n), #  Renfrewshire  
            S12000026 = zeros(n), #  Scottish Borders  
            S12000027 = zeros(n), #  Shetland Islands  
            S12000028 = zeros(n), #  South Ayrshire  
            S12000029 = zeros(n), #  South Lanarkshire  
            S12000030 = zeros(n), #  Stirling  
            S12000039 = zeros(n), #  West Dunbartonshire  
            S12000040 = zeros(n), #  West Lothian
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
    
    function make_target_row_scotland_2022!( row :: DataFrameRow, hh :: Household )
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
            # row.owner_occupied = 1
        elseif hh.tenure == Council_Rented
            row.las_etc_rented = 1
        elseif hh.tenure == Housing_Association
            row.housing_association = 1
        else
            row.private_rented_plus_rent_free = 1
        end
        num_people = num_u_16s+num_male_ads+num_female_ads
        num_adults = num_male_ads+num_female_ads
        if num_people == 1
            if num_male_ads == 1
                row.v_1_adult_male = 1
            else
                row.v_1_adult_female = 1
            end
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
        if hh.council !== :S12000033 
            # aberdeen city, dropped to avoid collinearity, otherwise ...
            row[hh.council] = 1
        end
    end
    