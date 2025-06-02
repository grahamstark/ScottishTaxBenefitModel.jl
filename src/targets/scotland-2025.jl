
#=
sheet 4 of: data/targets/mar-2025-updates/target-generation.ods
=#
const DEFAULT_TARGETS_SCOTLAND_2025 = [
    1396973.33650263	,	#	1	M- Total in employment- aged 16+ from nomis summary + rescaled for popn projection 24-25
    64874.8	,	#	2	M- Total unemployed- aged 16+
    1335426.8358251	,	#	3	F- Total in employment- aged 16+
    41671.8	,	#	4	F- Total unemployed- aged 16+
    338562.8	,	#	5	private rented+rent free
    295559.9	,	#	6	housing association
    318971.5	,	#	7	las etc rented
    123049.231648,	#	8	M – 0 – 4 HOUSEHOLD ONLY
    138306.066048	,	#	9	5 - 9
    185220.458496	,	#	10	10 – 15
    114657.772688	,	#	11	16 - 19
    162040.5591	,	#	12	20 - 24
    174148.607772	,	#	13	25 - 29
    173357.576433	,	#	14	 30 - 34
    175422.600944	,	#	15	 35 - 39
    170222.00313	,	#	16	40 - 44
    157682.50992	,	#	17	 45 - 49
    169983.234076	,	#	18	 50 - 54
    191095.008325	,	#	19	 55 - 59
    190023.360555	,	#	20	 60 - 64
    164083.503344	,	#	21	 65 - 69
    132220.40598	,	#	22	 70 - 74
    112896.641432	,	#	23	 75 - 79
    111172.14919	,	#	24	80+
    117052.1	,	#	25	F – 0 - 4
    131000.3	,	#	26	5 - 9
    176597.4	,	#	27	10 – 15
    105393.0	,	#	28	16 - 19
    164126.8	,	#	29	20 - 24
    183096.0	,	#	30	25 - 29
    185695.4	,	#	31	 30 - 34
    186892.1	,	#	32	 35 - 39
    182632.7	,	#	33	40 - 44
    166872.3	,	#	34	 45 - 49
    182171.8	,	#	35	 50 - 54
    204498.4	,	#	36	 55 - 59
    203822.3	,	#	37	 60 - 64
    176564.2	,	#	38	 65 - 69
    146086.4	,	#	39	 70 - 74
    130637.4	,	#	40	 75 - 79
    154262.2	,	#	41	80+
    485621.0	,	#	42	 # 42 - 1 adult: male
    461487.0	,	#	43	 # 43 - 1 adult: female
    821558.0	,	#	44	 # 44 - 2 adults
    157479.0	,	#	45	 # 45 - 1 adult 1+ child
    439357.0	,	#	46	 # 47 - 2+ adults 1+ children
    206033.0	,	#	47	 # 48 - 3+ adults
    89620	,	#	48	CARERS
    706572	,	#	49	All Disability
    116323.6	,	#	50	 # S12000034 - 52 Aberdeenshire  
    55050.3	,	#	51	 # S12000041 - Angus  
    41290.1	,	#	52	 # S12000035 - Argyll and Bute  
    253222.8	,	#	53	 # S12000036 - City of Edinburgh  
    24332.2	,	#	54	 # S12000005 - Clackmannanshire  
    70025.3	,	#	55	 # S12000006 - Dumfries and Galloway  
    71427.5	,	#	56	 # S12000042 - Dundee City  
    55836.5	,	#	57	 # S12000008 - East Ayrshire  
    47583.5	,	#	58	 # S12000045 - East Dunbartonshire  
    49565.1	,	#	59	 # S12000010 - East Lothian  
    41216.1	,	#	60	 # S12000011 - East Renfrewshire  
    75553.7	,	#	61	 # S12000014 - Falkirk  
    172710.9	,	#	62	 # S12000047 - Fife  
    304947.7	,	#	63	 # S12000049 - Glasgow City  
    112633.0	,	#	64	 # S12000017 - Highland  
    36942.6	,	#	65	 # S12000018 - Inverclyde  
    43594.4	,	#	66	 # S12000019 - Midlothian  
    44228.3	,	#	67	 # S12000020 - Moray  
    12649.0	,	#	68	 # S12000013 - Na h-Eileanan Siar  
    64188.8	,	#	69	 # S12000021 - North Ayrshire  
    156255.8	,	#	70	 # S12000050 - North Lanarkshire  
    10914.2	,	#	71	 # S12000023 - Orkney Islands  
    71100.2	,	#	72	 # S12000048 - Perth and KinroS  
    89621.8	,	#	73	 # S12000038 - Renfrewshire  
    56104.3	,	#	74	 # S12000026 - Scottish Borders  
    10673.6	,	#	75	 # S12000027 - Shetland Islands  
    53113.0	,	#	76	 # S12000028 - South Ayrshire  
    151812.0	,	#	77	 # S12000029 - South Lanarkshire  
    41633.4	,	#	78	 # S12000030 - Stirling  
    43221.6	,	#	79	 # S12000039 - West Dunbartonshire  
    83687.9	,	#	80	 # S12000040 - West Lothian  
    698093.7	,	#	81	% all in employment who are - 2: professional occupations (SOC2010)
    410667.6	,	#	82	% all in employment who are - 3: associate prof & tech occupations (SOC2010)
    267880.4	,	#	83	% all in employment who are - 4: administrative and secretarial occupations (SOC2010)
    266543.0	,	#	84	% all in employment who are - 5: skilled trades occupations (SOC2010)
    264999.9	,	#	85	% all in employment who are - 6: caring, leisure and other service occupations (SOC2010)
    172208.8	,	#	86	% all in employment who are - 7: sales and customer service occupations (SOC2010)
    160275.6	,	#	87	% all in employment who are - 8: process, plant and machine operatives (SOC2010)
    258107.5	]	#	88	% all in employment who are - 9: elementary occupations (SOC2010)


    const NUM_HOUSEHOLDS_SCOTLAND_2025 = sum( DEFAULT_TARGETS_SCOTLAND_2025[42:48]) # 2_537_971
    
    function make_target_row_scotland_2025!( row :: DataFrameRow, hh :: Household )
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
            if get(pers.income,carers_allowance,0.0) > 0
                row.ca += 1
            end
            if get( pers.income, personal_independence_payment_daily_living, 0.0 ) > 0 ||
               get( pers.income, personal_independence_payment_mobility, 0.0 ) > 0 ||
               get( pers.income, dlaself_care, 0.0 ) > 0 ||
               get( pers.income, dlamobility, 0.0 ) > 0 ||
               get(pers.income,attendance_allowance,0.0) > 0 ### sp!!!!!
               
               row.pip_aa_or_dla += 1
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
    
    function initialise_target_dataframe_scotland_2025( n :: Integer ) :: DataFrame
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
            pip_aa_or_dla = zeros(n),
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
    