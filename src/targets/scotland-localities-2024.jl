"""
An include file that helps with generating 2024 local authority
weights using a bunch of Census Scotland datafiles downloaded in Dec 2024.
"""
#= MEMO
 Row │ Authority              authority_code 
     │ String?                Symbol         
─────┼───────────────────────────────────────
   1 │ Aberdeen City          S12000033
   2 │ Aberdeenshire          S12000034
   3 │ Angus                  S12000041
   4 │ Argyll and Bute        S12000035
   5 │ City of Edinburgh      S12000036
   6 │ Clackmannanshire       S12000005
   7 │ Dumfries and Galloway  S12000006
   8 │ Dundee City            S12000042
   9 │ East Ayrshire          S12000008
  10 │ East Dunbartonshire    S12000045
  11 │ East Lothian           S12000010
  12 │ East Renfrewshire      S12000011
  13 │ Falkirk                S12000014
  14 │ Fife                   S12000047
  15 │ Glasgow City           S12000049
  16 │ Highland               S12000017
  17 │ Inverclyde             S12000018
  18 │ Midlothian             S12000019
  19 │ Moray                  S12000020
  20 │ Na h-Eileanan Siar     S12000013
  21 │ North Ayrshire         S12000021
  22 │ North Lanarkshire      S12000050
  23 │ Orkney Islands         S12000023
  24 │ Perth and Kinross      S12000048
  25 │ Renfrewshire           S12000038
  26 │ Scottish Borders       S12000026
  27 │ Shetland Islands       S12000027
  28 │ South Ayrshire         S12000028
  29 │ South Lanarkshire      S12000029
  30 │ Stirling               S12000030
  31 │ West Dunbartonshire    S12000039
  32 │ West Lothian           S12000040
  33 │ Total                  S92000003

=#

function read_census_file(filename::String)::Tuple
    d = (CSV.File( filename; normalizenames=true, header=10, skipto=12)|>DataFrame)
    # if ismissing(d[1,2])
    #     delete!( )
    # end
    label = names(d)[1]
    actuald = d[1:33,2:end]
    nms = names(actuald)
    rename!(actuald,1=>"Authority")
    actuald, label, nms
end

"""
Very, very ad-hoc code to munge together a bunch of Census Scotland datafiles into a
single dataframe.
"""
function read_all_scot_2024( file_dir :: AbstractString )::Tuple
    fs = sort(readdir( file_dir, join=true ))
    n = 0
    merged_census_files = nothing
    rows = 0
    cols = 0
    nfs = length(fs)
    individual_datasets = []
    labels = DataFrame( filename=fill("",nfs), label=fill("",nfs), start=zeros(Int,nfs) )
    for f in fs
        if ! isnothing(match(r".*table.*.csv$",f))
            n += 1
            println( "on $f")
            data, label, nms = read_census_file(f)
            println(nms)
            println(label)
            println(data)
            labels.filename[n] = f
            labels.label[n]=label
            labels.start[n]=cols+2        
            if n == 1
                merged_census_files = deepcopy( data )
            else
                n1 = String.(data[:,1])[1:8] # skip "Na hEileanan Siar", since it's sometimes edited
                n2 = String.(merged_census_files[:,1])[1:8]
                @assert n1 == n2 "$(n1) !== $(n2)" # check in sync
                merged_census_files = hcat( merged_census_files, data; makeunique=true )
                rows,cols = size(merged_census_files)                
            end
            push!(individual_datasets,data)
            # println( "label=$label")
        end
    end
    merged_census_files,labels[1:n,:],individual_datasets
end

