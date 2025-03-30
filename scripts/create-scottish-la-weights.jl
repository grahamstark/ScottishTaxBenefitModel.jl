#=

OBSOLETE VERSION DON'T USE!!!
use LocalWeightGeneration.jl in src/ instead.

=#

using CSV, DataFrames
using ScottishTaxBenefitModel
using .ModelHousehold
using .Definitions
using .FRSHouseholdGetter
using .RunSettings
using .Weighting
using SurveyDataWeighting
using CSV
using StatsBase

INCLUDE_OCCUP = true
INCLUDE_HOUSING = true
INCLUDE_BEDROOMS = true
INCLUDE_CT = true
INCLUDE_HCOMP = true
INCLUDE_EMPLOYMENT = true
INCLUDE_INDUSTRY = false
INCLUDE_HH_SIZE = true

const DDIR = joinpath("/","mnt","data","ScotBen","data", "local", "local_targets_2024" )
io = open( "tmp/la-errors-2.out", "w")

function readc(filename::String)::Tuple
    d = (CSV.File( filename; normalizenames=true, header=10, skipto=12)|>DataFrame)
    if ismissing(d[1,2])
        delete!( )
    end
    label = names(d)[1]
    actuald = d[1:33,2:end]
    nms = names(actuald)
    rename!(actuald,1=>"Authority")
    actuald, label, nms
end

function read_all()
    fs = sort(readdir( DDIR, join=true ))
    n = 0
    allfs = nothing
    rows = 0
    cols = 0
    nfs = length(fs)
    dfs = []
    labels = DataFrame( filename=fill("",nfs), label=fill("",nfs), start=zeros(Int,nfs) )
    for f in fs
        if ! isnothing(match(r".*table.*.csv$",f))
            n += 1
            println( io, "on $f")
            data, label, nms = readc(f)
            println( io, nms)
            println( io, label)
            println( io, data)
            labels.filename[n] = f
            labels.label[n]=label
            labels.start[n]=cols+2        
            if n == 1
                allfs = deepcopy( data )
            else
                n1 = String.(data[:,1])[1:8] # skip "Na hEileanan Siar", since it's sometimes edited
                n2 = String.(allfs[:,1])[1:8]
                @assert n1 == n2 "$(n1) !== $(n2)" # check in sync
                allfs = hcat( allfs, data; makeunique=true )
                rows,cols = size(allfs)                
            end
            push!(dfs,data)
            # println( "label=$label")
        end
    end
    allfs,labels[1:n,:],dfs
end

allfs,labels,dfs = read_all()

const authority_codes = [
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


function summarise_dfs( data :: DataFrame, targets::DataFrameRow, household_total :: Number )::DataFrame
    nms = Symbol.(names(targets))
    nrows, ncols = size( data )
    d = DataFrame()
    scale = nrows / popn
    initial_weights = Weights(ones(nrows)*household_total/rows)
    for n in nms 
        d[n] = zeros(11)
        v = summarystats(data[!,n], initial_weights)
        d[1,n] = v.max
        d[3,n] = v.mean
        d[4,n] = v.median
        d[5,n] = v.nmiss
        d[6,n] = v.min
        d[7,n] = v.nobs
        d[8,n] = v.q25
        d[9,n] = v.q75
        d[10,n] = v.sd
        d[11,n] = targets[n] / sum(data[!,n],initial_weights)
    end
    return d
end
# stray columns we want to delete in the main target file once
# it's assembled
COLS_TO_DELETE = [
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

ctbase=CSV.File(joinpath( DDIR, "CTAXBASE+2024+-+Tables+-+Chargeable+Dwellings.csv"),normalizenames=true)|>DataFrame
allfs = hcat( allfs, ctbase; makeunique=true )

rename!( allfs, RENAMES )
select!( allfs, Not(COLS_TO_DELETE))
allfs.total_cts = sum.(eachrow(allfs[:,[:A,:B,:C,:D,:E,:F,:G,:H]]))

# merged columns 
allfs.private_rented_rent_free = allfs.private_rented + allfs.rent_free
allfs.converted_flat = allfs.converted_flat_1 + allfs.converted_flat_2
allfs.all_mortgaged = allfs.mortgaged + allfs.shared_ownership + allfs.shared_equity
allfs.bedrooms_4_plus = allfs.bedrooms_4 + allfs.bedrooms_5_plus
allfs.Five_plus_people = allfs.Five_people +
        allfs.Six_people +
        allfs.Seven_people +
        allfs.Eight_or_more_people 
allfs.working = allfs.economically_active_employee + allfs.economically_active_self_employed 
allfs.authority_code = authority_codes

CSV.write( joinpath(DDIR,"labels.tab"), labels; delim='\t')
CSV.write( joinpath(DDIR,"allfs.tab"), allfs; delim='\t' )

function initialise_target_dataframe_scotland_la( n :: Integer ) :: DataFrame
    d = DataFrame()

    if INCLUDE_HCOMP 
        # d.single_person = zeros(n) #1
        d.single_parent = zeros(n) # 2
        # d.single_family = zeros(n) # 3
        d.multi_family = zeros(n) # 4
    end
    # 5
    if INCLUDE_CT
        # d.A = zeros(n) #7
        d.B = zeros(n) #5
        d.C = zeros(n) #6
        d.D = zeros(n)
        d.E = zeros(n) #8
        d.F = zeros(n) #9
        d.G = zeros(n) # 10
        d.H = zeros(n) # 11
        # d.I = zeros(n) # 12
    end
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
    # 25
    if INCLUDE_EMPLOYMENT
        # d.working = zeros(n)
        d.economically_active_employee  = zeros(n)
        d.economically_active_self_employed  = zeros(n)
        d.economically_active_unemployed  = zeros(n)
    end
    # 29
    if INCLUDE_OCCUP 
        # d.Soc_Managers_Directors_and_Senior_Officials=zeros(n)
        d.Soc_Professional_Occupations = zeros(n)	#	83	% all in employment who are - 2: professional occupations (SOC2010)
        d.Soc_Associate_Prof_and_Technical_Occupations = zeros(n)	#	84	% all in employment who are - 3: associate prof & tech occupations (SOC2010)
        d.Soc_Admin_and_Secretarial_Occupations = zeros(n)	#	85	% all in employment who are - 4: administrative and secretarial occupations (SOC2010)
        d.Soc_Skilled_Trades_Occupations = zeros(n)	#	86	% all in employment who are - 5: skilled trades occupations (SOC2010)
        d.Soc_Caring_leisure_and_other_service_occupations = zeros(n)	#	87	% all in employment who are - 6: caring, leisure and other service occupations (SOC2010)
        d.Soc_Sales_and_Customer_Service = zeros(n)	#	88	% all in employment who are - 7: sales and customer service occupations (SOC2010)
        d.Soc_Process_Plant_and_Machine_Operatives = zeros(n)  	#	89	% all in employment who are - 8: process, plant and machine operatives (SOC2010)
        d.Soc_Elementary_Occupations = zeros(n)    #   90  % all in employment who are - 9: elementary occupations (SOC2010) 
    end

    if INCLUDE_HOUSING 
        # owner_occupied = zeros(n),
        d.all_mortgaged = zeros(n)
        d.socially_rented = zeros(n)
        d.private_rented_rent_free = zeros(n)


        # detached
        d.semi_detached = zeros(n)
        d.terraced = zeros(n)
        d.flat_or_maisonette = zeros(n)
        d.converted_flat = zeros(n)
        d.other_accom = zeros(n)
    end
    if INCLUDE_BEDROOMS
        # one bedroom
        d.bedrooms_2 = zeros(n)
        d.bedrooms_3 = zeros(n)
        d.bedrooms_4_plus = zeros(n)
    end        
    if INCLUDE_INDUSTRY
        # d.A_B_D_E_Agriculture_energy_and_water = zeros(n)
        d.C_Manufacturing = zeros(n)
        d.F_Construction = zeros(n)
        d.G_I_Distribution_hotels_and_restaurants = zeros(n)
        d.H_J_Transport_and_communication = zeros(n)
        d.K_L_M_N_Financial_real_estate_professional_and_administrative_activities  = zeros(n)
        d.O_P_Q_Public_administration_education_and_health = zeros(n)
    end
    if INCLUDE_HH_SIZE
        # one person
        d.Two_people = zeros(n)
        d.Three_people = zeros(n)
        d.Four_people = zeros(n)
        d.Five_plus_people = zeros(n)
        # d.Six_people = zeros(n)
        # d.Seven_people = zeros(n)
        # d.Eight_or_more_people = zeros(n)
    end
    return d    
end

function make_target_row_scotland_la!( 
    row :: DataFrameRow, 
    hh :: Household )
    if INCLUDE_HCOMP
        bus = get_benefit_units( hh )
        if is_single(hh)
            # println("single_person")
            # row.single_person = 1
            # 
        elseif size(bus)[1] > 1
            row.multi_family = 1 
            # println( "multi-family")
        elseif is_lone_parent(hh) # only dependent children
            row.single_parent = 1
            # println( "single_parent")
        else
            # row.single_family = 1 
            # println( "single_family")
            # 
        end
    end
    if INCLUDE_CT
        # println( "hh.ct_band $(hh.ct_band)")
        if hh.ct_band == Band_A
           #  row.A = 1
        elseif hh.ct_band == Band_B
            row.B = 1
        elseif hh.ct_band == Band_C
            row.C = 1
        elseif hh.ct_band == Band_D
            row.D = 1
        elseif hh.ct_band == Band_E
            row.E = 1
        elseif hh.ct_band == Band_F
            row.F = 1
        elseif hh.ct_band == Band_G
            row.G = 1
        elseif hh.ct_band == Band_H
            row.H = 1
        elseif hh.ct_band == Band_I
            @assert false "wrong band I for hh=$(hh.hid)"
            # row.I = 1
        else hh.ct_band == Household_not_valued_separately
            # row.A = 1 # DODGY!! FIXME
            #
            # @assert false "NO CT BAND"
        end            
    end # CT

    # these sum to totals
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
        if INCLUDE_EMPLOYMENT
            # drop inactive 
            if pers.employment_status in [Full_time_Employee, Part_time_Employee]
                row.economically_active_employee += 1
                # row.working += 1
            elseif pers.employment_status in [
                Full_time_Self_Employed,
                Part_time_Self_Employed ]
                # row.working += 1
                row.economically_active_self_employed += 1
            elseif pers.employment_status in [Unemployed]
                row.economically_active_unemployed += 1
            end
        end
        if INCLUDE_OCCUP
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
                if p != Managers_Directors_and_Senior_Officials
                    psoc = Symbol( "Soc_$(p)")            
                    row[psoc] += 1
                end
            end # occupation
        end # include occ
        if INCLUDE_INDUSTRY
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
        end    
    end # pers loop
    if INCLUDE_BEDROOMS
        if hh.bedrooms == 1
            #
        elseif hh.bedrooms == 2
            row.bedrooms_2 = 1
        elseif hh.bedrooms == 3
            row.bedrooms_3 = 1
        else
            row.bedrooms_4_plus = 1
        end
    end
    if INCLUDE_HOUSING
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
            # row.
        end
        # dwell_na = -1
        if hh.dwelling == detatched
            # 
        elseif hh.dwelling == semi_detached
            row.semi_detached = 1
        elseif hh.dwelling == terraced
            row.terraced = 1
        elseif hh.dwelling == flat_or_maisonette
            row.flat_or_maisonette = 1
        elseif hh.dwelling == converted_flat
            row.converted_flat = 1
        else 
            row.other_accom = 1
        end
    end
    if INCLUDE_HH_SIZE
        hsize = num_people(hh)
        if hsize == 1
            #
        elseif hsize == 2
            row.Two_people = 1
        elseif hsize == 3
            row.Three_people = 1
        elseif hsize == 4
            row.Four_people = 1
        elseif hsize >= 5
            row.Five_plus_people = 1
        end
    end
end

function make_target_list( alldata::DataFrame, council::Symbol )::Vector
    data = alldata[alldata.authority_code .== council,:][1,:]
    v = initialise_target_dataframe_scotland_la(1)[1,:] # a single row
    if INCLUDE_HCOMP
        # v.single_person = data.single_person
        v.single_parent = data.single_parent
        # v.single_family = data.single_family
        v.multi_family = data.multi_family        
    end
    if INCLUDE_CT
        scale = data.total_cts/data.total_hhlds # since total cts is always a bit smaller as total hhlds
        # v.A = data.A*scale
        v.B = data.B*scale
        v.C = data.C*scale
        v.D = data.D*scale
        v.E = data.E*scale
        v.F = data.F*scale
        v.G = data.G*scale
        v.H = data.H*scale
        # v.I = data.I*scale 
    end
    v.f_0_15  = data.f_0_15 
    v.f_16_24  = data.f_16_24 
    v.f_25_34  = data.f_25_34 
    v.f_35_49 = data.f_35_49
    v.f_50_64 = data.f_50_64
    v.f_65plus = data.f_65plus
    v.m_0_15 = data.m_0_15
    v.m_16_24 = data.m_16_24
    v.m_25_34 = data.m_25_34
    v.m_35_49 = data.m_35_49
    v.m_50_64 = data.m_50_64
    v.m_65plus = data.m_65plus
    if INCLUDE_EMPLOYMENT
        # v.working  = data.working
        v.economically_active_employee  = data.economically_active_employee 
        v.economically_active_self_employed  = data.economically_active_self_employed 
        v.economically_active_unemployed  = data.economically_active_unemployed 
    end
    if INCLUDE_OCCUP 
        # v.Soc_Managers_Directors_and_Senior_Officials = data.Soc_Managers_Directors_and_Senior_Officials
        v.Soc_Professional_Occupations = data.Soc_Professional_Occupations
        v.Soc_Associate_Prof_and_Technical_Occupations = data.Soc_Associate_Prof_and_Technical_Occupations
        v.Soc_Admin_and_Secretarial_Occupations = data.Soc_Admin_and_Secretarial_Occupations
        v.Soc_Skilled_Trades_Occupations = data.Soc_Skilled_Trades_Occupations
        v.Soc_Caring_leisure_and_other_service_occupations = data.Soc_Caring_leisure_and_other_service_occupations
        v.Soc_Sales_and_Customer_Service = data.Soc_Sales_and_Customer_Service
        v.Soc_Process_Plant_and_Machine_Operatives = data.Soc_Process_Plant_and_Machine_Operatives
        v.Soc_Elementary_Occupations = data.Soc_Elementary_Occupations
    end
    if INCLUDE_BEDROOMS
        # one bedroom
        v.bedrooms_2 = data.bedrooms_2
        v.bedrooms_3 = data.bedrooms_3
        v.bedrooms_4_plus = data.bedrooms_4_plus
    end

    if INCLUDE_HOUSING 
        # owner_occupied = zeros(n),
        v.all_mortgaged = data.all_mortgaged
        v.socially_rented = data.socially_rented
        v.private_rented_rent_free = data.private_rented_rent_free
        # detached
        v.semi_detached = data.semi_detached
        v.terraced = data.terraced
        v.flat_or_maisonette = data.flat_or_maisonette
        v.converted_flat = data.converted_flat
        v.other_accom = data.other_accom
    end
    if INCLUDE_INDUSTRY
        # v.A_B_D_E_Agriculture_energy_and_water = data.A_B_D_E_Agriculture_energy_and_water
        v.C_Manufacturing = data.C_Manufacturing
        v.F_Construction = data.F_Construction
        v.G_I_Distribution_hotels_and_restaurants = data.G_I_Distribution_hotels_and_restaurants
        v.H_J_Transport_and_communication = data.H_J_Transport_and_communication
        v.K_L_M_N_Financial_real_estate_professional_and_administrative_activities  = data.K_L_M_N_Financial_real_estate_professional_and_administrative_activities 
        v.O_P_Q_Public_administration_education_and_health = data.O_P_Q_Public_administration_education_and_health
    end
    if INCLUDE_HH_SIZE
        # one person
        v.Two_people = data.Two_people
        v.Three_people = data.Three_people
        v.Four_people = data.Four_people
        v.Five_plus_people  = data.Five_plus_people
        #v.Six_people = data.Six_people
        #v.Seven_people = data.Seven_people
        #v.Eight_or_more_people = data.Eight_or_more_people
    end
    return Vector(v)
end

function weight_to_la( 
    settings :: Settings,
    alldata :: DataFrame, 
    code :: Symbol,
    num_households :: Int )
    targets = make_target_list( alldata, code ) 
    println( io, "target list for $code")
    println( io, targets )
    hhtotal = alldata[alldata.authority_code .== code,:total_hhlds][1]
    println( io, "calculating for $code; hh total $hhtotal")
    weights,dataset = generate_weights(
        num_households;
        weight_type = settings.weight_type,
        lower_multiple = settings.lower_multiple, # these values can be narrowed somewhat, to around 0.25-4.7
        upper_multiple = settings.upper_multiple,
        household_total = hhtotal,
        targets = targets,
        initialise_target_dataframe = initialise_target_dataframe_scotland_la,
        make_target_row! = make_target_row_scotland_la! )
    return weights,dataset
end

function t_make_target_dataset( 
    nhhlds :: Integer, 
    initialise_target_dataframe :: Function,
    make_target_row! :: Function ) :: Tuple
    df :: DataFrame = initialise_target_dataframe( nhhlds )
    for hno in 1:nhhlds
        hh = FRSHouseholdGetter.get_household( hno )
        make_target_row!( df[hno,:], hh )
    end
    m = Matrix{Float64}(df) 

    # consistency
    nr,nc = size(m)
    # no column is all zero - since only +ive cells possible this is the easiest way
    # println(m)
    for c in 1:nc 
        @assert sum(m[:,c]) != 0 "all zero column $c"
    end
    # no row all zero
    for r in 1:nr
        @assert sum(m[r,:] ) != 0 "all zero row $r"
    end
    return m,df
end

settings = Settings()
settings.weighting_strategy = use_runtime_computed_weights
settings.lower_multiple = 0.1
settings.upper_multiple = 7.0
settings.included_data_years = collect(2015:2021)
  
@time settings.num_households, settings.num_people, nhh2 = 
    initialise( settings; reset=false )
# initial version for checking
m, tdf = t_make_target_dataset(
    settings.num_households,
    initialise_target_dataframe_scotland_la,
    make_target_row_scotland_la! )
    errors = []
const wides = Set([:S12000013] ) # h-Eileanan Siar""Angus", "East Lothian", "East Renfrewshire", "Renfrewshire", "East Dunbartonshire", "North Ayrshire", "West Dunbartonshire", "Shetland Islands", "Orkney Islands", "Inverclyde", "Midlothian", "Argyll and Bute", "East Ayrshire", "Dundee City", "Na h-Eileanan Siar", "South Lanarkshire", "Clackmannanshire", "West Lothian", "Falkirk", "Moray", "South Ayrshire", "City of Edinburgh", "Aberdeenshire", "North Lanarkshire"])
const verywides = Set([:S12000010, :S12000019, :S12000011, :S12000035, :S12000045] ) 
#"East Lothian", "Midlothian", "East Renfrewshire", "Argyll and Bute", "East Dunbartonshire"])
s = Set()
settings.lower_multiple = 0.01
settings.upper_multiple = 50.0  

outweights = DataFrame()

outweights.data_year = zeros(Int,settings.num_households)
outweights.hid = zeros(BigInt,settings.num_households)
outweights.uhid = zeros(BigInt,settings.num_households)
for href in 1:settings.num_households
    mhh = get_household( href )
    outweights.uhid[href] = mhh.uhid
    outweights.hid[href] = mhh.hid
    outweights.data_year[href] = mhh.data_year
end
for code in allfs.authority_code
    println( io, "on $code")
    try
        # FIXME messing with globals for empl, hhsize, which break some authorities
        if code in verywides
            INCLUDE_EMPLOYMENT = false
            INCLUDE_HH_SIZE = false
        elseif code in wides     
            INCLUDE_EMPLOYMENT = true
            INCLUDE_HH_SIZE = true
            settings.lower_multiple = 0.001
            settings.upper_multiple = 100.0            
        else
            INCLUDE_HH_SIZE = true
            INCLUDE_EMPLOYMENT = true            
        end
        #  INCLUDE_EMPLOYMENT = false
        # INCLUDE_HH_SIZE = false
        w,data = weight_to_la( settings, allfs, code, settings.num_households )
        println( io, "size w=$(size(w)) size outweights=$(size(outweights))")
        outweights[!,code] = w
    catch e
        println( io, e )
        println( io, stacktrace())
        push!( errors, (; e, code ))
        push!( s, code )
    end
end
# println( io, "ERRORS=$errors" )
println( io, "s=$s")
CSV.write( joinpath( DDIR, "la-frs-weights-scotland-2025.tab"), outweights; delim='\t')
weights = CSV.File( joinpath( DDIR, "la-frs-weights-scotland-2025.tab") ) |> DataFrame 
close(io)