"""
More ad-hoc code code to load Census Scotland files, clean them up and
add some constructed fields.
"""
function load_census_2024()
    file_dir = joinpath("/","mnt","data","ScotBen","data", "local", "local_targets_2024" )
    merged_census_files,labels,individual_datasets = read_all_scot_2024( file_dir )
    # FIXME dup
    authority_codes = [
        :S12000033,
        :S12000034,
        :S12000041,
        :S12000035,
        :S12000036,
        :S12000005,
        :S12000006,
        :S12000042,
        :S12000008,
        :S12000045,
        :S12000010,
        :S12000011,
        :S12000014,
        :S12000047,
        :S12000049,
        :S12000017,
        :S12000018,
        :S12000019,
        :S12000020,
        :S12000013,
        :S12000021,
        :S12000050,
        :S12000023,
        :S12000048,
        :S12000038,
        :S12000026,
        :S12000027,
        :S12000028,
        :S12000029,
        :S12000030,
        :S12000039,
        :S12000040,
        :S92000003] # scotland

    DROPS = [
        "Authority_1",
        "Total_1",
        "Authority_2",
        "No_code_required",
        "Authority_3",
        "No_code_required_1",
        "Total_2",
        "Authority_4",
        "Total_3",
        "Authority_5",
        "Total_4",
        "Authority_6",
        "Total_5",
        "Authority_7",
        "Total_6",
        # "Column10",
        "Column11",
        "Authority_9",
        "No_code_required_2",
        "Total_7",
        "Authority_9",
        "Total_8",
        # "Column13",
        "Column14",
        "Authority_10",
        "Total_9",
        # "Column11_1",
        "Column12",
        "Authority_11",
        "Total_10",
        # "Column13_1",
        "Column14_1",
        "Authority_12",
        "Column9",
        "Authority_13",
        "Column9_1",
        "Authority_14",
        "Total_12",
        "Column9_2",
        "Column9_3",
        "Authority_16",
        "Authority_15"]
    
    RENAMES = Dict(
        [
            "Total" => "total_hhlds",
            "Eightor_more_people" => "Eight_or_more_people",
            "Total_11" => "total_people",
            "Owned_Owned_outright" => "owned_outright",
            "Owned_Owned_with_a_mortgage_or_loan" => "mortgaged",
            "Owned_Shared_ownership_part_owned_and_part_rented_" => "shared_ownership",
            "Owned_Shared_Equity_e_g_LIFT_or_Help_to_Buy_" => "shared_equity",
            "Social_Rented_Council_LA_or_Housing_Association_Registered_Social_Landlord" => "socially_rented",
            "Private_rented_Private_landlord_or_letting_agency" => "private_rented",
            "Private_rented_Other" => "private_rented_other",
            "Lives_Rent_Free" => "rent_free",
            "Whole_house_or_bungalow_Detached" => "detached",
            "Whole_house_or_bungalow_Semi_detached" => "semi_detached",
            "Whole_house_or_bungalow_Terraced_including_end_terrace_" => "terraced",
            "Flat_maisonette_or_apartment_Purpose_built_block_of_flats_or_tenement" => "flat_or_maisonette",
            "Flat_maisonette_or_apartment_Part_of_a_converted_or_shared_house_including_bed_sits_" => "converted_flat_1",
            "Flat_maisonette_or_apartment_In_a_commercial_building" => "converted_flat_2",
            "Caravan_or_other_mobile_or_temporary_structure" => "other_accom",
            
            "Economically_active_Employee" => "economically_active_employee",
            "Economically_active_Self_employed" => "economically_active_self_employed",
            "Economically_active_Unemployed" => "economically_active_unemployed",
            "Economically_inactive" => "economically_inactive",
            "Lower_school_qualifications" => "lower_school",
            "Upper_school_qualifications" => "higher_school",
            "Apprenticeship_qualifications" => "apprenticeship",
            "Further_Education_and_sub_degree_Higher_Education_qualifications_incl_HNC_HNDs" => "higher_education",
            "Degree_level_qualifications_or_above_Education_qualifications_not_already_mentioned_including_foreign_qualifications_" => "degree_level",
    
            "One_person_household" => "single_person",
            "One_family_household_Couple_family" => "single_family",
            "One_family_household_Lone_parent" => "single_parent",
            "Other_household_types" => "multi_family",
            "Managers_Directors_and_Senior_Officials" => "Soc_Managers_Directors_and_Senior_Officials",
            "Professional_Occupations" => "Soc_Professional_Occupations",
            "Associate_Professional_and_Technical_Occupations" => "Soc_Associate_Prof_and_Technical_Occupations",
            "Administrative_and_Secretarial_Occupations" => "Soc_Admin_and_Secretarial_Occupations",
            "Skilled_Trade_Occupations" => "Soc_Skilled_Trades_Occupations",
            "Caring_Leisure_and_Other_Service_Occupations" => "Soc_Caring_leisure_and_other_service_occupations",
            "Sales_and_Customer_Service_Occupations" => "Soc_Sales_and_Customer_Service",
            "Process_Plant_and_Machine_Operatives" => "Soc_Process_Plant_and_Machine_Operatives",
            "Elementary_Occupations" => "Soc_Elementary_Occupations",
            "Band_A" => "A",
            "Band_B" => "B",
            "Band_C" => "C",
            "Band_D" => "D",
            "Band_E" => "E",
            "Band_F" => "F",
            "Band_G" => "G",
            "Band_H" => "H"])
            
        # merged_census_files,labels,individual_datasets = read_all_scot_2024()

        ctbase=CSV.File(joinpath( file_dir, "CTAXBASE+2024+-+Tables+-+Chargeable+Dwellings.csv"),normalizenames=true)|>DataFrame
        merged_census_files = hcat( merged_census_files, ctbase; makeunique=true )
        
        rename!( merged_census_files, RENAMES )
        select!( merged_census_files, Not(DROPS))
        merged_census_files.total_cts = sum.(eachrow(merged_census_files[:,[:A,:B,:C,:D,:E,:F,:G,:H]]))
        
        # merged columns 
        merged_census_files.private_rented_rent_free = merged_census_files.private_rented + merged_census_files.rent_free
        merged_census_files.converted_flat_or_other= merged_census_files.converted_flat_1 + merged_census_files.converted_flat_2 + merged_census_files.other_accom
        merged_census_files.all_mortgaged = merged_census_files.mortgaged + merged_census_files.shared_ownership + merged_census_files.shared_equity
        merged_census_files.bedrooms_4_plus = merged_census_files.bedrooms_4 + merged_census_files.bedrooms_5_plus
        merged_census_files.total_tenures = merged_census_files.private_rented_rent_free + 
            merged_census_files.all_mortgaged +
            merged_census_files.socially_rented +
            merged_census_files.owned_outright
        
        merged_census_files.A_C = merged_census_files.A + merged_census_files.B + merged_census_files.C
        merged_census_files.E_H = merged_census_files.E + merged_census_files.F + merged_census_files.G + merged_census_files.H
        

        merged_census_files.Five_plus_people = merged_census_files.Five_people +
                merged_census_files.Six_people +
                merged_census_files.Seven_people +
                merged_census_files.Eight_or_more_people 
        merged_census_files.working = merged_census_files.economically_active_employee + merged_census_files.economically_active_self_employed 
        merged_census_files.authority_code = authority_codes
        
        CSV.write( joinpath(file_dir,"merged_census_labels_2024.tab"), labels; delim='\t')
        CSV.write( joinpath(file_dir,"merged_census_files_2024.tab"), merged_census_files; delim='\t' )
        return merged_census_files
end

"""
No idea how this works, but it does.
see: https://discourse.julialang.org/t/how-to-remove-specific-collumn-from-modelframe-statsmodels-jl/106864/5?u=grahamstark
"""
function near_collinear_cols( m :: Matrix; tol=1e-8)
    qrd = qr(m'm)
    return findall(x-> abs(x) < tol, diag(qrd.R))
end

function near_collinear_cols( d :: DataFrame; tol=1e-8 )::Vector
    m = Matrix(d)
    nms = names(d)
    grps = near_collinear_cols(m; tol=tol)
    return nms[grps]
end 

"""
Create a dataframe with num_households length zeroed entries and all possible
weighting fields.
"""
function initialise_model_dataframe_scotland_la( n :: Integer ) :: DataFrame
    d = DataFrame()
    d.A = zeros(n) #7
    d.B = zeros(n) #5
    d.C = zeros(n) #6
    d.D = zeros(n)
    d.E = zeros(n) #8
    d.F = zeros(n) #9
    d.G = zeros(n) # 10
    d.H = zeros(n) # 11
    d.A_C = zeros(n)
    d.E_H = zeros(n) 

    d.single_person = zeros(n) 
    d.single_parent = zeros(n) 
    d.single_family = zeros(n) 
    d.multi_family = zeros(n) 
    d.One_person = zeros(n) 
    d.Two_people = zeros(n) 
    d.Three_people = zeros(n)
    d.Four_people = zeros(n)
    d.Five_plus_people = zeros(n)
    # d.I = zeros(n) # 12
    # 13
    d.f_0_15  = zeros(n)
    d.f_16_24  = zeros(n)
    d.f_25_34  = zeros(n)
    d.f_35_49 = zeros(n)
    d.f_50_64 = zeros(n)
    d.f_65plus = zeros(n)
    d.m_0_15 = zeros(n)
    d.m_16_24 = zeros(n)
    d.m_25_34 = zeros(n)
    d.m_35_49 = zeros(n)
    d.m_50_64 = zeros(n)
    d.m_65plus = zeros(n)
    d.working = zeros(n)
    d.economically_active_employee  = zeros(n)
    d.economically_active_self_employed  = zeros(n)
    d.economically_inactive  = zeros(n)
    d.Soc_Managers_Directors_and_Senior_Officials=zeros(n)
    d.Soc_Professional_Occupations = zeros(n)	#	83	% all in employment who are - 2: professional occupations (SOC2010)
    d.Soc_Associate_Prof_and_Technical_Occupations = zeros(n)	#	84	% all in employment who are - 3: associate prof & tech occupations (SOC2010)
    d.Soc_Admin_and_Secretarial_Occupations = zeros(n)	#	85	% all in employment who are - 4: administrative and secretarial occupations (SOC2010)
    d.Soc_Skilled_Trades_Occupations = zeros(n)	#	86	% all in employment who are - 5: skilled trades occupations (SOC2010)
    d.Soc_Caring_leisure_and_other_service_occupations = zeros(n)	#	87	% all in employment who are - 6: caring, leisure and other service occupations (SOC2010)
    d.Soc_Sales_and_Customer_Service = zeros(n)	#	88	% all in employment who are - 7: sales and customer service occupations (SOC2010)
    d.Soc_Process_Plant_and_Machine_Operatives = zeros(n)  	#	89	% all in employment who are - 8: process, plant and machine operatives (SOC2010)
    d.Soc_Elementary_Occupations = zeros(n)    #   90  % all in employment who are - 9: elementary occupations (SOC2010) 
    d.owned_outright = zeros(n)
    d.all_mortgaged = zeros(n)
    d.socially_rented = zeros(n)
    d.private_rented_rent_free = zeros(n)
    d.detached = zeros(n)
    d.semi_detached = zeros(n)
    d.terraced = zeros(n)
    d.flat_or_maisonette = zeros(n)
    d.converted_flat_or_other= zeros(n)
    d.bedrooms_1 = zeros(n)
    d.bedrooms_2 = zeros(n)
    d.bedrooms_3 = zeros(n)
    d.bedrooms_4_plus = zeros(n)
    # d.A_B_D_E_Agriculture_energy_and_water = zeros(n)
    #= TODO 
    d.C_Manufacturing = zeros(n)
    d.F_Construction = zeros(n)
    d.G_I_Distribution_hotels_and_restaurants = zeros(n)
    d.H_J_Transport_and_communication = zeros(n)
    d.K_L_M_N_Financial_real_estate_professional_and_administrative_activities  = zeros(n)
    d.O_P_Q_Public_administration_education_and_health = zeros(n)
    =#
    return d    
end

"""

"""
function make_model_dataframe_row!( 
    row :: DataFrameRow, 
    hh :: Household )
    bus = get_benefit_units( hh )
    if is_single(hh)
        row.single_person = 1
    elseif size(bus)[1] > 1
        row.multi_family = 1 
    elseif is_lone_parent(hh) # only dependent children
        row.single_parent = 1
    else
        row.single_family = 1 
    end
    hsize = num_people(hh)
    if hsize == 1
        row.One_person = 1
    elseif hsize == 2
        row.Two_people = 1
    elseif hsize == 3
        row.Three_people = 1
    elseif hsize == 4
        row.Four_people = 1
    elseif hsize >= 5
        row.Five_plus_people = 1
    end
    if hh.ct_band == Band_A
        row.A = 1
        row.A_C = 1
    elseif hh.ct_band == Band_B
        row.B = 1
        row.A_C = 1
    elseif hh.ct_band == Band_C
        row.C = 1
        row.A_C = 1
    elseif hh.ct_band == Band_D
        row.D = 1
    elseif hh.ct_band == Band_E
        row.E = 1
        row.E_H = 1
    elseif hh.ct_band == Band_F
        row.F = 1
        row.E_H = 1
    elseif hh.ct_band == Band_G
        row.G = 1
        row.E_H = 1
    elseif hh.ct_band == Band_H
        row.H = 1
        row.E_H = 1
    elseif hh.ct_band == Band_I
        @assert false "wrong band I for hh=$(hh.hid)"
        # row.I = 1
    else hh.ct_band == Household_not_valued_separately
        row.A = 1 # DODGY!! FIXME
        #
        # @assert false "NO CT BAND"
    end
    # these sum to total people
    for (pid,pers) in hh.people
        if pers.sex == Male
            if pers.age <= 16
                row.m_0_15 += 1
            elseif pers.age <= 24
                row.m_16_24 += 1
            elseif pers.age <= 34
                row.m_25_34 += 1
            elseif pers.age <= 49
                row.m_35_49 += 1
            elseif pers.age <= 64
                row.m_50_64 += 1
            else
                row.m_65plus += 1
            end
        else  # female
            if pers.age <= 16
                row.f_0_15 += 1
            elseif pers.age <= 24
                row.f_16_24 += 1
            elseif pers.age <= 34
                row.f_25_34 += 1
            elseif pers.age <= 49
                row.f_35_49 += 1
            elseif pers.age <= 64
                row.f_50_64 += 1
            else
                row.f_65plus += 1
            end
        end # female
        # drop inactive 
        if ! pers.is_standard_child 
            if pers.employment_status in [Full_time_Employee, Part_time_Employee]
                row.economically_active_employee += 1
                row.working += 1
            elseif pers.employment_status in [
                Full_time_Self_Employed,
                Part_time_Self_Employed ]
                row.working += 1
                row.economically_active_self_employed += 1
            elseif pers.employment_status !== Unemployed
                row.economically_inactive += 1
            end
            if pers.years_in_full_time_work > 0 # no children or people who've never been in work
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
                    Elementary_Occupations] "$p not recognised hhld $(hh.hid) $(hh.data_year) pid $(pers.pid)"
                # FIXME HACK
                if p == Undefined_SOC
                    # println( "undefined soc for working person pid $(pers.pid)")
                    p = rand( [ 
                    Professional_Occupations,
                    Associate_Prof_and_Technical_Occupations,
                    Admin_and_Secretarial_Occupations,
                    Skilled_Trades_Occupations,
                    Caring_leisure_and_other_service_occupations,
                    Sales_and_Customer_Service,
                    Process_Plant_and_Machine_Operatives,
                    Elementary_Occupations ])
                end
                psoc = Symbol( "Soc_$(p)")
                row[psoc] += 1
            end # occupation
            if pers.employment_status in [
                Full_time_Employee,
                Part_time_Employee,
                Full_time_Self_Employed,
                Part_time_Self_Employed
                ]      
                #= TODO
                pers.sic
                # d.A_B_D_E_Agriculture_energy_and_water = zeros(n)
                d.C_Manufacturing = zeros(n)
                d.F_Construction = zeros(n)
                d.G_I_Distribution_hotels_and_restaurants = zeros(n)
                d.H_J_Transport_and_communication = zeros(n)
                d.K_L_M_N_Financial_real_estate_professional_and_administrative_activities  = zeros(n)
                d.O_P_Q_Public_administration_education_and_health = zeros(n)
                =#
            end
        end # adults 
    end # people loop
    if hh.bedrooms == 1
        row.bedrooms_1 = 1
    elseif hh.bedrooms == 2
        row.bedrooms_2 = 1
    elseif hh.bedrooms == 3
        row.bedrooms_3 = 1
    else
        row.bedrooms_4_plus = 1
    end
    if hh.tenure in [Council_Rented, Housing_Association]
        row.socially_rented = 1
    elseif hh.tenure in [Private_Rented_Unfurnished,
        Private_Rented_Furnished,
        Rent_free,
        Squats ]
        row.private_rented_rent_free = 1
    elseif hh.tenure in [Mortgaged_Or_Shared]
        row.all_mortgaged = 1
    elseif hh.tenure == Owned_outright
        row.owned_outright = 1
    end        
    # dwell_na = -1
    if hh.dwelling == detatched
        row.detached = 1
    elseif hh.dwelling == semi_detached
        row.semi_detached = 1
    elseif hh.dwelling == terraced
        row.terraced = 1
    elseif hh.dwelling == flat_or_maisonette
        row.flat_or_maisonette = 1
    else # if hh.dwelling == converted_flat merge other with flat conversion since it's often way out
        row.converted_flat_or_other= 1
    # else 
    #     row.other_accom = 1
    end
end # proc

"""
return a df single row loaded with values for the `council` 
"""
function make_target_list_2024( 
    all_council_data::DataFrameRow, 
    which_included = INCLUDE_ALL )::Tuple 

    included_fields = []
    df = initialise_model_dataframe_scotland_la(1)# a single row
    v = df[1,:]
    # sums to all households
    v.single_person = all_council_data.single_person
    v.single_parent = all_council_data.single_parent
    v.single_family = all_council_data.single_family
    v.multi_family = all_council_data.multi_family  
    v.One_person = all_council_data.One_person
    v.Two_people = all_council_data.Two_people
    v.Three_people = all_council_data.Three_people
    v.Four_people = all_council_data.Four_people
    v.Five_plus_people  = all_council_data.Five_plus_people
    scale = all_council_data.total_hhlds/all_council_data.total_cts # since total cts is always a bit smaller as total hhlds
    v.A = all_council_data.A*scale
    v.B = all_council_data.B*scale
    v.C = all_council_data.C*scale
    v.D = all_council_data.D*scale
    v.E = all_council_data.E*scale
    v.F = all_council_data.F*scale
    v.G = all_council_data.G*scale
    v.H = all_council_data.H*scale
    v.E_H = all_council_data.E_H*scale
    v.A_C = all_council_data.A_C*scale
    
    # sums to all people
    v.f_0_15  = all_council_data.f_0_15 
    v.f_16_24  = all_council_data.f_16_24 
    v.f_25_34  = all_council_data.f_25_34 
    v.f_35_49 = all_council_data.f_35_49
    v.f_50_64 = all_council_data.f_50_64
    v.f_65plus = all_council_data.f_65plus
    v.m_0_15 = all_council_data.m_0_15
    v.m_16_24 = all_council_data.m_16_24
    v.m_25_34 = all_council_data.m_25_34
    v.m_35_49 = all_council_data.m_35_49
    v.m_50_64 = all_council_data.m_50_64
    v.m_65plus = all_council_data.m_65plus
    v.working = all_council_data.working
    # these sum to all adults 
    v.economically_active_employee  = all_council_data.economically_active_employee 
    v.economically_active_self_employed  = all_council_data.economically_active_self_employed 
    v.economically_inactive  = all_council_data.economically_inactive 
    v.Soc_Managers_Directors_and_Senior_Officials = all_council_data.Soc_Managers_Directors_and_Senior_Officials
    v.Soc_Professional_Occupations = all_council_data.Soc_Professional_Occupations
    v.Soc_Associate_Prof_and_Technical_Occupations = all_council_data.Soc_Associate_Prof_and_Technical_Occupations
    v.Soc_Admin_and_Secretarial_Occupations = all_council_data.Soc_Admin_and_Secretarial_Occupations
    v.Soc_Skilled_Trades_Occupations = all_council_data.Soc_Skilled_Trades_Occupations
    v.Soc_Caring_leisure_and_other_service_occupations = all_council_data.Soc_Caring_leisure_and_other_service_occupations
    v.Soc_Sales_and_Customer_Service = all_council_data.Soc_Sales_and_Customer_Service
    v.Soc_Process_Plant_and_Machine_Operatives = all_council_data.Soc_Process_Plant_and_Machine_Operatives
    v.Soc_Elementary_Occupations = all_council_data.Soc_Elementary_Occupations
    v.bedrooms_1 = all_council_data.bedrooms_1
    v.bedrooms_2 = all_council_data.bedrooms_2
    v.bedrooms_3 = all_council_data.bedrooms_3
    v.bedrooms_4_plus = all_council_data.bedrooms_4_plus

    scale2 = all_council_data.total_hhlds/all_council_data.total_tenures # since total TENures is always a bit smaller as total hhlds
    v.owned_outright = all_council_data.owned_outright*scale2
    v.all_mortgaged = all_council_data.all_mortgaged*scale2
    v.socially_rented = all_council_data.socially_rented*scale2
    v.private_rented_rent_free = all_council_data.private_rented_rent_free*scale2
    # detached
    v.detached = all_council_data.detached
    v.semi_detached = all_council_data.semi_detached
    v.terraced = all_council_data.terraced
    v.flat_or_maisonette = all_council_data.flat_or_maisonette
    v.converted_flat_or_other = all_council_data.converted_flat_or_other
    # v.other_accom = all_council_data.other_accom
    #= TODO
    v.C_Manufacturing = all_council_data.C_Manufacturing
    v.F_Construction = all_council_data.F_Construction
    v.G_I_Distribution_hotels_and_restaurants = all_council_data.G_I_Distribution_hotels_and_restaurants
    v.H_J_Transport_and_communication = all_council_data.H_J_Transport_and_communication
    v.K_L_M_N_Financial_real_estate_professional_and_administrative_activities  = all_council_data.K_L_M_N_Financial_real_estate_professional_and_administrative_activities 
    v.O_P_Q_Public_administration_education_and_health = all_council_data.O_P_Q_Public_administration_education_and_health
    if(INCLUDE_INDUSTRY in which_included)
        # v.A_B_D_E_Agriculture_energy_and_water = all_council_data.A_B_D_E_Agriculture_energy_and_water
        push!( included_fields, :C_Manufacturing )
        push!( included_fields, :F_Construction )
        push!( included_fields, :G_I_Distribution_hotels_and_restaurants )
        push!( included_fields, :H_J_Transport_and_communication )
        push!( included_fields, :K_L_M_N_Financial_real_estate_professional_and_administrative_activities  )
        push!( included_fields, :O_P_Q_Public_administration_education_and_health )
    end
    =#
    # FIXME to own function 
    if( INCLUDE_HCOMP in which_included)
        push!( included_fields, :single_person ) 
        # push!( included_fields, :single_parent ) 
        push!( included_fields, :single_family ) 
        push!( included_fields, :multi_family )     
    end
    push!( included_fields, :f_0_15  )
    push!( included_fields, :f_16_24  )
    push!( included_fields, :f_25_34  )
    push!( included_fields, :f_35_49 )
    push!( included_fields, :f_50_64 )
    push!( included_fields, :f_65plus )
    push!( included_fields, :m_0_15 )
    push!( included_fields, :m_16_24 )
    push!( included_fields, :m_25_34 )
    push!( included_fields, :m_35_49 )
    push!( included_fields, :m_50_64 )
    push!( included_fields, :m_65plus )
    if(INCLUDE_EMPLOYMENT in which_included)
        push!( included_fields, :economically_active_employee  ) # collinear with sum if occupation?
        push!( included_fields, :economically_active_self_employed  )
        # push!( included_fields, :economically_inactive  )
    end
    if(INCLUDE_CT in which_included)
        push!( included_fields, :A ) 
        push!( included_fields, :B ) 
        push!( included_fields, :C ) 
        push!( included_fields, :D ) 
        push!( included_fields, :E ) 
        push!( included_fields, :F ) 
        push!( included_fields, :G ) 
        push!( included_fields, :H ) 
    elseif INCLUDE_BROAD_CT in which_included
        push!( included_fields, :A_C ) 
        push!( included_fields, :D ) 
        push!( included_fields, :E_H )         
    end
    if (INCLUDE_HH_SIZE in which_included)
        # one person
        # push!( included_fields, :Two_people )
        push!( included_fields, :Three_people )
        push!( included_fields, :Four_people )
        push!( included_fields, :Five_plus_people  )
    end
    if(INCLUDE_OCCUP in which_included)
        push!( included_fields, :Soc_Managers_Directors_and_Senior_Officials )
        push!( included_fields, :Soc_Professional_Occupations )
        push!( included_fields, :Soc_Associate_Prof_and_Technical_Occupations )
        push!( included_fields, :Soc_Admin_and_Secretarial_Occupations )
        push!( included_fields, :Soc_Skilled_Trades_Occupations )
        push!( included_fields, :Soc_Caring_leisure_and_other_service_occupations )
        push!( included_fields, :Soc_Sales_and_Customer_Service )
        push!( included_fields, :Soc_Process_Plant_and_Machine_Operatives )
        push!( included_fields, :Soc_Elementary_Occupations )
    end
    if(INCLUDE_BEDROOMS in which_included)
        # one bedroom
        push!( included_fields, :bedrooms_2 )
        push!( included_fields, :bedrooms_3 )
        push!( included_fields, :bedrooms_4_plus )
    end
    if(INCLUDE_HOUSING in which_included)
        # owner_occupied
        push!( included_fields, :all_mortgaged )
        push!( included_fields, :socially_rented )
        push!( included_fields, :private_rented_rent_free )
        # detached
        push!( included_fields, :semi_detached )
        push!( included_fields, :terraced )
        push!( included_fields, :flat_or_maisonette )
        push!( included_fields, :converted_flat_or_other )
    end

    av = copy(v)
    println( typeof(v))
    select!( df, included_fields )
    return v,included_fields,av
end






